import 'dart:async';

import 'package:flutter/widgets.dart';

import 'app_nav.dart';
import 'config/config_loader.dart';
import 'db/app_db.dart';
import 'db/dao.dart';
import 'services/reward_service.dart';
import 'timer/notifications.dart';
import 'timer/notification_handler.dart';
import 'timer/timer_service.dart';
import 'ui/sheets/log_completion_sheet.dart';
import 'utils/day_cutoff.dart';

/// Example bootstrap wiring for notifications -> timer actions.
///
/// Call [bootstrapPomopet] early in app startup (before showing UI).
class PomopetRuntime {
  final AppDb db;
  final TimerService timer;
  final NotificationActionHandler notificationHandler;

  PomopetRuntime({
    required this.db,
    required this.timer,
    required this.notificationHandler,
  });
}

Future<PomopetRuntime> bootstrapPomopet() async {
  WidgetsFlutterBinding.ensureInitialized();

  final db = AppDb();
  final timer = TimerService(db);

  final handler = NotificationActionHandler(
    onPause: () async {
      final s = await db.select(db.timerSessions).getSingleOrNull();
      if (s != null) await timer.pause(s.id);
    },
    onResume: () async {
      final s = await db.select(db.timerSessions).getSingleOrNull();
      if (s != null) await timer.resume(s.id);
    },
    onStop: () async {
      final s = await db.select(db.timerSessions).getSingleOrNull();
      if (s != null) await timer.stop(s.id);
    },
  );

  final config = await ConfigLoader().loadAssets();
  final rewards = RewardService();
  final dao = PomopetDao(db);

  await Notifications.init(
    onAction: (actionId, payload) async {
      // 1) action buttons
      await handler.handle(actionId);

      // 2) tapping finish notification: open log completion sheet
      if (actionId == null) {
        final p = payload ?? const <String, dynamic>{};
        final kind = (p['kind'] as String?) ?? '';
        if (kind == 'timer_finish') {
          final ctx = pomopetContext;
          if (ctx != null) {
            final sid = (p['sessionId'] as String?) ?? '';
            final session = sid.isNotEmpty ? await dao.getSessionById(sid) : await dao.getActiveSession();
            final planned = session?.plannedMinutes ?? 25;
            final res = await LogCompletionSheet.show(
              ctx,
              dao: dao,
              title: '番茄完成！要入账吗？',
              defaultMinutes: planned,
            );
            if (res != null) {
              if (res.taskId == null) return;

              final cutoff = await dao.getSetting('dayCutoff') ??
                  (config.game['defaults']?['dayCutoff'] as String?) ??
                  '00:00';
              final date = logicalDate(DateTime.now(), cutoff: cutoff);
              await logCompletionTx(
                db: db,
                rewards: rewards,
                game: config.game,
                userId: 1,
                taskId: res.taskId!,
                dateYYYYMMDD: date,
                minutes: res.minutes,
                source: 'timer',
                dao: dao,
              );
            }
          }
        }
      }
    },
  );

  // Reconcile on startup.
  await timer.reconcile();

  return PomopetRuntime(db: db, timer: timer, notificationHandler: handler);
}
