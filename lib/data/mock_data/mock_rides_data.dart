import 'dart:math';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/map_ride_model.dart';

/// Mock ride data for development and demonstrations
/// Focused on Cape Town area with realistic university locations
class MockRidesData {
  
  /// Cape Town area center (UCT vicinity)
  static const LatLng capeTownCenter = LatLng(-33.9576, 18.4612);
  
  /// UCT Upper Campus
  static const LatLng uctUpperCampus = LatLng(-33.9577, 18.4612);
  
  /// UCT Lower Campus (Health Sciences)
  static const LatLng uctLowerCampus = LatLng(-33.9425, 18.4676);
  
  /// Stellenbosch University
  static const LatLng stellenboschUni = LatLng(-33.9333, 18.8644);
  
  /// V&A Waterfront
  static const LatLng vaWaterfront = LatLng(-33.9018, 18.4186);
  
  /// Cape Town CBD
  static const LatLng capeTownCBD = LatLng(-33.9249, 18.4241);
  
  /// Claremont (UCT residence area)
  static const LatLng claremont = LatLng(-33.9847, 18.4645);
  
  /// Rondebosch (UCT area)
  static const LatLng rondebosch = LatLng(-33.9608, 18.4841);

  /// Generate mock rides around Cape Town
  static List<MapRideModel> getMockRides() {
    final now = DateTime.now();
    
    return [
      // Ride 1: UCT to V&A Waterfront
      MapRideModel(
        id: '', // Let Firestore generate the ID
        driverId: 'driver_001',
        driverName: 'Sarah Johnson',
        driverPhoto: '👩🏽‍🎓', // Emoji placeholder for avatar
        university: 'University of Cape Town',
        pickupLocation: uctUpperCampus,
        destinationLocation: vaWaterfront,
        pickupAddress: 'UCT Upper Campus, Rondebosch',
        destinationAddress: 'V&A Waterfront, Cape Town',
        departureTime: now.add(const Duration(minutes: 15)),
        availableSeats: 3,
        price: 25.0,
        rating: 4.8,
        totalRides: 47,
        isVerified: true,
        carModel: 'Toyota Corolla',
        carColor: 'White',
        status: RideStatus.available,
      ),
      
      // Ride 2: Stellenbosch to Cape Town CBD
      MapRideModel(
        id: '', // Let Firestore generate the ID
        driverId: 'driver_002',
        driverName: 'Thabo Mthembu',
        driverPhoto: '👨🏿‍🎓',
        university: 'Stellenbosch University',
        pickupLocation: stellenboschUni,
        destinationLocation: capeTownCBD,
        pickupAddress: 'Stellenbosch University',
        destinationAddress: 'Cape Town CBD',
        departureTime: now.add(const Duration(minutes: 30)),
        availableSeats: 2,
        price: 45.0,
        rating: 4.9,
        totalRides: 73,
        isVerified: true,
        carModel: 'Honda Civic',
        carColor: 'Blue',
        status: RideStatus.available,
      ),
      
      // Ride 3: Claremont to UCT
      MapRideModel(
        id: '', // Let Firestore generate the ID
        driverId: 'driver_003',
        driverName: 'Emma van der Merwe',
        driverPhoto: '👩🏼‍🎓',
        university: 'University of Cape Town',
        pickupLocation: claremont,
        destinationLocation: uctUpperCampus,
        pickupAddress: 'Claremont Main Road',
        destinationAddress: 'UCT Upper Campus',
        departureTime: now.add(const Duration(minutes: 8)),
        availableSeats: 1,
        price: 15.0,
        rating: 4.7,
        totalRides: 32,
        isVerified: true,
        carModel: 'VW Polo',
        carColor: 'Red',
        status: RideStatus.departing,
      ),
      
      // Ride 4: UCT to Rondebosch
      MapRideModel(
        id: '', // Let Firestore generate the ID
        driverId: 'driver_004',
        driverName: 'Michael Peters',
        driverPhoto: '👨🏾‍🎓',
        university: 'University of Cape Town',
        pickupLocation: uctLowerCampus,
        destinationLocation: rondebosch,
        pickupAddress: 'UCT Health Sciences Campus',
        destinationAddress: 'Rondebosch Common',
        departureTime: now.add(const Duration(minutes: 45)),
        availableSeats: 4,
        price: 12.0,
        rating: 4.6,
        totalRides: 28,
        isVerified: true,
        carModel: 'Nissan Micra',
        carColor: 'Silver',
        status: RideStatus.available,
      ),
      
      // Ride 5: CBD to UCT
      MapRideModel(
        id: '', // Let Firestore generate the ID
        driverId: 'driver_005',
        driverName: 'Aisha Patel',
        driverPhoto: '👩🏽‍🎓',
        university: 'University of Cape Town',
        pickupLocation: capeTownCBD,
        destinationLocation: uctUpperCampus,
        pickupAddress: 'Cape Town Station',
        destinationAddress: 'UCT Jammie Plaza',
        departureTime: now.add(const Duration(hours: 1, minutes: 20)),
        availableSeats: 2,
        price: 30.0,
        rating: 4.9,
        totalRides: 89,
        isVerified: true,
        carModel: 'Mazda 3',
        carColor: 'Black',
        status: RideStatus.available,
      ),
      
      // Ride 6: V&A to Stellenbosch
      MapRideModel(
        id: '', // Let Firestore generate the ID
        driverId: 'driver_006',
        driverName: 'Daniel Botha',
        driverPhoto: '👨🏼‍🎓',
        university: 'Stellenbosch University',
        pickupLocation: vaWaterfront,
        destinationLocation: stellenboschUni,
        pickupAddress: 'V&A Waterfront Clock Tower',
        destinationAddress: 'Stellenbosch University',
        departureTime: now.add(const Duration(hours: 2)),
        availableSeats: 3,
        price: 50.0,
        rating: 4.8,
        totalRides: 55,
        isVerified: true,
        carModel: 'Ford Fiesta',
        carColor: 'Green',
        status: RideStatus.available,
      ),
      
      // Ride 7: Rondebosch to Claremont
      MapRideModel(
        id: '', // Let Firestore generate the ID
        driverId: 'driver_007',
        driverName: 'Nomsa Dlamini',
        driverPhoto: '👩🏿‍🎓',
        university: 'University of Cape Town',
        pickupLocation: rondebosch,
        destinationLocation: claremont,
        pickupAddress: 'Rondebosch Boys\' High',
        destinationAddress: 'Claremont Station',
        departureTime: now.add(const Duration(minutes: 25)),
        availableSeats: 1,
        price: 18.0,
        rating: 4.5,
        totalRides: 19,
        isVerified: true,
        carModel: 'Hyundai i20',
        carColor: 'Orange',
        status: RideStatus.available,
      ),
    ];
  }

  /// Get rides filtered by availability
  static List<MapRideModel> getAvailableRides() {
    return getMockRides().where((ride) => ride.status.isAvailable).toList();
  }

  /// Get rides departing soon (within 30 minutes)
  static List<MapRideModel> getDepartingSoonRides() {
    final rides = getMockRides();
    return rides.where((ride) {
      return ride.minutesUntilDeparture <= 30 && ride.minutesUntilDeparture > 0;
    }).toList();
  }

  /// Get rides by university
  static List<MapRideModel> getRidesByUniversity(String university) {
    return getMockRides().where((ride) => ride.university == university).toList();
  }

  /// Get rides within a radius (in kilometers) from a center point
  static List<MapRideModel> getRidesNearLocation(LatLng center, double radiusKm) {
    final rides = getMockRides();
    return rides.where((ride) {
      final distance = _calculateDistance(center, ride.pickupLocation);
      return distance <= radiusKm;
    }).toList();
  }

  /// Calculate distance between two points in kilometers using Haversine formula
  static double _calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadiusKm = 6371;
    final double dLat = _degreesToRadians(point2.latitude - point1.latitude);
    final double dLon = _degreesToRadians(point2.longitude - point1.longitude);
    
    final double lat1Rad = _degreesToRadians(point1.latitude);
    final double lat2Rad = _degreesToRadians(point2.latitude);
    
    final double a = 
        pow(sin(dLat / 2), 2) +
        pow(sin(dLon / 2), 2) * cos(lat1Rad) * cos(lat2Rad);
    
    final double c = 2 * asin(sqrt(a));
    return earthRadiusKm * c;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * (pi / 180);
  }
} 