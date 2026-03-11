import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'notification_actions.dart';

/// Local notifications wrapper for Pomopet timer.
///
/// Notes:
/// - iOS: we schedule a single finish notification.
/// - Android: we show a persistent "running" notification with action buttons,
///   plus a finish notification at end.
class Notifications {
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  /// Notification channel id for timer.
  static const String _timerChannelId = 'pomopet_timer';

  /// Android notification id used for the ongoing timer notification.
  static const int timerOngoingId = 1001;

  /// Android notification id used for the finish notification.
  static const int timerFinishId = 1002;

  static bool _initialized = false;

  static Future<void> init({
    required Future<void> Function(String? actionId, Map<String, dynamic>? payload) onAction,
  }) async {
    if (_initialized) return;

    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (resp) async {
        final payload = _decodePayload(resp.payload);
        await onAction(resp.actionId, payload);
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    // Create Android channel.
    final android = _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      await android.createNotificationChannel(const AndroidNotificationChannel(
        _timerChannelId,
        'Pomopet Timer',
        description: 'Pomopet timer notifications and controls',
        importance: Importance.high,
      ));
    }

    _initialized = true;
  }

  /// iOS permission request — call this when user first starts a timer.
  static Future<bool> requestPermissionsIOS() async {
    final ios = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    if (ios == null) return true;
    final ok = await ios.requestPermissions(alert: true, badge: false, sound: true);
    return ok ?? false;
  }

  static Future<void> showOngoing({
    required String sessionId,
    required String title,
    required String body,
    required Map<String, dynamic> payload,
    bool paused = false,
  }) async {
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _timerChannelId,
        'Pomopet Timer',
        channelDescription: 'Pomopet timer notifications and controls',
        importance: Importance.high,
        priority: Priority.high,
        ongoing: true,
        autoCancel: false,
        showWhen: false,
        category: AndroidNotificationCategory.stopwatch,
        actions: <AndroidNotificationAction>[
          AndroidNotificationAction(
            paused ? NotificationActions.timerResume : NotificationActions.timerPause,
            paused ? '继续' : '暂停',
            showsUserInterface: true,
          ),
          const AndroidNotificationAction(
            NotificationActions.timerStop,
            '结束',
            showsUserInterface: true,
          ),
        ],
      ),
      iOS: const DarwinNotificationDetails(),
    );

    await _plugin.show(
      timerOngoingId,
      title,
      body,
      details,
      payload: _encodePayload(<String, dynamic>{'sessionId': sessionId, ...payload}),
    );
  }

  static Future<void> cancelOngoing() async {
    await _plugin.cancel(timerOngoingId);
  }

  /// Schedule a finish notification at [at].
  static Future<void> scheduleFinish({
    required String sessionId,
    required DateTime at,
    Map<String, dynamic>? payload,
  }) async {
    final when = tz.TZDateTime.from(at, tz.local);

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _timerChannelId,
        'Pomopet Timer',
        channelDescription: 'Pomopet timer notifications and controls',
        importance: Importance.high,
        priority: Priority.high,
        ongoing: false,
        autoCancel: true,
        category: AndroidNotificationCategory.alarm,
      ),
      iOS: const DarwinNotificationDetails(presentAlert: true, presentSound: true),
    );

    final p = <String, dynamic>{
      'kind': 'timer_finish',
      'sessionId': sessionId,
      ...(payload ?? {}),
    };

    await _plugin.zonedSchedule(
      timerFinishId,
      '番茄完成！',
      '回到 Pomopet 记为完成领奖励',
      when,
      details,
      payload: _encodePayload(p),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: null,
    );
  }

  static Future<void> cancelFinish() async {
    await _plugin.cancel(timerFinishId);
  }

  static String _encodePayload(Map<String, dynamic> payload) {
    try {
      return jsonEncode(payload);
    } catch (_) {
      return '{}';
    }
  }

  static Map<String, dynamic>? _decodePayload(String? payload) {
    if (payload == null || payload.isEmpty) return null;
    try {
      final v = jsonDecode(payload);
      if (v is Map<String, dynamic>) return v;
      return null;
    } catch (e) {
      if (kDebugMode) {
        // ignore
      }
      return null;
    }
  }
}

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  // Required for background callback. Intentionally empty.
}
