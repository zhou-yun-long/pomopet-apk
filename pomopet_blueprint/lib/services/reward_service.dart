import '../db/app_db.dart';

class Reward {
  final int xp;
  final int coin;
  final bool verified;
  Reward({required this.xp, required this.coin, required this.verified});
}

class RewardService {
  /// Calculate reward using game_config.json.
  ///
  /// Expected structure:
  /// game['rewards']['sources'][source] -> { xpPerMinute, coinPerMinute, verified }
  /// game['rewards']['basePerLog'] -> { xp, coin }
  Reward calc({
    required int minutes,
    required String source,
    required Map<String, dynamic> game,
  }) {
    final rewards = (game['rewards'] as Map).cast<String, dynamic>();
    final sources = (rewards['sources'] as Map).cast<String, dynamic>();
    final base = (rewards['basePerLog'] as Map).cast<String, dynamic>();

    final baseXp = (base['xp'] as num).toInt();
    final baseCoin = (base['coin'] as num).toInt();

    final s = (sources[source] as Map).cast<String, dynamic>();
    final xpPerMin = (s['xpPerMinute'] as num).toDouble();
    final coinPerMin = (s['coinPerMinute'] as num).toDouble();
    final verified = ((s['verified'] as num).toInt() == 1);

    final xp = baseXp + (minutes * xpPerMin).round();
    final coin = baseCoin + (minutes * coinPerMin).round();

    return Reward(xp: xp, coin: coin, verified: verified);
  }

  /// Compute level from total xp using game_config.json leveling formula.
  ///
  /// Uses:
  /// game['pet']['leveling'] -> { maxLevel, xpPerLevelBase, xpPerLevelGrowth }
  int levelFromXp(int xp, Map<String, dynamic> game) {
    final pet = (game['pet'] as Map).cast<String, dynamic>();
    final leveling = (pet['leveling'] as Map).cast<String, dynamic>();
    final maxLevel = (leveling['maxLevel'] as num).toInt();
    final base = (leveling['xpPerLevelBase'] as num).toInt();
    final growth = (leveling['xpPerLevelGrowth'] as num).toInt();

    var level = 1;
    var need = base;
    var remain = xp;
    while (remain >= need && level < maxLevel) {
      remain -= need;
      level += 1;
      need += growth;
    }
    return level;
  }
}

/// Transaction helper to log completion and update user xp/coin/level.
Future<Reward> logCompletionTx({
  required AppDb db,
  required RewardService rewards,
  required Map<String, dynamic> game,
  required int userId,
  required int taskId,
  required String dateYYYYMMDD,
  required int minutes,
  required String source,
  String? attachmentPath,
}) async {
  final reward = rewards.calc(minutes: minutes, source: source, game: game);

  await db.transaction(() async {
    await db.into(db.completionLogs).insert(CompletionLogsCompanion.insert(
          taskId: taskId,
          date: dateYYYYMMDD,
          minutes: minutes,
          source: source,
          verified: Value(reward.verified),
          attachmentPath: Value(attachmentPath),
        ));

    final user = await (db.select(db.users)..where((u) => u.id.equals(userId))).getSingle();
    final newXp = user.xp + reward.xp;
    final newCoin = user.coin + reward.coin;
    final newLevel = rewards.levelFromXp(newXp, game);

    await (db.update(db.users)..where((u) => u.id.equals(userId))).write(
      UsersCompanion(
        xp: Value(newXp),
        coin: Value(newCoin),
        level: Value(newLevel),
      ),
    );
  });

  return reward;
}
