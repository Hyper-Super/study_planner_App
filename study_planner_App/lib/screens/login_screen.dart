import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/user_provider.dart';
import 'onboarding_screen.dart';
import 'dashboard_screen.dart';

/// Login / Sign-Up screen.
/// ── UI is UNCHANGED from the original design ──
/// Backend changes:
///   • _handleGoogleSignIn   → UserProvider.signInWithGoogle()
///   • _handleAppleSignIn    → UserProvider.signInWithApple()
///   • _handleLogin          → UserProvider.login()
///   • _handleSignUp         → UserProvider.signUp()
///   • _handleForgotPassword → UserProvider.resetPassword()
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLogin = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeIn = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.4), end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ── Snackbar helper ────────────────────────────────────────────────────────

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

  // ── Navigation helpers ─────────────────────────────────────────────────────

  void _goToDashboard() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const DashboardScreen(),
        transitionsBuilder: (_, anim, __, child) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0), end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  void _goToOnboarding() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const OnboardingScreen(),
        transitionsBuilder: (_, anim, __, child) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0), end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  // ── Auth handlers ──────────────────────────────────────────────────────────

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showSnack('Please enter email and password');
      return;
    }
    if (!_isValidEmail(email)) {
      _showSnack('Please enter a valid email address');
      return;
    }

    setState(() => _isLoading = true);
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    final success = await userProvider.login(email: email, password: password);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      _goToDashboard();
    } else {
      _showSnack(userProvider.errorMessage ?? 'Login failed');
    }
  }

  Future<void> _handleSignUp() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (name.isEmpty) {
      _showSnack('Please enter your name');
      return;
    }
    if (email.isEmpty || !_isValidEmail(email)) {
      _showSnack('Please enter a valid email address');
      return;
    }
    if (password.length < 6) {
      _showSnack('Password must be at least 6 characters');
      return;
    }

    setState(() => _isLoading = true);
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    final success =
        await userProvider.signUp(name: name, email: email, password: password);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      _goToOnboarding();
    } else {
      _showSnack(userProvider.errorMessage ?? 'Sign up failed');
    }
  }
  //
  // Future<void> _handleGoogleSignIn() async {
  //   setState(() => _isLoading = true);
  //   final userProvider = Provider.of<UserProvider>(context, listen: false);
  //
  //   final success = await userProvider.signInWithGoogle();
  //
  //   if (!mounted) return;
  //   setState(() => _isLoading = false);
  //
  //   if (success) {
  //     // Existing Google account → dashboard; new account → onboarding
  //     // We detect "new" by checking if createdAt is within the last 10 seconds.
  //     final user = userProvider.user;
  //     final isNew = user?.createdAt != null &&
  //         DateTime.now().difference(user!.createdAt!).inSeconds < 10;
  //     isNew ? _goToOnboarding() : _goToDashboard();
  //   } else {
  //     final err = userProvider.errorMessage ?? '';
  //     if (err.isNotEmpty && !err.contains('cancelled')) {
  //       _showSnack(err);
  //     }
  //   }
  // }

  Future<void> _handleAppleSignIn() async {
    setState(() => _isLoading = true);
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    final success = await userProvider.signInWithApple();

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      final user = userProvider.user;
      final isNew = user?.createdAt != null &&
          DateTime.now().difference(user!.createdAt!).inSeconds < 10;
      isNew ? _goToOnboarding() : _goToDashboard();
    } else {
      final err = userProvider.errorMessage ?? '';
      if (err.isNotEmpty && !err.contains('cancelled')) {
        _showSnack(err);
      }
    }
  }

  Future<void> _handleForgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showSnack('Enter your email first to reset password');
      return;
    }
    if (!_isValidEmail(email)) {
      _showSnack('Please enter a valid email address');
      return;
    }

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final success = await userProvider.resetPassword(email);
    if (!mounted) return;

    if (success) {
      _showSnack('Password reset email sent! Check your inbox.');
    } else {
      _showSnack(userProvider.errorMessage ?? 'Failed to send reset email');
    }
  }

  bool _isValidEmail(String email) =>
      RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkMainGradient : AppTheme.mainGradient),
        child: SafeArea(
          child: Stack(
            children: [
              // Decorative circles — UNCHANGED
              Positioned(
                top: -30, right: -30,
                child: Container(
                  width: 200, height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.primaryPurple.withValues(alpha: 0.25),
                  ),
                ),
              ),
              Positioned(
                top: 20, left: -50,
                child: Container(
                  width: 150, height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.primaryBlue.withValues(alpha: 0.2),
                  ),
                ),
              ),

              // Logo + title — UNCHANGED
              Positioned(
                top: 40, left: 0, right: 0,
                child: FadeTransition(
                  opacity: _fadeIn,
                  child: Column(
                    children: [
                      Container(
                        width: 60, height: 60,
                        decoration: BoxDecoration(
                          gradient: AppTheme.purpleGradient,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(Icons.school_rounded,
                            color: Colors.white, size: 32),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'STUDY SCHEDULE',
                        style: GoogleFonts.poppins(
                          fontSize: 18, fontWeight: FontWeight.w700,
                          color: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkTextPrimary : AppTheme.textPrimary, letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Your smart learning companion',
                        style: GoogleFonts.poppins(
                            fontSize: 12, color: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkTextSecondary : AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),

              // Form card — UNCHANGED layout, backend wired
              Align(
                alignment: Alignment.bottomCenter,
                child: FadeTransition(
                  opacity: _fadeIn,
                  child: SlideTransition(
                    position: _slideUp,
                    child: Container(
                      margin: const EdgeInsets.only(top: 200),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.95),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(32),
                          topRight: Radius.circular(32),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 30, offset: const Offset(0, -5),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(28, 28, 28, 20),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isLogin ? 'Welcome back 👋' : 'Create Account',
                                style: GoogleFonts.poppins(
                                  fontSize: 24, fontWeight: FontWeight.w700,
                                  color: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkTextPrimary : AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _isLogin
                                    ? 'Sign in to continue learning'
                                    : 'Start your learning journey today',
                                style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkTextSecondary : AppTheme.textSecondary),
                              ),
                              const SizedBox(height: 24),

                              // Name field — sign up only
                              if (!_isLogin) ...[
                                _buildTextField(
                                  controller: _nameController,
                                  hint: 'Full Name',
                                  icon: Icons.person_outline,
                                ),
                                const SizedBox(height: 14),
                              ],

                              // Email
                              _buildTextField(
                                controller: _emailController,
                                hint: 'Email Address',
                                icon: Icons.email_outlined,
                                keyboardType: TextInputType.emailAddress,
                              ),
                              const SizedBox(height: 14),

                              // Password
                              _buildTextField(
                                controller: _passwordController,
                                hint: 'Password',
                                icon: Icons.lock_outline,
                                isPassword: true,
                              ),

                              // Forgot password
                              if (_isLogin) ...[
                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: GestureDetector(
                                    onTap: _handleForgotPassword,
                                    child: Text(
                                      'Forgot Password?',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: AppTheme.accentPurple,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                              ],

                              const SizedBox(height: 24),

                              // Main action button — UNCHANGED
                              GestureDetector(
                                onTap: _isLoading
                                    ? null
                                    : (_isLogin ? _handleLogin : _handleSignUp),
                                child: Container(
                                  width: double.infinity, height: 56,
                                  decoration: BoxDecoration(
                                    gradient: AppTheme.purpleGradient,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme.accentPurple
                                            .withValues(alpha: 0.4),
                                        blurRadius: 20,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: _isLoading
                                        ? const SizedBox(
                                            width: 24, height: 24,
                                            child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2),
                                          )
                                        : Text(
                                            _isLogin ? 'Sign In' : 'Sign Up',
                                            style: GoogleFonts.poppins(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                            ),
                                          ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 20),



                              const SizedBox(height: 20),

                              // Toggle login / signup — UNCHANGED
                              Center(
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _isLogin = !_isLogin;
                                      _emailController.clear();
                                      _passwordController.clear();
                                      _nameController.clear();
                                    });
                                  },
                                  child: RichText(
                                    text: TextSpan(
                                      style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          color: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkTextSecondary : AppTheme.textSecondary),
                                      children: [
                                        TextSpan(
                                          text: _isLogin
                                              ? "Don't have an account? "
                                              : "Already have an account? ",
                                        ),
                                        TextSpan(
                                          text: _isLogin ? 'Sign Up' : 'Sign In',
                                          style: const TextStyle(
                                            color: AppTheme.accentPurple,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                          ),
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
    );
  }

  // ── TextField builder — UNCHANGED ──────────────────────────────────────────

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword ? _obscurePassword : false,
        keyboardType: keyboardType,
        style: GoogleFonts.poppins(fontSize: 14, color: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkTextPrimary : AppTheme.textPrimary),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.poppins(color: AppTheme.textHint, fontSize: 14),
          prefixIcon: Icon(icon, color: AppTheme.textHint, size: 20),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: AppTheme.textHint,
                    size: 20,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                )
              : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  // ── Google SVG icon (inline — no asset needed) ─────────────────────────────
  Widget _googleIcon() => SizedBox(
        width: 20,
        height: 20,
        child: CustomPaint(painter: _GoogleIconPainter()),
      );
}

// ── Social button widget ───────────────────────────────────────────────────────

class _SocialButton extends StatelessWidget {
  final String label;
  final Widget icon;
  final VoidCallback? onTap;

  const _SocialButton({
    required this.label,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkTextPrimary : AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Google "G" logo painter (no SVG asset required) ────────────────────────────

class _GoogleIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;

    // Background circle
    final bgPaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(cx, cy), r, bgPaint);

    // Four Google colour segments (simplified)
    final paint = Paint()..style = PaintingStyle.fill;
    final segments = [
      (const Color(0xFF4285F4), -1.57, 0.79),  // blue top-right
      (const Color(0xFF34A853),  0.79, 2.36),  // green bottom-right
      (const Color(0xFFFBBC05),  2.36, 3.14),  // yellow bottom-left
      (const Color(0xFFEA4335), -3.14, -1.57), // red top-left
    ];

    for (final (color, start, end) in segments) {
      paint.color = color;
      final path = Path()
        ..moveTo(cx, cy)
        ..arcTo(Rect.fromCircle(center: Offset(cx, cy), radius: r * 0.9),
            start, end - start, false)
        ..close();
      canvas.drawPath(path, paint);
    }

    // White inner circle (donut effect)
    canvas.drawCircle(Offset(cx, cy), r * 0.55, bgPaint);

    // Blue right bar (the horizontal part of the "G")
    paint.color = const Color(0xFF4285F4);
    canvas.drawRect(
      Rect.fromLTWH(cx, cy - r * 0.18, r * 0.9, r * 0.36),
      paint,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}
