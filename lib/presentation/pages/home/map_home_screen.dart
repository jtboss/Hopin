import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../data/models/map_ride_model.dart';
import '../../../data/mock_data/mock_rides_data.dart';
import '../../../domain/entities/location.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/services/location_service.dart';
import '../../widgets/map/google_map_widget.dart';
import '../../widgets/bottom_sheets/ride_booking_bottom_sheet.dart';
import '../../widgets/bottom_sheets/ride_details_bottom_sheet.dart';

import '../../theme/app_theme.dart';
import '../auth/login_screen.dart';

/// Main home screen showing the map and available rides
class MapHomeScreen extends StatefulWidget {
  final bool isDriverMode;
  
  const MapHomeScreen({
    super.key,
    this.isDriverMode = false,
  });

  @override
  State<MapHomeScreen> createState() => _MapHomeScreenState();
}

class _MapHomeScreenState extends State<MapHomeScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  
  List<MapRideModel> _availableRides = [];
  bool _isLoading = true;
  String? _error;
  User? _currentUser;
  StreamSubscription? _rideUpdateSubscription;

  @override
  void initState() {
    super.initState();
    _checkAuthAndLoadData();
  }

  Future<void> _checkAuthAndLoadData() async {
    // Check if user is authenticated
    _currentUser = FirebaseAuth.instance.currentUser;
    if (_currentUser == null) {
      // Redirect to login if not authenticated
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
      return;
    }

    await _loadAvailableRides();
  }

  Future<void> _loadAvailableRides() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Cancel existing subscription if any
      _rideUpdateSubscription?.cancel();
      
      // Listen to rides stream from Firebase
      _rideUpdateSubscription = _firestoreService.getAvailableRides().listen(
        (rides) {
          if (mounted) {
            print('🔄 Raw rides received from Firebase: ${rides.length}');
            for (final ride in rides) {
              print('  - ${ride.id}: ${ride.status.name} by ${ride.driverName}');
              print('    Pickup: ${ride.pickupLocation.latitude}, ${ride.pickupLocation.longitude}');
              print('    Destination: ${ride.destinationLocation.latitude}, ${ride.destinationLocation.longitude}');
              print('    Driver ID: ${ride.driverId}, Current User: ${_currentUser?.uid}');
            }
            
            // Filter to only show truly available rides (not started or completed)
            final availableRides = rides.where((ride) => 
              ride.status == RideStatus.available && 
              ride.availableSeats > 0 &&
              ride.departureTime.isAfter(DateTime.now().subtract(const Duration(hours: 1))) &&
              // In driver mode, show your own rides; in passenger mode, hide them
              (widget.isDriverMode || ride.driverId != (_currentUser?.uid ?? ''))
            ).toList();
            
            print('🎯 After filtering: ${availableRides.length} available rides');
            if (availableRides.isEmpty) {
              print('⚠️ No rides available after filtering. Reasons:');
              for (final ride in rides) {
                final reasons = <String>[];
                if (ride.status != RideStatus.available) reasons.add('Status: ${ride.status.name}');
                if (ride.availableSeats <= 0) reasons.add('No seats available');
                if (ride.departureTime.isBefore(DateTime.now().subtract(const Duration(hours: 1)))) reasons.add('Departure time passed');
                if (!widget.isDriverMode && ride.driverId == (_currentUser?.uid ?? '')) reasons.add('Your own ride (passenger mode)');
                print('  - ${ride.id}: ${reasons.join(', ')}');
              }
            }
            
            setState(() {
              _availableRides = availableRides;
              _isLoading = false;
            });
            
            print('✅ Loaded ${availableRides.length} available rides from Firebase');
            if (widget.isDriverMode) {
              print('📱 Driver mode: Showing all rides including your own');
            } else {
              print('👥 Passenger mode: Hiding your own rides');
            }
          }
        },
        onError: (e) {
          print('❌ Error loading rides: $e');
          if (mounted) {
            setState(() {
              _error = 'Failed to load rides. Please try again.';
              _isLoading = false;
            });
          }
        },
      );
    } catch (e) {
      print('❌ Error setting up ride stream: $e');
      if (mounted) {
        setState(() {
          _error = 'Failed to load rides. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshRides() async {
    print('🔄 Refreshing rides...');
    await _loadAvailableRides();
  }

  @override
  void dispose() {
    _rideUpdateSubscription?.cancel();
    super.dispose();
  }

  Future<void> _signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sign out failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showRideSelectionBottomSheet() {
    if (_availableRides.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No rides available at the moment'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    // Show the first available ride directly for now
    // TODO: Implement proper ride selection UI
    _showRideBookingBottomSheet(_availableRides.first);
  }

  void _showCreateRideInterface() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildCreateRideBottomSheet(),
    );
  }

  Widget _buildCreateRideBottomSheet() {
    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: HopinColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: HopinColors.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Title
              const Text(
                'Create New Ride',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: HopinColors.onSurface,
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Create ride form
              Expanded(
                child: _CreateRideForm(
                  onRideCreated: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('🎉 Ride created successfully! Students can now book.'),
                        backgroundColor: HopinColors.secondary,
                      ),
                    );
                    // Refresh rides to show the new ride
                    _loadAvailableRides();
                  },
                  currentUser: _currentUser,
                  onRefreshRides: _refreshRides,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showRideBookingBottomSheet(MapRideModel ride) {
    // Don't call Navigator.pop - that was causing the weird navigation issue
    // Just show the booking bottom sheet directly
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RideBookingBottomSheet(
        ride: ride,
        onBookingComplete: () {
          // Refresh rides after booking
          _loadAvailableRides();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HopinColors.background,
      appBar: AppBar(
        backgroundColor: HopinColors.background,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Hopin',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: HopinColors.onSurface,
              ),
            ),
            if (_currentUser != null)
              Text(
                'Welcome, ${_currentUser!.email?.split('@')[0] ?? 'Student'}!',
                style: const TextStyle(
                  fontSize: 12,
                  color: HopinColors.onSurfaceVariant,
                ),
              ),
          ],
        ),
        actions: [
          // Driver/Rider toggle placeholder
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: HopinColors.primaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text(
              'Rider Mode',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: HopinColors.onPrimaryContainer,
              ),
            ),
          ),
          
          // Profile/Sign out
          PopupMenuButton(
            icon: CircleAvatar(
              radius: 16,
              backgroundColor: HopinColors.primary,
              child: Text(
                _currentUser?.email?.substring(0, 1).toUpperCase() ?? 'U',
                style: const TextStyle(
                  color: HopinColors.onPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            itemBuilder: (context) => [
              PopupMenuItem(
                child: const Row(
                  children: [
                    Icon(Icons.person_outline),
                    SizedBox(width: 8),
                    Text('Profile'),
                  ],
                ),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Profile feature coming soon!'),
                    ),
                  );
                },
              ),
              PopupMenuItem(
                child: const Row(
                  children: [
                    Icon(Icons.logout),
                    SizedBox(width: 8),
                    Text('Sign Out'),
                  ],
                ),
                onTap: _signOut,
              ),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          // Main map area
          GoogleMapWidget(
            availableRides: _availableRides,
            isLoading: _isLoading,
            isDriverMode: widget.isDriverMode,
            onRideSelected: _handleRideSelection,
          ),
          
          // Error banner
          if (_error != null)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(12),
                color: Colors.orange.shade100,
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber, color: Colors.orange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.orange),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.orange),
                      onPressed: () {
                        setState(() {
                          _error = null;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Refresh button
          FloatingActionButton.small(
            heroTag: "refresh",
            onPressed: _refreshRides,
            backgroundColor: HopinColors.surface,
            child: const Icon(
              Icons.refresh,
              color: HopinColors.primary,
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Main action button - Different for drivers vs riders
          if (widget.isDriverMode) ...[
            // Driver mode: Create ride button
            FloatingActionButton.extended(
              onPressed: _showCreateRideInterface,
              backgroundColor: HopinColors.secondary,
              foregroundColor: HopinColors.onSecondary,
              icon: const Icon(Icons.add_location_alt),
              label: const Text('Create Ride'),
            ),
          ] else ...[
            // Rider mode: Find ride button
            FloatingActionButton.extended(
              onPressed: _availableRides.isEmpty ? null : _showRideSelectionBottomSheet,
              backgroundColor: HopinColors.primary,
              foregroundColor: HopinColors.onPrimary,
              icon: const Icon(Icons.directions_car),
              label: Text(
                _isLoading 
                  ? 'Loading...' 
                  : _availableRides.isEmpty 
                    ? 'No Rides' 
                    : 'Find Ride',
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _handleRideSelection(MapRideModel ride) {
    // Double-check ride is still available before showing booking
    if (ride.status != RideStatus.available || ride.availableSeats <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ This ride is no longer available'),
          backgroundColor: Colors.orange,
        ),
      );
      // Refresh rides to update the map
      _loadAvailableRides();
      return;
    }

    if (!widget.isDriverMode) {
      // Only show booking sheet for riders
      _onRideSelected(ride);
    } else {
      // For drivers, show ride info without booking option
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This is another driver\'s ride'),
          backgroundColor: Colors.blue,
        ),
      );
    }
  }

  void _onRideSelected(MapRideModel ride) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RideDetailsBottomSheet(
        ride: ride,
        onBookRide: () => _bookRide(ride),
      ),
    );
  }

  Future<void> _bookRide(MapRideModel ride) async {
    try {
      // Check if user is trying to book their own ride
      if (ride.driverId == _currentUser?.uid) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ You cannot book your own ride'),
            backgroundColor: HopinColors.error,
          ),
        );
        return;
      }

      // Create booking
      await _firestoreService.createBooking(
        rideId: ride.id,
        seatsBooked: 1,
        specialRequests: null,
      );

      // Update ride available seats
      await _firestoreService.updateRide(ride.id, {
        'availableSeats': ride.availableSeats - 1,
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Ride booked successfully!'),
          backgroundColor: HopinColors.secondary,
        ),
      );

      // Close bottom sheet
      Navigator.pop(context);

    } catch (e) {
      print('❌ Error booking ride: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Failed to book ride: $e'),
          backgroundColor: HopinColors.error,
        ),
      );
    }
  }
}

class _CreateRideForm extends StatefulWidget {
  final VoidCallback onRideCreated;
  final User? currentUser;
  final VoidCallback onRefreshRides;
  
  const _CreateRideForm({
    required this.onRideCreated,
    required this.currentUser,
    required this.onRefreshRides,
  });
  
  @override
  State<_CreateRideForm> createState() => _CreateRideFormState();
}

class _CreateRideFormState extends State<_CreateRideForm> {
  final _formKey = GlobalKey<FormState>();
  final _pickupFieldKey = GlobalKey<_LocationAutocompleteFieldState>();
  final _destinationFieldKey = GlobalKey<_LocationAutocompleteFieldState>();
  final FirestoreService _firestoreService = FirestoreService();
  final LocationService _locationService = LocationService();
  
  String _pickupAddress = '';
  String _destinationAddress = '';
  LatLng? _pickupCoordinates;
  LatLng? _destinationCoordinates;
  int _availableSeats = 1;
  DateTime _departureTime = DateTime.now().add(const Duration(hours: 1));
  double _price = 25.0;
  bool _isCreating = false;
  bool _isGettingLocation = false;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pickup location
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Pickup Location',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: HopinColors.onSurface,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: _isGettingLocation ? null : _useCurrentLocation,
                  icon: _isGettingLocation 
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.gps_fixed, size: 16),
                  label: Text(_isGettingLocation ? 'Getting Location...' : 'Use Current Location'),
                  style: TextButton.styleFrom(
                    foregroundColor: HopinColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _LocationAutocompleteField(
              key: _pickupFieldKey,
              hintText: 'Enter pickup location',
              prefixIcon: const Icon(Icons.my_location, color: HopinColors.secondary),
              onLocationSelected: (address, coordinates) {
                print('🚗 Pickup location selected:');
                print('  - Address: $address');
                print('  - Coordinates: ${coordinates?.latitude}, ${coordinates?.longitude}');
                setState(() {
                  _pickupAddress = address;
                  _pickupCoordinates = coordinates;
                });
              },
            ),
            
            const SizedBox(height: 16),
            
            // Destination location
            const Text(
              'Destination Location',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: HopinColors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            _LocationAutocompleteField(
              key: _destinationFieldKey,
              hintText: 'Enter destination location',
              prefixIcon: const Icon(Icons.location_on, color: HopinColors.error),
              onLocationSelected: (address, coordinates) {
                print('🎯 Destination location selected:');
                print('  - Address: $address');
                print('  - Coordinates: ${coordinates?.latitude}, ${coordinates?.longitude}');
                setState(() {
                  _destinationAddress = address;
                  _destinationCoordinates = coordinates;
                });
              },
            ),
            
            const SizedBox(height: 16),
            
            // Number of seats
            const Text(
              'Available Seats',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: HopinColors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                for (int i = 1; i <= 4; i++) ...[
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: i < 4 ? 8 : 0,
                      ),
                      child: FilledButton.tonal(
                        onPressed: () {
                          setState(() {
                            _availableSeats = i;
                          });
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: _availableSeats == i 
                              ? HopinColors.primary 
                              : HopinColors.surfaceVariant,
                          foregroundColor: _availableSeats == i 
                              ? HopinColors.onPrimary 
                              : HopinColors.onSurfaceVariant,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          '$i',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Departure time
            const Text(
              'Departure Time',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: HopinColors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: const Icon(Icons.schedule, color: HopinColors.primary),
                title: Text(
                  '${_departureTime.hour.toString().padLeft(2, '0')}:${_departureTime.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  'Today, ${_departureTime.day}/${_departureTime.month}/${_departureTime.year}',
                ),
                trailing: const Icon(Icons.edit),
                onTap: () {
                  _selectTime();
                },
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Price
            const Text(
              'Price per Person',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: HopinColors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text(
                  'R',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: HopinColors.primary,
                  ),
                ),
                Expanded(
                  child: Slider(
                    value: _price,
                    min: 15.0,
                    max: 100.0,
                    divisions: 17,
                    label: 'R${_price.toStringAsFixed(0)}',
                    onChanged: (value) {
                      setState(() {
                        _price = value;
                      });
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: HopinColors.secondaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'R${_price.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: HopinColors.onSecondaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Create ride button
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isCreating ? null : _createRide,
                child: _isCreating
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Create Ride',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_departureTime),
    );
    if (picked != null) {
      setState(() {
        _departureTime = DateTime(
          _departureTime.year,
          _departureTime.month,
          _departureTime.day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }

  Future<void> _useCurrentLocation() async {
    setState(() {
      _isGettingLocation = true;
    });

    try {
      // Get current location coordinates using LocationService
      final currentCoordinates = await _locationService.getCurrentLocation();
      
      // Reverse geocode to get address
      final addressString = await _locationService.reverseGeocode(currentCoordinates);
      
      setState(() {
        _pickupAddress = addressString;
        _pickupCoordinates = currentCoordinates;
      });
      
      // Update the pickup field
      _pickupFieldKey.currentState?.setLocation(addressString);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📍 Current location set as pickup'),
          backgroundColor: HopinColors.secondary,
          duration: Duration(seconds: 2),
        ),
      );
      
    } catch (e) {
      // Fallback to UCT default location
      const fallbackLocation = 'UCT Upper Campus Main Gate';
      const fallbackCoordinates = LatLng(-33.9249, 18.4241);
      
      setState(() {
        _pickupAddress = fallbackLocation;
        _pickupCoordinates = fallbackCoordinates;
      });
      
      _pickupFieldKey.currentState?.setLocation(fallbackLocation);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Using default location: $e'),
          backgroundColor: Colors.orange,
        ),
      );
    } finally {
      setState(() {
        _isGettingLocation = false;
      });
    }
  }

  Future<void> _createRide() async {
    if (_pickupAddress.isEmpty || _destinationAddress.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select both pickup and destination locations'),
          backgroundColor: HopinColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isCreating = true;
    });

    print('🚗 Creating ride with stored data:');
    print('  - Pickup Address: $_pickupAddress');
    print('  - Pickup Coordinates: ${_pickupCoordinates?.latitude}, ${_pickupCoordinates?.longitude}');
    print('  - Destination Address: $_destinationAddress');
    print('  - Destination Coordinates: ${_destinationCoordinates?.latitude}, ${_destinationCoordinates?.longitude}');

    // Use coordinates if available, otherwise use default locations
    final pickupCoords = _pickupCoordinates ?? const LatLng(-33.9249, 18.4241);
    final destinationCoords = _destinationCoordinates ?? const LatLng(-33.9567, 18.4603);

    if (_pickupCoordinates == null) {
      print('⚠️ Using FALLBACK pickup coordinates: ${pickupCoords.latitude}, ${pickupCoords.longitude}');
    } else {
      print('✅ Using REAL pickup coordinates: ${pickupCoords.latitude}, ${pickupCoords.longitude}');
    }

    if (_destinationCoordinates == null) {
      print('⚠️ Using FALLBACK destination coordinates: ${destinationCoords.latitude}, ${destinationCoords.longitude}');
    } else {
      print('✅ Using REAL destination coordinates: ${destinationCoords.latitude}, ${destinationCoords.longitude}');
    }

    try {
      print('🚗 Creating ride with final coordinates:');
      print('   Pickup: ${pickupCoords.latitude}, ${pickupCoords.longitude} ($_pickupAddress)');
      print('   Destination: ${destinationCoords.latitude}, ${destinationCoords.longitude} ($_destinationAddress)');

      // Create ride using FirestoreService
      final ride = MapRideModel(
        id: '',
        driverId: widget.currentUser?.uid ?? '',
        driverName: widget.currentUser?.displayName ?? 'Student Driver',
        driverPhoto: '👤',
        university: 'UCT',
        pickupLocation: pickupCoords,
        destinationLocation: destinationCoords,
        pickupAddress: _pickupAddress,
        destinationAddress: _destinationAddress,
        departureTime: _departureTime,
        availableSeats: _availableSeats,
        price: _price,
        rating: 5.0,
        totalRides: 0,
        isVerified: true,
        carModel: 'Honda Civic',
        carColor: 'White',
        status: RideStatus.available,
      );

      await _firestoreService.createRide(ride);
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Ride created successfully!'),
          backgroundColor: HopinColors.secondary,
        ),
      );

      // Clear form
      setState(() {
        _pickupAddress = '';
        _destinationAddress = '';
        _pickupCoordinates = null;
        _destinationCoordinates = null;
        _availableSeats = 1;
        _departureTime = DateTime.now().add(const Duration(hours: 1));
        _price = 25.0;
      });
      
      // Clear the form fields
      _pickupFieldKey.currentState?.setLocation('');
      _destinationFieldKey.currentState?.setLocation('');
      
      // Refresh the ride list and notify parent
      widget.onRefreshRides();
      widget.onRideCreated();
      
    } catch (e) {
      print('❌ Error creating ride: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Failed to create ride: $e'),
          backgroundColor: HopinColors.error,
        ),
      );
    } finally {
      setState(() {
        _isCreating = false;
      });
    }
  }
}

class _LocationAutocompleteField extends StatefulWidget {
  final String hintText;
  final Widget prefixIcon;
  final Function(String, LatLng?) onLocationSelected;
  
  const _LocationAutocompleteField({
    super.key,
    required this.hintText,
    required this.prefixIcon,
    required this.onLocationSelected,
  });
  
  @override
  State<_LocationAutocompleteField> createState() => _LocationAutocompleteFieldState();
}

class _LocationAutocompleteFieldState extends State<_LocationAutocompleteField> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final LocationService _locationService = LocationService();
  List<Location> _suggestions = [];
  bool _showSuggestions = false;
  Timer? _debounceTimer;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onTextChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (query.length >= 2) {
        _searchLocations(query);
      } else {
        setState(() {
          _suggestions = [];
          _showSuggestions = false;
        });
      }
    });
  }

  void _searchLocations(String query) async {
    try {
      // Use LocationService to get real location suggestions
      final locations = await _locationService.searchPlaces(query);
      
      if (mounted) {
        setState(() {
          _suggestions = locations.take(5).toList();
          _showSuggestions = locations.isNotEmpty;
        });
      }
    } catch (e) {
      print('❌ Error searching locations: $e');
      if (mounted) {
        setState(() {
          _suggestions = [];
          _showSuggestions = false;
        });
      }
    }
  }

  void _selectSuggestion(Location location) {
    final displayName = location.landmark ?? location.address;
    
    print('📍 Location selected:');
    print('  - Display Name: $displayName');
    print('  - Address: ${location.address}');
    print('  - Coordinates: ${location.latitude}, ${location.longitude}');
    print('  - City: ${location.city}');
    
    _controller.text = displayName;
    widget.onLocationSelected(displayName, LatLng(location.latitude, location.longitude));
    setState(() {
      _showSuggestions = false;
    });
    _focusNode.unfocus();
  }

  void setLocation(String locationText) {
    print('📍 Manual location set: $locationText (no coordinates)');
    _controller.text = locationText;
    widget.onLocationSelected(locationText, null); // No coordinates for manual input
    setState(() {
      _showSuggestions = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          controller: _controller,
          focusNode: _focusNode,
          decoration: InputDecoration(
            hintText: widget.hintText,
            prefixIcon: widget.prefixIcon,
            border: const OutlineInputBorder(),
            suffixIcon: _controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _controller.clear();
                      widget.onLocationSelected('', null);
                      setState(() {
                        _showSuggestions = false;
                      });
                    },
                  )
                : null,
          ),
          onChanged: _onTextChanged,
          onTap: () {
            if (_controller.text.length >= 2) {
              _searchLocations(_controller.text);
            }
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter a location';
            }
            return null;
          },
        ),
        
        // Suggestions dropdown
        if (_showSuggestions) ...[
          const SizedBox(height: 4),
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              color: HopinColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: HopinColors.outline),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _suggestions.length,
              itemBuilder: (context, index) {
                final location = _suggestions[index];
                final displayName = location.landmark ?? location.address;
                return ListTile(
                  dense: true,
                  leading: Icon(
                    displayName.contains('University') || displayName.contains('UCT')
                        ? Icons.school
                        : displayName.contains('Airport')
                            ? Icons.flight
                            : displayName.contains('Mall') || displayName.contains('Centre')
                                ? Icons.shopping_bag
                                : Icons.location_on,
                    color: HopinColors.primary,
                    size: 20,
                  ),
                  title: Text(
                    displayName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: location.city != null ? Text(
                    location.city!,
                    style: TextStyle(
                      fontSize: 12,
                      color: HopinColors.onSurfaceVariant,
                    ),
                  ) : null,
                  onTap: () => _selectSuggestion(location),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
} 