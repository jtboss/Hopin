import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';
import '../../data/models/map_ride_model.dart';

/// Service to handle real-time map tracking and visualization
class MapTrackingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Tracking state
  final Map<String, StreamSubscription<DocumentSnapshot>> _rideSubscriptions = {};
  final Map<String, LatLng> _driverLocations = {};
  final Map<String, List<LatLng>> _routePoints = {};
  
  // Callbacks
  Function(String rideId, LatLng location)? onDriverLocationUpdate;
  Function(String rideId, RideStatus status)? onRideStatusUpdate;
  Function(Set<Marker> markers)? onMarkersUpdate;
  Function(Set<Polyline> polylines)? onPolylinesUpdate;

  /// Start tracking a ride in real-time
  Future<void> startTrackingRide(MapRideModel ride) async {
    try {
      print('🗺️ Starting real-time tracking for ride: ${ride.id}');
      
      // Listen to ride status updates
      _rideSubscriptions[ride.id] = _firestore
          .collection('rides')
          .doc(ride.id)
          .snapshots()
          .listen((snapshot) {
            if (snapshot.exists) {
              final data = snapshot.data()!;
              final status = _parseRideStatus(data['status'] ?? 'available');
              onRideStatusUpdate?.call(ride.id, status);
              
              print('📊 Ride ${ride.id} status: ${status.name}');
            }
          });

      // Listen to driver location updates
      _firestore
          .collection('driver_locations')
          .doc(ride.driverId)
          .snapshots()
          .listen((snapshot) {
            if (snapshot.exists) {
              final data = snapshot.data()!;
              final lat = data['latitude']?.toDouble();
              final lng = data['longitude']?.toDouble();
              
              if (lat != null && lng != null) {
                final location = LatLng(lat, lng);
                _driverLocations[ride.id] = location;
                onDriverLocationUpdate?.call(ride.id, location);
                
                _updateMapVisualization(ride);
                print('📍 Driver location updated: $lat, $lng');
              }
            }
          });

    } catch (e) {
      print('❌ Error starting ride tracking: $e');
    }
  }

  /// Stop tracking a ride
  void stopTrackingRide(String rideId) {
    _rideSubscriptions[rideId]?.cancel();
    _rideSubscriptions.remove(rideId);
    _driverLocations.remove(rideId);
    _routePoints.remove(rideId);
    
    print('⏹️ Stopped tracking ride: $rideId');
  }

  /// Stop all tracking
  void stopAllTracking() {
    for (final subscription in _rideSubscriptions.values) {
      subscription.cancel();
    }
    _rideSubscriptions.clear();
    _driverLocations.clear();
    _routePoints.clear();
    
    print('⏹️ Stopped all ride tracking');
  }

  /// Update map visualization with current ride data
  void _updateMapVisualization(MapRideModel ride) {
    try {
      final markers = _generateMarkers(ride);
      final polylines = _generatePolylines(ride);
      
      onMarkersUpdate?.call(markers);
      onPolylinesUpdate?.call(polylines);
    } catch (e) {
      print('❌ Error updating map visualization: $e');
    }
  }

  /// Generate markers for ride visualization
  Set<Marker> _generateMarkers(MapRideModel ride) {
    final markers = <Marker>{};

    // Pickup location marker
    markers.add(Marker(
      markerId: MarkerId('pickup_${ride.id}'),
      position: ride.pickupLocation,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      infoWindow: InfoWindow(
        title: 'Pickup Location',
        snippet: ride.pickupAddress,
      ),
    ));

    // Destination marker
    markers.add(Marker(
      markerId: MarkerId('destination_${ride.id}'),
      position: ride.destinationLocation,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      infoWindow: InfoWindow(
        title: 'Destination',
        snippet: ride.destinationAddress,
      ),
    ));

    // Driver location marker (if available and ride is active)
    final driverLocation = _driverLocations[ride.id];
    if (driverLocation != null && 
        (ride.status == RideStatus.departing || ride.status == RideStatus.inProgress)) {
      
      markers.add(Marker(
        markerId: MarkerId('driver_${ride.id}'),
        position: driverLocation,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: InfoWindow(
          title: '${ride.driverName}',
          snippet: '${ride.carModel} • ${ride.carColor}',
        ),
        // Add rotation based on movement direction if needed
      ));
    }

    return markers;
  }

  /// Generate polylines for route visualization
  Set<Polyline> _generatePolylines(MapRideModel ride) {
    final polylines = <Polyline>{};

    // Route from pickup to destination
    polylines.add(Polyline(
      polylineId: PolylineId('route_${ride.id}'),
      points: [ride.pickupLocation, ride.destinationLocation],
      color: ride.status == RideStatus.inProgress 
          ? Colors.blue.withOpacity(0.8)
          : Colors.grey.withOpacity(0.6),
      width: 4,
      patterns: ride.status == RideStatus.available 
          ? [PatternItem.dash(10), PatternItem.gap(5)]
          : [],
    ));

    // Driver trail (if driver is moving and we have route points)
    final routePoints = _routePoints[ride.id];
    final driverLocation = _driverLocations[ride.id];
    
    if (routePoints != null && 
        routePoints.isNotEmpty && 
        driverLocation != null &&
        ride.status == RideStatus.inProgress) {
      
      // Create trail showing where driver has been
      polylines.add(Polyline(
        polylineId: PolylineId('trail_${ride.id}'),
        points: [...routePoints, driverLocation],
        color: Colors.blue.withOpacity(0.8),
        width: 3,
      ));
    }

    return polylines;
  }

  /// Add a point to the driver's route trail
  void addRoutePoint(String rideId, LatLng point) {
    if (!_routePoints.containsKey(rideId)) {
      _routePoints[rideId] = [];
    }
    
    _routePoints[rideId]!.add(point);
    
    // Limit trail to last 50 points to prevent memory issues
    if (_routePoints[rideId]!.length > 50) {
      _routePoints[rideId]!.removeAt(0);
    }
  }

  /// Calculate estimated time to pickup/destination
  Future<String> calculateETA(LatLng from, LatLng to) async {
    try {
      final distance = Geolocator.distanceBetween(
        from.latitude, from.longitude,
        to.latitude, to.longitude,
      );
      
      // Simple ETA calculation (40 km/h average speed in city)
      final timeInMinutes = (distance / 1000) / 40 * 60;
      
      if (timeInMinutes < 1) {
        return 'Arriving now';
      } else if (timeInMinutes < 60) {
        return '${timeInMinutes.round()} min';
      } else {
        final hours = (timeInMinutes / 60).floor();
        final minutes = (timeInMinutes % 60).round();
        return '${hours}h ${minutes}m';
      }
    } catch (e) {
      return 'Unknown';
    }
  }

  /// Get camera position to show entire route
  CameraPosition getCameraPositionForRide(MapRideModel ride) {
    final bounds = _calculateBounds([
      ride.pickupLocation,
      ride.destinationLocation,
      if (_driverLocations[ride.id] != null) _driverLocations[ride.id]!,
    ]);

    return CameraPosition(
      target: bounds.center,
      zoom: _calculateZoomLevel(bounds),
    );
  }

  /// Calculate bounds for a list of coordinates
  LatLngBounds _calculateBounds(List<LatLng> coordinates) {
    double minLat = coordinates.first.latitude;
    double maxLat = coordinates.first.latitude;
    double minLng = coordinates.first.longitude;
    double maxLng = coordinates.first.longitude;

    for (final coord in coordinates) {
      minLat = min(minLat, coord.latitude);
      maxLat = max(maxLat, coord.latitude);
      minLng = min(minLng, coord.longitude);
      maxLng = max(maxLng, coord.longitude);
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  /// Calculate appropriate zoom level for bounds
  double _calculateZoomLevel(LatLngBounds bounds) {
    final distance = Geolocator.distanceBetween(
      bounds.southwest.latitude,
      bounds.southwest.longitude,
      bounds.northeast.latitude,
      bounds.northeast.longitude,
    );

    if (distance < 1000) return 16; // Very close
    if (distance < 5000) return 14; // Close
    if (distance < 10000) return 13; // Medium
    if (distance < 25000) return 12; // Far
    return 11; // Very far
  }

  /// Parse ride status from string
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

  /// Cleanup resources
  void dispose() {
    stopAllTracking();
  }
}

/// Extension to get center of LatLngBounds
extension LatLngBoundsExtension on LatLngBounds {
  LatLng get center {
    return LatLng(
      (southwest.latitude + northeast.latitude) / 2,
      (southwest.longitude + northeast.longitude) / 2,
    );
  }
} 