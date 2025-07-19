import 'dart:math' as math;

import 'package:equatable/equatable.dart';

/// Location entity for handling geographic coordinates and addresses
class Location extends Equatable {
  const Location({
    required this.latitude,
    required this.longitude,
    required this.address,
    this.landmark,
    this.city,
    this.province,
    this.postalCode,
    this.country = 'South Africa',
  });

  final double latitude;
  final double longitude;
  final String address;
  final String? landmark;
  final String? city;
  final String? province;
  final String? postalCode;
  final String country;

  /// Get a short display name for the location
  String get displayName {
    if (landmark != null && landmark!.isNotEmpty) {
      return landmark!;
    }
    
    // Try to get a meaningful part of the address
    final addressParts = address.split(',');
    if (addressParts.isNotEmpty) {
      return addressParts.first.trim();
    }
    
    return address;
  }

  /// Get a full display address
  String get fullAddress {
    final parts = <String>[];
    
    parts.add(address);
    
    if (city != null && city!.isNotEmpty) {
      parts.add(city!);
    }
    
    if (province != null && province!.isNotEmpty) {
      parts.add(province!);
    }
    
    return parts.join(', ');
  }

  /// Calculate distance to another location in kilometers
  double distanceTo(Location other) {
    const double earthRadiusKm = 6371.0;
    
    final double lat1Rad = latitude * (3.14159265359 / 180.0);
    final double lat2Rad = other.latitude * (3.14159265359 / 180.0);
    final double deltaLatRad = (other.latitude - latitude) * (3.14159265359 / 180.0);
    final double deltaLngRad = (other.longitude - longitude) * (3.14159265359 / 180.0);

    final double a = (deltaLatRad / 2).sin() * (deltaLatRad / 2).sin() +
        lat1Rad.cos() * lat2Rad.cos() *
        (deltaLngRad / 2).sin() * (deltaLngRad / 2).sin();
    
    final double c = 2 * a.sqrt().asin();
    
    return earthRadiusKm * c;
  }

  /// Check if location is within a certain radius of another location
  bool isWithinRadius(Location other, double radiusKm) {
    return distanceTo(other) <= radiusKm;
  }

  /// Create a location with updated coordinates
  Location copyWith({
    double? latitude,
    double? longitude,
    String? address,
    String? landmark,
    String? city,
    String? province,
    String? postalCode,
    String? country,
  }) {
    return Location(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      landmark: landmark ?? this.landmark,
      city: city ?? this.city,
      province: province ?? this.province,
      postalCode: postalCode ?? this.postalCode,
      country: country ?? this.country,
    );
  }

  @override
  List<Object?> get props => [
        latitude,
        longitude,
        address,
        landmark,
        city,
        province,
        postalCode,
        country,
      ];

  @override
  String toString() {
    return 'Location(lat: $latitude, lng: $longitude, address: $address)';
  }
}

/// Extension for common math operations
extension MathExtensions on double {
  double sin() => math.sin(this);
  double cos() => math.cos(this);
  double asin() => math.asin(this);
  double sqrt() => math.sqrt(this);
} 