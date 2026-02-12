import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ionicons/ionicons.dart';

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/palette.dart';
import '../../services/firebase_auth_service.dart';
import '../../services/api_service.dart';
import 'dart:io';

class LoginScreen extends StatefulWidget {
  final String? role;

  const LoginScreen({super.key, this.role});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isPasswordVisible = false;
  bool _rememberMe = false;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = FirebaseAuthService();
  bool _isLoading = false;
  String? _userRole; // Store actual user role from backend

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.isEmpty) {
      _showSnackBar('Please enter email and password', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // First, try local authentication (for existing MongoDB users)
      debugPrint('🔐 Attempting login for: ${_emailController.text.trim()}');
      final localSuccess = await _tryLocalLogin();

      if (localSuccess) {
        debugPrint('✅ Local authentication successful');
        if (!mounted) return;
        _navigateToHome();
        return;
      }

      // If local auth fails, try Firebase authentication (for new users)
      debugPrint('🔄 Local auth failed, trying Firebase...');
      try {
        // Get stored role from registration
        final prefs = await SharedPreferences.getInstance();
        final storedRole = prefs.getString('pending_role');
        final storedEmail = prefs.getString('pending_email');

        String? roleToUse;
        if (storedEmail == _emailController.text.trim()) {
          roleToUse = storedRole;
          debugPrint('📝 Using stored role for first login: $roleToUse');
        } else {
          debugPrint('⚠️ No stored role found or email mismatch');
        }

        debugPrint('🔑 Calling signIn with role: $roleToUse');

        await _authService.signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          role: roleToUse,
        );

        debugPrint('✅ Firebase authentication successful');

        // Clear stored values after successful login and MongoDB sync
        if (storedEmail == _emailController.text.trim()) {
          await prefs.remove('pending_role');
          await prefs.remove('pending_email');
          debugPrint('🗑️ Cleared stored registration data');
        }

        // Get Firebase ID token and save it
        final firebaseToken = await _authService.getIdToken();
        if (firebaseToken != null) {
          await prefs.setString('auth_token', firebaseToken);
          debugPrint('💾 Firebase token saved to SharedPreferences');
        }

        // Fetch user profile from backend to get actual role
        await _fetchUserProfile();

        if (!mounted) return;
        _navigateToHome();
      } on Exception catch (firebaseError) {
        debugPrint('❌ Firebase auth also failed: $firebaseError');
        throw Exception('Login failed. Please check your credentials.');
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(e.toString(), isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<bool> _tryLocalLogin() async {
    try {
      debugPrint('🔄 Attempting local authentication...');
      final response = await ApiService.post('auth/login', {
        'email': _emailController.text.trim(),
        'password': _passwordController.text,
      });

      debugPrint('📡 Local auth response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final userRole = data['user']['role'] as String?;
        final accessToken = data['accessToken'] as String?;

        debugPrint('✅ Local auth successful');
        debugPrint('👤 User role from MongoDB: $userRole');
        debugPrint('🔑 Access token received: ${accessToken != null}');

        // Save JWT token to SharedPreferences for API calls
        if (accessToken != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('auth_token', accessToken);
          debugPrint('💾 Token saved to SharedPreferences');
        }

        // Store the user role for navigation
        if (mounted) {
          setState(() {
            _userRole = userRole;
          });
        }

        return true;
      }
      debugPrint(
        '❌ Local auth failed: ${response.statusCode} - ${response.body}',
      );
      return false;
    } catch (e) {
      debugPrint('❌ Local auth error: $e');
      return false;
    }
  }

  Future<void> _fetchUserProfile() async {
    try {
      debugPrint('📥 Fetching user profile from backend...');
      // Note: ApiService automatically adds the auth token if available.
      final response = await ApiService.get('users/profile');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final userRole = data['user']?['role'] as String?;
        debugPrint('👤 User role from profile: $userRole');

        if (mounted && userRole != null) {
          setState(() {
            _userRole = userRole;
          });
        }
      } else {
        debugPrint('⚠️ Failed to fetch profile: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error fetching profile: $e');
    }
  }

  void _navigateToHome() {
    // Use the actual user role from database, not widget.role
    final roleToUse = _userRole ?? widget.role ?? 'player';
    debugPrint('🏠 Navigating to home: $roleToUse');

    if (roleToUse == 'coach') {
      context.go('/coach/home');
    } else if (roleToUse == 'player') {
      context.go('/player/home');
    } else if (roleToUse == 'guardian') {
      context.go('/guardian/home');
    } else {
      context.go('/player/home'); // default
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);

    try {
      await _authService.signInWithGoogle(loginOnly: true);

      // Save the fresh token to SharedPreferences for ApiService to use
      final firebaseToken = await _authService.getIdToken();
      if (firebaseToken != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', firebaseToken);
        debugPrint('💾 Firebase token saved to SharedPreferences');
      }

      // Fetch user profile from backend to get actual role
      await _fetchUserProfile();

      if (!mounted) return;
      _navigateToHome();
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(e.toString(), isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleAppleSignIn() async {
    setState(() => _isLoading = true);

    try {
      await _authService.signInWithApple();

      // Save the fresh token to SharedPreferences for ApiService to use
      final firebaseToken = await _authService.getIdToken();
      if (firebaseToken != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', firebaseToken);
        debugPrint('💾 Firebase token saved to SharedPreferences');
      }

      // Fetch user profile from backend to get actual role
      await _fetchUserProfile();

      if (!mounted) return;
      _navigateToHome();
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(e.toString(), isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : AppPalette.successGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 16),
              // Back Button (Optional context based)
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/');
                    }
                  },
                ),
              ),

              const SizedBox(height: 30),

              // Logo/Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).dividerColor.withValues(alpha: 0.1),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Image.asset(
                    'assets/images/burl_icon.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ).animate().scale(delay: 100.ms),

              const SizedBox(height: 24),

              // Title
              Text(
                'Welcome Back',
                style: GoogleFonts.outfit(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ).animate().fadeIn(delay: 200.ms),

              const SizedBox(height: 8),

              Text(
                'Sign in to manage your team and track progress.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                  height: 1.5,
                ),
              ).animate().fadeIn(delay: 300.ms),

              const SizedBox(height: 48),

              // Email Field
              _CustomTextField(
                label: 'Email Address',
                hint: 'coach@example.com',
                icon: Ionicons.mail_outline,
                keyboardType: TextInputType.emailAddress,
                controller: _emailController,
              ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.1),

              const SizedBox(height: 16),

              // Password Field
              _CustomTextField(
                label: 'Password',
                hint: '••••••••',
                icon: Ionicons.lock_closed_outline,
                isPassword: true,
                isVisible: _isPasswordVisible,
                onVisibilityChanged: () =>
                    setState(() => _isPasswordVisible = !_isPasswordVisible),
                controller: _passwordController,
              ).animate().fadeIn(delay: 500.ms).slideX(begin: -0.1),

              const SizedBox(height: 12),

              // Details: Remember Me & Forgot Password
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: _rememberMe,
                          activeColor: AppPalette.orangeAccent,
                          side: BorderSide(
                            color: Theme.of(context).unselectedWidgetColor,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          onChanged: (val) =>
                              setState(() => _rememberMe = val!),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Remember me',
                        style: GoogleFonts.inter(
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () => context.push('/forgot-password'),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Forgot Password?',
                      style: GoogleFonts.inter(
                        color: AppPalette.orangeAccent,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 600.ms),

              const SizedBox(height: 32),

              // Login Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppPalette.orangeAccent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Log In',
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Ionicons.arrow_forward, size: 20),
                          ],
                        ),
                ),
              ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.2),

              const SizedBox(height: 32),

              // Social Login Divider
              Row(
                children: [
                  Expanded(
                    child: Divider(color: Theme.of(context).dividerColor),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'OR CONTINUE WITH',
                      style: GoogleFonts.inter(
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Divider(color: Theme.of(context).dividerColor),
                  ),
                ],
              ).animate().fadeIn(delay: 800.ms),

              const SizedBox(height: 24),

              // Social Buttons
              Row(
                children: [
                  if (!Platform.isWindows)
                    Expanded(
                      child: _SocialButton(
                        assetPath: 'assets/images/logo_google.png',
                        onTap: _handleGoogleSignIn,
                      ),
                    ),
                  if (!Platform.isWindows) const SizedBox(width: 16),
                  if (Platform.isIOS || Platform.isMacOS)
                    Expanded(
                      child: _SocialButton(
                        assetPath: 'assets/images/logo_apple.png',
                        isApple: true,
                        onTap: _handleAppleSignIn,
                      ),
                    ),
                ],
              ).animate().fadeIn(delay: 900.ms),

              const SizedBox(height: 48),

              // Footer
              Center(
                child: GestureDetector(
                  onTap: () {
                    // Navigate to role selection instead of directly to register
                    context.go('/role-selection');
                  },
                  child: RichText(
                    text: TextSpan(
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                      children: [
                        const TextSpan(text: "Don't have an account? "),
                        TextSpan(
                          text: 'Sign Up',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            color: AppPalette.orangeAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 1000.ms),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _CustomTextField extends StatelessWidget {
  final String label;
  final String hint;
  final IconData icon;
  final bool isPassword;
  final bool isVisible;
  final VoidCallback? onVisibilityChanged;
  final TextInputType keyboardType;
  final TextEditingController? controller;

  const _CustomTextField({
    required this.label,
    required this.hint,
    required this.icon,
    this.isPassword = false,
    this.isVisible = false,
    this.onVisibilityChanged,
    this.keyboardType = TextInputType.text,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    // Determine if dark mode is active to clear the fill color for glass effect
    // OR use the theme's input Decoration
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: isDark
                ? AppPalette.surfaceGlassDark
                : Colors.grey[100], // Glass in dark, grey in light
            borderRadius: BorderRadius.circular(12),
            border: isDark
                ? Border.all(color: Colors.white.withValues(alpha: 0.1))
                : null,
          ),
          child: TextFormField(
            controller: controller,
            obscureText: isPassword && !isVisible,
            keyboardType: keyboardType,
            style: GoogleFonts.inter(
              fontSize: 15,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.inter(color: Theme.of(context).hintColor),
              prefixIcon: Icon(
                icon,
                color: Theme.of(context).iconTheme.color,
                size: 20,
              ),
              suffixIcon: isPassword
                  ? IconButton(
                      icon: Icon(
                        isVisible
                            ? Ionicons.eye_off_outline
                            : Ionicons.eye_outline,
                        color: Theme.of(context).iconTheme.color,
                        size: 20,
                      ),
                      onPressed: onVisibilityChanged,
                    )
                  : null,
              filled: true,
              fillColor: Colors.transparent, // Handled by Container
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  final String assetPath;
  final VoidCallback onTap;
  final bool isApple;

  const _SocialButton({
    required this.assetPath,
    required this.onTap,
    this.isApple = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 56, // Match main button height
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
          ),
          borderRadius: BorderRadius.circular(12),
          color: Theme.of(context).cardColor,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(assetPath, height: 24, width: 24),
            if (isApple) ...[
              const SizedBox(width: 8),
              Text(
                'iOS',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
