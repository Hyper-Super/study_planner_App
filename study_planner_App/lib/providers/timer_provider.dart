import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/session_model.dart';
import '../services/notification_service.dart';
import '../services/audio_service.dart';
import '../services/session_service.dart';

// ── SharedPreferences keys ─────────────────────────────────────────────────
const _kMode        = 'timer_mode';
const _kSecondsLeft = 'timer_seconds_left';
const _kTotalSecs   = 'timer_total_seconds';
const _kIsRunning   = 'timer_is_running';
const _kEpoch       = 'timer_epoch';

/// Full-featured Pomodoro timer provider.
///
/// • Accurate countdown using DateTime wall-clock deltas (survives background).
/// • Pause / resume with state persistence via SharedPreferences.
/// • Firestore session saving on completion or reset.
/// • Local notifications: live background notification + completion alert.
/// • In-memory daily stats streamed from Firestore.
class TimerProvider extends ChangeNotifier {

  static const Map<String, int> modeDurations = {
    'Pomodoro':    25,
    'Short Break': 5,
    'Long Break':  15,
  };

  // ── State ──────────────────────────────────────────────────────────────────
  String   _currentMode      = 'Pomodoro';
  int      _secondsRemaining = 25 * 60;
  int      _totalSeconds     = 25 * 60;
  bool     _isRunning        = false;

  DateTime? _startedAt;           // wall-clock when last started/resumed
  int       _secondsAtLastStart = 25 * 60;

  Timer?    _ticker;

  DateTime? _sessionStartedAt;    // when the current session began
  String?   _currentUserId;

  // Today's stats
  int _todayPomodoros   = 0;
  int _todayFocusMins   = 0;
  int _todayShortBreaks = 0;
  int _todayLongBreaks  = 0;

  StreamSubscription<DailyStats?>? _statsSub;

  // ── Getters ────────────────────────────────────────────────────────────────
  String get currentMode      => _currentMode;
  int    get secondsRemaining => _secondsRemaining;
  int    get totalSeconds     => _totalSeconds;
  bool   get isRunning        => _isRunning;

  double get progress =>
      _totalSeconds == 0 ? 0 : _secondsRemaining / _totalSeconds;

  String get formattedTime {
    final m = _secondsRemaining ~/ 60;
    final s = _secondsRemaining % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  int get todayPomodoros   => _todayPomodoros;
  int get todayFocusMins   => _todayFocusMins;
  int get todayShortBreaks => _todayShortBreaks;
  int get todayLongBreaks  => _todayLongBreaks;

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  /// Must be called once after construction with the signed-in user's uid.
  Future<void> init(String userId) async {
    _currentUserId = userId.isNotEmpty ? userId : null;
    await NotificationService.instance.init();
    await _restoreState();
    _subscribeToStats();
    notifyListeners();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _statsSub?.cancel();
    super.dispose();
  }

  // ── Public API ─────────────────────────────────────────────────────────────

  void setMode(String mode) {
    if (!modeDurations.containsKey(mode)) return;
    _cancelTicker();
    _currentMode      = mode;
    _totalSeconds     = modeDurations[mode]! * 60;
    _secondsRemaining = _totalSeconds;
    _isRunning        = false;
    _sessionStartedAt = null;
    _saveState();
    NotificationService.instance.cancelBackgroundTimer();
    notifyListeners();
  }

  void toggleTimer() => _isRunning ? _pause() : _start();

  void reset() {
    _cancelTicker();
    _secondsRemaining = _totalSeconds;
    _isRunning        = false;
    _sessionStartedAt = null;
    _saveState();
    NotificationService.instance.cancelBackgroundTimer();
    notifyListeners();
  }

  void skip() {
    _cancelTicker();
    NotificationService.instance.cancelBackgroundTimer();
    const order = ['Pomodoro', 'Short Break', 'Long Break'];
    final next  = order[(order.indexOf(_currentMode) + 1) % order.length];
    setMode(next);
  }

  // ── Internal ───────────────────────────────────────────────────────────────

  void _start() {
    _sessionStartedAt ??= DateTime.now();
    _startedAt           = DateTime.now();
    _secondsAtLastStart  = _secondsRemaining;
    _isRunning           = true;
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    _saveState();
    notifyListeners();
  }

  void _pause() {
    _cancelTicker();
    _isRunning = false;
    _saveState();
    NotificationService.instance.cancelBackgroundTimer();
    notifyListeners();
  }

  void _tick() {
    if (_startedAt == null) return;
    final elapsed   = DateTime.now().difference(_startedAt!).inSeconds;
    final remaining = _secondsAtLastStart - elapsed;

    if (remaining <= 0) {
      _secondsRemaining = 0;
      _cancelTicker();
      _isRunning = false;
      notifyListeners();
      _onTimerComplete();
    } else {
      _secondsRemaining = remaining;
      notifyListeners();
      if (remaining % 5 == 0) {
        NotificationService.instance.updateBackgroundTimer(
          modeName:      _currentMode,
          timeRemaining: formattedTime,
        );
      }
    }
    _saveState();
  }

  void _cancelTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  Future<void> _onTimerComplete() async {
    final type = SessionTypeX.fromLabel(_currentMode);
    await NotificationService.instance.cancelBackgroundTimer();
    await NotificationService.instance.showTimerComplete(
      modeName:   _currentMode,
      nextAction: type == SessionType.pomodoro
          ? 'Great work! Time for a break.'
          : 'Break over — ready to focus?',
    );
    // Play in-app completion sound
    await AudioService.instance.playTimerComplete();
    await _saveSession(completed: true);
  }

  Future<void> _saveSession({required bool completed}) async {
    if (_sessionStartedAt == null || _currentUserId == null) return;
    final session = SessionModel(
      id:             _generateId(),
      userId:         _currentUserId!,
      type:           SessionTypeX.fromLabel(_currentMode),
      startedAt:      _sessionStartedAt!,
      endedAt:        DateTime.now(),
      focusedSeconds: _totalSeconds - _secondsRemaining,
      completed:      completed,
    );
    await SessionFirestoreService.instance.saveSession(session);
    _sessionStartedAt = null;
  }

  String _generateId() =>
      '${DateTime.now().millisecondsSinceEpoch}_'
      '${Random().nextInt(9999).toString().padLeft(4, '0')}';

  // ── SharedPreferences ──────────────────────────────────────────────────────

  Future<void> _saveState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kMode,       _currentMode);
    await prefs.setInt   (_kTotalSecs,  _totalSeconds);
    await prefs.setBool  (_kIsRunning,  _isRunning);
    if (_isRunning && _startedAt != null) {
      await prefs.setInt(_kSecondsLeft, _secondsAtLastStart);
      await prefs.setInt(_kEpoch,       _startedAt!.millisecondsSinceEpoch);
    } else {
      await prefs.setInt(_kSecondsLeft, _secondsRemaining);
      await prefs.remove(_kEpoch);
    }
  }

  Future<void> _restoreState() async {
    final prefs = await SharedPreferences.getInstance();
    _currentMode  = prefs.getString(_kMode)   ?? 'Pomodoro';
    _totalSeconds = prefs.getInt(_kTotalSecs) ?? modeDurations[_currentMode]! * 60;

    final wasRunning  = prefs.getBool(_kIsRunning)  ?? false;
    final savedSecs   = prefs.getInt(_kSecondsLeft) ?? _totalSeconds;
    final epochMillis = prefs.getInt(_kEpoch);

    if (wasRunning && epochMillis != null) {
      final startedAt = DateTime.fromMillisecondsSinceEpoch(epochMillis);
      final elapsed   = DateTime.now().difference(startedAt).inSeconds;
      final remaining = savedSecs - elapsed;

      if (remaining <= 0) {
        _secondsRemaining = 0;
        _isRunning        = false;
        _onTimerComplete();
      } else {
        _secondsRemaining   = remaining;
        _secondsAtLastStart = savedSecs;
        _startedAt          = startedAt;
        _isRunning          = true;
        _sessionStartedAt ??= DateTime.now()
            .subtract(Duration(seconds: _totalSeconds - remaining));
        _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
      }
    } else {
      _secondsRemaining = savedSecs;
      _isRunning        = false;
    }
  }

  // ── Stats stream ───────────────────────────────────────────────────────────

  void _subscribeToStats() {
    if (_currentUserId == null) return;
    _statsSub?.cancel();
    _statsSub = SessionFirestoreService.instance
        .todayStatsStream(_currentUserId!)
        .listen((stats) {
      _todayPomodoros   = stats?.pomodorosCompleted ?? 0;
      _todayFocusMins   = stats?.totalFocusMinutes  ?? 0;
      _todayShortBreaks = stats?.shortBreaks         ?? 0;
      _todayLongBreaks  = stats?.longBreaks          ?? 0;
      notifyListeners();
    });
  }

  /// Call when auth state changes (login / logout).
  void updateUser(String? userId) {
    _statsSub?.cancel();
    _currentUserId = (userId != null && userId.isNotEmpty) ? userId : null;
    _subscribeToStats();
  }
}
