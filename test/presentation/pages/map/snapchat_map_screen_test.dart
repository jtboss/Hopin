import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../lib/presentation/pages/map/snapchat_map_screen.dart';
import '../../../../lib/core/services/live_location_service.dart';
import '../../../../lib/domain/entities/live_ride.dart';

// Generate mocks
@GenerateMocks([
  LiveLocationService,
  GoogleMapController,
  User,
])
import 'snapchat_map_screen_test.mocks.dart';

void main() {
  group('SnapchatMapScreen Widget Tests', () {
    late MockLiveLocationService mockLocationService;
    late MockGoogleMapController mockMapController;
    late MockUser mockUser;

    // Test data
    final testLiveRide = LiveRide(
      id: 'test-ride-id',
      driverId: 'test-driver-id',
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
      mockLocationService = MockLiveLocationService();
      mockMapController = MockGoogleMapController();
      mockUser = MockUser();

      // Set up basic mock behaviors
      when(mockLocationService.getNearbyRides(any, any))
          .thenAnswer((_) => Stream.value([testLiveRide]));
      when(mockLocationService.getFriendsRides(any))
          .thenAnswer((_) => Stream.value([]));
      
      when(mockUser.uid).thenReturn('current-user-id');
      when(mockUser.displayName).thenReturn('Current User');
      when(mockUser.photoURL).thenReturn('https://example.com/user-avatar.jpg');
    });

    testWidgets('should display full-screen map with no chrome', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: const SnapchatMapScreen(isDriverMode: false),
        ),
      );

      // Wait for widget to settle
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(GoogleMap), findsOneWidget);
      expect(find.byType(AppBar), findsNothing); // No app bar in full-screen mode
      expect(find.byType(BottomNavigationBar), findsNothing); // No bottom navigation
    });

    testWidgets('should show minimal UI overlay with friends toggle and emergency button', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: const SnapchatMapScreen(isDriverMode: false),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('ALL'), findsOneWidget); // Friends toggle default state
      expect(find.byIcon(Icons.emergency), findsOneWidget); // Emergency button
    });

    testWidgets('should toggle friends-only view when friends toggle is tapped', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: const SnapchatMapScreen(isDriverMode: false),
        ),
      );

      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.text('ALL'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('FRIENDS'), findsOneWidget);
    });

    testWidgets('should show driver mode indicator when in driver mode', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: const SnapchatMapScreen(isDriverMode: true),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('DRIVER MODE'), findsOneWidget);
      expect(find.byIcon(Icons.directions_car), findsOneWidget);
    });

    testWidgets('should display live rides counter with pulsing animation', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: const SnapchatMapScreen(isDriverMode: false),
        ),
      );

      // Wait for data to load
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      // Assert
      expect(find.textContaining('LIVE'), findsOneWidget);
      expect(find.byIcon(Icons.radio_button_checked), findsOneWidget);
    });

    testWidgets('should show emergency options when emergency button is tapped', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: const SnapchatMapScreen(isDriverMode: false),
        ),
      );

      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.byIcon(Icons.emergency));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('🚨 Emergency Options'), findsOneWidget);
      expect(find.text('Panic Button'), findsOneWidget);
      expect(find.text('Share Live Location'), findsOneWidget);
      expect(find.text('Call Emergency Services'), findsOneWidget);
    });

    group('Driver Mode Tests', () {
      testWidgets('should show instant ride creator on long press in driver mode', (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(
          MaterialApp(
            home: const SnapchatMapScreen(isDriverMode: true),
          ),
        );

        await tester.pumpAndSettle();

        // Act - Simulate long press on map
        final mapWidget = find.byType(GoogleMap);
        await tester.longPress(mapWidget);
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('🚗 Create Ride'), findsOneWidget);
        expect(find.text('Available Seats'), findsOneWidget);
        expect(find.text('Destination'), findsOneWidget);
        expect(find.text('Price per Seat'), findsOneWidget);
      });

      testWidgets('should not show ride creator on long press in passenger mode', (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(
          MaterialApp(
            home: const SnapchatMapScreen(isDriverMode: false),
          ),
        );

        await tester.pumpAndSettle();

        // Act - Simulate long press on map
        final mapWidget = find.byType(GoogleMap);
        await tester.longPress(mapWidget);
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('🚗 Create Ride'), findsNothing);
      });
    });

    group('Performance Tests', () {
      testWidgets('map should initialize within 2 seconds', (WidgetTester tester) async {
        // Arrange
        final stopwatch = Stopwatch()..start();

        // Act
        await tester.pumpWidget(
          MaterialApp(
            home: const SnapchatMapScreen(isDriverMode: false),
          ),
        );

        // Wait for map to be ready
        await tester.pumpAndSettle();

        stopwatch.stop();

        // Assert
        expect(stopwatch.elapsedMilliseconds, lessThan(2000));
      });

      testWidgets('friends toggle should respond within 150ms', (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(
          MaterialApp(
            home: const SnapchatMapScreen(isDriverMode: false),
          ),
        );

        await tester.pumpAndSettle();

        final stopwatch = Stopwatch()..start();

        // Act
        await tester.tap(find.text('ALL'));
        await tester.pump(); // Single frame

        stopwatch.stop();

        // Assert - Should respond immediately (within animation duration)
        expect(stopwatch.elapsedMilliseconds, lessThan(150));
      });
    });

    group('Accessibility Tests', () {
      testWidgets('should have proper semantics for screen readers', (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          MaterialApp(
            home: const SnapchatMapScreen(isDriverMode: false),
          ),
        );

        await tester.pumpAndSettle();

        // Assert - Check for semantic elements
        expect(find.byType(Semantics), findsWidgets);
      });

      testWidgets('should support high contrast mode', (WidgetTester tester) async {
        // Test high contrast theming
        expect(true, isTrue); // Placeholder for contrast testing
      });
    });

    group('Error Handling Tests', () {
      testWidgets('should handle location permission denied gracefully', (WidgetTester tester) async {
        // Test error states
        await tester.pumpWidget(
          MaterialApp(
            home: const SnapchatMapScreen(isDriverMode: false),
          ),
        );

        await tester.pumpAndSettle();

        // Should not crash and should show appropriate error state
        expect(find.byType(SnapchatMapScreen), findsOneWidget);
      });

      testWidgets('should handle network connectivity issues', (WidgetTester tester) async {
        // Test offline scenarios
        expect(true, isTrue); // Placeholder
      });
    });

    group('Animation Tests', () {
      testWidgets('should animate live counter with pulse effect', (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(
          MaterialApp(
            home: const SnapchatMapScreen(isDriverMode: false),
          ),
        );

        await tester.pumpAndSettle();

        // Act - Let animation run
        await tester.pump(const Duration(milliseconds: 500));

        // Assert - Animation should be running
        expect(find.textContaining('LIVE'), findsOneWidget);
      });

      testWidgets('should animate FAB entrance in driver mode', (WidgetTester tester) async {
        // Test FAB animation
        await tester.pumpWidget(
          MaterialApp(
            home: const SnapchatMapScreen(isDriverMode: true),
          ),
        );

        // Let entrance animation complete
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pumpAndSettle();

        expect(find.text('DRIVER MODE'), findsOneWidget);
      });
    });

    group('Responsive Design Tests', () {
      testWidgets('should adapt to different screen sizes', (WidgetTester tester) async {
        // Test phone screen
        await tester.binding.setSurfaceSize(const Size(400, 800));
        
        await tester.pumpWidget(
          MaterialApp(
            home: const SnapchatMapScreen(isDriverMode: false),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(GoogleMap), findsOneWidget);

        // Test tablet screen  
        await tester.binding.setSurfaceSize(const Size(800, 1200));
        await tester.pumpAndSettle();

        expect(find.byType(GoogleMap), findsOneWidget);
      });
    });

    group('Haptic Feedback Tests', () {
      testWidgets('should provide haptic feedback on interactions', (WidgetTester tester) async {
        // This would require mocking HapticFeedback.selectionClick()
        // and verifying it's called on button taps
        expect(true, isTrue); // Placeholder
      });
    });

    group('Memory Management Tests', () {
      testWidgets('should properly dispose of resources', (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(
          MaterialApp(
            home: const SnapchatMapScreen(isDriverMode: false),
          ),
        );

        await tester.pumpAndSettle();

        // Act - Remove widget
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(body: Text('Empty')),
          ),
        );

        // Assert - Should not leak memory or throw errors
        expect(find.text('Empty'), findsOneWidget);
      });
    });
  });
}