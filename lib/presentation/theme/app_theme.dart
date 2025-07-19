import 'package:flutter/material.dart';

/// Hopin app color scheme
class HopinColors {
  // Primary brand colors
  static const Color primary = Color(0xFF6366F1); // Indigo
  static const Color primaryContainer = Color(0xFFE0E7FF);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryContainer = Color(0xFF1E1B3A);

  // Secondary colors
  static const Color secondary = Color(0xFF10B981); // Emerald
  static const Color secondaryContainer = Color(0xFFD1FAE5);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color onSecondaryContainer = Color(0xFF064E3B);

  // Error colors
  static const Color error = Color(0xFFEF4444);
  static const Color errorContainer = Color(0xFFFEE2E2);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color onErrorContainer = Color(0xFF7F1D1D);

  // Surface colors
  static const Color surface = Color(0xFFFAFAFA);
  static const Color surfaceVariant = Color(0xFFF3F4F6);
  static const Color surfaceContainerHighest = Color(0xFFF3F4F6);
  static const Color onSurface = Color(0xFF111827);
  static const Color onSurfaceVariant = Color(0xFF6B7280);

  // Background colors
  static const Color background = Color(0xFFFFFFFF);
  static const Color onBackground = Color(0xFF111827);

  // Outline colors
  static const Color outline = Color(0xFFD1D5DB);
  static const Color outlineVariant = Color(0xFFE5E7EB);

  // Status colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);

  // Ride status colors
  static const Color rideRequested = Color(0xFF8B5CF6);
  static const Color ridePending = Color(0xFFF59E0B);
  static const Color rideAccepted = Color(0xFF10B981);
  static const Color rideInProgress = Color(0xFF3B82F6);
  static const Color rideCompleted = Color(0xFF059669);
  static const Color rideCancelled = Color(0xFFEF4444);
}

/// App theme configuration
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
      ),
      
      // Typography
      textTheme: _textTheme,
      
      // App Bar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: HopinColors.background,
        foregroundColor: HopinColors.onBackground,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: HopinColors.onBackground,
        ),
      ),
      
      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: HopinColors.primary,
          foregroundColor: HopinColors.onPrimary,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // Filled Button Theme
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: HopinColors.primary,
          foregroundColor: HopinColors.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: HopinColors.primary,
          side: const BorderSide(color: HopinColors.primary),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: HopinColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: HopinColors.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: HopinColors.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: HopinColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: HopinColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: HopinColors.error, width: 2),
        ),
        filled: true,
        fillColor: HopinColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: const TextStyle(
          color: HopinColors.onSurfaceVariant,
          fontSize: 16,
        ),
      ),
      
      // Card Theme
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: HopinColors.background,
        shadowColor: HopinColors.onBackground.withValues(alpha: 0.1),
      ),
      
      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: HopinColors.background,
        selectedItemColor: HopinColors.primary,
        unselectedItemColor: HopinColors.onSurfaceVariant,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
      ),
      
      // Floating Action Button Theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: HopinColors.primary,
        foregroundColor: HopinColors.onPrimary,
        elevation: 4,
      ),
      
      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: HopinColors.surfaceVariant,
        labelStyle: const TextStyle(
          color: HopinColors.onSurface,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: HopinColors.primary,
        primaryContainer: Color(0xFF312E81),
        onPrimary: HopinColors.onPrimary,
        onPrimaryContainer: Color(0xFFC7D2FE),
        secondary: HopinColors.secondary,
        secondaryContainer: Color(0xFF065F46),
        onSecondary: HopinColors.onSecondary,
        onSecondaryContainer: Color(0xFFA7F3D0),
        error: HopinColors.error,
        errorContainer: Color(0xFF991B1B),
        onError: HopinColors.onError,
        onErrorContainer: Color(0xFFFECACA),
        surface: Color(0xFF1F2937),
        surfaceContainerHighest: Color(0xFF374151),
        onSurface: Color(0xFFF9FAFB),
        onSurfaceVariant: Color(0xFF9CA3AF),
        outline: Color(0xFF4B5563),
        outlineVariant: Color(0xFF374151),
      ),
      textTheme: _textTheme.apply(
        bodyColor: const Color(0xFFF9FAFB),
        displayColor: const Color(0xFFF9FAFB),
      ),
    );
  }

  static const TextTheme _textTheme = TextTheme(
    displayLarge: TextStyle(
      fontSize: 57,
      fontWeight: FontWeight.w400,
      letterSpacing: -0.25,
    ),
    displayMedium: TextStyle(
      fontSize: 45,
      fontWeight: FontWeight.w400,
    ),
    displaySmall: TextStyle(
      fontSize: 36,
      fontWeight: FontWeight.w400,
    ),
    headlineLarge: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.w600,
    ),
    headlineMedium: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w600,
    ),
    headlineSmall: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w600,
    ),
    titleLarge: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w600,
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.15,
    ),
    titleSmall: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.1,
    ),
    labelLarge: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.1,
    ),
    labelMedium: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
    ),
    labelSmall: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
    ),
    bodyLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.5,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.25,
    ),
    bodySmall: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.4,
    ),
  );
}

/// Custom text styles for specific use cases
class HopinTextStyles {
  static const TextStyle appBarTitle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: HopinColors.onBackground,
  );

  static const TextStyle rideTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: HopinColors.onSurface,
  );

  static const TextStyle rideSubtitle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: HopinColors.onSurfaceVariant,
  );

  static const TextStyle priceText = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: HopinColors.primary,
  );

  static const TextStyle statusText = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: HopinColors.onSurfaceVariant,
  );
} 