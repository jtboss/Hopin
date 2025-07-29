import 'package:flutter/material.dart';

/// Hopin 2.0 Snapchat-inspired color scheme
class HopinColors {
  // Primary Colors (Snapchat-inspired)
  static const Color snapchatYellow = Color(0xFFFFFC00);
  static const Color ghostWhite = Color(0xFFFAFAFA);
  static const Color midnightBlue = Color(0xFF162447);
  
  // Accent Colors
  static const Color liveGreen = Color(0xFF00D4AA);
  static const Color urgentRed = Color(0xFFFF006E);
  static const Color friendGold = Color(0xFFFFD700);
  
  // Legacy compatibility - mapped to new system
  static const Color primary = snapchatYellow;
  static const Color primaryContainer = Color(0xFFFFFE80);
  static const Color onPrimary = midnightBlue;
  static const Color onPrimaryContainer = midnightBlue;

  static const Color secondary = liveGreen;
  static const Color secondaryContainer = Color(0xFF80EAD7);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color onSecondaryContainer = Color(0xFF004D3D);

  static const Color error = urgentRed;
  static const Color errorContainer = Color(0xFFFF80B7);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color onErrorContainer = Color(0xFF800037);

  static const Color surface = ghostWhite;
  static const Color surfaceVariant = Color(0xFFF0F0F0);
  static const Color surfaceContainerHighest = Color(0xFFE8E8E8);
  static const Color onSurface = midnightBlue;
  static const Color onSurfaceVariant = Color(0xFF4A5568);

  static const Color background = Color(0xFFFFFFFF);
  static const Color onBackground = midnightBlue;

  static const Color outline = Color(0xFFD1D5DB);
  static const Color outlineVariant = Color(0xFFE5E7EB);

  // Social status colors
  static const Color friendOnline = friendGold;
  static const Color rideActive = liveGreen;
  static const Color rideRequested = Color(0xFF8B5CF6);
  static const Color ridePending = Color(0xFFF59E0B);
  static const Color rideAccepted = liveGreen;
  static const Color rideInProgress = Color(0xFF3B82F6);
  static const Color rideCompleted = Color(0xFF059669);
  static const Color rideCancelled = urgentRed;
}

/// Hopin 2.0 Animation Configuration
class HopinAnimations {
  // Snapchat-style quick animations
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration medium = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  
  // Signature curves
  static const Curve snapBounce = Curves.elasticOut;
  static const Curve snapEase = Curves.easeInOut;
  static const Curve snapQuick = Curves.easeOut;
}

/// App theme configuration with Gen-Z design principles
class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        primary: HopinColors.primary,
        primaryContainer: HopinColors.primaryContainer,
        onPrimary: HopinColors.onPrimary,
        onPrimaryContainer: HopinColors.onPrimaryContainer,
        secondary: HopinColors.secondary,
        secondaryContainer: HopinColors.secondaryContainer,
        onSecondary: HopinColors.onSecondary,
        onSecondaryContainer: HopinColors.onSecondaryContainer,
        error: HopinColors.error,
        errorContainer: HopinColors.errorContainer,
        onError: HopinColors.onError,
        onErrorContainer: HopinColors.onErrorContainer,
        surface: HopinColors.surface,
        surfaceContainerHighest: HopinColors.surfaceVariant,
        onSurface: HopinColors.onSurface,
        onSurfaceVariant: HopinColors.onSurfaceVariant,
        outline: HopinColors.outline,
        outlineVariant: HopinColors.outlineVariant,
        background: HopinColors.background,
        onBackground: HopinColors.onBackground,
      ),
      
      // Gen-Z Typography (Proxima Nova inspired)
      textTheme: _genZTextTheme,
      
      // App Bar Theme (minimal for map-first experience)
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: HopinColors.onBackground,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: HopinColors.onBackground,
          letterSpacing: -0.5,
        ),
      ),
      
      // Snapchat-style button themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: HopinColors.snapchatYellow,
          foregroundColor: HopinColors.midnightBlue,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
      ),
      
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: HopinColors.snapchatYellow,
          foregroundColor: HopinColors.midnightBlue,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
      ),
      
      // Minimal input decoration for quick interactions
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: const BorderSide(color: HopinColors.snapchatYellow, width: 2),
        ),
        filled: true,
        fillColor: HopinColors.ghostWhite,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        hintStyle: const TextStyle(
          color: HopinColors.onSurfaceVariant,
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
      ),
      
      // Card theme for minimal UI elements
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        color: HopinColors.background.withOpacity(0.9),
        shadowColor: HopinColors.onBackground.withOpacity(0.05),
      ),
      
      // Floating Action Button for primary actions
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: HopinColors.snapchatYellow,
        foregroundColor: HopinColors.midnightBlue,
        elevation: 4,
        shape: CircleBorder(),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: HopinColors.snapchatYellow,
        primaryContainer: Color(0xFF4A4A00),
        onPrimary: HopinColors.midnightBlue,
        onPrimaryContainer: HopinColors.snapchatYellow,
        secondary: HopinColors.liveGreen,
        secondaryContainer: Color(0xFF006B54),
        onSecondary: HopinColors.midnightBlue,
        onSecondaryContainer: HopinColors.liveGreen,
        error: HopinColors.urgentRed,
        errorContainer: Color(0xFFB30052),
        onError: Color(0xFFFFFFFF),
        onErrorContainer: HopinColors.urgentRed,
        surface: HopinColors.midnightBlue,
        surfaceContainerHighest: Color(0xFF1F2937),
        onSurface: HopinColors.ghostWhite,
        onSurfaceVariant: Color(0xFF9CA3AF),
        outline: Color(0xFF4B5563),
        outlineVariant: Color(0xFF374151),
        background: Color(0xFF111827),
        onBackground: HopinColors.ghostWhite,
      ),
      textTheme: _genZTextTheme.apply(
        bodyColor: HopinColors.ghostWhite,
        displayColor: HopinColors.ghostWhite,
      ),
    );
  }

  // Gen-Z optimized typography
  static const TextTheme _genZTextTheme = TextTheme(
    displayLarge: TextStyle(
      fontSize: 57,
      fontWeight: FontWeight.w700,
      letterSpacing: -1.0,
      height: 1.1,
    ),
    displayMedium: TextStyle(
      fontSize: 45,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.8,
      height: 1.1,
    ),
    displaySmall: TextStyle(
      fontSize: 36,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.5,
      height: 1.2,
    ),
    headlineLarge: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.5,
      height: 1.2,
    ),
    headlineMedium: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.3,
      height: 1.3,
    ),
    headlineSmall: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.2,
      height: 1.3,
    ),
    titleLarge: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.1,
      height: 1.4,
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      letterSpacing: 0,
      height: 1.4,
    ),
    titleSmall: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
      height: 1.4,
    ),
    labelLarge: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.1,
      height: 1.4,
    ),
    labelMedium: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
      height: 1.4,
    ),
    labelSmall: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
      height: 1.4,
    ),
    bodyLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
      height: 1.4,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
      height: 1.4,
    ),
    bodySmall: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.2,
      height: 1.4,
    ),
  );
  
  // Map styling for Snapchat-like appearance
  static const String snapchatMapStyle = '''
  [
    {
      "featureType": "all",
      "stylers": [
        {"saturation": -20},
        {"lightness": 15},
        {"gamma": 1.2}
      ]
    },
    {
      "featureType": "road",
      "stylers": [
        {"color": "#FFFFFF"},
        {"weight": 1}
      ]
    },
    {
      "featureType": "water",
      "stylers": [
        {"color": "#E3F2FD"}
      ]
    },
    {
      "featureType": "landscape",
      "stylers": [
        {"color": "#FAFAFA"}
      ]
    },
    {
      "featureType": "poi",
      "stylers": [
        {"visibility": "simplified"},
        {"color": "#F0F0F0"}
      ]
    }
  ]
  ''';
}

/// Snapchat-style text styles for specific use cases
class HopinTextStyles {
  static const TextStyle snapchatButton = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: HopinColors.midnightBlue,
    letterSpacing: -0.2,
  );

  static const TextStyle rideMarkerText = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: HopinColors.onPrimary,
    letterSpacing: 0,
  );

  static const TextStyle friendName = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: HopinColors.friendGold,
    letterSpacing: -0.1,
  );

  static const TextStyle liveIndicator = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w700,
    color: HopinColors.liveGreen,
    letterSpacing: 0.5,
  );

  static const TextStyle emergencyText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: HopinColors.urgentRed,
    letterSpacing: -0.1,
  );

  static const TextStyle gestureResponse = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w400,
  );
}

/// Custom animation helpers
class HopinAnimationHelpers {
  // Signature bounce animation for ride markers
  static Animation<double> rideMarkerEntrance(AnimationController controller) {
    return Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: controller,
        curve: HopinAnimations.snapBounce,
      ),
    );
  }
  
  // Gesture feedback animation
  static Animation<double> gestureFlash(AnimationController controller) {
    return Tween<double>(begin: 1.0, end: 1.5).animate(
      CurvedAnimation(
        parent: controller,
        curve: HopinAnimations.snapEase,
      ),
    );
  }
  
  // Quick fade animation for UI elements
  static Animation<double> quickFade(AnimationController controller) {
    return Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: controller,
        curve: HopinAnimations.snapQuick,
      ),
    );
  }
} 