import 'package:equatable/equatable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// LiveRide entity - Represents a real-time active ride in Hopin 2.0
/// 
/// This is the core entity for the Snapchat-Uber hybrid experience,
/// containing all data needed for social features, real-time tracking,
/// and instant booking capabilities.
class LiveRide extends Equatable {
  final String id;
  final String driverId;
  final String driverName;
  final String driverAvatarUrl;
  final double? driverRating;
  final LatLng startLocation;
  final LatLng destination;
  final LatLng currentLocation;
  final int availableSeats;
  final int totalSeats;
  final double pricePerSeat;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final List<RidePassenger> passengers;
  final String? notes;
  final double? speed;
  final double? heading;
  final DateTime? lastUpdated;
  final String status; // 'active', 'completed', 'cancelled'
  final String? cancellationReason;

  const LiveRide({
    required this.id,
    required this.driverId,
    required this.driverName,
    required this.driverAvatarUrl,
    this.driverRating,
    required this.startLocation,
    required this.destination,
    required this.currentLocation,
    required this.availableSeats,
    required this.totalSeats,
    required this.pricePerSeat,
    required this.isActive,
    required this.createdAt,
    this.startedAt,
    this.completedAt,
    required this.passengers,
    this.notes,
    this.speed,
    this.heading,
    this.lastUpdated,
    this.status = 'active',
    this.cancellationReason,
  });

  /// Create a copy with updated fields
  LiveRide copyWith({
    String? id,
    String? driverId,
    String? driverName,
    String? driverAvatarUrl,
    double? driverRating,
    LatLng? startLocation,
    LatLng? destination,
    LatLng? currentLocation,
    int? availableSeats,
    int? totalSeats,
    double? pricePerSeat,
    bool? isActive,
    DateTime? createdAt,
    DateTime? startedAt,
    DateTime? completedAt,
    List<RidePassenger>? passengers,
    String? notes,
    double? speed,
    double? heading,
    DateTime? lastUpdated,
    String? status,
    String? cancellationReason,
  }) {
    return LiveRide(
      id: id ?? this.id,
      driverId: driverId ?? this.driverId,
      driverName: driverName ?? this.driverName,
      driverAvatarUrl: driverAvatarUrl ?? this.driverAvatarUrl,
      driverRating: driverRating ?? this.driverRating,
      startLocation: startLocation ?? this.startLocation,
      destination: destination ?? this.destination,
      currentLocation: currentLocation ?? this.currentLocation,
      availableSeats: availableSeats ?? this.availableSeats,
      totalSeats: totalSeats ?? this.totalSeats,
      pricePerSeat: pricePerSeat ?? this.pricePerSeat,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      passengers: passengers ?? this.passengers,
      notes: notes ?? this.notes,
      speed: speed ?? this.speed,
      heading: heading ?? this.heading,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      status: status ?? this.status,
      cancellationReason: cancellationReason ?? this.cancellationReason,
    );
  }

  /// Check if the ride has available seats
  bool get hasAvailableSeats => availableSeats > 0;

  /// Get the number of booked seats
  int get bookedSeats => passengers.length;

  /// Check if the ride is full
  bool get isFull => availableSeats == 0;

  /// Get the total earnings for this ride
  double get totalEarnings => bookedSeats * pricePerSeat;

  /// Check if a user is already a passenger
  bool hasPassenger(String userId) {
    return passengers.any((p) => p.id == userId);
  }

  /// Get ride duration in minutes (if started)
  int? get durationMinutes {
    if (startedAt == null) return null;
    final endTime = completedAt ?? DateTime.now();
    return endTime.difference(startedAt!).inMinutes;
  }

  /// Check if the ride is live and active
  bool get isLive => isActive && status == 'active';

  @override
  List<Object?> get props => [
        id,
        driverId,
        driverName,
        driverAvatarUrl,
        driverRating,
        startLocation,
        destination,
        currentLocation,
        availableSeats,
        totalSeats,
        pricePerSeat,
        isActive,
        createdAt,
        startedAt,
        completedAt,
        passengers,
        notes,
        speed,
        heading,
        lastUpdated,
        status,
        cancellationReason,
      ];
}

/// RidePassenger entity - Represents a passenger in a live ride
class RidePassenger extends Equatable {
  final String id;
  final String name;
  final String avatarUrl;
  final double? rating;
  final DateTime bookedAt;
  final String? notes;

  const RidePassenger({
    required this.id,
    required this.name,
    required this.avatarUrl,
    this.rating,
    required this.bookedAt,
    this.notes,
  });

  /// Create a copy with updated fields
  RidePassenger copyWith({
    String? id,
    String? name,
    String? avatarUrl,
    double? rating,
    DateTime? bookedAt,
    String? notes,
  }) {
    return RidePassenger(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      rating: rating ?? this.rating,
      bookedAt: bookedAt ?? this.bookedAt,
      notes: notes ?? this.notes,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        avatarUrl,
        rating,
        bookedAt,
        notes,
      ];
}