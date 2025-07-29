import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../theme/app_theme.dart';

/// InstantRideCreator - 3-second ride creation widget
/// 
/// This widget embodies the "3-second rule" - any core action takes ≤3 seconds.
/// Designed with Snapchat-style interactions and Apple-level polish.
/// 
/// Features:
/// - Visual seat selector with tap gestures
/// - Destination picker with smart predictions
/// - One-tap publish with instant feedback
/// - Real-time performance tracking
/// - Haptic feedback for every interaction
class InstantRideCreator extends StatefulWidget {
  final LatLng startLocation;
  final Function({
    required LatLng startLocation,
    required LatLng destination,
    required int seats,
    required double price,
    String? notes,
  }) onCreateRide;

  const InstantRideCreator({
    super.key,
    required this.startLocation,
    required this.onCreateRide,
  });

  @override
  State<InstantRideCreator> createState() => _InstantRideCreatorState();
}

class _InstantRideCreatorState extends State<InstantRideCreator>
    with TickerProviderStateMixin {
  // State management
  int _selectedSeats = 2;
  LatLng? _selectedDestination;
  String? _destinationName;
  double _pricePerSeat = 25.0;
  bool _isCreating = false;
  
  // Animation controllers
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;
  
  // Performance tracking
  final Stopwatch _creationTimer = Stopwatch();
  
  // Popular destinations (university-specific)
  final List<Map<String, dynamic>> _popularDestinations = [
    {
      'name': 'University Library',
      'location': const LatLng(-26.1929, 28.0305),
      'icon': '📚',
    },
    {
      'name': 'Main Campus',
      'location': const LatLng(-26.1906, 28.0305),
      'icon': '🏫',
    },
    {
      'name': 'Student Residence',
      'location': const LatLng(-26.1950, 28.0280),
      'icon': '🏠',
    },
    {
      'name': 'Shopping Center',
      'location': const LatLng(-26.1800, 28.0400),
      'icon': '🛒',
    },
    {
      'name': 'Transport Hub',
      'location': const LatLng(-26.2044, 28.0456),
      'icon': '🚌',
    },
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startCreationTimer();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  /// Initialize Snapchat-style animations
  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: HopinAnimations.medium,
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: HopinAnimations.fast,
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: HopinAnimations.snapEase,
    ));

    _pulseAnimation = HopinAnimationHelpers.gestureFlash(_pulseController);

    // Start entrance animation
    _slideController.forward();
  }

  /// Start creation timer for performance tracking
  void _startCreationTimer() {
    _creationTimer.start();
  }

  /// Handle seat selection with haptic feedback
  void _selectSeats(int seats) {
    HapticFeedback.selectionClick();
    _pulseController.forward().then((_) => _pulseController.reverse());
    
    setState(() {
      _selectedSeats = seats;
    });
  }

  /// Handle destination selection
  void _selectDestination(String name, LatLng location) {
    HapticFeedback.selectionClick();
    
    setState(() {
      _destinationName = name;
      _selectedDestination = location;
    });
  }

  /// Handle price adjustment
  void _adjustPrice(double delta) {
    HapticFeedback.selectionClick();
    
    setState(() {
      _pricePerSeat = (_pricePerSeat + delta).clamp(10.0, 100.0);
    });
  }

  /// Create ride with performance tracking
  Future<void> _createRide() async {
    if (_selectedDestination == null) {
      _showError('Please select a destination');
      return;
    }

    setState(() {
      _isCreating = true;
    });

    HapticFeedback.mediumImpact();

    try {
      await widget.onCreateRide(
        startLocation: widget.startLocation,
        destination: _selectedDestination!,
        seats: _selectedSeats,
        price: _pricePerSeat,
        notes: _destinationName,
      );

      _creationTimer.stop();
      
      // Return creation time for analytics
      if (mounted) {
        Navigator.pop(context, {
          'success': true,
          'creationTime': _creationTimer.elapsedMilliseconds,
        });
      }
    } catch (e) {
      setState(() {
        _isCreating = false;
      });
      _showError('Failed to create ride: $e');
    }
  }

  /// Show error message
  void _showError(String message) {
    HapticFeedback.heavyImpact();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: HopinColors.urgentRed,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: HopinColors.background,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: HopinColors.onBackground.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: HopinColors.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Text(
                    '🚗 Create Ride',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: HopinColors.onSurface,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: HopinColors.liveGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${(_creationTimer.elapsedMilliseconds / 1000).toStringAsFixed(1)}s',
                      style: HopinTextStyles.liveIndicator.copyWith(
                        color: HopinColors.liveGreen,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Seat selector
                  _buildSeatSelector(),
                  
                  const SizedBox(height: 24),
                  
                  // Destination picker
                  _buildDestinationPicker(),
                  
                  const SizedBox(height: 24),
                  
                  // Price selector
                  _buildPriceSelector(),
                  
                  const SizedBox(height: 24),
                  
                  // Create button
                  _buildCreateButton(),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  /// Build visual seat selector
  Widget _buildSeatSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Available Seats',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: List.generate(4, (index) {
            final seatCount = index + 1;
            final isSelected = _selectedSeats == seatCount;
            
            return Expanded(
              child: GestureDetector(
                onTap: () => _selectSeats(seatCount),
                child: AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    final scale = isSelected ? _pulseAnimation.value : 1.0;
                    
                    return Transform.scale(
                      scale: scale,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? HopinColors.snapchatYellow
                              : HopinColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(15),
                          border: isSelected
                              ? Border.all(
                                  color: HopinColors.midnightBlue,
                                  width: 2,
                                )
                              : null,
                        ),
                        child: Column(
                          children: [
                            Text(
                              '$seatCount',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: isSelected 
                                    ? HopinColors.midnightBlue
                                    : HopinColors.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              seatCount == 1 ? 'seat' : 'seats',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: isSelected 
                                    ? HopinColors.midnightBlue
                                    : HopinColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  /// Build destination picker with popular locations
  Widget _buildDestinationPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Destination',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _popularDestinations.length,
            itemBuilder: (context, index) {
              final destination = _popularDestinations[index];
              final isSelected = _destinationName == destination['name'];
              
              return GestureDetector(
                onTap: () => _selectDestination(
                  destination['name'],
                  destination['location'],
                ),
                child: Container(
                  width: 120,
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? HopinColors.snapchatYellow
                        : HopinColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(15),
                    border: isSelected
                        ? Border.all(
                            color: HopinColors.midnightBlue,
                            width: 2,
                          )
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        destination['icon'],
                        style: const TextStyle(fontSize: 24),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        destination['name'],
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isSelected 
                              ? HopinColors.midnightBlue
                              : HopinColors.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Build price selector with +/- controls
  Widget _buildPriceSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Price per Seat',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            // Decrease button
            GestureDetector(
              onTap: () => _adjustPrice(-5.0),
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: HopinColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: const Icon(
                  Icons.remove,
                  color: HopinColors.onSurfaceVariant,
                ),
              ),
            ),
            
            // Price display
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: HopinColors.snapchatYellow,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  'R${_pricePerSeat.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: HopinColors.midnightBlue,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            
            // Increase button
            GestureDetector(
              onTap: () => _adjustPrice(5.0),
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: HopinColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: const Icon(
                  Icons.add,
                  color: HopinColors.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Build create ride button
  Widget _buildCreateButton() {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: _isCreating ? null : _createRide,
        style: ElevatedButton.styleFrom(
          backgroundColor: HopinColors.liveGreen,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: _isCreating
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                '🚗 Go Live',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }
}