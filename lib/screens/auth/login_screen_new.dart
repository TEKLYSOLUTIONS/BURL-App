import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/palette.dart';
import '../../services/firebase_auth_service.dart';
import '../../widgets/app_buttons.dart';
import '../../widgets/app_text_fields.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';

class LoginScreen extends StatefulWidget {
  final String? role;

  const LoginScreen({super.key, this.role});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _rememberMe = false;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = FirebaseAuthService();
  bool _isLoading = false;
  String? _userRole;

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
      debugPrint('🔐 Attempting login for: ${_emailController.text.trim()}');
      final localSuccess = await _tryLocalLogin();

      if (localSuccess) {
        debugPrint('✅ Local login successful');
        _navigateBasedOnRole(_userRole ?? 'player');
      } else {
        debugPrint('🔄 Local login failed, trying Firebase login...');

        final userCredential = await _authService.signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        debugPrint('✅ Firebase login successful');

        // Clear any legacy pending_email / pending_role keys (no longer used)
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('pending_email');
        await prefs.remove('pending_role');

        final token = await userCredential.user?.getIdToken();
        if (token != null) {
          await _saveUserDataAndNavigate(token);
        }
      }
    } catch (e) {
      debugPrint('❌ Login error: $e');
      _showSnackBar(e.toString(), isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<bool> _tryLocalLogin() async {
    try {
      debugPrint('🔍 Trying local authentication...');
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': _emailController.text.trim(),
          'password': _passwordController.text,
        }),
      );

      debugPrint('📡 Local auth response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['token']);
        await prefs.setString('user', json.encode(data['user']));

        _userRole = data['user']['role'];
        debugPrint('✅ Local login successful, role: $_userRole');
        return true;
      }

      debugPrint('❌ Local login failed: ${response.body}');
      return false;
    } catch (e) {
      debugPrint('❌ Local login error: $e');
      return false;
    }
  }

  Future<void> _saveUserDataAndNavigate(String token) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/auth/me'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final userData = json.decode(response.body);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);
        await prefs.setString('user', json.encode(userData));

        _navigateBasedOnRole(userData['role']);
      }
    } catch (e) {
      debugPrint('❌ Error fetching user data: $e');
      _showSnackBar('Failed to retrieve user data', isError: true);
    }
  }

  void _navigateBasedOnRole(String role) {
    if (!mounted) return;

    switch (role.toLowerCase()) {
      case 'coach':
        context.go('/coach-dashboard');
        break;
      case 'player':
        context.go('/player-dashboard');
        break;
      case 'guardian':
        context.go('/guardian-dashboard');
        break;
      default:
        context.go('/player-dashboard');
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      final userCredential = await _authService.signInWithGoogle();
      final token = await userCredential.user?.getIdToken();
      if (token != null) {
        await _saveUserDataAndNavigate(token);
      }
    } catch (e) {
      if (!mounted) return;
      if (e is SocialRoleRequiredException) {
        context.push('/social-role-selection', extra: e.credential);
      } else if (e.toString() != 'Exception: Google sign-in cancelled') {
        _showSnackBar(e.toString(), isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleAppleSignIn() async {
    setState(() => _isLoading = true);
    try {
      final userCredential = await _authService.signInWithApple();
      final token = await userCredential.user?.getIdToken();
      if (token != null) {
        await _saveUserDataAndNavigate(token);
      }
    } catch (e) {
      if (!mounted) return;
      if (e is SocialRoleRequiredException) {
        context.push('/social-role-selection', extra: e.credential);
      } else if (e.toString() != 'Exception: SignInWithAppleAuthorizationException(AuthorizationErrorCode.canceled, The user canceled the authorization attempt.)') {
        _showSnackBar(e.toString(), isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? AppPalette.errorRed : AppPalette.successGreen,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),

              // Header
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome Back!',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Log in to continue your cricket journey',
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).textTheme.bodyMedium?.color ??
                          AppPalette.textSecondaryLight,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 48),

              // Email field
              EmailTextField(
                controller: _emailController,
                hintText: 'Email address',
                enabled: !_isLoading,
              ),

              const SizedBox(height: 16),

              // Password field
              PasswordTextField(
                controller: _passwordController,
                hintText: 'Password',
                enabled: !_isLoading,
              ),

              const SizedBox(height: 16),

              // Remember me & Forgot password
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        height: 24,
                        width: 24,
                        child: Checkbox(
                          value: _rememberMe,
                          onChanged: _isLoading
                              ? null
                              : (value) {
                                  setState(() => _rememberMe = value ?? false);
                                },
                          fillColor: WidgetStateProperty.resolveWith((states) {
                            if (states.contains(WidgetState.selected)) {
                              return AppPalette.orangeAccent;
                            }
                            return Colors.grey.shade300;
                          }),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Remember me',
                        style: TextStyle(
                          fontSize: 14,
                          color:
                              Theme.of(context).textTheme.bodyMedium?.color ??
                                  AppPalette.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                  AppTextButton(
                    text: 'Forgot Password?',
                    onPressed: () => context.push('/forgot-password'),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Login button
              PrimaryButton(
                text: 'Log In',
                onPressed: _isLoading ? null : _handleLogin,
                isLoading: _isLoading,
              ),

              const SizedBox(height: 24),

              // Divider
              Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey.shade300)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'OR',
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyMedium?.color ??
                            AppPalette.textSecondaryLight,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: Colors.grey.shade300)),
                ],
              ),

              const SizedBox(height: 24),

              // Social login buttons
              SocialButton(
                text: 'Continue with Google',
                icon: const Icon(Icons.g_mobiledata, size: 24),
                onPressed: _handleGoogleSignIn,
                isLoading: _isLoading,
              ),

              const SizedBox(height: 12),

              SocialButton(
                text: 'Continue with Apple',
                icon: const Icon(Icons.apple, size: 24),
                onPressed: _handleAppleSignIn,
                isLoading: _isLoading,
              ),

              const SizedBox(height: 32),

              // Sign up link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Don't have an account? ",
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color ??
                          AppPalette.textSecondaryLight,
                      fontSize: 14,
                    ),
                  ),
                  AppTextButton(
                    text: 'Sign Up',
                    onPressed: () => context.push('/register'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
