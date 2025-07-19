import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/models/map_ride_model.dart';
import '../../data/models/booking_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collections
  static const String _ridesCollection = 'rides';
  static const String _usersCollection = 'users';
  static const String _bookingsCollection = 'bookings';

  // ==================== RIDES ====================

  // Create a new ride
  Future<String> createRide(MapRideModel ride) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User must be authenticated to create rides');
      }

      // Generate a proper document ID
      final docRef = _firestore.collection('rides').doc();
      final rideId = docRef.id;

      print('🔄 Creating ride with ID: $rideId');
      print('📍 Pickup: ${ride.pickupLocation.latitude}, ${ride.pickupLocation.longitude}');
      print('🎯 Destination: ${ride.destinationLocation.latitude}, ${ride.destinationLocation.longitude}');

      await docRef.set({
        'id': rideId,
        'driverId': user.uid,
        'driverName': ride.driverName,
        'driverPhoto': ride.driverPhoto,
        'university': ride.university,
        'pickupLocation': GeoPoint(ride.pickupLocation.latitude, ride.pickupLocation.longitude),
        'destinationLocation': GeoPoint(ride.destinationLocation.latitude, ride.destinationLocation.longitude),
        'pickupAddress': ride.pickupAddress,
        'destinationAddress': ride.destinationAddress,
        'price': ride.price,
        'availableSeats': ride.availableSeats,
        'departureTime': Timestamp.fromDate(ride.departureTime),
        'rating': ride.rating,
        'totalRides': ride.totalRides,
        'isVerified': ride.isVerified,
        'carModel': ride.carModel,
        'carColor': ride.carColor,
        'status': ride.status.name,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Ride created successfully in Firestore: $rideId');
      return rideId;
    } catch (e) {
      print('❌ Error creating ride in Firestore: $e');
      throw Exception('Failed to create ride: $e');
    }
  }

  // Get available rides near a location
  Stream<List<MapRideModel>> getAvailableRides({
    double? centerLat,
    double? centerLng,
    double radiusKm = 10.0,
  }) {
    try {
      return _firestore
          .collection(_ridesCollection)
          .orderBy('departureTime')
          .snapshots()
          .map((snapshot) {
            return snapshot.docs
                .map((doc) {
                  final data = doc.data();
                  
                  return MapRideModel(
                    id: doc.id,
                    driverId: data['driverId'] ?? '',
                    driverName: data['driverName'] ?? '',
                    driverPhoto: data['driverPhoto'] ?? '👤',
                    university: data['university'] ?? '',
                    pickupLocation: _geoPointToLatLng(data['pickupLocation']),
                    destinationLocation: _geoPointToLatLng(data['destinationLocation']),
                    pickupAddress: data['pickupAddress'] ?? '',
                    destinationAddress: data['destinationAddress'] ?? '',
                    departureTime: (data['departureTime'] as Timestamp).toDate(),
                    availableSeats: data['availableSeats'] ?? 0,
                    price: (data['price'] ?? 0.0).toDouble(),
                    rating: (data['driverRating'] ?? 5.0).toDouble(),
                    totalRides: data['totalRides'] ?? 0,
                    isVerified: true, // All Firebase users are verified
                    carModel: data['carModel'] ?? 'Honda Civic',
                    carColor: data['carColor'] ?? 'White',
                    status: _parseRideStatus(data['status'] ?? 'available'),
                  );
                })
                .where((ride) => 
                  ride.availableSeats > 0 && 
                  ride.status == RideStatus.available // Only show available rides
                )
                .toList();
          });
    } catch (e) {
      throw Exception('Failed to get available rides: $e');
    }
  }

  // Get rides for a specific driver
  Stream<List<MapRideModel>> getDriverRides(String driverId) {
    try {
      return _firestore
          .collection(_ridesCollection)
          .where('driverId', isEqualTo: driverId)
          .orderBy('departureTime', descending: true)
          .snapshots()
          .map((snapshot) {
            final rides = snapshot.docs.map((doc) {
              final data = doc.data();
              
              return MapRideModel(
                id: doc.id,
                driverId: data['driverId'] ?? '',
                driverName: data['driverName'] ?? '',
                driverPhoto: data['driverPhoto'] ?? '👤',
                university: data['university'] ?? '',
                pickupLocation: _geoPointToLatLng(data['pickupLocation']),
                destinationLocation: _geoPointToLatLng(data['destinationLocation']),
                pickupAddress: data['pickupAddress'] ?? '',
                destinationAddress: data['destinationAddress'] ?? '',
                departureTime: (data['departureTime'] as Timestamp).toDate(),
                availableSeats: data['availableSeats'] ?? 0,
                price: (data['price'] ?? 0.0).toDouble(),
                rating: (data['driverRating'] ?? 5.0).toDouble(),
                totalRides: data['totalRides'] ?? 0,
                isVerified: true, // All Firebase users are verified
                carModel: data['carModel'] ?? 'Honda Civic',
                carColor: data['carColor'] ?? 'White',
                status: _parseRideStatus(data['status'] ?? 'available'),
              );
            }).toList();
            
            print('📊 Loaded ${rides.length} rides for driver $driverId');
            for (final ride in rides) {
              print('  - ${ride.id}: ${ride.status.name} (${ride.pickupAddress} -> ${ride.destinationAddress})');
            }
            
            return rides;
          });
    } catch (e) {
      print('❌ Error loading driver rides: $e');
      throw Exception('Failed to get driver rides: $e');
    }
  }

  // Get ACTIVE rides only for driver dashboard
  Stream<List<MapRideModel>> getDriverActiveRides(String driverId) {
    try {
      // Simplified query to avoid compound index requirements
      return _firestore
          .collection(_ridesCollection)
          .where('driverId', isEqualTo: driverId)
          .snapshots()
          .map((snapshot) {
            final allRides = snapshot.docs.map((doc) {
              final data = doc.data();
              
              return MapRideModel(
                id: doc.id,
                driverId: data['driverId'] ?? '',
                driverName: data['driverName'] ?? '',
                driverPhoto: data['driverPhoto'] ?? '👤',
                university: data['university'] ?? '',
                pickupLocation: _geoPointToLatLng(data['pickupLocation']),
                destinationLocation: _geoPointToLatLng(data['destinationLocation']),
                pickupAddress: data['pickupAddress'] ?? '',
                destinationAddress: data['destinationAddress'] ?? '',
                departureTime: (data['departureTime'] as Timestamp).toDate(),
                availableSeats: data['availableSeats'] ?? 0,
                price: (data['price'] ?? 0.0).toDouble(),
                rating: (data['driverRating'] ?? 5.0).toDouble(),
                totalRides: data['totalRides'] ?? 0,
                isVerified: true, // All Firebase users are verified
                carModel: data['carModel'] ?? 'Honda Civic',
                carColor: data['carColor'] ?? 'White',
                status: _parseRideStatus(data['status'] ?? 'available'),
              );
            }).toList();

            // Filter for active rides client-side to avoid compound index
            final activeRides = allRides.where((ride) => 
              ride.status == RideStatus.available || 
              ride.status == RideStatus.departing ||
              ride.status == RideStatus.inProgress
            ).toList();

            // Sort by departure time client-side
            activeRides.sort((a, b) => a.departureTime.compareTo(b.departureTime));
            
            print('🚗 Loaded ${activeRides.length} ACTIVE rides for driver dashboard');
            for (final ride in activeRides) {
              print('  - ${ride.id}: ${ride.status.name} (${ride.pickupAddress} -> ${ride.destinationAddress})');
            }
            
            return activeRides;
          });
    } catch (e) {
      print('❌ Error loading driver active rides: $e');
      throw Exception('Failed to get driver active rides: $e');
    }
  }

  // Update ride status
  Future<void> updateRideStatus(String rideId, RideStatus status) async {
    try {
      await _firestore.collection('rides').doc(rideId).update({
        'status': status.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      print('✅ Ride status updated: $rideId -> ${status.name}');
    } catch (e) {
      print('❌ Error updating ride status: $e');
      throw Exception('Failed to update ride status: $e');
    }
  }

  // ==================== BOOKINGS ====================

  // Create a booking
  Future<String> createBooking({
    required String rideId,
    required int seatsBooked,
    String? specialRequests,
  }) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User must be logged in to book a ride');
      }

      // Get ride details
      final rideDoc = await _firestore.collection(_ridesCollection).doc(rideId).get();
      if (!rideDoc.exists) {
        throw Exception('Ride not found');
      }

      final rideData = rideDoc.data()!;
      final availableSeats = rideData['availableSeats'] as int;
      final pricePerSeat = rideData['price'] as double;
      final driverId = rideData['driverId'] as String;
      
      if (availableSeats < seatsBooked) {
        throw Exception('Not enough seats available');
      }

      // Start a batch operation
      final batch = _firestore.batch();

      // Create booking document
      final bookingRef = _firestore.collection(_bookingsCollection).doc();
      batch.set(bookingRef, {
        'id': bookingRef.id,
        'rideId': rideId,
        'riderId': currentUser.uid,
        'riderName': currentUser.displayName ?? 'Student Rider',
        'riderEmail': currentUser.email ?? '',
        'driverId': driverId,
        'driverName': rideData['driverName'],
        'seatsBooked': seatsBooked,
        'totalPrice': pricePerSeat * seatsBooked,
        'bookingTime': FieldValue.serverTimestamp(),
        'status': 'confirmed',
        'specialRequests': specialRequests,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update ride available seats
      final rideRef = _firestore.collection(_ridesCollection).doc(rideId);
      batch.update(rideRef, {
        'availableSeats': FieldValue.increment(-seatsBooked),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Create notification for driver
      final notificationRef = _firestore.collection('notifications').doc();
      batch.set(notificationRef, {
        'id': notificationRef.id,
        'type': 'booking_created',
        'recipientId': driverId,
        'senderId': currentUser.uid,
        'senderName': currentUser.displayName ?? 'Student Rider',
        'title': 'New Booking!',
        'message': '${currentUser.displayName ?? 'A student'} booked $seatsBooked seat${seatsBooked > 1 ? 's' : ''} for your ride',
        'rideId': rideId,
        'bookingId': bookingRef.id,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Commit the batch
      await batch.commit();

      print('✅ Booking created successfully: ${bookingRef.id}');
      print('✅ Notification sent to driver: $driverId');
      
      return bookingRef.id;
    } catch (e) {
      print('❌ Error creating booking: $e');
      throw Exception('Failed to create booking: $e');
    }
  }

  // Get user bookings
  Stream<List<BookingModel>> getUserBookings(String userId) {
    try {
      return _firestore
          .collection(_bookingsCollection)
          .where('riderId', isEqualTo: userId)
          .snapshots()
          .map((snapshot) {
            final bookings = snapshot.docs.map((doc) {
              final data = doc.data();
              return BookingModel(
                id: doc.id,
                rideId: data['rideId'] ?? '',
                riderId: data['riderId'] ?? '',
                riderName: data['riderName'] ?? '',
                riderEmail: data['riderEmail'] ?? '',
                driverId: data['driverId'] ?? '',
                driverName: data['driverName'] ?? '',
                seatsBooked: data['seatsBooked'] ?? 1,
                totalPrice: (data['totalPrice'] ?? 0.0).toDouble(),
                bookingTime: (data['bookingTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
                status: _parseBookingStatus(data['status'] ?? 'pending'),
                specialRequests: data['specialRequests'],
              );
            }).toList();
            
            // Sort by booking time in app instead of Firestore
            bookings.sort((a, b) => b.bookingTime.compareTo(a.bookingTime));
            return bookings;
          });
    } catch (e) {
      throw Exception('Failed to get user bookings: $e');
    }
  }

  // Get driver bookings
  Stream<List<BookingModel>> getDriverBookings(String driverId) {
    try {
      return _firestore
          .collection(_bookingsCollection)
          .where('driverId', isEqualTo: driverId)
          .snapshots()
          .map((snapshot) {
            final bookings = snapshot.docs.map((doc) {
              final data = doc.data();
              return BookingModel(
                id: doc.id,
                rideId: data['rideId'] ?? '',
                riderId: data['riderId'] ?? '',
                riderName: data['riderName'] ?? '',
                riderEmail: data['riderEmail'] ?? '',
                driverId: data['driverId'] ?? '',
                driverName: data['driverName'] ?? '',
                seatsBooked: data['seatsBooked'] ?? 1,
                totalPrice: (data['totalPrice'] ?? 0.0).toDouble(),
                bookingTime: (data['bookingTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
                status: _parseBookingStatus(data['status'] ?? 'pending'),
                specialRequests: data['specialRequests'],
              );
            }).toList();
            
            // Sort by booking time in app instead of Firestore
            bookings.sort((a, b) => b.bookingTime.compareTo(a.bookingTime));
            return bookings;
          });
    } catch (e) {
      throw Exception('Failed to get driver bookings: $e');
    }
  }

  // Get bookings for a specific ride
  Stream<List<BookingModel>> getRideBookings(String rideId) {
    try {
      return _firestore
          .collection(_bookingsCollection)
          .where('rideId', isEqualTo: rideId)
          .where('status', whereIn: ['confirmed', 'pending']) // Only active bookings
          .snapshots()
          .map((snapshot) {
            final bookings = snapshot.docs.map((doc) {
              final data = doc.data();
              return BookingModel(
                id: doc.id,
                rideId: data['rideId'] ?? '',
                riderId: data['riderId'] ?? '',
                riderName: data['riderName'] ?? '',
                riderEmail: data['riderEmail'] ?? '',
                driverId: data['driverId'] ?? '',
                driverName: data['driverName'] ?? '',
                seatsBooked: data['seatsBooked'] ?? 1,
                totalPrice: (data['totalPrice'] ?? 0.0).toDouble(),
                bookingTime: (data['bookingTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
                status: _parseBookingStatus(data['status'] ?? 'pending'),
                specialRequests: data['specialRequests'],
              );
            }).toList();
            
            // Sort by booking time
            bookings.sort((a, b) => a.bookingTime.compareTo(b.bookingTime));
            return bookings;
          });
    } catch (e) {
      throw Exception('Failed to get ride bookings: $e');
    }
  }

  // Update booking status
  Future<void> updateBookingStatus(String bookingId, BookingStatus status) async {
    try {
      await _firestore.collection(_bookingsCollection).doc(bookingId).update({
        'status': status.toString().split('.').last,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('✅ Booking status updated: $bookingId -> ${status.displayName}');
    } catch (e) {
      print('❌ Error updating booking status: $e');
      throw Exception('Failed to update booking status: $e');
    }
  }

  // Cancel booking
  Future<void> cancelBooking(String bookingId) async {
    try {
      // Get booking details
      final bookingDoc = await _firestore.collection(_bookingsCollection).doc(bookingId).get();
      if (!bookingDoc.exists) {
        throw Exception('Booking not found');
      }

      final bookingData = bookingDoc.data()!;
      final rideId = bookingData['rideId'] as String;
      final seatsBooked = bookingData['seatsBooked'] as int;

      // Start a batch operation
      final batch = _firestore.batch();

      // Update booking status
      final bookingRef = _firestore.collection(_bookingsCollection).doc(bookingId);
      batch.update(bookingRef, {
        'status': 'cancelled',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Return seats to ride
      final rideRef = _firestore.collection(_ridesCollection).doc(rideId);
      batch.update(rideRef, {
        'availableSeats': FieldValue.increment(seatsBooked),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Commit the batch
      await batch.commit();

      print('✅ Booking cancelled successfully: $bookingId');
    } catch (e) {
      print('❌ Error cancelling booking: $e');
      throw Exception('Failed to cancel booking: $e');
    }
  }

  // ==================== USERS ====================

  // Get user profile
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final doc = await _firestore.collection(_usersCollection).doc(userId).get();
      return doc.exists ? doc.data() : null;
    } catch (e) {
      throw Exception('Failed to get user profile: $e');
    }
  }

  // Update user profile
  Future<void> updateUserProfile(String userId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection(_usersCollection).doc(userId).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update user profile: $e');
    }
  }

  // Update user rating
  Future<void> updateUserRating(String userId, double newRating) async {
    try {
      await _firestore.collection(_usersCollection).doc(userId).update({
        'rating': newRating,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update user rating: $e');
    }
  }

  // ==================== CLEANUP METHODS ====================

  /// Clean up Firebase data - removes all rides, bookings, and notifications
  /// Use this to reset the database to a clean state
  Future<void> cleanupFirebaseData() async {
    try {
      print('🧹 Starting Firebase cleanup...');
      
      // Get current user
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        print('❌ No authenticated user for cleanup');
        return;
      }

      final batch = _firestore.batch();
      int deleteCount = 0;

      // Delete all rides for current user
      final ridesQuery = await _firestore
          .collection(_ridesCollection)
          .where('driverId', isEqualTo: currentUser.uid)
          .get();
      
      for (final doc in ridesQuery.docs) {
        batch.delete(doc.reference);
        deleteCount++;
      }

      // Delete all bookings for current user
      final bookingsQuery = await _firestore
          .collection(_bookingsCollection)
          .where('driverId', isEqualTo: currentUser.uid)
          .get();
      
      for (final doc in bookingsQuery.docs) {
        batch.delete(doc.reference);
        deleteCount++;
      }

      // Delete all notifications for current user
      final notificationsQuery = await _firestore
          .collection('notifications')
          .where('recipientId', isEqualTo: currentUser.uid)
          .get();
      
      for (final doc in notificationsQuery.docs) {
        batch.delete(doc.reference);
        deleteCount++;
      }

      // Delete driver location data
      final driverLocationDoc = _firestore
          .collection('driver_locations')
          .doc(currentUser.uid);
      batch.delete(driverLocationDoc);
      deleteCount++;

      // Commit all deletions
      await batch.commit();
      
      print('✅ Firebase cleanup completed - deleted $deleteCount documents');
      
    } catch (e) {
      print('❌ Error during Firebase cleanup: $e');
      throw Exception('Failed to cleanup Firebase data: $e');
    }
  }

  /// Clean up ALL Firebase data (admin function - use with caution)
  Future<void> cleanupAllFirebaseData() async {
    try {
      print('🧹 Starting FULL Firebase cleanup...');
      
      final batch = _firestore.batch();
      int deleteCount = 0;

      // Delete all rides
      final ridesQuery = await _firestore.collection(_ridesCollection).get();
      for (final doc in ridesQuery.docs) {
        batch.delete(doc.reference);
        deleteCount++;
      }

      // Delete all bookings
      final bookingsQuery = await _firestore.collection(_bookingsCollection).get();
      for (final doc in bookingsQuery.docs) {
        batch.delete(doc.reference);
        deleteCount++;
      }

      // Delete all notifications
      final notificationsQuery = await _firestore.collection('notifications').get();
      for (final doc in notificationsQuery.docs) {
        batch.delete(doc.reference);
        deleteCount++;
      }

      // Delete all driver locations
      final driverLocationsQuery = await _firestore.collection('driver_locations').get();
      for (final doc in driverLocationsQuery.docs) {
        batch.delete(doc.reference);
        deleteCount++;
      }

      // Commit all deletions
      await batch.commit();
      
      print('✅ FULL Firebase cleanup completed - deleted $deleteCount documents');
      
    } catch (e) {
      print('❌ Error during FULL Firebase cleanup: $e');
      throw Exception('Failed to cleanup all Firebase data: $e');
    }
  }

  // ==================== HELPER METHODS ====================

  RideStatus _parseRideStatus(String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return RideStatus.available;
      case 'departing_soon':
      case 'departing':
        return RideStatus.departing;
      case 'in_progress':
        return RideStatus.inProgress;
      case 'completed':
        return RideStatus.completed;
      case 'cancelled':
        return RideStatus.cancelled;
      default:
        return RideStatus.available;
    }
  }

  BookingStatus _parseBookingStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return BookingStatus.pending;
      case 'confirmed':
        return BookingStatus.confirmed;
      case 'cancelled':
        return BookingStatus.cancelled;
      case 'completed':
        return BookingStatus.completed;
      case 'no_show':
        return BookingStatus.noShow;
      default:
        return BookingStatus.pending;
    }
  }

  // Add sample rides for development demonstrations
  Future<void> addSampleRides() async {
    try {
      // Check if rides already exist to avoid duplicates
      final existingRides = await _firestore.collection(_ridesCollection).limit(1).get();
      if (existingRides.docs.isNotEmpty) {
        print('Sample rides already exist, skipping...');
        return;
      }

      final now = DateTime.now();
      final sampleRides = [
        {
          'driverId': 'driver_1',
          'driverName': 'Aisha Patel',
          'driverPhoto': '👩🏾‍🎓',
          'university': 'UCT',
          'driverRating': 4.8,
          'totalRides': 47,
          'carModel': 'Honda Civic',
          'carColor': 'White',
          'pickupLocation': {
            'name': 'UCT Upper Campus',
            'latitude': -33.9570,
            'longitude': 18.4608,
          },
          'dropoffLocation': {
            'name': 'V&A Waterfront',
            'latitude': -33.9020,
            'longitude': 18.4186,
          },
          'price': 25.0,
          'availableSeats': 3,
          'totalSeats': 4,
          'departureTime': Timestamp.fromDate(now.add(const Duration(minutes: 15))),
          'estimatedDuration': '15min',
          'status': 'available',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        {
          'driverId': 'driver_2',
          'driverName': 'Thabo Mthembu',
          'driverPhoto': '👨🏿‍🎓',
          'university': 'Stellenbosch',
          'driverRating': 4.9,
          'totalRides': 123,
          'carModel': 'Toyota Corolla',
          'carColor': 'Silver',
          'pickupLocation': {
            'name': 'Stellenbosch Central',
            'latitude': -33.9321,
            'longitude': 18.8602,
          },
          'dropoffLocation': {
            'name': 'Somerset West Mall',
            'latitude': -34.0781,
            'longitude': 18.8419,
          },
          'price': 18.0,
          'availableSeats': 2,
          'totalSeats': 4,
          'departureTime': Timestamp.fromDate(now.add(const Duration(minutes: 8))),
          'estimatedDuration': '12min',
          'status': 'departing',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        {
          'driverId': 'driver_3',
          'driverName': 'Zara Johnson',
          'driverPhoto': '👩🏼‍🎓',
          'university': 'UCT',
          'driverRating': 4.7,
          'totalRides': 89,
          'carModel': 'VW Polo',
          'carColor': 'Blue',
          'pickupLocation': {
            'name': 'Claremont Station',
            'latitude': -33.9847,
            'longitude': 18.4648,
          },
          'dropoffLocation': {
            'name': 'UCT Health Sciences',
            'latitude': -33.9459,
            'longitude': 18.4693,
          },
          'price': 12.0,
          'availableSeats': 1,
          'totalSeats': 4,
          'departureTime': Timestamp.fromDate(now.add(const Duration(minutes: 25))),
          'estimatedDuration': '8min',
          'status': 'available',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        {
          'driverId': 'driver_4',
          'driverName': 'Kyle van der Merwe',
          'driverPhoto': '👨🏼‍🎓',
          'university': 'Stellenbosch',
          'driverRating': 4.6,
          'totalRides': 156,
          'carModel': 'BMW 3 Series',
          'carColor': 'Black',
          'pickupLocation': {
            'name': 'Kayamandi',
            'latitude': -33.9176,
            'longitude': 18.8739,
          },
          'dropoffLocation': {
            'name': 'Stellenbosch University',
            'latitude': -33.9289,
            'longitude': 18.8646,
          },
          'price': 15.0,
          'availableSeats': 4,
          'totalSeats': 4,
          'departureTime': Timestamp.fromDate(now.add(const Duration(minutes: 35))),
          'estimatedDuration': '6min',
          'status': 'available',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        {
          'driverId': 'driver_5',
          'driverName': 'Lerato Molefe',
          'driverPhoto': '👩🏿‍🎓',
          'university': 'UCT',
          'driverRating': 4.9,
          'totalRides': 78,
          'carModel': 'Nissan Micra',
          'carColor': 'Red',
          'pickupLocation': {
            'name': 'Observatory Main Road',
            'latitude': -33.9244,
            'longitude': 18.4837,
          },
          'dropoffLocation': {
            'name': 'Woodstock Exchange',
            'latitude': -33.9304,
            'longitude': 18.4446,
          },
          'price': 22.0,
          'availableSeats': 2,
          'totalSeats': 4,
          'departureTime': Timestamp.fromDate(now.add(const Duration(minutes: 18))),
          'estimatedDuration': '10min',
          'status': 'available',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        {
          'driverId': 'driver_6',
          'driverName': 'Cameron Smith',
          'driverPhoto': '👨🏽‍🎓',
          'university': 'UWC',
          'driverRating': 4.5,
          'totalRides': 67,
          'carModel': 'Ford Fiesta',
          'carColor': 'Grey',
          'pickupLocation': {
            'name': 'UWC Campus',
            'latitude': -33.6844,
            'longitude': 18.6286,
          },
          'dropoffLocation': {
            'name': 'Parow Shopping Centre',
            'latitude': -33.6913,
            'longitude': 18.6356,
          },
          'price': 16.0,
          'availableSeats': 3,
          'totalSeats': 4,
          'departureTime': Timestamp.fromDate(now.add(const Duration(minutes: 42))),
          'estimatedDuration': '8min',
          'status': 'available',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        {
          'driverId': 'driver_7',
          'driverName': 'Nomsa Dlamini',
          'driverPhoto': '👩🏿‍🎓',
          'university': 'CPUT',
          'driverRating': 4.8,
          'totalRides': 134,
          'carModel': 'Hyundai i20',
          'carColor': 'White',
          'pickupLocation': {
            'name': 'CPUT Bellville',
            'latitude': -33.8818,
            'longitude': 18.6368,
          },
          'dropoffLocation': {
            'name': 'Tygervalley Centre',
            'latitude': -33.8518,
            'longitude': 18.6338,
          },
          'price': 20.0,
          'availableSeats': 1,
          'totalSeats': 4,
          'departureTime': Timestamp.fromDate(now.add(const Duration(minutes: 12))),
          'estimatedDuration': '7min',
          'status': 'departing',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
      ];

      print('🔄 Adding ${sampleRides.length} sample rides to Firebase...');
      
      // Add all rides in a batch for better performance
      final batch = _firestore.batch();
      for (final ride in sampleRides) {
        final docRef = _firestore.collection(_ridesCollection).doc();
        batch.set(docRef, ride);
      }
      
      await batch.commit();
      print('✅ Successfully added ${sampleRides.length} sample rides to Firebase');
    } catch (e) {
      print('❌ Failed to add sample rides: $e');
      rethrow;
    }
  }

  /// Updates an existing ride
  Future<void> updateRide(String rideId, Map<String, dynamic> updates) async {
    try {
      await _firestore.collection('rides').doc(rideId).update({
        ...updates,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update ride: $e');
    }
  }

  /// Deletes a ride
  Future<void> deleteRide(String rideId) async {
    try {
      await _firestore.collection('rides').doc(rideId).delete();
      print('✅ Ride deleted: $rideId');
    } catch (e) {
      print('❌ Error deleting ride: $e');
      throw Exception('Failed to delete ride: $e');
    }
  }

  /// Helper method to safely convert GeoPoint to LatLng
  LatLng _geoPointToLatLng(dynamic geoPointData) {
    try {
      if (geoPointData == null) {
        print('⚠️ GeoPoint data is null, using default UCT coordinates');
        return const LatLng(-33.9249, 18.4241); // Default to UCT
      }

      if (geoPointData is GeoPoint) {
        return LatLng(geoPointData.latitude, geoPointData.longitude);
      } else if (geoPointData is Map<String, dynamic>) {
        final lat = geoPointData['latitude'];
        final lng = geoPointData['longitude'];
        
        if (lat != null && lng != null) {
          return LatLng(lat.toDouble(), lng.toDouble());
        } else {
          print('⚠️ Invalid coordinates in GeoPoint map: lat=$lat, lng=$lng');
          return const LatLng(-33.9249, 18.4241); // Default to UCT
        }
      } else {
        print('⚠️ Unknown GeoPoint format: ${geoPointData.runtimeType}');
        return const LatLng(-33.9249, 18.4241); // Default to UCT
      }
    } catch (e) {
      print('❌ Error converting GeoPoint: $e');
      return const LatLng(-33.9249, 18.4241); // Default to UCT
    }
  }

  // Get notifications for a user
  Stream<List<Map<String, dynamic>>> getNotifications(String userId) {
    try {
      return _firestore
          .collection('notifications')
          .where('recipientId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .snapshots()
          .map((snapshot) {
            return snapshot.docs.map((doc) {
              final data = doc.data();
              return {
                'id': doc.id,
                'type': data['type'] ?? '',
                'title': data['title'] ?? '',
                'message': data['message'] ?? '',
                'senderName': data['senderName'] ?? '',
                'rideId': data['rideId'],
                'bookingId': data['bookingId'],
                'isRead': data['isRead'] ?? false,
                'createdAt': (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
              };
            }).toList();
          });
    } catch (e) {
      print('❌ Error getting notifications: $e');
      return Stream.value([]);
    }
  }

  // Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('❌ Error marking notification as read: $e');
    }
  }

  // Get unread notification count
  Stream<int> getUnreadNotificationCount(String userId) {
    try {
      return _firestore
          .collection('notifications')
          .where('recipientId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .snapshots()
          .map((snapshot) => snapshot.docs.length);
    } catch (e) {
      print('❌ Error getting unread count: $e');
      return Stream.value(0);
    }
  }
} 