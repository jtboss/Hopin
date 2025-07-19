import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;
  
  // Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign up with email and password
  Future<UserCredential?> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
    required String university,
    required String studentNumber,
  }) async {
    try {
      print('🔍 Validating email: $email');
      
      // Check if email domain is allowed (university email)
      if (!_isUniversityEmail(email)) {
        throw Exception('Please use your university email address');
      }
      print('✅ Email validation passed');

      print('🔐 Creating Firebase Auth user...');
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      print('✅ Firebase Auth user created: ${credential.user?.uid}');

      // Create user profile in Firestore
      if (credential.user != null) {
        print('📝 Creating user profile for ${credential.user!.uid}');
        await _createUserProfile(
          uid: credential.user!.uid,
          email: email,
          fullName: fullName,
          university: university,
          studentNumber: studentNumber,
        );
        print('✅ User profile created successfully');

        // TODO: Re-enable email verification in production
        // await credential.user!.sendEmailVerification();
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      print('❌ FirebaseAuthException: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      print('❌ General exception during signup: $e');
      throw Exception('Signup failed: $e');
    }
  }

  // Sign in with email and password
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Send email verification
  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  // Check if current user's email is verified
  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

  // Reload user to get updated verification status
  Future<void> reloadUser() async {
    await _auth.currentUser?.reload();
  }

  // Check if email belongs to a university domain
  bool _isUniversityEmail(String email) {
    // Basic email validation - strict university validation can be enabled later
    return email.contains('@') && email.contains('.');
    
    /* ORIGINAL STRICT VALIDATION - RESTORE LATER
    final universityDomains = [
      'student.uct.ac.za',
      'sun.ac.za',
      'tuks.co.za', 
      'ru.ac.za',
      'wits.ac.za',
      'ufs.ac.za',
      'ukzn.ac.za',
      'nwu.ac.za',
      'up.ac.za',
      'uwc.ac.za',
      // Add more South African university domains
    ];
    
    return universityDomains.any((domain) => email.toLowerCase().endsWith('@$domain'));
    */
  }

  // Create user profile in Firestore
  Future<void> _createUserProfile({
    required String uid,
    required String email,
    required String fullName,
    required String university,
    required String studentNumber,
  }) async {
    await _firestore.collection('users').doc(uid).set({
      'uid': uid,
      'email': email,
      'fullName': fullName,
      'university': university,
      'studentNumber': studentNumber,
      'isVerified': false, // Will be verified manually or through student ID upload
      'profilePicture': null,
      'phoneNumber': null,
      'rating': 5.0,
      'totalRides': 0,
      'isDriver': false,
      'isRider': true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Handle Firebase Auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'email-already-in-use':
        return 'The account already exists for that email.';
      case 'user-not-found':
        return 'No user found for that email.';
      case 'wrong-password':
        return 'Wrong password provided for that user.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'too-many-requests':
        return 'Too many failed login attempts. Please try again later.';
      default:
        return 'An error occurred. Please try again.';
    }
  }
} 