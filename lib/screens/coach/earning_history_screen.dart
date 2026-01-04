import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../config/palette.dart';

class EarningHistoryScreen extends StatelessWidget {
  const EarningHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.backgroundLight,
      appBar: AppBar(
        title: Text(
          'Earnings',
          style: GoogleFonts.outfit(
            color: AppPalette.navyPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Total Earnings Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppPalette.navyPrimary, AppPalette.navyLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppPalette.navyPrimary.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    'Total Earnings',
                    style: GoogleFonts.inter(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '\$3,450.00',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMiniStat('This Month', '+\$450'),
                      Container(width: 1, height: 30, color: Colors.white24),
                      _buildMiniStat('Pending', '\$120'),
                    ],
                  ),
                ],
              ),
            ).animate().fadeIn().slideY(),

            const SizedBox(height: 32),

            // Chart Section
            Container(
              height: 250,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Monthly Overview',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: LineChart(
                      LineChartData(
                        gridData: const FlGridData(show: false),
                        titlesData: FlTitlesData(
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                switch (value.toInt()) {
                                  case 0:
                                    return const Text(
                                      'Jan',
                                      style: TextStyle(fontSize: 10),
                                    );
                                  case 1:
                                    return const Text(
                                      'Feb',
                                      style: TextStyle(fontSize: 10),
                                    );
                                  case 2:
                                    return const Text(
                                      'Mar',
                                      style: TextStyle(fontSize: 10),
                                    );
                                  case 3:
                                    return const Text(
                                      'Apr',
                                      style: TextStyle(fontSize: 10),
                                    );
                                  case 4:
                                    return const Text(
                                      'May',
                                      style: TextStyle(fontSize: 10),
                                    );
                                  case 5:
                                    return const Text(
                                      'Jun',
                                      style: TextStyle(fontSize: 10),
                                    );
                                }
                                return const Text('');
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
                        minX: 0,
                        maxX: 5,
                        minY: 0,
                        maxY: 6,
                        lineBarsData: [
                          LineChartBarData(
                            spots: const [
                              FlSpot(0, 3),
                              FlSpot(1, 1),
                              FlSpot(2, 4),
                              FlSpot(3, 3),
                              FlSpot(4, 5),
                              FlSpot(5, 4),
                            ],
                            isCurved: true,
                            color: AppPalette.orangeAccent,
                            barWidth: 3,
                            isStrokeCapRound: true,
                            dotData: const FlDotData(show: false),
                            belowBarData: BarAreaData(
                              show: true,
                              color: AppPalette.orangeAccent.withValues(
                                alpha: 0.1,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 200.ms),

            const SizedBox(height: 32),

            // Transactions Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Transactions',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppPalette.navyPrimary,
                  ),
                ),
                TextButton(onPressed: () {}, child: const Text('See All')),
              ],
            ).animate().fadeIn(delay: 300.ms),

            // List
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 4,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return _buildTransactionItem(index);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildTransactionItem(int index) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppPalette.divider),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppPalette.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.arrow_downward, color: AppPalette.success),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Session with Rahul',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    color: AppPalette.navyPrimary,
                  ),
                ),
                Text(
                  'Oct 24, 2023 • 10:00 AM',
                  style: GoogleFonts.inter(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            '+\$45.00',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              color: AppPalette.success,
              fontSize: 16,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: (300 + index * 100).ms).slideX();
  }
}
