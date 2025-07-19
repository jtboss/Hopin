import 'package:flutter/foundation.dart';

/// Application configuration class
/// Handles environment variables and production settings
class AppConfig {
  // Private constructor to prevent instantiation
  AppConfig._();

  /// Current environment
  static const String environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'development',
  );

  /// Debug mode flag
  static bool get isDebug => kDebugMode;

  /// Production mode flag
  static bool get isProduction => environment == 'production';

  /// Development mode flag
  static bool get isDevelopment => environment == 'development';

  // Firebase Configuration
  static const String firebaseApiKey = String.fromEnvironment(
    'FIREBASE_API_KEY',
    defaultValue: '',
  );

  static const String firebaseAppId = String.fromEnvironment(
    'FIREBASE_APP_ID',
    defaultValue: '',
  );

  static const String firebaseProjectId = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
    defaultValue: 'hopin-51e85',
  );

  // Google Maps Configuration
  static const String googleMapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: '',
  );

  // Stripe Configuration
  static const String stripePublishableKey = String.fromEnvironment(
    'STRIPE_PUBLISHABLE_KEY',
    defaultValue: '',
  );

  static const String stripeSecretKey = String.fromEnvironment(
    'STRIPE_SECRET_KEY',
    defaultValue: '',
  );

  // Backend Configuration
  static const String backendUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: 'https://your-backend-url.com/api',
  );

  // Feature Flags
  static const bool enablePayments = bool.fromEnvironment(
    'ENABLE_PAYMENTS',
    defaultValue: false,
  );

  static const bool enablePushNotifications = bool.fromEnvironment(
    'ENABLE_PUSH_NOTIFICATIONS',
    defaultValue: false,
  );

  static const bool enableAnalytics = bool.fromEnvironment(
    'ENABLE_ANALYTICS',
    defaultValue: true,
  );

  static const bool enableCrashlytics = bool.fromEnvironment(
    'ENABLE_CRASHLYTICS',
    defaultValue: true,
  );

  // Rate Limiting
  static const int maxRequestsPerMinute = int.fromEnvironment(
    'MAX_REQUESTS_PER_MINUTE',
    defaultValue: 60,
  );

  static const int maxRideRequestsPerHour = int.fromEnvironment(
    'MAX_RIDE_REQUESTS_PER_HOUR',
    defaultValue: 10,
  );

  // University Configuration
  static const String allowedUniversityDomains = String.fromEnvironment(
    'ALLOWED_UNIVERSITY_DOMAINS',
    defaultValue: 'sun.ac.za,uct.ac.za,tuks.co.za,ru.ac.za,wits.ac.za',
  );

  /// Get list of allowed university domains
  static List<String> get universityDomains => 
      allowedUniversityDomains.split(',').map((e) => e.trim()).toList();

  /// Validate configuration
  static void validateConfig() {
    final errors = <String>[];

    if (isProduction) {
      // Production validation
      if (firebaseApiKey.isEmpty) {
        errors.add('FIREBASE_API_KEY is required in production');
      }
      if (firebaseAppId.isEmpty) {
        errors.add('FIREBASE_APP_ID is required in production');
      }
      if (googleMapsApiKey.isEmpty) {
        errors.add('GOOGLE_MAPS_API_KEY is required in production');
      }
      if (enablePayments && stripePublishableKey.isEmpty) {
        errors.add('STRIPE_PUBLISHABLE_KEY is required when payments are enabled');
      }
    }

    if (errors.isNotEmpty) {
      throw Exception('Configuration errors:\n${errors.join('\n')}');
    }
  }

  /// Get configuration summary
  static Map<String, dynamic> getConfigSummary() {
    return {
      'environment': environment,
      'isDebug': isDebug,
      'isProduction': isProduction,
      'enablePayments': enablePayments,
      'enablePushNotifications': enablePushNotifications,
      'enableAnalytics': enableAnalytics,
      'enableCrashlytics': enableCrashlytics,
      'universityDomains': universityDomains.length,
      'maxRequestsPerMinute': maxRequestsPerMinute,
      'maxRideRequestsPerHour': maxRideRequestsPerHour,
    };
  }
}

/// Production readiness checker
class ProductionReadinessChecker {
  static List<String> checkReadiness() {
    final issues = <String>[];

    // Check Firebase configuration
    if (AppConfig.firebaseApiKey.isEmpty) {
      issues.add('Firebase API key not configured');
    }

    // Check Google Maps
    if (AppConfig.googleMapsApiKey.isEmpty) {
      issues.add('Google Maps API key not configured');
    }

    // Check Stripe if payments enabled
    if (AppConfig.enablePayments && AppConfig.stripePublishableKey.isEmpty) {
      issues.add('Stripe configuration incomplete');
    }

    // Check backend URL
    if (AppConfig.backendUrl.contains('your-backend-url.com')) {
      issues.add('Backend URL not configured');
    }

    return issues;
  }

  static bool get isProductionReady => checkReadiness().isEmpty;
} 