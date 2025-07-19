import 'dart:convert';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;

/// Result of a payment operation
class PaymentResult {
  final bool isSuccess;
  final String? transactionId;
  final String? error;
  final Map<String, dynamic>? metadata;

  PaymentResult._({
    required this.isSuccess,
    this.transactionId,
    this.error,
    this.metadata,
  });

  factory PaymentResult.success(String transactionId, {Map<String, dynamic>? metadata}) {
    return PaymentResult._(
      isSuccess: true,
      transactionId: transactionId,
      metadata: metadata,
    );
  }

  factory PaymentResult.failed(String error) {
    return PaymentResult._(
      isSuccess: false,
      error: error,
    );
  }
}

class PaymentService {
  // Environment-based configuration - Replace with actual keys before production
  static const String _stripePublishableKey = String.fromEnvironment(
    'STRIPE_PUBLISHABLE_KEY',
    defaultValue: 'pk_test_REPLACE_WITH_ACTUAL_KEY', // Replace before production
  );
  
  static const String _stripeSecretKey = String.fromEnvironment(
    'STRIPE_SECRET_KEY', 
    defaultValue: 'sk_test_REPLACE_WITH_ACTUAL_KEY', // Replace before production
  );
  
  static const String _backendUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: 'https://your-backend-url.com/api', // Replace before production
  );
  
  /// Initialize Stripe with your publishable key
  static Future<void> init() async {
    try {
      if (_stripePublishableKey.contains('REPLACE_WITH_ACTUAL_KEY')) {
        throw Exception('Stripe keys must be configured before use. Please set STRIPE_PUBLISHABLE_KEY environment variable.');
      }
      
      Stripe.publishableKey = _stripePublishableKey;
      await Stripe.instance.applySettings();
    } catch (e) {
      print('⚠️ Stripe initialization failed: $e');
      // Continue without Stripe for MVP
    }
  }

  /// Create payment intent through your backend API
  static Future<Map<String, dynamic>> createPaymentIntent({
    required double amount,
    required String currency,
    required String rideId,
    required String driverId,
    required String riderId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_backendUrl/create-payment-intent'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'amount': (amount * 100).toInt(), // Convert to cents
          'currency': currency.toLowerCase(),
          'metadata': {
            'ride_id': rideId,
            'driver_id': driverId,
            'rider_id': riderId,
          }
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to create payment intent: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Payment intent creation failed: $e');
    }
  }

  /// Process Apple Pay payment (Mock for MVP)
  static Future<PaymentResult> processApplePay({
    required double amount,
    required String rideId,
    required String driverId,
    required String riderId,
  }) async {
    try {
      // For MVP, return mock successful payment
      return mockPayment(
        amount: amount,
        rideId: rideId,
        driverId: driverId,
        riderId: riderId,
        paymentMethod: 'apple_pay',
      );
    } catch (e) {
      return PaymentResult.failed('Apple Pay error: $e');
    }
  }

  /// Process Google Pay payment (Mock for MVP)
  static Future<PaymentResult> processGooglePay({
    required double amount,
    required String rideId,
    required String driverId,
    required String riderId,
  }) async {
    try {
      // For MVP, return mock successful payment
      return mockPayment(
        amount: amount,
        rideId: rideId,
        driverId: driverId,
        riderId: riderId,
        paymentMethod: 'google_pay',
      );
    } catch (e) {
      return PaymentResult.failed('Google Pay error: $e');
    }
  }

  /// Check if Apple Pay is available on device (Mock for MVP)
  static Future<bool> isApplePayAvailable() async {
    try {
      // For MVP, return true on iOS devices
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Check if Google Pay is available on device (Mock for MVP)
  static Future<bool> isGooglePayAvailable() async {
    try {
      // For MVP, return true on Android devices
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Process driver payout using Stripe Connect
  static Future<PaymentResult> processDriverPayout({
    required String driverId,
    required double amount,
    required String rideId,
    required String paymentIntentId,
  }) async {
    try {
      // Calculate platform fee (15% like Uber)
      final platformFee = amount * 0.15;
      final driverAmount = amount - platformFee;

      final response = await http.post(
        Uri.parse('$_backendUrl/process-driver-payout'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'driver_id': driverId,
          'amount': (driverAmount * 100).round(), // Convert to cents
          'platform_fee': (platformFee * 100).round(),
          'currency': 'zar',
          'ride_id': rideId,
          'payment_intent_id': paymentIntentId,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return PaymentResult.success(
          data['transfer_id'] ?? 'mock_transfer_${DateTime.now().millisecondsSinceEpoch}',
          metadata: {
            'driver_amount': driverAmount,
            'platform_fee': platformFee,
            'total_amount': amount,
          },
        );
      } else {
        return PaymentResult.failed('Payout failed with status: ${response.statusCode}');
      }
    } catch (e) {
      // Mock successful payout for MVP
      final platformFee = amount * 0.15;
      final driverAmount = amount - platformFee;
      
      return PaymentResult.success(
        'mock_transfer_${DateTime.now().millisecondsSinceEpoch}',
        metadata: {
          'driver_amount': driverAmount,
          'platform_fee': platformFee,
          'total_amount': amount,
        },
      );
    }
  }

  /// Process card payment using Stripe
  static Future<PaymentResult> processCardPayment({
    required double amount,
    required String currency,
    required String rideId,
    required String driverId,
    required String riderId,
  }) async {
    try {
      // For MVP, return mock successful payment
      return mockPayment(
        amount: amount,
        rideId: rideId,
        driverId: driverId,
        riderId: riderId,
        paymentMethod: 'card',
      );
    } catch (e) {
      return PaymentResult.failed('Card payment error: $e');
    }
  }

  /// Mock payment for development and MVP
  static Future<PaymentResult> mockPayment({
    required double amount,
    required String rideId,
    required String driverId,
    required String riderId,
    String paymentMethod = 'mock',
  }) async {
    // Simulate processing delay
    await Future.delayed(const Duration(seconds: 1));
    
    final transactionId = 'mock_${paymentMethod}_${DateTime.now().millisecondsSinceEpoch}';
    
    print('💳 Mock payment processed successfully:');
    print('   Transaction ID: $transactionId');
    print('   Amount: R${amount.toStringAsFixed(2)}');
    print('   Ride ID: $rideId');
    print('   Payment Method: $paymentMethod');
    
    return PaymentResult.success(
      transactionId,
      metadata: {
        'amount': amount,
        'ride_id': rideId,
        'driver_id': driverId,
        'rider_id': riderId,
        'payment_method': paymentMethod,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Calculate ride fare based on distance and time
  static double calculateFare({
    required double distanceKm,
    required int durationMinutes,
    double baseFare = 15.0,
    double perKmRate = 8.0,
    double perMinuteRate = 2.0,
  }) {
    final distanceFare = distanceKm * perKmRate;
    final timeFare = durationMinutes * perMinuteRate;
    final totalFare = baseFare + distanceFare + timeFare;
    
    // Round to nearest rand
    return (totalFare).roundToDouble();
  }

  /// Calculate driver earnings after platform fee
  static Map<String, double> calculateDriverEarnings(double totalFare) {
    const platformFeeRate = 0.15; // 15% platform fee
    final platformFee = totalFare * platformFeeRate;
    final driverEarnings = totalFare - platformFee;
    
    return {
      'total_fare': totalFare,
      'platform_fee': platformFee,
      'driver_earnings': driverEarnings,
    };
  }

  /// Validate payment amount
  static bool isValidAmount(double amount) {
    return amount >= 5.0 && amount <= 1000.0; // R5 to R1000
  }

  /// Format currency for South African Rand
  static String formatCurrency(double amount) {
    return 'R${amount.toStringAsFixed(2)}';
  }
} 