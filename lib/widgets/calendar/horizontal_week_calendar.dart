import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/palette.dart';

class HorizontalWeekCalendar extends StatefulWidget {
  final Function(DateTime) onDateSelected;
  final DateTime initialDate;

  const HorizontalWeekCalendar({
    super.key,
    required this.onDateSelected,
    required this.initialDate,
  });

  @override
  State<HorizontalWeekCalendar> createState() => _HorizontalWeekCalendarState();
}

class _HorizontalWeekCalendarState extends State<HorizontalWeekCalendar> {
  late DateTime _selectedDate;
  final ScrollController _scrollController = ScrollController();
  final List<DateTime> _dates = [];

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _generateDates();

    // Auto-scroll to selected date after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToDate(_selectedDate);
    });
  }

  void _generateDates() {
    // Generate dates: 2 weeks back, 4 weeks forward
    final now = DateTime.now();
    final start = now.subtract(const Duration(days: 14));
    for (int i = 0; i < 45; i++) {
      _dates.add(start.add(Duration(days: i)));
    }
  }

  void _scrollToDate(DateTime date) {
    // Determine index
    int index = _dates.indexWhere(
      (d) => d.year == date.year && d.month == date.month && d.day == date.day,
    );

    if (index != -1 && _scrollController.hasClients) {
      // Calculate offset (item width is approx 60 + margin)
      double offset =
          index * 70.0 - (MediaQuery.of(context).size.width / 2) + 35;
      if (offset < 0) offset = 0;

      _scrollController.animateTo(
        offset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Month Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            _formatMonthYear(_selectedDate),
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppPalette.navyPrimary,
              letterSpacing: 1,
            ),
          ),
        ),
        SizedBox(
          height: 90,
          child: ListView.builder(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _dates.length,
            itemBuilder: (context, index) {
              final date = _dates[index];
              final isSelected =
                  date.year == _selectedDate.year &&
                  date.month == _selectedDate.month &&
                  date.day == _selectedDate.day;

              final isToday =
                  date.year == DateTime.now().year &&
                  date.month == DateTime.now().month &&
                  date.day == DateTime.now().day;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedDate = date;
                  });
                  widget.onDateSelected(date);
                  _scrollToDate(date);
                },
                child: Container(
                  width: 60,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? AppPalette.navyPrimary : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: isSelected
                        ? null
                        : Border.all(
                            color: isToday
                                ? AppPalette.orangeAccent
                                : Colors.grey.shade200,
                          ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppPalette.navyPrimary.withValues(
                                alpha: 0.3,
                              ),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _getDayName(date.weekday).toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white70 : Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        date.day.toString(),
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? Colors.white
                              : AppPalette.navyPrimary,
                        ),
                      ),
                      if (isToday)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white
                                : AppPalette.orangeAccent,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _formatMonthYear(DateTime date) {
    const months = [
      'JANUARY',
      'FEBRUARY',
      'MARCH',
      'APRIL',
      'MAY',
      'JUNE',
      'JULY',
      'AUGUST',
      'SEPTEMBER',
      'OCTOBER',
      'NOVEMBER',
      'DECEMBER',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  String _getDayName(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }
}
