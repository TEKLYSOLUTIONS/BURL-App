import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// Pubspec didn't have rating bar, so I'll use simple star row logic or just sliders.
// Pubspec didn't have rating bar, so I'll use simple star row logic or just sliders.
import 'package:go_router/go_router.dart';
import '../../config/palette.dart';

class SessionReportScreen extends StatefulWidget {
  const SessionReportScreen({super.key});

  @override
  State<SessionReportScreen> createState() => _SessionReportScreenState();
}

class _SessionReportScreenState extends State<SessionReportScreen> {
  double _techniqueScore = 4;
  double _effortScore = 5;
  double _attitudeScore = 4;
  final TextEditingController _notesController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Create Report',
          style: GoogleFonts.outfit(
            color: AppPalette.navyPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Student Selector (Mock)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    backgroundImage: NetworkImage(
                      'https://i.pravatar.cc/150?img=11',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Arjun Sharma',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppPalette.navyPrimary,
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
            const SizedBox(height: 32),

            _buildRatingRow(
              'Technique',
              _techniqueScore,
              (val) => setState(() => _techniqueScore = val),
            ),
            const SizedBox(height: 24),
            _buildRatingRow(
              'Effort',
              _effortScore,
              (val) => setState(() => _effortScore = val),
            ),
            const SizedBox(height: 24),
            _buildRatingRow(
              'Attitude',
              _attitudeScore,
              (val) => setState(() => _attitudeScore = val),
            ),

            const SizedBox(height: 32),

            Text(
              'Coach Notes',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Enter feedback regarding today\'s session...',
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
              ),
            ),

            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('Report Sent!')));
                  context.pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppPalette.navyPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Submit Report'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingRow(
    String label,
    double score,
    ValueChanged<double> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            Text(
              score.toInt().toString(),
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: AppPalette.orangeAccent,
              ),
            ),
          ],
        ),
        Slider(
          value: score,
          min: 1,
          max: 5,
          divisions: 4,
          activeColor: AppPalette.orangeAccent,
          inactiveColor: Colors.grey[200],
          onChanged: onChanged,
        ),
      ],
    );
  }
}
