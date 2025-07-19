import 'package:equatable/equatable.dart';

/// Model representing a ride booking
class BookingModel extends Equatable {
  final String id;
  final String rideId;
  final String riderId;
  final String riderName;
  final String riderEmail;
  final String driverId;
  final String driverName;
  final int seatsBooked;
  final double totalPrice;
  final DateTime bookingTime;
  final BookingStatus status;
  final String? specialRequests;

  const BookingModel({
    required this.id,
    required this.rideId,
    required this.riderId,
    required this.riderName,
    required this.riderEmail,
    required this.driverId,
    required this.driverName,
    required this.seatsBooked,
    required this.totalPrice,
    required this.bookingTime,
    required this.status,
    this.specialRequests,
  });

  @override
  List<Object?> get props => [
        id,
        rideId,
        riderId,
        riderName,
        riderEmail,
        driverId,
        driverName,
        seatsBooked,
        totalPrice,
        bookingTime,
        status,
        specialRequests,
      ];

  /// Creates a copy with modified fields
  BookingModel copyWith({
    String? id,
    String? rideId,
    String? riderId,
    String? riderName,
    String? riderEmail,
    String? driverId,
    String? driverName,
    int? seatsBooked,
    double? totalPrice,
    DateTime? bookingTime,
    BookingStatus? status,
    String? specialRequests,
  }) {
    return BookingModel(
      id: id ?? this.id,
      rideId: rideId ?? this.rideId,
      riderId: riderId ?? this.riderId,
      riderName: riderName ?? this.riderName,
      riderEmail: riderEmail ?? this.riderEmail,
      driverId: driverId ?? this.driverId,
      driverName: driverName ?? this.driverName,
      seatsBooked: seatsBooked ?? this.seatsBooked,
      totalPrice: totalPrice ?? this.totalPrice,
      bookingTime: bookingTime ?? this.bookingTime,
      status: status ?? this.status,
      specialRequests: specialRequests ?? this.specialRequests,
    );
  }

  /// Formatted total price in Rands
  String get formattedPrice => 'R${totalPrice.toStringAsFixed(0)}';

  /// Formatted booking time
  String get formattedBookingTime {
    final now = DateTime.now();
    final difference = now.difference(bookingTime);
    
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${bookingTime.day}/${bookingTime.month}';
    }
  }

  /// Price per seat
  double get pricePerSeat => totalPrice / seatsBooked;
}

/// Enum for booking status
enum BookingStatus {
  pending,
  confirmed,
  cancelled,
  completed,
  noShow,
}

/// Extension for booking status
extension BookingStatusExtension on BookingStatus {
  String get displayName {
    switch (this) {
      case BookingStatus.pending:
        return 'Pending';
      case BookingStatus.confirmed:
        return 'Confirmed';
      case BookingStatus.cancelled:
        return 'Cancelled';
      case BookingStatus.completed:
        return 'Completed';
      case BookingStatus.noShow:
        return 'No Show';
    }
  }

  String get description {
    switch (this) {
      case BookingStatus.pending:
        return 'Waiting for driver confirmation';
      case BookingStatus.confirmed:
        return 'Ready to ride';
      case BookingStatus.cancelled:
        return 'Booking was cancelled';
      case BookingStatus.completed:
        return 'Ride completed successfully';
      case BookingStatus.noShow:
        return 'Rider did not show up';
    }
  }

  bool get isActive => this == BookingStatus.confirmed || this == BookingStatus.pending;
  bool get canCancel => this == BookingStatus.pending || this == BookingStatus.confirmed;
} 