import 'package:flutter/material.dart';
import '../../../domain/entities/live_ride.dart';
import '../../theme/app_theme.dart';

/// LiveRideMarker - Snapchat-style ride marker widget
/// 
/// Represents live rides on the map with avatar-style markers,
/// friends prioritization, and real-time updates.
/// 
/// Features:
/// - Circular avatar markers with user photos
/// - Gold borders for friend rides
/// - Available seat indicators
/// - Pulsing animation for active rides
/// - Tap to book functionality
class LiveRideMarker extends StatefulWidget {
  final LiveRide ride;
  final bool isFriend;
  final VoidCallback? onTap;

  const LiveRideMarker({
    super.key,
    required this.ride,
    this.isFriend = false,
    this.onTap,
  });

  @override
  State<LiveRideMarker> createState() => _LiveRideMarkerState();
}

class _LiveRideMarkerState extends State<LiveRideMarker>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(
      begin: 0.9,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _pulseAnimation.value,
            child: Container(
              width: widget.isFriend ? 60 : 40,
              height: widget.isFriend ? 60 : 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: widget.isFriend 
                      ? HopinColors.friendGold 
                      : HopinColors.liveGreen,
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (widget.isFriend 
                        ? HopinColors.friendGold 
                        : HopinColors.liveGreen).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // User avatar
                  CircleAvatar(
                    radius: widget.isFriend ? 27 : 17,
                    backgroundColor: HopinColors.primaryContainer,
                    child: widget.ride.driverAvatarUrl.isNotEmpty
                        ? ClipOval(
                            child: Image.network(
                              widget.ride.driverAvatarUrl,
                              width: widget.isFriend ? 54 : 34,
                              height: widget.isFriend ? 54 : 34,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return _buildFallbackAvatar();
                              },
                            ),
                          )
                        : _buildFallbackAvatar(),
                  ),
                  
                  // Available seats indicator
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: HopinColors.snapchatYellow,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '${widget.ride.availableSeats}',
                          style: HopinTextStyles.rideMarkerText.copyWith(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFallbackAvatar() {
    return Container(
      width: widget.isFriend ? 54 : 34,
      height: widget.isFriend ? 54 : 34,
      decoration: BoxDecoration(
        color: HopinColors.primaryContainer,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          widget.ride.driverName.substring(0, 1).toUpperCase(),
          style: TextStyle(
            fontSize: widget.isFriend ? 20 : 14,
            fontWeight: FontWeight.w700,
            color: HopinColors.midnightBlue,
          ),
        ),
      ),
    );
  }
}