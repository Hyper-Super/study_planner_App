import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';

import '../theme/app_theme.dart';
import '../providers/user_provider.dart';
import 'login_screen.dart';
import 'help_support_screen.dart';
import 'privacy_policy_screen.dart';
import 'about_app_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final List<Map<String, dynamic>> _themes = [
    {'name': 'Lavender', 'color': const Color(0xFF9B8EC4)},
    {'name': 'Ocean',    'color': const Color(0xFF0288D1)},
    {'name': 'Rose',     'color': const Color(0xFFE91E8C)},
    {'name': 'Forest',   'color': const Color(0xFF388E3C)},
    {'name': 'Sunset',   'color': const Color(0xFFE64A19)},
  ];

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final selectedTheme = userProvider.selectedThemeIndex;

    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _buildHeader(userProvider),
              const SizedBox(height: 20),
              _buildStats(userProvider),
              const SizedBox(height: 20),
              _buildThemeSection(selectedTheme, userProvider),
              const SizedBox(height: 20),
              _buildSettings(userProvider),
              const SizedBox(height: 20),
              _buildAccount(context, userProvider),
              const SizedBox(height: 80),
            ],
          ),
        ),

        // ── Global loading overlay ─────────────────────────────────────────
        if (userProvider.isUploadingImage)
          Container(
            color: Colors.black26,
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 12),
                  Text('Uploading photo…',
                      style: TextStyle(color: Colors.white, fontSize: 14)),
                ],
              ),
            ),
          ),

        // ── Success / error snackbar-style banner ─────────────────────────
        if (userProvider.successMessage != null)
          Positioned(
            top: 12, left: 20, right: 20,
            child: _StatusBanner(
              message: userProvider.successMessage!,
              isError: false,
            ),
          ),
        if (userProvider.errorMessage != null)
          Positioned(
            top: 12, left: 20, right: 20,
            child: _StatusBanner(
              message: userProvider.errorMessage!,
              isError: true,
              onDismiss: () => userProvider.clearError(),
            ),
          ),
      ],
    );
  }

  // ── Header ───────────────────────────────────────────────────────────────

  Widget _buildHeader(UserProvider userProvider) {
    final name  = userProvider.user?.name ?? 'Student';
    final email = userProvider.user?.email ?? 'user@studyplanner.com';
    final avatarUrl = userProvider.user?.avatarUrl;

    return _GCard(
      child: Column(
        children: [
          Stack(
            children: [
              // Avatar
              Container(
                width: 88, height: 88,
                decoration: BoxDecoration(
                  gradient: AppTheme.purpleGradient, shape: BoxShape.circle,
                  boxShadow: [BoxShadow(
                    color: AppTheme.accentPurple.withValues(alpha: 0.4),
                    blurRadius: 20, offset: const Offset(0, 6),
                  )],
                ),
                child: ClipOval(
                  child: avatarUrl != null
                      ? Image.network(
                          avatarUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.person_rounded, color: Colors.white, size: 44),
                        )
                      : const Icon(Icons.person_rounded, color: Colors.white, size: 44),
                ),
              ),

              // Edit badge
              Positioned(
                bottom: 2, right: 2,
                child: GestureDetector(
                  onTap: () => _showImageOptions(context, userProvider),
                  child: Container(
                    width: 24, height: 24,
                    decoration: BoxDecoration(
                      gradient: AppTheme.pinkGradient, shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.edit_rounded, color: Colors.white, size: 12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(name,
              style: GoogleFonts.poppins(
                  fontSize: 20, fontWeight: FontWeight.w700, color: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkTextPrimary : AppTheme.textPrimary)),
          Text(email,
              style: GoogleFonts.poppins(fontSize: 13, color: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkTextSecondary : AppTheme.textSecondary)),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _showEditProfile(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentPurple, foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text('Edit Profile',
                  style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Stats ────────────────────────────────────────────────────────────────

  Widget _buildStats(UserProvider userProvider) {
    final streak = userProvider.user?.studyStreak ?? 12;
    final hours  = userProvider.user?.totalHours  ?? 156;
    final score  = userProvider.user?.score       ?? 84.0;

    return Row(
      children: [
        _statCard('$streak', 'Day Streak', Icons.local_fire_department_rounded, const Color(0xFFFFB300)),
        const SizedBox(width: 12),
        _statCard('$hours',  'Hours',      Icons.schedule_rounded,              const Color(0xFF81D4FA)),
        const SizedBox(width: 12),
        _statCard('${score.toStringAsFixed(0)}%', 'Score', Icons.stars_rounded, const Color(0xFFCE93D8)),
      ],
    );
  }

  Widget _statCard(String value, String label, IconData icon, Color color) {
    return Expanded(
      child: _GCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(value,
                style: GoogleFonts.poppins(
                    fontSize: 18, fontWeight: FontWeight.w700, color: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkTextPrimary : AppTheme.textPrimary)),
            Text(label,
                style: GoogleFonts.poppins(fontSize: 11, color: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkTextSecondary : AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }

  // ── Theme section ─────────────────────────────────────────────────────────

  Widget _buildThemeSection(int selected, UserProvider userProvider) {
    return _GCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('App Theme',
              style: GoogleFonts.poppins(
                  fontSize: 15, fontWeight: FontWeight.w600, color: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkTextPrimary : AppTheme.textPrimary)),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_themes.length, (i) {
              final isSel = selected == i;
              final isDark = Theme.of(context).brightness == Brightness.dark;
              return GestureDetector(
                onTap: () => userProvider.setTheme(i),
                child: Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: _themes[i]['color'] as Color,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: isSel ? (isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary) : Colors.transparent,
                            width: 3),
                        boxShadow: isSel
                            ? [BoxShadow(
                                color: (_themes[i]['color'] as Color).withValues(alpha: 0.4),
                                blurRadius: 10, offset: const Offset(0, 4))]
                            : null,
                      ),
                      child: isSel
                          ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
                          : null,
                    ),
                    const SizedBox(height: 6),
                    Text(_themes[i]['name'] as String,
                        style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: isSel ? FontWeight.w600 : FontWeight.w400,
                            color: isSel ? (isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary) : (isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary))),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // ── Settings ──────────────────────────────────────────────────────────────

  Widget _buildSettings(UserProvider userProvider) {
    return _GCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Settings',
              style: GoogleFonts.poppins(
                  fontSize: 15, fontWeight: FontWeight.w600, color: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkTextPrimary : AppTheme.textPrimary)),
          const SizedBox(height: 14),
          _toggle(
            Icons.notifications_outlined,
            'Push Notifications',
            'Get task reminders',
            userProvider.notificationsEnabled,
            const Color(0xFFCE93D8),
            (v) => userProvider.toggleNotifications(v),
          ),
          Divider(color: Colors.grey.shade100),
          _toggle(
            Icons.dark_mode_outlined,
            'Dark Mode',
            'Switch to dark theme',
            userProvider.isDarkMode,
            const Color(0xFF5B8EBF),
            (v) => userProvider.toggleDarkMode(v),
          ),
          Divider(color: Colors.grey.shade100),
          _toggle(
            Icons.alarm_outlined,
            'Study Reminders',
            'Daily study alerts',
            userProvider.studyRemindersEnabled,
            const Color(0xFFA5D6A7),
            (v) => userProvider.toggleStudyReminders(v),
          ),
        ],
      ),
    );
  }

  Widget _toggle(IconData icon, String label, String sub, bool val, Color color,
      void Function(bool) onChange) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.poppins(
                        fontSize: 14, fontWeight: FontWeight.w500, color: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkTextPrimary : AppTheme.textPrimary)),
                Text(sub,
                    style: GoogleFonts.poppins(fontSize: 11, color: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkTextSecondary : AppTheme.textSecondary)),
              ],
            ),
          ),
          Switch(
            value: val,
            onChanged: onChange,
            activeColor: AppTheme.accentPurple,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }

  // ── Account section ───────────────────────────────────────────────────────

  Widget _buildAccount(BuildContext context, UserProvider userProvider) {
    final items = [
      {'icon': Icons.help_outline_rounded,    'label': 'Help & Support',  'color': const Color(0xFF81D4FA),  'action': 'help'},
      {'icon': Icons.privacy_tip_outlined,    'label': 'Privacy Policy',  'color': const Color(0xFFCE93D8),  'action': 'privacy'},
      {'icon': Icons.info_outline_rounded,    'label': 'About App',       'color': const Color(0xFFA5D6A7),  'action': 'about'},
      {'icon': Icons.logout_rounded,          'label': 'Sign Out',        'color': const Color(0xFFF48FB1),  'action': 'logout'},
      {'icon': Icons.delete_outline_rounded,  'label': 'Delete Account',  'color': const Color(0xFFEF5350),  'action': 'delete'},
    ];

    return _GCard(
      child: Column(
        children: items.asMap().entries.map((e) {
          final item   = e.value;
          final isLast = e.key == items.length - 1;
          final action = item['action'] as String;
          final isDestructive = action == 'logout' || action == 'delete';

          return Column(
            children: [
              GestureDetector(
                onTap: () => _handleAccountAction(context, userProvider, action),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                            color: (item['color'] as Color).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12)),
                        child: Icon(item['icon'] as IconData,
                            color: item['color'] as Color, size: 20),
                      ),
                      const SizedBox(width: 14),
                      Text(
                        item['label'] as String,
                        style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: isDestructive
                                ? item['color'] as Color
                                : (Theme.of(context).brightness == Brightness.dark ? AppTheme.darkTextPrimary : AppTheme.textPrimary)),
                      ),
                      const Spacer(),
                      if (!isDestructive)
                        Icon(Icons.chevron_right_rounded,
                            color: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkTextSecondary : AppTheme.textHint, size: 20),
                    ],
                  ),
                ),
              ),
              if (!isLast) Divider(color: Colors.grey.shade100),
            ],
          );
        }).toList(),
      ),
    );
  }

  Future<void> _handleAccountAction(
      BuildContext context, UserProvider userProvider, String action) async {
    switch (action) {
      case 'logout':
        final confirm = await _showConfirmDialog(
          context,
          title: 'Sign Out',
          message: 'Are you sure you want to sign out?',
          confirmLabel: 'Sign Out',
          confirmColor: const Color(0xFFF48FB1),
        );
        if (confirm == true && context.mounted) {
          await userProvider.logout();
          if (context.mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const LoginScreen()),
              (_) => false,
            );
          }
        }
        break;

      case 'delete':
        final confirm = await _showDeleteAccountDialog(context);
        if (confirm == true && context.mounted) {
          final err = await userProvider.deleteAccount();
          if (err != null && context.mounted) {
            _showSnack(context, err, isError: true);
          } else if (context.mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const LoginScreen()),
              (_) => false,
            );
          }
        }
        break;

      case 'help':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const HelpSupportScreen()),
        );
        break;

      case 'privacy':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
        );
        break;

      case 'about':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AboutAppScreen()),
        );
        break;

      default:
        break;
    }
  }

  // ── Edit profile sheet ────────────────────────────────────────────────────

  void _showEditProfile(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final nameCtrl  = TextEditingController(text: userProvider.user?.name ?? '');
    final emailCtrl = TextEditingController(text: userProvider.user?.email ?? '');
    bool saving = false;

    showModalBottomSheet(
      context: context,
      backgroundColor: null,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Edit Profile',
                    style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkTextPrimary : AppTheme.textPrimary)),
                const SizedBox(height: 20),
                _editField('Full Name', nameCtrl),
                const SizedBox(height: 12),
                _editField('Email (cannot be changed)', emailCtrl, enabled: false),
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 2),
                  child: Row(
                    children: [
                      const Icon(Icons.lock_outline_rounded, size: 12, color: AppTheme.textHint),
                      const SizedBox(width: 4),
                      Text('Email is linked to your account and cannot be edited',
                          style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textHint)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: saving
                      ? null
                      : () async {
                          setLocalState(() => saving = true);
                          final ok =
                              await userProvider.updateName(nameCtrl.text.trim());
                          if (ctx.mounted) {
                            Navigator.pop(ctx);
                            if (!ok) {
                              _showSnack(context,
                                  userProvider.errorMessage ?? 'Update failed',
                                  isError: true);
                            }
                          }
                        },
                  child: Container(
                    width: double.infinity, height: 50,
                    decoration: BoxDecoration(
                        gradient: AppTheme.purpleGradient,
                        borderRadius: BorderRadius.circular(14)),
                    child: Center(
                      child: saving
                          ? const SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : Text('Save Changes',
                              style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _editField(String label, TextEditingController ctrl,
      {bool enabled = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.poppins(
                fontSize: 12, fontWeight: FontWeight.w500, color: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkTextSecondary : AppTheme.textSecondary)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          enabled: enabled,
          style: GoogleFonts.poppins(fontSize: 14, color: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkTextPrimary : AppTheme.textPrimary),
          decoration: InputDecoration(
            filled: true,
            fillColor: enabled
                ? (Theme.of(context).brightness == Brightness.dark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade50)
                : (Theme.of(context).brightness == Brightness.dark ? Colors.white.withValues(alpha: 0.04) : Colors.grey.shade100),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200)),
            disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }

  // ── Photo picker ──────────────────────────────────────────────────────────

  void _showImageOptions(BuildContext context, UserProvider userProvider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: null,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: Color(0xFF9B8EC4)),
              title: Text('Choose from Gallery',
                  style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500)),
              onTap: () {
                Navigator.pop(context);
                _pickImage(context, userProvider, ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded, color: Color(0xFF0288D1)),
              title: Text('Take a Photo',
                  style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500)),
              onTap: () {
                Navigator.pop(context);
                _pickImage(context, userProvider, ImageSource.camera);
              },
            ),
            if (userProvider.user?.avatarUrl != null)
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF5350)),
                title: Text('Remove Photo',
                    style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFFEF5350))),
                onTap: () async {
                  Navigator.pop(context);
                  await userProvider.removeProfileImage();
                },
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(
      BuildContext context, UserProvider userProvider, ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
          source: source, maxWidth: 512, maxHeight: 512, imageQuality: 80);
      if (picked == null) return;
      await userProvider.uploadProfileImage(File(picked.path));
    } catch (e) {
      if (context.mounted) {
        _showSnack(context, 'Could not pick image. Please try again.',
            isError: true);
      }
    }
  }

  // ── Dialogs ───────────────────────────────────────────────────────────────

  Future<bool?> _showConfirmDialog(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
    required Color confirmColor,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title,
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        content:
            Text(message, style: GoogleFonts.poppins()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel',
                style: GoogleFonts.poppins(color: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkTextSecondary : AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmLabel,
                style: GoogleFonts.poppins(
                    color: confirmColor, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showDeleteAccountDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Account',
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700, color: const Color(0xFFEF5350))),
        content: Text(
          'This will permanently delete your account, all tasks, sessions, and data. This action cannot be undone.',
          style: GoogleFonts.poppins(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child:
                Text('Cancel', style: GoogleFonts.poppins(color: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkTextSecondary : AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete',
                style: GoogleFonts.poppins(
                    color: const Color(0xFFEF5350), fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _showSnack(BuildContext context, String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.poppins(fontSize: 13)),
      backgroundColor: isError ? const Color(0xFFEF5350) : const Color(0xFF388E3C),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }
}

// ── Glass card ────────────────────────────────────────────────────────────────

class _GCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  const _GCard({required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.07)
            : Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.white.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
              blurRadius: 15,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(16),
        child: child,
      ),
    );
  }
}

// ── Status banner ─────────────────────────────────────────────────────────────

class _StatusBanner extends StatelessWidget {
  final String message;
  final bool isError;
  final VoidCallback? onDismiss;

  const _StatusBanner({
    required this.message,
    required this.isError,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isError ? const Color(0xFFEF5350) : const Color(0xFF388E3C),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
              color: Colors.white, size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(message,
                  style: GoogleFonts.poppins(
                      fontSize: 13, color: Colors.white, fontWeight: FontWeight.w500)),
            ),
            if (onDismiss != null)
              GestureDetector(
                onTap: onDismiss,
                child: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
              ),
          ],
        ),
      ),
    );
  }
}
