import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.accentPurple.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.arrow_back_ios_rounded,
                size: 16, color: AppTheme.accentPurple),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Privacy Policy',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFCE93D8), Color(0xFF9C64A6)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.accentPurple.withValues(alpha: 0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.privacy_tip_rounded,
                      color: Colors.white, size: 32),
                  const SizedBox(height: 10),
                  Text('Your Privacy Matters',
                      style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                  const SizedBox(height: 4),
                  Text('Last updated: May 2025',
                      style: GoogleFonts.poppins(
                          fontSize: 12, color: Colors.white70)),
                ],
              ),
            ),

            const SizedBox(height: 24),

            _section(
              context,
              isDark: isDark,
              icon: Icons.info_outline_rounded,
              iconColor: const Color(0xFF81D4FA),
              title: '1. Introduction',
              content:
                  'Welcome to Study Planner ("we", "our", or "us"). We are committed to protecting your personal information and your right to privacy. This Privacy Policy explains how we collect, use, and share information when you use our Study Planner mobile application.\n\nBy using our app, you agree to the collection and use of information in accordance with this policy.',
            ),

            _section(
              context,
              isDark: isDark,
              icon: Icons.data_usage_rounded,
              iconColor: const Color(0xFFA5D6A7),
              title: '2. Information We Collect',
              content:
                  '• Account Information: When you register, we collect your name and email address.\n\n• Profile Data: Profile photos you upload, your education level, and study interests you provide during onboarding.\n\n• Usage Data: Tasks you create, study sessions you record, and AI chat conversations you have within the app.\n\n• Device Information: Basic device info (OS version, device type) to ensure compatibility.\n\n• We do NOT collect payment information, location data, contacts, or any sensitive personal identifiers beyond what is listed above.',
            ),

            _section(
              context,
              isDark: isDark,
              icon: Icons.work_outline_rounded,
              iconColor: const Color(0xFFFFB300),
              title: '3. How We Use Your Information',
              content:
                  '• To provide and maintain the Study Planner service.\n\n• To personalize your AI tutoring experience based on your education level and interests.\n\n• To send optional study reminders and push notifications (only if you enable them).\n\n• To improve the app based on aggregated, anonymized usage patterns.\n\n• To respond to your support requests.\n\nWe do NOT sell your personal data to third parties. We do NOT use your data for advertising purposes.',
            ),

            _section(
              context,
              isDark: isDark,
              icon: Icons.cloud_outlined,
              iconColor: const Color(0xFFCE93D8),
              title: '4. Data Storage & Security',
              content:
                  'Your data is stored securely using Google Firebase (Firestore Database and Firebase Storage), which is hosted on Google Cloud Platform.\n\n• Authentication: Passwords are handled exclusively by Firebase Authentication — we never store your password in plain text.\n\n• Profile images: Stored securely in Firebase Storage with access restricted to your account.\n\n• Chat history: Stored in Firestore, accessible only by your authenticated account.\n\n• All data transmission uses HTTPS/TLS encryption.\n\nWhile we implement industry-standard security measures, no method of transmission over the internet is 100% secure.',
            ),

            _section(
              context,
              isDark: isDark,
              icon: Icons.share_outlined,
              iconColor: const Color(0xFFF48FB1),
              title: '5. Third-Party Services',
              content:
                  'We use the following third-party services:\n\n• Google Firebase: Authentication, database, and file storage. Governed by Google\'s Privacy Policy.\n\n• Google Gemini AI: Powers the AI Tutor feature. Your chat messages are sent to Google\'s Gemini API to generate responses. Messages may be used by Google to improve their AI models per their terms.\n\n• Google Sign-In / Apple Sign-In: Optional social authentication. We only receive your name and email from these providers.',
            ),

            _section(
              context,
              isDark: isDark,
              icon: Icons.child_care_outlined,
              iconColor: const Color(0xFF81D4FA),
              title: "6. Children's Privacy",
              content:
                  'Study Planner is designed for students of all ages. We do not knowingly collect personal information from children under 13 without parental consent. If you are a parent and believe your child has provided personal information without your consent, please contact us immediately and we will delete that information.',
            ),

            _section(
              context,
              isDark: isDark,
              icon: Icons.settings_outlined,
              iconColor: const Color(0xFFA5D6A7),
              title: '7. Your Rights & Choices',
              content:
                  '• Edit Profile: Update your name and profile photo at any time from the Profile screen.\n\n• Delete Account: Permanently delete your account and all associated data from Profile → Delete Account.\n\n• Notifications: Enable or disable push notifications and study reminders from Profile → Settings.\n\n• Data Access: Contact us to request a copy of the personal data we hold about you.\n\n• EU/UK Users: You have additional rights under GDPR, including the right to data portability and the right to object to processing.',
            ),

            _section(
              context,
              isDark: isDark,
              icon: Icons.update_rounded,
              iconColor: const Color(0xFFFFB300),
              title: '8. Changes to This Policy',
              content:
                  'We may update this Privacy Policy from time to time. We will notify you of any significant changes by displaying a notice in the app. The "Last updated" date at the top of this page will always reflect the most recent version.\n\nContinued use of the app after changes constitutes your acceptance of the revised policy.',
            ),

            _section(
              context,
              isDark: isDark,
              icon: Icons.email_outlined,
              iconColor: const Color(0xFFCE93D8),
              title: '9. Contact Us',
              content:
                  'If you have questions, concerns, or requests regarding this Privacy Policy or your personal data, please contact us:\n\n📧 privacy@studyplanner.app\n\nWe will respond to all legitimate requests within 30 days.',
            ),

            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.accentPurple.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: AppTheme.accentPurple.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified_outlined,
                      color: AppTheme.accentPurple, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'We are committed to being transparent about our data practices and giving you control over your information.',
                      style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppTheme.accentPurple,
                          height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(
    BuildContext context, {
    required bool isDark,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String content,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.07)
            : Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.white.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary,
          ),
        ),
        iconColor: AppTheme.accentPurple,
        collapsedIconColor: isDark
            ? AppTheme.darkTextSecondary
            : AppTheme.textSecondary,
        shape: const Border(),
        collapsedShape: const Border(),
        children: [
          Text(
            content,
            style: GoogleFonts.poppins(
              fontSize: 13,
              height: 1.65,
              color: isDark
                  ? AppTheme.darkTextSecondary
                  : AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
