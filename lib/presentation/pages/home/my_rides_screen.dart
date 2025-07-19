import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/services/firestore_service.dart';
import '../../../data/models/map_ride_model.dart';
import '../../../data/models/booking_model.dart';
import '../../theme/app_theme.dart';

/// Screen showing user's rides (either as rider or driver)
class MyRidesScreen extends StatefulWidget {
  final bool showDriverRides;
  
  const MyRidesScreen({
    super.key,
    required this.showDriverRides,
  });

  @override
  State<MyRidesScreen> createState() => _MyRidesScreenState();
}

class _MyRidesScreenState extends State<MyRidesScreen> with TickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();
  late TabController _tabController;
  
  List<MapRideModel> _activeRides = [];
  List<MapRideModel> _pastRides = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadRides();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadRides() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        if (widget.showDriverRides) {
          // Load driver's rides
          _firestoreService.getDriverRides(currentUser.uid).listen((rides) {
            if (mounted) {
              final activeRides = rides.where((ride) => 
                ride.status == RideStatus.available || 
                ride.status == RideStatus.departing ||
                ride.status == RideStatus.inProgress
              ).toList();
              
              final pastRides = rides.where((ride) => 
                ride.status == RideStatus.completed || 
                ride.status == RideStatus.cancelled
              ).toList();
              
              setState(() {
                _activeRides = activeRides;
                _pastRides = pastRides;
                _isLoading = false;
              });
              
              print('✅ Loaded ${rides.length} driver rides (${activeRides.length} active, ${pastRides.length} past)');
            }
          });
        } else {
          // Load rider's bookings and convert to rides
          _firestoreService.getUserBookings(currentUser.uid).listen((bookings) async {
            if (mounted) {
              // Get ride details for each booking
              final activeRides = <MapRideModel>[];
              final pastRides = <MapRideModel>[];
              
              for (final booking in bookings) {
                try {
                  final rideSnapshot = await FirebaseFirestore.instance
                      .collection('rides')
                      .doc(booking.rideId)
                      .get();
                  
                  if (rideSnapshot.exists) {
                    final data = rideSnapshot.data()!;
                    final ride = MapRideModel(
                      id: rideSnapshot.id,
                      driverId: data['driverId'] ?? '',
                      driverName: data['driverName'] ?? '',
                      driverPhoto: data['driverPhoto'] ?? '👤',
                      university: data['university'] ?? '',
                                             pickupLocation: _geoPointToLatLng(data['pickupLocation']),
                       destinationLocation: _geoPointToLatLng(data['destinationLocation']),
                      pickupAddress: data['pickupAddress'] ?? '',
                      destinationAddress: data['destinationAddress'] ?? '',
                      departureTime: (data['departureTime'] as Timestamp).toDate(),
                      availableSeats: data['availableSeats'] ?? 0,
                      price: (data['price'] ?? 0.0).toDouble(),
                      rating: (data['driverRating'] ?? 5.0).toDouble(),
                      totalRides: data['totalRides'] ?? 0,
                      isVerified: true,
                      carModel: data['carModel'] ?? 'Honda Civic',
                      carColor: data['carColor'] ?? 'White',
                                             status: _parseRideStatus(data['status'] ?? 'available'),
                    );
                    
                    if (booking.status == BookingStatus.confirmed || 
                        booking.status == BookingStatus.pending) {
                      activeRides.add(ride);
                    } else {
                      pastRides.add(ride);
                    }
                  }
                } catch (e) {
                  print('❌ Error loading ride ${booking.rideId}: $e');
                }
              }
              
              setState(() {
                _activeRides = activeRides;
                _pastRides = pastRides;
                _isLoading = false;
              });
              
              print('✅ Loaded ${bookings.length} rider bookings (${activeRides.length} active, ${pastRides.length} past)');
            }
          });
        }
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error loading rides: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Tab bar
                Container(
                  color: HopinColors.surface,
                  child: TabBar(
                    controller: _tabController,
                    indicatorColor: HopinColors.primary,
                    labelColor: HopinColors.primary,
                    unselectedLabelColor: HopinColors.onSurfaceVariant,
                    tabs: [
                      Tab(
                        text: widget.showDriverRides ? 'Active Rides' : 'Upcoming',
                        icon: const Icon(Icons.schedule),
                      ),
                      Tab(
                        text: widget.showDriverRides ? 'Completed' : 'History',
                        icon: const Icon(Icons.history),
                      ),
                    ],
                  ),
                ),
                
                // Tab content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildRidesList(_activeRides, isActive: true),
                      _buildRidesList(_pastRides, isActive: false),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildRidesList(List<MapRideModel> rides, {required bool isActive}) {
    if (rides.isEmpty) {
      return _buildEmptyState(isActive);
    }

    return RefreshIndicator(
      onRefresh: _loadRides,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: rides.length,
        itemBuilder: (context, index) {
          final ride = rides[index];
          return _buildRideCard(ride, isActive: isActive);
        },
      ),
    );
  }

  Widget _buildEmptyState(bool isActive) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: HopinColors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(40),
            ),
            child: Icon(
              isActive ? Icons.schedule : Icons.history,
              size: 40,
              color: HopinColors.onSurfaceVariant,
            ),
          ),
          
          const SizedBox(height: 16),
          
          Text(
            isActive ? 'No upcoming rides' : 'No ride history',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: HopinColors.onSurface,
            ),
          ),
          
          const SizedBox(height: 8),
          
          Text(
            isActive 
                ? widget.showDriverRides
                    ? 'Create your first ride to start earning!'
                    : 'Book your first ride to get started!'
                : 'Your completed rides will appear here',
            style: const TextStyle(
              fontSize: 14,
              color: HopinColors.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRideCard(MapRideModel ride, {required bool isActive}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with driver info and status
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: HopinColors.primaryContainer,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: HopinColors.primary,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      ride.driverPhoto,
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.showDriverRides 
                            ? 'Ride to ${ride.destinationAddress}'
                            : 'With ${ride.driverName}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: HopinColors.onSurface,
                        ),
                      ),
                      Text(
                        '${ride.university} • ${ride.formattedRating}⭐',
                        style: const TextStyle(
                          fontSize: 14,
                          color: HopinColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(ride.status).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStatusText(ride.status),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _getStatusColor(ride.status),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Route info
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: HopinColors.secondary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              ride.pickupAddress,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            width: 2,
                            height: 20,
                            margin: const EdgeInsets.only(left: 3),
                            decoration: BoxDecoration(
                              color: HopinColors.onSurfaceVariant.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Text(
                            ride.formattedDepartureTime,
                            style: const TextStyle(
                              fontSize: 12,
                              color: HopinColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: HopinColors.primary,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: HopinColors.background,
                                width: 2,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              ride.destinationAddress,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Price
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'R${ride.price.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: HopinColors.primary,
                      ),
                    ),
                    if (widget.showDriverRides)
                      Text(
                        '${4 - ride.availableSeats}/4 booked', // Assume 4 seats for now
                        style: const TextStyle(
                          fontSize: 12,
                          color: HopinColors.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ],
            ),
            
            // Action buttons
            if (isActive) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  if (widget.showDriverRides) ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          _viewRideDetails(ride);
                        },
                        child: const Text('View Details'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          _startRide(ride);
                        },
                        child: const Text('Start Ride'),
                      ),
                    ),
                  ] else ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          // Cancel booking
                        },
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          // Contact driver
                        },
                        child: const Text('Contact Driver'),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(RideStatus status) {
    switch (status) {
      case RideStatus.available:
        return HopinColors.secondary;
      case RideStatus.departing:
        return Colors.orange;
      case RideStatus.inProgress:
        return HopinColors.primary;
      case RideStatus.completed:
        return Colors.green;
      case RideStatus.cancelled:
        return Colors.red;
      default:
        return HopinColors.onSurfaceVariant;
    }
  }

  String _getStatusText(RideStatus status) {
    switch (status) {
      case RideStatus.available:
        return 'Confirmed';
      case RideStatus.departing:
        return 'Departing';
      case RideStatus.inProgress:
        return 'In Progress';
      case RideStatus.completed:
        return 'Completed';
      case RideStatus.cancelled:
        return 'Cancelled';
      default:
        return 'Unknown';
    }
  }

  void _viewRideDetails(MapRideModel ride) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildRideDetailsBottomSheet(ride),
    );
  }

  Widget _buildRideDetailsBottomSheet(MapRideModel ride) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: HopinColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: HopinColors.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Ride details
          Text(
            'Ride Details',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: HopinColors.onSurface,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Route info
          Row(
            children: [
              Column(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: HopinColors.secondary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Container(
                    width: 2,
                    height: 40,
                    color: HopinColors.outline,
                  ),
                  Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: HopinColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(width: 16),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ride.pickupAddress,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: HopinColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      ride.destinationAddress,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: HopinColors.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Price
              Text(
                'R${ride.price.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: HopinColors.primary,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Ride info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: HopinColors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Departure Time'),
                    Text(
                      ride.formattedDepartureTime,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Available Seats'),
                    Text(
                      '${ride.availableSeats} seats',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Status'),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(ride.status),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _getStatusText(ride.status),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: ride.status == RideStatus.available 
                    ? () => _startRideFromModal(ride)
                    : ride.status == RideStatus.inProgress 
                      ? () => _completeRideFromModal(ride)
                      : null,
                  child: Text(
                    ride.status == RideStatus.available 
                      ? 'Start Ride'
                      : ride.status == RideStatus.inProgress 
                        ? 'Complete Ride'
                        : 'Ride ${_getStatusText(ride.status)}',
                  ),
                ),
              ),
            ],
          ),
          
          // Safe area padding
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  void _startRide(MapRideModel ride) {
    if (ride.status != RideStatus.available) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cannot start ride. Status: ${_getStatusText(ride.status)}'),
          backgroundColor: HopinColors.error,
        ),
      );
      return;
    }

    // Update ride status to in-progress
    setState(() {
      // Note: MapRideModel properties are final, so we'd need to create a new instance
      // For now, just show the message - real implementation would update Firestore
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🚗 Ride started! Have a safe trip.'),
        backgroundColor: HopinColors.secondary,
      ),
    );
    
    // In a real app, this would update Firestore
    // await _firestoreService.updateRideStatus(ride.id, RideStatus.inProgress);
  }

  void _startRideFromModal(MapRideModel ride) {
    Navigator.pop(context); // Close modal first
    _startRide(ride);
  }

  void _completeRideFromModal(MapRideModel ride) {
    Navigator.pop(context); // Close modal first
    _completeRide(ride);
  }

  void _completeRide(MapRideModel ride) {
    // Update ride status to completed
    setState(() {
      // Note: MapRideModel properties are final, so we'd need to create a new instance
      // For now, just show the message - real implementation would update Firestore
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Ride completed! Well done.'),
        backgroundColor: HopinColors.secondary,
      ),
    );
    
    // In a real app, this would update Firestore and trigger earnings update
    // await _firestoreService.updateRideStatus(ride.id, RideStatus.completed);
  }

  // Helper methods
  LatLng _geoPointToLatLng(dynamic geoPointData) {
    try {
      if (geoPointData is GeoPoint) {
        return LatLng(geoPointData.latitude, geoPointData.longitude);
      } else if (geoPointData is Map<String, dynamic>) {
        final lat = (geoPointData['latitude'] ?? 0.0).toDouble();
        final lng = (geoPointData['longitude'] ?? 0.0).toDouble();
        return LatLng(lat, lng);
      } else {
        print('⚠️ Unknown GeoPoint format: ${geoPointData.runtimeType}');
        return const LatLng(-33.9249, 18.4241); // Default to UCT
      }
    } catch (e) {
      print('❌ Error converting GeoPoint: $e');
      return const LatLng(-33.9249, 18.4241); // Default to UCT
    }
  }

  RideStatus _parseRideStatus(String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return RideStatus.available;
      case 'departing_soon':
      case 'departing':
        return RideStatus.departing;
      case 'in_progress':
        return RideStatus.inProgress;
      case 'completed':
        return RideStatus.completed;
      case 'cancelled':
        return RideStatus.cancelled;
      default:
        return RideStatus.available;
    }
  }
} 