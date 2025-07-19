import 'package:flutter/material.dart';
import '../../../data/models/map_ride_model.dart';
import '../../theme/app_theme.dart';
import '../bottom_sheets/ride_booking_bottom_sheet.dart';

/// Custom info window for ride markers on the map
class RideMarkerInfoWindow extends StatelessWidget {
  final MapRideModel ride;
  final VoidCallback onTap;
  final VoidCallback? onClose;

  const RideMarkerInfoWindow({
    super.key,
    required this.ride,
    required this.onTap,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: HopinColors.background,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: HopinColors.onBackground.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with driver info and close button
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
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
                  child: Center(
                    child: Text(
                      ride.driverPhoto,
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Driver details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            ride.driverName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: HopinColors.onSurface,
                            ),
                          ),
                          const SizedBox(width: 4),
                          if (ride.isVerified)
                            const Icon(
                              Icons.verified,
                              size: 16,
                              color: HopinColors.primary,
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        ride.university,
                        style: const TextStyle(
                          fontSize: 12,
                          color: HopinColors.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.star,
                            size: 14,
                            color: Colors.amber[700],
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '${ride.formattedRating} • ${ride.totalRides} rides',
                            style: const TextStyle(
                              fontSize: 12,
                              color: HopinColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Close button
                if (onClose != null)
                  IconButton(
                    onPressed: onClose,
                    icon: const Icon(
                      Icons.close,
                      size: 20,
                      color: HopinColors.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          
          // Route information
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                // Route line
                Row(
                  children: [
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
                          color: HopinColors.onSurfaceVariant.withValues(alpha: 0.3),
                        ),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: HopinColors.error,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(width: 12),
                    
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ride.pickupAddress,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: HopinColors.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 20),
                          Text(
                            ride.destinationAddress,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: HopinColors.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Ride details
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Departure time
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Departure',
                      style: TextStyle(
                        fontSize: 12,
                        color: HopinColors.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      ride.formattedDepartureTime,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: HopinColors.onSurface,
                      ),
                    ),
                  ],
                ),
                
                // Available seats
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'Seats',
                      style: TextStyle(
                        fontSize: 12,
                        color: HopinColors.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      '${ride.availableSeats}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: HopinColors.onSurface,
                      ),
                    ),
                  ],
                ),
                
                // Price
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Price',
                      style: TextStyle(
                        fontSize: 12,
                        color: HopinColors.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      ride.formattedPrice,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: HopinColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Book ride button
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => RideBookingBottomSheet(
                          ride: ride,
                          onBookingComplete: () {
                            onClose?.call(); // Close the info window after booking
                          },
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: HopinColors.primary,
                      foregroundColor: HopinColors.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Book Ride',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: onTap,
                  style: IconButton.styleFrom(
                    backgroundColor: HopinColors.surface,
                    foregroundColor: HopinColors.onSurface,
                    padding: const EdgeInsets.all(14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.info_outline),
                  tooltip: 'View Details',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 