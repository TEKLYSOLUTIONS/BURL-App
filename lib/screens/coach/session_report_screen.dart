import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../services/session_service.dart';
import '../../utils/date_time_utils.dart';

class SessionReportScreen extends StatefulWidget {
  final String sessionId;

  const SessionReportScreen({super.key, required this.sessionId});

  @override
  State<SessionReportScreen> createState() => _SessionReportScreenState();
}

class _SessionReportScreenState extends State<SessionReportScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _session;

  @override
  void initState() {
    super.initState();
    _fetchSessionDetails();
  }

  Future<void> _fetchSessionDetails() async {
    setState(() => _isLoading = true);

    try {
      final session = await SessionService.getSessionById(widget.sessionId);
      if (mounted) {
        setState(() {
          _session = session;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load session report: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Session Report')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_session == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Session Report')),
        body: const Center(child: Text('Session not found')),
      );
    }

    final assignedPlayers = _session!['assignedPlayers'] as List? ?? [];
    final timeSlots = _session!['timeSlots'] as List? ?? [];
    final firstTimeSlot = timeSlots.isNotEmpty ? timeSlots[0] : null;
    final startTime = firstTimeSlot != null
        ? DateTime.parse(firstTimeSlot['startTime'] as String).toLocal()
        : DateTime.now();

    final presentCount = assignedPlayers
        .where((p) => p['attended'] == true)
        .length;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).cardColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.close,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Session Report',
          style: GoogleFonts.outfit(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Session Header Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(20),
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
                    _session!['title']?.toString() ?? 'Untitled Session',
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    DateTimeUtils.formatSessionDate(startTime),
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildStatBadge(
                        context,
                        'Present',
                        presentCount.toString(),
                        Colors.green,
                      ),
                      const SizedBox(width: 12),
                      _buildStatBadge(
                        context,
                        'Absent',
                        (assignedPlayers.length - presentCount).toString(),
                        Colors.red,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Session Notes
            _buildSectionLabel('SESSION NOTES'),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
                ),
              ),
              child: Text(
                (_session!['sessionNotes'] != null &&
                        _session!['sessionNotes'].toString().isNotEmpty)
                    ? _session!['sessionNotes'].toString()
                    : 'No notes added for this session.',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  height: 1.5,
                  color: Theme.of(context).colorScheme.onSurface,
                  fontStyle:
                      (_session!['sessionNotes'] == null ||
                          _session!['sessionNotes'].toString().isEmpty)
                      ? FontStyle.italic
                      : FontStyle.normal,
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Player Feedback
            _buildSectionLabel('PLAYER FEEDBACK (${assignedPlayers.length})'),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: assignedPlayers.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final playerData = assignedPlayers[index];
                final player = (playerData['player'] is Map)
                    ? Map<String, dynamic>.from(playerData['player'])
                    : <String, dynamic>{};
                final attended = playerData['attended'] as bool? ?? false;
                final note = playerData['note'] as String? ?? '';

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: attended
                          ? Colors.green.withValues(alpha: 0.3)
                          : Colors.red.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundImage: NetworkImage(
                              player['profilePhoto']?.toString() ??
                                  'https://i.pravatar.cc/150',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              player['fullName']?.toString() ?? 'Player',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: attended
                                  ? Colors.green.withValues(alpha: 0.1)
                                  : Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              attended ? 'Present' : 'Absent',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: attended ? Colors.green : Colors.red,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (note.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest
                                .withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            note,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
        letterSpacing: 1.0,
      ),
    );
  }

  Widget _buildStatBadge(
    BuildContext context,
    String label,
    String value,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
