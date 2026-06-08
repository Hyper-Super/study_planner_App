import 'package:cloud_firestore/cloud_firestore.dart';

/// Types of timer sessions.
enum SessionType { pomodoro, shortBreak, longBreak }

extension SessionTypeX on SessionType {
  String get label {
    switch (this) {
      case SessionType.pomodoro:   return 'Pomodoro';
      case SessionType.shortBreak: return 'Short Break';
      case SessionType.longBreak:  return 'Long Break';
    }
  }

  int get defaultMinutes {
    switch (this) {
      case SessionType.pomodoro:   return 25;
      case SessionType.shortBreak: return 5;
      case SessionType.longBreak:  return 15;
    }
  }

  static SessionType fromLabel(String label) {
    switch (label) {
      case 'Short Break': return SessionType.shortBreak;
      case 'Long Break':  return SessionType.longBreak;
      default:            return SessionType.pomodoro;
    }
  }
}

/// A single completed (or interrupted) timer session.
class SessionModel {
  final String      id;
  final String      userId;
  final SessionType type;

  /// When the session started.
  final DateTime startedAt;

  /// When the session ended (completed or stopped).
  final DateTime endedAt;

  /// Actual duration the user focused, in seconds.
  final int focusedSeconds;

  /// True when the full timer reached 0.
  final bool completed;

  SessionModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.startedAt,
    required this.endedAt,
    required this.focusedSeconds,
    required this.completed,
  });

  int get focusedMinutes => (focusedSeconds / 60).ceil();

  // ── Firestore ─────────────────────────────────────────────────────────────

  Map<String, dynamic> toMap() => {
    'userId':         userId,
    'type':           type.label,
    'startedAt':      Timestamp.fromDate(startedAt),
    'endedAt':        Timestamp.fromDate(endedAt),
    'focusedSeconds': focusedSeconds,
    'completed':      completed,
  };

  factory SessionModel.fromMap(String docId, Map<String, dynamic> map) {
    return SessionModel(
      id:             docId,
      userId:         map['userId'] as String? ?? '',
      type:           SessionTypeX.fromLabel(map['type'] as String? ?? ''),
      startedAt:      (map['startedAt'] as Timestamp).toDate(),
      endedAt:        (map['endedAt']   as Timestamp).toDate(),
      focusedSeconds: (map['focusedSeconds'] as num?)?.toInt() ?? 0,
      completed:      map['completed'] as bool? ?? false,
    );
  }
}

/// Daily aggregated statistics stored / read from Firestore.
class DailyStats {
  /// Date key: "yyyy-MM-dd"
  final String dateKey;
  final String userId;
  int pomodorosCompleted;
  int totalFocusMinutes;
  int shortBreaks;
  int longBreaks;

  DailyStats({
    required this.dateKey,
    required this.userId,
    this.pomodorosCompleted = 0,
    this.totalFocusMinutes  = 0,
    this.shortBreaks        = 0,
    this.longBreaks         = 0,
  });

  Map<String, dynamic> toMap() => {
    'userId':              userId,
    'dateKey':             dateKey,
    'pomodorosCompleted':  pomodorosCompleted,
    'totalFocusMinutes':   totalFocusMinutes,
    'shortBreaks':         shortBreaks,
    'longBreaks':          longBreaks,
  };

  factory DailyStats.fromMap(Map<String, dynamic> map) {
    return DailyStats(
      dateKey:             map['dateKey']            as String? ?? '',
      userId:              map['userId']             as String? ?? '',
      pomodorosCompleted:  (map['pomodorosCompleted'] as num?)?.toInt() ?? 0,
      totalFocusMinutes:   (map['totalFocusMinutes']  as num?)?.toInt() ?? 0,
      shortBreaks:         (map['shortBreaks']        as num?)?.toInt() ?? 0,
      longBreaks:          (map['longBreaks']         as num?)?.toInt() ?? 0,
    );
  }
}
