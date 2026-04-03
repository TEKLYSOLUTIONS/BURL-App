import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/palette.dart';
import '../../services/stripe_payment_service.dart';
import '../../services/profile_service.dart';

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  final _stripeService = StripePaymentService();
  List<Map<String, dynamic>> _cards = [];
  String? _role;
  int _currentTab = 0; // 0 = Cards, 1 = Withdrawals
  Map<String, dynamic>? _connectStatus;
  bool _loading = true;
  bool _adding = false;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() => _loading = true);
    
    try {
      final profile = await ProfileService.getProfile();
      _role = profile['role'];
    } catch (_) {}

    try {
      _cards = await _stripeService.listCards();
      
      if (_role == 'coach') {
        _connectStatus = await _stripeService.getConnectStatus();
      }
    } catch (e) {
      debugPrint('Error loading payment data: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadCards() async {
    try {
      _cards = await _stripeService.listCards();
    } catch (e) {
      debugPrint('Error reloading cards: $e');
    } finally {
      if (mounted) setState(() {});
    }
  }

  Future<void> _addCard() async {
    setState(() => _adding = true);
    try {
      final success = await _stripeService.addCard(context);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Card added successfully'),
            backgroundColor: AppPalette.successGreen,
          ),
        );
        await _loadCards();
      } else if (!success && mounted) {
        // Only show if the user didn't cancel voluntarily, though StripeException often covers both.
        // It's optional, but handling the false case gracefully is good.
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add card. Please try again.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  Future<void> _deleteCard(String pmId, String last4) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Remove Card', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        content: Text('Remove card ending in $last4?', style: GoogleFonts.inter()),
        actions: [
          TextButton(onPressed: () => ctx.pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => ctx.pop(true),
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    try {
      final ok = await _stripeService.deleteCard(pmId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ok ? 'Card removed' : 'Failed to remove card'),
            backgroundColor: ok ? AppPalette.successGreen : Colors.red,
          ),
        );
        if (ok) await _loadCards();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error removing card. Please try again later.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  IconData _brandIcon(String brand) {
    switch (brand.toLowerCase()) {
      case 'visa':
        return Icons.credit_card;
      case 'mastercard':
        return Icons.credit_card;
      case 'amex':
        return Icons.credit_card;
      default:
        return Icons.credit_card_outlined;
    }
  }

  Color _brandColor(String brand) {
    switch (brand.toLowerCase()) {
      case 'visa':
        return const Color(0xFF1A1F71);
      case 'mastercard':
        return const Color(0xFFEB001B);
      case 'amex':
        return const Color(0xFF007BC1);
      default:
        return AppPalette.navyPrimary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Payment Methods',
          style: GoogleFonts.inter(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (_currentTab == 0)
            TextButton.icon(
              onPressed: _adding ? null : _addCard,
              icon: _adding
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: theme.colorScheme.primary),
                    )
                  : Icon(Icons.add, size: 18, color: theme.colorScheme.primary),
              label: Text(
                _adding ? 'Adding...' : 'Add',
                style: GoogleFonts.inter(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_role == 'coach') _buildCoachTabs(),
                Expanded(
                  child: _currentTab == 0
                      ? (_cards.isEmpty ? _buildEmptyState() : _buildCardList())
                      : _buildWithdrawalsView(),
                ),
              ],
            ),
    );
  }

  Widget _buildCoachTabs() {
    final theme = Theme.of(context);
    final isSelected0 = _currentTab == 0;
    final isSelected1 = _currentTab == 1;

    return Container(
      color: theme.colorScheme.surface,
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _currentTab = 0),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isSelected0 ? theme.colorScheme.primary : Colors.transparent,
                      width: 3,
                    ),
                  ),
                ),
                child: Center(
                  child: Text(
                    'Cards',
                    style: GoogleFonts.inter(
                      fontWeight: isSelected0 ? FontWeight.bold : FontWeight.w500,
                      color: isSelected0 ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _currentTab = 1),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isSelected1 ? theme.colorScheme.primary : Colors.transparent,
                      width: 3,
                    ),
                  ),
                ),
                child: Center(
                  child: Text(
                    'Withdrawals',
                    style: GoogleFonts.inter(
                      fontWeight: isSelected1 ? FontWeight.bold : FontWeight.w500,
                      color: isSelected1 ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWithdrawalsView() {
    final theme = Theme.of(context);
    final isConnected = _connectStatus?['connected'] == true;
    final statusObj = _connectStatus?['status'] as String? ?? 'not_connected';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.account_balance_outlined,
                size: 64,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Bank Payouts',
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            if (isConnected && statusObj == 'active') ...[
              Text(
                'Your bank account is securely linked through Stripe. Earnings will be automatically paid out to this account.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 15, color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _onboardCoach,
                icon: const Icon(Icons.dashboard_customize),
                label: const Text('View Stripe Dashboard'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  minimumSize: const Size(0, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ] else if (isConnected && statusObj == 'pending') ...[
              Text(
                'Your account is pending verification by Stripe. Please provide any missing details to enable payouts.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 15, color: theme.colorScheme.error),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _onboardCoach,
                icon: const Icon(Icons.warning_amber),
                label: const Text('Complete Verification'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.error,
                  foregroundColor: theme.colorScheme.onError,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  minimumSize: const Size(0, 56), // Prevent infinity stretching
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ] else ...[
              Text(
                'Link a bank account to receive automated withdrawals for your coaching sessions.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 15, color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _onboardCoach,
                icon: const Icon(Icons.account_balance),
                label: const Text('Set Up Payouts'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  minimumSize: const Size(0, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Future<void> _onboardCoach() async {
    final url = await _stripeService.getConnectOnboardingUrl();
    if (url != null) {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  Widget _buildCardList() {
    return RefreshIndicator(
      onRefresh: _loadCards,
      child: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: _cards.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          final card = _cards[i];
          final cardData = card['card'] as Map<String, dynamic>;
          final brand = (cardData['brand'] as String?) ?? 'card';
          final last4 = (cardData['last4'] as String?) ?? '••••';
          final expMonth = cardData['exp_month']?.toString().padLeft(2, '0') ?? '??';
          final expYear = cardData['exp_year']?.toString().substring(2) ?? '??';
          final pmId = card['id'] as String;

          return _CardTile(
            brand: brand,
            last4: last4,
            expMonth: expMonth,
            expYear: expYear,
            brandColor: _brandColor(brand),
            brandIcon: _brandIcon(brand),
            isDefault: i == 0,
            onDelete: () => _deleteCard(pmId, last4),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppPalette.orangeAccent.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.credit_card_off_rounded,
              size: 64,
              color: AppPalette.orangeAccent,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Payment Methods',
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add a card to book sessions\nand subscribe to plans.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 15, color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _adding ? null : _addCard,
            icon: _adding
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(color: theme.colorScheme.onPrimary, strokeWidth: 2),
                  )
                : const Icon(Icons.add),
            label: Text(_adding ? 'Adding...' : 'Add New Card'),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              minimumSize: const Size(0, 56), // Prevent infinity stretching
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class _CardTile extends StatelessWidget {
  final String brand;
  final String last4;
  final String expMonth;
  final String expYear;
  final Color brandColor;
  final IconData brandIcon;
  final bool isDefault;
  final VoidCallback onDelete;

  const _CardTile({
    required this.brand,
    required this.last4,
    required this.expMonth,
    required this.expYear,
    required this.brandColor,
    required this.brandIcon,
    required this.isDefault,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDefault ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
          width: isDefault ? 2 : 1,
        ),
        boxShadow: [
          if (theme.brightness != Brightness.dark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: brandColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(brandIcon, color: theme.brightness == Brightness.dark ? Colors.white70 : brandColor, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      brand[0].toUpperCase() + brand.substring(1),
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    if (isDefault) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Default',
                          style: GoogleFonts.inter(
                            color: theme.colorScheme.onPrimary,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '•••• •••• •••• $last4  |  $expMonth/$expYear',
                  style: GoogleFonts.inter(fontSize: 13, color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onDelete,
            icon: Icon(Icons.delete_outline, color: theme.colorScheme.error, size: 22),
            tooltip: 'Remove card',
          ),
        ],
      ),
    );
  }
}
