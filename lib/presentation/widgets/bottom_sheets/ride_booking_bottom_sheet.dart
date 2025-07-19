import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../data/models/map_ride_model.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/services/payment_service.dart';
import '../../theme/app_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../domain/entities/ride.dart' as domain;
import '../../../domain/entities/user.dart' as app_user;
import '../../../domain/entities/location.dart' as domain;
import '../../pages/ride/ride_status_screen.dart';
import 'payment_method_bottom_sheet.dart';

/// Bottom sheet for booking a ride with Apple Pay integration
class RideBookingBottomSheet extends StatefulWidget {
  final MapRideModel ride;
  final VoidCallback? onBookingComplete;

  const RideBookingBottomSheet({
    super.key,
    required this.ride,
    this.onBookingComplete,
  });

  @override
  State<RideBookingBottomSheet> createState() => _RideBookingBottomSheetState();
}

class _RideBookingBottomSheetState extends State<RideBookingBottomSheet> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _specialRequestsController = TextEditingController();
  
  int _selectedSeats = 1;
  bool _isBooking = false;
  bool _showSpecialRequests = false;
  bool _isApplePayAvailable = false;
  bool _isGooglePayAvailable = false;
  bool _isCheckingPaymentAvailability = true;

  @override
  void initState() {
    super.initState();
    _checkPaymentAvailability();
  }

  Future<void> _checkPaymentAvailability() async {
    try {
      final applePayAvailable = await PaymentService.isApplePayAvailable();
      final googlePayAvailable = await PaymentService.isGooglePayAvailable();
      
      if (mounted) {
        setState(() {
          _isApplePayAvailable = applePayAvailable;
          _isGooglePayAvailable = googlePayAvailable;
          _isCheckingPaymentAvailability = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCheckingPaymentAvailability = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _specialRequestsController.dispose();
    super.dispose();
  }

  double get _totalPrice => widget.ride.price * _selectedSeats;

  String _getPaymentButtonText() {
    if (_isApplePayAvailable) {
      return 'Pay with Apple Pay';
    } else if (_isGooglePayAvailable) {
      return 'Pay with Google Pay';
    } else {
      return 'Book Ride';
    }
  }

  Future<void> _processPayment() async {
    if (_isBooking) return;

    // Show payment method selection UI first
    final paymentResult = await _showPaymentMethodSelector();
    
    if (paymentResult == null) {
      // User cancelled payment
      return;
    }

    setState(() {
      _isBooking = true;
    });

    try {
      // Get current user ID
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('Please log in to book a ride');
      }

      if (paymentResult.isSuccess) {
        // Payment successful, create booking
        final bookingId = await _firestoreService.createBooking(
          rideId: widget.ride.id,
          seatsBooked: _selectedSeats,
          specialRequests: _specialRequestsController.text.trim().isEmpty 
              ? null 
              : _specialRequestsController.text.trim(),
        );

        if (mounted) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Payment & Booking Successful!',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text('Booking ID: ${bookingId.substring(0, 8)}...'),
                        Text('Transaction: ${paymentResult.transactionId?.substring(0, 10)}...'),
                      ],
                    ),
                  ),
                ],
              ),
              backgroundColor: HopinColors.secondary,
              duration: const Duration(seconds: 4),
            ),
          );

          // Close bottom sheet
          Navigator.pop(context);
          
          // Navigate to ride status screen
          _navigateToRideStatus();
          
          // Notify parent
          widget.onBookingComplete?.call();
        }
      } else {
        // Payment failed
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Payment failed: ${paymentResult.error}'),
                  ),
                ],
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Booking failed: $e'),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isBooking = false;
        });
      }
    }
  }

  /// Show payment method selector bottom sheet
  Future<PaymentResult?> _showPaymentMethodSelector() async {
    return await showModalBottomSheet<PaymentResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PaymentMethodBottomSheet(
        amount: _totalPrice,
        rideId: widget.ride.id,
        driverId: widget.ride.driverId,
        riderId: FirebaseAuth.instance.currentUser?.uid ?? '',
        isApplePayAvailable: _isApplePayAvailable,
        isGooglePayAvailable: _isGooglePayAvailable,
      ),
    );
  }

  void _navigateToRideStatus() {
    // Convert MapRideModel to domain entities for RideStatusScreen
    final ride = domain.Ride(
      id: widget.ride.id,
      driverId: widget.ride.driverId,
      riderId: FirebaseAuth.instance.currentUser?.uid ?? '',
      pickupLocation: domain.Location(
        latitude: widget.ride.pickupLocation.latitude,
        longitude: widget.ride.pickupLocation.longitude,
        address: widget.ride.pickupAddress,
      ),
      destinationLocation: domain.Location(
        latitude: widget.ride.destinationLocation.latitude,
        longitude: widget.ride.destinationLocation.longitude,
        address: widget.ride.destinationAddress,
      ),
      scheduledTime: widget.ride.departureTime,
      requestedSeats: _selectedSeats, // Use the number of seats user booked
      estimatedPrice: widget.ride.price,
      status: domain.RideStatus.accepted, // Ride is now booked and accepted
      createdAt: DateTime.now(),
    );

    final driver = app_user.User(
      id: widget.ride.driverId,
      name: widget.ride.driverName,
      email: '${widget.ride.driverName.toLowerCase().replaceAll(' ', '.')}@${widget.ride.university.toLowerCase().replaceAll(' ', '')}.ac.za',
      studentNumber: 'MOCK001',
      university: widget.ride.university,
      type: app_user.UserType.driver,
      verificationStatus: app_user.VerificationStatus.verified,
      createdAt: DateTime.now(),
      rating: widget.ride.rating,
      totalRides: widget.ride.totalRides,
    );

    final rider = app_user.User(
      id: FirebaseAuth.instance.currentUser?.uid ?? '',
      name: FirebaseAuth.instance.currentUser?.displayName ?? 'You',
      email: FirebaseAuth.instance.currentUser?.email ?? 'student@university.ac.za',
      studentNumber: 'MOCK002',
      university: widget.ride.university,
      type: app_user.UserType.rider,
      verificationStatus: app_user.VerificationStatus.verified,
      createdAt: DateTime.now(),
    );

    // Navigate to ride status screen
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => RideStatusScreen(
          ride: ride,
          driver: driver,
          rider: rider,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: HopinColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: HopinColors.onSurfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Header
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: HopinColors.primaryContainer,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: HopinColors.primary,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    widget.ride.driverPhoto,
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Book ride with ${widget.ride.driverName}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: HopinColors.onSurface,
                      ),
                    ),
                    Text(
                      '${widget.ride.university} • ${widget.ride.formattedRating}⭐ • ${widget.ride.totalRides} rides',
                      style: const TextStyle(
                        fontSize: 14,
                        color: HopinColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Route info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: HopinColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: HopinColors.outline.withOpacity(0.2),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: HopinColors.secondary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.ride.pickupAddress,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: HopinColors.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      width: 2,
                      height: 20,
                      margin: const EdgeInsets.only(left: 3),
                      decoration: BoxDecoration(
                        color: HopinColors.onSurfaceVariant.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                    const SizedBox(width: 18),
                    Text(
                      'Departs ${widget.ride.formattedDepartureTime}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: HopinColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: HopinColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: HopinColors.background,
                          width: 2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.ride.destinationAddress,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: HopinColors.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Seat selection
          const Text(
            'Select number of seats',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: HopinColors.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          
          Row(
            children: [
              ...List.generate(
                widget.ride.availableSeats.clamp(1, 4),
                (index) {
                  final seatNumber = index + 1;
                  final isSelected = _selectedSeats == seatNumber;
                  
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: index < widget.ride.availableSeats.clamp(1, 4) - 1 ? 8 : 0,
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _selectedSeats = seatNumber;
                            });
                            HapticFeedback.lightImpact();
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected 
                                  ? HopinColors.primary 
                                  : HopinColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected 
                                    ? HopinColors.primary 
                                    : HopinColors.outline.withOpacity(0.3),
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Text(
                              '$seatNumber seat${seatNumber > 1 ? 's' : ''}',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isSelected 
                                    ? HopinColors.onPrimary 
                                    : HopinColors.onSurface,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Special requests (optional)
          InkWell(
            onTap: () {
              setState(() {
                _showSpecialRequests = !_showSpecialRequests;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Icon(
                    _showSpecialRequests ? Icons.expand_less : Icons.expand_more,
                    color: HopinColors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Add special requests (optional)',
                    style: TextStyle(
                      fontSize: 14,
                      color: HopinColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          if (_showSpecialRequests) ...[
            const SizedBox(height: 8),
            TextField(
              controller: _specialRequestsController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'e.g., Please wait 5 minutes, I have heavy bags...',
                hintStyle: TextStyle(
                  color: HopinColors.onSurfaceVariant.withOpacity(0.7),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: HopinColors.outline.withOpacity(0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: HopinColors.primary,
                  ),
                ),
              ),
            ),
          ],
          
          const SizedBox(height: 24),
          
          // Price and Apple Pay button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: HopinColors.primaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                // Price display
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total cost',
                            style: TextStyle(
                              fontSize: 14,
                              color: HopinColors.onSurface.withOpacity(0.7),
                            ),
                          ),
                          Text(
                            'R${_totalPrice.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: HopinColors.primary,
                            ),
                          ),
                          if (_selectedSeats > 1)
                            Text(
                              'R${widget.ride.price.toStringAsFixed(0)} per seat',
                              style: TextStyle(
                                fontSize: 12,
                                color: HopinColors.onSurface.withOpacity(0.7),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Payment Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (_isBooking || _isCheckingPaymentAvailability) ? null : _processPayment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isCheckingPaymentAvailability
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : _isBooking
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.payment, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    _getPaymentButtonText(),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                  ),
                ),
              ],
            ),
          ),
          
          // Bottom padding for safe area
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
} 