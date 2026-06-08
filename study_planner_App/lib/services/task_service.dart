// lib/services/task_service.dart
//
// All Firestore I/O for tasks lives here.
// ─────────────────────────────────────────────────────────────────────────────
// Firestore collection layout
// ─────────────────────────────────────────────────────────────────────────────
//
//  users/{uid}/
//    tasks/{taskId}          ← one doc per task (fields: see TaskModel)
//    stats/daily             ← aggregated daily stats doc
//    stats/subjects          ← aggregated per-subject progress doc
//
// Firestore security rules (paste into Firebase Console → Rules):
// ─────────────────────────────────────────────────────────────────────────────
//  rules_version = '2';
//  service cloud.firestore {
//    match /databases/{database}/documents {
//      match /users/{uid}/tasks/{taskId} {
//        allow read, write: if request.auth != null && request.auth.uid == uid;
//      }
//      match /users/{uid}/stats/{doc} {
//        allow read, write: if request.auth != null && request.auth.uid == uid;
//      }
//    }
//  }
// ─────────────────────────────────────────────────────────────────────────────

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/task_model.dart';

class TaskService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ── Helpers ────────────────────────────────────────────────────────────────

  String get _uid {
    final u = _auth.currentUser;
    if (u == null) throw Exception('TaskService: user not signed in');
    return u.uid;
  }

  CollectionReference<Map<String, dynamic>> get _tasksCol =>
      _db.collection('users').doc(_uid).collection('tasks');

  DocumentReference<Map<String, dynamic>> get _dailyStatsDoc =>
      _db.collection('users').doc(_uid).collection('stats').doc('daily');

  DocumentReference<Map<String, dynamic>> get _subjectStatsDoc =>
      _db.collection('users').doc(_uid).collection('stats').doc('subjects');

  // ── Real-time stream of all tasks ─────────────────────────────────────────

  /// Streams the user's tasks ordered by dueDate ascending.
  /// Firestore SDK handles offline cache automatically — set
  /// [PersistenceEnabled] in FirebaseFirestore.instance.settings for more
  /// control (already enabled by default on mobile).
  Stream<List<TaskModel>> tasksStream() {
    return _tasksCol
        .orderBy('dueDate', descending: false)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => TaskModel.fromFirestore(d)).toList());
  }

  /// Stream filtered by a specific calendar date (day-granularity).
  Stream<List<TaskModel>> tasksForDateStream(DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end   = start.add(const Duration(days: 1));
    return _tasksCol
        .where('dueDate', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('dueDate', isLessThan: Timestamp.fromDate(end))
        .orderBy('dueDate')
        .snapshots()
        .map((s) => s.docs.map(TaskModel.fromFirestore).toList());
  }

  /// Stream filtered by subject name.
  Stream<List<TaskModel>> tasksForSubjectStream(String subject) {
    return _tasksCol
        .where('subject', isEqualTo: subject)
        .orderBy('dueDate')
        .snapshots()
        .map((s) => s.docs.map(TaskModel.fromFirestore).toList());
  }

  // ── CRUD ───────────────────────────────────────────────────────────────────

  /// Add a new task. Returns the saved [TaskModel] with its Firestore ID.
  Future<TaskModel> addTask(TaskModel task) async {
    final docRef = await _tasksCol.add(task.toFirestore());
    final saved = task.copyWith(id: docRef.id);
    await _refreshStats();
    return saved;
  }

  /// Update an existing task (full overwrite).
  Future<void> updateTask(TaskModel task) async {
    assert(task.id.isNotEmpty, 'updateTask: task.id must not be empty');
    await _tasksCol.doc(task.id).set(task.toFirestore());
    await _refreshStats();
  }

  /// Delete a task by ID.
  Future<void> deleteTask(String taskId) async {
    await _tasksCol.doc(taskId).delete();
    await _refreshStats();
  }

  /// Mark task as completed and set completedMinutes = estimatedMinutes.
  Future<void> markCompleted(String taskId) async {
    await _tasksCol.doc(taskId).update({
      'status':           TaskStatus.completed.value,
      'completedMinutes': FieldValue.increment(0), // placeholder — real val below
      'updatedAt':        FieldValue.serverTimestamp(),
    });
    // Fetch the task to read estimatedMinutes then write correctly
    final snap = await _tasksCol.doc(taskId).get();
    if (snap.exists) {
      final est = (snap.data()?['estimatedMinutes'] as num?)?.toInt() ?? 60;
      await _tasksCol.doc(taskId).update({
        'status':           TaskStatus.completed.value,
        'completedMinutes': est,
        'updatedAt':        FieldValue.serverTimestamp(),
      });
    }
    await _refreshStats();
  }

  /// Update only the progress (completedMinutes) for an ongoing task.
  Future<void> updateProgress(String taskId, int completedMinutes) async {
    await _tasksCol.doc(taskId).update({
      'completedMinutes': completedMinutes,
      'updatedAt':        FieldValue.serverTimestamp(),
    });
    await _refreshStats();
  }

  // ── Stats ──────────────────────────────────────────────────────────────────

  /// Streams daily statistics (total / completed / upcoming counts, minutes).
  Stream<DailyStats> dailyStatsStream() {
    return _dailyStatsDoc.snapshots().map((snap) {
      if (!snap.exists) return DailyStats.empty();
      return DailyStats.fromMap(snap.data()!);
    });
  }

  /// Streams per-subject progress percentages.
  Stream<Map<String, int>> subjectProgressStream() {
    return _subjectStatsDoc.snapshots().map((snap) {
      if (!snap.exists) return {};
      final data = snap.data()!;
      return data.map((k, v) => MapEntry(k, (v as num).toInt()));
    });
  }

  // ── Private: recalculate + persist stats ──────────────────────────────────

  Future<void> _refreshStats() async {
    try {
      final snap = await _tasksCol.get();
      final tasks = snap.docs.map(TaskModel.fromFirestore).toList();

      // Daily stats
      final today = DateTime.now();
      final todayTasks = tasks.where((t) =>
          t.dueDate.year  == today.year &&
          t.dueDate.month == today.month &&
          t.dueDate.day   == today.day).toList();

      final totalMinutesToday    = todayTasks.fold<int>(0, (s, t) => s + t.estimatedMinutes);
      final completedMinToday    = todayTasks.fold<int>(0, (s, t) => s + t.completedMinutes);
      final completedTasksToday  = todayTasks.where((t) => t.status == TaskStatus.completed).length;

      await _dailyStatsDoc.set({
        'totalTasks':        tasks.length,
        'completedTasks':    tasks.where((t) => t.status == TaskStatus.completed).length,
        'ongoingTasks':      tasks.where((t) => t.status == TaskStatus.ongoing).length,
        'upcomingTasks':     tasks.where((t) => t.status == TaskStatus.upcoming).length,
        'todayTotal':        todayTasks.length,
        'todayCompleted':    completedTasksToday,
        'todayMinutesEst':   totalMinutesToday,
        'todayMinutesDone':  completedMinToday,
        'updatedAt':         FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Subject progress
      final Map<String, int> subjectDone = {};
      final Map<String, int> subjectEst  = {};

      for (final t in tasks) {
        subjectDone[t.subject] = (subjectDone[t.subject] ?? 0) + t.completedMinutes;
        subjectEst[t.subject]  = (subjectEst[t.subject]  ?? 0) + t.estimatedMinutes;
      }

      final Map<String, dynamic> progressMap = {};
      for (final s in subjectEst.keys) {
        final est = subjectEst[s]!;
        final done = subjectDone[s] ?? 0;
        progressMap[s] = est == 0 ? 0 : ((done / est) * 100).round().clamp(0, 100);
      }

      await _subjectStatsDoc.set(progressMap, SetOptions(merge: true));
    } catch (_) {
      // Stats refresh is best-effort — never block the main CRUD operation
    }
  }

  // ── One-shot fetches (for non-reactive contexts) ──────────────────────────

  Future<List<TaskModel>> fetchAllTasks() async {
    final snap = await _tasksCol.orderBy('dueDate').get();
    return snap.docs.map(TaskModel.fromFirestore).toList();
  }

  Future<TaskModel?> fetchTask(String taskId) async {
    final snap = await _tasksCol.doc(taskId).get();
    if (!snap.exists) return null;
    return TaskModel.fromFirestore(snap);
  }

  /// Weekly stats: returns a list of 7 maps (Mon→Sun) with done/est minutes.
  Future<List<Map<String, int>>> weeklyStats() async {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final weekStart = DateTime(monday.year, monday.month, monday.day);
    final weekEnd   = weekStart.add(const Duration(days: 7));

    final snap = await _tasksCol
        .where('dueDate', isGreaterThanOrEqualTo: Timestamp.fromDate(weekStart))
        .where('dueDate', isLessThan: Timestamp.fromDate(weekEnd))
        .get();

    final tasks = snap.docs.map(TaskModel.fromFirestore).toList();
    final List<Map<String, int>> result = List.generate(7, (_) => {'est': 0, 'done': 0});

    for (final t in tasks) {
      final dayIdx = t.dueDate.weekday - 1; // 0=Mon … 6=Sun
      result[dayIdx]['est']  = (result[dayIdx]['est']!  + t.estimatedMinutes);
      result[dayIdx]['done'] = (result[dayIdx]['done']! + t.completedMinutes);
    }
    return result;
  }
}

// ─── DailyStats value object ──────────────────────────────────────────────────

class DailyStats {
  final int totalTasks;
  final int completedTasks;
  final int ongoingTasks;
  final int upcomingTasks;
  final int todayTotal;
  final int todayCompleted;
  final int todayMinutesEst;
  final int todayMinutesDone;

  const DailyStats({
    this.totalTasks      = 0,
    this.completedTasks  = 0,
    this.ongoingTasks    = 0,
    this.upcomingTasks   = 0,
    this.todayTotal      = 0,
    this.todayCompleted  = 0,
    this.todayMinutesEst = 0,
    this.todayMinutesDone = 0,
  });

  factory DailyStats.empty() => const DailyStats();

  factory DailyStats.fromMap(Map<String, dynamic> m) => DailyStats(
    totalTasks:       (m['totalTasks']       as num?)?.toInt() ?? 0,
    completedTasks:   (m['completedTasks']   as num?)?.toInt() ?? 0,
    ongoingTasks:     (m['ongoingTasks']     as num?)?.toInt() ?? 0,
    upcomingTasks:    (m['upcomingTasks']    as num?)?.toInt() ?? 0,
    todayTotal:       (m['todayTotal']       as num?)?.toInt() ?? 0,
    todayCompleted:   (m['todayCompleted']   as num?)?.toInt() ?? 0,
    todayMinutesEst:  (m['todayMinutesEst']  as num?)?.toInt() ?? 0,
    todayMinutesDone: (m['todayMinutesDone'] as num?)?.toInt() ?? 0,
  );

  double get overallCompletionRate =>
      totalTasks == 0 ? 0 : completedTasks / totalTasks;

  double get todayCompletionRate =>
      todayTotal == 0 ? 0 : todayCompleted / todayTotal;
}
