import 'package:equatable/equatable.dart';

import 'location.dart';

/// Ride status enumeration
enum RideStatus {
  requested,    // Rider has requested a ride
  pending,      // Waiting for driver acceptance
  accepted,     // Driver has accepted the ride
  driverEnRoute, // Driver is on the way to pickup
  arrived,      // Driver has arrived at pickup location
  inProgress,   // Ride is currently in progress
  completed,    // Ride has been completed successfully
  cancelled,    // Ride was cancelled
  expired,      // Ride request expired without acceptance
}

/// Core Ride entity for the Hopin app
class Ride extends Equatable {
  const Ride({
    required this.id,
    required this.riderId,
    required this.pickupLocation,
    required this.destinationLocation,
    required this.scheduledTime,
    required this.status,
    required this.requestedSeats,
    required this.createdAt,
    this.driverId,
    this.estimatedPrice,
    this.finalPrice,
    this.estimatedDuration,
    this.actualDuration,
    this.distance,
    this.notes,
    this.emergencyContact,
    this.isEmergency = false,
    this.acceptedAt,
    this.startedAt,
    this.completedAt,
    this.cancelledAt,
    this.cancellationReason,
    this.driverRating,
    this.riderRating,
  });

  final String id;
  final String riderId;
  final String? driverId;
  final Location pickupLocation;
  final Location destinationLocation;
  final DateTime scheduledTime;
  final RideStatus status;
  final int requestedSeats;
  final DateTime createdAt;
  final double? estimatedPrice;
  final double? finalPrice;
  final int? estimatedDuration; // in minutes
  final int? actualDuration; // in minutes
  final double? distance; // in kilometers
  final String? notes;
  final String? emergencyContact;
  final bool isEmergency;
  final DateTime? acceptedAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  final String? cancellationReason;
  final double? driverRating;
  final double? riderRating;

  /// Check if ride has been assigned to a driver
  bool get hasDriver => driverId != null;

  /// Check if ride is active (in progress or accepted)
  bool get isActive => status == RideStatus.accepted || 
                      status == RideStatus.driverEnRoute ||
                      status == RideStatus.arrived ||
                      status == RideStatus.inProgress;

  /// Check if ride can be cancelled
  bool get canBeCancelled => status == RideStatus.requested ||
                            status == RideStatus.pending ||
                            status == RideStatus.accepted ||
                            status == RideStatus.driverEnRoute;

  /// Check if ride is completed
  bool get isCompleted => status == RideStatus.completed;

  /// Check if ride is cancelled
  bool get isCancelled => status == RideStatus.cancelled;

  /// Check if ride needs rating
  bool get needsRating => isCompleted && (driverRating == null || riderRating == null);

  /// Get status display text
  String get statusText {
    switch (status) {
      case RideStatus.requested:
        return 'Requested';
      case RideStatus.pending:
        return 'Looking for driver...';
      case RideStatus.accepted:
        return 'Driver assigned';
      case RideStatus.driverEnRoute:
        return 'Driver on the way';
      case RideStatus.arrived:
        return 'Driver has arrived';
      case RideStatus.inProgress:
        return 'In progress';
      case RideStatus.completed:
        return 'Completed';
      case RideStatus.cancelled:
        return 'Cancelled';
      case RideStatus.expired:
        return 'Expired';
    }
  }

  /// Get ride duration in minutes
  int? get durationMinutes {
    if (startedAt != null && completedAt != null) {
      return completedAt!.difference(startedAt!).inMinutes;
    }
    return estimatedDuration;
  }

  /// Calculate estimated price based on distance
  double calculateEstimatedPrice(double basePricePerKm) {
    if (distance == null) return 0.0;
    
    // Base calculation: distance * price per km
    double price = distance! * basePricePerKm;
    
    // Minimum price of R10
    if (price < 10.0) price = 10.0;
    
    // Round to nearest rand
    return price.roundToDouble();
  }

  /// Copy with method for immutable updates
  Ride copyWith({
    String? id,
    String? riderId,
    String? driverId,
    Location? pickupLocation,
    Location? destinationLocation,
    DateTime? scheduledTime,
    RideStatus? status,
    int? requestedSeats,
    DateTime? createdAt,
    double? estimatedPrice,
    double? finalPrice,
    int? estimatedDuration,
    int? actualDuration,
    double? distance,
    String? notes,
    String? emergencyContact,
    bool? isEmergency,
    DateTime? acceptedAt,
    DateTime? startedAt,
    DateTime? completedAt,
    DateTime? cancelledAt,
    String? cancellationReason,
    double? driverRating,
    double? riderRating,
  }) {
    return Ride(
      id: id ?? this.id,
      riderId: riderId ?? this.riderId,
      driverId: driverId ?? this.driverId,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      destinationLocation: destinationLocation ?? this.destinationLocation,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      status: status ?? this.status,
      requestedSeats: requestedSeats ?? this.requestedSeats,
      createdAt: createdAt ?? this.createdAt,
      estimatedPrice: estimatedPrice ?? this.estimatedPrice,
      finalPrice: finalPrice ?? this.finalPrice,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      actualDuration: actualDuration ?? this.actualDuration,
      distance: distance ?? this.distance,
      notes: notes ?? this.notes,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      isEmergency: isEmergency ?? this.isEmergency,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      driverRating: driverRating ?? this.driverRating,
      riderRating: riderRating ?? this.riderRating,
    );
  }

  @override
  List<Object?> get props => [
        id,
        riderId,
        driverId,
        pickupLocation,
        destinationLocation,
        scheduledTime,
        status,
        requestedSeats,
        createdAt,
        estimatedPrice,
        finalPrice,
        estimatedDuration,
        actualDuration,
        distance,
        notes,
        emergencyContact,
        isEmergency,
        acceptedAt,
        startedAt,
        completedAt,
        cancelledAt,
        cancellationReason,
        driverRating,
        riderRating,
      ];

  @override
  String toString() {
    return 'Ride(id: $id, status: $status, from: ${pickupLocation.displayName}, to: ${destinationLocation.displayName})';
  }
} 