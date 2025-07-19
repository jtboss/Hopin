import 'package:firebase_auth/firebase_auth.dart';

class FirebaseAuthServiceSimple {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;
  
  // Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Simple sign up - just Firebase Auth, no Firestore
  Future<UserCredential?> signUpWithEmailSimple({
    required String email,
    required String password,
  }) async {
    try {
      print('🔐 Creating Firebase Auth user for: $email');
      
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      print('✅ Firebase Auth user created successfully: ${credential.user?.uid}');
      return credential;
      
    } on FirebaseAuthException catch (e) {
      print('❌ FirebaseAuthException: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      print('❌ General exception: $e');
      throw Exception('Signup failed: $e');
    }
  }

  // Simple sign in
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      print('🔐 Signing in user: $email');
      
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      print('✅ Sign in successful: ${credential.user?.uid}');
      return credential;
      
    } on FirebaseAuthException catch (e) {
      print('❌ SignIn FirebaseAuthException: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      print('❌ SignIn General exception: $e');
      throw Exception('Sign in failed: $e');
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Handle Firebase Auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'Password is too weak (minimum 6 characters)';
      case 'email-already-in-use':
        return 'An account already exists for this email';
      case 'user-not-found':
        return 'No account found for this email';
      case 'wrong-password':
        return 'Incorrect password';
      case 'invalid-email':
        return 'Invalid email address';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later';
      case 'operation-not-allowed':
        return 'Email/password sign-in is not enabled';
      default:
        return 'Authentication error: ${e.message}';
    }
  }
} 