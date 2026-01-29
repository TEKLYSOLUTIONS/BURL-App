import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:io';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  // Change baseUrl based on platform
  static const String baseUrl = 'http://localhost:4000/api';

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get ID token for API calls
  Future<String?> getIdToken() async {
    return await _auth.currentUser?.getIdToken();
  }

  // Sign up with email and password
  Future<UserCredential> signUp({
    required String email,
    required String password,
    required String fullName,
    required String role,
  }) async {
    try {
      debugPrint('📝 Creating Firebase account for: $email');
      
      // Create user in Firebase
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name
      await userCredential.user?.updateDisplayName(fullName);

      // Send email verification
      await userCredential.user?.sendEmailVerification();
      debugPrint('✉️ Verification email sent to: $email');
      
      // Store user data in Firebase custom claims for first login
      // Note: MongoDB sync will happen on first verified login
      debugPrint('✅ Firebase account created, awaiting email verification');

      return userCredential;
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign in with email and password
  Future<UserCredential> signIn({
    required String email,
    required String password,
    String? role, // Role for first-time login MongoDB creation
  }) async {
    try {
      debugPrint('🔑 SignIn called with role: $role');
      
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Check if email is verified
      if (!userCredential.user!.emailVerified) {
        await _auth.signOut();
        throw Exception('Please verify your email before logging in. Check your inbox.');
      }

      debugPrint('✅ Email verified, syncing with MongoDB...');
      debugPrint('📋 Passing role to _ensureMongoDBUser: $role');
      
      // Create/sync user in MongoDB on first verified login
      await _ensureMongoDBUser(
        email: email,
        fullName: userCredential.user?.displayName ?? 'User',
        role: role,
      );

      // Check if profile is complete
      await _checkProfileCompletion();

      return userCredential;
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign in with Google
  Future<UserCredential> signInWithGoogle({String? role}) async {
    try {
      // Trigger the Google Sign In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        throw Exception('Google sign-in cancelled');
      }

      // Obtain the auth details
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase
      final userCredential = await _auth.signInWithCredential(credential);

      // Ensure user exists in MongoDB
      await _ensureMongoDBUser(
        fullName: userCredential.user?.displayName ?? 'Google User',
        role: role ?? 'player',
        email: userCredential.user?.email ?? '',
      );

      // Check if profile is complete
      await _checkProfileCompletion();

      return userCredential;
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign in with Apple
  Future<UserCredential> signInWithApple({String? role}) async {
    try {
      // Check if platform supports Apple Sign In
      if (!Platform.isIOS && !Platform.isMacOS) {
        throw Exception('Apple Sign-In is only available on iOS and macOS');
      }

      // Request Apple ID credential
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      // Create Firebase credential
      final oAuthProvider = OAuthProvider('apple.com');
      final credential = oAuthProvider.credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      // Sign in to Firebase
      final userCredential = await _auth.signInWithCredential(credential);

      // Get full name
      String fullName = 'Apple User';
      if (appleCredential.givenName != null && appleCredential.familyName != null) {
        fullName = '${appleCredential.givenName} ${appleCredential.familyName}';
      }

      // Ensure user exists in MongoDB
      await _ensureMongoDBUser(
        fullName: fullName,
        role: role ?? 'player',
        email: userCredential.user?.email ?? '',
      );

      // Check if profile is complete
      await _checkProfileCompletion();

      return userCredential;
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Resend verification email
  Future<void> resendVerificationEmail() async {
    try {
      await _auth.currentUser?.sendEmailVerification();
    } catch (e) {
      throw Exception('Failed to send verification email. Please try again later.');
    }
  }

  // Check email verification status
  Future<bool> isEmailVerified() async {
    await _auth.currentUser?.reload();
    return _auth.currentUser?.emailVerified ?? false;
  }

  // Sign out
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Ensure user exists in MongoDB (create if first login after verification)
  Future<void> _ensureMongoDBUser({
    required String email,
    required String fullName,
    String? role,
  }) async {
    try {
      final token = await getIdToken();

      if (token == null) {
        debugPrint('❌ No authentication token available');
        throw Exception('No authentication token available');
      }

      // Use default role if not provided
      final finalRole = role ?? 'player';
      debugPrint('🔄 Checking/creating user in MongoDB...');
      debugPrint('📍 URL: $baseUrl/auth/signup');
      debugPrint('📝 Data: fullName=$fullName, role=$finalRole, email=$email');

      final response = await http.post(
        Uri.parse('$baseUrl/auth/signup'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'fullName': fullName,
          'role': finalRole,
          'email': email,
        }),
      );

      debugPrint('📡 MongoDB sync response: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['isNewUser'] == true) {
          debugPrint('🆕 New user created in MongoDB');
        } else {
          debugPrint('✅ Existing user found in MongoDB');
        }
      } else {
        debugPrint('⚠️ MongoDB sync warning: ${response.body}');
        // Don't throw - allow login even if MongoDB sync fails
        // User can try again or data will sync on next API call
      }
    } catch (e) {
      debugPrint('❌ MongoDB sync error: $e');
      // Don't throw - allow login even if MongoDB sync fails
    }
  }

  // Check if profile is complete and create notification if not
  Future<void> _checkProfileCompletion() async {
    try {
      final token = await getIdToken();
      if (token == null) return;

      final response = await http.get(
        Uri.parse('$baseUrl/auth/profile'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final user = data['user'];

        // Check if profile is incomplete
        final isIncomplete = user['phoneNumber'] == null ||
            user['phoneNumber'] == '' ||
            (user['role'] == 'coach' &&
                (user['coachProfile'] == null ||
                    user['coachProfile']['specialization'] == null ||
                    user['coachProfile']['specialization'].isEmpty));

        if (isIncomplete) {
          // Create profile completion notification
          await _createProfileCompletionNotification();
        }
      }
    } catch (e) {
      debugPrint('Profile check error: $e');
    }
  }

  // Create notification for profile completion
  Future<void> _createProfileCompletionNotification() async {
    try {
      final token = await getIdToken();
      if (token == null) return;

      await http.post(
        Uri.parse('$baseUrl/notifications'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'title': 'Complete Your Profile',
          'message':
              'Welcome! Please complete your profile to get the most out of our platform.',
          'type': 'profile_completion',
          'category': 'general',
          'priority': 'high',
          'actionUrl': '/profile/edit',
          'icon': 'person',
        }),
      );
    } catch (e) {
      debugPrint('Failed to create profile notification: $e');
    }
  }

  // Handle authentication exceptions
  String _handleAuthException(dynamic e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'weak-password':
          return 'The password provided is too weak.';
        case 'email-already-in-use':
          return 'An account already exists with this email.';
        case 'invalid-email':
          return 'The email address is invalid.';
        case 'user-not-found':
          return 'No user found with this email.';
        case 'wrong-password':
          return 'Wrong password provided.';
        case 'user-disabled':
          return 'This account has been disabled.';
        case 'too-many-requests':
          return 'Too many attempts. Please try again later.';
        case 'operation-not-allowed':
          return 'This sign-in method is not enabled.';
        default:
          return e.message ?? 'An authentication error occurred.';
      }
    }
    return e.toString();
  }
}
