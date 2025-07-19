import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/services/firestore_service.dart';
import '../../../data/models/map_ride_model.dart' as map_model;
import '../../../domain/entities/ride.dart';
import 'character_avatar_marker.dart';
import '../../theme/app_theme.dart';

/// Google Maps widget showing rides with character avatars (Snapchat-style)
class GoogleMapWidget extends StatefulWidget {
  final List<map_model.MapRideModel> availableRides;
  final Function(map_model.MapRideModel)? onRideSelected;
  final bool isLoading;
  final bool isDriverMode;

  const GoogleMapWidget({
    super.key,
    required this.availableRides,
    this.onRideSelected,
    required this.isLoading,
    required this.isDriverMode,
  });

  @override
  State<GoogleMapWidget> createState() => _GoogleMapWidgetState();
}

class _GoogleMapWidgetState extends State<GoogleMapWidget> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  map_model.MapRideModel? _selectedRide;
  Offset? _popupPosition;
  
  // Cape Town coordinates (default location)
  static const LatLng _initialPosition = LatLng(-33.9249, 18.4241);

  bool _isDriverMode = false;

  @override
  void initState() {
    super.initState();
    _createMarkers();
    _isDriverMode = widget.isDriverMode;
  }

  @override
  void didUpdateWidget(GoogleMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.availableRides != widget.availableRides) {
      _createMarkers();
    }
  }

  void _createMarkers() {
    final Set<Marker> markers = {};

    print('🗺️ Creating markers for ${widget.availableRides.length} rides');
    
    for (final ride in widget.availableRides) {
      print('📍 Creating marker for ride ${ride.id}:');
      print('  - Driver: ${ride.driverName}');
      print('  - Location: ${ride.pickupLocation.latitude}, ${ride.pickupLocation.longitude}');
      print('  - Address: ${ride.pickupAddress}');
      
      // Use simple colored marker for now (character marker has issues)
      final BitmapDescriptor markerIcon = BitmapDescriptor.defaultMarkerWithHue(
        CharacterAvatarMarker.getBorderColorForDriver(ride.driverId) == Colors.blue 
          ? BitmapDescriptor.hueBlue
          : CharacterAvatarMarker.getBorderColorForDriver(ride.driverId) == Colors.green
            ? BitmapDescriptor.hueGreen
            : CharacterAvatarMarker.getBorderColorForDriver(ride.driverId) == Colors.purple
              ? BitmapDescriptor.hueViolet
              : CharacterAvatarMarker.getBorderColorForDriver(ride.driverId) == Colors.orange
                ? BitmapDescriptor.hueOrange
                : BitmapDescriptor.hueRed,
      );

      final marker = Marker(
        markerId: MarkerId(ride.id),
        position: ride.pickupLocation,
        icon: markerIcon,
        onTap: () => _onMarkerTapped(ride),
        infoWindow: InfoWindow(
          title: ride.driverName,
          snippet: '${ride.pickupAddress} → ${ride.destinationAddress}',
        ),
      );

      markers.add(marker);
      print('✅ Created marker for ${ride.driverName}');
    }

    print('🎯 Total markers created: ${markers.length}');
    
    if (mounted) {
      setState(() {
        _markers = markers;
      });
      
      // Fit camera to show all markers if any exist
      if (markers.isNotEmpty && _mapController != null) {
        print('📹 Fitting camera to show all markers');
        _fitCameraToMarkers();
      }
    }
  }

  void _onMarkerTapped(map_model.MapRideModel ride) {
    // Calculate popup position based on marker location
    if (_mapController != null) {
      _mapController!.getScreenCoordinate(ride.pickupLocation).then((screenCoordinate) {
        setState(() {
          _selectedRide = ride;
          _popupPosition = Offset(screenCoordinate.x.toDouble(), screenCoordinate.y.toDouble() - 100);
        });
      });
    }
  }

  void _closePopup() {
    setState(() {
      _selectedRide = null;
      _popupPosition = null;
    });
  }

  Widget _buildRidePopup(map_model.MapRideModel ride) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Driver info with avatar
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: CharacterAvatarMarker.getBorderColorForDriver(ride.driverId),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Center(
                  child: Text(
                    CharacterAvatarMarker.getCharacterForDriver(ride.driverId),
                    style: const TextStyle(fontSize: 18),
                  ),
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
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      '${ride.university} • ${ride.formattedRating}⭐',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              // Close button
              GestureDetector(
                onTap: _closePopup,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, size: 14, color: Colors.grey),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Route info - compact
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Column(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 20,
                      color: Colors.grey.shade300,
                    ),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ride.pickupAddress,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        ride.destinationAddress,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Price and seats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'R${ride.price.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Text(
                '${ride.availableSeats} seats',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Book Ride button
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: () {
                _closePopup();
                widget.onRideSelected?.call(ride);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: HopinColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
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

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Main map
        if (widget.isLoading)
          const Center(
            child: CircularProgressIndicator(),
          )
        else
          GestureDetector(
            onTap: () {
              // Close popup when tapping elsewhere on map
              if (_selectedRide != null) {
                _closePopup();
              }
            },
            child: GoogleMap(
              initialCameraPosition: const CameraPosition(
                target: _initialPosition,
                zoom: 12.0,
              ),
              markers: _markers,
              onMapCreated: (GoogleMapController controller) {
                _mapController = controller;
                print('🗺️ Map controller created and set');
                
                // Fit camera to show all markers if any exist
                if (_markers.isNotEmpty) {
                  print('📹 Fitting camera to existing markers on map creation');
                  _fitCameraToMarkers();
                } else {
                  print('📍 No markers available when map was created');
                }
              },
              myLocationEnabled: true,
              myLocationButtonEnabled: false, // We'll add custom button
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              compassEnabled: true,
              trafficEnabled: false,
              buildingsEnabled: true,
              indoorViewEnabled: false,
              mapType: MapType.normal,
              style: _mapStyle,
              onTap: (_) => _closePopup(), // Close popup on map tap
            ),
          ),
          
        // Rides count overlay
        Positioned(
          top: 16,
          left: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.directions_car,
                  size: 16,
                  color: HopinColors.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  '${widget.availableRides.length} rides',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Custom location button
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton.small(
            onPressed: () {
              // Center map on user's location or Cape Town
              if (_mapController != null) {
                _mapController!.animateCamera(
                  CameraUpdate.newLatLng(_initialPosition),
                );
              }
            },
            backgroundColor: Colors.white,
            foregroundColor: Colors.black87,
            child: const Icon(Icons.my_location),
          ),
        ),
        
        // ONLY show ride popup when a marker is tapped
        if (_selectedRide != null && _popupPosition != null)
          Positioned(
            left: _popupPosition!.dx - 140, // Center the popup
            top: _popupPosition!.dy - 180, // Position above marker
            child: Material(
              color: Colors.transparent,
              child: _buildRidePopup(_selectedRide!),
            ),
          ),
      ],
    );
  }

  void _fitCameraToMarkers() {
    if (_markers.isEmpty || _mapController == null) {
      print('❌ Cannot fit camera: markers=${_markers.length}, controller=${_mapController != null}');
      return;
    }

    print('📹 Fitting camera to ${_markers.length} markers');
    
    final bounds = _calculateBounds(_markers.map((m) => m.position).toList());
    
    print('📏 Calculated bounds: SW(${bounds.southwest.latitude}, ${bounds.southwest.longitude}) -> NE(${bounds.northeast.latitude}, ${bounds.northeast.longitude})');
    
    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 80.0),
    );
    
    print('✅ Camera animation initiated');
  }

  LatLngBounds _calculateBounds(List<LatLng> positions) {
    double minLat = positions.first.latitude;
    double maxLat = positions.first.latitude;
    double minLng = positions.first.longitude;
    double maxLng = positions.first.longitude;

    for (final position in positions) {
      minLat = minLat < position.latitude ? minLat : position.latitude;
      maxLat = maxLat > position.latitude ? maxLat : position.latitude;
      minLng = minLng < position.longitude ? minLng : position.longitude;
      maxLng = maxLng > position.longitude ? maxLng : position.longitude;
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  // Custom map style (optional - makes it look more modern)
  static const String _mapStyle = '''
  [
    {
      "featureType": "poi",
      "elementType": "labels",
      "stylers": [
        {
          "visibility": "off"
        }
      ]
    }
  ]
  ''';

  void _showCreateRideInterface() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CreateRideMapInterface(
        onRideCreated: (ride) {
          setState(() {
            _markers.add(_createMarker(ride));
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🚗 Ride created successfully! Students can now book with you.'),
              backgroundColor: HopinColors.secondary,
            ),
          );
        },
      ),
    );
  }

  Marker _createMarker(map_model.MapRideModel ride) {
    // Use simple colored markers (faster than custom icons)
    BitmapDescriptor markerIcon = BitmapDescriptor.defaultMarkerWithHue(
      CharacterAvatarMarker.getHueForDriver(ride.driverId),
    );

    return Marker(
      markerId: MarkerId(ride.id),
      position: ride.pickupLocation,
      icon: markerIcon,
      onTap: () => _onMarkerTapped(ride),
      infoWindow: InfoWindow(
        title: ride.driverName,
        snippet: '${ride.pickupAddress} → ${ride.destinationAddress}',
      ),
    );
  }
}

class _CreateRideMapInterface extends StatefulWidget {
  final Function(map_model.MapRideModel) onRideCreated;

  const _CreateRideMapInterface({required this.onRideCreated});

  @override
  State<_CreateRideMapInterface> createState() => _CreateRideMapInterfaceState();
}

class _CreateRideMapInterfaceState extends State<_CreateRideMapInterface> {
  final _formKey = GlobalKey<FormState>();
  final _pickupController = TextEditingController();
  final _destinationController = TextEditingController();
  final _priceController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();
  
  int _selectedSeats = 2;
  DateTime _selectedTime = DateTime.now().add(const Duration(hours: 1));
  bool _isCreating = false;
  
  // Location picking
  LatLng? _pickupLocation;
  LatLng? _destinationLocation;
  bool _isPickingPickup = false;
  bool _isPickingDestination = false;

  @override
  void dispose() {
    _pickupController.dispose();
    _destinationController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _createRide() async {
    if (!_formKey.currentState!.validate()) return;
    if (_pickupLocation == null || _destinationLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select pickup and destination locations on the map'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isCreating = true);

    try {
      // Get current user from Firebase Auth
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('You must be logged in to create a ride');
      }

      // Create the ride
      final ride = map_model.MapRideModel(
        id: 'ride_${DateTime.now().millisecondsSinceEpoch}',
        driverId: currentUser.uid,
        driverName: currentUser.displayName ?? 'Student Driver',
        driverPhoto: '🚗',
        university: 'UCT',
        pickupLocation: _pickupLocation!,
        destinationLocation: _destinationLocation!,
        pickupAddress: _pickupController.text,
        destinationAddress: _destinationController.text,
        price: double.parse(_priceController.text),
        availableSeats: _selectedSeats,
        departureTime: _selectedTime,
        rating: 4.8,
        totalRides: 23,
        isVerified: true,
        carModel: 'Honda Accord',
        carColor: 'Silver',
        status: map_model.RideStatus.available,
      );
      
      // TODO: Save to Firestore
      await _saveRideToFirestore(ride);
      
      if (mounted) {
        Navigator.pop(context);
        widget.onRideCreated(ride);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create ride: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  Future<void> _saveRideToFirestore(map_model.MapRideModel ride) async {
    try {
      await _firestoreService.createRide(ride);
      print('✅ Ride saved to Firestore: ${ride.id}');
    } catch (e) {
      print('❌ Error saving ride to Firestore: $e');
      throw e; // Re-throw to be caught by the caller
    }
  }

  void _pickLocationOnMap({required bool isPickup}) {
    setState(() {
      if (isPickup) {
        _isPickingPickup = true;
        _isPickingDestination = false;
      } else {
        _isPickingPickup = false;
        _isPickingDestination = true;
      }
    });
    
    // Show location picker dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isPickup ? 'Select Pickup Location' : 'Select Destination'),
        content: const Text('Tap on the map to select a location'),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _isPickingPickup = false;
                _isPickingDestination = false;
              });
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: HopinColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: HopinColors.onSurfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            const Text(
              'Create New Ride',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: HopinColors.onSurface,
              ),
            ),
            
            const SizedBox(height: 20),
            
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Pickup location
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _pickupController,
                            decoration: const InputDecoration(
                              labelText: 'Pickup Location',
                              prefixIcon: Icon(Icons.trip_origin, color: Colors.green),
                              border: OutlineInputBorder(),
                              hintText: 'e.g., UCT Upper Campus',
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter pickup location';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () => _pickLocationOnMap(isPickup: true),
                          icon: const Icon(Icons.location_on),
                          tooltip: 'Pick on map',
                          style: IconButton.styleFrom(
                            backgroundColor: HopinColors.secondary.withOpacity(0.2),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Destination
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _destinationController,
                            decoration: const InputDecoration(
                              labelText: 'Destination',
                              prefixIcon: Icon(Icons.location_on, color: Colors.red),
                              border: OutlineInputBorder(),
                              hintText: 'e.g., V&A Waterfront',
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter destination';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () => _pickLocationOnMap(isPickup: false),
                          icon: const Icon(Icons.location_on),
                          tooltip: 'Pick on map',
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.red.withOpacity(0.2),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    Row(
                      children: [
                        // Price
                        Expanded(
                          child: TextFormField(
                            controller: _priceController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Price per seat',
                              prefixText: 'R',
                              border: OutlineInputBorder(),
                              hintText: '25',
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Enter price';
                              }
                              final price = double.tryParse(value);
                              if (price == null || price <= 0) {
                                return 'Valid price required';
                              }
                              return null;
                            },
                          ),
                        ),
                        
                        const SizedBox(width: 16),
                        
                        // Available seats
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Available seats',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: HopinColors.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                                decoration: BoxDecoration(
                                  border: Border.all(color: HopinColors.outline),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '$_selectedSeats seats',
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                    Row(
                                      children: [
                                        GestureDetector(
                                          onTap: _selectedSeats > 1 
                                              ? () => setState(() => _selectedSeats--)
                                              : null,
                                          child: Icon(
                                            Icons.remove_circle_outline,
                                            color: _selectedSeats > 1 
                                                ? HopinColors.primary 
                                                : HopinColors.onSurfaceVariant,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        GestureDetector(
                                          onTap: _selectedSeats < 4 
                                              ? () => setState(() => _selectedSeats++)
                                              : null,
                                          child: Icon(
                                            Icons.add_circle_outline,
                                            color: _selectedSeats < 4 
                                                ? HopinColors.primary 
                                                : HopinColors.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Departure time
                    GestureDetector(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _selectedTime,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 7)),
                        );
                        if (date != null) {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.fromDateTime(_selectedTime),
                          );
                          if (time != null) {
                            setState(() {
                              _selectedTime = DateTime(
                                date.year,
                                date.month,
                                date.day,
                                time.hour,
                                time.minute,
                              );
                            });
                          }
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: HopinColors.outline),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.schedule, color: HopinColors.primary),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Departure time',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: HopinColors.onSurfaceVariant,
                                  ),
                                ),
                                Text(
                                  '${_selectedTime.day}/${_selectedTime.month} at ${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            const Icon(Icons.edit, color: HopinColors.onSurfaceVariant),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            
            // Create button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton(
                onPressed: _isCreating ? null : _createRide,
                child: _isCreating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Create Ride',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 