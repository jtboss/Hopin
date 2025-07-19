import 'package:flutter/material.dart';
import '../../../domain/entities/ride.dart';
import '../../../domain/entities/user.dart';
import '../../../domain/entities/location.dart';
import '../../theme/app_theme.dart';
import '../rides/ride_card.dart';

class RideSelectionBottomSheet extends StatefulWidget {
  final Location pickupLocation;
  final Location destinationLocation;
  final List<Ride> availableRides;
  final Function(Ride) onRideSelected;

  const RideSelectionBottomSheet({
    super.key,
    required this.pickupLocation,
    required this.destinationLocation,
    required this.availableRides,
    required this.onRideSelected,
  });

  @override
  State<RideSelectionBottomSheet> createState() => _RideSelectionBottomSheetState();
}

class _RideSelectionBottomSheetState extends State<RideSelectionBottomSheet> {
  Ride? selectedRide;
  
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: HopinColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
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
          
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Choose a ride',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: HopinColors.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                _buildRouteInfo(),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Available rides
          Flexible(
            child: widget.availableRides.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    itemCount: widget.availableRides.length,
                    itemBuilder: (context, index) {
                      final ride = widget.availableRides[index];
                      return RideCard(
                        ride: ride,
                        driver: _getMockDriver(), // Replace with actual driver data
                        isSelected: selectedRide?.id == ride.id,
                        onTap: () {
                          setState(() {
                            selectedRide = ride;
                          });
                        },
                      );
                    },
                  ),
          ),
          
          // Bottom action button
          if (selectedRide != null) _buildActionButton(),
          
          // Safe area padding
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  Widget _buildRouteInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: HopinColors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
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
                  widget.pickupLocation.displayName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: HopinColors.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  widget.destinationLocation.displayName,
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
          
          // Distance
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: HopinColors.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${widget.pickupLocation.distanceTo(widget.destinationLocation).toStringAsFixed(1)}km',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: HopinColors.onPrimaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: HopinColors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(40),
            ),
            child: const Icon(
              Icons.directions_car_outlined,
              size: 40,
              color: HopinColors.onSurfaceVariant,
            ),
          ),
          
          const SizedBox(height: 16),
          
          Text(
            'No rides available',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: HopinColors.onSurface,
            ),
          ),
          
          const SizedBox(height: 8),
          
          Text(
            'No student drivers are heading this way right now. Try adjusting your pickup location or time.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: HopinColors.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 24),
          
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to create ride request
            },
            icon: const Icon(Icons.add),
            label: const Text('Request a Ride'),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Selected ride summary
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: HopinColors.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: HopinColors.primary,
                  size: 20,
                ),
                
                const SizedBox(width: 8),
                
                Expanded(
                  child: Text(
                    'Selected ride with ${_getMockDriver().name}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: HopinColors.onPrimaryContainer,
                    ),
                  ),
                ),
                
                Text(
                  'R${selectedRide!.estimatedPrice?.toStringAsFixed(0) ?? '0'}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: HopinColors.primary,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Confirm button
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                widget.onRideSelected(selectedRide!);
                Navigator.pop(context);
              },
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
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
        ],
      ),
    );
  }

  // Mock driver data - replace with actual data
  User _getMockDriver() {
    return User(
      id: 'driver123',
      name: 'Sarah Johnson',
      email: 'sarah@uct.ac.za',
      studentNumber: 'JHNS001',
      university: 'University of Cape Town',
      type: UserType.driver,
      verificationStatus: VerificationStatus.verified,
      createdAt: DateTime.now(),
      rating: 4.8,
      totalRides: 156,
    );
  }
}

// Show ride selection bottom sheet
void showRideSelectionBottomSheet({
  required BuildContext context,
  required Location pickupLocation,
  required Location destinationLocation,
  required List<Ride> availableRides,
  required Function(Ride) onRideSelected,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, scrollController) => RideSelectionBottomSheet(
        pickupLocation: pickupLocation,
        destinationLocation: destinationLocation,
        availableRides: availableRides,
        onRideSelected: onRideSelected,
      ),
    ),
  );
} 