import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

Future<TimeOfDay?> showIOSTidPicker({
  required BuildContext context,
  required TimeOfDay initialTime,
}) async {
  TimeOfDay selectedTime = initialTime;

  return await showModalBottomSheet<TimeOfDay>(
    context: context,
    backgroundColor: const Color(0xFF1C1C1E), // Dark iOS background
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (BuildContext context) {
      return Container(
        height: 300,
        padding: const EdgeInsets.only(top: 8),
        child: Column(
          children: [
            // Header with Cancel/Done
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Text(
                    'Select Time',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.check, color: Colors.orange),
                    onPressed: () => Navigator.of(context).pop(selectedTime),
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoTheme(
                data: const CupertinoThemeData(
                  brightness: Brightness.dark,
                  textTheme: CupertinoTextThemeData(
                    dateTimePickerTextStyle: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                    ),
                  ),
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
                  onDateTimeChanged: (DateTime newDateTime) {
                    selectedTime = TimeOfDay(
                      hour: newDateTime.hour,
                      minute: newDateTime.minute,
                    );
                  },
                  use24hFormat: false,
                  backgroundColor: const Color(0xFF1C1C1E),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}
