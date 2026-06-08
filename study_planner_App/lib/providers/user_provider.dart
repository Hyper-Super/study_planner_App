import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/onboarding_service.dart';
import '../services/profile_service.dart';
import '../services/notification_service.dart';

/// Central state holder for authentication + user preferences + onboarding.
class UserProvider extends ChangeNotifier {
  final AuthService       _authService       = AuthService();
  final OnboardingService _onboardingService = OnboardingService();
  final ProfileService    _profileService    = ProfileService();

  UserModel? _user;
  bool _isLoggedIn          = false;
  bool _isLoading           = true;
  bool _isSaving            = false;
  bool _isUploadingImage    = false;
  bool _onboardingCompleted = false;
  String? _errorMessage;
  String? _successMessage;

  StreamSubscription<User?>?      _authSub;
  StreamSubscription<UserModel?>? _userSub;

  static const String _keyThemeIndex = 'theme_index';

  // ── Getters ───────────────────────────────────────────────────────────────

  UserModel? get user               => _user;
  bool get isLoggedIn               => _isLoggedIn;
  bool get isLoading                => _isLoading;
  bool get isSaving                 => _isSaving;
  bool get isUploadingImage         => _isUploadingImage;
  bool get onboardingCompleted      => _onboardingCompleted;
  String? get errorMessage          => _errorMessage;
  String? get successMessage        => _successMessage;

  int  get selectedThemeIndex       => _user?.selectedThemeIndex ?? 0;
  bool get isDarkMode               => _user?.darkModeEnabled ?? false;
  bool get notificationsEnabled     => _user?.notificationsEnabled ?? true;
  bool get studyRemindersEnabled    => _user?.studyRemindersEnabled ?? true;

  static const List<Color> themeColors = [
    Color(0xFF9B8EC4),
    Color(0xFF0288D1),
    Color(0xFFE91E8C),
    Color(0xFF388E3C),
    Color(0xFFE64A19),
  ];

  Color get accentColor => themeColors[selectedThemeIndex];

  // ── Initialisation ────────────────────────────────────────────────────────

  Future<void> checkLoginStatus() async {
    // Pre-load theme from local prefs for instant startup (before Firestore)
    final prefs = await SharedPreferences.getInstance();
    final localTheme = prefs.getInt(_keyThemeIndex) ?? 0;

    final firebaseUser = _authService.currentUser;
    if (firebaseUser != null) {
      try {
        final fetched = await _profileService.fetchUser(firebaseUser.uid);
        if (fetched != null) {
          _user = fetched;
        } else {
          _user = UserModel(
            id: firebaseUser.uid,
            name: firebaseUser.displayName ?? 'Student',
            email: firebaseUser.email ?? '',
            avatarUrl: firebaseUser.photoURL,
            selectedThemeIndex: localTheme,
          );
          await _profileService.ensureUserDocument(_user!);
        }
      } catch (_) {
        _user = UserModel(
          id: firebaseUser.uid,
          name: firebaseUser.displayName ?? 'Student',
          email: firebaseUser.email ?? '',
          selectedThemeIndex: localTheme,
        );
      }
      _isLoggedIn = true;
      _onboardingCompleted = await _onboardingService.isOnboardingCompleted(
        uid: firebaseUser.uid,
      );
      _subscribeToUserStream(firebaseUser.uid);
    }

    _isLoading = false;
    notifyListeners();

    _authSub = _authService.authStateChanges.listen(_onAuthStateChanged);
  }

  void _onAuthStateChanged(User? firebaseUser) {
    if (firebaseUser == null) {
      _userSub?.cancel();
      _user = null;
      _isLoggedIn = false;
      _onboardingCompleted = false;
      notifyListeners();
    }
  }

  /// Subscribe to real-time Firestore updates for the user document.
  void _subscribeToUserStream(String uid) {
    _userSub?.cancel();
    _userSub = _profileService.userStream(uid).listen((updatedUser) {
      if (updatedUser != null) {
        _user = updatedUser;
        // Keep local prefs in sync with Firestore theme
        SharedPreferences.getInstance().then(
          (p) => p.setInt(_keyThemeIndex, updatedUser.selectedThemeIndex),
        );
        // Re-sync notifications when user document changes
        NotificationService.instance.init().then((_) {
          if (updatedUser.notificationsEnabled && updatedUser.studyRemindersEnabled) {
            NotificationService.instance.scheduleStudyReminders();
          }
        });
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _userSub?.cancel();
    super.dispose();
  }

  // ── Onboarding ────────────────────────────────────────────────────────────

  Future<bool> saveOnboarding({
    required String educationLevel,
    required List<String> interests,
  }) async {
    if (_user == null) {
      _errorMessage = 'No user session found. Please log in again.';
      notifyListeners();
      return false;
    }

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _onboardingService.saveOnboarding(
        uid: _user!.id,
        educationLevel: educationLevel,
        interests: interests,
      );
      _user = _user!.copyWith(
        educationLevel: educationLevel,
        interests: interests,
      );
      _onboardingCompleted = true;
      _isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to save your profile. Please try again.';
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  // ── Auth ──────────────────────────────────────────────────────────────────

  Future<bool> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    return _run(() async {
      _user = await _authService.signUpWithEmail(
        name: name, email: email, password: password,
      );
      _isLoggedIn = true;
      _onboardingCompleted = false;
      _subscribeToUserStream(_user!.id);
    });
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    return _run(() async {
      _user = await _authService.signInWithEmail(email: email, password: password);
      _isLoggedIn = true;
      _onboardingCompleted = await _onboardingService.isOnboardingCompleted(
        uid: _user!.id,
      );
      _subscribeToUserStream(_user!.id);
    });
  }

  Future<bool> signInWithGoogle() async {
    return _run(() async {
      _user = await _authService.signInWithGoogle();
      _isLoggedIn = true;
      _onboardingCompleted = await _onboardingService.isOnboardingCompleted(
        uid: _user!.id,
      );
      _subscribeToUserStream(_user!.id);
    });
  }

  Future<bool> signInWithApple() async {
    return _run(() async {
      _user = await _authService.signInWithApple();
      _isLoggedIn = true;
      _onboardingCompleted = await _onboardingService.isOnboardingCompleted(
        uid: _user!.id,
      );
      _subscribeToUserStream(_user!.id);
    });
  }

  Future<bool> resetPassword(String email) async {
    try {
      _errorMessage = null;
      await _authService.sendPasswordResetEmail(email);
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = AuthService.friendlyError(e);
      notifyListeners();
      return false;
    } catch (_) {
      _errorMessage = 'Failed to send reset email. Please try again.';
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _userSub?.cancel();
    await _authService.signOut();
    await _onboardingService.clearCache();
    _user = null;
    _isLoggedIn = false;
    _onboardingCompleted = false;
    notifyListeners();
  }

  // ── Profile editing ───────────────────────────────────────────────────────

  /// Updates the display name in Firestore + Firebase Auth.
  Future<bool> updateName(String name) async {
    if (_user == null || name.trim().isEmpty) return false;
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _profileService.updateName(_user!.id, name.trim());
      _user = _user!.copyWith(name: name.trim());
      _isSaving = false;
      _successMessage = 'Profile updated successfully!';
      notifyListeners();
      _clearSuccessAfterDelay();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update name. Please try again.';
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  /// Uploads a profile image to Firebase Storage and persists the URL.
  Future<bool> uploadProfileImage(File imageFile) async {
    if (_user == null) return false;
    _isUploadingImage = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final url = await _profileService.uploadProfileImage(_user!.id, imageFile);
      _user = _user!.copyWith(avatarUrl: url);
      _isUploadingImage = false;
      _successMessage = 'Photo updated!';
      notifyListeners();
      _clearSuccessAfterDelay();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to upload photo. Please try again.';
      _isUploadingImage = false;
      notifyListeners();
      return false;
    }
  }

  /// Removes the profile photo.
  Future<bool> removeProfileImage() async {
    if (_user == null) return false;
    try {
      await _profileService.deleteProfileImage(_user!.id);
      _user = _user!.copyWith(clearAvatar: true);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to remove photo.';
      notifyListeners();
      return false;
    }
  }

  void updateStats({int? streak, int? hours}) {
    if (_user == null) return;
    _user = _user!.copyWith(studyStreak: streak, totalHours: hours);
    notifyListeners();
  }

  // ── Theme ─────────────────────────────────────────────────────────────────

  Future<void> setTheme(int index) async {
    if (_user == null) return;
    if (index < 0 || index >= themeColors.length) return;
    _user = _user!.copyWith(selectedThemeIndex: index);
    notifyListeners();

    // Persist locally for instant next launch
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyThemeIndex, index);

    // Persist to Firestore (non-blocking)
    try {
      await _profileService.saveTheme(_user!.id, index);
    } catch (_) {
      // Local state already updated; Firestore sync is best-effort
    }
  }

  // ── Notification settings ─────────────────────────────────────────────────

  Future<void> toggleNotifications(bool value) async {
    if (_user == null) return;
    _user = _user!.copyWith(notificationsEnabled: value);
    notifyListeners();
    // Schedule or cancel study reminders based on both toggles
    if (value && _user!.studyRemindersEnabled) {
      await NotificationService.instance.scheduleStudyReminders();
    } else {
      await NotificationService.instance.cancelStudyReminders();
    }
    try {
      await _profileService.saveNotificationSettings(
        _user!.id,
        notificationsEnabled: value,
        studyRemindersEnabled: _user!.studyRemindersEnabled,
      );
    } catch (_) {}
  }

  Future<void> toggleStudyReminders(bool value) async {
    if (_user == null) return;
    _user = _user!.copyWith(studyRemindersEnabled: value);
    notifyListeners();
    // Only schedule if master notifications is also on
    if (value && _user!.notificationsEnabled) {
      await NotificationService.instance.scheduleStudyReminders();
    } else if (!value) {
      await NotificationService.instance.cancelStudyReminders();
    }
    try {
      await _profileService.saveNotificationSettings(
        _user!.id,
        notificationsEnabled: _user!.notificationsEnabled,
        studyRemindersEnabled: value,
      );
    } catch (_) {}
  }

  Future<void> toggleDarkMode(bool value) async {
    if (_user == null) return;
    _user = _user!.copyWith(darkModeEnabled: value);
    notifyListeners();
    try {
      await _profileService.updateSettings(
        _user!.id,
        {'darkModeEnabled': value},
      );
    } catch (_) {}
  }

  // ── Account deletion ──────────────────────────────────────────────────────

  /// Permanently deletes the account. Returns an error message on failure.
  Future<String?> deleteAccount() async {
    if (_user == null) return 'No user session.';
    try {
      _userSub?.cancel();
      await _profileService.deleteAccount(_user!.id);
      _user = null;
      _isLoggedIn = false;
      _onboardingCompleted = false;
      notifyListeners();
      return null; // success
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        return 'Please sign out and sign in again before deleting your account.';
      }
      return 'Failed to delete account: ${e.message}';
    } catch (e) {
      return 'Failed to delete account. Please try again.';
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _clearSuccessAfterDelay() {
    Future.delayed(const Duration(seconds: 3), () {
      _successMessage = null;
      notifyListeners();
    });
  }

  Future<bool> _run(Future<void> Function() fn) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await fn();
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = AuthService.friendlyError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      // Show the actual error so the developer can debug setup issues
      final msg = e.toString();
      if (msg.contains('network') || msg.contains('Network')) {
        _errorMessage = 'No internet connection. Please check your network.';
      } else if (msg.contains('API key not valid') || msg.contains('api-key-not-valid')) {
        _errorMessage =
            'Firebase API key is not valid. Re-download google-services.json from Firebase Console.';
      } else if (msg.contains('operation-not-allowed') ||
          msg.contains('not enabled')) {
        _errorMessage =
            'Email/Password sign-in is not enabled.\nGo to Firebase Console → Authentication → Sign-in method → Enable Email/Password.';
      } else if (msg.contains('channel-error') || msg.contains('channel_error')) {
        _errorMessage =
            'Firebase config error. Add SHA-1 fingerprint in Firebase Console → Project Settings → Android App.';
      } else if (msg.isNotEmpty && msg != 'null') {
        // Show the real error message — helps find setup issues fast
        _errorMessage = msg.replaceFirst('Exception: ', '').replaceFirst('FirebaseAuthException: ', '');
      } else {
        _errorMessage = 'Something went wrong. Please try again.';
      }
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
