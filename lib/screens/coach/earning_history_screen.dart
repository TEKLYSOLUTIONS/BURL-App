import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
<<<<<<< HEAD
import 'package:go_router/go_router.dart';
import '../../widgets/notification_button.dart';
import '../../widgets/headers/coach_app_bar.dart';
=======
import '../../widgets/notification_button.dart';
>>>>>>> c580486c100d6e4782b9991b06e70b9ceddc33ba
import '../../config/palette.dart';

class EarningHistoryScreen extends StatefulWidget {
  const EarningHistoryScreen({super.key});

  @override
  State<EarningHistoryScreen> createState() => _EarningHistoryScreenState();
}

class _EarningHistoryScreenState extends State<EarningHistoryScreen> {
  String _selectedPeriod = 'Monthly';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.backgroundLight,
      body: Column(
        children: [
<<<<<<< HEAD
          CoachAppBar(
=======
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 20,
              bottom: 24,
              left: 24,
              right: 24,
            ),
            decoration: const BoxDecoration(
              color: AppPalette.navyPrimary,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
>>>>>>> c580486c100d6e4782b9991b06e70b9ceddc33ba
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 40),
                Expanded(
                  child: Text(
                    'Earnings',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
<<<<<<< HEAD
                      fontSize: 24, // Consistent size
=======
                      fontSize: 28,
>>>>>>> c580486c100d6e4782b9991b06e70b9ceddc33ba
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
<<<<<<< HEAD
                NotificationButton(
                  hasNotification: true,
                  onTap: () => context.push('/coach/notifications'),
                ),
=======
                const NotificationButton(hasNotification: true),
>>>>>>> c580486c100d6e4782b9991b06e70b9ceddc33ba
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Total Balance Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppPalette.navyPrimary,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: AppPalette.navyPrimary.withValues(alpha: 0.3),
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
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.0,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2C3E50), // Darker Navy
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.trending_up,
                                    color: AppPalette.success,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '+15%',
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
                          '\$1,240.50',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Last updated just now',
                          style: GoogleFonts.inter(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppPalette.orangeAccent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
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
                      color: Colors.grey[200],
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
                              color: AppPalette.textSecondaryLight,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '\$3,450',
                            style: GoogleFonts.outfit(
                              color: AppPalette.navyPrimary,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppPalette.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '+ \$420 vs last month',
                          style: GoogleFonts.outfit(
                            color: AppPalette.success,
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
                    child: BarChart(
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
                          color: AppPalette.navyPrimary,
                          height:
                              1.2, // Fix vertical alignment/padding visually
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: Text(
                          'See All',
                          style: GoogleFonts.inter(
                            color: AppPalette.orangeAccent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  _buildActivityItem(
                    name: 'Marcus Johnson',
                    detail: '1-on-1 Coaching • Oct 24',
                    amount: '+\$60.00',
                    isCompleted: true,
                    avatarUrl: 'https://i.pravatar.cc/150?img=11',
                  ),
                  _buildActivityItem(
                    name: 'Sarah Williams',
                    detail: 'Group Drill • Oct 23',
                    amount: '+\$120.00',
                    isCompleted: true,
                    avatarUrl: 'https://i.pravatar.cc/150?img=5',
                  ),
                  _buildActivityItem(
                    name: 'Team Fury',
                    detail: 'Monthly Retainer • Oct 20',
                    amount: '+\$500.00',
                    isCompleted: true,
                    avatarUrl:
                        'https://ui-avatars.com/api/?name=Team+Fury&background=EBF4FF&color=7F9CF5',
                    isNetworkImage: true,
                  ),
                  _buildActivityItem(
                    name: 'Emily Chen',
                    detail: 'Video Analysis • Oct 19',
                    amount: '+\$45.00',
                    isCompleted: false, // Pending
                    statusText: 'Pending',
                    avatarUrl: 'https://i.pravatar.cc/150?img=9',
                  ),

                  const SizedBox(height: 80), // Padding at bottom for scrolling
                ],
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
        setState(() {
          _selectedPeriod = text;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
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
            color: isSelected ? AppPalette.navyPrimary : Colors.grey[600],
          ),
        ),
      ),
    );
  }

  Widget _getBottomTitles(double value, TitleMeta meta) {
    String text = '';
    bool isBold = false;
    int index = value.toInt();

    switch (_selectedPeriod) {
      case 'Weekly':
        if (index >= 0 && index < 4) {
          text = 'W${index + 1}';
          if (index == 3) isBold = true;
        }
        break;
      case 'Monthly':
        const months = ['Jul', 'Aug', 'Sep', 'Oct'];
        if (index >= 0 && index < months.length) {
          text = months[index];
          if (index == 3) isBold = true;
        }
        break;
      case 'Yearly':
        const years = ['2021', '2022', '2023', '2024'];
        if (index >= 0 && index < years.length) {
          text = years[index];
          if (index == 3) isBold = true;
        }
        break;
    }

    if (text.isEmpty) return const SizedBox();
    return _buildChartLabel(text, isBold: isBold);
  }

  List<BarChartGroupData> _getBarGroups() {
    List<double> values;
    switch (_selectedPeriod) {
      case 'Weekly':
        values = [8, 12, 10, 16];
        break;
      case 'Monthly':
        values = [14, 11, 15, 18];
        break;
      case 'Yearly':
        values = [10, 14, 12, 17];
        break;
      default:
        values = [8, 12, 10, 16];
    }

    return List.generate(values.length, (index) {
      // Highlight the last bar
      final color = index == values.length - 1
          ? AppPalette.orangeAccent
          : AppPalette.navyPrimary;
      return _buildBarGroup(index, values[index], color);
    });
  }

  Widget _buildChartLabel(String text, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Text(
        text,
        style: GoogleFonts.inter(
          color: isBold ? AppPalette.navyPrimary : Colors.grey[400],
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
            color: Colors.grey[200],
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
    bool isNetworkImage = true,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundImage: NetworkImage(avatarUrl),
            backgroundColor: Colors.grey[200],
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
                    color: AppPalette.navyPrimary,
                    height: 1.1,
                  ),
                ),
                Text(
                  detail,
                  style: GoogleFonts.inter(
                    color: AppPalette.textSecondaryLight,
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
                      ? AppPalette.navyPrimary
                      : Colors.grey[400],
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isCompleted
                      ? AppPalette.success.withValues(alpha: 0.1)
                      : AppPalette.orangeAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  statusText ?? 'Completed',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isCompleted
                        ? AppPalette.success
                        : AppPalette.orangeAccent,
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
