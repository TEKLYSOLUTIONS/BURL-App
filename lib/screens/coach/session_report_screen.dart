import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import '../../config/palette.dart';

class SessionReportScreen extends StatefulWidget {
  const SessionReportScreen({super.key});

  @override
  State<SessionReportScreen> createState() => _SessionReportScreenState();
}

class _SessionReportScreenState extends State<SessionReportScreen> {
  // Mock Data
  final String _selectedPlayer = 'Alex Johnson';
  final String _selectedSession = 'Oct 24 - Agility Drills';

  // Ratings
  double _technicalScore = 4;
  double _effortScore = 5;
  double _tacticalScore = 0; // Default 0 as per image

  final TextEditingController _notesController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          AppPalette.backgroundLight, // Slightly off-white background
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'New Session Report',
          style: GoogleFonts.outfit(
            color: AppPalette.navyPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () {},
            child: Text(
              'Drafts',
              style: GoogleFonts.inter(
                color: AppPalette.orangeAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionLabel('PLAYER'),
                  const SizedBox(height: 8),
                  _buildDropdownCard(
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 20,
                          backgroundImage: NetworkImage(
                            'https://i.pravatar.cc/150?img=11',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedPlayer,
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: AppPalette.navyPrimary,
                                ),
                              ),
                              Text(
                                'Forward • #10',
                                style: GoogleFonts.inter(
                                  color: AppPalette.textSecondaryLight,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  _buildSectionLabel('SESSION'),
                  const SizedBox(height: 8),
                  _buildDropdownCard(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppPalette.orangeAccent.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.calendar_today_rounded,
                            color: AppPalette.orangeAccent,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedSession,
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: AppPalette.navyPrimary,
                                ),
                              ),
                              Text(
                                'Tuesday • 10:00 AM - 11:30 AM',
                                style: GoogleFonts.inter(
                                  color: AppPalette.textSecondaryLight,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Performance',
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppPalette.navyPrimary,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppPalette.orangeAccent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Score: 8.5',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            color: AppPalette.orangeAccent,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        _buildStarRatingRow(
                          'Technical Skill',
                          _technicalScore,
                          (v) => setState(() => _technicalScore = v),
                        ),
                        const SizedBox(height: 20),
                        _buildStarRatingRow(
                          'Effort & Intensity',
                          _effortScore,
                          (v) => setState(() => _effortScore = v),
                        ),
                        const SizedBox(height: 20),
                        _buildStarRatingRow(
                          'Tactical Awareness',
                          _tacticalScore,
                          (v) => setState(() => _tacticalScore = v),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Coach\'s Notes',
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppPalette.navyPrimary,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppPalette.orangeAccent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.mic,
                              size: 16,
                              color: AppPalette.orangeAccent,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Dictate',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                color: AppPalette.orangeAccent,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: 150,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _notesController,
                            maxLines: null,
                            decoration: InputDecoration(
                              hintText:
                                  'Describe key takeaways, areas for improvement, and positive highlights from the session...',
                              hintStyle: GoogleFonts.inter(
                                color: Colors.grey[400],
                              ),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: Text(
                            'Auto-saved',
                            style: GoogleFonts.inter(
                              color: Colors.grey[400],
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                  _buildSectionLabel('ATTACHMENTS'),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildAddAttachmentButton(),
                      const SizedBox(width: 12),
                      _buildAttachmentThumbnail(
                        'https://images.unsplash.com/photo-1531415074968-055a585ddd11?auto=format&fit=crop&q=80&w=200',
                      ), // Grass/Cones
                      const SizedBox(width: 12),
                      _buildAttachmentThumbnail(
                        'https://images.unsplash.com/photo-1624880357913-a8539238245b?auto=format&fit=crop&q=80&w=200',
                        isVideo: true,
                      ), // Player
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Report Sent Successfully!')),
                  );
                  context.pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppPalette.orangeAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Send Report',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: const Color(0xFF94A3B8), // Slate grey
        letterSpacing: 1.0,
      ),
    );
  }

  Widget _buildDropdownCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Expanded(child: child),
          Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey[400]),
        ],
      ),
    );
  }

  Widget _buildStarRatingRow(
    String label,
    double score,
    ValueChanged<double> onChanged,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: AppPalette.navyPrimary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: List.generate(5, (index) {
                return GestureDetector(
                  onTap: () => onChanged(index + 1.0),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Icon(
                      index < score
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      color: index < score
                          ? AppPalette.orangeAccent
                          : Colors.grey[300],
                      size: 28,
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
        Text(
          '${score.toInt()}/5',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: score > 0 ? AppPalette.orangeAccent : Colors.grey[300],
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildAddAttachmentButton() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: AppPalette.orangeAccent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppPalette.orangeAccent,
          style: BorderStyle.solid,
        ), // Dotted border would require a custom painter, solid is fine for MVP
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.add_a_photo_rounded, color: AppPalette.orangeAccent),
          const SizedBox(height: 4),
          Text(
            'Add',
            style: GoogleFonts.inter(
              color: AppPalette.orangeAccent,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentThumbnail(String imageUrl, {bool isVideo = false}) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            image: DecorationImage(
              image: NetworkImage(imageUrl),
              fit: BoxFit.cover,
            ),
          ),
        ),
        if (isVideo)
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.play_arrow_rounded,
              color: AppPalette.navyPrimary,
              size: 20,
            ),
          ),
      ],
    );
  }
}
