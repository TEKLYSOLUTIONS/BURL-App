import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/palette.dart';
import '../../services/session_service.dart';
import '../../services/coach_service.dart';
import '../../services/booking_service.dart';
import '../../utils/date_time_utils.dart';
import 'create_session_screen.dart';

class SessionDetailsScreen extends StatefulWidget {
  final String sessionId;

  const SessionDetailsScreen({super.key, required this.sessionId});

  @override
  State<SessionDetailsScreen> createState() => _SessionDetailsScreenState();
}

class _SessionDetailsScreenState extends State<SessionDetailsScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _session;
  String? _userRole;
  bool _isDeleting = false;

  // Booking State
  bool _isBooked = false;
  String? _bookingId;
  bool _isCancelling = false;

  @override
  void initState() {
    super.initState();
    _loadUserRole().then((_) => _checkBookingStatus());
    _fetchSessionDetails();
  }

  Future<void> _loadUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userRole = prefs.getString('user_role');
    });
  }

  Future<void> _fetchSessionDetails() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final session = await SessionService.getSessionById(widget.sessionId);
      setState(() {
        _session = session;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load session: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteSession() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Session?'),
        content: const Text(
          'Are you sure you want to delete this session? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isDeleting = true;
    });

    try {
      await SessionService.deleteSession(widget.sessionId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Session deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop(true); // Return to previous screen
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete session: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  Future<void> _checkBookingStatus() async {
    if (_userRole == 'coach') return;

    try {
      // Fetch user's upcoming bookings
      final response = await BookingService.getPlayerBookings(type: 'upcoming');
      final bookings = response['bookings'] as List<dynamic>;

      // Check if any booking matches this session
      for (final booking in bookings) {
        final session = booking['session'];
        if (session != null && session['_id'] == widget.sessionId) {
          // Check status - only consider active bookings
          final status = booking['status'] as String? ?? 'pending';
          if (status != 'cancelled' && status != 'declined') {
            if (mounted) {
              setState(() {
                _isBooked = true;
                _bookingId = booking['_id'];
              });
            }
            break;
          }
        }
      }
    } catch (e) {
      debugPrint('Error checking booking status: $e');
    } finally {
      if (mounted) {}
    }
  }

  Future<void> _cancelBooking() async {
    if (_bookingId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Booking?'),
        content: const Text('Are you sure you want to cancel this session?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep Booking'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isCancelling = true);

    try {
      await BookingService.cancelBooking(_bookingId!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking cancelled successfully'),
            backgroundColor: Colors.green,
          ),
        );

        setState(() {
          _isBooked = false;
          _bookingId = null;
        });

        // Refresh session details to update capacity/attendees if needed
        _fetchSessionDetails();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to cancel booking: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCancelling = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: Text(
            'Session Details',
            style: GoogleFonts.outfit(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      );
    }

    if (_session == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: Text(
            'Session Details',
            style: GoogleFonts.outfit(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                'Session not found',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.pop(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    final timeSlots = _session!['timeSlots'] as List? ?? [];
    final firstTimeSlot = timeSlots.isNotEmpty ? timeSlots[0] : null;
    final startTime = firstTimeSlot != null
        ? DateTime.parse(firstTimeSlot['startTime'] as String).toLocal()
        : DateTime.now();
    final duration = firstTimeSlot != null
        ? firstTimeSlot['durationMinutes'] as int
        : 0;
    final assignedPlayers = _session!['assignedPlayers'] as List? ?? [];
    // Handle coach data - backend might send it as 'coach' or 'createdBy'
    Map<String, dynamic>? coach;
    final createdByValue = _session!['createdBy'];
    final coachValue = _session!['coach'];

    if (createdByValue is Map<String, dynamic>) {
      coach = createdByValue;
    } else if (coachValue is Map<String, dynamic>) {
      // Check for nested coachProfile
      if (coachValue['coachProfile'] is Map<String, dynamic>) {
        coach = coachValue['coachProfile'];
      } else {
        coach = coachValue;
      }
    }

    final isCoach = _userRole == 'coach';

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: CircleAvatar(
            backgroundColor: Colors.white,
            child: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Theme.of(context).iconTheme.color,
              ),
              onPressed: () => context.pop(),
            ),
          ),
        ),
        title: Text(
          'Session Details',
          style: GoogleFonts.outfit(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          if (isCoach)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.orange),
              onSelected: (value) async {
                if (value == 'edit') {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          CreateSessionScreen(sessionToEdit: _session),
                    ),
                  );
                  if (result == true) {
                    _fetchSessionDetails();
                  }
                } else if (value == 'delete') {
                  _deleteSession();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 20, color: Colors.orange),
                      SizedBox(width: 12),
                      Text('Edit Session'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 20, color: Colors.red),
                      SizedBox(width: 12),
                      Text(
                        'Delete Session',
                        style: TextStyle(color: Colors.red),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
        flexibleSpace: Container(
          color: Theme.of(context).scaffoldBackgroundColor,
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Image with Cricket Icon
                Container(
                  height: 200,
                  width: double.infinity,
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppPalette.navyPrimary,
                        AppPalette.navyPrimary.withValues(alpha: 0.7),
                      ],
                    ),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Icon(
                          Icons.sports_cricket,
                          size: 80,
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                      ),
                      Positioned(
                        top: 16,
                        left: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: startTime.isAfter(DateTime.now())
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).disabledColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            startTime.isAfter(DateTime.now())
                                ? 'Upcoming'
                                : 'Completed',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate().slideY(begin: 0.1, duration: 400.ms),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        _session!['title'] as String,
                        style: GoogleFonts.outfit(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Date Time
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 18,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            DateTimeUtils.formatSessionDate(startTime),
                            style: GoogleFonts.inter(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),
                      Divider(color: Theme.of(context).dividerColor),
                      const SizedBox(height: 20),

                      // Stats Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildQuickStat(
                            Icons.timer_outlined,
                            DateTimeUtils.formatDuration(duration),
                          ),
                          _buildQuickStat(
                            Icons.people_outline,
                            '${_session!['capacity']} Capacity',
                          ),
                          _buildQuickStat(Icons.sports_cricket, 'Cricket'),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // Description
                      if (_session!['description'] != null &&
                          (_session!['description'] as String).isNotEmpty) ...[
                        _buildSectionTitle('Description'),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _session!['description'] as String,
                            style: GoogleFonts.inter(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],

                      // Coach & Location
                      _buildSectionTitle('Coach & Location'),
                      const SizedBox(height: 16),

                      // Coach Card
                      if (coach != null)
                        _buildInfoCard(
                          icon: CircleAvatar(
                            backgroundColor: AppPalette.navyPrimary,
                            child: Text(
                              (coach['fullName'] as String)
                                  .substring(0, 1)
                                  .toUpperCase(),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: coach['fullName'] as String,
                          subtitle: 'Head Coach',
                          actionIcon: Icons.phone,
                        ),
                      const SizedBox(height: 12),

                      // Location Card
                      _buildInfoCard(
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.primaryContainer,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.location_on,
                            color: Theme.of(
                              context,
                            ).colorScheme.onPrimaryContainer,
                          ),
                        ),
                        title: _session!['location'] as String,
                        subtitle: 'Training Location',
                        actionIcon: Icons.directions,
                      ),

                      const SizedBox(height: 32),

                      // Session Level Note
                      if (_session!['sessionNotes'] != null &&
                          (_session!['sessionNotes'] as String).isNotEmpty) ...[
                        _buildSectionTitle('Session Note'),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Theme.of(context).dividerColor,
                            ),
                          ),
                          child: Text(
                            _session!['sessionNotes'] as String,
                            style: GoogleFonts.inter(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],

                      // Participants & Attendance
                      if (assignedPlayers.isNotEmpty) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildSectionTitle(
                              'Participants (${assignedPlayers.length})',
                            ),
                            if (isCoach)
                              TextButton(
                                onPressed: () {
                                  _showAddPlayersSheet();
                                },
                                child: Text(
                                  'Add Players',
                                  style: GoogleFonts.outfit(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // If coach and session started/ended, show attendance list
                        if (isCoach &&
                            startTime.isBefore(
                              DateTime.now().add(const Duration(minutes: 15)),
                            ))
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: assignedPlayers.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final pData = assignedPlayers[index];
                              final player =
                                  pData['player'] as Map<String, dynamic>;
                              final attended =
                                  pData['attended'] as bool? ?? false;
                              final playerId = player['_id'] as String;

                              return Container(
                                decoration: BoxDecoration(
                                  color: Theme.of(context).cardColor,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: attended
                                        ? Colors.green.withValues(alpha: 0.5)
                                        : Theme.of(context).dividerColor,
                                  ),
                                ),
                                child: SwitchListTile(
                                  title: Text(
                                    player['fullName'] as String,
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        attended ? 'Present' : 'Absent',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: attended
                                              ? Colors.green
                                              : Theme.of(
                                                  context,
                                                ).colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                      if (pData['note'] != null &&
                                          (pData['note'] as String).isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 4,
                                          ),
                                          child: Text(
                                            'Note: ${pData['note']}',
                                            style: GoogleFonts.inter(
                                              fontSize: 12,
                                              fontStyle: FontStyle.italic,
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  secondary: CircleAvatar(
                                    backgroundImage: NetworkImage(
                                      player['profilePhoto'] ??
                                          'https://i.pravatar.cc/150?u=$playerId',
                                    ),
                                  ),
                                  value: attended,
                                  activeTrackColor: Colors.green,
                                  onChanged: (val) async {
                                    // Capture ScaffoldMessenger before async gap
                                    final messenger = ScaffoldMessenger.of(
                                      context,
                                    );

                                    // Optimistic update
                                    setState(() {
                                      assignedPlayers[index]['attended'] = val;
                                    });

                                    try {
                                      await SessionService.updateAttendance(
                                        widget.sessionId,
                                        playerId,
                                        val,
                                      );
                                    } catch (e) {
                                      // Revert on error
                                      if (mounted) {
                                        setState(() {
                                          assignedPlayers[index]['attended'] =
                                              !val;
                                        });
                                        messenger.showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Failed to update attendance: $e',
                                            ),
                                          ),
                                        );
                                      }
                                    }
                                  },
                                ),
                              );
                            },
                          )
                        else
                          // Standard horizontal list for players or future sessions
                          SizedBox(
                            height: 60,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: assignedPlayers.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(width: 16),
                              itemBuilder: (context, index) {
                                final player =
                                    assignedPlayers[index]['player']
                                        as Map<String, dynamic>;
                                final fullName = player['fullName'] as String;
                                return _buildAvatar(
                                  fullName.split(' ')[0],
                                  player['_id'] as String,
                                );
                              },
                            ),
                          ),
                        const SizedBox(height: 32),
                      ],

                      // All Time Slots
                      if (timeSlots.length > 1) ...[
                        _buildSectionTitle(
                          'All Sessions (${timeSlots.length})',
                        ),
                        const SizedBox(height: 16),
                        ...timeSlots.asMap().entries.map((entry) {
                          final index = entry.key;
                          final timeSlot = entry.value;
                          final occStartTime = DateTime.parse(
                            timeSlot['startTime'] as String,
                          ).toLocal();
                          final occEndTime = DateTime.parse(
                            timeSlot['endTime'] as String,
                          ).toLocal();

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Theme.of(context).dividerColor,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppPalette.orangeLight.withValues(
                                      alpha: 0.2,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${index + 1}',
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        DateTimeUtils.formatSessionDate(
                                          occStartTime,
                                        ),
                                        style: GoogleFonts.outfit(
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurface,
                                        ),
                                      ),
                                      Text(
                                        '${DateTimeUtils.formatTimeFromDateTime(occStartTime)} - ${DateTimeUtils.formatTimeFromDateTime(occEndTime)}',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  DateTimeUtils.formatDuration(
                                    timeSlot['durationMinutes'] as int,
                                  ),
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                        const SizedBox(height: 20),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Sticky Footer - Role-based actions
          if (!isCoach && startTime.isAfter(DateTime.now()))
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(
                        context,
                      ).shadowColor.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: _isBooked
                      ? OutlinedButton(
                          onPressed: _isCancelling ? null : _cancelBooking,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.red),
                            foregroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isCancelling
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.red,
                                  ),
                                )
                              : Text(
                                  'Cancel Booking',
                                  style: GoogleFonts.outfit(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        )
                      : ElevatedButton(
                          onPressed: () {
                            context.push('/booking/${widget.sessionId}');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppPalette.navyPrimary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Book Session',
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                ),
              ),
            ),

          if (isCoach)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(
                        context,
                      ).shadowColor.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isDeleting
                            ? null
                            : () => context.push('/coach/session-report'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: AppPalette.navyPrimary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'View Report',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppPalette.navyPrimary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isDeleting
                            ? null
                            : () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CreateSessionScreen(
                                      sessionToEdit: _session,
                                    ),
                                  ),
                                );
                                if (result == true) {
                                  _fetchSessionDetails();
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppPalette.orangeAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          _isDeleting ? 'Deleting...' : 'Edit Session',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Sticky Footer for Players (Review)
          if (!isCoach && startTime.isBefore(DateTime.now()))
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(
                        context,
                      ).shadowColor.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final result = await context.push(
                        '/add-review',
                        extra: _session!,
                      );
                      if (result == true) {
                        // Refresh session details if needed, or just show success
                        _fetchSessionDetails();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppPalette.navyPrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Leave a Review',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
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

  Widget _buildQuickStat(IconData icon, String label) {
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary, size: 24),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }

  Widget _buildInfoCard({
    required Widget icon,
    required String title,
    required String subtitle,
    required IconData actionIcon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          icon,
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              actionIcon,
              color: Theme.of(context).colorScheme.primary,
            ),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(String label, String playerId) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppPalette.navyPrimary.withValues(alpha: 0.1),
        shape: BoxShape.circle,
        border: Border.all(
          color: AppPalette.navyPrimary.withValues(alpha: 0.2),
        ),
      ),
      child: Center(
        child: Text(
          label.substring(0, min(label.length, 2)).toUpperCase(),
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: AppPalette.navyPrimary,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  void _showAddPlayersSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddPlayersSheet(
        sessionId: widget.sessionId,
        currentPlayers: (_session!['assignedPlayers'] as List? ?? [])
            .map((p) => (p['player'] as Map<String, dynamic>)['_id'] as String)
            .toList(),
        onPlayersAdded: () {
          _fetchSessionDetails(); // Refresh
        },
      ),
    );
  }
}

class _AddPlayersSheet extends StatefulWidget {
  final String sessionId;
  final List<String> currentPlayers;
  final VoidCallback onPlayersAdded;

  const _AddPlayersSheet({
    required this.sessionId,
    required this.currentPlayers,
    required this.onPlayersAdded,
  });

  @override
  State<_AddPlayersSheet> createState() => _AddPlayersSheetState();
}

class _AddPlayersSheetState extends State<_AddPlayersSheet> {
  bool _isLoading = true;
  bool _isSaving = false;
  List<Map<String, dynamic>> _myPlayers = [];
  final Set<String> _selectedPlayers = {};

  @override
  void initState() {
    super.initState();
    _loadMyPlayers();
  }

  Future<void> _loadMyPlayers() async {
    try {
      final data = await CoachService.getCoachPlayers();
      final players = data['players'] as List? ?? [];

      if (!mounted) return;

      setState(() {
        // Filter out players already in the session
        _myPlayers = players
            .where((p) {
              final id = p['_id'] as String;
              return !widget.currentPlayers.contains(id);
            })
            .map((p) => p as Map<String, dynamic>)
            .toList();

        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        debugPrint('Error loading players: $e');
      }
    }
  }

  Future<void> _saveSelection() async {
    if (_selectedPlayers.isEmpty) return;

    setState(() => _isSaving = true);

    try {
      await SessionService.addPlayersToSession(
        widget.sessionId,
        _selectedPlayers.toList(),
      );

      if (mounted) {
        Navigator.pop(context);
        widget.onPlayersAdded();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Added ${_selectedPlayers.length} players to session',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add players: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Add Players',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                if (_selectedPlayers.isNotEmpty)
                  TextButton(
                    onPressed: _isSaving ? null : _saveSelection,
                    child: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            'Add (${_selectedPlayers.length})',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _myPlayers.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 48,
                          color: Theme.of(context).disabledColor,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No available players to add',
                          style: GoogleFonts.inter(
                            color: Theme.of(context).disabledColor,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: _myPlayers.length,
                    itemBuilder: (context, index) {
                      final player = _myPlayers[index];
                      final id = player['_id'] as String;
                      final isSelected = _selectedPlayers.contains(id);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: ListTile(
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                _selectedPlayers.remove(id);
                              } else {
                                _selectedPlayers.add(id);
                              }
                            });
                          },
                          leading: CircleAvatar(
                            backgroundImage: NetworkImage(
                              player['avatarUrl'] ??
                                  'https://i.pravatar.cc/150',
                            ),
                          ),
                          title: Text(
                            player['name'] ?? 'Unknown',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          trailing: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.transparent,
                              border: Border.all(
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).dividerColor,
                                width: 2,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: isSelected
                                ? const Icon(
                                    Icons.check,
                                    size: 16,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
