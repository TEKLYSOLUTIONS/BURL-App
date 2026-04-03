import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:crypto/crypto.dart';

import '../config/api_config.dart';
import 'push_notification_service.dart';

class SocialRoleRequiredException implements Exception {
  final UserCredential credential;
  SocialRoleRequiredException(this.credential);
  @override
  String toString() => "Role selection required";
}

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  bool _isGoogleInitialized = false;

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

      // 2️⃣ Run background Firebase tasks asynchronously to speed up the flow
      userCredential.user?.updateDisplayName(fullName).catchError((_) {});

      final actionCodeSettings = ActionCodeSettings(
        url:
            'https://burl-ad60f.firebaseapp.com/finishSignUp?email=${userCredential.user?.email ?? email}',
        handleCodeInApp: true,
        iOSBundleId: 'com.burlcoachbookingapp.app',
        androidPackageName: 'com.burlcoachbookingapp.app',
        androidInstallApp: true,
        androidMinimumVersion: '12',
      );
      // Fire-and-forget email verification
      userCredential.user?.sendEmailVerification(actionCodeSettings).catchError((_) {});
      debugPrint('✉️ Verification email requested in background to: $email');

      // 3️⃣ Immediately persist role + name in MongoDB
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
        final secureStorage = const FlutterSecureStorage();
        await secureStorage.write(key: 'auth_token', value: token);

        // Fetch profile once to persist role for navigation
        Map<String, dynamic>? prefetchedUser;
        try {
          final response = await http.get(
            Uri.parse('$baseUrl/users/profile'),
            headers: {'Authorization': 'Bearer $token'},
          );
          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            prefetchedUser = data['user'] as Map<String, dynamic>?;
            if (prefetchedUser != null && data['profile'] != null) {
              final String? r = prefetchedUser['role']?.toString().toLowerCase();
              if (r == 'coach') {
                prefetchedUser['coachProfile'] = data['profile'];
              } else if (r == 'player') {
                prefetchedUser['playerProfile'] = data['profile'];
              } else if (r == 'guardian') {
                prefetchedUser['guardianProfile'] = data['profile'];
              }
            }
            final role = prefetchedUser?['role'] as String?;
            final name = prefetchedUser?['fullName'] as String?;
            final uid = (prefetchedUser?['_id'] ?? prefetchedUser?['id']) as String?;
            if (role != null) await prefs.setString('user_role', role);
            if (name != null) await prefs.setString('user_name', name);
            if (uid != null) await prefs.setString('user_id', uid);
            debugPrint('💾 Role saved: $role, ID saved: $uid');
          }
        } catch (_) {}

        // Profile completion check — reuse already-fetched user data (no extra API call)
        _checkProfileCompletion(prefetchedUser: prefetchedUser);

        // Register FCM token for push notifications
        PushNotificationService.refreshToken();
      }

      return userCredential;
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign in with Google
  Future<UserCredential> signInWithGoogle() async {
    try {
      // Initialize only once
      if (!_isGoogleInitialized) {
        await _googleSignIn.initialize();
        _isGoogleInitialized = true;
      }

      // Trigger the Google Sign In flow
      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();

      // Obtain the auth details
      final GoogleSignInAuthentication googleAuth =
          googleUser.authentication;

      if (googleAuth.idToken == null) {
        throw Exception(
          'Google Sign-In failed: could not obtain id token.',
        );
      }

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: null, // accessToken relies on authorizeScopes now; idToken is enough
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase
      final userCredential = await _auth.signInWithCredential(credential);

      // Check if new user
      if (userCredential.additionalUserInfo?.isNewUser ?? false) {
        debugPrint('🆕 Google Sign-In: New user detected. Routing to role selection.');
        throw SocialRoleRequiredException(userCredential);
      }

      // Ensure user exists in MongoDB — returns the synced user map
      final syncedUser = await _ensureMongoDBUser(
        fullName: userCredential.user?.displayName ??
            googleUser.displayName ??
            'Google User',
        email: userCredential.user?.email ?? googleUser.email,
      );

      // Save token to SharedPreferences for ApiService
      final token = await userCredential.user?.getIdToken();
      if (token != null) {
        final secureStorage = const FlutterSecureStorage();
        await secureStorage.write(key: 'auth_token', value: token);
      }

      // Profile completion check — reuse data from _ensureMongoDBUser (no extra API call)
      _checkProfileCompletion(prefetchedUser: syncedUser);

      // Register FCM token for push notifications
      PushNotificationService.refreshToken();

      return userCredential;
    } catch (e) {
      if (e is SocialRoleRequiredException) rethrow;
      throw _handleAuthException(e);
    }
  }

  // Sign in with Apple
  Future<UserCredential> signInWithApple() async {
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
        accessToken: appleCredential.authorizationCode,
        rawNonce: rawNonce,
      );

      // Sign in to Firebase
      final userCredential = await _auth.signInWithCredential(credential);
      
      // Get full name — Apple only provides name on FIRST login
      String fullName = userCredential.user?.displayName ?? '';
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

      // Check if new user
      if (userCredential.additionalUserInfo?.isNewUser ?? false) {
        debugPrint('🆕 Apple Sign-In: New user detected. Routing to role selection.');
        throw SocialRoleRequiredException(userCredential);
      }

      final email = userCredential.user?.email ?? appleCredential.email ?? '';

      // Ensure user exists in MongoDB — returns the synced user map
      final syncedUser = await _ensureMongoDBUser(
        fullName: fullName.isNotEmpty ? fullName : 'User',
        email: email,
      );

      // Save token to SharedPreferences for ApiService
      final token = await userCredential.user?.getIdToken();
      if (token != null) {
        final secureStorage = const FlutterSecureStorage();
        await secureStorage.write(key: 'auth_token', value: token);
      }

      // Profile completion check — reuse data from _ensureMongoDBUser (no extra API call)
      _checkProfileCompletion(prefetchedUser: syncedUser);

      // Register FCM token for push notifications
      PushNotificationService.refreshToken();

      return userCredential;
    } catch (e) {
      if (e is SocialRoleRequiredException) rethrow;
      throw _handleAuthException(e);
    }
  }

  // Finalize social login after role selection
  Future<void> finalizeSocialLogin({
    required UserCredential userCredential,
    required String role,
    required String fullName,
  }) async {
    try {
      final String email = userCredential.user?.email ?? '';

      // Update Firebase display name if it was empty before
      if (userCredential.user?.displayName == null || userCredential.user!.displayName!.isEmpty) {
        await userCredential.user?.updateDisplayName(fullName);
      }

      // Create user in MongoDB with selected role
      await _ensureMongoDBUser(
        fullName: fullName,
        role: role,
        email: email,
      );

      // Save token to SharedPreferences for ApiService
      final token = await userCredential.user?.getIdToken();
      if (token != null) {
        final prefs = await SharedPreferences.getInstance();
        final secureStorage = const FlutterSecureStorage();
        await secureStorage.write(key: 'auth_token', value: token);

        // Fetch profile to persist role, name, and user_id
        try {
          final response = await http.get(
            Uri.parse('$baseUrl/users/profile'),
            headers: {'Authorization': 'Bearer $token'},
          );
          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            final dbRole = data['user']?['role'] as String?;
            final name = data['user']?['fullName'] as String?;
            final uid = (data['user']?['_id'] ?? data['user']?['id']) as String?;
            if (dbRole != null) await prefs.setString('user_role', dbRole);
            if (name != null) await prefs.setString('user_name', name);
            if (uid != null) await prefs.setString('user_id', uid);
          }
        } catch (_) {}
      }
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
    final secureStorage = const FlutterSecureStorage();
    await secureStorage.delete(key: 'auth_token');
    await prefs.remove('user_role');
    await prefs.remove('user_id');
    await prefs.remove('user_name');
  }

  // Delete the current Firebase user account
  Future<void> deleteCurrentUser() async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.delete();
      debugPrint('🗑️ Firebase account deleted for: ${user.email}');
    }
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
  // Returns the synced user map so callers can reuse it without extra API calls.
  Future<Map<String, dynamic>?> _ensureMongoDBUser({
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

        // Update local storage with ACTUAL role/name from DB
        if (data['user'] != null) {
          final dbUser = data['user'] as Map<String, dynamic>;
          final dbRole = dbUser['role'];
          final dbName = dbUser['fullName'];
          final dbId = (dbUser['_id'] ?? dbUser['id']) as String?;

          if (dbRole != null) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('user_role', dbRole as String);
            if (dbName != null) await prefs.setString('user_name', dbName as String);
            if (dbId != null) await prefs.setString('user_id', dbId);
            debugPrint('💾 Updated local role to: $dbRole, ID: $dbId');
          }
          // Return the user map so callers can pass it to _checkProfileCompletion
          return dbUser;
        }
      } else {
        debugPrint('⚠️ MongoDB sync warning: ${response.body}');
        // Don't throw - allow login even if MongoDB sync fails
      }
    } catch (e) {
      debugPrint('❌ MongoDB sync error: $e');
      // Don't throw - allow login even if MongoDB sync fails
    }
    return null;
  }

  // Check if profile is complete and create notification if not.
  // Accepts an optional [prefetchedUser] map to avoid an extra GET /users/profile call.
  Future<void> _checkProfileCompletion({Map<String, dynamic>? prefetchedUser}) async {
    try {
      final token = await getIdToken();
      if (token == null) return;

      Map<String, dynamic>? user = prefetchedUser;

      // Only fetch from network if we don't already have the user data
      if (user == null) {
        final response = await http.get(
          Uri.parse('$baseUrl/users/profile'),
          headers: {'Authorization': 'Bearer $token'},
        );
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          user = data['user'] as Map<String, dynamic>?;
          if (user != null && data['profile'] != null) {
            final String? r = user['role']?.toString().toLowerCase();
            if (r == 'coach') {
              user['coachProfile'] = data['profile'];
            } else if (r == 'player') {
              user['playerProfile'] = data['profile'];
            } else if (r == 'guardian') {
              user['guardianProfile'] = data['profile'];
            }
          }
        }
      }

      if (user == null) return;

      // Check if profile is incomplete
      final coachProfile = user['coachProfile'];
      bool isSpecializationEmpty() {
        final String? primarySpec = coachProfile?['primarySpecialization'] as String?;
        final List? specialties = coachProfile?['specialties'] as List?;
        final bool hasPrimary = primarySpec != null && primarySpec.trim().isNotEmpty;
        final bool hasSpecialties = specialties != null && specialties.isNotEmpty;
        return !(hasPrimary || hasSpecialties);
      }

      final isIncomplete = user['phoneNumber'] == null ||
          user['phoneNumber'] == '' ||
          (user['role'] == 'coach' &&
              (coachProfile == null ||
                  isSpecializationEmpty() ||
                  coachProfile['aboutMe'] == null ||
                  (coachProfile['aboutMe'] as String? ?? '').trim().isEmpty ||
                  coachProfile['city'] == null ||
                  (coachProfile['city'] as String? ?? '').trim().isEmpty)) ||
          (user['role'] == 'player' &&
              (user['playerProfile'] == null ||
                  user['playerProfile'] is! Map ||
                  (user['playerProfile'] as Map)['role'] == null ||
                  ((user['playerProfile'] as Map)['role'] as String? ?? '').isEmpty ||
                  (user['playerProfile'] as Map)['address'] == null ||
                  ((user['playerProfile'] as Map)['address'] as String? ?? '').trim().isEmpty ||
                  (user['playerProfile'] as Map)['dateOfBirth'] == null ||
                  ((user['playerProfile'] as Map)['dateOfBirth'] as String? ?? '').trim().isEmpty)) ||
          (user['role'] == 'guardian' &&
              (user['guardianProfile'] == null ||
                  user['guardianProfile'] is! Map ||
                  (user['guardianProfile'] as Map)['address'] == null ||
                  ((user['guardianProfile'] as Map)['address'] as String? ?? '').trim().isEmpty));

      if (isIncomplete) {
        await _createProfileCompletionNotification();
      } else {
        // Profile is complete — mark all notifications as read
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
          'description':
              'Welcome! Please complete your profile to get the most out of our platform.',
          'type': 'profile_completion',
          'category': 'Other',
          'priority': 'high',
          'actionButton': {
            'text': 'Complete Profile',
            'action': 'view',
            'url': '/edit-profile'
          },
          'sendPush': true, // Added flag for backend to fire FCM
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
        case 'account-exists-with-different-credential':
          return 'An account already exists with this email. Please login using your email and password and link this provider from your profile settings.';
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
