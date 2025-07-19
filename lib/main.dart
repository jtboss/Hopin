import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Import our custom theme and pages
import 'presentation/theme/app_theme.dart';
import 'presentation/pages/home/main_navigation_screen.dart';
import 'presentation/pages/auth/login_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // Only log in debug mode
    if (kDebugMode) {
      debugPrint('✅ Firebase initialized successfully');
    }
  } catch (e) {
    // Only log in debug mode
    if (kDebugMode) {
      debugPrint('❌ Firebase initialization failed: $e');
    }
    
    // In production, you might want to show an error screen or retry
    // For now, we'll continue without crashing
  }
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  runApp(const HopinApp());
}

class HopinApp extends StatelessWidget {
  const HopinApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hopin',
      debugShowCheckedModeBanner: kDebugMode, // Only show in debug mode
      
      // Use our custom Uber-inspired theme
      theme: AppTheme.lightTheme,
      
      // Use StreamBuilder to handle authentication state
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // Show loading while checking auth state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
          
          // If user is logged in, show main navigation
          if (snapshot.hasData && snapshot.data != null) {
            return const MainNavigationScreen();
          }
          
          // If not logged in, show login screen
          return const LoginScreen();
        },
      ),
    );
  }
} 