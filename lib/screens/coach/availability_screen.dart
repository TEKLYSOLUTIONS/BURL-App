import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../widgets/notification_button.dart';
import '../../widgets/headers/coach_app_bar.dart';
import '../../config/palette.dart';
import '../../widgets/app_time_picker.dart';
import '../../services/coach_service.dart';

class CoachAvailabilityScreen extends StatefulWidget {
  const CoachAvailabilityScreen({super.key});

  @override
  State<CoachAvailabilityScreen> createState() =>
      _CoachAvailabilityScreenState();
}

class TimeInterval {
  String start;
  String end;
  TimeInterval({required this.start, required this.end});
  
  Map<String, dynamic> toJson() => {
    'start': start,
    'end': end,
  };
}

class BlockedDate {
  final String? id;
  final String title;
  final DateTime start;
  final DateTime end;
  final Color color;
  final IconData icon;

  BlockedDate({
    this.id,
    required this.title,
    required this.start,
    required this.end,
    required this.color,
    required this.icon,
  });
  
  Map<String, dynamic> toJson() => {
    'title': title,
    'startDate': start.toIso8601String(),
    'endDate': end.toIso8601String(),
    'icon': _iconToString(icon),
    'color': _colorToString(color),
  };
  
  String _iconToString(IconData icon) {
    if (icon == Icons.flight_takeoff) return 'flight';
    if (icon == Icons.calendar_today) return 'calendar';
    if (icon == Icons.block) return 'block';
    return 'block';
  }
  
  String _colorToString(Color color) {
    if (color == Colors.orange) return 'orange';
    if (color == Colors.blueGrey) return 'blueGrey';
    if (color == Colors.redAccent) return 'red';
    return 'red';
  }
}

class _CoachAvailabilityScreenState extends State<CoachAvailabilityScreen> {
  bool _isLoading = true;
  bool _isSaving = false;

  // recurring schedule
  final List<String> _weekDays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  final List<String> _fullDayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  
  // Currently selected day index (0=Monday, 1=Tuesday, etc.)
  int _selectedDayIndex = 0;
  
  // Store time intervals for each day (7 days)
  final Map<int, List<TimeInterval>> _daySchedules = {
    0: [TimeInterval(start: '09:00 AM', end: '05:00 PM')], // Monday
    1: [TimeInterval(start: '09:00 AM', end: '05:00 PM')], // Tuesday
    2: [TimeInterval(start: '09:00 AM', end: '05:00 PM')], // Wednesday
    3: [TimeInterval(start: '09:00 AM', end: '05:00 PM')], // Thursday
    4: [TimeInterval(start: '09:00 AM', end: '05:00 PM')], // Friday
    5: [], // Saturday - empty by default
    6: [], // Sunday - empty by default
  };

  // blocked dates
  final CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay = DateTime.now();

  // Dynamic blocked dates list
  List<BlockedDate> _blockedDates = [];

  @override
  void initState() {
    super.initState();
    _loadAvailability();
  }

  Future<void> _loadAvailability() async {
    setState(() => _isLoading = true);

    try {
      final data = await CoachService.getCoachAvailability();
      
      // Debug: print the response
      debugPrint('Availability data: $data');
      
      // Parse recurring schedule with null safety
      if (data.containsKey('recurringSchedule') && data['recurringSchedule'] != null) {
        final recurringSchedule = data['recurringSchedule'] as Map<String, dynamic>;
        
        // Parse day-specific schedules
        if (recurringSchedule.containsKey('daySchedules') && recurringSchedule['daySchedules'] is Map) {
          final daySchedules = recurringSchedule['daySchedules'] as Map<String, dynamic>;
          
          // Load schedule for each day
          for (int i = 0; i < 7; i++) {
            final dayKey = i.toString();
            if (daySchedules.containsKey(dayKey) && daySchedules[dayKey] is List) {
              final intervals = daySchedules[dayKey] as List;
              _daySchedules[i] = intervals.map((ti) {
                if (ti is Map) {
                  return TimeInterval(
                    start: ti['start']?.toString() ?? '09:00 AM',
                    end: ti['end']?.toString() ?? '05:00 PM',
                  );
                }
                return TimeInterval(start: '09:00 AM', end: '05:00 PM');
              }).toList();
            }
          }
        } else if (recurringSchedule.containsKey('timeIntervals')) {
          // Backward compatibility: if old format, apply to Monday-Friday
          final timeIntervals = recurringSchedule['timeIntervals'];
          if (timeIntervals is List && timeIntervals.isNotEmpty) {
            final intervals = timeIntervals.map((ti) {
              if (ti is Map) {
                return TimeInterval(
                  start: ti['start']?.toString() ?? '09:00 AM',
                  end: ti['end']?.toString() ?? '05:00 PM',
                );
              }
              return TimeInterval(start: '09:00 AM', end: '05:00 PM');
            }).toList();
            
            // Apply to Monday-Friday (indices 0-4)
            for (int i = 0; i < 5; i++) {
              _daySchedules[i] = intervals.map((ti) => TimeInterval(start: ti.start, end: ti.end)).toList();
            }
          }
        }
      }

      // Parse blocked dates with null safety
      if (data.containsKey('blockedDates') && data['blockedDates'] != null) {
        final blockedDates = data['blockedDates'];
        if (blockedDates is List) {
          _blockedDates = blockedDates.map((bd) {
            if (bd is Map) {
              return BlockedDate(
                id: bd['_id']?.toString(),
                title: bd['title']?.toString() ?? 'Blocked',
                start: DateTime.parse(bd['startDate']?.toString() ?? DateTime.now().toIso8601String()),
                end: DateTime.parse(bd['endDate']?.toString() ?? DateTime.now().toIso8601String()),
                color: _parseColor(bd['color']?.toString()),
                icon: _parseIcon(bd['icon']?.toString()),
              );
            }
            return BlockedDate(
              title: 'Blocked',
              start: DateTime.now(),
              end: DateTime.now(),
              color: Colors.red,
              icon: Icons.block,
            );
          }).toList();
        }
      }

      setState(() => _isLoading = false);
    } catch (e, stackTrace) {
      debugPrint('Error loading availability: $e');
      debugPrint('Stack trace: $stackTrace');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load availability: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Color _parseColor(String? colorStr) {
    switch (colorStr) {
      case 'orange': return Colors.orange;
      case 'blueGrey': return Colors.blueGrey;
      case 'red': return Colors.redAccent;
      default: return Colors.redAccent;
    }
  }

  IconData _parseIcon(String? iconStr) {
    switch (iconStr) {
      case 'flight': return Icons.flight_takeoff;
      case 'calendar': return Icons.calendar_today;
      case 'block': return Icons.block;
      default: return Icons.block;
    }
  }

  Future<void> _saveAvailability() async {
    setState(() => _isSaving = true);

    try {
      // Convert day schedules to API format
      final daySchedulesData = <String, dynamic>{};
      for (int i = 0; i < 7; i++) {
        daySchedulesData[i.toString()] = _daySchedules[i]!.map((ti) => ti.toJson()).toList();
      }

      final availabilityData = {
        'recurringSchedule': {
          'daySchedules': daySchedulesData,
        },
        'blockedDates': _blockedDates.map((bd) => {
          if (bd.id != null) '_id': bd.id,
          'title': bd.title,
          'startDate': bd.start.toIso8601String(),
          'endDate': bd.end.toIso8601String(),
          'icon': bd._iconToString(bd.icon),
          'color': bd._colorToString(bd.color),
        }).toList(),
      };

      debugPrint('Saving availability data: $availabilityData');
      
      await CoachService.updateCoachAvailability(availabilityData);

      setState(() => _isSaving = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Availability saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save availability: $e'),
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
        backgroundColor: Colors.grey[50],
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50], // Light grey background
      body: Column(
        children: [
          CoachAppBar(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 40), // Balance the icon size
                Expanded(
                  child: Text(
                    'Manage Availability',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 24, // Consistent size
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Recurring Schedule Section
                  Text(
                    'Recurring Schedule',
                    style: GoogleFonts.outfit(
                      color: AppPalette.navyPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap days to edit specific working hours.',
                    style: GoogleFonts.inter(
                      color: Colors.grey[500],
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Day Selector (Single Selection)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(_weekDays.length, (index) {
                            final isSelected = _selectedDayIndex == index;
                            final hasSchedule = _daySchedules[index]!.isNotEmpty;
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedDayIndex = index;
                                });
                              },
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppPalette.orangeAccent
                                      : hasSchedule
                                          ? AppPalette.orangeAccent.withValues(alpha: 0.2)
                                          : Colors.grey[100],
                                  shape: BoxShape.circle,
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: AppPalette.orangeAccent
                                                .withValues(alpha: 0.4),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          ),
                                        ]
                                      : [],
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  _weekDays[index],
                                  style: GoogleFonts.inter(
                                    color: isSelected
                                        ? Colors.white
                                        : hasSchedule
                                            ? AppPalette.orangeAccent
                                            : Colors.grey[400],
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 16),

                        // Selected Day Label
                        Text(
                          _fullDayNames[_selectedDayIndex],
                          style: GoogleFonts.outfit(
                            color: AppPalette.navyPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Time Intervals for Selected Day
                        if (_daySchedules[_selectedDayIndex]!.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[200]!),
                            ),
                            child: Text(
                              'No schedule set for this day',
                              style: GoogleFonts.inter(
                                color: Colors.grey[500],
                                fontSize: 13,
                              ),
                            ),
                          )
                        else
                          ...List.generate(_daySchedules[_selectedDayIndex]!.length, (index) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              if (index == 0) ...[
                                                Text(
                                                  'START',
                                                  style: GoogleFonts.inter(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color:
                                                        AppPalette.orangeAccent,
                                                    letterSpacing: 1,
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                              ],
                                              _buildTimeDropdown(
                                                _daySchedules[_selectedDayIndex]![index].start,
                                                (val) {
                                                  setState(() {
                                                    _daySchedules[_selectedDayIndex]![index].start = val;
                                                    // Validate: Ensure End is after Start
                                                    final startMinutes =
                                                        _minutesFromTime(
                                                          _parseTime(val),
                                                        );
                                                    final endMinutes =
                                                        _minutesFromTime(
                                                          _parseTime(
                                                            _daySchedules[_selectedDayIndex]![index].end,
                                                          ),
                                                        );

                                                    if (startMinutes >=
                                                        endMinutes) {
                                                      // Auto-adjust end time to start + 1 hour
                                                      final newEndMinutes =
                                                          startMinutes + 60;
                                                      // Handle wrap around (24 hours) - simplified for day schedule
                                                      final adjustedEnd =
                                                          newEndMinutes >= 1440
                                                          ? 1439
                                                          : newEndMinutes;
                                                      _daySchedules[_selectedDayIndex]![index].end =
                                                          _formatTime(
                                                            _timeFromMinutes(
                                                              adjustedEnd,
                                                            ),
                                                          );
                                                    }
                                                  });
                                                },
                                              ),
                                            ],
                                          ),
                                      ),
                                      const SizedBox(width: 12),
                                      Padding(
                                        padding: EdgeInsets.only(
                                          top: index == 0 ? 24.0 : 0.0,
                                        ),
                                        child: Text(
                                          '-',
                                          style: GoogleFonts.outfit(
                                            fontSize: 20,
                                            color: Colors.grey[300],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            if (index == 0) ...[
                                              Text(
                                                'END',
                                                style: GoogleFonts.inter(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color:
                                                      AppPalette.orangeAccent,
                                                  letterSpacing: 1,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                            ],
                                            _buildTimeDropdown(
                                              _daySchedules[_selectedDayIndex]![index].end,
                                              (val) {
                                                // Validate: Ensure End is after Start
                                                final newEndMinutes =
                                                    _minutesFromTime(
                                                      _parseTime(val),
                                                    );
                                                final startMinutes =
                                                    _minutesFromTime(
                                                      _parseTime(
                                                        _daySchedules[_selectedDayIndex]![index].start,
                                                      ),
                                                    );

                                                if (newEndMinutes <=
                                                    startMinutes) {
                                                  // Invalid selection
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                        "End time must be after start time",
                                                      ),
                                                      backgroundColor:
                                                          Colors.red,
                                                    ),
                                                  );
                                                } else {
                                                  setState(() {
                                                    _daySchedules[_selectedDayIndex]![index].end = val;
                                                  });
                                                }
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Delete Button
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 12.0),
                                  child: InkWell(
                                    onTap: () {
                                      if (_daySchedules[_selectedDayIndex]!.length > 1) {
                                        setState(() {
                                          _daySchedules[_selectedDayIndex]!.removeAt(index);
                                        });
                                      } else {
                                        // If it's the last interval, remove it to clear the day
                                        setState(() {
                                          _daySchedules[_selectedDayIndex] = [];
                                        });
                                      }
                                    },
                                    child: Icon(
                                      Icons.delete_outline,
                                      color: Colors.red[300],
                                      size: 24,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),

                        const SizedBox(height: 16),

                        // Add Interval Button (only show if day has schedule)
                        if (_daySchedules[_selectedDayIndex]!.isNotEmpty)
                          InkWell(
                            onTap: () {
                              setState(() {
                                _daySchedules[_selectedDayIndex]!.add(
                                  TimeInterval(
                                    start: '09:00 AM',
                                    end: '05:00 PM',
                                  ),
                                );
                              });
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.add,
                                  color: AppPalette.orangeAccent,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Add Interval',
                                  style: GoogleFonts.inter(
                                    color: AppPalette.orangeAccent,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Add Schedule Button (only show if day has no schedule)
                        if (_daySchedules[_selectedDayIndex]!.isEmpty)
                          InkWell(
                            onTap: () {
                              setState(() {
                                _daySchedules[_selectedDayIndex] = [
                                  TimeInterval(
                                    start: '09:00 AM',
                                    end: '05:00 PM',
                                  ),
                                ];
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: AppPalette.orangeAccent.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppPalette.orangeAccent,
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.add,
                                    color: AppPalette.orangeAccent,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Add Schedule for ${_fullDayNames[_selectedDayIndex]}',
                                    style: GoogleFonts.inter(
                                      color: AppPalette.orangeAccent,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        const SizedBox(height: 24),
                        
                        // Copy to All Weekdays Button
                        if (_daySchedules[_selectedDayIndex]!.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  // Copy current day's schedule to Monday-Friday (0-4)
                                  final currentSchedule = _daySchedules[_selectedDayIndex]!
                                      .map((ti) => TimeInterval(start: ti.start, end: ti.end))
                                      .toList();
                                  for (int i = 0; i < 5; i++) {
                                    _daySchedules[i] = currentSchedule
                                        .map((ti) => TimeInterval(start: ti.start, end: ti.end))
                                        .toList();
                                  }
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Schedule copied to all weekdays (Mon-Fri)'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.copy_all,
                                    color: AppPalette.orangeAccent,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Copy to all weekdays',
                                    style: GoogleFonts.inter(
                                      color: AppPalette.orangeAccent,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        
                        // Save Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _saveAvailability,
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
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    'Save Schedule',
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Blocked Dates Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Blocked Dates',
                            style: GoogleFonts.outfit(
                              color: AppPalette.navyPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Manage time off and holidays.',
                            style: GoogleFonts.inter(
                              color: Colors.grey[500],
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppPalette.orangeAccent.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.add,
                            color: AppPalette.orangeAccent,
                          ),
                          onPressed: () => _showAddBlockedDateDialog(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
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
                    child: TableCalendar(
                      firstDay: DateTime.utc(2020, 10, 16),
                      lastDay: DateTime.utc(2030, 3, 14),
                      focusedDay: _focusedDay,
                      calendarFormat: _calendarFormat,
                      availableGestures: AvailableGestures.horizontalSwipe,
                      selectedDayPredicate: (day) {
                        return isSameDay(_selectedDay, day);
                      },
                      onDaySelected: (selectedDay, focusedDay) {
                        setState(() {
                          _selectedDay = selectedDay;
                          _focusedDay = focusedDay;
                        });
                      },
                      headerStyle: HeaderStyle(
                        titleCentered: true,
                        formatButtonVisible: false,
                        titleTextStyle: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppPalette.navyPrimary,
                        ),
                        leftChevronIcon: const Icon(
                          Icons.chevron_left,
                          color: AppPalette.navyPrimary,
                        ),
                        rightChevronIcon: const Icon(
                          Icons.chevron_right,
                          color: AppPalette.navyPrimary,
                        ),
                      ),
                      calendarStyle: CalendarStyle(
                        outsideDaysVisible: false,
                        defaultTextStyle: GoogleFonts.inter(
                          fontWeight: FontWeight.w500,
                        ),
                        weekendTextStyle: GoogleFonts.inter(
                          fontWeight: FontWeight.w500,
                        ),
                        todayDecoration: BoxDecoration(
                          color: AppPalette.orangeAccent.withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                        ),
                        selectedDecoration: const BoxDecoration(
                          color: AppPalette.orangeAccent,
                          shape: BoxShape.circle,
                        ),
                        markerDecoration: const BoxDecoration(
                          color: AppPalette.navyPrimary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      eventLoader: (day) {
                        return _blockedDates.where((blocked) {
                          return isSameDay(blocked.start, day) ||
                              isSameDay(blocked.end, day) ||
                              (day.isAfter(blocked.start) &&
                                  day.isBefore(blocked.end));
                        }).toList();
                      },
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Dynamic Blocked List
                  ..._blockedDates.map((blockedDate) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: _buildBlockedItem(
                        blockedDate: blockedDate,
                        onDelete: () async {
                          if (blockedDate.id != null) {
                            final scaffoldMessenger = ScaffoldMessenger.of(context);
                            try {
                              await CoachService.removeBlockedDate(blockedDate.id!);
                              setState(() {
                                _blockedDates.remove(blockedDate);
                              });
                              if (mounted) {
                                scaffoldMessenger.showSnackBar(
                                  const SnackBar(
                                    content: Text('Blocked date removed'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                scaffoldMessenger.showSnackBar(
                                  SnackBar(
                                    content: Text('Failed to remove: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          } else {
                            setState(() {
                              _blockedDates.remove(blockedDate);
                            });
                          }
                        },
                      ),
                    );
                  }),
                  
                  const SizedBox(height: 100), // Spacing for Floating Tab Bar
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddBlockedDateDialog() {
    final TextEditingController titleController = TextEditingController();
    DateTime startDate = _selectedDay ?? DateTime.now();
    DateTime endDate = _selectedDay ?? DateTime.now();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.white,
              elevation: 4, // Consistent elevation
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ), // M3 radius
              child: Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add Blocked Date',
                      style: GoogleFonts.outfit(
                        fontSize: 24, // Larger M3 title
                        color: AppPalette.navyPrimary,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Reason Input
                    TextField(
                      controller: titleController,
                      style: GoogleFonts.inter(
                        color: AppPalette.navyPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Reason',
                        labelStyle: GoogleFonts.inter(color: Colors.grey[600]),
                        hintText: 'e.g. Vacation',
                        hintStyle: GoogleFonts.inter(color: Colors.grey[400]),
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Separate Date Pickers
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: startDate,
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(
                                  const Duration(days: 365),
                                ),
                                builder: (context, child) {
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      colorScheme: const ColorScheme.light(
                                        primary: AppPalette.navyPrimary,
                                        onPrimary: Colors.white,
                                        onSurface: AppPalette.navyPrimary,
                                      ),
                                      textButtonTheme: TextButtonThemeData(
                                        style: TextButton.styleFrom(
                                          foregroundColor:
                                              AppPalette.orangeAccent,
                                        ),
                                      ),
                                    ),
                                    child: child!,
                                  );
                                },
                              );
                              if (picked != null) {
                                setDialogState(() {
                                  startDate = picked;
                                  if (endDate.isBefore(startDate)) {
                                    endDate = startDate;
                                  }
                                });
                              }
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'START',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppPalette.navyPrimary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                    horizontal: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppPalette.navyPrimary,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: Text(
                                      "${startDate.day}/${startDate.month}",
                                      style: GoogleFonts.inter(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: endDate,
                                firstDate: startDate,
                                lastDate: DateTime.now().add(
                                  const Duration(days: 365),
                                ),
                                builder: (context, child) {
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      colorScheme: const ColorScheme.light(
                                        primary: AppPalette.navyPrimary,
                                        onPrimary: Colors.white,
                                        onSurface: AppPalette.navyPrimary,
                                      ),
                                      textButtonTheme: TextButtonThemeData(
                                        style: TextButton.styleFrom(
                                          foregroundColor:
                                              AppPalette.orangeAccent,
                                        ),
                                      ),
                                    ),
                                    child: child!,
                                  );
                                },
                              );
                              if (picked != null) {
                                setDialogState(() {
                                  endDate = picked;
                                });
                              }
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'END',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppPalette.navyPrimary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                    horizontal: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors
                                        .grey[200], // M3 surface container high?
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: Text(
                                      "${endDate.day}/${endDate.month}",
                                      style: GoogleFonts.inter(
                                        color: AppPalette
                                            .navyPrimary, // Text color
                                        fontSize: 20,
                                        fontWeight: FontWeight.w600,
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

                    const SizedBox(height: 32),

                    // Actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            foregroundColor: AppPalette.orangeAccent,
                          ),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () async {
                            if (titleController.text.isNotEmpty) {
                              // Extract these before async operations
                              final navigator = Navigator.of(context);
                              final scaffoldMessenger = ScaffoldMessenger.of(context);
                              
                              try {
                                // Save to backend first
                                final newBlockedDate = BlockedDate(
                                  title: titleController.text,
                                  start: startDate,
                                  end: endDate,
                                  color: Colors.redAccent,
                                  icon: Icons.block,
                                );
                                
                                final savedData = await CoachService.addBlockedDate(
                                  newBlockedDate.toJson(),
                                );
                                
                                setState(() {
                                  _blockedDates.add(
                                    BlockedDate(
                                      id: savedData['_id'],
                                      title: titleController.text,
                                      start: startDate,
                                      end: endDate,
                                      color: Colors.redAccent,
                                      icon: Icons.block,
                                    ),
                                  );
                                });
                                
                                navigator.pop();
                                
                                if (mounted) {
                                  scaffoldMessenger.showSnackBar(
                                    const SnackBar(
                                      content: Text('Blocked date added'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              } catch (e) {
                                navigator.pop();
                                if (mounted) {
                                  scaffoldMessenger.showSnackBar(
                                    SnackBar(
                                      content: Text('Failed to add: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            }
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: AppPalette.orangeAccent,
                          ),
                          child: Text(
                            'OK',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTimeDropdown(String value, Function(String) onChanged) {
    return InkWell(
      onTap: () async {
        TimeOfDay initialTime = TimeOfDay.now();
        try {
          final parts = value.split(' ');
          final timeParts = parts[0].split(':');
          int hour = int.parse(timeParts[0]);
          int minute = int.parse(timeParts[1]);
          if (parts[1] == 'PM' && hour != 12) hour += 12;
          if (parts[1] == 'AM' && hour == 12) hour = 0;
          initialTime = TimeOfDay(hour: hour, minute: minute);
        } catch (_) {}

        final TimeOfDay? picked = await AppTimePicker.show(
          context,
          initialTime: initialTime,
        );

        if (picked != null) {
          final hour = picked.hourOfPeriod == 0 ? 12 : picked.hourOfPeriod;
          final minute = picked.minute.toString().padLeft(2, '0');
          final period = picked.period == DayPeriod.am ? 'AM' : 'PM';
          onChanged('${hour.toString().padLeft(2, '0')}:$minute $period');
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey[50], // Very light background
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              value,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: AppPalette.navyPrimary,
                fontSize: 14,
              ),
            ),
            Icon(Icons.keyboard_arrow_down, color: Colors.orange, size: 20),
          ],
        ),
      ),
    );
  }

  TimeOfDay _parseTime(String timeString) {
    final parts = timeString.split(' ');
    final timeParts = parts[0].split(':');
    int hour = int.parse(timeParts[0]);
    final int minute = int.parse(timeParts[1]);
    final isPm = parts[1] == 'PM';

    if (isPm && hour != 12) hour += 12;
    if (!isPm && hour == 12) hour = 0;

    return TimeOfDay(hour: hour, minute: minute);
  }

  int _minutesFromTime(TimeOfDay time) {
    return time.hour * 60 + time.minute;
  }

  TimeOfDay _timeFromMinutes(int minutes) {
    final hour = (minutes ~/ 60) % 24;
    final minute = minutes % 60;
    return TimeOfDay(hour: hour, minute: minute);
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return "$hour:$minute $period";
  }

  Widget _buildBlockedItem({
    required BlockedDate blockedDate,
    required VoidCallback onDelete,
  }) {
    // Format date string
    String dateStr = "";
    if (isSameDay(blockedDate.start, blockedDate.end)) {
      dateStr = "${blockedDate.start.day}/${blockedDate.start.month}";
    } else {
      dateStr =
          "${blockedDate.start.day}/${blockedDate.start.month} - ${blockedDate.end.day}/${blockedDate.end.month}";
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: blockedDate.color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(blockedDate.icon, color: blockedDate.color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  blockedDate.title,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    color: AppPalette.navyPrimary,
                    fontSize: 16,
                  ),
                ),
                Text(
                  dateStr,
                  style: GoogleFonts.inter(
                    color: Colors.grey[500],
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.delete, color: Colors.orange, size: 18),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
