import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:crypto/crypto.dart';

import '../config/api_config.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Use ApiConfig for consistent URL handling across platforms
  static String get baseUrl => ApiConfig.baseUrl;

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
    UserCredential? userCredential;
    try {
      debugPrint('📝 Creating Firebase account for: $email');

      // 1️⃣ Create user in Firebase
      userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 2️⃣ Update display name
      await userCredential.user?.updateDisplayName(fullName);

      // 3️⃣ Immediately persist role + name in MongoDB (user is authenticated
      //    but email not yet verified — the backend only checks token validity).
      //    This removes the race condition where role was stored in
      //    SharedPreferences and could be lost or mismatched.
      debugPrint('🔄 Persisting user in MongoDB at sign-up...');
      final token = await userCredential.user?.getIdToken();
      if (token == null) throw Exception('Could not obtain Firebase token');

      final response = await http.post(
        Uri.parse('$baseUrl/auth/signup'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'fullName': fullName, 'role': role, 'email': email}),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        debugPrint('❌ MongoDB signup failed: ${response.body}');
        throw Exception('Failed to create account. Please try again.');
      }
      debugPrint('✅ User persisted in MongoDB with role: $role');

      // 4️⃣ Now send verification email
      final actionCodeSettings = ActionCodeSettings(
        url:
            'https://burl-ad60f.firebaseapp.com/finishSignUp?email=${userCredential.user?.email ?? email}',
        handleCodeInApp: true,
        iOSBundleId: 'com.burlcoachbookingapp.app',
        androidPackageName: 'com.burlcoachbookingapp.app',
        androidInstallApp: true,
        androidMinimumVersion: '12',
      );
      await userCredential.user?.sendEmailVerification(actionCodeSettings);
      debugPrint('✉️ Verification email sent to: $email');

      return userCredential;
    } catch (e) {
      // 🔥 If anything fails after Firebase user was created, delete it
      //    so the user can retry sign-up cleanly.
      if (userCredential != null) {
        try {
          await userCredential.user?.delete();
          debugPrint('🔄 Firebase user rolled back after sign-up error');
        } catch (_) {}
      }
      throw _handleAuthException(e);
    }
  }

  // Sign in with email and password
  // Role is NO LONGER needed here — MongoDB was populated at sign-up time.
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('🔑 Signing in: $email');

      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Check if email is verified
      if (!userCredential.user!.emailVerified) {
        await _auth.signOut();
        throw Exception(
          'Please verify your email before logging in. Check your inbox.',
        );
      }

      debugPrint('✅ Email verified — user already in MongoDB from sign-up');

      // Save token first so ApiService has it immediately
      final token = await userCredential.user?.getIdToken();
      if (token != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', token);

        // Fetch profile once to persist role for navigation
        try {
          final response = await http.get(
            Uri.parse('$baseUrl/users/profile'),
            headers: {'Authorization': 'Bearer $token'},
          );
          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            final role = data['user']?['role'] as String?;
            final name = data['user']?['fullName'] as String?;
            if (role != null) await prefs.setString('user_role', role);
            if (name != null) await prefs.setString('user_name', name);
            debugPrint('💾 Role saved: $role');
          }
        } catch (_) {}

        // Profile completion notification check — background, non-blocking
        _checkProfileCompletion();
      }

      return userCredential;
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign in with Google
  Future<UserCredential> signInWithGoogle({
    String? role,
    bool loginOnly = false,
  }) async {
    try {
      // Trigger the Google Sign In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        throw Exception('Google sign-in cancelled');
      }

      // Obtain the auth details
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      if (googleAuth.accessToken == null && googleAuth.idToken == null) {
        throw Exception(
          'Google Sign-In failed: could not obtain authentication tokens.',
        );
      }

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase
      final userCredential = await _auth.signInWithCredential(credential);

      // Check for existing user restriction
      if (loginOnly &&
          (userCredential.additionalUserInfo?.isNewUser ?? false)) {
        debugPrint('❌ Login only mode: New Google user rejected');
        // Delete the just created user
        await userCredential.user?.delete();
        await _googleSignIn.signOut();
        throw Exception(
          'Account does not exist. Please register using the Sign Up page.',
        );
      }

      // Ensure user exists in MongoDB
      await _ensureMongoDBUser(
        fullName: userCredential.user?.displayName ??
            googleUser.displayName ??
            'Google User',
        role: role ?? 'player',
        email: userCredential.user?.email ?? googleUser.email,
      );

      // Check if profile is complete
      await _checkProfileCompletion();

      // Save token to SharedPreferences for ApiService
      final token = await userCredential.user?.getIdToken();
      if (token != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', token);
      }

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

      // Generate a secure nonce to prevent replay attacks
      final rawNonce = _generateNonce();
      final nonce = _sha256ofString(rawNonce);

      // Request Apple ID credential
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      // Create Firebase credential with nonce
      final oAuthProvider = OAuthProvider('apple.com');
      final credential = oAuthProvider.credential(
        idToken: appleCredential.identityToken,
        rawNonce: rawNonce,
      );

      // Sign in to Firebase
      final userCredential = await _auth.signInWithCredential(credential);

      // Get full name — Apple only provides name on FIRST login
      String fullName = userCredential.user?.displayName ?? 'Apple User';
      if (appleCredential.givenName != null ||
          appleCredential.familyName != null) {
        fullName = [appleCredential.givenName, appleCredential.familyName]
            .where((n) => n != null && n.isNotEmpty)
            .join(' ');
        // Persist name to Firebase (Apple only sends it once)
        if (fullName.isNotEmpty) {
          await userCredential.user?.updateDisplayName(fullName);
        }
      }

      final email = userCredential.user?.email ?? appleCredential.email ?? '';

      // Ensure user exists in MongoDB
      await _ensureMongoDBUser(
        fullName: fullName.isNotEmpty ? fullName : 'Apple User',
        role: role ?? 'player',
        email: email,
      );

      // Check if profile is complete
      await _checkProfileCompletion();

      // Save token to SharedPreferences for ApiService
      final token = await userCredential.user?.getIdToken();
      if (token != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', token);
      }

      return userCredential;
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Generates a cryptographically secure random nonce string
  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)])
        .join();
  }

  /// Returns the SHA256 hash of the given string
  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Resend verification email
  Future<void> resendVerificationEmail() async {
    try {
      await _auth.currentUser?.sendEmailVerification();
    } catch (e) {
      throw Exception(
        'Failed to send verification email. Please try again later.',
      );
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

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
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

        // ✅ CRITICAL FIX: Update local storage with ACTUAL role/name from DB
        if (data['user'] != null) {
          final dbUser = data['user'];
          final dbRole = dbUser['role'];
          final dbName = dbUser['fullName'];

          if (dbRole != null) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('user_role', dbRole);
            if (dbName != null) {
              await prefs.setString('user_name', dbName);
            }
            debugPrint('💾 Updated local role to: $dbRole');
          }
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
        Uri.parse('$baseUrl/users/profile'),
        headers: {'Authorization': 'Bearer $token'},
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
                    user['coachProfile']['specialization'].isEmpty ||
                    user['coachProfile']['bio'] == null ||
                    (user['coachProfile']['bio'] as String).isEmpty));

        if (isIncomplete) {
          // Create profile completion notification
          await _createProfileCompletionNotification();
        } else {
          // Profile is complete — mark all notifications as read so the
          // "Complete Your Profile" prompt disappears automatically on login.
          try {
            await http.put(
              Uri.parse('$baseUrl/notifications/mark-all-read'),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $token',
              },
              body: jsonEncode({}),
            );
            debugPrint('✅ Profile complete — notifications marked as read');
          } catch (_) {}
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
      debugPrint('Firebase Auth Error Code: ${e.code}, Message: ${e.message}');
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
        case 'invalid-credential':
          return 'Invalid email or password.';
        case 'user-disabled':
          return 'This account has been disabled.';
        case 'too-many-requests':
          return 'Too many attempts. Please try again later.';
        case 'operation-not-allowed':
          return 'This sign-in method is not enabled.';
        case 'unknown-error':
          if (e.message != null &&
              (e.message!.contains('An internal error has occurred') ||
                  e.message!.contains('INVALID_LOGIN_CREDENTIALS'))) {
            return 'Invalid email or password.';
          }
          return 'An unknown error occurred. Please try again.';
        case 'channel-error':
          return 'Please check your internet connection, or fields are empty.';
        case 'network-request-failed':
          return 'Network error. Please check your internet connection.';
        case 'internal-error':
          // Sometimes Firebase returns internal-error for invalid credentials on certain platforms
          if (e.message != null &&
              e.message!.contains('INVALID_LOGIN_CREDENTIALS')) {
            return 'Invalid email or password.';
          }
          return 'An internal error occurred. Please try again.';
        default:
          // Check if message itself mentions internal error but it's just invalid credentials
          if (e.message != null &&
              e.message!.contains('internal error') &&
              (e.message!.contains('credential') ||
                  e.message!.contains('password'))) {
            return 'Invalid email or password.';
          }
          return e.message ?? 'An authentication error occurred.';
      }
    }
    return e.toString();
  }
}
