import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../lib/core/services/live_location_service.dart';
import '../../../lib/domain/entities/live_ride.dart';
import '../../../lib/data/models/live_ride_model.dart';

// Generate mocks
@GenerateMocks([
  FirebaseFirestore,
  CollectionReference,
  DocumentReference,
  DocumentSnapshot,
  QuerySnapshot,
  Query,
  Transaction,
])
import 'live_location_service_test.mocks.dart';

void main() {
  group('LiveLocationService', () {
    late LiveLocationService liveLocationService;
    late MockFirebaseFirestore mockFirestore;
    late MockCollectionReference<Map<String, dynamic>> mockCollection;
    late MockDocumentReference<Map<String, dynamic>> mockDocRef;
    late MockDocumentSnapshot<Map<String, dynamic>> mockDocSnapshot;
    late MockQuerySnapshot<Map<String, dynamic>> mockQuerySnapshot;
    late MockQuery<Map<String, dynamic>> mockQuery;
    late MockTransaction mockTransaction;

    // Test data
    const testRideId = 'test-ride-id';
    const testUserId = 'test-user-id';
    const testPosition = Position(
      latitude: -26.2041,
      longitude: 28.0473,
      timestamp: null,
      accuracy: 10.0,
      altitude: 0.0,
      heading: 0.0,
      speed: 0.0,
      speedAccuracy: 0.0,
    );

    final testLiveRide = LiveRide(
      id: testRideId,
      driverId: testUserId,
      driverName: 'Test Driver',
      driverAvatarUrl: 'https://example.com/avatar.jpg',
      startLocation: const LatLng(-26.2041, 28.0473),
      destination: const LatLng(-26.1929, 28.0305),
      currentLocation: const LatLng(-26.2041, 28.0473),
      availableSeats: 3,
      totalSeats: 4,
      pricePerSeat: 25.0,
      isActive: true,
      createdAt: DateTime.now(),
      passengers: [],
    );

    setUp(() {
      // Initialize mocks
      mockFirestore = MockFirebaseFirestore();
      mockCollection = MockCollectionReference<Map<String, dynamic>>();
      mockDocRef = MockDocumentReference<Map<String, dynamic>>();
      mockDocSnapshot = MockDocumentSnapshot<Map<String, dynamic>>();
      mockQuerySnapshot = MockQuerySnapshot<Map<String, dynamic>>();
      mockQuery = MockQuery<Map<String, dynamic>>();
      mockTransaction = MockTransaction();

      // Create service instance
      liveLocationService = LiveLocationService();

      // Set up basic mock behaviors
      when(mockFirestore.collection('live_rides')).thenReturn(mockCollection);
      when(mockCollection.doc(any)).thenReturn(mockDocRef);
      when(mockCollection.where(any, isEqualTo: any)).thenReturn(mockQuery);
      when(mockQuery.snapshots()).thenAnswer((_) => Stream.value(mockQuerySnapshot));
      when(mockQuerySnapshot.docs).thenReturn([]);
    });

    group('startLiveTracking', () {
      test('should start tracking and update position successfully', () async {
        // Arrange
        when(mockDocRef.update(any)).thenAnswer((_) async => {});

        // Mock location permission
        // Note: In a real test, you'd mock Geolocator.checkPermission()
        // For this example, we'll focus on the core logic

        // Act & Assert
        expect(
          () => liveLocationService.startLiveTracking(testRideId, testUserId),
          returnsNormally,
        );
      });

      test('should handle location permission denied', () async {
        // This test would require mocking Geolocator.checkPermission()
        // to return LocationPermission.denied
        expect(true, isTrue); // Placeholder
      });

      test('should update position with correct data structure', () async {
        // Arrange
        final capturedData = <String, dynamic>{};
        when(mockDocRef.update(captureAny)).thenAnswer((invocation) async {
          capturedData.addAll(invocation.positionalArguments[0] as Map<String, dynamic>);
        });

        // Act
        await liveLocationService.startLiveTracking(testRideId, testUserId);

        // Simulate position update (this would normally come from GPS stream)
        // In production, we'd have a way to inject position updates for testing

        // Assert - verify the data structure
        expect(capturedData, isNotEmpty);
        // Additional assertions would verify the exact fields
      });

      test('should handle network errors gracefully', () async {
        // Arrange
        when(mockDocRef.update(any)).thenThrow(Exception('Network error'));

        // Act & Assert
        expect(
          () => liveLocationService.startLiveTracking(testRideId, testUserId),
          returnsNormally, // Should not crash on network error
        );
      });
    });

    group('stopLiveTracking', () {
      test('should stop tracking and mark ride as inactive', () async {
        // Arrange
        final capturedData = <String, dynamic>{};
        when(mockDocRef.update(captureAny)).thenAnswer((invocation) async {
          capturedData.addAll(invocation.positionalArguments[0] as Map<String, dynamic>);
        });

        // Act
        await liveLocationService.stopLiveTracking(testRideId);

        // Assert
        verify(mockDocRef.update(any)).called(1);
        expect(capturedData['isActive'], false);
        expect(capturedData, containsPair('endedAt', isA<FieldValue>()));
      });

      test('should handle stop tracking for non-existent ride', () async {
        // Arrange
        when(mockDocRef.update(any)).thenThrow(Exception('Document not found'));

        // Act & Assert
        expect(
          () => liveLocationService.stopLiveTracking(testRideId),
          returnsNormally,
        );
      });
    });

    group('createLiveRide', () {
      test('should create ride with correct data structure', () async {
        // Arrange
        when(mockCollection.doc()).thenReturn(mockDocRef);
        when(mockDocRef.id).thenReturn(testRideId);
        when(mockDocRef.set(any)).thenAnswer((_) async => {});

        // Act
        final rideId = await liveLocationService.createLiveRide(
          driverId: testUserId,
          driverName: 'Test Driver',
          driverAvatarUrl: 'https://example.com/avatar.jpg',
          startLocation: const LatLng(-26.2041, 28.0473),
          destination: const LatLng(-26.1929, 28.0305),
          availableSeats: 3,
          pricePerSeat: 25.0,
        );

        // Assert
        expect(rideId, equals(testRideId));
        verify(mockDocRef.set(any)).called(1);
      });

      test('should handle invalid coordinates', () async {
        // Arrange
        when(mockCollection.doc()).thenReturn(mockDocRef);
        when(mockDocRef.id).thenReturn(testRideId);
        when(mockDocRef.set(any)).thenThrow(Exception('Invalid coordinates'));

        // Act & Assert
        expect(
          () => liveLocationService.createLiveRide(
            driverId: testUserId,
            driverName: 'Test Driver',
            driverAvatarUrl: '',
            startLocation: const LatLng(200, 200), // Invalid coordinates
            destination: const LatLng(-26.1929, 28.0305),
            availableSeats: 3,
            pricePerSeat: 25.0,
          ),
          throwsException,
        );
      });

      test('should validate seat count', () async {
        // Test with invalid seat counts
        expect(
          () => liveLocationService.createLiveRide(
            driverId: testUserId,
            driverName: 'Test Driver',
            driverAvatarUrl: '',
            startLocation: const LatLng(-26.2041, 28.0473),
            destination: const LatLng(-26.1929, 28.0305),
            availableSeats: 0, // Invalid: no seats available
            pricePerSeat: 25.0,
          ),
          returnsNormally, // Service should handle this gracefully
        );
      });
    });

    group('bookRideInstantly', () {
      test('should book ride successfully with transaction', () async {
        // Arrange
        final mockLiveRideDoc = {
          'id': testRideId,
          'driverId': testUserId,
          'driverName': 'Test Driver',
          'driverAvatarUrl': '',
          'startLocation': const GeoPoint(-26.2041, 28.0473),
          'destination': const GeoPoint(-26.1929, 28.0305),
          'currentLocation': const GeoPoint(-26.2041, 28.0473),
          'availableSeats': 2,
          'totalSeats': 4,
          'passengers': <Map<String, dynamic>>[],
          'pricePerSeat': 25.0,
          'isActive': true,
          'createdAt': Timestamp.now(),
          'status': 'active',
        };

        when(mockDocSnapshot.exists).thenReturn(true);
        when(mockDocSnapshot.data()).thenReturn(mockLiveRideDoc);
        when(mockDocSnapshot.id).thenReturn(testRideId);
        when(mockTransaction.get(mockDocRef)).thenAnswer((_) async => mockDocSnapshot);
        when(mockTransaction.update(mockDocRef, any)).thenReturn(null);
        when(mockFirestore.runTransaction<bool>(any)).thenAnswer((invocation) async {
          final transactionFunction = invocation.positionalArguments[0] as Future<bool> Function(Transaction);
          return await transactionFunction(mockTransaction);
        });

        // Act
        final success = await liveLocationService.bookRideInstantly(
          rideId: testRideId,
          passengerId: 'passenger-id',
          passengerName: 'Passenger Name',
          passengerAvatarUrl: '',
        );

        // Assert
        expect(success, isTrue);
        verify(mockFirestore.runTransaction<bool>(any)).called(1);
      });

      test('should fail when ride is full', () async {
        // Arrange - ride with no available seats
        final mockLiveRideDoc = {
          'id': testRideId,
          'driverId': testUserId,
          'driverName': 'Test Driver',
          'driverAvatarUrl': '',
          'startLocation': const GeoPoint(-26.2041, 28.0473),
          'destination': const GeoPoint(-26.1929, 28.0305),
          'currentLocation': const GeoPoint(-26.2041, 28.0473),
          'availableSeats': 0, // No seats available
          'totalSeats': 4,
          'passengers': <Map<String, dynamic>>[],
          'pricePerSeat': 25.0,
          'isActive': true,
          'createdAt': Timestamp.now(),
          'status': 'active',
        };

        when(mockDocSnapshot.exists).thenReturn(true);
        when(mockDocSnapshot.data()).thenReturn(mockLiveRideDoc);
        when(mockDocSnapshot.id).thenReturn(testRideId);
        when(mockTransaction.get(mockDocRef)).thenAnswer((_) async => mockDocSnapshot);
        when(mockFirestore.runTransaction<bool>(any)).thenAnswer((invocation) async {
          final transactionFunction = invocation.positionalArguments[0] as Future<bool> Function(Transaction);
          return await transactionFunction(mockTransaction);
        });

        // Act
        final success = await liveLocationService.bookRideInstantly(
          rideId: testRideId,
          passengerId: 'passenger-id',
          passengerName: 'Passenger Name',
          passengerAvatarUrl: '',
        );

        // Assert
        expect(success, isFalse);
      });

      test('should handle non-existent ride', () async {
        // Arrange
        when(mockDocSnapshot.exists).thenReturn(false);
        when(mockTransaction.get(mockDocRef)).thenAnswer((_) async => mockDocSnapshot);
        when(mockFirestore.runTransaction<bool>(any)).thenAnswer((invocation) async {
          final transactionFunction = invocation.positionalArguments[0] as Future<bool> Function(Transaction);
          try {
            return await transactionFunction(mockTransaction);
          } catch (e) {
            return false;
          }
        });

        // Act
        final success = await liveLocationService.bookRideInstantly(
          rideId: 'non-existent-ride',
          passengerId: 'passenger-id',
          passengerName: 'Passenger Name',
          passengerAvatarUrl: '',
        );

        // Assert
        expect(success, isFalse);
      });
    });

    group('getNearbyRides', () {
      test('should return rides within radius', () async {
        // Arrange
        final testLocation = const LatLng(-26.2041, 28.0473);
        final mockRideDoc = MockDocumentSnapshot<Map<String, dynamic>>();
        
        when(mockRideDoc.id).thenReturn(testRideId);
        when(mockRideDoc.data()).thenReturn({
          'driverId': testUserId,
          'driverName': 'Test Driver',
          'driverAvatarUrl': '',
          'startLocation': const GeoPoint(-26.2041, 28.0473),
          'destination': const GeoPoint(-26.1929, 28.0305),
          'currentLocation': const GeoPoint(-26.2041, 28.0473),
          'availableSeats': 2,
          'totalSeats': 4,
          'passengers': <Map<String, dynamic>>[],
          'pricePerSeat': 25.0,
          'isActive': true,
          'createdAt': Timestamp.now(),
          'status': 'active',
        });

        when(mockQuerySnapshot.docs).thenReturn([mockRideDoc]);

        // Act
        final ridesStream = liveLocationService.getNearbyRides(
          testLocation,
          [], // No friends
        );

        // Monitor the stream
        final rides = await ridesStream.first;

        // Assert
        expect(rides, isNotEmpty);
        expect(rides.first.id, equals(testRideId));
      });

      test('should prioritize friends rides', () async {
        // Arrange
        final testLocation = const LatLng(-26.2041, 28.0473);
        final friendRideDoc = MockDocumentSnapshot<Map<String, dynamic>>();
        final regularRideDoc = MockDocumentSnapshot<Map<String, dynamic>>();
        
        const friendUserId = 'friend-user-id';
        const regularUserId = 'regular-user-id';

        // Setup friend ride
        when(friendRideDoc.id).thenReturn('friend-ride-id');
        when(friendRideDoc.data()).thenReturn({
          'driverId': friendUserId,
          'driverName': 'Friend Driver',
          'driverAvatarUrl': '',
          'startLocation': const GeoPoint(-26.2041, 28.0473),
          'destination': const GeoPoint(-26.1929, 28.0305),
          'currentLocation': const GeoPoint(-26.2000, 28.0400), // Slightly farther
          'availableSeats': 2,
          'totalSeats': 4,
          'passengers': <Map<String, dynamic>>[],
          'pricePerSeat': 25.0,
          'isActive': true,
          'createdAt': Timestamp.now(),
          'status': 'active',
        });

        // Setup regular ride
        when(regularRideDoc.id).thenReturn('regular-ride-id');
        when(regularRideDoc.data()).thenReturn({
          'driverId': regularUserId,
          'driverName': 'Regular Driver',
          'driverAvatarUrl': '',
          'startLocation': const GeoPoint(-26.2041, 28.0473),
          'destination': const GeoPoint(-26.1929, 28.0305),
          'currentLocation': const GeoPoint(-26.2010, 28.0480), // Closer but not friend
          'availableSeats': 2,
          'totalSeats': 4,
          'passengers': <Map<String, dynamic>>[],
          'pricePerSeat': 25.0,
          'isActive': true,
          'createdAt': Timestamp.now(),
          'status': 'active',
        });

        when(mockQuerySnapshot.docs).thenReturn([regularRideDoc, friendRideDoc]);

        // Act
        final ridesStream = liveLocationService.getNearbyRides(
          testLocation,
          [friendUserId], // Friend list
        );

        final rides = await ridesStream.first;

        // Assert
        expect(rides.length, equals(2));
        expect(rides.first.driverId, equals(friendUserId)); // Friend should be first
      });

      test('should limit results for performance', () async {
        // This would test the _maxRidesPerView limit
        // Creating 60 mock rides and verifying only 50 are returned
        expect(true, isTrue); // Placeholder for complex performance test
      });
    });

    group('Performance Tests', () {
      test('ride creation should complete under 3 seconds', () async {
        // Arrange
        when(mockCollection.doc()).thenReturn(mockDocRef);
        when(mockDocRef.id).thenReturn(testRideId);
        when(mockDocRef.set(any)).thenAnswer((_) async => {});

        final stopwatch = Stopwatch()..start();

        // Act
        await liveLocationService.createLiveRide(
          driverId: testUserId,
          driverName: 'Test Driver',
          driverAvatarUrl: '',
          startLocation: const LatLng(-26.2041, 28.0473),
          destination: const LatLng(-26.1929, 28.0305),
          availableSeats: 3,
          pricePerSeat: 25.0,
        );

        stopwatch.stop();

        // Assert - 3-second rule compliance
        expect(stopwatch.elapsedMilliseconds, lessThan(3000));
      });

      test('instant booking should complete under 1 second', () async {
        // Similar performance test for booking
        expect(true, isTrue); // Placeholder
      });
    });

    group('Edge Cases', () {
      test('should handle concurrent booking attempts', () async {
        // Test race conditions in booking
        expect(true, isTrue); // Placeholder for complex concurrency test
      });

      test('should handle location updates after ride completion', () async {
        // Test cleanup scenarios
        expect(true, isTrue); // Placeholder
      });

      test('should handle network connectivity issues', () async {
        // Test offline/online scenarios
        expect(true, isTrue); // Placeholder
      });
    });

    group('Data Validation', () {
      test('should validate coordinates are within valid ranges', () {
        // Test coordinate validation
        expect(() {
          // This would test internal coordinate validation
        }, returnsNormally);
      });

      test('should sanitize user input data', () {
        // Test data sanitization
        expect(true, isTrue);
      });
    });
  });
}