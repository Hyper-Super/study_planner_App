import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Handles all persistence for the onboarding flow:
///   • Firestore  → users/{uid}  (educationLevel, interests, onboardingCompleted)
///   • SharedPreferences → local cache so the app never shows onboarding twice,
///     even when Firestore is slow or offline.
class OnboardingService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const String _keyOnboardingDone = 'onboarding_completed';
  static const String _keyEducationLevel  = 'education_level';
  static const String _keyInterests       = 'interests';

  // ── Save ───────────────────────────────────────────────────────────────────

  /// Writes educationLevel + interests to Firestore and caches locally.
  /// Uses merge: true — never overwrites name/email/streak/etc.
  Future<void> saveOnboarding({
    required String uid,
    required String educationLevel,
    required List<String> interests,
  }) async {
    await _db.collection('users').doc(uid).set(
      {
        'educationLevel'          : educationLevel,
        'interests'               : interests,
        'onboardingCompleted'     : true,
        'onboardingCompletedAt'   : FieldValue.serverTimestamp(),
        'updatedAt'               : FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setBool(_keyOnboardingDone, true),
      prefs.setString(_keyEducationLevel, educationLevel),
      prefs.setStringList(_keyInterests, interests),
    ]);
  }

  // ── Check ──────────────────────────────────────────────────────────────────

  /// true if this device already finished onboarding.
  /// Checks SharedPreferences first (fast); falls back to Firestore.
  Future<bool> isOnboardingCompleted({required String uid}) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_keyOnboardingDone) == true) return true;

    try {
      final doc = await _db.collection('users').doc(uid).get();
      final done = doc.data()?['onboardingCompleted'] as bool? ?? false;
      if (done) await prefs.setBool(_keyOnboardingDone, true);
      return done;
    } catch (_) {
      return false;
    }
  }

  // ── Cache helpers ──────────────────────────────────────────────────────────

  Future<OnboardingCache> getCachedData() async {
    final prefs = await SharedPreferences.getInstance();
    return OnboardingCache(
      educationLevel: prefs.getString(_keyEducationLevel) ?? '',
      interests     : prefs.getStringList(_keyInterests)  ?? [],
    );
  }

  /// Call on logout so the next user starts fresh.
  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.remove(_keyOnboardingDone),
      prefs.remove(_keyEducationLevel),
      prefs.remove(_keyInterests),
    ]);
  }
}

/// Lightweight value object for cached onboarding data.
class OnboardingCache {
  final String educationLevel;
  final List<String> interests;
  const OnboardingCache({required this.educationLevel, required this.interests});
  bool get isEmpty => educationLevel.isEmpty && interests.isEmpty;
}
