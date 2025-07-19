import 'package:flutter/material.dart';
import '../../../data/models/map_ride_model.dart';
import '../../../data/mock_data/mock_rides_data.dart';
import '../../theme/app_theme.dart';

/// Fallback map widget when Google Maps is not available
/// Shows rides in a list format with location visualization
class MapFallbackWidget extends StatelessWidget {
  final Function(MapRideModel) onRideSelected;
  final List<MapRideModel> availableRides;
  final bool isLoading;
  
  const MapFallbackWidget({
    super.key,
    required this.onRideSelected,
    required this.availableRides,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              HopinColors.primaryContainer.withValues(alpha: 0.3),
              HopinColors.secondaryContainer.withValues(alpha: 0.2),
            ],
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: HopinColors.primary,
              ),
              SizedBox(height: 16),
              Text(
                'Loading rides from Firebase...',
                style: TextStyle(
                  color: HopinColors.onSurface,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            HopinColors.primaryContainer.withValues(alpha: 0.3),
            HopinColors.secondaryContainer.withValues(alpha: 0.2),
          ],
        ),
      ),
      child: Column(
        children: [
          // Map placeholder header
          Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const SizedBox(height: 40),
                Icon(
                  Icons.map_outlined,
                  size: 64,
                  color: HopinColors.primary.withValues(alpha: 0.7),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Cape Town Area',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: HopinColors.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: HopinColors.primary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${availableRides.length} rides available',
                    style: const TextStyle(
                      color: HopinColors.onPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Rides list
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: HopinColors.background,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: HopinColors.onBackground.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Handle bar
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: HopinColors.onSurfaceVariant.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  
                  // List header
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Text(
                          'Available Rides',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: HopinColors.onSurface,
                          ),
                        ),
                        Spacer(),
                        Icon(
                          Icons.location_on,
                          size: 16,
                          color: HopinColors.onSurfaceVariant,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Near UCT',
                          style: TextStyle(
                            fontSize: 12,
                            color: HopinColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Rides list
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: availableRides.length,
                      itemBuilder: (context, index) {
                        final ride = availableRides[index];
                        return _buildRideCard(ride);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRideCard(MapRideModel ride) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: HopinColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: HopinColors.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onRideSelected(ride),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Driver avatar and location indicator
                Stack(
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
                          ride.driverPhoto,
                          style: const TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -2,
                      right: -2,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: ride.status == RideStatus.departing 
                              ? Colors.orange 
                              : HopinColors.secondary,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: HopinColors.background,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(width: 12),
                
                // Ride details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Driver name and verification
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
                              size: 14,
                              color: HopinColors.primary,
                            ),
                        ],
                      ),
                      
                      const SizedBox(height: 4),
                      
                      // Route
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: HopinColors.secondary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '${ride.pickupAddress} → ${ride.destinationAddress}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: HopinColors.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 6),
                      
                      // Time and seats
                      Row(
                        children: [
                          Icon(
                            Icons.schedule,
                            size: 12,
                            color: HopinColors.onSurfaceVariant.withValues(alpha: 0.7),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            ride.formattedDepartureTime,
                            style: TextStyle(
                              fontSize: 12,
                              color: HopinColors.onSurfaceVariant.withValues(alpha: 0.8),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.people,
                            size: 12,
                            color: HopinColors.onSurfaceVariant.withValues(alpha: 0.7),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${ride.availableSeats} seats',
                            style: TextStyle(
                              fontSize: 12,
                              color: HopinColors.onSurfaceVariant.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Price and rating
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      ride.formattedPrice,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: HopinColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.star,
                          size: 12,
                          color: Colors.amber[700],
                        ),
                        const SizedBox(width: 2),
                        Text(
                          ride.formattedRating,
                          style: const TextStyle(
                            fontSize: 12,
                            color: HopinColors.onSurfaceVariant,
                          ),
                        ),
                      ],
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
} 