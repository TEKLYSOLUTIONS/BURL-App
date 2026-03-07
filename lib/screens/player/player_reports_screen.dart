import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../config/palette.dart';
import '../../services/auth_service.dart';
import '../../services/session_service.dart';
import '../../utils/date_time_utils.dart';

class PlayerReportsScreen extends StatefulWidget {
  /// Pass a non-empty playerId to view a specific player's reports (guardian/coach flow).
  /// When empty, the screen loads the currently logged-in player's own reports.
  final String playerId;

  const PlayerReportsScreen({super.key, required this.playerId});

  @override
  State<PlayerReportsScreen> createState() => _PlayerReportsScreenState();
}

class _PlayerReportsScreenState extends State<PlayerReportsScreen> {
  bool _isLoading = true;
  String? _error;
  List<dynamic> _reports = [];

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      String? id = widget.playerId.isNotEmpty
          ? widget.playerId
          : await AuthService.getUserId();
      if (id == null || id.isEmpty) {
        setState(() {
          _isLoading = false;
          _error = 'Could not determine player ID.';
        });
        return;
      }
      final reports = await SessionService.getPlayerSessionReports(id);
      if (mounted) {
        setState(() {
          _reports = reports;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Failed to load reports. Please try again.';
        });
      }
    }
  }

  double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Performance Reports',
          style: GoogleFonts.inter(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          onPressed: () => context.pop(),
        ),
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                _error!,
                style: GoogleFonts.inter(fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadReports,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_reports.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.description_outlined,
                  size: 64,
                  color: Theme.of(context).disabledColor),
              const SizedBox(height: 16),
              Text(
                'No reports yet',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Coach reports will appear here\nafter your training sessions.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.55),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: _reports.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, index) =>
          _buildReportCard(context, _reports[index], index: index),
    );
  }

  Widget _buildReportCard(BuildContext context, dynamic report,
      {int index = 0}) {
    final Map<String, dynamic> r = Map<String, dynamic>.from(report as Map);

    final coach = r['coach'] as Map<String, dynamic>?;
    final String sessionTitle = r['sessionTitle']?.toString() ??
        (r['session'] as Map<String, dynamic>?)?['title']?.toString() ??
        'Session';
    final String coachName = coach?['fullName']?.toString() ?? 'Coach';
    final String dateStr = r['sessionDate']?.toString() ??
        r['date']?.toString() ??
        (r['session'] as Map<String, dynamic>?)?['date']?.toString() ??
        '';
    final String notes = r['notes']?.toString() ??
        r['coachNotes']?.toString() ??
        r['primaryFocus']?.toString() ??
        '';
    final double batting =
        _toDouble(r['batting'] ?? r['technicalRating'] ?? r['battingRating']);
    final double bowling =
        _toDouble(r['bowling'] ?? r['physicalRating'] ?? r['bowlingRating']);
    final double fielding =
        _toDouble(r['fielding'] ?? r['mentalRating'] ?? r['fieldingRating']);
    final double overall = _toDouble(r['overall'] ?? r['overallRating']);
    final String formattedDate = dateStr.isNotEmpty
        ? DateTimeUtils.formatDate(
            DateTime.tryParse(dateStr) ?? DateTime.now())
        : 'Unknown Date';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppPalette.orangeAccent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.description_outlined,
                    color: AppPalette.orangeAccent, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sessionTitle,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      'by $coachName  •  $formattedDate',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
              if (overall > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star_rounded,
                          color: Colors.amber, size: 14),
                      const SizedBox(width: 3),
                      Text(
                        overall.toStringAsFixed(1),
                        style: GoogleFonts.inter(
                          color: Colors.amber,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          // Scores row
          if (batting > 0 || bowling > 0 || fielding > 0) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                if (batting > 0)
                  _ScoreChip(label: 'Technical', value: batting),
                if (batting > 0 && bowling > 0) const SizedBox(width: 8),
                if (bowling > 0)
                  _ScoreChip(label: 'Physical', value: bowling),
                if ((batting > 0 || bowling > 0) && fielding > 0)
                  const SizedBox(width: 8),
                if (fielding > 0)
                  _ScoreChip(label: 'Mental', value: fielding),
              ],
            ),
          ],

          // Notes
          if (notes.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              notes,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.65),
                height: 1.4,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    ).animate().fadeIn(delay: (80 * index).ms).slideY(begin: 0.08);
  }
}

class _ScoreChip extends StatelessWidget {
  final String label;
  final double value;

  const _ScoreChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .secondary
            .withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$label: ${value.toStringAsFixed(1)}',
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.secondary,
        ),
      ),
    );
  }
}
