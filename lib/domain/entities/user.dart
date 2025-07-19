import 'package:equatable/equatable.dart';

/// User types in the Hopin app
enum UserType { rider, driver, both }

/// Verification status for student accounts
enum VerificationStatus { pending, verified, rejected, expired }

/// Core User entity for the Hopin app
class User extends Equatable {
  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.studentNumber,
    required this.university,
    required this.type,
    required this.verificationStatus,
    required this.createdAt,
    this.profileImageUrl,
    this.phoneNumber,
    this.dateOfBirth,
    this.emergencyContact,
    this.emergencyContactNumber,
    this.rating = 0.0,
    this.totalRides = 0,
    this.isActive = true,
    this.lastSeen,
  });

  final String id;
  final String name;
  final String email;
  final String studentNumber;
  final String university;
  final UserType type;
  final VerificationStatus verificationStatus;
  final DateTime createdAt;
  final String? profileImageUrl;
  final String? phoneNumber;
  final DateTime? dateOfBirth;
  final String? emergencyContact;
  final String? emergencyContactNumber;
  final double rating;
  final int totalRides;
  final bool isActive;
  final DateTime? lastSeen;

  /// Check if user is verified
  bool get isVerified => verificationStatus == VerificationStatus.verified;

  /// Check if user can drive
  bool get canDrive => type == UserType.driver || type == UserType.both;

  /// Check if user can request rides
  bool get canRide => type == UserType.rider || type == UserType.both;

  /// Get university domain from email
  String get universityDomain {
    final emailParts = email.split('@');
    return emailParts.length > 1 ? emailParts[1] : '';
  }

  /// Copy with method for immutable updates
  User copyWith({
    String? id,
    String? name,
    String? email,
    String? studentNumber,
    String? university,
    UserType? type,
    VerificationStatus? verificationStatus,
    DateTime? createdAt,
    String? profileImageUrl,
    String? phoneNumber,
    DateTime? dateOfBirth,
    String? emergencyContact,
    String? emergencyContactNumber,
    double? rating,
    int? totalRides,
    bool? isActive,
    DateTime? lastSeen,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      studentNumber: studentNumber ?? this.studentNumber,
      university: university ?? this.university,
      type: type ?? this.type,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      createdAt: createdAt ?? this.createdAt,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      emergencyContactNumber: emergencyContactNumber ?? this.emergencyContactNumber,
      rating: rating ?? this.rating,
      totalRides: totalRides ?? this.totalRides,
      isActive: isActive ?? this.isActive,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        email,
        studentNumber,
        university,
        type,
        verificationStatus,
        createdAt,
        profileImageUrl,
        phoneNumber,
        dateOfBirth,
        emergencyContact,
        emergencyContactNumber,
        rating,
        totalRides,
        isActive,
        lastSeen,
      ];

  @override
  String toString() {
    return 'User(id: $id, name: $name, email: $email, university: $university, type: $type, verificationStatus: $verificationStatus)';
  }
} 