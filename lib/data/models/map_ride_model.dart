import 'package:equatable/equatable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Model representing a ride available on the map
class MapRideModel extends Equatable {
  final String id;
  final String driverId;
  final String driverName;
  final String driverPhoto;
  final String university;
  final LatLng pickupLocation;
  final LatLng destinationLocation;
  final String pickupAddress;
  final String destinationAddress;
  final DateTime departureTime;
  final int availableSeats;
  final double price;
  final double rating;
  final int totalRides;
  final bool isVerified;
  final String carModel;
  final String carColor;
  final RideStatus status;

  const MapRideModel({
    required this.id,
    required this.driverId,
    required this.driverName,
    required this.driverPhoto,
    required this.university,
    required this.pickupLocation,
    required this.destinationLocation,
    required this.pickupAddress,
    required this.destinationAddress,
    required this.departureTime,
    required this.availableSeats,
    required this.price,
    required this.rating,
    required this.totalRides,
    required this.isVerified,
    required this.carModel,
    required this.carColor,
    required this.status,
  });

  @override
  List<Object?> get props => [
        id,
        driverId,
        driverName,
        driverPhoto,
        university,
        pickupLocation,
        destinationLocation,
        pickupAddress,
        destinationAddress,
        departureTime,
        availableSeats,
        price,
        rating,
        totalRides,
        isVerified,
        carModel,
        carColor,
        status,
      ];

  /// Creates a copy with modified fields
  MapRideModel copyWith({
    String? id,
    String? driverId,
    String? driverName,
    String? driverPhoto,
    String? university,
    LatLng? pickupLocation,
    LatLng? destinationLocation,
    String? pickupAddress,
    String? destinationAddress,
    DateTime? departureTime,
    int? availableSeats,
    double? price,
    double? rating,
    int? totalRides,
    bool? isVerified,
    String? carModel,
    String? carColor,
    RideStatus? status,
  }) {
    return MapRideModel(
      id: id ?? this.id,
      driverId: driverId ?? this.driverId,
      driverName: driverName ?? this.driverName,
      driverPhoto: driverPhoto ?? this.driverPhoto,
      university: university ?? this.university,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      destinationLocation: destinationLocation ?? this.destinationLocation,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      destinationAddress: destinationAddress ?? this.destinationAddress,
      departureTime: departureTime ?? this.departureTime,
      availableSeats: availableSeats ?? this.availableSeats,
      price: price ?? this.price,
      rating: rating ?? this.rating,
      totalRides: totalRides ?? this.totalRides,
      isVerified: isVerified ?? this.isVerified,
      carModel: carModel ?? this.carModel,
      carColor: carColor ?? this.carColor,
      status: status ?? this.status,
    );
  }

  /// Time until departure in minutes
  int get minutesUntilDeparture {
    final now = DateTime.now();
    final difference = departureTime.difference(now);
    return difference.inMinutes;
  }

  /// Formatted departure time
  String get formattedDepartureTime {
    final now = DateTime.now();
    final difference = departureTime.difference(now);
    
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}min';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ${difference.inMinutes % 60}min';
    } else {
      return '${departureTime.day}/${departureTime.month}';
    }
  }

  /// Formatted price in Rands
  String get formattedPrice => 'R${price.toStringAsFixed(0)}';

  /// Formatted rating
  String get formattedRating => rating.toStringAsFixed(1);
}

/// Enum for ride status
enum RideStatus {
  available,
  departing,
  inProgress,
  completed,
  cancelled,
}

/// Extension for ride status
extension RideStatusExtension on RideStatus {
  String get displayName {
    switch (this) {
      case RideStatus.available:
        return 'Available';
      case RideStatus.departing:
        return 'Departing Soon';
      case RideStatus.inProgress:
        return 'In Progress';
      case RideStatus.completed:
        return 'Completed';
      case RideStatus.cancelled:
        return 'Cancelled';
    }
  }

  bool get isAvailable => this == RideStatus.available || this == RideStatus.departing;
} 