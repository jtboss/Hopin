import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../domain/entities/ride.dart';
import '../../../domain/entities/user.dart';
import '../../theme/app_theme.dart';

class RideStatusScreen extends StatefulWidget {
  final Ride ride;
  final User driver;
  final User rider;

  const RideStatusScreen({
    super.key,
    required this.ride,
    required this.driver,
    required this.rider,
  });

  @override
  State<RideStatusScreen> createState() => _RideStatusScreenState();
}

class _RideStatusScreenState extends State<RideStatusScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Map placeholder (will be replaced with Google Maps)
          Container(
            width: double.infinity,
            height: double.infinity,
            color: HopinColors.surfaceContainerHighest,
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.map,
                    size: 64,
                    color: HopinColors.onSurfaceVariant,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Live tracking map will be here',
                    style: TextStyle(
                      color: HopinColors.onSurfaceVariant,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Top status overlay
          SafeArea(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: HopinColors.background,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: HopinColors.onBackground.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildStatusHeader(),
                  const SizedBox(height: 12),
                  _buildRouteInfo(),
                ],
              ),
            ),
          ),
          
          // Bottom driver info and actions
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: HopinColors.background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle bar
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: HopinColors.outline,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    
                    _buildDriverInfo(),
                    _buildActionButtons(),
                  ],
                ),
              ),
            ),
          ),
          
          // Live location button
          Positioned(
            top: MediaQuery.of(context).padding.top + 120,
            right: 16,
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: FloatingActionButton.small(
                    onPressed: () {
                      _shareLocation();
                    },
                    backgroundColor: HopinColors.secondary,
                    child: const Icon(
                      Icons.my_location,
                      color: HopinColors.onSecondary,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusHeader() {
    return Row(
      children: [
        // Status indicator
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: _getStatusColor(),
            shape: BoxShape.circle,
          ),
        ),
        
        const SizedBox(width: 8),
        
        // Status text
        Expanded(
          child: Text(
            widget.ride.statusText,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: HopinColors.onSurface,
            ),
          ),
        ),
        
        // Trip time/ETA
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: HopinColors.primaryContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            _getETAText(),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: HopinColors.onPrimaryContainer,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRouteInfo() {
    return Row(
      children: [
        // Route indicators
        Column(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: HopinColors.secondary,
                shape: BoxShape.circle,
              ),
            ),
            Container(
              width: 2,
              height: 20,
              color: HopinColors.outline,
            ),
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: HopinColors.error,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
        
        const SizedBox(width: 12),
        
        // Locations
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.ride.pickupLocation.displayName,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: HopinColors.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                widget.ride.destinationLocation.displayName,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: HopinColors.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDriverInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Driver photo
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: HopinColors.primaryContainer,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: HopinColors.primary,
                width: 2,
              ),
            ),
            child: widget.driver.profileImageUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: Image.network(
                      widget.driver.profileImageUrl!,
                      fit: BoxFit.cover,
                    ),
                  )
                : const Icon(
                    Icons.person,
                    color: HopinColors.primary,
                    size: 30,
                  ),
          ),
          
          const SizedBox(width: 16),
          
          // Driver details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.driver.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: HopinColors.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.school,
                      size: 16,
                      color: HopinColors.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        widget.driver.university,
                        style: TextStyle(
                          fontSize: 14,
                          color: HopinColors.onSurfaceVariant,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.star,
                      size: 16,
                      color: Colors.amber,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${widget.driver.rating.toStringAsFixed(1)} • ${widget.driver.totalRides} rides',
                      style: TextStyle(
                        fontSize: 14,
                        color: HopinColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Price
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'R${widget.ride.estimatedPrice?.toStringAsFixed(0) ?? '0'}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: HopinColors.primary,
                ),
              ),
              Text(
                'Total fare',
                style: TextStyle(
                  fontSize: 12,
                  color: HopinColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Message button
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _messageDriver,
              icon: const Icon(Icons.message),
              label: const Text('Message'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Call button
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _callDriver,
              icon: const Icon(Icons.phone),
              label: const Text('Call'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Emergency button
          Container(
            decoration: BoxDecoration(
              color: HopinColors.errorContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: _emergencyAction,
              icon: const Icon(
                Icons.emergency,
                color: HopinColors.error,
              ),
              tooltip: 'Emergency',
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    switch (widget.ride.status) {
      case RideStatus.accepted:
        return HopinColors.rideAccepted;
      case RideStatus.driverEnRoute:
        return HopinColors.ridePending;
      case RideStatus.arrived:
        return HopinColors.secondary;
      case RideStatus.inProgress:
        return HopinColors.rideInProgress;
      case RideStatus.completed:
        return HopinColors.rideCompleted;
      default:
        return HopinColors.onSurfaceVariant;
    }
  }

  String _getETAText() {
    if (widget.ride.status == RideStatus.inProgress) {
      return '${widget.ride.estimatedDuration ?? 15} min';
    } else if (widget.ride.status == RideStatus.driverEnRoute) {
      return '5 min away';
    } else if (widget.ride.status == RideStatus.arrived) {
      return 'Driver here';
    } else {
      return 'Confirmed';
    }
  }

  void _shareLocation() {
    HapticFeedback.lightImpact();
    // Implement location sharing with emergency contact
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Location shared with emergency contact'),
        backgroundColor: HopinColors.secondary,
      ),
    );
  }

  void _messageDriver() {
    // Implement messaging functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening chat with driver...')),
    );
  }

  void _callDriver() {
    // Implement call functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Calling driver...')),
    );
  }

  void _emergencyAction() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Emergency'),
        content: const Text(
          'Are you sure you want to trigger emergency mode? This will immediately notify your emergency contacts and campus security.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              // Trigger emergency protocol
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Emergency mode activated'),
                  backgroundColor: HopinColors.error,
                ),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: HopinColors.error,
            ),
            child: const Text('Emergency'),
          ),
        ],
      ),
    );
  }
} 