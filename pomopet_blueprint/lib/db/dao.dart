import 'package:drift/drift.dart';

import 'app_db.dart';

class PomopetDao {
  final AppDb db;
  PomopetDao(this.db);

  // -------------------
  // Timer session
  // -------------------

  Future<TimerSession?> getActiveSession() {
    return (db.select(db.timerSessions)
          ..where((t) => t.status.equals('running') | t.status.equals('paused'))
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])
          ..limit(1))
        .getSingleOrNull();
  }

  Future<TimerSession?> getSessionById(String id) {
    return (db.select(db.timerSessions)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Stream<TimerSession?> watchActiveSession() {
    final q = db.select(db.timerSessions)
      ..where((t) => t.status.equals('running') | t.status.equals('paused'))
      ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])
      ..limit(1);
    return q.watchSingleOrNull();
  }

  // -------------------
  // Tasks
  // -------------------

  Stream<List<Task>> watchActiveTasks() {
    return (db.select(db.tasks)..where((t) => t.status.equals('active'))).watch();
  }

  Future<List<Task>> listActiveTasks() {
    return (db.select(db.tasks)..where((t) => t.status.equals('active'))).get();
  }

  // -------------------
  // Completion stats
  // -------------------

  Future<int> getTotalMinutesByDate(String dateYYYYMMDD) async {
    final exp = db.completionLogs.minutes.sum();

    final row = await (db.selectOnly(db.completionLogs)
          ..addColumns([exp])
          ..where(db.completionLogs.date.equals(dateYYYYMMDD)))
        .getSingle();

    return row.read(exp) ?? 0;
  }

  /// taskId -> minutes
  Future<Map<int, int>> getMinutesByTaskOnDate(String dateYYYYMMDD) async {
    final sumExp = db.completionLogs.minutes.sum();

    final rows = await (db.selectOnly(db.completionLogs)
          ..addColumns([db.completionLogs.taskId, sumExp])
          ..where(db.completionLogs.date.equals(dateYYYYMMDD))
          ..groupBy([db.completionLogs.taskId]))
        .get();

    final map = <int, int>{};
    for (final r in rows) {
      final taskId = r.read(db.completionLogs.taskId);
      final minutes = r.read(sumExp) ?? 0;
      if (taskId != null) map[taskId] = minutes;
    }
    return map;
  }

  /// Daily totals for a date range (YYYY-MM-DD strings).
  Future<List<DailyMinutes>> getDailyMinutesRange({
    required String startDateYYYYMMDD,
    required String endDateYYYYMMDD,
  }) async {
    final sumExp = db.completionLogs.minutes.sum();

    final rows = await (db.selectOnly(db.completionLogs)
          ..addColumns([db.completionLogs.date, sumExp])
          ..where(db.completionLogs.date.isBetweenValues(startDateYYYYMMDD, endDateYYYYMMDD))
          ..groupBy([db.completionLogs.date])
          ..orderBy([OrderingTerm.asc(db.completionLogs.date)]))
        .get();

    return rows
        .map(
          (r) => DailyMinutes(
            date: r.read(db.completionLogs.date)!,
            minutes: r.read(sumExp) ?? 0,
          ),
        )
        .toList();
  }
}

class DailyMinutes {
  final String date; // YYYY-MM-DD
  final int minutes;
  DailyMinutes({required this.date, required this.minutes});
}
