import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/services/driver_service.dart';
import '../../../core/services/firestore_service.dart';
import '../../../data/models/map_ride_model.dart' as map_model;
import '../../../data/models/booking_model.dart';
import '../../theme/app_theme.dart';

class DriverDashboardScreen extends StatefulWidget {
  const DriverDashboardScreen({super.key});

  @override
  State<DriverDashboardScreen> createState() => _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends State<DriverDashboardScreen> {
  final DriverService _driverService = DriverService();
  final FirestoreService _firestoreService = FirestoreService();
  
  bool _isLoading = true;
  List<map_model.MapRideModel> _activeRides = [];
  
  // Mock earnings data
  double _todayEarnings = 145.50;
  double _weekEarnings = 892.75;
  int _totalRides = 23;
  double _rating = 4.8;

  @override
  void initState() {
    super.initState();
    _loadActiveRides();
  }

  Future<void> _loadActiveRides() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      _firestoreService.getDriverActiveRides(currentUser.uid).listen((rides) {
        if (mounted) {
          setState(() {
            _activeRides = rides;
            _isLoading = false;
          });
        }
      });
    } catch (e) {
      print('❌ Error loading active rides: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Dashboard'),
        backgroundColor: HopinColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        // Stats card
        Container(
          width: double.infinity,
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: HopinColors.primary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Active Rides',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${_activeRides.length} rides',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        // Rides list
        Expanded(
          child: _activeRides.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  itemCount: _activeRides.length,
                  itemBuilder: (context, index) {
                    final ride = _activeRides[index];
                    return _buildRideCard(ride);
                  },
                ),
        ),

        // Development tools
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text(
                'Development Tools',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _cleanMyData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Clean My Data'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _cleanAllData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Clean All Data'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.directions_car_outlined,
            size: 80,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'No active rides',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Create a ride to start earning',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRideCard(map_model.MapRideModel ride) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(ride.status),
          child: const Icon(
            Icons.directions_car,
            color: Colors.white,
          ),
        ),
        title: Text(
          '${ride.pickupAddress} → ${ride.destinationAddress}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status: ${ride.status.name}'),
            Text('Seats: ${ride.availableSeats} | Price: R${ride.price.toStringAsFixed(0)}'),
          ],
        ),
        trailing: PopupMenuButton(
          onSelected: (value) {
            switch (value) {
              case 'start':
                _startRide(ride);
                break;
              case 'cancel':
                _cancelRide(ride);
                break;
            }
          },
          itemBuilder: (context) => [
            if (ride.status == map_model.RideStatus.available)
              const PopupMenuItem(
                value: 'start',
                child: Row(
                  children: [
                    Icon(Icons.play_arrow),
                    SizedBox(width: 8),
                    Text('Start Ride'),
                  ],
                ),
              ),
            const PopupMenuItem(
              value: 'cancel',
              child: Row(
                children: [
                  Icon(Icons.cancel),
                  SizedBox(width: 8),
                  Text('Cancel Ride'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(map_model.RideStatus status) {
    switch (status) {
      case map_model.RideStatus.available:
        return Colors.green;
      case map_model.RideStatus.departing:
        return Colors.orange;
      case map_model.RideStatus.inProgress:
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Future<void> _startRide(map_model.MapRideModel ride) async {
    try {
      await _firestoreService.updateRideStatus(ride.id, map_model.RideStatus.departing);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Ride started successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _cancelRide(map_model.MapRideModel ride) async {
    try {
      await _firestoreService.updateRideStatus(ride.id, map_model.RideStatus.cancelled);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Ride cancelled successfully!'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _cleanMyData() async {
    try {
      await _firestoreService.cleanupFirebaseData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Your data cleaned successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _cleanAllData() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Action'),
        content: const Text('This will delete ALL data in Firebase. Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _firestoreService.cleanupAllFirebaseData();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ All data cleaned successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
} 