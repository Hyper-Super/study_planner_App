import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;

/// Handles all local notification logic — Pomodoro timer AND study reminders.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const String _timerChannelId   = 'pomodoro_timer';
  static const String _timerChannelName = 'Pomodoro Timer';
  static const String _timerChannelDesc = 'Timer completion and background alerts';

  static const String _reminderChannelId   = 'study_reminders';
  static const String _reminderChannelName = 'Study Reminders';
  static const String _reminderChannelDesc = 'Daily study reminder notifications';

  static const int _timerDoneId    = 1;
  static const int _backgroundId   = 2;
  static const int _morningRemId   = 100;
  static const int _eveningRemId   = 101;

  bool _initialized = false;

  // ── Init ──────────────────────────────────────────────────────────────────

  Future<void> init() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios     = DarwinInitializationSettings(
      requestAlertPermission:  true,
      requestBadgePermission:  true,
      requestSoundPermission:  true,
    );
    const settings = InitializationSettings(android: android, iOS: ios);

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onTap,
    );

    await _createChannel(_timerChannelId, _timerChannelName, _timerChannelDesc);
    await _createChannel(_reminderChannelId, _reminderChannelName, _reminderChannelDesc);

    await _requestPermissions();
    _initialized = true;
  }

  Future<void> _createChannel(String id, String name, String desc) async {
    final channel = AndroidNotificationChannel(
      id, name,
      description: desc,
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  Future<void> _requestPermissions() async {
    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    // Request POST_NOTIFICATIONS permission (Android 13+)
    await androidImpl?.requestNotificationsPermission();
    // Request exact alarm permission (Android 12+)
    await androidImpl?.requestExactAlarmsPermission();
  }

  void _onTap(NotificationResponse response) {}

  // ── Timer notifications ───────────────────────────────────────────────────

  Future<void> showTimerComplete({
    required String modeName,
    required String nextAction,
  }) async {
    if (!_initialized) return;

    // Play device vibration pattern as alarm feedback
    HapticFeedback.vibrate();
    await Future.delayed(const Duration(milliseconds: 300));
    HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 300));
    HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 300));
    HapticFeedback.heavyImpact();

    await _plugin.show(
      _timerDoneId,
      '⏱ $modeName Complete!',
      nextAction,
      _timerDetailsAlarm(ticker: 'Timer complete'),
    );
  }

  Future<void> showBackgroundTimer({
    required String modeName,
    required String timeRemaining,
  }) async {
    if (!_initialized) return;
    await _plugin.show(
      _backgroundId,
      '⏱ $modeName – $timeRemaining remaining',
      'Tap to return to the app.',
      _timerDetails(ticker: 'Timer running', ongoing: true, autoCancel: false),
    );
  }

  Future<void> updateBackgroundTimer({
    required String modeName,
    required String timeRemaining,
  }) => showBackgroundTimer(modeName: modeName, timeRemaining: timeRemaining);

  Future<void> cancelBackgroundTimer() => _plugin.cancel(_backgroundId);
  Future<void> cancelAll() => _plugin.cancelAll();

  // ── Study reminder scheduling ─────────────────────────────────────────────

  /// Call this when the user toggles notifications or study reminders ON.
  /// Schedules a morning (8 AM) and evening (8 PM) daily reminder.
  Future<void> scheduleStudyReminders() async {
    if (!_initialized) await init();
    try {
      // Cancel existing ones first
      await _plugin.cancel(_morningRemId);
      await _plugin.cancel(_eveningRemId);

      final location = tz.local;
      final now = tz.TZDateTime.now(location);

      // Morning: 8:00 AM
      var morning = tz.TZDateTime(location, now.year, now.month, now.day, 8, 0);
      if (morning.isBefore(now)) morning = morning.add(const Duration(days: 1));

      // Evening: 8:00 PM
      var evening = tz.TZDateTime(location, now.year, now.month, now.day, 20, 0);
      if (evening.isBefore(now)) evening = evening.add(const Duration(days: 1));

      await _plugin.zonedSchedule(
        _morningRemId,
        '📚 Good Morning! Time to Study',
        'Start your day strong — open your study planner.',
        morning,
        _reminderDetails(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );

      await _plugin.zonedSchedule(
        _eveningRemId,
        '🌙 Evening Study Session',
        'Don\'t forget your tasks for today. Keep the streak!',
        evening,
        _reminderDetails(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );

      debugPrint('[NotificationService] Study reminders scheduled.');
    } catch (e) {
      debugPrint('[NotificationService] Failed to schedule reminders: $e');
    }
  }

  /// Call this when the user toggles notifications or study reminders OFF.
  Future<void> cancelStudyReminders() async {
    await _plugin.cancel(_morningRemId);
    await _plugin.cancel(_eveningRemId);
    debugPrint('[NotificationService] Study reminders cancelled.');
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  NotificationDetails _timerDetailsAlarm({required String ticker}) {
    final android = AndroidNotificationDetails(
      _timerChannelId, _timerChannelName,
      channelDescription: _timerChannelDesc,
      importance: Importance.max,
      priority: Priority.max,
      ticker: ticker,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 500, 200, 500, 200, 500]),
      playSound: true,
      fullScreenIntent: true,
    );
    const ios = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );
    return NotificationDetails(android: android, iOS: ios);
  }

  NotificationDetails _timerDetails({
    required String ticker,
    bool ongoing    = false,
    bool autoCancel = true,
  }) {
    final android = AndroidNotificationDetails(
      _timerChannelId, _timerChannelName,
      channelDescription: _timerChannelDesc,
      importance: Importance.high, priority: Priority.high,
      ticker: ticker, ongoing: ongoing, autoCancel: autoCancel,
      enableVibration: true,
    );
    const ios = DarwinNotificationDetails(
      presentAlert: true, presentBadge: true, presentSound: true,
    );
    return NotificationDetails(android: android, iOS: ios);
  }

  NotificationDetails _reminderDetails() {
    const android = AndroidNotificationDetails(
      _reminderChannelId, _reminderChannelName,
      channelDescription: _reminderChannelDesc,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      enableVibration: true,
    );
    const ios = DarwinNotificationDetails(
      presentAlert: true, presentBadge: false, presentSound: true,
    );
    return const NotificationDetails(android: android, iOS: ios);
  }
}
