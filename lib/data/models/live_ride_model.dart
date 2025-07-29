import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../domain/entities/live_ride.dart';

/// LiveRideModel - Data model for Firestore persistence of LiveRide entities
/// 
/// Handles serialization/deserialization between Firebase and domain entities
/// with proper error handling and data validation
class LiveRideModel {
  final String id;
  final String driverId;
  final String driverName;
  final String driverAvatarUrl;
  final double? driverRating;
  final GeoPoint startLocation;
  final GeoPoint destination;
  final GeoPoint currentLocation;
  final int availableSeats;
  final int totalSeats;
  final double pricePerSeat;
  final bool isActive;
  final Timestamp createdAt;
  final Timestamp? startedAt;
  final Timestamp? completedAt;
  final List<Map<String, dynamic>> passengers;
  final String? notes;
  final double? speed;
  final double? heading;
  final Timestamp? lastUpdated;
  final String status;
  final String? cancellationReason;

  const LiveRideModel({
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
    required this.status,
    this.cancellationReason,
  });

  /// Create model from Firestore document
  factory LiveRideModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return LiveRideModel(
      id: doc.id,
      driverId: data['driverId'] as String,
      driverName: data['driverName'] as String,
      driverAvatarUrl: data['driverAvatarUrl'] as String,
      driverRating: data['driverRating']?.toDouble(),
      startLocation: data['startLocation'] as GeoPoint,
      destination: data['destination'] as GeoPoint,
      currentLocation: data['currentLocation'] as GeoPoint,
      availableSeats: (data['availableSeats'] as num).toInt(),
      totalSeats: (data['totalSeats'] as num).toInt(),
      pricePerSeat: (data['pricePerSeat'] as num).toDouble(),
      isActive: data['isActive'] as bool? ?? false,
      createdAt: data['createdAt'] as Timestamp,
      startedAt: data['startedAt'] as Timestamp?,
      completedAt: data['completedAt'] as Timestamp?,
      passengers: List<Map<String, dynamic>>.from(data['passengers'] ?? []),
      notes: data['notes'] as String?,
      speed: data['speed']?.toDouble(),
      heading: data['heading']?.toDouble(),
      lastUpdated: data['lastUpdated'] as Timestamp?,
      status: data['status'] as String? ?? 'active',
      cancellationReason: data['cancellationReason'] as String?,
    );
  }

  /// Create model from domain entity
  factory LiveRideModel.fromEntity(LiveRide entity) {
    return LiveRideModel(
      id: entity.id,
      driverId: entity.driverId,
      driverName: entity.driverName,
      driverAvatarUrl: entity.driverAvatarUrl,
      driverRating: entity.driverRating,
      startLocation: GeoPoint(
        entity.startLocation.latitude,
        entity.startLocation.longitude,
      ),
      destination: GeoPoint(
        entity.destination.latitude,
        entity.destination.longitude,
      ),
      currentLocation: GeoPoint(
        entity.currentLocation.latitude,
        entity.currentLocation.longitude,
      ),
      availableSeats: entity.availableSeats,
      totalSeats: entity.totalSeats,
      pricePerSeat: entity.pricePerSeat,
      isActive: entity.isActive,
      createdAt: Timestamp.fromDate(entity.createdAt),
      startedAt: entity.startedAt != null ? Timestamp.fromDate(entity.startedAt!) : null,
      completedAt: entity.completedAt != null ? Timestamp.fromDate(entity.completedAt!) : null,
      passengers: entity.passengers.map((p) => {
        'id': p.id,
        'name': p.name,
        'avatarUrl': p.avatarUrl,
        'rating': p.rating,
        'bookedAt': Timestamp.fromDate(p.bookedAt),
        'notes': p.notes,
      }).toList(),
      notes: entity.notes,
      speed: entity.speed,
      heading: entity.heading,
      lastUpdated: entity.lastUpdated != null ? Timestamp.fromDate(entity.lastUpdated!) : null,
      status: entity.status,
      cancellationReason: entity.cancellationReason,
    );
  }

  /// Convert to domain entity
  LiveRide toEntity() {
    return LiveRide(
      id: id,
      driverId: driverId,
      driverName: driverName,
      driverAvatarUrl: driverAvatarUrl,
      driverRating: driverRating,
      startLocation: LatLng(startLocation.latitude, startLocation.longitude),
      destination: LatLng(destination.latitude, destination.longitude),
      currentLocation: LatLng(currentLocation.latitude, currentLocation.longitude),
      availableSeats: availableSeats,
      totalSeats: totalSeats,
      pricePerSeat: pricePerSeat,
      isActive: isActive,
      createdAt: createdAt.toDate(),
      startedAt: startedAt?.toDate(),
      completedAt: completedAt?.toDate(),
      passengers: passengers.map((p) => RidePassenger(
        id: p['id'] as String,
        name: p['name'] as String,
        avatarUrl: p['avatarUrl'] as String,
        rating: p['rating']?.toDouble(),
        bookedAt: (p['bookedAt'] as Timestamp).toDate(),
        notes: p['notes'] as String?,
      )).toList(),
      notes: notes,
      speed: speed,
      heading: heading,
      lastUpdated: lastUpdated?.toDate(),
      status: status,
      cancellationReason: cancellationReason,
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'driverId': driverId,
      'driverName': driverName,
      'driverAvatarUrl': driverAvatarUrl,
      'driverRating': driverRating,
      'startLocation': startLocation,
      'destination': destination,
      'currentLocation': currentLocation,
      'availableSeats': availableSeats,
      'totalSeats': totalSeats,
      'pricePerSeat': pricePerSeat,
      'isActive': isActive,
      'createdAt': createdAt,
      'startedAt': startedAt,
      'completedAt': completedAt,
      'passengers': passengers,
      'notes': notes,
      'speed': speed,
      'heading': heading,
      'lastUpdated': lastUpdated,
      'status': status,
      'cancellationReason': cancellationReason,
    };
  }

  /// Create a copy with updated fields
  LiveRideModel copyWith({
    String? id,
    String? driverId,
    String? driverName,
    String? driverAvatarUrl,
    double? driverRating,
    GeoPoint? startLocation,
    GeoPoint? destination,
    GeoPoint? currentLocation,
    int? availableSeats,
    int? totalSeats,
    double? pricePerSeat,
    bool? isActive,
    Timestamp? createdAt,
    Timestamp? startedAt,
    Timestamp? completedAt,
    List<Map<String, dynamic>>? passengers,
    String? notes,
    double? speed,
    double? heading,
    Timestamp? lastUpdated,
    String? status,
    String? cancellationReason,
  }) {
    return LiveRideModel(
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
}