import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../config/palette.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../widgets/notification_button.dart';
import '../../widgets/headers/coach_app_bar.dart';

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

  final List<String> _fullDayNames = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

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
  // Initialize to today so the override editor is always visible at startup
  DateTime? _selectedDay = DateTime.now();

  // 0 = Sunday, 1 = Monday, ... 6 = Saturday
  int _selectedDayIndex = 0;

  // Helper to map UI Index (0=Sun) to Data Index (0=Mon)
  int _getDataIndex(int uiIndex) {
    if (uiIndex == 0) return 6; // Sunday -> 6
    return uiIndex - 1; // 1->0, 2->1 ...
  }

  String _getDayName(int uiIndex) {
    // _fullDayNames is Mon-Sun
    // our UI is Sun-Sat
    if (uiIndex == 0) return 'Sunday';
    return _fullDayNames[uiIndex - 1];
  }

  Widget _buildDayDetails() {
    final dataIndex = _getDataIndex(_selectedDayIndex);
    final dayName = _getDayName(_selectedDayIndex);
    final hasSlots = _daySchedules[dataIndex]?.isNotEmpty ?? false;

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 280),
      child: Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Day Name (Toggle Removed)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                dayName,
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              // Optional: Status Indicator text instead of toggle?
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: hasSlots
                      ? AppPalette.orangeAccent.withValues(alpha: 0.15)
                      : Theme.of(context).disabledColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  hasSlots ? 'Active' : 'Inactive',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: hasSlots
                        ? AppPalette.orangeAccent
                        : Theme.of(context).disabledColor,
                  ),
                ),
              ),
            ],
          ),

          const Divider(height: 32),

          // Slots List or Placeholder
          if (hasSlots)
            ...List.generate(_daySchedules[dataIndex]!.length, (slotIndex) {
              final interval = _daySchedules[dataIndex]![slotIndex];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    // Start Time
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'START',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              color: AppPalette.orangeAccent,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildTimeDropdown(interval.start, (val) {
                            final startMin = _minutesFromTime(_parseTime(val));
                            final endMin = _minutesFromTime(
                              _parseTime(interval.end),
                            );
                            setState(() {
                              interval.start = val;
                              if (startMin >= endMin) {
                                interval.end = _formatTime(
                                  _timeFromMinutes(startMin + 60),
                                );
                              }
                            });
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Arrow
                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        size: 20,
                        color: AppPalette.orangeAccent.withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // End Time
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'END',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              color: AppPalette.orangeAccent,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildTimeDropdown(interval.end, (val) {
                            final startMin = _minutesFromTime(
                              _parseTime(interval.start),
                            );
                            final endMin = _minutesFromTime(_parseTime(val));

                            if (endMin <= startMin) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'End time must be after start time',
                                    ),
                                  ),
                                );
                              }
                              return;
                            }
                            setState(() => interval.end = val);
                          }),
                        ],
                      ),
                    ),
                    // Remove Button
                    Padding(
                      padding: const EdgeInsets.only(left: 8, top: 16),
                      child: IconButton(
                        icon: const Icon(
                          Icons.remove_circle_outline,
                          color: Colors.redAccent,
                        ),
                        onPressed: () {
                          setState(() {
                            _daySchedules[dataIndex]!.removeAt(slotIndex);
                          });
                        },
                      ),
                    ),
                  ],
                ),
              );
            })
          else
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.event_busy,
                      size: 48,
                      color: Theme.of(
                        context,
                      ).disabledColor.withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No availability set for $dayName',
                      style: GoogleFonts.inter(
                        color: Theme.of(context).disabledColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 16),

          // Add Slot Button (Always Visible)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  final schedule = _daySchedules[dataIndex]!;
                  String newStart = '09:00 AM';
                  String newEnd = '05:00 PM';

                  if (schedule.isNotEmpty) {
                    final lastSlot = schedule.last;
                    try {
                      final lastEnd = _parseTime(lastSlot.end);
                      final lastEndMinutes = _minutesFromTime(lastEnd);

                      // Start next slot at end of last slot
                      final startMinutes = lastEndMinutes;
                      // End next slot 1 hour later, cap at 23:59 (1439 mins)
                      final endMinutes = (startMinutes + 60).clamp(0, 1439);

                      newStart = _formatTime(_timeFromMinutes(startMinutes));
                      newEnd = _formatTime(_timeFromMinutes(endMinutes));
                    } catch (e) {
                      debugPrint('Error calculating dynamic time slot: $e');
                    }
                  }

                  schedule.add(TimeInterval(start: newStart, end: newEnd));
                });
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Time Slot'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppPalette.orangeAccent,
                side: BorderSide(
                  color: AppPalette.orangeAccent.withValues(alpha: 0.5),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    ),  // end ConstrainedBox child Container
    );  // end ConstrainedBox
  }

  List<BlockedDate> _blockedDates = [];

  // Date-specific availability overrides (format: "2026-02-10" => [TimeInterval(...)])
  final Map<String, List<TimeInterval>> _dateOverrides = {};

  @override
  void initState() {
    super.initState();
    _loadAvailability();
  }

  @override
  void deactivate() {
    // Auto-save when navigating away via bottom nav bar or any other nav
    _saveAvailability(silent: true);
    super.deactivate();
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

      // Parse date overrides
      if (data.containsKey('dateOverrides') && data['dateOverrides'] != null) {
        final dateOverrides = data['dateOverrides'];
        if (dateOverrides is List) {
          _dateOverrides.clear();
          for (var override in dateOverrides) {
            if (override is Map) {
              final dateKey = override['date']?.toString();
              final schedule = override['schedule'];
              if (dateKey != null && schedule is List) {
                _dateOverrides[dateKey] = schedule.map((ti) {
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

  /// [silent] – when true, suppresses the success snackbar (used for auto-saves).
  Future<void> _saveAvailability({bool silent = false}) async {
    if (!mounted) return;
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
        'dateOverrides': _dateOverrides.entries
            .map(
              (e) => {
                'date': e.key,
                'schedule': e.value.map((ti) => ti.toJson()).toList(),
              },
            )
            .toList(),
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

      if (!mounted) return;
      setState(() => _isSaving = false);

      if (!silent && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Availability saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
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
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;
          if (_isSaving) return;
          await _saveAvailability();
          if (context.mounted) {
            Navigator.of(context).pop();
          }
        },
        child: Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (_isSaving) return;
        await _saveAvailability();
        if (context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Column(
          children: [
            CoachAppBar(
              backgroundColor: AppPalette.navyPrimary, // Unified Header Color
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (context.canPop())
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () async {
                        if (_isSaving) return;
                        await _saveAvailability();
                        if (context.mounted) {
                          context.pop();
                        }
                      },
                    )
                  else
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
                    iconColor: Colors.white,
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
                    // SECTION: Weekly Schedule (Always visible, but maybe disabled state if overriding?)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                        // Horizontal Day Selector - Circular Buttons
                        LayoutBuilder(
                          builder: (context, constraints) {
                            // Calculate dynamic size based on available width
                            final availableWidth = constraints.maxWidth;
                            final spacing = 10.0;
                            final totalSpacing =
                                spacing * 6; // 6 gaps between 7 items
                            final circleSize =
                                ((availableWidth - totalSpacing) / 7).clamp(
                                  40.0,
                                  56.0,
                                );

                            return SizedBox(
                              height: circleSize,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: 7,
                                separatorBuilder: (context, index) =>
                                    SizedBox(width: spacing),
                                itemBuilder: (context, index) {
                                  // Mapping UI index (0=Sun) to Data index (0=Mon)
                                  // UI: Sun(0), Mon(1), Tue(2) ... Sat(6)
                                  // Data: Mon(0), Tue(1) ... Sat(5), Sun(6)
                                  final dataIndex = index == 0 ? 6 : index - 1;
                                  final isSelected = _selectedDayIndex == index;
                                  final hasSlots =
                                      _daySchedules[dataIndex]?.isNotEmpty ??
                                      false;

                                  return GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedDayIndex = index;
                                        // If they click a weekly day, we exit specific date mode
                                        _selectedDay = null;
                                      });
                                    },
                                    child: Container(
                                      width: circleSize,
                                      height: circleSize,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isSelected
                                            ? AppPalette.orangeAccent
                                            : hasSlots
                                            ? AppPalette.orangeAccent
                                                  .withValues(alpha: 0.15)
                                            : Theme.of(context).cardColor,
                                        border: Border.all(
                                          color: hasSlots || isSelected
                                              ? AppPalette.orangeAccent
                                              : Theme.of(context).dividerColor
                                                    .withValues(alpha: 0.2),
                                          width: isSelected ? 2 : 1,
                                        ),
                                        boxShadow: isSelected
                                            ? [
                                                BoxShadow(
                                                  color: AppPalette.orangeAccent
                                                      .withValues(alpha: 0.3),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ]
                                            : null,
                                      ),
                                      child: Center(
                                        child: Text(
                                          [
                                            'S',
                                            'M',
                                            'T',
                                            'W',
                                            'T',
                                            'F',
                                            'S',
                                          ][index],
                                          style: GoogleFonts.outfit(
                                            fontSize:
                                                circleSize *
                                                0.35, // Dynamic font size
                                            fontWeight: FontWeight.bold,
                                            color: isSelected
                                                ? Colors.white
                                                : hasSlots
                                                ? AppPalette.orangeAccent
                                                : Theme.of(
                                                    context,
                                                  ).disabledColor,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                        _buildDayDetails(),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Calendar Section (Moved Below Weekly Schedule)
                    Text(
                      'Calendar Overrides',
                      style: GoogleFonts.outfit(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Select a date to customize availability or block dates.',
                      style: GoogleFonts.inter(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.6),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 16),

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
                        firstDay: DateTime.now(), // Disable past dates
                        lastDay: DateTime.utc(2030, 3, 14),
                        focusedDay: _focusedDay,
                        calendarFormat: _calendarFormat,
                        availableGestures: AvailableGestures.all,
                        selectedDayPredicate: (day) {
                          return isSameDay(_selectedDay, day);
                        },
                        onDaySelected: (selectedDay, focusedDay) {
                          setState(() {
                            _selectedDay = selectedDay;
                            _focusedDay = focusedDay;
                            // If selecting a calendar date, deselect the weekly toggle (visually)
                          });
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
                            color: AppPalette.orangeAccent.withValues(
                              alpha: 0.3,
                            ),
                            shape: BoxShape.circle,
                          ),
                          selectedDecoration: const BoxDecoration(
                            color: AppPalette.orangeAccent,
                            shape: BoxShape.circle,
                          ),
                          markerDecoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.error,
                            shape: BoxShape.circle,
                          ),
                        ),
                        calendarBuilders: CalendarBuilders(
                          // Paint blocked date cells with a red background
                          defaultBuilder: (context, date, _) {
                            final isBlocked = _isDateBlocked(date);
                            if (!isBlocked) return null;
                            return Container(
                              margin: const EdgeInsets.all(5.0),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.redAccent,
                                  width: 1.2,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  '${date.day}',
                                  style: GoogleFonts.inter(
                                    color: Colors.redAccent,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            );
                          },
                          // Disabled (past) days — still show red if blocked
                          disabledBuilder: (context, date, _) {
                            final isBlocked = _isDateBlocked(date);
                            if (!isBlocked) return null;
                            return Container(
                              margin: const EdgeInsets.all(5.0),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.10),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.redAccent.withValues(alpha: 0.5),
                                  width: 1.2,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  '${date.day}',
                                  style: GoogleFonts.inter(
                                    color: Colors.redAccent.withValues(alpha: 0.6),
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            );
                          },
                          // Blocked + selected → keep red but inverted
                          selectedBuilder: (context, date, _) {
                            final isBlocked = _isDateBlocked(date);
                            return Container(
                              margin: const EdgeInsets.all(5.0),
                              decoration: BoxDecoration(
                                color: isBlocked
                                    ? Colors.redAccent
                                    : AppPalette.orangeAccent,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '${date.day}',
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            );
                          },
                          // Blocked + today → red ring
                          todayBuilder: (context, date, _) {
                            final isBlocked = _isDateBlocked(date);
                            return Container(
                              margin: const EdgeInsets.all(5.0),
                              decoration: BoxDecoration(
                                color: isBlocked
                                    ? Colors.red.withValues(alpha: 0.15)
                                    : AppPalette.orangeAccent.withValues(alpha: 0.3),
                                shape: BoxShape.circle,
                                border: isBlocked
                                    ? Border.all(color: Colors.redAccent, width: 1.2)
                                    : null,
                              ),
                              child: Center(
                                child: Text(
                                  '${date.day}',
                                  style: GoogleFonts.inter(
                                    color: isBlocked
                                        ? Colors.redAccent
                                        : Theme.of(context).colorScheme.onSurface,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            );
                          },
                          markerBuilder: (context, date, events) {
                            final dateKey =
                                "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
                            final hasOverride = _dateOverrides.containsKey(
                              dateKey,
                            );

                            final isSelected = isSameDay(date, _selectedDay);

                            // Check if this date is blocked
                            final isBlocked = _isDateBlocked(date);

                            // Blocked dates show via defaultBuilder cell color; skip dot marker
                            if (isBlocked) return null;

                            if (hasOverride) {
                              return Positioned(
                                bottom: 7,
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isSelected
                                        ? AppPalette.navyPrimary
                                        : Colors.blue,
                                  ),
                                  width: 5.0,
                                  height: 5.0,
                                ),
                              );
                            }

                            final weekdayIndex = _getDataIndex(
                              date.weekday == 7 ? 0 : date.weekday,
                            );
                            final hasRecurring =
                                _daySchedules[weekdayIndex]?.isNotEmpty ??
                                false;

                            if (hasRecurring) {
                              return Positioned(
                                bottom: 7,
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isSelected
                                        ? Colors.white
                                        : AppPalette.orangeAccent,
                                  ),
                                  width: 5.0,
                                  height: 5.0,
                                ),
                              );
                            }
                            return null;
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // SECTION: Date Override Editor (Always visible)
                    _buildDateOverrideEditor(),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 24),

                    const SizedBox(height: 24),

                    // Blocked Dates List (Keep at bottom)
                    Text(
                      'Blocked Dates List',

                      style: GoogleFonts.outfit(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Add holidays or specific days you are unavailable.',
                      style: GoogleFonts.inter(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.6),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Blocked Dates List
                    if (_blockedDates.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Theme.of(
                              context,
                            ).dividerColor.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'No blocked dates added yet.',
                            style: GoogleFonts.inter(
                              color: Theme.of(context).disabledColor,
                            ),
                          ),
                        ),
                      )
                    else
                      ..._blockedDates.map((blockedDate) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Theme.of(
                                context,
                              ).dividerColor.withValues(alpha: 0.1),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(
                                  context,
                                ).shadowColor.withValues(alpha: 0.02),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: blockedDate.color.withValues(
                                    alpha: 0.1,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  blockedDate.icon,
                                  color: blockedDate.color,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      blockedDate.title,
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      '${_formatDateShort(blockedDate.start)} - ${_formatDateShort(blockedDate.end)}',
                                      style: GoogleFonts.inter(
                                        color: Theme.of(context).disabledColor,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.grey,
                                ),
                                onPressed: () async {
                                  if (blockedDate.id != null) {
                                    // Call API to remove
                                    try {
                                      await CoachService.removeBlockedDate(
                                        blockedDate.id!,
                                      );
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Failed to delete: $e',
                                            ),
                                          ),
                                        );
                                      }
                                      return; // Don't remove from list if API failed
                                    }
                                  }
                                  setState(() {
                                    _blockedDates.remove(blockedDate);
                                  });
                                },
                              ),
                            ],
                          ),
                        );
                      }),

                    const SizedBox(height: 16),

                    // Add Blocked Date Button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _showAddBlockedDateDialog,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(color: AppPalette.navyPrimary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: Icon(Icons.add, color: AppPalette.navyPrimary),
                        label: Text(
                          "Add Blocked Date",
                          style: TextStyle(
                            color: AppPalette.navyPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 50), // Bottom padding
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Helper Methods ---

  /// Builds the editor for a specifically selected date (Override Mode)
  Widget _buildDateOverrideEditor() {
    if (_selectedDay == null) {
      // Fallback: should not normally occur since _selectedDay defaults to today
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.touch_app_outlined,
              color: Theme.of(context).disabledColor.withValues(alpha: 0.5),
              size: 32,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                'Tap a date on the calendar above to customize availability or block that day.',
                style: GoogleFonts.inter(
                  color: Theme.of(context).disabledColor,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final dateKey =
        "${_selectedDay!.year}-${_selectedDay!.month.toString().padLeft(2, '0')}-${_selectedDay!.day.toString().padLeft(2, '0')}";
    final formattedDate =
        "${_fullDayNames[_getDataIndex(_selectedDay!.weekday == 7 ? 0 : _selectedDay!.weekday)]}, ${_selectedDay!.day}/${_selectedDay!.month}";

    // Check statuses
    final bool isBlocked = _isDateBlocked(_selectedDay!);
    final bool hasOverride = _dateOverrides.containsKey(dateKey);

    // Get schedule to display: Override -> or Default Recurring
    List<TimeInterval> displaySchedule;
    if (hasOverride) {
      displaySchedule = _dateOverrides[dateKey]!;
    } else {
      // Fallback to recurring
      final weekdayIndex = _getDataIndex(
        _selectedDay!.weekday == 7 ? 0 : _selectedDay!.weekday,
      ); // Map to 0-6 (Mon-Sun)
      displaySchedule = _daySchedules[weekdayIndex] ?? [];
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppPalette.navyPrimary.withValues(alpha: 0.1),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Edit for $formattedDate',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppPalette.navyPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (hasOverride)
                    Text(
                      'Custom Override Active',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.blue,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  else if (isBlocked)
                    Text(
                      'Date is Blocked',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  else
                    Text(
                      'Currently using default schedule.',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                ],
              ),

            ],
          ),
          const Divider(height: 24),

          // Actions Row
          Row(
            children: [
              if (hasOverride || isBlocked)
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _dateOverrides.remove(dateKey);
                      _blockedDates.removeWhere(
                        (bd) => isSameDay(bd.start, _selectedDay),
                      );
                    });
                  },
                  icon: const Icon(Icons.restart_alt, size: 16),
                  label: const Text('Reset to Default'),
                  style: TextButton.styleFrom(foregroundColor: Colors.grey),
                ),
              const Spacer(),
            ],
          ),

          const SizedBox(height: 16),

          if (isBlocked) ...[
            Center(
              child: Column(
                children: [
                  const Icon(Icons.block, size: 40, color: Colors.redAccent),
                  const SizedBox(height: 12),
                  const Text('This date is blocked.'),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _blockedDates.removeWhere(
                          (bd) => isSameDay(bd.start, _selectedDay),
                        );
                      });
                    },
                    child: const Text('Unblock Date'),
                  ),
                ],
              ),
            ),
          ] else ...[
            // Time Slots Editor (Operating on a COPY or directly on override)
            ...List.generate(displaySchedule.length, (index) {
              final interval = displaySchedule[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    // Start
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'START',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              color: AppPalette.orangeAccent,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildTimeDropdown(interval.start, (val) {
                            _updateOverrideSlot(dateKey, index, start: val);
                          }),
                        ],
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Padding(
                        padding: EdgeInsets.only(top: 20),
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          size: 20,
                          color: AppPalette.orangeAccent,
                        ),
                      ),
                    ),
                    // End
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'END',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              color: AppPalette.orangeAccent,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildTimeDropdown(interval.end, (val) {
                            _updateOverrideSlot(dateKey, index, end: val);
                          }),
                        ],
                      ),
                    ),
                    // Delete
                    Padding(
                      padding: const EdgeInsets.only(left: 8, top: 20),
                      child: IconButton(
                        icon: const Icon(
                          Icons.remove_circle_outline,
                          color: Colors.redAccent,
                          size: 20,
                        ),
                        onPressed: () {
                          _removeOverrideSlot(dateKey, index);
                        },
                      ),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                _addOverrideSlot(dateKey);
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Slot for this Date'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppPalette.orangeAccent,
                side: BorderSide(
                  color: AppPalette.orangeAccent.withValues(alpha: 0.5),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            const SizedBox(height: 12),
            // Block Date Option
            const SizedBox(height: 16),
            // Save Changes Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : () async {
                  await _saveAvailability();
                },
                icon: _isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save_outlined, color: Colors.white),
                label: Text(
                  _isSaving ? 'Saving...' : 'Save Changes',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppPalette.orangeAccent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _updateOverrideSlot(
    String dateKey,
    int index, {
    String? start,
    String? end,
  }) {
    // Ensure we are working on an override, not the default map reference
    if (!_dateOverrides.containsKey(dateKey)) {
      final weekdayIndex = _getDataIndex(
        _selectedDay!.weekday == 7 ? 0 : _selectedDay!.weekday,
      );
      final defaultSchedule = _daySchedules[weekdayIndex] ?? [];
      _dateOverrides[dateKey] = defaultSchedule
          .map((ti) => TimeInterval(start: ti.start, end: ti.end))
          .toList();
    }

    final schedule = _dateOverrides[dateKey]!;
    if (index >= schedule.length) return;

    // Save old values in case we need to revert
    final oldStart = schedule[index].start;
    final oldEnd = schedule[index].end;

    // Apply the proposed change
    if (start != null) schedule[index].start = start;
    if (end != null) schedule[index].end = end;

    // Validate: end > start and no overlaps
    final error = _validateSlots(schedule);
    if (error != null) {
      // Revert to previous values
      schedule[index].start = oldStart;
      schedule[index].end = oldEnd;
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    setState(() {});

    // Auto-save time changes immediately
    _saveAvailability(silent: true);
  }

  void _removeOverrideSlot(String dateKey, int index) {
    if (!_dateOverrides.containsKey(dateKey)) {
      // Copy default to override first
      final weekdayIndex = _getDataIndex(
        _selectedDay!.weekday == 7 ? 0 : _selectedDay!.weekday,
      );
      final defaultSchedule = _daySchedules[weekdayIndex] ?? [];
      _dateOverrides[dateKey] = defaultSchedule
          .map((ti) => TimeInterval(start: ti.start, end: ti.end))
          .toList();
    }

    setState(() {
      if (_dateOverrides[dateKey]!.length > index) {
        _dateOverrides[dateKey]!.removeAt(index);
      }
    });

    // Auto-save so the removal persists immediately
    _saveAvailability(silent: true);
  }

  void _addOverrideSlot(String dateKey) {
    if (!_dateOverrides.containsKey(dateKey)) {
      final weekdayIndex = _getDataIndex(
        _selectedDay!.weekday == 7 ? 0 : _selectedDay!.weekday,
      );
      final defaultSchedule = _daySchedules[weekdayIndex] ?? [];
      _dateOverrides[dateKey] = defaultSchedule
          .map((ti) => TimeInterval(start: ti.start, end: ti.end))
          .toList();
    }

    final schedule = _dateOverrides[dateKey]!;

    // Default new slot if schedule is empty
    String newStart = '09:00 AM';
    String newEnd = '10:00 AM';

    if (schedule.isNotEmpty) {
      try {
        // Sort by start time and walk through gaps to find a free 60-min window
        final sortedSlots = List<TimeInterval>.from(schedule)
          ..sort((a, b) => a.startMinutes.compareTo(b.startMinutes));

        bool found = false;
        // Try placing after each existing slot end
        for (final slot in sortedSlots) {
          final candidateStart = slot.endMinutes;
          final candidateEnd = candidateStart + 60;
          if (candidateEnd > 1440) continue;

          final candidate = TimeInterval(
            start: _formatTime(_timeFromMinutes(candidateStart)),
            end: _formatTime(_timeFromMinutes(candidateEnd)),
          );
          if (_validateSlots([...schedule, candidate]) == null) {
            newStart = candidate.start;
            newEnd = candidate.end;
            found = true;
            break;
          }
        }

        if (!found) {
          if (mounted) {
            ScaffoldMessenger.of(context).clearSnackBars();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No available gap to add a new slot. All time is occupied.'),
                backgroundColor: Colors.redAccent,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          return;
        }
      } catch (e) {
        debugPrint('Error calculating next override slot: $e');
      }
    }

    setState(() {
      schedule.add(TimeInterval(start: newStart, end: newEnd));
    });

    // Auto-save so the override persists immediately
    _saveAvailability(silent: true);
  }

  // --- Helper Methods ---

  /// Robustly checks whether a calendar [date] falls within any blocked range.
  /// Normalises both sides to local midnight to avoid UTC/local mismatches.
  bool _isDateBlocked(DateTime date) {
    final normalised = DateTime(date.year, date.month, date.day);
    return _blockedDates.any((bd) {
      final local = bd.start.toLocal();
      final localEnd = bd.end.toLocal();
      final start = DateTime(local.year, local.month, local.day);
      final end = DateTime(localEnd.year, localEnd.month, localEnd.day);
      return !normalised.isBefore(start) && !normalised.isAfter(end);
    });
  }

  /// Returns null if all slots are valid (end > start, no overlaps).
  /// Returns an error message string if validation fails.
  String? _validateSlots(List<TimeInterval> slots) {
    for (int i = 0; i < slots.length; i++) {
      final aStart = slots[i].startMinutes;
      final aEnd = slots[i].endMinutes;
      if (aEnd <= aStart) {
        return 'End time must be after start time for each slot.';
      }
      for (int j = 0; j < slots.length; j++) {
        if (i == j) continue;
        final bStart = slots[j].startMinutes;
        final bEnd = slots[j].endMinutes;
        // Overlap when A starts before B ends AND A ends after B starts
        if (aStart < bEnd && aEnd > bStart) {
          return 'Time slots cannot overlap. Please choose a different time.';
        }
      }
    }
    return null;
  }

  void _showAddBlockedDateDialog({DateTime? initialDate}) {
    final titleController = TextEditingController();
    DateTime rangeStart = initialDate ?? DateTime.now();
    DateTime rangeEnd = initialDate ?? DateTime.now();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                'Block Dates',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Reason (e.g., Vacation)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    title: const Text('Select Date Range'),
                    subtitle: Text(
                      '${_formatDateShort(rangeStart)} - ${_formatDateShort(rangeEnd)}',
                    ),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final picked = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                        initialDateRange: DateTimeRange(
                          start: rangeStart,
                          end: rangeEnd,
                        ),
                      );
                      if (picked != null) {
                        setDialogState(() {
                          rangeStart = picked.start;
                          rangeEnd = picked.end;
                        });
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (titleController.text.isEmpty) return;

                    final newBlock = BlockedDate(
                      title: titleController.text,
                      start: rangeStart,
                      end: rangeEnd,
                      color: Colors.redAccent,
                      icon: Icons.block,
                    );

                    // Optimistic UI update
                    setState(() => _blockedDates.add(newBlock));
                    Navigator.pop(context);

                    // API Call
                    try {
                      final res = await CoachService.addBlockedDate({
                        'title': newBlock.title,
                        'startDate': newBlock.start.toIso8601String(),
                        'endDate': newBlock.end.toIso8601String(),
                        'icon': 'block',
                        'color': 'red',
                      });
                      // Update with real ID from server
                      if (res.containsKey('_id')) {
                        setState(() {
                          final index = _blockedDates.indexOf(newBlock);
                          if (index != -1) {
                            _blockedDates[index] = BlockedDate(
                              id: res['_id'],
                              title: newBlock.title,
                              start: newBlock.start,
                              end: newBlock.end,
                              color: newBlock.color,
                              icon: newBlock.icon,
                            );
                          }
                        });
                      }
                    } catch (e) {
                      setDialogState(() => _blockedDates.remove(newBlock));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to add blocked date: $e'),
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppPalette.navyPrimary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Add Block'),
                ),
              ],
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
          initialTime = _parseTime(value);
        } catch (_) {}

        // Use showDialog instead of showModalBottomSheet to appear above the current dialog
        final TimeOfDay? picked = await showDialog<TimeOfDay>(
          context: context,
          builder: (BuildContext dialogContext) {
            TimeOfDay selectedTime = initialTime;
            return Theme(
              data: ThemeData.light(),
              child: Dialog(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Container(
                  height: 350,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.inter(
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          Text(
                            'Select Time',
                            style: GoogleFonts.outfit(
                              color: AppPalette.navyPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          TextButton(
                            onPressed: () =>
                                Navigator.pop(dialogContext, selectedTime),
                            child: Text(
                              'Done',
                              style: GoogleFonts.inter(
                                color: AppPalette.orangeAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Picker
                      Expanded(
                        child: CupertinoTheme(
                          data: const CupertinoThemeData(
                            brightness: Brightness.light,
                          ),
                          child: CupertinoDatePicker(
                            mode: CupertinoDatePickerMode.time,
                            initialDateTime: DateTime(
                              2024,
                              1,
                              1,
                              initialTime.hour,
                              initialTime.minute,
                            ),
                            onDateTimeChanged: (DateTime newTime) {
                              selectedTime = TimeOfDay.fromDateTime(newTime);
                            },
                            use24hFormat: false,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );

        if (picked != null) {
          onChanged(_formatTime(picked));
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppPalette.divider.withValues(alpha: 0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w600,
                    color: AppPalette.textPrimaryLight,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppPalette.orangeAccent,
              size: 18,
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

  String _formatDateShort(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}';
  }
}
