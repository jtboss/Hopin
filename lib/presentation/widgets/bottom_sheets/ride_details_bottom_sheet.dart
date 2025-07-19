import 'package:flutter/material.dart';
import '../../../data/models/map_ride_model.dart';
import '../../theme/app_theme.dart';

class RideDetailsBottomSheet extends StatelessWidget {
  final MapRideModel ride;
  final VoidCallback onBookRide;

  const RideDetailsBottomSheet({
    super.key,
    required this.ride,
    required this.onBookRide,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            height: 4,
            width: 40,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Ride details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Driver info
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: HopinColors.primary,
                      child: Text(
                        ride.driverPhoto,
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ride.driverName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Row(
                            children: [
                              Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${ride.rating.toStringAsFixed(1)} • ${ride.totalRides} rides',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'R${ride.price.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: HopinColors.primary,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Route info
                Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.circle,
                          color: HopinColors.secondary,
                          size: 12,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            ride.pickupAddress,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          color: HopinColors.error,
                          size: 12,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            ride.destinationAddress,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Ride details
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildDetailItem(
                      icon: Icons.schedule,
                      label: 'Departure',
                      value: _formatTime(ride.departureTime),
                    ),
                    _buildDetailItem(
                      icon: Icons.person,
                      label: 'Seats',
                      value: '${ride.availableSeats}',
                    ),
                    _buildDetailItem(
                      icon: Icons.directions_car,
                      label: 'Car',
                      value: ride.carModel,
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Book button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: onBookRide,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: HopinColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: const Text(
                      'Book Ride',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: HopinColors.primary,
          size: 20,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = dateTime.difference(now);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'Now';
    }
  }
} 