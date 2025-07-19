import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/services/payment_service.dart';
import '../../theme/app_theme.dart';

class PaymentMethodBottomSheet extends StatefulWidget {
  final double amount;
  final String rideId;
  final String driverId;
  final String riderId;
  final bool isApplePayAvailable;
  final bool isGooglePayAvailable;

  const PaymentMethodBottomSheet({
    super.key,
    required this.amount,
    required this.rideId,
    required this.driverId,
    required this.riderId,
    required this.isApplePayAvailable,
    required this.isGooglePayAvailable,
  });

  @override
  State<PaymentMethodBottomSheet> createState() => _PaymentMethodBottomSheetState();
}

class _PaymentMethodBottomSheetState extends State<PaymentMethodBottomSheet>
    with TickerProviderStateMixin {
  bool _isProcessing = false;
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value * MediaQuery.of(context).size.height),
          child: Container(
            decoration: const BoxDecoration(
              color: HopinColors.surface,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle bar
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: HopinColors.onSurfaceVariant.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Payment header
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                          style: IconButton.styleFrom(
                            backgroundColor: HopinColors.onSurfaceVariant.withOpacity(0.1),
                          ),
                        ),
                        const Expanded(
                          child: Text(
                            'Choose Payment Method',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: HopinColors.onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(width: 48), // Balance the close button
                      ],
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Payment amount
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: HopinColors.primaryContainer.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.directions_car,
                            color: HopinColors.primary,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Column(
                            children: [
                              const Text(
                                'Total Amount',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: HopinColors.onSurfaceVariant,
                                ),
                              ),
                              Text(
                                'R${widget.amount.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: HopinColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Payment methods
                    if (widget.isApplePayAvailable) ...[
                      _buildPaymentMethod(
                        icon: '🍏',
                        title: 'Apple Pay',
                        subtitle: 'Touch ID or Face ID',
                        onTap: () => _processPayment('apple_pay'),
                        color: Colors.black,
                      ),
                      const SizedBox(height: 12),
                    ],
                    
                    if (widget.isGooglePayAvailable) ...[
                      _buildPaymentMethod(
                        icon: 'G',
                        title: 'Google Pay',
                        subtitle: 'Pay with Google',
                        onTap: () => _processPayment('google_pay'),
                        color: const Color(0xFF4285F4),
                      ),
                      const SizedBox(height: 12),
                    ],
                    
                    // Card payment option
                    _buildPaymentMethod(
                      icon: '💳',
                      title: 'Credit Card',
                      subtitle: 'Visa, Mastercard, Amex',
                      onTap: () => _processPayment('card'),
                      color: HopinColors.primary,
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Cash payment option
                    _buildPaymentMethod(
                      icon: '💵',
                      title: 'Pay Driver in Cash',
                      subtitle: 'Pay the driver directly',
                      onTap: () => _processPayment('cash'),
                      color: Colors.green,
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Security note
                    Row(
                      children: [
                        Icon(
                          Icons.security,
                          size: 16,
                          color: HopinColors.onSurfaceVariant.withOpacity(0.7),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Your payment information is encrypted and secure',
                            style: TextStyle(
                              fontSize: 12,
                              color: HopinColors.onSurfaceVariant.withOpacity(0.7),
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPaymentMethod({
    required String icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isProcessing ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: HopinColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: HopinColors.outline.withOpacity(0.3),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: icon.startsWith('G')
                      ? Text(
                          icon,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        )
                      : Text(
                          icon,
                          style: const TextStyle(fontSize: 24),
                        ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: HopinColors.onSurface,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: HopinColors.onSurfaceVariant.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
              if (_isProcessing) ...[
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(HopinColors.primary),
                  ),
                ),
              ] else ...[
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: HopinColors.onSurfaceVariant.withOpacity(0.5),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _processPayment(String paymentMethod) async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    // Add haptic feedback
    HapticFeedback.lightImpact();

    try {
      PaymentResult result;
      
      switch (paymentMethod) {
        case 'apple_pay':
          result = await PaymentService.processApplePay(
            amount: widget.amount,
            rideId: widget.rideId,
            driverId: widget.driverId,
            riderId: widget.riderId,
          );
          break;
        case 'google_pay':
          result = await PaymentService.processGooglePay(
            amount: widget.amount,
            rideId: widget.rideId,
            driverId: widget.driverId,
            riderId: widget.riderId,
          );
          break;
        case 'card':
          result = await PaymentService.processCardPayment(
            amount: widget.amount,
            currency: 'ZAR',
            rideId: widget.rideId,
            driverId: widget.driverId,
            riderId: widget.riderId,
          );
          break;
        case 'cash':
          // For cash payments, create a successful result
          result = PaymentResult.success(
            'cash_${DateTime.now().millisecondsSinceEpoch}',
            metadata: {
              'amount': widget.amount,
              'ride_id': widget.rideId,
              'driver_id': widget.driverId,
              'rider_id': widget.riderId,
              'payment_method': 'cash',
              'timestamp': DateTime.now().toIso8601String(),
            },
          );
          break;
        default:
          throw Exception('Unknown payment method: $paymentMethod');
      }

      // Simulate payment processing delay
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        // Success feedback
        HapticFeedback.mediumImpact();
        
        // Close this sheet and return result
        Navigator.pop(context, result);
      }

    } catch (e) {
      if (mounted) {
        // Error feedback
        HapticFeedback.heavyImpact();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
        
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }
} 