import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/user_model.dart';

/// Handles all profile-related backend operations:
/// Firestore read/write, Firebase Storage image upload,
/// account deletion, and real-time user stream.
class ProfileService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // ── Firestore reference ──────────────────────────────────────────────────

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _db.collection('users').doc(uid);

  // ── Real-time stream ─────────────────────────────────────────────────────

  /// Streams the Firestore user document so the UI updates in real time.
  Stream<UserModel?> userStream(String uid) {
    return _userDoc(uid).snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      return UserModel.fromFirestore(snap);
    });
  }

  // ── Fetch ────────────────────────────────────────────────────────────────

  Future<UserModel?> fetchUser(String uid) async {
    final doc = await _userDoc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return UserModel.fromFirestore(doc);
  }

  // ── Update display name ──────────────────────────────────────────────────

  Future<void> updateName(String uid, String name) async {
    await Future.wait([
      _userDoc(uid).update({'name': name, 'updatedAt': FieldValue.serverTimestamp()}),
      _auth.currentUser?.updateDisplayName(name) ?? Future.value(),
    ]);
  }

  // ── Update settings ──────────────────────────────────────────────────────

  Future<void> updateSettings(String uid, Map<String, dynamic> settings) async {
    await _userDoc(uid).update({
      ...settings,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ── Theme persistence ────────────────────────────────────────────────────

  Future<void> saveTheme(String uid, int themeIndex) async {
    await _userDoc(uid)
        .update({'selectedThemeIndex': themeIndex, 'updatedAt': FieldValue.serverTimestamp()});
  }

  // ── Notification persistence ─────────────────────────────────────────────

  Future<void> saveNotificationSettings(
    String uid, {
    required bool notificationsEnabled,
    required bool studyRemindersEnabled,
  }) async {
    await _userDoc(uid).update({
      'notificationsEnabled': notificationsEnabled,
      'studyRemindersEnabled': studyRemindersEnabled,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ── Profile photo upload ─────────────────────────────────────────────────

  /// Uploads [imageFile] to Firebase Storage under `profile_images/{uid}/avatar.jpg`.
  /// Returns the download URL.
  Future<String> uploadProfileImage(String uid, File imageFile) async {
    final ref = _storage.ref().child('profile_images/$uid/avatar.jpg');

    final uploadTask = await ref.putFile(
      imageFile,
      SettableMetadata(contentType: 'image/jpeg'),
    );

    final downloadUrl = await uploadTask.ref.getDownloadURL();

    // Persist to Firestore and Firebase Auth profile
    await Future.wait([
      _userDoc(uid).update({
        'avatarUrl': downloadUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      }),
      _auth.currentUser?.updatePhotoURL(downloadUrl) ?? Future.value(),
    ]);

    return downloadUrl;
  }

  /// Deletes the profile photo from Storage and clears the avatarUrl field.
  Future<void> deleteProfileImage(String uid) async {
    try {
      await _storage.ref().child('profile_images/$uid/avatar.jpg').delete();
    } catch (_) {
      // Ignore if no file exists
    }
    await Future.wait([
      _userDoc(uid).update({
        'avatarUrl': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      }),
      _auth.currentUser?.updatePhotoURL(null) ?? Future.value(),
    ]);
  }

  // ── Logout ───────────────────────────────────────────────────────────────

  Future<void> signOut() async {
    await _auth.signOut();
  }

  // ── Delete account ───────────────────────────────────────────────────────

  /// Permanently deletes all user data and the Firebase Auth account.
  /// Caller should re-authenticate the user first if needed.
  Future<void> deleteAccount(String uid) async {
    // 1. Delete Storage files
    try {
      final listResult = await _storage.ref().child('profile_images/$uid').listAll();
      for (final item in listResult.items) {
        await item.delete();
      }
    } catch (_) {
      // Best-effort
    }

    // 2. Delete Firestore subcollections (tasks, sessions, etc.)
    final collections = ['tasks', 'sessions', 'chats'];
    for (final col in collections) {
      final snap = await _userDoc(uid).collection(col).get();
      for (final doc in snap.docs) {
        await doc.reference.delete();
      }
    }

    // 3. Delete user Firestore document
    await _userDoc(uid).delete();

    // 4. Delete Firebase Auth account
    await _auth.currentUser?.delete();
  }

  // ── Create / upsert ──────────────────────────────────────────────────────

  /// Ensures a Firestore document exists for the given user (upsert).
  Future<void> ensureUserDocument(UserModel model) async {
    await _userDoc(model.id).set(model.toFirestore(), SetOptions(merge: true));
  }
}
