import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/user_provider.dart';
import 'dashboard_screen.dart';

/// Onboarding — shown once after first sign-up.
/// Step 1 : Select education level.
/// Step 2 : Select subjects of interest.
///
/// ── UI is 100 % UNCHANGED ──
/// Backend changes:
///   • _nextPage  → calls UserProvider.saveOnboarding() on final step
///   • Skip       → saves whatever is selected (allows empty values)
///   • Loading spinner replaces "Get Started" text while saving
///   • Error snackbar on Firestore failure
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  String? _selectedClass;
  final List<String> _selectedInterests = [];

  late AnimationController _animController;
  late Animation<double> _fadeIn;

  final List<Map<String, dynamic>> _classes = [
    {'label': 'Year 2-9',   'icon': Icons.child_care_outlined,      'color': const Color(0xFF81D4FA)},
    {'label': 'Year 10-11', 'icon': Icons.school_outlined,           'color': const Color(0xFFCE93D8)},
    {'label': 'Year 12-13', 'icon': Icons.local_library_outlined,    'color': const Color(0xFFA5D6A7)},
    {'label': 'Bachelors',  'icon': Icons.menu_book_outlined,        'color': const Color(0xFFFFCC80)},
    {'label': 'Masters',    'icon': Icons.workspace_premium_outlined, 'color': const Color(0xFFF48FB1)},
    {'label': 'PhD',        'icon': Icons.psychology_outlined,       'color': const Color(0xFF80DEEA)},
  ];

  final List<Map<String, dynamic>> _interests = [
    {'label': 'Mathematics', 'icon': Icons.calculate_outlined,     'color': const Color(0xFFCE93D8)},
    {'label': 'Science',     'icon': Icons.science_outlined,       'color': const Color(0xFF81D4FA)},
    {'label': 'Literature',  'icon': Icons.auto_stories_outlined,  'color': const Color(0xFFA5D6A7)},
    {'label': 'History',     'icon': Icons.history_edu_outlined,   'color': const Color(0xFFFFCC80)},
    {'label': 'Languages',   'icon': Icons.translate_outlined,     'color': const Color(0xFFF48FB1)},
    {'label': 'Technology',  'icon': Icons.computer_outlined,      'color': const Color(0xFF80DEEA)},
    {'label': 'Art & Design','icon': Icons.palette_outlined,       'color': const Color(0xFFFFAB91)},
    {'label': 'Music',       'icon': Icons.music_note_outlined,    'color': const Color(0xFFB39DDB)},
    {'label': 'Sports',      'icon': Icons.sports_soccer_outlined, 'color': const Color(0xFF80CBC4)},
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeIn = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeIn),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animController.dispose();
    super.dispose();
  }

  // ── Navigation / save logic ────────────────────────────────────────────────

  Future<void> _nextPage() async {
    if (_currentPage < 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      await _saveAndNavigate();
    }
  }

  /// Called by "Get Started" and "Skip".
  Future<void> _saveAndNavigate() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    final success = await userProvider.saveOnboarding(
      educationLevel: _selectedClass ?? '',
      interests     : List<String>.from(_selectedInterests),
    );

    if (!mounted) return;

    if (success) {
      _goToDashboard();
    } else {
      _showSnack(userProvider.errorMessage ?? 'Failed to save. Please try again.');
    }
  }

  void _goToDashboard() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const DashboardScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.poppins(fontSize: 13)),
        backgroundColor: const Color(0xFF323232),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Listen only to isSaving so the button reacts to loading state
    final isSaving = context.select<UserProvider, bool>((p) => p.isSaving);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkMainGradient : AppTheme.mainGradient),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeIn,
            child: Column(
              children: [
                // ── Top bar — UNCHANGED ──────────────────────────────────
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      if (_currentPage > 0)
                        GestureDetector(
                          onTap: isSaving
                              ? null
                              : () => _pageController.previousPage(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                  ),
                          child: Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.arrow_back_ios_new_rounded,
                              size: 18, color: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkTextPrimary : AppTheme.textPrimary,
                            ),
                          ),
                        ),
                      const Spacer(),
                      GestureDetector(
                        onTap: isSaving ? null : _saveAndNavigate,
                        child: Text(
                          'Skip',
                          style: GoogleFonts.poppins(
                            color: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkTextSecondary : AppTheme.textSecondary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Page dots — UNCHANGED ────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: List.generate(2, (i) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(right: 6),
                        width: i == _currentPage ? 28 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: i == _currentPage
                              ? AppTheme.accentPurple
                              : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 24),

                // ── Pages — UNCHANGED ────────────────────────────────────
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: isSaving
                        ? const NeverScrollableScrollPhysics()
                        : const BouncingScrollPhysics(),
                    onPageChanged: (p) => setState(() => _currentPage = p),
                    children: [
                      _buildClassPage(),
                      _buildInterestsPage(),
                    ],
                  ),
                ),

                // ── Continue / Get Started button — UNCHANGED layout ─────
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: GestureDetector(
                    onTap: isSaving ? null : _nextPage,
                    child: Container(
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: AppTheme.purpleGradient,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.accentPurple.withValues(alpha: 0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Center(
                        child: isSaving
                            ? const SizedBox(
                                width: 24, height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2,
                                ),
                              )
                            : Text(
                                _currentPage == 0 ? 'Continue' : 'Get Started',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Page 1: Education level — UNCHANGED ───────────────────────────────────

  Widget _buildClassPage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Education level',
            style: GoogleFonts.poppins(
              fontSize: 24, fontWeight: FontWeight.w700, color: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkTextPrimary : AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Select your current study level',
            style: GoogleFonts.poppins(fontSize: 13, color: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkTextSecondary : AppTheme.textSecondary),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: _classes.length,
              itemBuilder: (context, i) {
                final item     = _classes[i];
                final selected = _selectedClass == item['label'];
                return GestureDetector(
                  onTap: () => setState(() => _selectedClass = item['label'] as String),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppTheme.accentPurple.withValues(alpha: 0.12)
                          : (Theme.of(context).brightness == Brightness.dark ? Colors.white.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.75)),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: selected ? AppTheme.accentPurple : (Theme.of(context).brightness == Brightness.dark ? Colors.white.withValues(alpha: 0.15) : Colors.grey.shade200),
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(
                            color: (item['color'] as Color).withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            item['icon'] as IconData,
                            color: item['color'] as Color, size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Text(
                          item['label'] as String,
                          style: GoogleFonts.poppins(
                            fontSize: 15, fontWeight: FontWeight.w500,
                            color: selected ? AppTheme.accentPurple : (Theme.of(context).brightness == Brightness.dark ? AppTheme.darkTextPrimary : AppTheme.textPrimary),
                          ),
                        ),
                        const Spacer(),
                        if (selected)
                          Container(
                            width: 22, height: 22,
                            decoration: const BoxDecoration(
                              color: AppTheme.accentPurple, shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.check_rounded, color: Colors.white, size: 14),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Page 2: Interests grid — UNCHANGED ───────────────────────────────────

  Widget _buildInterestsPage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Interests',
            style: GoogleFonts.poppins(
              fontSize: 24, fontWeight: FontWeight.w700, color: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkTextPrimary : AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Choose subjects you love to study',
            style: GoogleFonts.poppins(fontSize: 13, color: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkTextSecondary : AppTheme.textSecondary),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.9,
              ),
              itemCount: _interests.length,
              itemBuilder: (context, i) {
                final item     = _interests[i];
                final selected = _selectedInterests.contains(item['label']);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (selected) {
                        _selectedInterests.remove(item['label']);
                      } else {
                        _selectedInterests.add(item['label'] as String);
                      }
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    decoration: BoxDecoration(
                      color: selected
                          ? (item['color'] as Color).withValues(alpha: 0.2)
                          : (Theme.of(context).brightness == Brightness.dark ? Colors.white.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.75)),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: selected
                            ? (item['color'] as Color)
                            : (Theme.of(context).brightness == Brightness.dark ? Colors.white.withValues(alpha: 0.15) : Colors.grey.shade200),
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 48, height: 48,
                          decoration: BoxDecoration(
                            color: (item['color'] as Color).withValues(alpha: 0.25),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            item['icon'] as IconData,
                            color: item['color'] as Color, size: 24,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          item['label'] as String,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: selected
                                ? (item['color'] as Color)
                                : (Theme.of(context).brightness == Brightness.dark ? AppTheme.darkTextPrimary : AppTheme.textPrimary),
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
      ),
    );
  }
}
