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
  // User / inventory
  // -------------------

  Future<User> getUser(int userId) {
    return (db.select(db.users)..where((u) => u.id.equals(userId))).getSingle();
  }

  Stream<User> watchUser(int userId) {
    return (db.select(db.users)..where((u) => u.id.equals(userId))).watchSingle();
  }

  Future<void> updateUserPet(int userId, String petId) {
    return (db.update(db.users)..where((u) => u.id.equals(userId))).write(
      UsersCompanion(petId: Value(petId)),
    );
  }

  Future<List<InventoryData>> listInventory(int userId) {
    return (db.select(db.inventory)
          ..where((i) => i.userId.equals(userId))
          ..orderBy([(i) => OrderingTerm.desc(i.createdAt)]))
        .get();
  }

  Stream<List<InventoryData>> watchInventory(int userId) {
    return (db.select(db.inventory)
          ..where((i) => i.userId.equals(userId))
          ..orderBy([(i) => OrderingTerm.desc(i.createdAt)]))
        .watch();
  }

  Future<bool> hasItem(int userId, String itemId) async {
    final row = await (db.select(db.inventory)
          ..where((i) => i.userId.equals(userId) & i.itemId.equals(itemId))
          ..limit(1))
        .getSingleOrNull();
    return row != null;
  }

  Future<bool> purchaseItem({
    required int userId,
    required String itemId,
    required int price,
  }) async {
    return db.transaction(() async {
      final user = await getUser(userId);
      if (user.coin < price) return false;

      final owned = await hasItem(userId, itemId);
      if (owned) return false;

      await (db.update(db.users)..where((u) => u.id.equals(userId))).write(
        UsersCompanion(coin: Value(user.coin - price)),
      );

      await db.into(db.inventory).insert(
            InventoryCompanion.insert(
              userId: userId,
              itemId: itemId,
              count: const Value(1),
              equipped: const Value(false),
            ),
          );
      return true;
    });
  }

  Future<void> equipItem({
    required int userId,
    required String itemId,
  }) async {
    await db.transaction(() async {
      final row = await (db.select(db.inventory)
            ..where((i) => i.userId.equals(userId) & i.itemId.equals(itemId)))
          .getSingleOrNull();
      if (row == null) return;

      await (db.update(db.inventory)..where((i) => i.userId.equals(userId))).write(
        const InventoryCompanion(equipped: Value(false)),
      );
      await (db.update(db.inventory)..where((i) => i.id.equals(row.id))).write(
        const InventoryCompanion(equipped: Value(true)),
      );
    });
  }

  Future<InventoryData?> getEquippedItem(int userId) {
    return (db.select(db.inventory)
          ..where((i) => i.userId.equals(userId) & i.equipped.equals(true))
          ..limit(1))
        .getSingleOrNull();
  }

  Stream<InventoryData?> watchEquippedItem(int userId) {
    return (db.select(db.inventory)
          ..where((i) => i.userId.equals(userId) & i.equipped.equals(true))
          ..limit(1))
        .watchSingleOrNull();
  }

  // -------------------
  // App settings
  // -------------------

  Future<String?> getSetting(String key) async {
    final row = await (db.select(db.appSettings)..where((t) => t.key.equals(key))).getSingleOrNull();
    return row?.value;
  }

  Stream<String?> watchSetting(String key) {
    final q = db.select(db.appSettings)..where((t) => t.key.equals(key));
    return q.watchSingleOrNull().map((row) => row?.value);
  }

  Future<void> setSetting(String key, String value) async {
    await db.into(db.appSettings).insertOnConflictUpdate(
          AppSettingsCompanion.insert(
            key: key,
            value: value,
            updatedAt: Value(DateTime.now()),
          ),
        );
  }

  Future<Map<String, dynamic>> getSettingsBundle(Map<String, dynamic> gameConfig) async {
    final defaults = (gameConfig['defaults'] as Map?)?.cast<String, dynamic>() ?? const {};
    final mode = await getSetting('mode') ?? defaults['mode']?.toString() ?? 'mixed';
    final theme = await getSetting('theme') ?? defaults['theme']?.toString() ?? 'tomato_strong';
    final dayCutoff = await getSetting('dayCutoff') ?? defaults['dayCutoff']?.toString() ?? '00:00';
    final finishNotify = (await getSetting('finishNotify')) ?? 'true';
    final ongoingNotify = (await getSetting('ongoingNotify')) ?? 'true';

    return {
      'mode': mode,
      'theme': theme,
      'dayCutoff': dayCutoff,
      'finishNotify': finishNotify == 'true',
      'ongoingNotify': ongoingNotify == 'true',
    };
  }

  Future<void> saveSettingsBundle({
    required String mode,
    required String theme,
    required String dayCutoff,
    required bool finishNotify,
    required bool ongoingNotify,
  }) async {
    await db.transaction(() async {
      await setSetting('mode', mode);
      await setSetting('theme', theme);
      await setSetting('dayCutoff', dayCutoff);
      await setSetting('finishNotify', finishNotify.toString());
      await setSetting('ongoingNotify', ongoingNotify.toString());
    });
  }

  // -------------------
  // Tasks
  // -------------------

  Stream<List<Task>> watchVisibleTasks() {
    return (db.select(db.tasks)
          ..where((t) => t.status.equals('active') | t.status.equals('paused'))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .watch();
  }

  Future<List<Task>> listVisibleTasks() {
    return (db.select(db.tasks)
          ..where((t) => t.status.equals('active') | t.status.equals('paused'))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
  }

  Future<int> createTask({
    required String name,
    int targetMinutes = 30,
    bool required = false,
  }) {
    return db.into(db.tasks).insert(
          TasksCompanion.insert(
            name: name,
            targetMinutes: Value(targetMinutes),
            required: Value(required),
            status: const Value('active'),
          ),
        );
  }

  Future<void> updateTask(
    int id, {
    required String name,
    required int targetMinutes,
    required bool required,
  }) {
    return (db.update(db.tasks)..where((t) => t.id.equals(id))).write(
      TasksCompanion(
        name: Value(name),
        targetMinutes: Value(targetMinutes),
        required: Value(required),
      ),
    );
  }

  Future<void> setTaskStatus(int id, String status) {
    return (db.update(db.tasks)..where((t) => t.id.equals(id))).write(
      TasksCompanion(status: Value(status)),
    );
  }

  Future<void> archiveTask(int id) {
    return setTaskStatus(id, 'archived');
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

  Future<int> getBestConsecutiveStreak({required String endDateYYYYMMDD}) async {
    final rows = await (db.selectOnly(db.completionLogs)
          ..addColumns([db.completionLogs.date])
          ..groupBy([db.completionLogs.date])
          ..orderBy([OrderingTerm.asc(db.completionLogs.date)]))
        .get();

    final dates = rows.map((e) => e.read(db.completionLogs.date)).whereType<String>().toList();
    if (dates.isEmpty) return 0;

    var best = 0;
    var current = 0;
    DateTime? last;

    for (final s in dates) {
      final d = DateTime.parse(s);
      if (last == null) {
        current = 1;
      } else {
        final diff = d.difference(last).inDays;
        current = diff == 1 ? current + 1 : 1;
      }
      if (current > best) best = current;
      last = d;
    }

    return best;
  }

  Future<int> getTrailingStreak(String dateYYYYMMDD) async {
    final rows = await (db.selectOnly(db.completionLogs)
          ..addColumns([db.completionLogs.date])
          ..groupBy([db.completionLogs.date])
          ..orderBy([OrderingTerm.asc(db.completionLogs.date)]))
        .get();

    final set = rows.map((e) => e.read(db.completionLogs.date)).whereType<String>().toSet();
    var streak = 0;
    var cursor = DateTime.parse(dateYYYYMMDD);

    while (set.contains(_dateOnly(cursor))) {
      streak += 1;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  Future<void> syncUserStreak({
    required int userId,
    required String dateYYYYMMDD,
  }) async {
    final current = await getTrailingStreak(dateYYYYMMDD);
    final best = await getBestConsecutiveStreak(endDateYYYYMMDD: dateYYYYMMDD);
    await (db.update(db.users)..where((u) => u.id.equals(userId))).write(
      UsersCompanion(
        streak: Value(current),
        bestStreak: Value(best),
      ),
    );
  }

  // -------------------
  // Completion logs
  // -------------------

  Future<List<RecentCompletion>> listRecentCompletions({
    required String dateYYYYMMDD,
    int limit = 10,
  }) async {
    final q = db.select(db.completionLogs)
      ..where((c) => c.date.equals(dateYYYYMMDD))
      ..orderBy([(c) => OrderingTerm.desc(c.createdAt)])
      ..limit(limit);

    final logs = await q.get();
    if (logs.isEmpty) return [];

    final taskIds = logs.map((e) => e.taskId).toSet().toList();
    final tasks = await (db.select(db.tasks)..where((t) => t.id.isIn(taskIds))).get();
    final nameById = {for (final t in tasks) t.id: t.name};

    return logs
        .map(
          (l) => RecentCompletion(
            id: l.id,
            taskId: l.taskId,
            taskName: nameById[l.taskId] ?? '任务#${l.taskId}',
            minutes: l.minutes,
            source: l.source,
            createdAt: l.createdAt,
          ),
        )
        .toList();
  }
}

String _dateOnly(DateTime d) {
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '$y-$m-$day';
}

class DailyMinutes {
  final String date; // YYYY-MM-DD
  final int minutes;
  DailyMinutes({required this.date, required this.minutes});
}

class RecentCompletion {
  final int id;
  final int taskId;
  final String taskName;
  final int minutes;
  final String source;
  final DateTime createdAt;
  RecentCompletion({
    required this.id,
    required this.taskId,
    required this.taskName,
    required this.minutes,
    required this.source,
    required this.createdAt,
  });
}
