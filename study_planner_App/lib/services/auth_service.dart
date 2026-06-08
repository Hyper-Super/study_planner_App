import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

import '../models/user_model.dart';

/// All Firebase Authentication operations live here.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // ── Stream ─────────────────────────────────────────────────────────────────

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  // ── Email / Password ───────────────────────────────────────────────────────

  Future<UserModel> signUpWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = credential.user!;
    await user.updateDisplayName(name);
    await user.reload();

    final model = UserModel(
      id: user.uid,
      name: name,
      email: email,
      createdAt: DateTime.now(),
    );

    await _saveUserToFirestore(model);
    return model;
  }

  Future<UserModel> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return _getUserModel(credential.user!);
  }

  // ── Google Sign-In ─────────────────────────────────────────────────────────

  Future<UserModel> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) throw FirebaseAuthException(code: 'sign-in-cancelled');

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await _auth.signInWithCredential(credential);
    final user = userCredential.user!;

    final exists = await _userExists(user.uid);
    final model = UserModel(
      id: user.uid,
      name: user.displayName ?? googleUser.displayName ?? 'Student',
      email: user.email ?? '',
      avatarUrl: user.photoURL,
      createdAt: DateTime.now(),
    );

    if (!exists) await _saveUserToFirestore(model);
    return exists ? await _getUserModel(user) : model;
  }

  // ── Apple Sign-In ──────────────────────────────────────────────────────────

  Future<UserModel> signInWithApple() async {
    final rawNonce = _generateNonce();
    final nonce    = _sha256ofString(rawNonce);

    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: nonce,
    );

    final oauthCredential = OAuthProvider('apple.com').credential(
      idToken: appleCredential.identityToken,
      rawNonce: rawNonce,
    );

    final userCredential = await _auth.signInWithCredential(oauthCredential);
    final user = userCredential.user!;

    final name = [appleCredential.givenName, appleCredential.familyName]
        .where((e) => e != null && e.isNotEmpty)
        .join(' ');

    if (name.isNotEmpty) await user.updateDisplayName(name);

    final exists = await _userExists(user.uid);
    final model = UserModel(
      id: user.uid,
      name: name.isNotEmpty ? name : (user.displayName ?? 'Student'),
      email: user.email ?? appleCredential.email ?? '',
      createdAt: DateTime.now(),
    );

    if (!exists) await _saveUserToFirestore(model);
    return exists ? await _getUserModel(user) : model;
  }

  // ── Password Reset ─────────────────────────────────────────────────────────

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // ── Sign Out ───────────────────────────────────────────────────────────────

  Future<void> signOut() async {
    await Future.wait([
      _auth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }

  // ── Firestore Helpers ──────────────────────────────────────────────────────

  Future<void> _saveUserToFirestore(UserModel model) async {
    await _db
        .collection('users')
        .doc(model.id)
        .set(model.toFirestore(), SetOptions(merge: true));
  }

  Future<UserModel> _getUserModel(User user) async {
    final doc = await _db.collection('users').doc(user.uid).get();
    if (doc.exists && doc.data() != null) {
      return UserModel.fromFirestore(doc);
    }
    final model = UserModel(
      id: user.uid,
      name: user.displayName ?? 'Student',
      email: user.email ?? '',
      createdAt: DateTime.now(),
    );
    await _saveUserToFirestore(model);
    return model;
  }

  Future<bool> _userExists(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return doc.exists;
  }

  // ── Nonce helpers ──────────────────────────────────────────────────────────

  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)])
        .join();
  }

  String _sha256ofString(String input) {
    final bytes  = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // ── Error mapping ──────────────────────────────────────────────────────────

  static String friendlyError(FirebaseAuthException e) {
    switch (e.code) {
      case 'sign-in-cancelled':
        return 'Sign-in was cancelled.';
      case 'user-not-found':
        return 'No account found with this email. Please sign up first.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password. Please try again.';
      case 'email-already-in-use':
        return 'An account already exists with this email. Try signing in instead.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please wait a few minutes and try again.';
      case 'network-request-failed':
        return 'No internet connection. Please check your network and try again.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'operation-not-allowed':
        // ── MOST COMMON SETUP ERROR ──────────────────────────────────────────
        // This fires when Email/Password sign-in is NOT enabled in Firebase Console.
        // Fix: Firebase Console → Authentication → Sign-in method → Email/Password → Enable
        return 'Email/Password sign-in is not enabled.\n\nFix: Firebase Console → Authentication → Sign-in method → Email/Password → Enable it.';
      case 'account-exists-with-different-credential':
        return 'An account with this email already exists using a different sign-in method.';
      case 'requires-recent-login':
        return 'Please sign out and sign in again to continue.';
      case 'credential-already-in-use':
        return 'This credential is already linked to another account.';
      case 'provider-already-linked':
        return 'This sign-in method is already linked to your account.';
      case 'channel-error':
        // ── SECOND MOST COMMON SETUP ERROR ───────────────────────────────────
        // Usually means SHA-1 fingerprint is missing in Firebase Console,
        // OR google-services.json is outdated.
        // Fix: Add SHA-1 in Firebase Console → Project Settings → Your Apps → Android App
        return 'Firebase configuration error.\n\nFix: Add your SHA-1 fingerprint in Firebase Console → Project Settings → Android App, then re-download google-services.json.';
      case 'api-key-not-valid':
        return 'Firebase API key is not valid. Please re-download google-services.json from Firebase Console.';
      default:
        debugPrint('[AuthService] Unhandled FirebaseAuthException: code=${e.code}, msg=${e.message}');
        return e.message?.isNotEmpty == true
            ? e.message!
            : 'Something went wrong (code: ${e.code}). Please try again.';
    }
  }
}
