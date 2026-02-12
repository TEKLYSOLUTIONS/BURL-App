import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../widgets/notification_button.dart';
import '../../widgets/headers/coach_app_bar.dart';

import '../../services/earnings_service.dart';
import '../../config/palette.dart';

class EarningHistoryScreen extends StatefulWidget {
  const EarningHistoryScreen({super.key});

  @override
  State<EarningHistoryScreen> createState() => _EarningHistoryScreenState();
}

class _EarningHistoryScreenState extends State<EarningHistoryScreen> {
  String _selectedPeriod = 'Monthly';
  bool _isLoading = true;
  Map<String, dynamic> _summaryData = {};
  List<Map<String, dynamic>> _periodData = [];
  List<Map<String, dynamic>> _recentActivity = [];

  @override
  void initState() {
    super.initState();
    _loadEarningsData();
  }

  Future<void> _loadEarningsData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load all earnings data in parallel
      final results = await Future.wait([
        EarningsService.getEarningsSummary(),
        EarningsService.getEarningsByPeriod(
          type: _selectedPeriod.toLowerCase(),
        ),
      ]);

      setState(() {
        _summaryData = results[0];
        _periodData = List<Map<String, dynamic>>.from(
          results[1]['earnings'] ?? [],
        );
        _recentActivity = List<Map<String, dynamic>>.from(
          _summaryData['recentActivity'] ?? [],
        );
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Load earnings error: $e');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load earnings data: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _onPeriodChanged(String period) async {
    setState(() {
      _selectedPeriod = period;
      _isLoading = true;
    });

    try {
      final data = await EarningsService.getEarningsByPeriod(
        type: period.toLowerCase(),
      );

      setState(() {
        _periodData = List<Map<String, dynamic>>.from(data['earnings'] ?? []);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Period change error: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleCashOut() async {
    final totalBalance = _summaryData['totalBalance'] ?? 0.0;

    if (totalBalance <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No balance available for cash out'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final result = await EarningsService.requestCashOut(amount: totalBalance);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Cash out request submitted'),
            backgroundColor: AppPalette.successGreen,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to process cash out: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Column(
          children: [
            CoachAppBar(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 40),
                  Expanded(
                    child: Text(
                      'Earnings',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  ),
                  NotificationButton(
                    onTap: () => context.push('/coach/notifications'),
                  ),
                ],
              ),
            ),
            const Expanded(child: Center(child: CircularProgressIndicator())),
          ],
        ),
      );
    }

    final totalBalance = (_summaryData['totalBalance'] ?? 0).toDouble();
    final percentageChange = (_summaryData['trend']?['percentageChange'] ?? 0)
        .toDouble();
    final changeAmount = (_summaryData['trend']?['changeAmount'] ?? 0)
        .toDouble();
    final currentMonthTotal = (_summaryData['currentMonth']?['total'] ?? 0)
        .toDouble();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          CoachAppBar(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 40),
                Expanded(
                  child: Text(
                    'Earnings',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimary,
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
              onRefresh: _loadEarningsData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Total Balance Card
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'TOTAL BALANCE',
                                style: GoogleFonts.inter(
                                  color: Theme.of(context).colorScheme.onPrimary
                                      .withValues(alpha: 0.7),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              if (percentageChange != 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2C3E50),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        percentageChange >= 0
                                            ? Icons.trending_up
                                            : Icons.trending_down,
                                        color: percentageChange >= 0
                                            ? AppPalette.successGreen
                                            : Theme.of(
                                                context,
                                              ).colorScheme.error,
                                        size: 14,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        EarningsService.formatPercentageChange(
                                          percentageChange,
                                        ),
                                        style: GoogleFonts.outfit(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            EarningsService.formatCurrency(totalBalance),
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Last updated ${DateFormat('MMM d, h:mm a').format(DateTime.now())}',
                            style: GoogleFonts.inter(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _handleCashOut,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.secondary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.wallet,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Cash Out Now',
                                    style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn().slideY(begin: 0.1),

                    const SizedBox(height: 24),

                    // Period Selector
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Expanded(child: _buildPeriodTab('Weekly')),
                          Expanded(child: _buildPeriodTab('Monthly')),
                          Expanded(child: _buildPeriodTab('Yearly')),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Income Trend
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Income Trend',
                              style: GoogleFonts.inter(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.6),
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              EarningsService.formatCurrency(currentMonthTotal),
                              style: GoogleFonts.outfit(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        if (changeAmount != 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: changeAmount >= 0
                                  ? AppPalette.successGreen.withValues(
                                      alpha: 0.1,
                                    )
                                  : Theme.of(
                                      context,
                                    ).colorScheme.error.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${changeAmount >= 0 ? '+ ' : ''}${EarningsService.formatCurrency(changeAmount)} vs last month',
                              style: GoogleFonts.outfit(
                                color: changeAmount >= 0
                                    ? AppPalette.successGreen
                                    : Theme.of(context).colorScheme.error,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Bar Chart
                    SizedBox(
                      height: 180,
                      child: _periodData.isEmpty
                          ? Center(
                              child: Text(
                                'No earnings data for this period',
                                style: GoogleFonts.inter(
                                  color: Theme.of(context).disabledColor,
                                  fontSize: 14,
                                ),
                              ),
                            )
                          : BarChart(
                              BarChartData(
                                gridData: const FlGridData(show: false),
                                titlesData: FlTitlesData(
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      getTitlesWidget: (value, meta) {
                                        return _getBottomTitles(value, meta);
                                      },
                                    ),
                                  ),
                                  leftTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  topTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  rightTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                ),
                                borderData: FlBorderData(show: false),
                                barGroups: _getBarGroups(),
                              ),
                            ),
                    ).animate().fadeIn(delay: 200.ms),

                    const SizedBox(height: 32),

                    // Recent Activity
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Recent Activity',
                          style: GoogleFonts.outfit(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                            height: 1.2,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            context.push('/coach/earnings/history');
                          },
                          child: Text(
                            'See All',
                            style: GoogleFonts.inter(
                              color: Theme.of(context).colorScheme.secondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    if (_recentActivity.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Text(
                            'No recent activity',
                            style: GoogleFonts.inter(
                              color: Theme.of(context).disabledColor,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    if (_recentActivity.isNotEmpty)
                      ..._recentActivity.map((activity) {
                        final player = activity['player'] ?? {};
                        final playerName = player['fullName'] ?? '';
                        final amount =
                            ((activity['netAmount'] ?? activity['amount']) ?? 0)
                                .toDouble();
                        final sessionDate = DateTime.tryParse(
                          activity['sessionDate'] ?? '',
                        );
                        final status = activity['status'] ?? 'confirmed';

                        return _buildActivityItem(
                          name: playerName.isEmpty
                              ? 'Unknown Player'
                              : playerName,
                          detail:
                              '${activity['sessionTitle'] ?? 'Session'} • ${sessionDate != null ? DateFormat('MMM d').format(sessionDate) : 'Unknown date'}',
                          amount: '+${EarningsService.formatCurrency(amount)}',
                          isCompleted:
                              status == 'confirmed' || status == 'paid',
                          statusText: status == 'pending'
                              ? 'Pending'
                              : 'Completed',
                          avatarUrl:
                              player['avatar'] ??
                              'https://ui-avatars.com/api/?name=${Uri.encodeComponent(playerName)}&background=EBF4FF&color=7F9CF5',
                        );
                      }),

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

  Widget _buildPeriodTab(String text) {
    final isSelected = _selectedPeriod == text;
    return GestureDetector(
      onTap: () {
        if (_selectedPeriod != text) {
          _onPeriodChanged(text);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).cardColor : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Theme.of(
                      context,
                    ).shadowColor.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }

  Widget _getBottomTitles(double value, TitleMeta meta) {
    if (_periodData.isEmpty) return const SizedBox();

    int index = value.toInt();
    if (index < 0 || index >= _periodData.length) return const SizedBox();

    String text = '';
    bool isBold = index == _periodData.length - 1;

    // Get the label from the API data
    final periodId = _periodData[index]['_id']?.toString() ?? '';

    switch (_selectedPeriod) {
      case 'Weekly':
        text = 'W${index + 1}';
        break;
      case 'Monthly':
        // periodId format: "2024-10" -> "Oct"
        if (periodId.isNotEmpty) {
          try {
            final parts = periodId.split('-');
            if (parts.length >= 2) {
              final month = int.tryParse(parts[1]) ?? 1;
              final monthNames = [
                '',
                'Jan',
                'Feb',
                'Mar',
                'Apr',
                'May',
                'Jun',
                'Jul',
                'Aug',
                'Sep',
                'Oct',
                'Nov',
                'Dec',
              ];
              text = monthNames[month];
            }
          } catch (e) {
            text = 'M${index + 1}';
          }
        } else {
          text = 'M${index + 1}';
        }
        break;
      case 'Yearly':
        // periodId is year number
        text = periodId.isEmpty
            ? '${DateTime.now().year - (_periodData.length - 1 - index)}'
            : periodId;
        break;
    }

    if (text.isEmpty) return const SizedBox();
    return _buildChartLabel(text, isBold: isBold);
  }

  List<BarChartGroupData> _getBarGroups() {
    if (_periodData.isEmpty) {
      return [];
    }

    // Get values from API data and convert to double
    final values = _periodData
        .map((e) => ((e['total'] ?? 0).toDouble()) / 100)
        .toList();

    return List.generate(values.length, (index) {
      // Highlight the last bar
      final color = index == values.length - 1
          ? Theme.of(context).colorScheme.primary
          : Theme.of(context).colorScheme.secondary;
      return _buildBarGroup(index, values[index], color);
    });
  }

  Widget _buildChartLabel(String text, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Text(
        text,
        style: GoogleFonts.inter(
          color: isBold
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          fontSize: 12,
        ),
      ),
    );
  }

  BarChartGroupData _buildBarGroup(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 50, // Wider bars
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(6),
            topRight: Radius.circular(6),
          ),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: 20, // Max height
            color: Theme.of(context).disabledColor.withValues(alpha: 0.2),
          ),
        ),
      ],
    );
  }

  Widget _buildActivityItem({
    required String name,
    required String detail,
    required String amount,
    required bool isCompleted,
    String? statusText,
    required String avatarUrl,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundImage: NetworkImage(avatarUrl),
            backgroundColor: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.onSurface,
                    height: 1.1,
                  ),
                ),
                Text(
                  detail,
                  style: GoogleFonts.inter(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.6),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isCompleted
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).disabledColor,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isCompleted
                      ? AppPalette.successGreen.withValues(alpha: 0.1)
                      : Theme.of(
                          context,
                        ).colorScheme.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  statusText ?? 'Completed',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isCompleted
                        ? AppPalette.successGreen
                        : Theme.of(context).colorScheme.secondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn().slideX();
  }
}
