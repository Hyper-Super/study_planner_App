import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class AboutAppScreen extends StatelessWidget {
  const AboutAppScreen({super.key});

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
          'About App',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App identity card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF9C64A6), Color(0xFF7B5EA7), Color(0xFF5B8EBF)],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.accentPurple.withValues(alpha: 0.4),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: const Icon(Icons.school_rounded,
                        color: Colors.white, size: 42),
                  ),
                  const SizedBox(height: 16),
                  Text('Study Planner',
                      style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Colors.white)),
                  Text('AI-Powered Learning Companion',
                      style: GoogleFonts.poppins(
                          fontSize: 13, color: Colors.white70)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _versionChip('Version 2.0.0'),
                      const SizedBox(width: 10),
                      _versionChip('Build 2025'),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Stats row
            Row(
              children: [
                _statBubble('10K+', 'Students', const Color(0xFFCE93D8), isDark),
                const SizedBox(width: 12),
                _statBubble('4.8★', 'Rating', const Color(0xFFFFB300), isDark),
                const SizedBox(width: 12),
                _statBubble('Free', 'Always', const Color(0xFFA5D6A7), isDark),
              ],
            ),

            const SizedBox(height: 24),

            // Mission
            _card(
              isDark: isDark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionHeader(
                      icon: Icons.flag_outlined,
                      iconColor: const Color(0xFFCE93D8),
                      title: 'Our Mission',
                      isDark: isDark),
                  const SizedBox(height: 12),
                  Text(
                    'Study Planner was built to make focused, effective studying accessible to every student — whether you\'re in school, university, or self-learning.\n\nWe combine smart task management, Pomodoro-style focus sessions, and the power of AI to help you learn faster, stay organised, and achieve your goals.',
                    style: GoogleFonts.poppins(
                        fontSize: 13,
                        height: 1.65,
                        color: isDark
                            ? AppTheme.darkTextSecondary
                            : AppTheme.textSecondary),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Features
            _card(
              isDark: isDark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionHeader(
                      icon: Icons.stars_rounded,
                      iconColor: const Color(0xFFFFB300),
                      title: 'Key Features',
                      isDark: isDark),
                  const SizedBox(height: 14),
                  ..._features.map((f) => _featureRow(f, isDark)),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Tech stack
            _card(
              isDark: isDark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionHeader(
                      icon: Icons.code_rounded,
                      iconColor: const Color(0xFF81D4FA),
                      title: 'Built With',
                      isDark: isDark),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _techStack
                        .map((tech) => _techChip(tech, isDark))
                        .toList(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // AI powered
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: AppTheme.purpleGradient,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome_rounded,
                      color: Colors.white, size: 28),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Powered by Gemini AI',
                            style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
                        Text(
                            'The AI Tutor uses Google\'s Gemini 1.5 Flash model — fast, capable, and free to use.',
                            style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: Colors.white70,
                                height: 1.5)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Legal / links
            _card(
              isDark: isDark,
              child: Column(
                children: [
                  _linkRow(Icons.privacy_tip_outlined, 'Privacy Policy',
                      const Color(0xFFCE93D8), isDark),
                  Divider(color: Colors.grey.shade100),
                  _linkRow(Icons.gavel_outlined, 'Terms of Service',
                      const Color(0xFF81D4FA), isDark),
                  Divider(color: Colors.grey.shade100),
                  _linkRow(Icons.balance_outlined,
                      'Open Source Licenses', const Color(0xFFA5D6A7), isDark),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Copyright
            Center(
              child: Column(
                children: [
                  Text('Made with ❤️ for students everywhere',
                      style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: isDark
                              ? AppTheme.darkTextSecondary
                              : AppTheme.textSecondary)),
                  const SizedBox(height: 4),
                  Text('© 2025 Study Planner. All rights reserved.',
                      style: GoogleFonts.poppins(
                          fontSize: 11, color: AppTheme.textHint)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Data ─────────────────────────────────────────────────────────────────

  static const List<Map<String, dynamic>> _features = [
    {
      'icon': Icons.task_alt_rounded,
      'color': Color(0xFFA5D6A7),
      'label': 'Smart Task Management',
      'desc': 'Organise tasks by subject, priority, and due date',
    },
    {
      'icon': Icons.timer_outlined,
      'color': Color(0xFFFFB300),
      'label': 'Pomodoro Focus Timer',
      'desc': 'Stay focused with timed study sessions',
    },
    {
      'icon': Icons.auto_awesome_rounded,
      'color': Color(0xFFCE93D8),
      'label': 'AI Tutor (AI Edge)',
      'desc': 'Instant explanations, quizzes, and study plans',
    },
    {
      'icon': Icons.bar_chart_rounded,
      'color': Color(0xFF81D4FA),
      'label': 'Progress Dashboard',
      'desc': 'Track streaks, hours, and performance scores',
    },
    {
      'icon': Icons.dark_mode_outlined,
      'color': Color(0xFF5B8EBF),
      'label': 'Dark Mode & Themes',
      'desc': 'Customise the look with 5 colour themes',
    },
    {
      'icon': Icons.notifications_outlined,
      'color': Color(0xFFF48FB1),
      'label': 'Smart Reminders',
      'desc': 'Daily study alerts and task deadline notifications',
    },
  ];

  static const List<String> _techStack = [
    'Flutter', 'Dart', 'Firebase', 'Firestore',
    'Gemini AI', 'Provider', 'Google Fonts', 'Material 3',
  ];

  // ── Widgets ───────────────────────────────────────────────────────────────

  Widget _versionChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: GoogleFonts.poppins(
              fontSize: 11, color: Colors.white, fontWeight: FontWeight.w500)),
    );
  }

  Widget _statBubble(String value, String label, Color color, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.07)
              : Colors.white.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : color.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          children: [
            Text(value,
                style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: color)),
            Text(label,
                style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _card({required bool isDark, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
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
      child: child,
    );
  }

  Widget _sectionHeader({
    required IconData icon,
    required Color iconColor,
    required String title,
    required bool isDark,
  }) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 12),
        Text(title,
            style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppTheme.darkTextPrimary
                    : AppTheme.textPrimary)),
      ],
    );
  }

  Widget _featureRow(Map<String, dynamic> f, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: (f['color'] as Color).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(f['icon'] as IconData,
                color: f['color'] as Color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(f['label'] as String,
                    style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppTheme.darkTextPrimary
                            : AppTheme.textPrimary)),
                Text(f['desc'] as String,
                    style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: isDark
                            ? AppTheme.darkTextSecondary
                            : AppTheme.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _techChip(String label, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.accentPurple.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: AppTheme.accentPurple.withValues(alpha: 0.25)),
      ),
      child: Text(label,
          style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppTheme.accentPurple,
              fontWeight: FontWeight.w500)),
    );
  }

  Widget _linkRow(IconData icon, String label, Color color, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label,
                style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? AppTheme.darkTextPrimary
                        : AppTheme.textPrimary)),
          ),
          Icon(Icons.chevron_right_rounded,
              color: isDark
                  ? AppTheme.darkTextSecondary
                  : AppTheme.textHint,
              size: 18),
        ],
      ),
    );
  }
}
