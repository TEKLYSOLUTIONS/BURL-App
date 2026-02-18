import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../config/palette.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

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
                  'Terms of Service',
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
                    'Welcome to Cricket Coaching App',
                    'These terms and conditions outline the rules and regulations for the use of Cricket Coaching App. By accessing this app, we assume you accept these terms and conditions. Do not continue to use Cricket Coaching App if you do not agree to all of the terms and conditions stated on this page.',
                  ),
                  _buildSection(
                    context,
                    '1. Account Registration',
                    'To use certain features of the app, you must register for an account. You agree to:\n\n• Provide accurate, current, and complete information\n• Maintain and promptly update your account information\n• Maintain the security of your password\n• Accept responsibility for all activities under your account\n• Notify us immediately of any unauthorized use',
                  ),
                  _buildSection(
                    context,
                    '2. User Roles and Responsibilities',
                    'The app supports three user roles:\n\n• Players: Access coaching sessions, track progress\n• Coaches: Provide coaching services, manage sessions\n• Guardians: Monitor player progress and activities\n\nEach role has specific responsibilities and access rights.',
                  ),
                  _buildSection(
                    context,
                    '3. Booking and Payment',
                    '• All coaching session bookings are subject to coach availability\n• Payment terms will be clearly communicated before booking\n• Cancellation policies apply as specified for each session\n• Refunds are handled on a case-by-case basis',
                  ),
                  _buildSection(
                    context,
                    '4. Code of Conduct',
                    'Users must:\n\n• Treat all users with respect\n• Not engage in harassment or abuse\n• Not share inappropriate content\n• Follow cricket coaching best practices\n• Respect intellectual property rights',
                  ),
                  _buildSection(
                    context,
                    '5. Content and Intellectual Property',
                    'All content provided through the app, including but not limited to text, graphics, logos, and software, is the property of Cricket Coaching App or its content suppliers and is protected by international copyright laws.',
                  ),
                  _buildSection(
                    context,
                    '6. Privacy and Data Protection',
                    'Your privacy is important to us. Please review our Privacy Policy to understand how we collect, use, and protect your personal information.',
                  ),
                  _buildSection(
                    context,
                    '7. Limitation of Liability',
                    'Cricket Coaching App shall not be liable for any indirect, incidental, special, consequential, or punitive damages resulting from your access to or use of the app.',
                  ),
                  _buildSection(
                    context,
                    '8. Termination',
                    'We reserve the right to terminate or suspend your account and access to the app immediately, without prior notice, for conduct that we believe violates these Terms of Service or is harmful to other users.',
                  ),
                  _buildSection(
                    context,
                    '9. Changes to Terms',
                    'We reserve the right to modify these terms at any time. We will notify users of any material changes. Continued use of the app after changes constitutes acceptance of the new terms.',
                  ),
                  _buildSection(
                    context,
                    '10. Contact Information',
                    'For questions about these Terms of Service, please contact us at:\n\nEmail: support@cricketcoachingapp.com\nWebsite: www.cricketcoachingapp.com',
                  ),
                  _buildSection(
                    context,
                    '11. Governing Law',
                    'These Terms shall be governed and construed in accordance with the laws of England and Wales, without regard to its conflict of law provisions. Our failure to enforce any right or provision of these Terms will not be considered a waiver of those rights.',
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
