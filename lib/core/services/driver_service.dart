import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'dart:math';
import '../../data/models/map_ride_model.dart';
import 'firestore_service.dart';

enum DriverStatus { offline, online, onTrip, unavailable }

class DriverService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirestoreService _firestoreService = FirestoreService();
  
  static const String _driversCollection = 'drivers';
  static const String _driverLocationsCollection = 'driver_locations';

  // Location tracking
  StreamSubscription<Position>? _locationSubscription;
  Timer? _locationTimer;
  MapRideModel? _activeRide;
  bool _isAutoTrackingEnabled = false;
  LatLng? _lastKnownLocation;

  // Auto-start thresholds
  static const double _pickupDistanceThreshold = 100; // meters
  static const int _locationUpdateInterval = 5; // seconds

  // Start automatic location tracking for a ride
  Future<void> startAutoTracking(MapRideModel ride) async {
    try {
      _activeRide = ride;
      _isAutoTrackingEnabled = true;
      
      // Request location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permission is required for auto-tracking');
        }
      }

      // Start continuous location tracking
      _locationSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10, // Update every 10 meters
        ),
      ).listen((Position position) {
        _handleLocationUpdate(position);
      });

      // Fallback timer for location updates
      _locationTimer = Timer.periodic(
        Duration(seconds: _locationUpdateInterval),
        (timer) => _checkLocationAndStatus(),
      );

      print('✅ Auto-tracking started for ride: ${ride.id}');
    } catch (e) {
      print('❌ Error starting auto-tracking: $e');
      throw Exception('Failed to start auto-tracking: $e');
    }
  }

  // Stop automatic location tracking
  Future<void> stopAutoTracking() async {
    _isAutoTrackingEnabled = false;
    _activeRide = null;
    _lastKnownLocation = null;
    
    await _locationSubscription?.cancel();
    _locationSubscription = null;
    
    _locationTimer?.cancel();
    _locationTimer = null;
    
    print('✅ Auto-tracking stopped');
  }

  // Handle location updates
  void _handleLocationUpdate(Position position) async {
    if (!_isAutoTrackingEnabled || _activeRide == null) return;

    final currentLocation = LatLng(position.latitude, position.longitude);
    _lastKnownLocation = currentLocation;

    // Update driver location in Firebase
    await updateDriverLocation(currentLocation);

    // Check if driver has moved away from pickup location
    if (_activeRide!.status == RideStatus.available) {
      final distanceFromPickup = _calculateDistance(
        currentLocation,
        _activeRide!.pickupLocation,
      );

      // If driver is far enough from pickup, auto-start the ride
      if (distanceFromPickup > _pickupDistanceThreshold) {
        await _autoStartRide();
      }
    }
  }

  // Check location and ride status periodically
  void _checkLocationAndStatus() async {
    if (!_isAutoTrackingEnabled || _activeRide == null) return;

    try {
      // Get current location
      final position = await Geolocator.getCurrentPosition();
      _handleLocationUpdate(position);

      // Check if ride status has changed externally
      final currentRideSnapshot = await _firestore
          .collection('rides')
          .doc(_activeRide!.id)
          .get();

      if (currentRideSnapshot.exists) {
        final data = currentRideSnapshot.data()!;
        final currentStatus = _parseRideStatus(data['status'] ?? 'available');
        
        // Update local ride status
        if (currentStatus != _activeRide!.status) {
          // Create new ride instance with updated status
          _activeRide = MapRideModel(
            id: _activeRide!.id,
            driverId: _activeRide!.driverId,
            driverName: _activeRide!.driverName,
            driverPhoto: _activeRide!.driverPhoto,
            university: _activeRide!.university,
            pickupLocation: _activeRide!.pickupLocation,
            destinationLocation: _activeRide!.destinationLocation,
            pickupAddress: _activeRide!.pickupAddress,
            destinationAddress: _activeRide!.destinationAddress,
            price: _activeRide!.price,
            availableSeats: _activeRide!.availableSeats,
            departureTime: _activeRide!.departureTime,
            rating: _activeRide!.rating,
            totalRides: _activeRide!.totalRides,
            isVerified: _activeRide!.isVerified,
            carModel: _activeRide!.carModel,
            carColor: _activeRide!.carColor,
            status: currentStatus, // Updated status
          );
          
          print('🔄 Updated ride status to: $currentStatus');
          
          // If ride is completed or cancelled, stop tracking
          if (currentStatus == RideStatus.completed || 
              currentStatus == RideStatus.cancelled) {
            print('🛑 Stopping auto-tracking - ride ${currentStatus == RideStatus.completed ? 'completed' : 'cancelled'}');
            await stopAutoTracking();
          }
        }
      }
    } catch (e) {
      print('❌ Error checking location and status: $e');
    }
  }

  // Automatically start the ride when driver moves away from pickup
  Future<void> _autoStartRide() async {
    if (_activeRide == null || _activeRide!.status != RideStatus.available) {
      return;
    }

    try {
      print('🚀 Auto-starting ride: ${_activeRide!.id}');
      
      // Update ride status to departing
      await _firestoreService.updateRideStatus(_activeRide!.id, RideStatus.departing);
      
      // Wait a moment, then change to in-progress
      await Future.delayed(const Duration(seconds: 3));
      await _firestoreService.updateRideStatus(_activeRide!.id, RideStatus.inProgress);
      
      // Update local ride status
      _activeRide = MapRideModel(
        id: _activeRide!.id,
        driverId: _activeRide!.driverId,
        driverName: _activeRide!.driverName,
        driverPhoto: _activeRide!.driverPhoto,
        university: _activeRide!.university,
        pickupLocation: _activeRide!.pickupLocation,
        destinationLocation: _activeRide!.destinationLocation,
        pickupAddress: _activeRide!.pickupAddress,
        destinationAddress: _activeRide!.destinationAddress,
        price: _activeRide!.price,
        availableSeats: _activeRide!.availableSeats,
        departureTime: _activeRide!.departureTime,
        rating: _activeRide!.rating,
        totalRides: _activeRide!.totalRides,
        isVerified: _activeRide!.isVerified,
        carModel: _activeRide!.carModel,
        carColor: _activeRide!.carColor,
        status: RideStatus.inProgress, // Updated to in-progress
      );
      
      print('✅ Ride auto-started successfully');
    } catch (e) {
      print('❌ Error auto-starting ride: $e');
    }
  }

  // Calculate distance between two points in meters
  double _calculateDistance(LatLng point1, LatLng point2) {
    return Geolocator.distanceBetween(
      point1.latitude,
      point1.longitude,
      point2.latitude,
      point2.longitude,
    );
  }

  // Parse ride status from string
  RideStatus _parseRideStatus(String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return RideStatus.available;
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

  // Get current location
  Future<LatLng?> getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      return LatLng(position.latitude, position.longitude);
    } catch (e) {
      print('❌ Error getting current location: $e');
      return null;
    }
  }

  // Start a new ride (driver creates ride)
  Future<String> startRide({
    required LatLng pickupLocation,
    required LatLng destinationLocation,
    required String pickupAddress,
    required String destinationAddress,
    required DateTime departureTime,
    required int availableSeats,
    required double price,
    bool enableAutoTracking = true,
  }) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('Driver must be logged in to start a ride');
      }

      // Get driver info
      final driverDoc = await _firestore
          .collection(_driversCollection)
          .doc(currentUser.uid)
          .get();
      
      final driverData = driverDoc.exists ? driverDoc.data()! : {};

      // Create ride using existing FirestoreService
      final ride = MapRideModel(
        id: '',
        driverId: currentUser.uid,
        driverName: driverData['name'] ?? currentUser.displayName ?? 'Student Driver',
        driverPhoto: driverData['photo'] ?? '👤',
        university: driverData['university'] ?? 'UCT',
        pickupLocation: pickupLocation,
        destinationLocation: destinationLocation,
        pickupAddress: pickupAddress,
        destinationAddress: destinationAddress,
        departureTime: departureTime,
        availableSeats: availableSeats,
        price: price,
        rating: driverData['rating']?.toDouble() ?? 5.0,
        totalRides: driverData['totalRides'] ?? 0,
        isVerified: true,
        carModel: driverData['carModel'] ?? 'Honda Civic',
        carColor: driverData['carColor'] ?? 'White',
        status: RideStatus.available,
      );

      final rideId = await _firestoreService.createRide(ride);
      final createdRide = ride.copyWith(id: rideId);
      
      // Update driver status to "on trip"
      await updateDriverStatus(DriverStatus.onTrip);
      
      // Start automatic tracking if enabled
      if (enableAutoTracking) {
        await startAutoTracking(createdRide);
      }
      
      return rideId;
    } catch (e) {
      throw Exception('Failed to start ride: $e');
    }
  }

  // Update driver status
  Future<void> updateDriverStatus(DriverStatus status) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      await _firestore.collection(_driversCollection).doc(currentUser.uid).update({
        'status': status.toString().split('.').last,
        'lastActive': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update driver status: $e');
    }
  }

  // Update driver location (real-time tracking)
  Future<void> updateDriverLocation(LatLng location) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      await _firestore.collection(_driverLocationsCollection).doc(currentUser.uid).set({
        'driverId': currentUser.uid,
        'latitude': location.latitude,
        'longitude': location.longitude,
        'timestamp': FieldValue.serverTimestamp(),
        'rideId': _activeRide?.id, // Associate with active ride
      });
    } catch (e) {
      throw Exception('Failed to update driver location: $e');
    }
  }

  // Complete ride and trigger payment
  Future<void> completeRide(String rideId) async {
    try {
      // Update ride status to completed
      await _firestoreService.updateRideStatus(rideId, RideStatus.completed);
      
      // Set driver back to online
      await updateDriverStatus(DriverStatus.online);
      
      // Stop auto-tracking
      await stopAutoTracking();
      
      // Trigger driver payout (you'll need to implement payment integration)
      // This would call your payment service to process driver payout
      
    } catch (e) {
      throw Exception('Failed to complete ride: $e');
    }
  }

  // Get driver's current rides
  Stream<List<MapRideModel>> getDriverActiveRides() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return Stream.value([]);
    }

    return _firestoreService.getDriverActiveRides(currentUser.uid);
  }

  // Cancel ride
  Future<void> cancelRide(String rideId, String reason) async {
    try {
      await _firestoreService.updateRideStatus(rideId, RideStatus.cancelled);
      await updateDriverStatus(DriverStatus.online);
      
      // Log cancellation reason
      await _firestore.collection('ride_cancellations').add({
        'rideId': rideId,
        'driverId': FirebaseAuth.instance.currentUser?.uid,
        'reason': reason,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to cancel ride: $e');
    }
  }

  // Get driver profile
  Future<Map<String, dynamic>?> getDriverProfile() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return null;

      final doc = await _firestore.collection(_driversCollection).doc(currentUser.uid).get();
      return doc.exists ? doc.data() : null;
    } catch (e) {
      throw Exception('Failed to get driver profile: $e');
    }
  }

  // Update driver profile
  Future<void> updateDriverProfile(Map<String, dynamic> profileData) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      await _firestore.collection(_driversCollection).doc(currentUser.uid).set({
        ...profileData,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to update driver profile: $e');
    }
  }

  // Start earning session (driver goes online)
  Future<void> startEarning() async {
    try {
      await updateDriverStatus(DriverStatus.online);
      
      // Log earning session start
      await _firestore.collection('earning_sessions').add({
        'driverId': FirebaseAuth.instance.currentUser?.uid,
        'startTime': FieldValue.serverTimestamp(),
        'status': 'active',
      });
    } catch (e) {
      throw Exception('Failed to start earning: $e');
    }
  }

  // Stop earning session (driver goes offline)
  Future<void> stopEarning() async {
    try {
      await updateDriverStatus(DriverStatus.offline);
      
      // Update earning session end time
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final sessions = await _firestore
            .collection('earning_sessions')
            .where('driverId', isEqualTo: currentUser.uid)
            .where('status', isEqualTo: 'active')
            .get();
        
        for (final session in sessions.docs) {
          await session.reference.update({
            'endTime': FieldValue.serverTimestamp(),
            'status': 'completed',
          });
        }
      }
    } catch (e) {
      throw Exception('Failed to stop earning: $e');
    }
  }
} 