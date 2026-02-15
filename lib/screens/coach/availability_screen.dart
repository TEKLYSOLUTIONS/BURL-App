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

  // Date-specific availability overrides (format: "2026-02-10" => [TimeInterval(...)])
  final Map<String, List<TimeInterval>> _dateOverrides = {};

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
                        setState(() {
                          _selectedDay = selectedDay;
                          _focusedDay = focusedDay;
                        });

                        // Shortcut to add blocked date
                        _showAddBlockedDateDialog(initialDate: selectedDay);
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
                      calendarBuilders: CalendarBuilders(
                        markerBuilder: (context, date, events) {
                          // Format date key for override lookup
                          final dateKey =
                              "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

                          // Check if this specific date has an override
                          final hasOverride = _dateOverrides.containsKey(
                            dateKey,
                          );

                          if (hasOverride) {
                            // Blue dot for date-specific override
                            return Positioned(
                              bottom: 1,
                              child: Container(
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.blue,
                                ),
                                width: 5.0,
                                height: 5.0,
                              ),
                            );
                          }

                          // Check if this day of week has recurring availability
                          final weekdayIndex = date.weekday - 1;
                          final hasRecurring =
                              _daySchedules[weekdayIndex]?.isNotEmpty ?? false;

                          if (hasRecurring) {
                            // Orange dot for recurring schedule
                            return Positioned(
                              bottom: 1,
                              child: Container(
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppPalette.orangeAccent,
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
                  // Weekly Schedule List
                  ...List.generate(_weekDays.length, (index) {
                    final dayName = _fullDayNames[index];
                    final isActive = _daySchedules[index]!.isNotEmpty;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isActive
                              ? AppPalette.navyPrimary.withValues(alpha: 0.1)
                              : Theme.of(
                                  context,
                                ).dividerColor.withValues(alpha: 0.1),
                          width: isActive ? 2 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(
                              context,
                            ).shadowColor.withValues(alpha: 0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header: Day + Toggle
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                dayName,
                                style: GoogleFonts.outfit(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: isActive
                                      ? AppPalette.navyPrimary
                                      : Theme.of(context).disabledColor,
                                ),
                              ),
                              Switch(
                                value: isActive,
                                activeTrackColor: AppPalette.navyPrimary,
                                onChanged: (val) {
                                  setState(() {
                                    if (val) {
                                      // Enable: Add default 9-5 slot
                                      _daySchedules[index] = [
                                        TimeInterval(
                                          start: '09:00 AM',
                                          end: '05:00 PM',
                                        ),
                                      ];
                                    } else {
                                      // Disable: Clear slots
                                      _daySchedules[index] = [];
                                    }
                                  });
                                },
                              ),
                            ],
                          ),

                          // Time Slots (if active)
                          if (isActive) ...[
                            const Divider(height: 24),
                            ...List.generate(_daySchedules[index]!.length, (
                              slotIndex,
                            ) {
                              final interval = _daySchedules[index]![slotIndex];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: _buildTimeDropdown(interval.start, (
                                        val,
                                      ) {
                                        final startMin = _minutesFromTime(
                                          _parseTime(val),
                                        );
                                        final endMin = _minutesFromTime(
                                          _parseTime(interval.end),
                                        );

                                        setState(() {
                                          interval.start = val;
                                          if (startMin >= endMin) {
                                            // Auto-adjust end time to be 1 hour after start
                                            interval.end = _formatTime(
                                              _timeFromMinutes(startMin + 60),
                                            );
                                          }
                                        });
                                      }),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                      ),
                                      child: Text(
                                        'To',
                                        style: GoogleFonts.inter(
                                          color: Colors.grey,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: _buildTimeDropdown(interval.end, (
                                        val,
                                      ) {
                                        final startMin = _minutesFromTime(
                                          _parseTime(interval.start),
                                        );
                                        final endMin = _minutesFromTime(
                                          _parseTime(val),
                                        );

                                        if (endMin <= startMin) {
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
                                        setState(() => interval.end = val);
                                      }),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.close,
                                        size: 20,
                                        color: Colors.grey,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _daySchedules[index]!.removeAt(
                                            slotIndex,
                                          );
                                          // Ensure we don't end up with empty list (which implies disabled)
                                          // unless user explicitly toggles off.
                                          // But for now, empty list = disabled is consistent.
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              );
                            }),

                            // Add Slot Button
                            TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  _daySchedules[index]!.add(
                                    TimeInterval(
                                      start: '09:00 AM',
                                      end: '05:00 PM',
                                    ),
                                  );
                                });
                              },
                              icon: const Icon(
                                Icons.add_circle_outline,
                                size: 16,
                              ),
                              label: const Text('Add Time Slot'),
                              style: TextButton.styleFrom(
                                foregroundColor: AppPalette.navyPrimary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }),

                  const SizedBox(height: 16),

                  // Save Button
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
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              "Save Weekly Schedule",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Blocked Dates Section Header
                  Text(
                    'Blocked Dates',
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
                                color: blockedDate.color.withValues(alpha: 0.1),
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
                                          content: Text('Failed to delete: $e'),
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
    );
  }

  // --- Helper Methods ---

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
