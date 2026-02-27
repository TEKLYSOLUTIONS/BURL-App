import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../config/palette.dart';
import '../../utils/date_time_utils.dart';
import '../../services/session_service.dart';

class PlayerReportScreen extends StatefulWidget {
  final String sessionId;
  final String playerId;

  const PlayerReportScreen({
    super.key,
    required this.sessionId,
    required this.playerId,
  });

  @override
  State<PlayerReportScreen> createState() => _PlayerReportScreenState();
}

class _PlayerReportScreenState extends State<PlayerReportScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  Map<String, dynamic>? _session;
  Map<String, dynamic>? _playerData;

  // Controllers for the 5-section report
  final TextEditingController _primaryFocusController = TextEditingController();

  final TextEditingController _technicalWinsController =
      TextEditingController();
  final TextEditingController _progressController = TextEditingController();
  final TextEditingController _intangiblesController = TextEditingController();

  final TextEditingController _technicalFlawsController =
      TextEditingController();
  final TextEditingController _tacticalMentalController =
      TextEditingController();

  final TextEditingController _specificDrillsController =
      TextEditingController();
  final TextEditingController _fitnessConditioningController =
      TextEditingController();

  final TextEditingController _goalForNextSessionController =
      TextEditingController();
  final TextEditingController _closingEncouragementController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _primaryFocusController.dispose();
    _technicalWinsController.dispose();
    _progressController.dispose();
    _intangiblesController.dispose();
    _technicalFlawsController.dispose();
    _tacticalMentalController.dispose();
    _specificDrillsController.dispose();
    _fitnessConditioningController.dispose();
    _goalForNextSessionController.dispose();
    _closingEncouragementController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final session = await SessionService.getSessionById(widget.sessionId);

      final assignedPlayers = session['assignedPlayers'] as List? ?? [];
      final playerAssignment = assignedPlayers.firstWhere(
        (p) => p['player']['_id'] == widget.playerId,
        orElse: () => null,
      );

      if (playerAssignment == null) {
        throw Exception('Player not found in this session.');
      }

      final report = playerAssignment['report'] as Map<String, dynamic>?;

      if (mounted) {
        setState(() {
          _session = session;
          _playerData = playerAssignment['player'];

          if (report != null) {
            _primaryFocusController.text =
                report['primaryFocus'] as String? ?? '';

            _technicalWinsController.text =
                report['technicalWins'] as String? ?? '';
            _progressController.text = report['progress'] as String? ?? '';
            _intangiblesController.text =
                report['intangibles'] as String? ?? '';

            _technicalFlawsController.text =
                report['technicalFlaws'] as String? ?? '';
            _tacticalMentalController.text =
                report['tacticalMentalAspects'] as String? ?? '';

            _specificDrillsController.text =
                report['specificDrills'] as String? ?? '';
            _fitnessConditioningController.text =
                report['fitnessConditioning'] as String? ?? '';

            _goalForNextSessionController.text =
                report['goalForNextSession'] as String? ?? '';
            _closingEncouragementController.text =
                report['closingEncouragement'] as String? ?? '';
          }

          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveReport() async {
    setState(() => _isSaving = true);

    try {
      final reportData = {
        'primaryFocus': _primaryFocusController.text.trim(),
        'technicalWins': _technicalWinsController.text.trim(),
        'progress': _progressController.text.trim(),
        'intangibles': _intangiblesController.text.trim(),
        'technicalFlaws': _technicalFlawsController.text.trim(),
        'tacticalMentalAspects': _tacticalMentalController.text.trim(),
        'specificDrills': _specificDrillsController.text.trim(),
        'fitnessConditioning': _fitnessConditioningController.text.trim(),
        'goalForNextSession': _goalForNextSessionController.text.trim(),
        'closingEncouragement': _closingEncouragementController.text.trim(),
      };

      await SessionService.updatePlayerReport(
        widget.sessionId,
        widget.playerId,
        reportData,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop(true); // Return true so previous screen can refresh
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save report: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildTextField(
      String label, String hint, TextEditingController controller,
      {int maxLines = 3}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(
              fontSize: 14,
              color: AppPalette.textDisabled,
            ),
            filled: true,
            fillColor: Theme.of(context).cardColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Theme.of(context).dividerColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Theme.of(context).dividerColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: AppPalette.orangeAccent, width: 2),
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
          style: GoogleFonts.inter(fontSize: 15),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, top: 8),
      child: Row(
        children: [
          Icon(icon, color: AppPalette.orangeAccent, size: 22),
          const SizedBox(width: 8),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _session == null || _playerData == null) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          elevation: 0,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final timeSlots = _session!['timeSlots'] as List? ?? [];
    final firstTimeSlot = timeSlots.isNotEmpty ? timeSlots[0] : null;
    final startTime = firstTimeSlot != null
        ? DateTime.parse(firstTimeSlot['startTime'] as String).toLocal()
        : DateTime.now();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.close_rounded,
              color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Detailed Session Report',
          style: GoogleFonts.inter(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Player Info Card
                    Text(
                      'PLAYER',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppPalette.textSecondaryLight,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: Theme.of(context).dividerColor),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: AppPalette.navyPrimary,
                            child: _playerData!['profilePhoto'] != null &&
                                    _playerData!['profilePhoto']
                                        .toString()
                                        .isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(20),
                                    child: Image.network(
                                      _playerData!['profilePhoto'],
                                      width: 40,
                                      height: 40,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : const Icon(Icons.person,
                                    color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _playerData!['fullName'] as String,
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                                Text(
                                  'Player',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: AppPalette.textSecondaryLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Session Info Card
                    Text(
                      'SESSION',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppPalette.textSecondaryLight,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: Theme.of(context).dividerColor),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppPalette.orangeAccent
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.event_note_rounded,
                                color: AppPalette.orangeAccent, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _session!['title'] as String,
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '${DateTimeUtils.formatSessionDate(startTime)} • ${DateTimeUtils.formatTimeFromDateTime(startTime)}',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: AppPalette.textSecondaryLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    Text(
                      'Please provide constructive feedback below. Fields left empty will be omitted from the final report visible to the player.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // 1. Session Overview
                    _buildSectionHeader(
                        '1. Session Overview', Icons.flag_rounded),
                    _buildTextField(
                      'Primary Focus',
                      'E.g. Playing spin bowling, fast bowling run-up...',
                      _primaryFocusController,
                      maxLines: 2,
                    ),

                    // 2. Strengths & Positives
                    _buildSectionHeader(
                        '2. Strengths & Positives', Icons.thumb_up_rounded),
                    _buildTextField(
                      'Technical Wins',
                      'Highlight specific techniques they executed well...',
                      _technicalWinsController,
                    ),
                    _buildTextField(
                      'Progress',
                      'Note any improvements made since their last session...',
                      _progressController,
                    ),
                    _buildTextField(
                      'Intangibles',
                      'Attitude, focus, work ethic, or stamina...',
                      _intangiblesController,
                    ),

                    // 3. Areas for Improvement
                    _buildSectionHeader(
                        '3. Areas for Improvement', Icons.build_rounded),
                    _buildTextField(
                      'Technical Flaws',
                      'Specific mechanics to fix...',
                      _technicalFlawsController,
                    ),
                    _buildTextField(
                      'Tactical & Mental Aspects',
                      'Shot selection, reading the bowler, concentration...',
                      _tacticalMentalController,
                    ),

                    // 4. Action Plan & Homework
                    _buildSectionHeader(
                        '4. Action Plan & Homework', Icons.assignment_rounded),
                    _buildTextField(
                      'Specific Drills',
                      'Drills they can do on their own or with a friend...',
                      _specificDrillsController,
                    ),
                    _buildTextField(
                      'Fitness & Conditioning',
                      'Physical work that might help their specific issues...',
                      _fitnessConditioningController,
                    ),

                    // 5. Looking Ahead
                    _buildSectionHeader(
                        '5. Looking Ahead', Icons.rocket_launch_rounded),
                    _buildTextField(
                      'Goal for Next Session',
                      'Briefly outline what you plan to tackle next time...',
                      _goalForNextSessionController,
                      maxLines: 2,
                    ),
                    _buildTextField(
                      'Closing Encouragement',
                      'A brief, supportive note to keep them motivated...',
                      _closingEncouragementController,
                      maxLines: 2,
                    ),

                    const SizedBox(height: 100), // padding for bottom bar
                  ],
                ),
              ),
            ),

            // Bottom Sticky Button
            Container(
              padding: EdgeInsets.fromLTRB(
                24,
                16,
                24,
                MediaQuery.of(context).padding.bottom + 16,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveReport,
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
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Send Detailed Report',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppPalette.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.send_rounded,
                                color: AppPalette.white, size: 18),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
