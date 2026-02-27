import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../config/palette.dart';
import '../../services/auth_service.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _hasMinLength = false;
  bool _hasSpecialChar = false;
  bool _hasUpperCase = false;

  void _validatePassword(String value) {
    setState(() {
      _hasMinLength = value.length >= 8;
      _hasSpecialChar = value.contains(RegExp(r'[@#$!%*?&]'));
      _hasUpperCase = value.contains(RegExp(r'[A-Z]'));
    });
  }

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final current = _currentController.text.trim();
    final newPass = _newController.text;
    final confirm = _confirmController.text;

    if (current.isEmpty) {
      _showSnack('Please enter your current password', isError: true);
      return;
    }
    if (!_hasMinLength || !_hasSpecialChar || !_hasUpperCase) {
      _showSnack('Please meet all password requirements', isError: true);
      return;
    }
    if (newPass != confirm) {
      _showSnack('Passwords do not match', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      await AuthService.changePassword(current, newPass);
      if (mounted) {
        _showSnack('Password updated successfully!', isError: false);
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        _showSnack(e.toString().replaceAll('Exception: ', ''), isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppPalette.error : AppPalette.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = Theme.of(context).scaffoldBackgroundColor;
    final cardColor = isDark ? AppPalette.surfaceGlassDark : Colors.white;
    final labelColor =
        isDark ? AppPalette.textPrimaryDark : AppPalette.textPrimaryLight;
    final subColor =
        isDark ? AppPalette.textSecondaryDark : AppPalette.textSecondaryLight;
    final borderColor =
        isDark ? Colors.white.withValues(alpha: 0.12) : Colors.grey.shade200;
    final fieldBg =
        isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: labelColor,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Change Password',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: labelColor,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Security Update',
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: labelColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Your new password must be different from your previous password.',
              style:
                  GoogleFonts.inter(fontSize: 14, color: subColor, height: 1.6),
            ),
            const SizedBox(height: 32),

            // Fields Card
            Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor),
                boxShadow: isDark
                    ? []
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildField(
                    label: 'Current Password',
                    hint: 'Enter your current password',
                    controller: _currentController,
                    obscure: _obscureCurrent,
                    onToggle: () =>
                        setState(() => _obscureCurrent = !_obscureCurrent),
                    fieldBg: fieldBg,
                    borderColor: borderColor,
                    labelColor: labelColor,
                    subColor: subColor,
                  ),
                  const SizedBox(height: 16),
                  _buildField(
                    label: 'New Password',
                    hint: 'Enter new password',
                    controller: _newController,
                    obscure: _obscureNew,
                    onChanged: _validatePassword,
                    onToggle: () => setState(() => _obscureNew = !_obscureNew),
                    fieldBg: fieldBg,
                    borderColor: borderColor,
                    labelColor: labelColor,
                    subColor: subColor,
                  ),
                  const SizedBox(height: 16),
                  _buildField(
                    label: 'Confirm New Password',
                    hint: 'Re-enter new password',
                    controller: _confirmController,
                    obscure: _obscureConfirm,
                    onToggle: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                    fieldBg: fieldBg,
                    borderColor: borderColor,
                    labelColor: labelColor,
                    subColor: subColor,
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),
            const SizedBox(height: 28),

            // Requirements
            Text(
              'REQUIREMENTS',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: subColor,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 14),
            _buildRequirement('At least 8 characters', _hasMinLength, subColor),
            _buildRequirement('Include a special character (@, #, \$, !)',
                _hasSpecialChar, subColor),
            _buildRequirement('One uppercase letter', _hasUpperCase, subColor),

            const SizedBox(height: 36),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppPalette.orangeAccent,
                  disabledBackgroundColor:
                      AppPalette.orangeAccent.withValues(alpha: 0.6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                  shadowColor: AppPalette.orangeAccent.withValues(alpha: 0.3),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Update Password',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.lock_reset_rounded,
                              color: Colors.white, size: 20),
                        ],
                      ),
              ),
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.15),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required bool obscure,
    required VoidCallback onToggle,
    required Color fieldBg,
    required Color borderColor,
    required Color labelColor,
    required Color subColor,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: labelColor,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: fieldBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            obscureText: obscure,
            style: GoogleFonts.inter(fontSize: 14, color: labelColor),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.inter(
                  color: subColor.withValues(alpha: 0.6), fontSize: 14),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              suffixIcon: IconButton(
                icon: Icon(
                  obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: subColor,
                  size: 20,
                ),
                onPressed: onToggle,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRequirement(String text, bool met, Color subColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Icon(
              met
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              key: ValueKey(met),
              size: 20,
              color: met ? AppPalette.success : subColor.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: met ? AppPalette.success : subColor,
            ),
          ),
        ],
      ),
    );
  }
}
