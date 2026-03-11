import 'dart:async';

import '../db/app_db.dart';
import 'notifications.dart';

/// A minimal, endAt-based timer service.
///
/// Design principles:
/// - Do not trust tick accumulation; always compute remaining via endAt.
/// - Persist a TimerSession to allow recovery.
/// - Drive notifications from persisted session.
class TimerService {
  final AppDb db;

  TimerService(this.db);

  /// Start a focus session.
  Future<String> startFocus({
    required int userId,
    int? taskId,
    required String presetId,
    required int focusMinutes,
    int breakIndex = 0,
  }) async {
    final id = _uuid();
    final now = DateTime.now();
    final endAt = now.add(Duration(minutes: focusMinutes));

    await db.into(db.timerSessions).insert(TimerSessionsCompanion.insert(
          id: id,
          userId: userId,
          taskId: Value(taskId),
          presetId: Value(presetId),
          phase: const Value('focus'),
          status: const Value('running'),
          plannedMinutes: focusMinutes,
          startedAt: now,
          endAt: endAt,
          breakIndex: Value(breakIndex),
        ));

    // Ongoing notification (Android) + finish schedule (iOS/Android)
    await Notifications.showOngoing(
      sessionId: id,
      title: '专注中',
      body: _formatRemaining(endAt.difference(now).inSeconds),
      payload: const <String, dynamic>{},
      paused: false,
    );
    await Notifications.scheduleFinish(sessionId: id, at: endAt, payload: <String, dynamic>{'kind': 'timer_finish', 'sessionId': id});

    return id;
  }

  Future<void> pause(String sessionId) async {
    final now = DateTime.now();
    final s = await _get(sessionId);
    if (s == null || s.status != 'running') return;

    final remaining = s.endAt.difference(now).inSeconds;
    await (db.update(db.timerSessions)..where((t) => t.id.equals(sessionId))).write(
      TimerSessionsCompanion(
        status: const Value('paused'),
        pausedAt: Value(now),
        elapsedSeconds: Value((s.plannedMinutes * 60) - remaining),
        updatedAt: Value(now),
      ),
    );

    await Notifications.cancelFinish();
    await Notifications.showOngoing(
      sessionId: sessionId,
      title: '已暂停',
      body: '点一下继续喂小兽',
      payload: const <String, dynamic>{},
      paused: true,
    );
  }

  Future<void> resume(String sessionId) async {
    final now = DateTime.now();
    final s = await _get(sessionId);
    if (s == null || s.status != 'paused') return;

    final remaining = (s.plannedMinutes * 60) - s.elapsedSeconds;
    final endAt = now.add(Duration(seconds: remaining));

    await (db.update(db.timerSessions)..where((t) => t.id.equals(sessionId))).write(
      TimerSessionsCompanion(
        status: const Value('running'),
        pausedAt: const Value(null),
        endAt: Value(endAt),
        updatedAt: Value(now),
      ),
    );

    await Notifications.showOngoing(
      sessionId: sessionId,
      title: '专注中',
      body: _formatRemaining(remaining),
      payload: const <String, dynamic>{},
      paused: false,
    );
    await Notifications.scheduleFinish(sessionId: sessionId, at: endAt, payload: <String, dynamic>{'kind': 'timer_finish', 'sessionId': sessionId});
  }

  Future<void> stop(String sessionId) async {
    final now = DateTime.now();
    await (db.update(db.timerSessions)..where((t) => t.id.equals(sessionId))).write(
      TimerSessionsCompanion(
        status: const Value('canceled'),
        finishedAt: Value(now),
        updatedAt: Value(now),
      ),
    );
    await Notifications.cancelFinish();
    await Notifications.cancelOngoing();
  }

  /// Mark finished (UI should prompt user to log completion).
  Future<void> markFinished(String sessionId) async {
    final now = DateTime.now();
    await (db.update(db.timerSessions)..where((t) => t.id.equals(sessionId))).write(
      TimerSessionsCompanion(
        status: const Value('finished'),
        finishedAt: Value(now),
        updatedAt: Value(now),
      ),
    );

    // Update ongoing notification to completed (optional)
    await Notifications.showOngoing(
      sessionId: sessionId,
      title: '番茄完成！',
      body: '回到 Pomopet 记为完成领奖励',
      payload: const <String, dynamic>{},
      paused: false,
    );
  }

  /// Periodic check to auto-finish if endAt has passed (e.g. after app resume).
  Future<void> reconcile() async {
    final s = await _getActive();
    if (s == null) return;
    if (s.status == 'running' && DateTime.now().isAfter(s.endAt)) {
      await markFinished(s.id);
    }
  }

  Future<TimerSession?> _get(String id) {
    return (db.select(db.timerSessions)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<TimerSession?> _getActive() {
    return (db.select(db.timerSessions)
          ..where((t) => t.status.equals('running') | t.status.equals('paused'))
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])
          ..limit(1))
        .getSingleOrNull();
  }

  String _uuid() => DateTime.now().microsecondsSinceEpoch.toString();

  String _formatRemaining(int seconds) {
    final s = seconds < 0 ? 0 : seconds;
    final m = (s ~/ 60).toString().padLeft(2, '0');
    final ss = (s % 60).toString().padLeft(2, '0');
    return '还剩 $m:$ss';
  }
}
