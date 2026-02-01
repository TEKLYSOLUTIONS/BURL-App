import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/palette.dart';

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 20,
              bottom: 24,
              left: 24,
              right: 24,
            ),
            decoration: const BoxDecoration(
              color: AppPalette.navyPrimary,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                Text(
                  'Help Center',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 24), // Spacer
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  Text(
                    'How can we help you?',
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppPalette.navyPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Search for help or browse frequently asked questions.',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Search Bar (Visual only for now)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      decoration: InputDecoration(
                        icon: Icon(Icons.search, color: Colors.grey[500]),
                        hintText: 'Search help articles...',
                        border: InputBorder.none,
                        hintStyle: GoogleFonts.inter(color: Colors.grey[500]),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  Text(
                    'Frequently Asked Questions',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppPalette.navyPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildFAQItem(
                    'How do I book a coach?',
                    'You can browse coaches from the home screen, select a coach to view their profile, and choose an available slot from their calendar.',
                  ),
                  _buildFAQItem(
                    'How are payments processed?',
                    'We use secure payment processing. You can pay via credit/debit card. Payments are held securely until the session is completed.',
                  ),
                  _buildFAQItem(
                    'Can I cancel a session?',
                    'Yes, you can cancel up to 24 hours before the session starts for a full refund. Late cancellations may be subject to a fee.',
                  ),
                  _buildFAQItem(
                    'How do I verify my profile?',
                    'Coaches need to submit their certifications and ID. Our team reviews these documents within 48 hours.',
                  ),

                  const SizedBox(height: 32),

                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppPalette.navyPrimary.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppPalette.navyPrimary.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.headset_mic_outlined,
                          size: 40,
                          color: AppPalette.navyPrimary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Still need help?',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppPalette.navyPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Our support team is available 24/7.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () async {
                              final Uri emailLaunchUri = Uri(
                                scheme: 'mailto',
                                path: 'support@cricketcoachingapp.com',
                                query:
                                    'subject=Support Request&body=Hi Support,',
                              );
                              if (await canLaunchUrl(emailLaunchUri)) {
                                await launchUrl(emailLaunchUri);
                              } else {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Could not open email client',
                                      ),
                                    ),
                                  );
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppPalette.navyPrimary,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Contact Support',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Theme(
        data: ThemeData(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(
            question,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              color: AppPalette.navyPrimary,
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                answer,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
