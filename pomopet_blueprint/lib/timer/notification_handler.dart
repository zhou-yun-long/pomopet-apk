import 'notification_actions.dart';

/// Handle notification button callbacks.
///
/// Wire this into flutter_local_notifications (onDidReceiveNotificationResponse).
///
/// This file only defines the dispatch layer; hook it up to your TimerService.
class NotificationActionHandler {
  final Future<void> Function() onPause;
  final Future<void> Function() onResume;
  final Future<void> Function() onStop;

  NotificationActionHandler({
    required this.onPause,
    required this.onResume,
    required this.onStop,
  });

  Future<void> handle(String? actionId) async {
    switch (actionId) {
      case NotificationActions.timerPause:
        return onPause();
      case NotificationActions.timerResume:
        return onResume();
      case NotificationActions.timerStop:
        return onStop();
      default:
        return;
    }
  }
}
