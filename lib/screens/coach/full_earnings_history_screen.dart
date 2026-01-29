import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../widgets/notification_button.dart';
import '../../widgets/headers/coach_app_bar.dart';
import '../../config/palette.dart';
import '../../services/earnings_service.dart';

class FullEarningsHistoryScreen extends StatefulWidget {
  const FullEarningsHistoryScreen({super.key});

  @override
  State<FullEarningsHistoryScreen> createState() => _FullEarningsHistoryScreenState();
}

class _FullEarningsHistoryScreenState extends State<FullEarningsHistoryScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _earnings = [];
  Map<String, dynamic> _pagination = {};
  int _currentPage = 1;
  final int _limit = 20;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _loadEarningsHistory();
  }

  Future<void> _loadEarningsHistory({bool loadMore = false}) async {
    if (loadMore && (_pagination['pages'] != null && _currentPage >= _pagination['pages'])) {
      return;
    }

    setState(() {
      if (loadMore) {
        _isLoadingMore = true;
      } else {
        _isLoading = true;
        _earnings = [];
        _currentPage = 1;
      }
    });

    try {
      final data = await EarningsService.getEarningsHistory(
        page: loadMore ? _currentPage + 1 : 1,
        limit: _limit,
      );

      setState(() {
        if (loadMore) {
          _earnings.addAll(List<Map<String, dynamic>>.from(data['earnings'] ?? []));
          _currentPage++;
        } else {
          _earnings = List<Map<String, dynamic>>.from(data['earnings'] ?? []);
        }
        _pagination = data['pagination'] ?? {};
        _isLoading = false;
        _isLoadingMore = false;
      });
    } catch (e) {
      debugPrint('Load earnings history error: $e');
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load earnings history: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildActivityItem({
    required String name,
    required String detail,
    required String amount,
    required bool isCompleted,
    required String statusText,
    required String avatarUrl,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundImage: NetworkImage(avatarUrl),
            backgroundColor: AppPalette.navyPrimary.withValues(alpha: 0.1),
            child: avatarUrl.isEmpty
                ? Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: GoogleFonts.outfit(
                      color: AppPalette.navyPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppPalette.navyPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppPalette.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? AppPalette.success.withValues(alpha: 0.1)
                        : Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    statusText,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: isCompleted ? AppPalette.success : Colors.orange,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppPalette.success,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppPalette.backgroundLight,
        body: Column(
          children: [
            CoachAppBar(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => context.pop(),
                  ),
                  Expanded(
                    child: Text(
                      'Full Earnings History',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  NotificationButton(
                    onTap: () => context.push('/coach/notifications'),
                  ),
                ],
              ),
            ),
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppPalette.backgroundLight,
      body: Column(
        children: [
          CoachAppBar(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => context.pop(),
                ),
                Expanded(
                  child: Text(
                    'Full Earnings History',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                NotificationButton(
                  onTap: () => context.push('/coach/notifications'),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _loadEarningsHistory(),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'All Earnings',
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppPalette.navyPrimary,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (_earnings.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Text(
                            'No earnings history',
                            style: GoogleFonts.inter(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    if (_earnings.isNotEmpty)
                      ..._earnings.map((earning) {
                        final player = earning['player'] ?? {};
                        final playerName = '${player['firstName'] ?? ''} ${player['lastName'] ?? ''}'.trim();
                        final amount = ((earning['netAmount'] ?? earning['amount']) ?? 0).toDouble();
                        final sessionDate = DateTime.tryParse(earning['sessionDate'] ?? '');
                        final status = earning['status'] ?? 'confirmed';

                        return _buildActivityItem(
                          name: playerName.isEmpty ? 'Unknown Player' : playerName,
                          detail: '${earning['sessionTitle'] ?? 'Session'} • ${sessionDate != null ? DateFormat('MMM d, yyyy').format(sessionDate) : 'Unknown date'}',
                          amount: '+${EarningsService.formatCurrency(amount)}',
                          isCompleted: status == 'confirmed' || status == 'paid',
                          statusText: status == 'pending' ? 'Pending' : 'Completed',
                          avatarUrl: player['avatar'] ?? 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(playerName)}&background=EBF4FF&color=7F9CF5',
                        );
                      }),

                    if (_isLoadingMore)
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(child: CircularProgressIndicator()),
                      ),

                    if (_pagination['pages'] != null && _currentPage < _pagination['pages'])
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: Center(
                          child: ElevatedButton(
                            onPressed: () => _loadEarningsHistory(loadMore: true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppPalette.orangeAccent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                            ),
                            child: Text(
                              'Load More',
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),

                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}