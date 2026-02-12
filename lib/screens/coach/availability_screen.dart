import 'package:flutter/material.dart';
import '../../config/palette.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../widgets/notification_button.dart';
import '../../widgets/headers/coach_app_bar.dart';

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

  Map<String, dynamic> toJson() => {'start': start, 'end': end};

  // Helper to get minutes from "HH:MM AM/PM"
  int get startMinutes => _toMinutes(start);
  int get endMinutes => _toMinutes(end);

  static int _toMinutes(String timeStr) {
    try {
      // timeStr format: "09:00 AM"
      final parts = timeStr.split(' ');
      final timeParts = parts[0].split(':');
      int hour = int.parse(timeParts[0]);
      int minute = int.parse(timeParts[1]);
      final period = parts[1];

      if (period == 'PM' && hour != 12) hour += 12;
      if (period == 'AM' && hour == 12) hour = 0;

      return hour * 60 + minute;
    } catch (e) {
      return 0;
    }
  }
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
  final List<String> _fullDayNames = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

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
      if (data.containsKey('recurringSchedule') &&
          data['recurringSchedule'] != null) {
        final recurringSchedule =
            data['recurringSchedule'] as Map<String, dynamic>;

        // Parse day-specific schedules
        if (recurringSchedule.containsKey('daySchedules') &&
            recurringSchedule['daySchedules'] is Map) {
          final daySchedules =
              recurringSchedule['daySchedules'] as Map<String, dynamic>;

          // Load schedule for each day
          for (int i = 0; i < 7; i++) {
            final dayKey = i.toString();
            if (daySchedules.containsKey(dayKey) &&
                daySchedules[dayKey] is List) {
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
              _daySchedules[i] = intervals
                  .map((ti) => TimeInterval(start: ti.start, end: ti.end))
                  .toList();
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
                start: DateTime.parse(
                  bd['startDate']?.toString() ??
                      DateTime.now().toIso8601String(),
                ),
                end: DateTime.parse(
                  bd['endDate']?.toString() ?? DateTime.now().toIso8601String(),
                ),
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
      case 'orange':
        return Colors.orange;
      case 'blueGrey':
        return Colors.blueGrey;
      case 'red':
        return Colors.redAccent;
      default:
        return Colors.redAccent;
    }
  }

  IconData _parseIcon(String? iconStr) {
    switch (iconStr) {
      case 'flight':
        return Icons.flight_takeoff;
      case 'calendar':
        return Icons.calendar_today;
      case 'block':
        return Icons.block;
      default:
        return Icons.block;
    }
  }

  // ... (keeping existing imports and class definitions)

  Future<void> _saveAvailability() async {
    setState(() => _isSaving = true);

    try {
      // Convert day schedules to API format
      final daySchedulesData = <String, dynamic>{};
      for (int i = 0; i < 7; i++) {
        daySchedulesData[i.toString()] = _daySchedules[i]!
            .map((ti) => ti.toJson())
            .toList();
      }

      final availabilityData = {
        'recurringSchedule': {'daySchedules': daySchedulesData},
        // 'blockedDates': ... // Blocked dates removed from UI, so we don't update them or keep existing?
        // If we don't send blockedDates, backend might keep existing ones or clear them?
        // Validating backend behavior: usually updates are patches or full replacements.
        // If full replacement, we must send existing blocked dates.
        'blockedDates': _blockedDates
            .map(
              (bd) => {
                if (bd.id != null) '_id': bd.id,
                'title': bd.title,
                'startDate': bd.start.toIso8601String(),
                'endDate': bd.end.toIso8601String(),
                'icon': bd._iconToString(bd.icon),
                'color': bd._colorToString(bd.color),
              },
            )
            .toList(),
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

  void _showDayScheduleDialog(DateTime date) {
    // Get the weekday index (0=Monday, 6=Sunday) from DateTime (1=Mon, 7=Sun)
    final weekdayIndex = date.weekday - 1;
    final dayName = _fullDayNames[weekdayIndex];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Theme.of(context).cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Edit Schedule for $dayName',
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This will update your recurring availability for all ${dayName}s.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // List Intervals
                    if (_daySchedules[weekdayIndex]!.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Text(
                            "No slots available",
                            style: GoogleFonts.inter(
                              color: Theme.of(context).disabledColor,
                            ),
                          ),
                        ),
                      )
                    else
                      ...List.generate(_daySchedules[weekdayIndex]!.length, (
                        index,
                      ) {
                        final interval = _daySchedules[weekdayIndex]![index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildTimeDropdown(interval.start, (
                                  val,
                                ) {
                                  final startMinutes = _minutesFromTime(
                                    _parseTime(val),
                                  );
                                  final endMinutes = _minutesFromTime(
                                    _parseTime(interval.end),
                                  );

                                  // Validate End > Start
                                  if (startMinutes >= endMinutes) {
                                    // Auto-adjust end time (add 1 hour)
                                    final newEnd = _formatTime(
                                      _timeFromMinutes(startMinutes + 60),
                                    );
                                    setDialogState(() {
                                      interval.start = val;
                                      interval.end = newEnd;
                                    });
                                  } else {
                                    setDialogState(() {
                                      interval.start = val;
                                    });
                                  }
                                  setState(() {}); // Update main widget
                                }),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                child: const Icon(
                                  Icons.arrow_right_alt,
                                  size: 16,
                                  color: Colors.grey,
                                ),
                              ),
                              Expanded(
                                child: _buildTimeDropdown(interval.end, (val) {
                                  final startMinutes = _minutesFromTime(
                                    _parseTime(interval.start),
                                  );
                                  final endMinutes = _minutesFromTime(
                                    _parseTime(val),
                                  );

                                  if (endMinutes <= startMinutes) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'End time must be after start time',
                                          ),
                                        ),
                                      );
                                    }
                                    return;
                                  }
                                  setDialogState(() {
                                    interval.end = val;
                                  });
                                  setState(() {});
                                }),
                              ),
                            ],
                          ),
                        );
                      }),

                    const SizedBox(height: 16),

                    // Add Button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          setDialogState(() {
                            _daySchedules[weekdayIndex]!.add(
                              TimeInterval(start: '09:00 AM', end: '05:00 PM'),
                            );
                          });
                          setState(() {});
                        },
                        icon: const Icon(Icons.add),
                        label: const Text("Add Time Slot"),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Done"),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _saveAvailability();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppPalette.navyPrimary,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text("Save Changes"),
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          CoachAppBar(
            backgroundColor: AppPalette.navyPrimary, // Unified Header Color
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
                      color: Colors.white, // Always white on navy
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
                  // Calendar Section (Moved to Top)
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(
                            context,
                          ).shadowColor.withValues(alpha: 0.05),
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
                      availableGestures: AvailableGestures.all,
                      selectedDayPredicate: (day) {
                        return isSameDay(_selectedDay, day);
                      },
                      onDaySelected: (selectedDay, focusedDay) {
                        debugPrint('Day Selected: $selectedDay');
                        setState(() {
                          _selectedDay = selectedDay;
                          _focusedDay = focusedDay;
                        });
                        _showDayScheduleDialog(selectedDay);
                      },
                      headerStyle: HeaderStyle(
                        titleCentered: true,
                        formatButtonVisible: false,
                        titleTextStyle: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        leftChevronIcon: Icon(
                          Icons.chevron_left,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        rightChevronIcon: Icon(
                          Icons.chevron_right,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      calendarStyle: CalendarStyle(
                        outsideDaysVisible: false,
                        defaultTextStyle: GoogleFonts.inter(
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        weekendTextStyle: GoogleFonts.inter(
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        todayDecoration: BoxDecoration(
                          color: AppPalette.navyPrimary.withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                        ),
                        selectedDecoration: const BoxDecoration(
                          color: AppPalette.navyPrimary,
                          shape: BoxShape.circle,
                        ),
                        markerDecoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.error,
                          shape: BoxShape.circle,
                        ),
                      ),
                      // Removed eventLoader for blocked dates since we removed the Block Date UI
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Recurring Schedule Section
                  Text(
                    'Weekly Schedule',
                    style: GoogleFonts.outfit(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Set your standard weekly availability.',
                    style: GoogleFonts.inter(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.6),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(
                            context,
                          ).shadowColor.withValues(alpha: 0.03),
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
                            final hasSchedule =
                                _daySchedules[index]!.isNotEmpty;
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
                                      ? AppPalette.navyPrimary
                                      : hasSchedule
                                      ? AppPalette.navyPrimary.withValues(
                                          alpha: 0.2,
                                        )
                                      : Theme.of(
                                          context,
                                        ).colorScheme.surfaceContainerHighest,
                                  shape: BoxShape.circle,
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: AppPalette.navyPrimary
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
                                        ? AppPalette.navyPrimary
                                        : Theme.of(context).disabledColor,
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
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Timeslot Editor (Embedded)
                        if (_daySchedules[_selectedDayIndex]!.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest
                                  .withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Theme.of(
                                  context,
                                ).dividerColor.withValues(alpha: 0.5),
                              ),
                            ),
                            child: Text(
                              'No schedule set for this day',
                              style: GoogleFonts.inter(
                                color: Theme.of(context).disabledColor,
                                fontSize: 13,
                              ),
                            ),
                          )
                        else
                          ...List.generate(_daySchedules[_selectedDayIndex]!.length, (
                            index,
                          ) {
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
                                                        AppPalette.navyPrimary,
                                                    letterSpacing: 1,
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                              ],
                                              _buildTimeDropdown(
                                                _daySchedules[_selectedDayIndex]![index]
                                                    .start,
                                                (val) {
                                                  setState(() {
                                                    _daySchedules[_selectedDayIndex]![index]
                                                            .start =
                                                        val;
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
                                              color: Theme.of(
                                                context,
                                              ).disabledColor,
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
                                                        AppPalette.navyPrimary,
                                                    letterSpacing: 1,
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                              ],
                                              _buildTimeDropdown(
                                                _daySchedules[_selectedDayIndex]![index]
                                                    .end,
                                                (val) {
                                                  setState(() {
                                                    _daySchedules[_selectedDayIndex]![index]
                                                            .end =
                                                        val;
                                                  });
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.red,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _daySchedules[_selectedDayIndex]!
                                            .removeAt(index);
                                      });
                                    },
                                  ),
                                ],
                              ),
                            );
                          }),

                        const SizedBox(height: 16),

                        // Add Interval Button
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
                                color: AppPalette.secondary,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Add Interval',
                                style: GoogleFonts.inter(
                                  color: AppPalette.secondary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Copy Weekdays
                        InkWell(
                          onTap: () {
                            setState(() {
                              final current = _daySchedules[_selectedDayIndex]!
                                  .map(
                                    (ti) => TimeInterval(
                                      start: ti.start,
                                      end: ti.end,
                                    ),
                                  )
                                  .toList();
                              for (int i = 0; i < 5; i++) {
                                _daySchedules[i] = current
                                    .map(
                                      (ti) => TimeInterval(
                                        start: ti.start,
                                        end: ti.end,
                                      ),
                                    )
                                    .toList();
                              }
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Copied to Mon-Fri'),
                              ),
                            );
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.copy_all,
                                color: AppPalette.secondary,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Copy to all weekdays',
                                style: GoogleFonts.inter(
                                  color: AppPalette.secondary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _saveAvailability,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppPalette.secondary,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isSaving
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : const Text(
                                    "Save Schedule",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Blocked Dates Section REMOVED
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Helper Methods ---

  Widget _buildTimeDropdown(String value, Function(String) onChanged) {
    return InkWell(
      onTap: () async {
        TimeOfDay initialTime = TimeOfDay.now();
        try {
          initialTime = _parseTime(value);
        } catch (_) {}

        final TimeOfDay? picked = await AppTimePicker.show(
          context,
          initialTime: initialTime,
        );

        if (picked != null) {
          onChanged(_formatTime(picked));
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(
            context,
          ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              value,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 14,
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down,
              color: Theme.of(context).colorScheme.secondary,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  TimeOfDay _parseTime(String timeString) {
    try {
      final parts = timeString.split(' ');
      final timeParts = parts[0].split(':');
      int hour = int.parse(timeParts[0]);
      final int minute = int.parse(timeParts[1]);
      final isPm = parts[1] == 'PM';

      if (isPm && hour != 12) hour += 12;
      if (!isPm && hour == 12) hour = 0;

      return TimeOfDay(hour: hour, minute: minute);
    } catch (e) {
      return TimeOfDay.now();
    }
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
}
