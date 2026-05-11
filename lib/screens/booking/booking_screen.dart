import 'package:flutter/material.dart';
import '../../config/palette.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../services/session_service.dart';
import 'package:intl/intl.dart';
import '../../utils/session_utils.dart';

class BookingScreen extends StatefulWidget {
  final String sessionId;

  const BookingScreen({super.key, required this.sessionId});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  bool _isLoading = true;
  DateTime _lastTap = DateTime.fromMillisecondsSinceEpoch(0);
  Map<String, dynamic>? _session;
  Set<int> _selectedDateIndices = {}; // Changed to Set for multi-select

  List<DateTime> _availableDates = [];

  @override
  void initState() {
    super.initState();
    _fetchSessionDetails();
  }

  Future<void> _fetchSessionDetails() async {
    try {
      final session = await SessionService.getSessionById(widget.sessionId);

      // Extract available dates from timeSlots
      final List<DateTime> dates = [];

      // Check for timeSlots first (new structure)
      if (session['timeSlots'] != null) {
        final now = DateTime.now();
        for (var timeSlot in session['timeSlots']) {
          final startTime = DateTime.parse(timeSlot['startTime']).toLocal();
          if (startTime.isAfter(now)) {
            dates.add(startTime);
          }
        }
      }
      // Fallback to occurrences (old structure)
      else if (session['occurrences'] != null) {
        for (var occurrence in session['occurrences']) {
          final date = DateTime.parse(occurrence['date']);
          if (date.isAfter(DateTime.now())) {
            dates.add(date);
          }
        }
      }

      dates.sort();

      setState(() {
        _session = session;
        _availableDates = dates;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading session: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'Book Session',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.bold,
              color: AppPalette.navyPrimary,
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_session == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'Book Session',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.bold,
              color: AppPalette.navyPrimary,
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: const Center(child: Text('Session not found')),
      );
    }

    Map<String, dynamic>? coachData;
    final coachValue = _session!['coach'];
    if (coachValue is Map) {
      final m = Map<String, dynamic>.from(coachValue);
      // Merge coachProfile fields (profilePhoto, fullName) into the top-level map
      if (m['coachProfile'] is Map) {
        final profile = Map<String, dynamic>.from(m['coachProfile'] as Map);
        m['profilePhoto'] ??= profile['profilePhoto'];
        m['fullName'] ??= profile['fullName'];
      }
      coachData = m;
    }

    final sessionTitle = _session!['title'] ?? 'Session';
    final coachName = coachData?['fullName']?.toString() ??
        _session!['coachName']?.toString() ??
        'Coach';
    final location = _session!['location'] ?? 'TBA';

    final coachImage = coachData?['profilePhoto']?.toString() ??
        coachData?['profileImage']?.toString() ??
        coachData?['avatarUrl']?.toString() ??
        coachData?['profileUrl']?.toString() ??
        coachData?['profilePhotoUrl']?.toString() ??
        (coachData?['coachProfile'] is Map
            ? coachData!['coachProfile']['profilePhoto']?.toString()
            : null);

    final sessionImage = _session!['imageUrl']?.toString() ??
        _session!['coverImage']?.toString();

    final displayImage =
        coachImage ?? sessionImage ?? SessionUtils.getSessionImage(_session);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Book Session',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: Theme.of(context).iconTheme.color,
          ),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Coach/Service Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                ),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: displayImage.isNotEmpty
                        ? Image.network(
                            displayImage,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                _buildImagePlaceholder(),
                          )
                        : _buildImagePlaceholder(),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sessionTitle,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'with $coachName',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.color,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              size: 16,
                              color: AppPalette.warning,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '4.9 (120+ Sessions)',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn().slideY(begin: 0.1),

            const SizedBox(height: 32),

            // Select Date Header with Select All button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Select Dates',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                if (_availableDates.isNotEmpty)
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        if (_selectedDateIndices.length ==
                            _availableDates.length) {
                          // Deselect all
                          _selectedDateIndices.clear();
                        } else {
                          // Select all
                          _selectedDateIndices = Set.from(
                            List.generate(_availableDates.length, (i) => i),
                          );
                        }
                      });
                    },
                    icon: Icon(
                      _selectedDateIndices.length == _availableDates.length
                          ? Icons.check_box
                          : Icons.check_box_outline_blank,
                      size: 20,
                    ),
                    label: Text(
                      _selectedDateIndices.length == _availableDates.length
                          ? 'Deselect All'
                          : 'Select All',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _availableDates.isEmpty
                ? Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).dividerColor.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Text(
                      'No upcoming sessions available',
                      style: GoogleFonts.inter(
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                    ),
                  )
                : SizedBox(
                    height: 100,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _availableDates.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final date = _availableDates[index];
                        final isSelected = _selectedDateIndices.contains(index);
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                _selectedDateIndices.remove(index);
                              } else {
                                _selectedDateIndices.add(index);
                              }
                            });
                          },
                          child: AnimatedContainer(
                            duration: 300.ms,
                            width: 80,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppPalette.navyPrimary
                                  : Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? AppPalette.navyPrimary
                                    : Theme.of(context).dividerColor,
                                width: 2,
                              ),
                            ),
                            child: Stack(
                              children: [
                                // Checkbox indicator
                                Positioned(
                                  top: 6,
                                  right: 6,
                                  child: Icon(
                                    isSelected
                                        ? Icons.check_circle
                                        : Icons.circle_outlined,
                                    size: 20,
                                    color: isSelected
                                        ? Colors.white
                                        : Theme.of(context).dividerColor,
                                  ),
                                ),
                                // Date content
                                Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        DateFormat('EEE').format(date),
                                        style: GoogleFonts.inter(
                                          color: isSelected
                                              ? Colors.white70
                                              : Theme.of(
                                                  context,
                                                ).textTheme.bodyMedium?.color,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        DateFormat('d').format(date),
                                        style: GoogleFonts.inter(
                                          color: isSelected
                                              ? Colors.white
                                              : Theme.of(
                                                  context,
                                                ).colorScheme.onSurface,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 20,
                                        ),
                                      ),
                                      Text(
                                        DateFormat('MMM').format(date),
                                        style: GoogleFonts.inter(
                                          color: isSelected
                                              ? Colors.white70
                                              : Theme.of(
                                                  context,
                                                ).textTheme.bodyMedium?.color,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ).animate().fadeIn(delay: 200.ms),

            const SizedBox(height: 24),

            // Selected sessions summary
            if (_selectedDateIndices.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppPalette.orangeAccent.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppPalette.orangeAccent.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.event_available,
                        color: AppPalette.orangeAccent,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${_selectedDateIndices.length} session${_selectedDateIndices.length > 1 ? 's' : ''} selected',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    Text(
                      '${_session!['pricing']['currency'] ?? 'USD'} ${(_session!['pricing']['amount'] as num) * _selectedDateIndices.length}',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        color: AppPalette.orangeAccent,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(),

            const SizedBox(height: 40),

            // Bottom Action
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _selectedDateIndices.isEmpty
                    ? null
                    : () async {
                        final now = DateTime.now();
                        if (now.difference(_lastTap).inMilliseconds < 1500) return;
                        _lastTap = now;

                        // Get all selected dates
                        final selectedDates = _selectedDateIndices
                           .map((i) => _availableDates[i])
                           .toList()
                        ..sort();

                        // Detect if us user is a guardian based on the current route
                        final currentUri = GoRouterState.of(context).uri.toString();
                        final isGuardian = currentUri.startsWith('/guardian');
                        final confirmPath = isGuardian
                            ? '/guardian/confirm-booking'
                            : '/player/confirm-booking';

                        final dynamic localRouter = GoRouter.of(context);
                        await localRouter.push(
                          confirmPath,
                          extra: {
                            'sessionId': widget.sessionId,
                            'session': _session,
                            'selectedDates': selectedDates
                                .map((d) => d.toIso8601String())
                                .toList(),
                            'occurrenceDate':
                                selectedDates.first.toIso8601String(),
                            'date': _selectedDateIndices.length == 1
                                ? DateFormat(
                                    'EEE, MMM d',
                                  ).format(selectedDates.first)
                                : '${_selectedDateIndices.length} sessions',
                            'time': _selectedDateIndices.length == 1
                                ? DateFormat(
                                    'h:mm a',
                                  ).format(selectedDates.first)
                                : 'Multiple dates',
                            'coachName': coachName,
                            'location': location,
                            'coachImage': displayImage,
                            'currency': _session!['pricing']['currency'] ?? 'USD',
                            'totalAmount':
                                (_session!['pricing']['amount'] as num) *
                                    _selectedDateIndices.length,
                          },
                        );
                    },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppPalette.navyPrimary,
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  _selectedDateIndices.isEmpty
                      ? 'Select Dates to Continue'
                      : 'Book ${_selectedDateIndices.length} Session${_selectedDateIndices.length > 1 ? 's' : ''}',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      width: 80,
      height: 80,
      color: Colors.grey[300],
      child: Icon(
        Icons.broken_image,
        color: Colors.grey[600],
      ),
    );
  }
}
