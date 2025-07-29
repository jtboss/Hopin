import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/services/live_location_service.dart';
import '../../../domain/entities/live_ride.dart';
import '../../theme/app_theme.dart';
import '../../widgets/map/live_ride_marker.dart';
import '../../widgets/instant_ride_creator.dart';
import '../../widgets/common/friends_toggle.dart';
import '../../widgets/common/emergency_button.dart';

/// SnapchatMapScreen - Revolutionary full-screen map experience
/// 
/// This is the "iPhone moment" for student mobility - a complete 
/// transformation from traditional ride-sharing UI to a gesture-driven,
/// social-first, map-native experience inspired by Snapchat's simplicity
/// and Uber's functionality.
/// 
/// Key Features:
/// - Full-screen map with no chrome
/// - Long-press to create rides instantly
/// - Tap avatar markers to book rides
/// - Friends prioritization with gold borders
/// - Real-time live location tracking
/// - Emergency panic button
/// - 3-second interaction rule compliance
class SnapchatMapScreen extends StatefulWidget {
  final bool isDriverMode;

  const SnapchatMapScreen({
    super.key,
    this.isDriverMode = false,
  });

  @override
  State<SnapchatMapScreen> createState() => _SnapchatMapScreenState();
}

class _SnapchatMapScreenState extends State<SnapchatMapScreen>
    with TickerProviderStateMixin {
  GoogleMapController? _mapController;
  StreamSubscription<List<LiveRide>>? _ridesSubscription;
  StreamSubscription<Position>? _locationSubscription;
  
  final LiveLocationService _liveLocationService = LiveLocationService();
  
  // State management
  List<LiveRide> _liveRides = [];
  LatLng? _currentLocation;
  bool _showFriendsOnly = false;
  bool _isMapReady = false;
  Set<Marker> _markers = {};
  
  // Animation controllers
  late AnimationController _pulseController;
  late AnimationController _fabController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _fabAnimation;
  
  // User data
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  final List<String> _friendIds = []; // TODO: Load from social service

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _requestLocationPermission();
    _startLocationTracking();
    _loadLiveRides();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _fabController.dispose();
    _ridesSubscription?.cancel();
    _locationSubscription?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  /// Initialize Snapchat-style animations
  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: HopinAnimations.slow,
      vsync: this,
    )..repeat(reverse: true);

    _fabController = AnimationController(
      duration: HopinAnimations.medium,
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: HopinAnimations.snapEase,
    ));

    _fabAnimation = HopinAnimationHelpers.quickFade(_fabController);
    _fabController.forward();
  }

  /// Request and handle location permissions
  Future<void> _requestLocationPermission() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        _showPermissionDialog();
        return;
      }

      // Get initial position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
      });

      // Move camera to user location
      if (_mapController != null) {
        await _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(_currentLocation!, 15.0),
        );
      }
    } catch (e) {
      debugPrint('❌ Location permission error: $e');
    }
  }

  /// Start real-time location tracking
  void _startLocationTracking() {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );

    _locationSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) {
      final newLocation = LatLng(position.latitude, position.longitude);
      
      if (mounted) {
        setState(() {
          _currentLocation = newLocation;
        });
      }
    });
  }

  /// Load live rides with friends prioritization
  void _loadLiveRides() {
    if (_currentLocation == null) {
      // Retry after location is available
      Future.delayed(const Duration(seconds: 1), _loadLiveRides);
      return;
    }

    _ridesSubscription = _showFriendsOnly
        ? _liveLocationService.getFriendsRides(_friendIds)
        : _liveLocationService.getNearbyRides(_currentLocation!, _friendIds);

    _ridesSubscription!.listen((rides) {
      if (mounted) {
        setState(() {
          _liveRides = rides;
          _updateMarkers();
        });
      }
    });
  }

  /// Update map markers with live rides
  void _updateMarkers() {
    final newMarkers = <Marker>{};

    for (final ride in _liveRides) {
      final isFriend = _friendIds.contains(ride.driverId);
      
      newMarkers.add(
        Marker(
          markerId: MarkerId(ride.id),
          position: ride.currentLocation,
          onTap: () => _onRideMarkerTapped(ride),
          anchor: const Offset(0.5, 0.5),
          icon: BitmapDescriptor.defaultMarker, // Custom marker in production
        ),
      );
    }

    setState(() {
      _markers = newMarkers;
    });
  }

  /// Handle map creation
  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    
    // Apply Snapchat-style map styling
    _mapController!.setMapStyle(AppTheme.snapchatMapStyle);
    
    setState(() {
      _isMapReady = true;
    });

    // Move to user location if available
    if (_currentLocation != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(_currentLocation!, 15.0),
      );
    }
  }

  /// Handle long press to create ride (3-second flow)
  void _onLongPressMap(LatLng position) async {
    if (!widget.isDriverMode) return;

    // Haptic feedback for tactile response
    HapticFeedback.mediumImpact();

    // Show instant ride creator with 3-second target
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => InstantRideCreator(
        startLocation: position,
        onCreateRide: _createRideInstantly,
      ),
    );

    if (result != null) {
      debugPrint('🚗 Ride created in ${result['creationTime']}ms');
    }
  }

  /// Handle ride marker tap for instant booking
  void _onRideMarkerTapped(LiveRide ride) async {
    if (widget.isDriverMode) return;
    if (ride.hasPassenger(_currentUserId)) return;

    // Haptic feedback
    HapticFeedback.lightImpact();

    // Show ride details with instant booking
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildRideDetailsSheet(ride),
    );
  }

  /// Create ride instantly (target: <3 seconds)
  Future<void> _createRideInstantly({
    required LatLng startLocation,
    required LatLng destination,
    required int seats,
    required double price,
    String? notes,
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      final user = FirebaseAuth.instance.currentUser!;
      
      final rideId = await _liveLocationService.createLiveRide(
        driverId: user.uid,
        driverName: user.displayName ?? 'Student Driver',
        driverAvatarUrl: user.photoURL ?? '',
        startLocation: startLocation,
        destination: destination,
        availableSeats: seats,
        pricePerSeat: price,
        notes: notes,
      );

      // Start live tracking immediately
      await _liveLocationService.startLiveTracking(rideId, user.uid);

      stopwatch.stop();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '🚗 Ride created in ${stopwatch.elapsedMilliseconds}ms',
              style: HopinTextStyles.snapchatButton,
            ),
            backgroundColor: HopinColors.liveGreen,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      stopwatch.stop();
      debugPrint('❌ Error creating ride: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create ride: $e'),
            backgroundColor: HopinColors.urgentRed,
          ),
        );
      }
    }
  }

  /// Build ride details bottom sheet
  Widget _buildRideDetailsSheet(LiveRide ride) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: HopinColors.background,
        borderRadius: BorderRadius.circular(25),
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
          
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Driver info
                Row(
                  children: [
                    CircleAvatar(
                      radius: 25,
                      backgroundColor: HopinColors.primaryContainer,
                      child: Text(
                        ride.driverName.substring(0, 1).toUpperCase(),
                        style: HopinTextStyles.rideMarkerText,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ride.driverName,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            '${ride.availableSeats} seats • R${ride.pricePerSeat.toStringAsFixed(0)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    if (_friendIds.contains(ride.driverId))
                      Icon(
                        Icons.star,
                        color: HopinColors.friendGold,
                        size: 20,
                      ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Instant book button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _bookRideInstantly(ride),
                    child: const Text('🚗 Book Instantly'),
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // View details button
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _showFullRideDetails(ride);
                    },
                    child: const Text('View Details'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Book ride instantly (target: <1 second)
  Future<void> _bookRideInstantly(LiveRide ride) async {
    final stopwatch = Stopwatch()..start();

    try {
      final user = FirebaseAuth.instance.currentUser!;
      
      final success = await _liveLocationService.bookRideInstantly(
        rideId: ride.id,
        passengerId: user.uid,
        passengerName: user.displayName ?? 'Student',
        passengerAvatarUrl: user.photoURL ?? '',
      );

      stopwatch.stop();

      if (!mounted) return;

      Navigator.pop(context);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Booked in ${stopwatch.elapsedMilliseconds}ms!',
              style: HopinTextStyles.snapchatButton,
            ),
            backgroundColor: HopinColors.liveGreen,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Ride is full or unavailable'),
            backgroundColor: HopinColors.urgentRed,
          ),
        );
      }
    } catch (e) {
      stopwatch.stop();
      debugPrint('❌ Error booking ride: $e');
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to book ride: $e'),
            backgroundColor: HopinColors.urgentRed,
          ),
        );
      }
    }
  }

  /// Show full ride details
  void _showFullRideDetails(LiveRide ride) {
    // TODO: Implement full ride details screen
    debugPrint('📱 Show full details for ride: ${ride.id}');
  }

  /// Show permission dialog
  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Permission Required'),
        content: const Text(
          'Hopin needs location access to show nearby rides and enable real-time tracking.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Geolocator.openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  /// Toggle friends-only view
  void _toggleFriendsOnly() {
    setState(() {
      _showFriendsOnly = !_showFriendsOnly;
    });
    
    // Reload rides with new filter
    _ridesSubscription?.cancel();
    _loadLiveRides();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Full-screen Google Map (no chrome)
          GoogleMap(
            onMapCreated: _onMapCreated,
            onLongPress: _onLongPressMap,
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            compassEnabled: false,
            mapToolbarEnabled: false,
            zoomControlsEnabled: false,
            initialCameraPosition: CameraPosition(
              target: _currentLocation ?? const LatLng(-26.2041, 28.0473), // Johannesburg
              zoom: 15.0,
            ),
          ),
          
          // Minimal UI overlay
          SafeArea(
            child: Column(
              children: [
                // Top bar with minimal controls
                _buildTopBar(),
                
                const Spacer(),
                
                // Bottom controls
                _buildBottomControls(),
              ],
            ),
          ),
          
          // Loading overlay
          if (!_isMapReady)
            Container(
              color: HopinColors.background,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  /// Build minimal top bar
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Friends toggle
          FriendsToggle(
            isActive: _showFriendsOnly,
            onToggle: _toggleFriendsOnly,
          ),
          
          const Spacer(),
          
          // Emergency button
          const EmergencyButton(),
        ],
      ),
    );
  }

  /// Build bottom controls
  Widget _buildBottomControls() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Live rides counter
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: HopinColors.liveGreen,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.radio_button_checked,
                        size: 12,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${_liveRides.length} LIVE',
                        style: HopinTextStyles.liveIndicator.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          
          const Spacer(),
          
          // Mode indicator
          if (widget.isDriverMode)
            FadeTransition(
              opacity: _fabAnimation,
              child: FloatingActionButton.extended(
                onPressed: null,
                backgroundColor: HopinColors.snapchatYellow,
                foregroundColor: HopinColors.midnightBlue,
                label: const Text(
                  'DRIVER MODE',
                  style: HopinTextStyles.snapchatButton,
                ),
                icon: const Icon(Icons.directions_car),
              ),
            ),
        ],
      ),
    );
  }
}