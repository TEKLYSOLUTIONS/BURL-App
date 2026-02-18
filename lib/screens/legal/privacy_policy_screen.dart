import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../config/palette.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 20,
              bottom: 24,
              left: 24,
              right: 24,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () => context.pop(),
                  icon: Icon(
                    Icons.arrow_back,
                    color: Theme.of(context).iconTheme.color,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                Text(
                  'Privacy Policy',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
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
                    'Last updated: ${DateTime.now().toString().split(' ')[0]}',
                    style: TextStyle(
                      fontSize: 14,
                      color:
                          Theme.of(context).textTheme.bodyMedium?.color ??
                          AppPalette.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildSection(
                    context,
                    'Introduction',
                    'Cricket Coaching App ("we," "our," or "us") is committed to protecting your privacy. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our mobile application. We operate in compliance with the UK Data Protection Act 2018 and the General Data Protection Regulation (GDPR).',
                  ),
                  _buildSection(
                    context,
                    '1. Information We Collect',
                    'Personal Information:\n• Name and email address\n• Profile information\n• Contact details\n• Payment information (processed securely)\n\nUsage Data:\n• Session attendance records\n• Performance metrics\n• App usage statistics\n• Device information\n\nLocation Data:\n• GPS location for finding nearby coaches (with permission)',
                  ),
                  _buildSection(
                    context,
                    '2. How We Use Your Information',
                    'We use the collected information to:\n\n• Provide and maintain our services\n• Process your bookings and payments\n• Send you notifications and updates\n• Improve app functionality\n• Analyze usage patterns\n• Communicate with you about your account\n• Provide customer support\n• Comply with legal obligations',
                  ),
                  _buildSection(
                    context,
                    '3. Data Sharing and Disclosure',
                    'We may share your information with:\n\n• Coaches: When you book a session\n• Payment processors: For secure transactions\n• Service providers: Who help us operate the app\n• Legal authorities: When required by law\n\nWe do NOT sell your personal information to third parties.',
                  ),
                  _buildSection(
                    context,
                    '4. Authentication Services',
                    'We use Firebase Authentication for secure user authentication. When you sign in using Google or Apple, we collect only the information necessary for authentication and account creation:\n\n• Email address\n• Name\n• Profile picture (optional)\n\nPlease review Google\'s Privacy Policy and Apple\'s Privacy Policy for information about their data practices.',
                  ),
                  _buildSection(
                    context,
                    '5. Data Security',
                    'We implement appropriate technical and organizational measures to protect your personal information:\n\n• Encryption of data in transit and at rest\n• Regular security assessments\n• Access controls and authentication\n• Secure cloud infrastructure\n\nHowever, no method of transmission over the Internet is 100% secure.',
                  ),
                  _buildSection(
                    context,
                    '6. Data Retention',
                    'We retain your personal information for as long as necessary to:\n\n• Provide our services\n• Comply with legal obligations (including tax and accounting requirements)\n• Resolve disputes\n• Enforce our agreements\n\nYou can request deletion of your account and associated data at any time (Right to Erasure).',
                  ),
                  _buildSection(
                    context,
                    '7. Your Rights (GDPR)',
                    'Under the UK GDPR, you have the following rights:\n\n• Right to be informed\n• Right of access\n• Right to rectification\n• Right to erasure\n• Right to restrict processing\n• Right to data portability\n• Right to object\n\nTo exercise these rights, contact our Data Protection Officer at privacy@cricketcoachingapp.com',
                  ),
                  _buildSection(
                    context,
                    '8. Children\'s Privacy',
                    'Our app is designed for users of all ages. For users under 18, guardian consent is required. Guardians can monitor their child\'s activities through the Guardian dashboard.',
                  ),
                  _buildSection(
                    context,
                    '9. Cookies and Tracking',
                    'We use cookies and similar technologies to:\n\n• Maintain your session\n• Remember your preferences\n• Analyze app usage\n• Improve user experience\n\nYou can control cookie settings through your device settings.',
                  ),
                  _buildSection(
                    context,
                    '10. Third-Party Services',
                    'Our app integrates with:\n\n• Firebase (Google): Authentication and cloud services\n• Payment processors: Secure payment handling\n• Analytics services: Usage insights\n\nThese services have their own privacy policies governing their use of information.',
                  ),
                  _buildSection(
                    context,
                    '11. Changes to Privacy Policy',
                    'We may update this Privacy Policy from time to time. We will notify you of any material changes by:\n\n• Posting the new policy in the app\n• Sending you an email notification\n• Displaying a prominent notice\n\nContinued use after changes constitutes acceptance.',
                  ),
                  _buildSection(
                    context,
                    '12. International Data Transfers',
                    'Your information may be transferred to and maintained on servers located outside the UK/EEA. We ensure appropriate safeguards (such as Standard Contractual Clauses) are in place for such transfers.',
                  ),
                  _buildSection(
                    context,
                    '13. Contact Us',
                    'For questions or concerns about this Privacy Policy or our data practices, contact us:\n\nEmail: privacy@cricketcoachingapp.com\nAddress: [Your Company Address]\nPhone: [Your Contact Number]',
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: TextStyle(
              fontSize: 15,
              color:
                  Theme.of(context).textTheme.bodyMedium?.color ??
                  AppPalette.textPrimaryLight,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
