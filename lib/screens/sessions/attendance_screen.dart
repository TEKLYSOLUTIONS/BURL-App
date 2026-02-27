import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../config/palette.dart';
import '../../utils/responsive.dart';
import '../../services/session_service.dart';
import '../../utils/date_time_utils.dart';

class AttendanceScreen extends StatefulWidget {
  final String sessionId;

  const AttendanceScreen({super.key, required this.sessionId});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  Map<String, dynamic>? _session;
  String _sessionNotes = '';
  Map<String, bool> _attendance = {};
  Map<String, TextEditingController> _noteControllers = {};

  @override
  void initState() {
    super.initState();
    _loadSessionData();
  }

  @override
  void dispose() {
    // Dispose all controllers
    for (var controller in _noteControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadSessionData() async {
    setState(() => _isLoading = true);

    try {
      final session = await SessionService.getSessionById(widget.sessionId);
      final assignedPlayers = session['assignedPlayers'] as List? ?? [];

      // Initialize attendance and notes from existing data or defaults
      Map<String, bool> attendanceMap = {};
      Map<String, TextEditingController> controllersMap = {};

      for (var playerData in assignedPlayers) {
        final player = playerData['player'] as Map<String, dynamic>;
        final playerId = player['_id'] as String;

        // Default to present, or use existing attendance value
        attendanceMap[playerId] = playerData['attended'] as bool? ?? true;

        // Get existing note if any
        final existingNote = playerData['note'] as String? ?? '';
        controllersMap[playerId] = TextEditingController(text: existingNote);
      }

      if (mounted) {
        setState(() {
          _session = session;
          _attendance = attendanceMap;
          _noteControllers = controllersMap;
          _sessionNotes = session['sessionNotes'] as String? ?? '';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load session: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveAndComplete() async {
    setState(() => _isSaving = true);

    try {
      // Save attendance for all participants
      final assignedPlayers = _session!['assignedPlayers'] as List;
      for (var playerData in assignedPlayers) {
        final player = playerData['player'] as Map<String, dynamic>;
        final playerId = player['_id'] as String;

        await SessionService.updateAttendance(
          widget.sessionId,
          playerId,
          _attendance[playerId] ?? false,
          note: _noteControllers[playerId]?.text,
        );
      }

      // Complete session with overall notes
      await SessionService.completeSession(
        widget.sessionId,
        sessionNotes: _sessionNotes,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Session completed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        // Navigate back to dashboard
        context.go('/coach');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to complete session: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveProgress() async {
    setState(() => _isSaving = true);

    try {
      // Save current attendance and notes without completing
      final assignedPlayers = _session!['assignedPlayers'] as List;
      for (var playerData in assignedPlayers) {
        final player = playerData['player'] as Map<String, dynamic>;
        final playerId = player['_id'] as String;

        await SessionService.updateAttendance(
          widget.sessionId,
          playerId,
          _attendance[playerId] ?? false,
          note: _noteControllers[playerId]?.text,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Progress saved'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() => _isSaving = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  int _getPresentCount() {
    return _attendance.values.where((attended) => attended).length;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final rawAssignedPlayers = _session!['assignedPlayers'] as List? ?? [];
    final List<dynamic> assignedPlayers = [];
    final Set<String> seenPlayerIds = {};
    for (var pData in rawAssignedPlayers) {
      bool added = false;
      if (pData is Map && pData['player'] is Map) {
        final playerId = pData['player']['_id']?.toString();
        if (playerId != null && playerId.isNotEmpty) {
          if (!seenPlayerIds.contains(playerId)) {
            seenPlayerIds.add(playerId);
            assignedPlayers.add(pData);
          }
          added = true;
        }
      }
      if (!added) assignedPlayers.add(pData);
    }

    final timeSlots = _session!['timeSlots'] as List? ?? [];
    final firstTimeSlot = timeSlots.isNotEmpty ? timeSlots[0] : null;
    final startTime = firstTimeSlot != null
        ? DateTime.parse(firstTimeSlot['startTime'] as String).toLocal()
        : DateTime.now();
    final endTime = firstTimeSlot != null
        ? DateTime.parse(firstTimeSlot['endTime'] as String).toLocal()
        : DateTime.now();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          Column(
            children: [
              // Rounded Navy Blue Header
              Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(
                  context.spacing.md,
                  MediaQuery.of(context).padding.top + context.spacing.sm,
                  context.spacing.md,
                  context.spacing.md,
                ),
                decoration: BoxDecoration(
                  color: AppPalette.navyPrimary,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  children: [
                    // Back button and title row
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: AppPalette.white,
                          ),
                          onPressed: () => context.pop(),
                        ),
                        Expanded(
                          child: Center(
                            child: Text(
                              'Session In Progress',
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                color: AppPalette.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 48), // Balance the back button
                      ],
                    ),
                  ],
                ),
              ),

              // Main Content
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(context.spacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Session Title
                      Text(
                        _session!['title'] as String,
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      SizedBox(height: context.spacing.xs),

                      // Date & Time
                      Text(
                        '${DateTimeUtils.formatSessionDate(startTime)} • ${DateTimeUtils.formatTimeFromDateTime(startTime)} - ${DateTimeUtils.formatTimeFromDateTime(endTime)}',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppPalette.textSecondaryLight,
                        ),
                      ),
                      SizedBox(height: context.spacing.lg),

                      // Time Remaining Info Box
                      Container(
                        padding: EdgeInsets.all(context.spacing.md),
                        decoration: BoxDecoration(
                          color: AppPalette.navyPrimary,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.timer_outlined,
                              color: AppPalette.white,
                              size: 20,
                            ),
                            SizedBox(width: context.spacing.sm),
                            Expanded(
                              child: Text(
                                endTime.isAfter(DateTime.now())
                                    ? 'Time remaining: ${DateTimeUtils.formatDurationDetailed(endTime.difference(DateTime.now()).inMinutes)}'
                                    : 'Session time completed',
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppPalette.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: context.spacing.xl),

                      // Mark Attendance Section
                      Text(
                        'MARK ATTENDANCE',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppPalette.textSecondaryLight,
                          letterSpacing: 1.2,
                        ),
                      ),
                      SizedBox(height: context.spacing.md),

                      // Participant List
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: assignedPlayers.length,
                        separatorBuilder: (context, index) =>
                            SizedBox(height: context.spacing.sm),
                        itemBuilder: (context, index) {
                          final playerData = assignedPlayers[index];
                          final player =
                              playerData['player'] as Map<String, dynamic>;
                          final playerId = player['_id'] as String;
                          final fullName = player['fullName'] as String;
                          final isPresent = _attendance[playerId] ?? true;

                          return Container(
                            padding: EdgeInsets.all(context.spacing.md),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: !isPresent
                                    ? AppPalette.error.withValues(alpha: 0.5)
                                    : Colors.transparent,
                                width: !isPresent ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Name and Checkbox
                                Row(
                                  children: [
                                    // Checkbox
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _attendance[playerId] = !isPresent;
                                        });
                                      },
                                      child: Container(
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          color: isPresent
                                              ? AppPalette.successGreen
                                              : Colors.transparent,
                                          border: Border.all(
                                            color: isPresent
                                                ? AppPalette.successGreen
                                                : AppPalette.textDisabled,
                                            width: 2,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: isPresent
                                            ? const Icon(
                                                Icons.check,
                                                size: 16,
                                                color: AppPalette.white,
                                              )
                                            : null,
                                      ),
                                    ),
                                    SizedBox(width: context.spacing.sm),

                                    // Name
                                    Expanded(
                                      child: Text(
                                        fullName,
                                        style: GoogleFonts.inter(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurface,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                // Warning for absent
                                if (!isPresent) ...[
                                  SizedBox(height: context.spacing.sm),
                                  Container(
                                    padding: EdgeInsets.all(context.spacing.sm),
                                    decoration: BoxDecoration(
                                      color: AppPalette.error.withValues(
                                        alpha: 0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: AppPalette.error.withValues(
                                          alpha: 0.3,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.warning_amber_rounded,
                                          size: 20,
                                          color: AppPalette.error,
                                        ),
                                        SizedBox(width: context.spacing.xs),
                                        Text(
                                          'Absent - No show',
                                          style: GoogleFonts.inter(
                                            fontSize: 13,
                                            color: AppPalette.error,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                SizedBox(height: context.spacing.sm),

                                // Add Report Button
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      context.push(
                                        '/coach/player-report/${widget.sessionId}/$playerId',
                                      );
                                    },
                                    icon: const Icon(Icons.analytics_outlined,
                                        size: 18),
                                    label: Text(
                                      'Add Progress Report',
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppPalette.orangeAccent,
                                      side: const BorderSide(
                                          color: AppPalette.orangeAccent),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 10),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                      SizedBox(height: context.spacing.md),

                      // Attendance Summary
                      Center(
                        child: Text(
                          '${_getPresentCount()} of ${assignedPlayers.length} present',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppPalette.textSecondaryLight,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),

                      SizedBox(height: context.spacing.xl),

                      // Session Notes Section
                      Text(
                        'SESSION NOTES (OPTIONAL)',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppPalette.textSecondaryLight,
                          letterSpacing: 1.2,
                        ),
                      ),
                      SizedBox(height: context.spacing.md),

                      TextField(
                        decoration: InputDecoration(
                          hintText: 'Overall session notes...',
                          hintStyle: GoogleFonts.inter(fontSize: 14),
                          filled: true,
                          fillColor: Theme.of(context).cardColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: Theme.of(context).dividerColor,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: Theme.of(context).dividerColor,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: AppPalette.orangeAccent,
                              width: 2,
                            ),
                          ),
                          contentPadding: EdgeInsets.all(context.spacing.md),
                        ),
                        style: GoogleFonts.inter(fontSize: 14),
                        maxLines: 4,
                        onChanged: (value) {
                          setState(() {
                            _sessionNotes = value;
                          });
                        },
                        controller: TextEditingController(text: _sessionNotes)
                          ..selection = TextSelection.fromPosition(
                            TextPosition(offset: _sessionNotes.length),
                          ),
                      ),

                      const SizedBox(height: 100), // Space for bottom navbar
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Fixed Bottom Navigation Bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                context.spacing.md,
                context.spacing.md,
                context.spacing.md,
                MediaQuery.of(context).padding.bottom + context.spacing.md,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSaving ? null : _saveProgress,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: AppPalette.orangeAccent),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Save',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: context.spacing.sm),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveAndComplete,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppPalette.orangeAccent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: AppPalette.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'Complete Session',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppPalette.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
