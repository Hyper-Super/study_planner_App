import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int? _expandedFaq;

  final List<Map<String, String>> _faqs = [
    {
      'q': 'How do I add a new task?',
      'a':
          'Tap the "+" button on the Dashboard screen. Fill in the task title, subject, due date, and priority level, then tap Save. Your task will appear in the task list immediately.',
    },
    {
      'q': 'How does the AI Tutor work?',
      'a':
          'The AI Tutor (AI Edge screen) is powered by Google Gemini. Simply type any study question, choose a Quick Action, or tap a suggested prompt. The AI will respond in real time with explanations, quizzes, study plans, and more.',
    },
    {
      'q': 'Can I change the app theme?',
      'a':
          'Yes! Go to Profile → App Theme and pick from Lavender, Ocean, Rose, Forest, or Sunset. You can also toggle Dark Mode in the Settings section of your profile.',
    },
    {
      'q': 'How do I track my study sessions?',
      'a':
          'Use the built-in Pomodoro timer on the Dashboard. Start a session, study until the timer ends, and your hours are logged automatically. You can view your total hours in the Profile stats.',
    },
    {
      'q': 'How do I update my profile photo?',
      'a':
          'On the Profile screen, tap the small edit icon (pencil) on your avatar. You can choose a photo from your gallery, take a new one with your camera, or remove your existing photo.',
    },
    {
      'q': 'I forgot my password. What do I do?',
      'a':
          'On the Login screen, tap "Forgot Password?" and enter your email address. You will receive a reset link within a few minutes. Check your spam folder if it does not arrive.',
    },
    {
      'q': 'How do I delete my account?',
      'a':
          'Go to Profile → Delete Account. You will be asked to confirm. This permanently removes all your tasks, sessions, chat history, and account data. This action cannot be undone.',
    },
    {
      'q': 'Why is the AI not responding?',
      'a':
          'Check your internet connection. If you are connected but the AI is still not responding, the service may be temporarily busy — wait a moment and tap Retry. If the issue persists, restart the app.',
    },
    {
      'q': 'How do I enable study reminders?',
      'a':
          'Go to Profile → Settings and toggle "Study Reminders" on. Make sure you have granted notification permissions when prompted. You can also enable "Push Notifications" for task deadline reminders.',
    },
    {
      'q': 'Is my data secure?',
      'a':
          'Yes. Your data is stored securely using Firebase (Google Cloud). Passwords are never stored in plain text — Firebase Authentication handles secure login. See our Privacy Policy for full details.',
    },
  ];

  List<Map<String, String>> get _filteredFaqs {
    if (_searchQuery.isEmpty) return _faqs;
    return _faqs
        .where((faq) =>
            faq['q']!.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            faq['a']!.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
          'Help & Support',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppTheme.purpleGradient,
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
                  const Icon(Icons.support_agent_rounded,
                      color: Colors.white, size: 32),
                  const SizedBox(height: 10),
                  Text('How can we help?',
                      style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                  const SizedBox(height: 4),
                  Text('Find answers or contact our support team',
                      style: GoogleFonts.poppins(
                          fontSize: 13, color: Colors.white70)),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Search bar
            Container(
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.07)
                    : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.grey.shade200,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _searchQuery = v),
                style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: isDark
                        ? AppTheme.darkTextPrimary
                        : AppTheme.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Search FAQs...',
                  hintStyle: GoogleFonts.poppins(
                      fontSize: 13, color: AppTheme.textHint),
                  prefixIcon:
                      const Icon(Icons.search_rounded, color: AppTheme.textHint),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded,
                              color: AppTheme.textHint, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Quick contact buttons
            Text('Contact Us',
                style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppTheme.darkTextPrimary
                        : AppTheme.textPrimary)),
            const SizedBox(height: 12),
            Row(
              children: [
                _contactButton(
                  icon: Icons.email_outlined,
                  label: 'Email',
                  subtitle: 'support@studyplanner.app',
                  color: const Color(0xFF81D4FA),
                  isDark: isDark,
                ),
                const SizedBox(width: 12),
                _contactButton(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: 'Live Chat',
                  subtitle: 'Usually replies in minutes',
                  color: const Color(0xFFA5D6A7),
                  isDark: isDark,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // FAQ section
            Row(
              children: [
                Text('Frequently Asked Questions',
                    style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppTheme.darkTextPrimary
                            : AppTheme.textPrimary)),
                const Spacer(),
                if (_searchQuery.isNotEmpty)
                  Text('${_filteredFaqs.length} result(s)',
                      style: GoogleFonts.poppins(
                          fontSize: 11, color: AppTheme.accentPurple)),
              ],
            ),
            const SizedBox(height: 12),

            if (_filteredFaqs.isEmpty)
              _emptySearch(isDark)
            else
              ..._filteredFaqs.asMap().entries.map((e) {
                final idx = e.key;
                final faq = e.value;
                final isOpen = _expandedFaq == idx;
                return _faqItem(faq['q']!, faq['a']!, idx, isOpen, isDark);
              }),

            const SizedBox(height: 24),

            // Tips section
            _tipCard(isDark),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _contactButton({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required bool isDark,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _showComingSoon(label),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.07)
                : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : color.withValues(alpha: 0.3),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 10),
              Text(label,
                  style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppTheme.darkTextPrimary
                          : AppTheme.textPrimary)),
              Text(subtitle,
                  style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }

  Widget _faqItem(
      String question, String answer, int idx, bool isOpen, bool isDark) {
    return GestureDetector(
      onTap: () => setState(() => _expandedFaq = isOpen ? null : idx),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.07)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isOpen
                ? AppTheme.accentPurple.withValues(alpha: 0.4)
                : (isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.grey.shade100),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppTheme.accentPurple
                          .withValues(alpha: isOpen ? 0.2 : 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isOpen
                          ? Icons.remove_rounded
                          : Icons.add_rounded,
                      color: AppTheme.accentPurple,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      question,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppTheme.darkTextPrimary
                            : AppTheme.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (isOpen)
              Padding(
                padding:
                    const EdgeInsets.fromLTRB(56, 0, 16, 16),
                child: Text(
                  answer,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    height: 1.6,
                    color: isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.textSecondary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _emptySearch(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.search_off_rounded,
                size: 40,
                color: isDark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.textHint),
            const SizedBox(height: 10),
            Text('No results for "$_searchQuery"',
                style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _tipCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF81D4FA), Color(0xFF0288D1)],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Icon(Icons.lightbulb_rounded, color: Colors.white, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pro Tip',
                    style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
                const SizedBox(height: 2),
                Text(
                    'Use the AI Tutor for instant answers. It can generate quizzes, explain concepts, and build a study plan — all for free!',
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: Colors.white70, height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showComingSoon(String feature) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('$feature Support',
            style:
                GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        content: Text(
            'Our $feature support is coming soon! For now, check the FAQs above or use the AI Tutor for instant help.',
            style: GoogleFonts.poppins(fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Got it',
                style: GoogleFonts.poppins(
                    color: AppTheme.accentPurple,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
