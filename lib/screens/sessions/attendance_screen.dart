import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../config/palette.dart';
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
        appBar: AppBar(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          elevation: 0,
          title: Text(
            'Session In Progress',
            style: GoogleFonts.outfit(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final assignedPlayers = _session!['assignedPlayers'] as List? ?? [];
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
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Session In Progress',
          style: GoogleFonts.outfit(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Session Title
            Text(
              _session!['title'] as String,
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),

            // Date & Time
            Text(
              '${DateTimeUtils.formatSessionDate(startTime)} • ${DateTimeUtils.formatTimeFromDateTime(startTime)} - ${DateTimeUtils.formatTimeFromDateTime(endTime)}',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),

            // Time Remaining Info Box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.timer_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      endTime.isAfter(DateTime.now())
                          ? 'Time remaining: ${DateTimeUtils.formatDurationDetailed(endTime.difference(DateTime.now()).inMinutes)}'
                          : 'Session time completed',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

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
            const SizedBox(height: 16),

            // Participant List
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: assignedPlayers.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final playerData = assignedPlayers[index];
                final player = playerData['player'] as Map<String, dynamic>;
                final playerId = player['_id'] as String;
                final fullName = player['fullName'] as String;
                final isPresent = _attendance[playerId] ?? true;

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: !isPresent
                          ? Colors.red.withValues(alpha: 0.5)
                          : Colors.green.withValues(alpha: 0.3),
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
                                    ? Colors.green
                                    : Colors.transparent,
                                border: Border.all(
                                  color: isPresent ? Colors.green : Colors.grey,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: isPresent
                                  ? const Icon(
                                      Icons.check,
                                      size: 16,
                                      color: Colors.white,
                                    )
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Name
                          Expanded(
                            child: Text(
                              fullName,
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Warning for absent
                      if (!isPresent) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.red.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.warning_amber_rounded,
                                size: 20,
                                color: Colors.red,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Absent - No show',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: Colors.red.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 12),

                      // Note Input
                      TextField(
                        controller: _noteControllers[playerId],
                        decoration: InputDecoration(
                          hintText: 'Add note for this student...',
                          hintStyle: GoogleFonts.inter(fontSize: 13),
                          filled: true,
                          fillColor: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        style: GoogleFonts.inter(fontSize: 14),
                        maxLines: 2,
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            // Attendance Summary
            Center(
              child: Text(
                '${_getPresentCount()} of ${assignedPlayers.length} present',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            const SizedBox(height: 32),

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
            const SizedBox(height: 16),

            TextField(
              decoration: InputDecoration(
                hintText: 'Overall session notes...',
                hintStyle: GoogleFonts.inter(fontSize: 14),
                filled: true,
                fillColor: Theme.of(context).cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Theme.of(context).dividerColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Theme.of(context).dividerColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.all(16),
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

            const SizedBox(height: 32),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSaving ? null : _saveProgress,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'Save',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveAndComplete,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            'Complete Session',
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}
