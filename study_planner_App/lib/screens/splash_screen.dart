import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/user_provider.dart';
import 'login_screen.dart';
import 'dashboard_screen.dart';
import 'onboarding_screen.dart';

/// Splash screen — shows animation, then checks if user is already
/// logged in. If yes → Dashboard. If no → Login.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _bgController;

  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _textOpacity;
  late Animation<Offset> _textSlide;
  late Animation<double> _bgAnimation;

  @override
  void initState() {
    super.initState();

    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _bgAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _bgController, curve: Curves.easeInOut),
    );
    _logoScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );
    _logoOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeIn),
    );
    _textOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeIn),
    );
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _textController, curve: Curves.easeOut));

    _startAnimations();
  }

  Future<void> _startAnimations() async {
    // Run splash animations
    await _bgController.forward();
    await Future.delayed(const Duration(milliseconds: 200));
    await _logoController.forward();
    await Future.delayed(const Duration(milliseconds: 100));
    await _textController.forward();

    // While animating, check saved login in parallel
    if (!mounted) return;
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    await userProvider.checkLoginStatus();

    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;

    // Navigate based on saved login state
    Widget destination;
    if (userProvider.isLoggedIn) {
      // Logged in but never finished onboarding → send there first
      destination = userProvider.onboardingCompleted
          ? const DashboardScreen()
          : const OnboardingScreen();
    } else {
      destination = const LoginScreen();
    }

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => destination,
        transitionsBuilder: (_, anim, __, child) => FadeTransition(
          opacity: anim,
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _bgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _bgAnimation,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.lerp(Colors.white, const Color(0xFFE8EAF6), _bgAnimation.value)!,
                  Color.lerp(Colors.white, const Color(0xFFF3E5F5), _bgAnimation.value)!,
                  Color.lerp(Colors.white, const Color(0xFFE1F5FE), _bgAnimation.value)!,
                ],
              ),
            ),
            child: child,
          );
        },
        child: SafeArea(
          child: Stack(
            children: [
              // Decorative circles
              Positioned(
                top: -60, right: -60,
                child: _circle(200, const Color(0xFFCE93D8).withValues(alpha: 0.2)),
              ),
              Positioned(
                bottom: -80, left: -80,
                child: _circle(250, const Color(0xFF81D4FA).withValues(alpha: 0.2)),
              ),
              Positioned(
                top: 100, left: -40,
                child: _circle(120, const Color(0xFFF48FB1).withValues(alpha: 0.15)),
              ),

              // Logo + text
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: _logoController,
                      builder: (_, child) => Transform.scale(
                        scale: _logoScale.value,
                        child: Opacity(opacity: _logoOpacity.value, child: child),
                      ),
                      child: Container(
                        width: 110, height: 110,
                        decoration: BoxDecoration(
                          gradient: AppTheme.purpleGradient,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF9C64A6).withValues(alpha: 0.4),
                              blurRadius: 30,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.school_rounded, size: 56, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 28),
                    AnimatedBuilder(
                      animation: _textController,
                      builder: (_, child) => SlideTransition(
                        position: _textSlide,
                        child: Opacity(opacity: _textOpacity.value, child: child),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'STUDY SCHEDULE',
                            style: GoogleFonts.poppins(
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkTextPrimary : AppTheme.textPrimary,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Your smart learning companion',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkTextSecondary : AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Loading bar at bottom
              Positioned(
                bottom: 60, left: 0, right: 0,
                child: AnimatedBuilder(
                  animation: _textController,
                  builder: (_, child) => Opacity(opacity: _textOpacity.value, child: child),
                  child: Center(
                    child: SizedBox(
                      width: 40, height: 4,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: const LinearProgressIndicator(
                          backgroundColor: Color(0xFFE0E0E0),
                          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentPurple),
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

  Widget _circle(double size, Color color) => Container(
    width: size, height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
  );
}
