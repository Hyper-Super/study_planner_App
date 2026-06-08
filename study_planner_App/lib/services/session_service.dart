import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/session_model.dart';

/// Persists Pomodoro sessions and daily statistics in Firestore.
///
/// Firestore structure:
///   users/{uid}/sessions/{sessionId}      – individual sessions
///   users/{uid}/dailyStats/{dateKey}      – aggregated daily totals
class SessionFirestoreService {
  SessionFirestoreService._();
  static final SessionFirestoreService instance =
      SessionFirestoreService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Collections ───────────────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> _sessions(String uid) =>
      _db.collection('users').doc(uid).collection('sessions');

  DocumentReference<Map<String, dynamic>> _dailyDoc(
          String uid, String dateKey) =>
      _db.collection('users').doc(uid).collection('dailyStats').doc(dateKey);

  // ── Session CRUD ──────────────────────────────────────────────────────────

  /// Save a completed or interrupted session and update daily aggregates.
  Future<void> saveSession(SessionModel session) async {
    final uid = session.userId;
    if (uid.isEmpty) return;

    // Write the session document
    await _sessions(uid).doc(session.id).set(session.toMap());

    // Update daily aggregates atomically
    final dateKey =
        '${session.startedAt.year}-'
        '${session.startedAt.month.toString().padLeft(2, '0')}-'
        '${session.startedAt.day.toString().padLeft(2, '0')}';

    final ref = _dailyDoc(uid, dateKey);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (snap.exists) {
        final data = snap.data()!;
        tx.update(ref, _buildDelta(session, data));
      } else {
        tx.set(ref, _newDailyStats(session, dateKey, uid));
      }
    });
  }

  Map<String, dynamic> _buildDelta(
      SessionModel session, Map<String, dynamic> existing) {
    final delta = <String, dynamic>{};
    if (session.type == SessionType.pomodoro && session.completed) {
      delta['pomodorosCompleted'] =
          (existing['pomodorosCompleted'] as int? ?? 0) + 1;
      delta['totalFocusMinutes'] =
          (existing['totalFocusMinutes'] as int? ?? 0) +
              session.focusedMinutes;
    } else if (session.type == SessionType.shortBreak && session.completed) {
      delta['shortBreaks'] = (existing['shortBreaks'] as int? ?? 0) + 1;
    } else if (session.type == SessionType.longBreak && session.completed) {
      delta['longBreaks'] = (existing['longBreaks'] as int? ?? 0) + 1;
    }
    return delta;
  }

  Map<String, dynamic> _newDailyStats(
      SessionModel session, String dateKey, String uid) {
    return DailyStats(
      dateKey:            dateKey,
      userId:             uid,
      pomodorosCompleted: (session.type == SessionType.pomodoro &&
              session.completed)
          ? 1
          : 0,
      totalFocusMinutes:  (session.type == SessionType.pomodoro &&
              session.completed)
          ? session.focusedMinutes
          : 0,
      shortBreaks: (session.type == SessionType.shortBreak &&
              session.completed)
          ? 1
          : 0,
      longBreaks:  (session.type == SessionType.longBreak &&
              session.completed)
          ? 1
          : 0,
    ).toMap();
  }

  // ── Read ──────────────────────────────────────────────────────────────────

  /// Latest N sessions for the user (ordered by most-recent first).
  Future<List<SessionModel>> getRecentSessions(String uid,
      {int limit = 20}) async {
    if (uid.isEmpty) return [];
    final snap = await _sessions(uid)
        .orderBy('startedAt', descending: true)
        .limit(limit)
        .get();
    return snap.docs
        .map((d) => SessionModel.fromMap(d.id, d.data()))
        .toList();
  }

  /// Daily stats for a specific date (returns null if none recorded yet).
  Future<DailyStats?> getDailyStats(String uid, DateTime date) async {
    if (uid.isEmpty) return null;
    final dateKey =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
    final snap = await _dailyDoc(uid, dateKey).get();
    if (!snap.exists) return null;
    return DailyStats.fromMap(snap.data()!);
  }

  /// Today's stats — live stream so the UI re-renders automatically.
  Stream<DailyStats?> todayStatsStream(String uid) {
    if (uid.isEmpty) return Stream.value(null);
    final now     = DateTime.now();
    final dateKey =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
    return _dailyDoc(uid, dateKey).snapshots().map((snap) =>
        snap.exists ? DailyStats.fromMap(snap.data()!) : null);
  }

  /// Weekly stats (last 7 days) for a bar chart.
  Future<List<DailyStats>> getWeeklyStats(String uid) async {
    if (uid.isEmpty) return [];
    final results = <DailyStats>[];
    for (int i = 6; i >= 0; i--) {
      final date = DateTime.now().subtract(Duration(days: i));
      final stats = await getDailyStats(uid, date);
      if (stats != null) results.add(stats);
    }
    return results;
  }
}
