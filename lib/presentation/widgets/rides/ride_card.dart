import 'package:flutter/material.dart';
import '../../../domain/entities/ride.dart';
import '../../../domain/entities/user.dart';
import '../../theme/app_theme.dart';

class RideCard extends StatelessWidget {
  final Ride ride;
  final User? driver;
  final VoidCallback? onTap;
  final bool isSelected;

  const RideCard({
    super.key,
    required this.ride,
    this.driver,
    this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected ? HopinColors.primaryContainer : HopinColors.background,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? HopinColors.primary : HopinColors.outline,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: HopinColors.onBackground.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Driver info and ride type
                Row(
                  children: [
                    // Driver avatar
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
                      child: driver?.profileImageUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(22),
                              child: Image.network(
                                driver!.profileImageUrl!,
                                fit: BoxFit.cover,
                              ),
                            )
                          : const Icon(
                              Icons.person,
                              color: HopinColors.primary,
                              size: 24,
                            ),
                    ),
                    
                    const SizedBox(width: 12),
                    
                    // Driver details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            driver?.name ?? 'Student Driver',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: HopinColors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                Icons.school,
                                size: 14,
                                color: HopinColors.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  driver?.university ?? 'University',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: HopinColors.onSurfaceVariant,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    // Price and rating
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (ride.estimatedPrice != null)
                          Text(
                            'R${ride.estimatedPrice!.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: HopinColors.primary,
                            ),
                          ),
                        const SizedBox(height: 2),
                        if (driver?.rating != null && driver!.rating > 0)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star,
                                size: 14,
                                color: Colors.amber,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                driver!.rating.toStringAsFixed(1),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: HopinColors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Route info
                Row(
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
                          height: 24,
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
                            ride.pickupLocation.displayName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: HopinColors.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            ride.destinationLocation.displayName,
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
                ),
                
                const SizedBox(height: 16),
                
                // Additional info
                Row(
                  children: [
                    // Available seats
                    _buildInfoChip(
                      Icons.airline_seat_recline_normal,
                      '${ride.requestedSeats} seats',
                    ),
                    
                    const SizedBox(width: 8),
                    
                    // Departure time
                    _buildInfoChip(
                      Icons.schedule,
                      _formatTime(ride.scheduledTime),
                    ),
                    
                    const SizedBox(width: 8),
                    
                    // Distance
                    if (ride.distance != null)
                      _buildInfoChip(
                        Icons.straighten,
                        '${ride.distance!.toStringAsFixed(1)}km',
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: HopinColors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: HopinColors.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: HopinColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = dateTime.difference(now);
    
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}min';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ${difference.inMinutes % 60}min';
    } else {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }
}

// Compact ride card for lists
class CompactRideCard extends StatelessWidget {
  final Ride ride;
  final User? driver;
  final VoidCallback? onTap;

  const CompactRideCard({
    super.key,
    required this.ride,
    this.driver,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: HopinColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: HopinColors.outline),
            ),
            child: Row(
              children: [
                // Driver avatar
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: HopinColors.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.person,
                    size: 16,
                    color: HopinColors.primary,
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Route info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${ride.pickupLocation.displayName} → ${ride.destinationLocation.displayName}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: HopinColors.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatTime(ride.scheduledTime),
                        style: TextStyle(
                          fontSize: 12,
                          color: HopinColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Price
                if (ride.estimatedPrice != null)
                  Text(
                    'R${ride.estimatedPrice!.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: HopinColors.primary,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = dateTime.difference(now);
    
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}min';
    } else {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }
} 