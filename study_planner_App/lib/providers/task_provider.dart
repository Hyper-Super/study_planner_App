// lib/providers/task_provider.dart
//
// Drop-in replacement for the existing task_provider.dart.
// ─────────────────────────────────────────────────────────────────────────────
// Responsibilities
//   • Owns all task state consumed by the UI
//   • Bridges TaskService (Firestore) ↔ widgets via ChangeNotifier
//   • Real-time Firestore stream subscription with offline cache
//   • Calendar-date filtering
//   • Subject-progress map
//   • Daily / weekly statistics
//   • Full error + loading state management
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/task_model.dart';
import '../services/task_service.dart';

// ─── Provider state enum ──────────────────────────────────────────────────────

enum TaskLoadState { idle, loading, loaded, error }

// ─── TaskProvider ─────────────────────────────────────────────────────────────

class TaskProvider extends ChangeNotifier {
  final TaskService _service = TaskService();

  // ── Raw state ──────────────────────────────────────────────────────────────
  List<TaskModel>  _tasks          = [];
  DailyStats       _dailyStats     = DailyStats.empty();
  Map<String, int> _subjectProgress = {};
  List<Map<String,int>> _weeklyStats = [];

  TaskLoadState _loadState  = TaskLoadState.idle;
  String?       _errorMessage;

  // Calendar filter — null = show all
  DateTime?    _selectedDate;

  // ── Stream subscriptions ──────────────────────────────────────────────────
  StreamSubscription<List<TaskModel>>? _tasksSub;
  StreamSubscription<DailyStats>?      _statsSub;
  StreamSubscription<Map<String,int>>? _progressSub;

  // ── Public getters ─────────────────────────────────────────────────────────

  TaskLoadState    get loadState       => _loadState;
  bool             get isLoading       => _loadState == TaskLoadState.loading;
  bool             get hasError        => _loadState == TaskLoadState.error;
  String?          get errorMessage    => _errorMessage;
  DateTime?        get selectedDate    => _selectedDate;
  DailyStats       get dailyStats      => _dailyStats;
  Map<String, int> get subjectProgress => Map.unmodifiable(_subjectProgress);
  List<Map<String,int>> get weeklyStats => List.unmodifiable(_weeklyStats);

  // ── Filtered task lists ───────────────────────────────────────────────────

  List<TaskModel> get _filtered {
    if (_selectedDate == null) return _tasks;
    return _tasks.where((t) =>
        t.dueDate.year  == _selectedDate!.year  &&
        t.dueDate.month == _selectedDate!.month &&
        t.dueDate.day   == _selectedDate!.day).toList();
  }

  List<TaskModel> get tasks          => List.unmodifiable(_filtered);
  List<TaskModel> get allTasks       => List.unmodifiable(_tasks);
  List<TaskModel> get ongoingTasks   => _filtered.where((t) => t.status == TaskStatus.ongoing).toList();
  List<TaskModel> get upcomingTasks  => _filtered.where((t) => t.status == TaskStatus.upcoming).toList();
  List<TaskModel> get completedTasks => _filtered.where((t) => t.status == TaskStatus.completed).toList();

  // Priority-sorted helpers
  List<TaskModel> get highPriorityTasks =>
      _filtered.where((t) => t.priority == TaskPriority.high && t.status != TaskStatus.completed).toList();

  List<TaskModel> get tasksSortedByPriority {
    final copy = List<TaskModel>.from(_filtered);
    copy.sort((a, b) => b.priority.sortOrder.compareTo(a.priority.sortOrder));
    return copy;
  }

  // Stats shortcuts
  int    get totalCount       => _tasks.length;
  int    get completedCount   => _tasks.where((t) => t.status == TaskStatus.completed).length;
  double get completionRate   => totalCount == 0 ? 0 : completedCount / totalCount;

  // Subject progress for a specific subject (falls back to computed value)
  int progressForSubject(String subject) {
    if (_subjectProgress.containsKey(subject)) return _subjectProgress[subject]!;
    final subTasks = _tasks.where((t) => t.subject == subject).toList();
    if (subTasks.isEmpty) return 0;
    final done = subTasks.fold<int>(0, (s, t) => s + t.completedMinutes);
    final est  = subTasks.fold<int>(0, (s, t) => s + t.estimatedMinutes);
    return est == 0 ? 0 : ((done / est) * 100).round().clamp(0, 100);
  }

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  /// Call once after the user signs in (e.g. from UserProvider or Splash).
  void init() {
    _loadState = TaskLoadState.loading;
    notifyListeners();

    _tasksSub = _service.tasksStream().listen(
      (list) {
        _tasks    = list;
        _loadState = TaskLoadState.loaded;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (e) {
        _loadState    = TaskLoadState.error;
        _errorMessage = _friendlyError(e);
        notifyListeners();
      },
    );

    _statsSub = _service.dailyStatsStream().listen((stats) {
      _dailyStats = stats;
      notifyListeners();
    });

    _progressSub = _service.subjectProgressStream().listen((map) {
      _subjectProgress = map;
      notifyListeners();
    });

    _loadWeeklyStats();
  }

  /// Call when the user signs out.
  void clear() {
    _tasksSub?.cancel();
    _statsSub?.cancel();
    _progressSub?.cancel();
    _tasks          = [];
    _dailyStats     = DailyStats.empty();
    _subjectProgress = {};
    _weeklyStats    = [];
    _selectedDate   = null;
    _loadState      = TaskLoadState.idle;
    _errorMessage   = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _tasksSub?.cancel();
    _statsSub?.cancel();
    _progressSub?.cancel();
    super.dispose();
  }

  // ── Calendar filter ───────────────────────────────────────────────────────

  void selectDate(DateTime? date) {
    _selectedDate = date;
    notifyListeners();
  }

  void clearDateFilter() => selectDate(null);

  /// Returns true if the given date has any tasks (for calendar dot indicators).
  bool hasTasksOnDate(DateTime date) => _tasks.any((t) =>
      t.dueDate.year  == date.year  &&
      t.dueDate.month == date.month &&
      t.dueDate.day   == date.day);

  // ── CRUD ──────────────────────────────────────────────────────────────────

  Future<void> addTask({
    required String title,
    required String subject,
    required String description,
    required DateTime dueDate,
    TaskPriority priority = TaskPriority.medium,
    int estimatedMinutes = 60,
  }) async {
    _clearError();
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final task = TaskModel.create(
      userId:           uid,
      title:            title,
      subject:          subject,
      description:      description,
      dueDate:          dueDate,
      priority:         priority,
      estimatedMinutes: estimatedMinutes,
    );
    try {
      await _service.addTask(task);
    } catch (e) {
      _setError(e);
    }
  }

  Future<void> updateTask(TaskModel task) async {
    _clearError();
    try {
      await _service.updateTask(task);
    } catch (e) {
      _setError(e);
    }
  }

  Future<void> deleteTask(String taskId) async {
    _clearError();
    try {
      await _service.deleteTask(taskId);
    } catch (e) {
      _setError(e);
    }
  }

  Future<void> markCompleted(String taskId) async {
    _clearError();
    try {
      await _service.markCompleted(taskId);
    } catch (e) {
      _setError(e);
    }
  }

  Future<void> updateProgress(String taskId, int completedMinutes) async {
    _clearError();
    try {
      await _service.updateProgress(taskId, completedMinutes);
    } catch (e) {
      _setError(e);
    }
  }

  // ── Weekly stats ──────────────────────────────────────────────────────────

  Future<void> _loadWeeklyStats() async {
    try {
      _weeklyStats = await _service.weeklyStats();
      notifyListeners();
    } catch (_) {
      // non-fatal
    }
  }

  Future<void> refreshWeeklyStats() => _loadWeeklyStats();

  // ── Retry ─────────────────────────────────────────────────────────────────

  void retry() {
    clear();
    init();
  }

  // ── Error helpers ─────────────────────────────────────────────────────────

  void _setError(Object e) {
    _errorMessage = _friendlyError(e);
    _loadState    = TaskLoadState.error;
    notifyListeners();
  }

  void _clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  static String _friendlyError(Object e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('network') || msg.contains('unavailable')) {
      return 'No internet. Showing cached data.';
    }
    if (msg.contains('permission')) {
      return 'Permission denied. Please sign in again.';
    }
    return 'Something went wrong. Pull to retry.';
  }
}
