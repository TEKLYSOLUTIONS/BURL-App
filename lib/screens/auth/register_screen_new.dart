import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/palette.dart';
import '../../services/firebase_auth_service.dart';
import '../../widgets/app_buttons.dart';
import '../../widgets/app_text_fields.dart';
import 'package:go_router/go_router.dart';

class RegisterScreen extends StatefulWidget {
  final String? role;

  const RegisterScreen({super.key, this.role});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = FirebaseAuthService();
  bool _isLoading = false;
  bool _agreedToTerms = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_agreedToTerms) {
      _showSnackBar('Please agree to the terms and conditions', isError: true);
      return;
    }

    if (_formKey.currentState?.validate() != true) {
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      _showSnackBar('Passwords do not match', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      debugPrint(
        '📝 Attempting registration for: ${_emailController.text.trim()}',
      );

      final _ = await _authService.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        fullName: _nameController.text.trim(),
        role: widget.role ?? 'player',
      );

      debugPrint('✅ Firebase registration successful');

      // Store email and role in SharedPreferences for first login
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('pending_email', _emailController.text.trim());
      await prefs.setString('pending_role', widget.role ?? 'player');
      debugPrint('📦 Stored pending registration data');

      if (mounted) {
        _showSnackBar(
          'Registration successful! Please check your email to verify your account.',
        );

        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          context.go('/login', extra: {'role': widget.role ?? 'player'});
        }
      }
    } catch (e) {
      debugPrint('❌ Registration error: $e');
      _showSnackBar(e.toString(), isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleGoogleSignUp() async {
    setState(() => _isLoading = true);
    try {
      final _ = await _authService.signInWithGoogle(role: widget.role);
      if (mounted) {
        _navigateBasedOnRole(widget.role ?? 'player');
      }
    } catch (e) {
      _showSnackBar(e.toString(), isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleAppleSignUp() async {
    setState(() => _isLoading = true);
    try {
      final _ = await _authService.signInWithApple(role: widget.role);
      if (mounted) {
        _navigateBasedOnRole(widget.role ?? 'player');
      }
    } catch (e) {
      _showSnackBar(e.toString(), isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _navigateBasedOnRole(String role) {
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).iconTheme.color,
          ),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Create Account',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sign up to get started',
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).textTheme.bodyMedium?.color ??
                            AppPalette.textSecondaryLight,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Role badge
                if (widget.role != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppPalette.orangeAccent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppPalette.orangeAccent.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _getRoleIcon(widget.role!),
                          color: AppPalette.orangeAccent,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Signing up as ${widget.role?.toUpperCase()}',
                          style: TextStyle(
                            color: AppPalette.orangeAccent,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 24),

                // Full name field
                AppTextField(
                  controller: _nameController,
                  hintText: 'Full name',
                  prefixIcon: Icons.person_outline,
                  enabled: !_isLoading,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your full name';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Email field
                EmailTextField(
                  controller: _emailController,
                  hintText: 'Email address',
                  enabled: !_isLoading,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!RegExp(
                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                    ).hasMatch(value)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Password field
                PasswordTextField(
                  controller: _passwordController,
                  hintText: 'Password',
                  enabled: !_isLoading,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Confirm password field
                PasswordTextField(
                  controller: _confirmPasswordController,
                  hintText: 'Confirm password',
                  enabled: !_isLoading,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your password';
                    }
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // Terms and conditions checkbox
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 24,
                      width: 24,
                      child: Checkbox(
                        value: _agreedToTerms,
                        onChanged: _isLoading
                            ? null
                            : (value) {
                                setState(() => _agreedToTerms = value ?? false);
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
                    const SizedBox(width: 12),
                    Expanded(
                      child: Wrap(
                        children: [
                          Text(
                            'I agree to the ',
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(
                                    context,
                                  ).textTheme.bodyMedium?.color ??
                                  AppPalette.textSecondaryLight,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => context.push('/terms'),
                            child: Text(
                              'Terms of Service',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppPalette.orangeAccent,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            ' and ',
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(
                                    context,
                                  ).textTheme.bodyMedium?.color ??
                                  AppPalette.textSecondaryLight,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => context.push('/privacy-policy'),
                            child: Text(
                              'Privacy Policy',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppPalette.orangeAccent,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Sign up button
                PrimaryButton(
                  text: 'Sign Up',
                  onPressed: _handleRegister,
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
                          color:
                              Theme.of(context).textTheme.bodyMedium?.color ??
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

                // Social sign up buttons
                SocialButton(
                  text: 'Continue with Google',
                  icon: const Icon(Icons.g_mobiledata, size: 24),
                  onPressed: _handleGoogleSignUp,
                  isLoading: _isLoading,
                ),

                const SizedBox(height: 12),

                SocialButton(
                  text: 'Continue with Apple',
                  icon: const Icon(Icons.apple, size: 24),
                  onPressed: _handleAppleSignUp,
                  isLoading: _isLoading,
                ),

                const SizedBox(height: 32),

                // Login link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyMedium?.color ??
                            AppPalette.textSecondaryLight,
                        fontSize: 14,
                      ),
                    ),
                    AppTextButton(
                      text: 'Log In',
                      onPressed: _isLoading
                          ? null
                          : () {
                              context.pop();
                            },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getRoleIcon(String role) {
    switch (role.toLowerCase()) {
      case 'coach':
        return Icons.sports;
      case 'player':
        return Icons.sports_cricket;
      case 'guardian':
        return Icons.family_restroom;
      default:
        return Icons.person;
    }
  }
}
