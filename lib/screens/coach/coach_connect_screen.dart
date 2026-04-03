import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/palette.dart';
import '../../services/stripe_payment_service.dart';

/// Screen for Stripe Connect Express onboarding and status display.
/// Coaches must complete Connect onboarding before they can receive payouts.
class CoachConnectScreen extends StatefulWidget {
  const CoachConnectScreen({super.key});

  @override
  State<CoachConnectScreen> createState() => _CoachConnectScreenState();
}

class _CoachConnectScreenState extends State<CoachConnectScreen> {
  final _stripeService = StripePaymentService();
  Map<String, dynamic>? _status;
  bool _loading = true;
  bool _onboarding = false;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    setState(() => _loading = true);
    _status = await _stripeService.getConnectStatus();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _startOnboarding() async {
    setState(() => _onboarding = true);
    try {
      final url = await _stripeService.getConnectOnboardingUrl();
      if (url != null && mounted) {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Could not open onboarding link')),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _onboarding = false);
      // Reload status after returning from browser
      await _loadStatus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          'Payout Setup',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: AppPalette.navyPrimary,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppPalette.navyPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  _buildHeaderCard(),
                  const SizedBox(height: 24),
                  if (_status != null) _buildStatusCard(),
                  const SizedBox(height: 32),
                  _buildActionButton(),
                  const SizedBox(height: 24),
                  _buildInfoSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildHeaderCard() {
    final isActive = _status?['status'] == 'active';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isActive
              ? [const Color(0xFF22C55E), const Color(0xFF16A34A)]
              : [AppPalette.navyPrimary, const Color(0xFF1E3A5F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (isActive ? const Color(0xFF22C55E) : AppPalette.navyPrimary)
                .withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isActive ? Icons.check_circle_rounded : Icons.account_balance_rounded,
              size: 52,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isActive ? 'Payouts Enabled' : 'Set Up Payouts',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isActive
                ? 'Your account is verified. You will receive payouts automatically.'
                : 'Connect with Stripe to receive session payments directly.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    final connected = _status?['connected'] == true;
    final chargesEnabled = _status?['chargesEnabled'] == true;
    final payoutsEnabled = _status?['payoutsEnabled'] == true;
    final requirements = (_status?['requirements'] as List?)?.cast<String>() ?? [];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ACCOUNT STATUS',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 16),
          _statusRow('Account Connected', connected),
          const SizedBox(height: 10),
          _statusRow('Charges Enabled', chargesEnabled),
          const SizedBox(height: 10),
          _statusRow('Payouts Enabled', payoutsEnabled),
          if (requirements.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Pending requirements',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[800],
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ...requirements.map(
                    (r) => Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        '• $r',
                        style: GoogleFonts.inter(fontSize: 12, color: Colors.orange[700]),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statusRow(String label, bool ok) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: ok
                ? const Color(0xFF22C55E).withValues(alpha: 0.1)
                : Colors.grey.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            ok ? Icons.check_rounded : Icons.close_rounded,
            size: 16,
            color: ok ? const Color(0xFF22C55E) : Colors.grey[400],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppPalette.navyPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton() {
    final isActive = _status?['status'] == 'active';

    if (isActive) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF22C55E).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.verified_rounded, color: Color(0xFF22C55E)),
            const SizedBox(width: 10),
            Text(
              'You\'re all set to receive payments!',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF16A34A),
                fontSize: 15,
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        onPressed: _onboarding ? null : _startOnboarding,
        icon: _onboarding
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : const Icon(Icons.open_in_browser_rounded),
        label: Text(
          _onboarding
              ? 'Opening Stripe...'
              : _status?['connected'] == true
                  ? 'Continue Onboarding'
                  : 'Connect with Stripe',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppPalette.navyPrimary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildInfoSection() {
    final items = [
      (Icons.security_rounded, 'Secure Identity Verification', 'Stripe handles all KYC securely. Your data is never stored on our servers.'),
      (Icons.schedule_rounded, 'Automatic Payouts', 'Earn money automatically after each session. Payouts sent every 2 business days.'),
      (Icons.money_off_rounded, 'No Hidden Fees', 'Platform takes only 1.8% service fee. The rest goes directly to you.'),
    ];

    return Column(
      children: items.map((item) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppPalette.navyPrimary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(item.$1, color: AppPalette.navyPrimary, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.$2,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppPalette.navyPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.$3,
                      style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600], height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
