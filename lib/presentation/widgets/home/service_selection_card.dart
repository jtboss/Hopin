import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

enum ServiceType { rider, driver }

class ServiceSelectionCard extends StatelessWidget {
  final ServiceType serviceType;
  final bool isSelected;
  final VoidCallback onTap;

  const ServiceSelectionCard({
    super.key,
    required this.serviceType,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
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
                if (isSelected)
                  BoxShadow(
                    color: HopinColors.primary.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Service icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isSelected ? HopinColors.primary : HopinColors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    serviceType == ServiceType.rider ? Icons.person : Icons.drive_eta,
                    color: isSelected ? HopinColors.onPrimary : HopinColors.onSurfaceVariant,
                    size: 24,
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Service title
                Text(
                  serviceType == ServiceType.rider ? 'Need a Ride' : 'Offer a Ride',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? HopinColors.onPrimaryContainer : HopinColors.onSurface,
                  ),
                ),
                
                const SizedBox(height: 4),
                
                // Service description
                Text(
                  serviceType == ServiceType.rider 
                      ? 'Find student drivers' 
                      : 'Share your car',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: isSelected 
                        ? HopinColors.onPrimaryContainer.withValues(alpha: 0.8)
                        : HopinColors.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ServiceSelectionRow extends StatefulWidget {
  final ServiceType initialSelection;
  final Function(ServiceType) onSelectionChanged;

  const ServiceSelectionRow({
    super.key,
    required this.initialSelection,
    required this.onSelectionChanged,
  });

  @override
  State<ServiceSelectionRow> createState() => _ServiceSelectionRowState();
}

class _ServiceSelectionRowState extends State<ServiceSelectionRow> {
  late ServiceType selectedService;

  @override
  void initState() {
    super.initState();
    selectedService = widget.initialSelection;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: ServiceSelectionCard(
              serviceType: ServiceType.rider,
              isSelected: selectedService == ServiceType.rider,
              onTap: () {
                setState(() {
                  selectedService = ServiceType.rider;
                });
                widget.onSelectionChanged(ServiceType.rider);
              },
            ),
          ),
          Expanded(
            child: ServiceSelectionCard(
              serviceType: ServiceType.driver,
              isSelected: selectedService == ServiceType.driver,
              onTap: () {
                setState(() {
                  selectedService = ServiceType.driver;
                });
                widget.onSelectionChanged(ServiceType.driver);
              },
            ),
          ),
        ],
      ),
    );
  }
} 