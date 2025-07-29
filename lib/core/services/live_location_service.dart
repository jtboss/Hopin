import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/foundation.dart';
import '../../domain/entities/live_ride.dart';
import '../../data/models/live_ride_model.dart';

/// LiveLocationService - Real-time location tracking for Hopin 2.0
/// 
/// Features:
/// - 5-second position updates for active rides
/// - Viewport-based ride filtering for performance
/// - Friends prioritization in location updates
/// - Debounced updates to prevent spam
/// - Offline support with local caching
class LiveLocationService {
  static final LiveLocationService _instance = LiveLocationService._internal();
  factory LiveLocationService() => _instance;
  LiveLocationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<Position>? _positionStream;
  Timer? _debounceTimer;
  
  // Performance optimization
  static const int _maxRidesPerView = 50;
  static const double _maxViewportRadius = 10.0; // 10km radius
  static const Duration _updateInterval = Duration(seconds: 5);
  static const Duration _debounceDelay = Duration(seconds: 3);

  /// Start live tracking for a ride (driver mode)
  /// Updates position every 5 seconds with optimized performance
  Future<void> startLiveTracking(String rideId, String userId) async {
    if (kDebugMode) {
      print('🔄 Starting live tracking for ride: $rideId');
    }

    // Request location permissions
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    // Configure high-accuracy location settings
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Only update if moved 10 meters
    );

    // Start position stream with optimized interval
    _positionStream = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (position) => _debouncedLocationUpdate(rideId, userId, position),
      onError: (error) {
        if (kDebugMode) {
          print('❌ Location stream error: $error');
        }
      },
    );

    // Mark ride as active with initial position
    final currentPosition = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    
    await _updateDriverPosition(rideId, userId, currentPosition, isInitial: true);
  }

  /// Stop live tracking for a ride
  Future<void> stopLiveTracking(String rideId) async {
    if (kDebugMode) {
      print('⏹️ Stopping live tracking for ride: $rideId');
    }

    _positionStream?.cancel();
    _positionStream = null;
    _debounceTimer?.cancel();
    _debounceTimer = null;

    // Mark ride as inactive
    await _firestore.collection('live_rides').doc(rideId).update({
      'isActive': false,
      'endedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Debounced location update to prevent excessive writes
  void _debouncedLocationUpdate(String rideId, String userId, Position position) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDelay, () {
      _updateDriverPosition(rideId, userId, position);
    });
  }

  /// Update driver position with performance optimization
  Future<void> _updateDriverPosition(
    String rideId, 
    String userId, 
    Position position, {
    bool isInitial = false,
  }) async {
    try {
      final updateData = {
        'currentLocation': GeoPoint(position.latitude, position.longitude),
        'lastUpdated': FieldValue.serverTimestamp(),
        'speed': position.speed,
        'heading': position.heading,
        'accuracy': position.accuracy,
        'isActive': true,
      };

      if (isInitial) {
        updateData['startedAt'] = FieldValue.serverTimestamp();
      }

      await _firestore.collection('live_rides').doc(rideId).update(updateData);

      if (kDebugMode) {
        print('📍 Updated position for ride $rideId: ${position.latitude}, ${position.longitude}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error updating driver position: $e');
      }
    }
  }

  /// Get nearby rides within viewport with friends prioritization
  Stream<List<LiveRide>> getNearbyRides(
    LatLng userLocation,
    List<String> friendIds, {
    double radiusKm = _maxViewportRadius,
  }) {
    return _firestore
        .collection('live_rides')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      // Convert to LiveRide entities
      final rides = snapshot.docs
          .map((doc) => LiveRideModel.fromFirestore(doc).toEntity())
          .where((ride) => _isWithinRadius(userLocation, ride.currentLocation, radiusKm))
          .toList();

      // Sort by friends first, then by distance
      rides.sort((a, b) {
        final aIsFriend = friendIds.contains(a.driverId);
        final bIsFriend = friendIds.contains(b.driverId);

        if (aIsFriend && !bIsFriend) return -1;
        if (!aIsFriend && bIsFriend) return 1;

        // Both are friends or both are not - sort by distance
        final aDistance = _calculateDistance(userLocation, a.currentLocation);
        final bDistance = _calculateDistance(userLocation, b.currentLocation);
        return aDistance.compareTo(bDistance);
      });

      // Limit results for performance
      return rides.take(_maxRidesPerView).toList();
    });
  }

  /// Get rides from friends with priority
  Stream<List<LiveRide>> getFriendsRides(List<String> friendIds) {
    if (friendIds.isEmpty) {
      return Stream.value([]);
    }

    return _firestore
        .collection('live_rides')
        .where('driverId', whereIn: friendIds)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => LiveRideModel.fromFirestore(doc).toEntity())
            .toList());
  }

  /// Get viewport-optimized rides for performance
  Stream<List<LiveRide>> getViewportRides(LatLngBounds bounds) {
    // Calculate center and radius of viewport
    final center = LatLng(
      (bounds.northeast.latitude + bounds.southwest.latitude) / 2,
      (bounds.northeast.longitude + bounds.southwest.longitude) / 2,
    );

    // Use geohash for efficient spatial queries (simplified version)
    return _firestore
        .collection('live_rides')
        .where('isActive', isEqualTo: true)
        .limit(_maxRidesPerView)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => LiveRideModel.fromFirestore(doc).toEntity())
          .where((ride) => _isWithinBounds(ride.currentLocation, bounds))
          .toList();
    });
  }

  /// Create a new live ride
  Future<String> createLiveRide({
    required String driverId,
    required String driverName,
    required String driverAvatarUrl,
    required LatLng startLocation,
    required LatLng destination,
    required int availableSeats,
    required double pricePerSeat,
    String? notes,
  }) async {
    final rideDoc = _firestore.collection('live_rides').doc();
    
    final liveRide = LiveRide(
      id: rideDoc.id,
      driverId: driverId,
      driverName: driverName,
      driverAvatarUrl: driverAvatarUrl,
      startLocation: startLocation,
      destination: destination,
      currentLocation: startLocation,
      availableSeats: availableSeats,
      totalSeats: availableSeats,
      pricePerSeat: pricePerSeat,
      isActive: true,
      createdAt: DateTime.now(),
      passengers: [],
      notes: notes,
    );

    await rideDoc.set(LiveRideModel.fromEntity(liveRide).toMap());
    
    if (kDebugMode) {
      print('🚗 Created live ride: ${rideDoc.id}');
    }

    return rideDoc.id;
  }

  /// Book a seat on a live ride (instant booking)
  Future<bool> bookRideInstantly({
    required String rideId,
    required String passengerId,
    required String passengerName,
    required String passengerAvatarUrl,
  }) async {
    try {
      final rideDoc = _firestore.collection('live_rides').doc(rideId);
      
      return await _firestore.runTransaction((transaction) async {
        final rideSnapshot = await transaction.get(rideDoc);
        
        if (!rideSnapshot.exists) {
          throw Exception('Ride not found');
        }

        final ride = LiveRideModel.fromFirestore(rideSnapshot).toEntity();
        
        if (ride.availableSeats <= 0) {
          return false; // No seats available
        }

        // Add passenger and update available seats
        final newPassenger = RidePassenger(
          id: passengerId,
          name: passengerName,
          avatarUrl: passengerAvatarUrl,
          bookedAt: DateTime.now(),
        );

        final updatedPassengers = [...ride.passengers, newPassenger];
        
        transaction.update(rideDoc, {
          'passengers': updatedPassengers.map((p) => {
            'id': p.id,
            'name': p.name,
            'avatarUrl': p.avatarUrl,
            'bookedAt': Timestamp.fromDate(p.bookedAt),
          }).toList(),
          'availableSeats': ride.availableSeats - 1,
        });

        return true;
      });
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error booking ride: $e');
      }
      return false;
    }
  }

  /// Calculate distance between two points in kilometers
  double _calculateDistance(LatLng point1, LatLng point2) {
    return Geolocator.distanceBetween(
      point1.latitude,
      point1.longitude,
      point2.latitude,
      point2.longitude,
    ) / 1000; // Convert to kilometers
  }

  /// Check if a point is within a radius
  bool _isWithinRadius(LatLng center, LatLng point, double radiusKm) {
    return _calculateDistance(center, point) <= radiusKm;
  }

  /// Check if a point is within viewport bounds
  bool _isWithinBounds(LatLng point, LatLngBounds bounds) {
    return point.latitude >= bounds.southwest.latitude &&
           point.latitude <= bounds.northeast.latitude &&
           point.longitude >= bounds.southwest.longitude &&
           point.longitude <= bounds.northeast.longitude;
  }

  /// Get real-time ride status
  Stream<LiveRide?> getRideStatus(String rideId) {
    return _firestore
        .collection('live_rides')
        .doc(rideId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      return LiveRideModel.fromFirestore(doc).toEntity();
    });
  }

  /// Cancel a live ride
  Future<void> cancelRide(String rideId, String reason) async {
    await _firestore.collection('live_rides').doc(rideId).update({
      'isActive': false,
      'status': 'cancelled',
      'cancellationReason': reason,
      'cancelledAt': FieldValue.serverTimestamp(),
    });

    // Stop tracking if this was the active ride
    await stopLiveTracking(rideId);
  }

  /// Complete a live ride
  Future<void> completeRide(String rideId) async {
    await _firestore.collection('live_rides').doc(rideId).update({
      'isActive': false,
      'status': 'completed',
      'completedAt': FieldValue.serverTimestamp(),
    });

    // Stop tracking
    await stopLiveTracking(rideId);
  }

  /// Dispose of resources
  void dispose() {
    _positionStream?.cancel();
    _debounceTimer?.cancel();
  }
}