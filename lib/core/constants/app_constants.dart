/// Core application constants for Hopin
class AppConstants {
  static const String appName = 'Hopin';
  static const String appVersion = '1.0.0';
  
  // Firebase configuration
  static const String firebaseCollectionUsers = 'users';
  static const String firebaseCollectionRides = 'rides';
  static const String firebaseCollectionUniversities = 'universities';
  static const String firebaseCollectionVerifications = 'verifications';
  
  // University email domains for verification
  static const Map<String, String> universityDomains = {
    'sun.ac.za': 'University of Stellenbosch',
    'uct.ac.za': 'University of Cape Town',
    'tuks.co.za': 'University of Pretoria',
    'ru.ac.za': 'Rhodes University',
    'wits.ac.za': 'University of the Witwatersrand',
    'ukzn.ac.za': 'University of KwaZulu-Natal',
    'up.ac.za': 'University of Pretoria',
    'nwu.ac.za': 'North-West University',
    'unisa.ac.za': 'University of South Africa',
    'cput.ac.za': 'Cape Peninsula University of Technology',
  };
  
  // App configuration
  static const int maxRideSeats = 8;
  static const int minRideSeats = 1;
  static const double basePrice = 5.0; // R5 per km
  static const double minRideDistance = 0.5; // 500 meters minimum
  static const double maxRideDistance = 100.0; // 100km maximum
  
  // Location settings
  static const double locationAccuracy = 10.0; // meters
  static const int locationUpdateInterval = 30; // seconds
  
  // UI constants
  static const double defaultPadding = 16.0;
  static const double defaultBorderRadius = 12.0;
  static const double defaultElevation = 4.0;
  
  // Animation durations
  static const Duration shortAnimationDuration = Duration(milliseconds: 300);
  static const Duration mediumAnimationDuration = Duration(milliseconds: 500);
  static const Duration longAnimationDuration = Duration(milliseconds: 800);
  
  // Error messages
  static const String networkErrorMessage = 'Please check your internet connection';
  static const String genericErrorMessage = 'Something went wrong. Please try again.';
  static const String authErrorMessage = 'Authentication failed. Please try again.';
  static const String locationErrorMessage = 'Unable to get your location. Please enable location services.';
  
  // Success messages
  static const String registrationSuccessMessage = 'Registration successful!';
  static const String rideCreatedMessage = 'Ride request created successfully!';
  static const String rideCompletedMessage = 'Ride completed successfully!';
} 