import 'package:flutter/material.dart';

import '../../db/app_db.dart';
import '../../db/dao.dart';
import '../../services/reward_service.dart';

class PetPage extends StatelessWidget {
  final PomopetDao dao;
  final Map<String, dynamic> gameConfig;
  final int userId;

  const PetPage({
    super.key,
    required this.dao,
    required this.gameConfig,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('小兽')),
      body: StreamBuilder<User>(
        stream: dao.watchUser(userId),
        builder: (context, snapshot) {
          final user = snapshot.data;
          if (user == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final pet = _findPet(gameConfig, user.petId);
          final stage = _findStage(gameConfig, user.level);
          final nextStage = _findNextStage(gameConfig, user.level);
          final progress = _levelProgress(user.level, user.xp, gameConfig);
          final availableSpecies = _availableSpecies(gameConfig, user.streak);

          return StreamBuilder<List<InventoryData>>(
            stream: dao.watchInventory(userId),
            builder: (context, invSnap) {
              final inventory = invSnap.data ?? const <InventoryData>[];
              InventoryData? equipped;
              for (final item in inventory) {
                if (item.equipped) {
                  equipped = item;
                  break;
                }
              }

              return ListView(
                padding: const EdgeInsets.all(18),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        children: [
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              Text(_petEmoji(user.petId), style: const TextStyle(fontSize: 64)),
                              if (equipped != null)
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      _itemVisualBadge(gameConfig, equipped.itemId),
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            pet['name']?.toString() ?? '小兽',
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${stage['name'] ?? '成长中'} · Lv.${user.level}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 14),
                          LinearProgressIndicator(value: progress),
                          const SizedBox(height: 10),
                          Text(
                            nextStage == null
                                ? '已经接近完全体了'
                                : '距离下一阶段「${nextStage['name']}」越来越近',
                          ),
                          const SizedBox(height: 8),
                          Text(
                            equipped == null
                                ? '当前装扮：无'
                                : '当前装扮：${_inventoryDisplayName(gameConfig, equipped.itemId)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.04),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _petStateLabel(user.streak, user.level),
                                  style: const TextStyle(fontWeight: FontWeight.w900),
                                ),
                                const SizedBox(height: 4),
                                Text(_petMoodText(user.streak, user.level)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FutureBuilder<List<RecentCompletion>>(
                    future: dao.listRecentCompletions(
                      dateYYYYMMDD: _dateOnly(DateTime.now()),
                      limit: 24,
                    ),
                    builder: (context, recentSnap) {
                      final recents = recentSnap.data ?? const <RecentCompletion>[];
                      final recent = recents.isNotEmpty ? recents.first : null;
                      final proofCount = recents.where((e) => e.source == 'proof').length;
                      final totalFeeds = recents.length;
                      final lastFeedTime = recent == null ? null : _hhmm(recent.createdAt);
                      final growth = _todayGrowthSummary(recents, gameConfig);
                      final xpToNext = _xpToNextLevel(user.level, user.xp, gameConfig);

                      return Column(
                        children: [
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('今日状态面板', style: TextStyle(fontWeight: FontWeight.w900)),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _PetStatusMiniCard(
                                          emoji: '🍽️',
                                          label: '今日喂养',
                                          value: '$totalFeeds 次',
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: _PetStatusMiniCard(
                                          emoji: '📸',
                                          label: '凭证次数',
                                          value: '$proofCount 次',
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: _PetStatusMiniCard(
                                          emoji: '🕒',
                                          label: '最后喂养',
                                          value: lastFeedTime ?? '--:--',
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    totalFeeds == 0
                                        ? '今天还没开喂，来一轮番茄，我就开始长。'
                                        : proofCount > 0
                                            ? '今天已经认真喂了 $totalFeeds 次，其中 $proofCount 次还带了凭证。'
                                            : '今天已经喂了 $totalFeeds 次，再来一轮我还能继续涨状态。',
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('今日成长结果', style: TextStyle(fontWeight: FontWeight.w900)),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _PetStatusMiniCard(
                                          emoji: '⭐',
                                          label: '今日 XP',
                                          value: '+${growth.xp}',
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: _PetStatusMiniCard(
                                          emoji: '🪙',
                                          label: '今日金币',
                                          value: '+${growth.coin}',
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: _PetStatusMiniCard(
                                          emoji: '⏱️',
                                          label: '今日分钟',
                                          value: '${growth.minutes}',
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    growth.minutes == 0
                                        ? '今天还没把成长值推起来，先喂一轮就会动。'
                                        : xpToNext <= 0
                                            ? '这一级已经吃满了，继续喂就准备冲下一阶段。'
                                            : '按现在进度，再拿 $xpToNext XP 就能更靠近下一阶段。',
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: recent == null
                                  ? const Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('最近一次喂养', style: TextStyle(fontWeight: FontWeight.w900)),
                                        SizedBox(height: 6),
                                        Text('今天还没喂我。来一轮番茄，我就会记住。'),
                                      ],
                                    )
                                  : Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('最近一次喂养', style: TextStyle(fontWeight: FontWeight.w900)),
                                        const SizedBox(height: 6),
                                        Text('${recent.taskName} · ${recent.minutes} 分钟', style: const TextStyle(fontWeight: FontWeight.w800)),
                                        const SizedBox(height: 4),
                                        Text(
                                          recent.source == 'proof'
                                              ? '这次是凭证完成，我已经认真收下了。'
                                              : recent.source == 'timer'
                                                  ? '这轮是正经番茄喂养，我记得很清楚。'
                                                  : '这次是补录完成，我也算进成长里了。',
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          icon: Icons.auto_awesome,
                          label: '经验',
                          value: '${user.xp} XP',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatCard(
                          icon: Icons.monetization_on,
                          label: '金币',
                          value: '${user.coin}',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatCard(
                          icon: Icons.local_fire_department,
                          label: '连续天数',
                          value: '${user.streak}',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('可选小兽', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 8),
                  ...availableSpecies.map(
                    (species) {
                      final selected = species['id'] == user.petId;
                      return Card(
                        child: ListTile(
                          leading: Text(_petEmoji(species['id']?.toString()), style: const TextStyle(fontSize: 28)),
                          title: Text(species['name']?.toString() ?? '小兽'),
                          subtitle: Text(selected ? '当前使用中' : '点击切换小兽形象'),
                          trailing: selected
                              ? const Icon(Icons.check_circle, color: Colors.green)
                              : FilledButton.tonal(
                                  onPressed: () async {
                                    await dao.updateUserPet(userId, species['id'].toString());
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('已切换为 ${species['name']}')),
                                    );
                                  },
                                  child: const Text('切换'),
                                ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text('商店', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 8),
                  ..._shopItems(gameConfig).map(
                    (item) {
                      final owned = inventory.any((e) => e.itemId == item.id);
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.storefront_outlined),
                          title: Text(item.name),
                          subtitle: Text('${item.type} · ${item.rarityLabel}'),
                          trailing: owned
                              ? const Text('已拥有')
                              : FilledButton.tonal(
                                  onPressed: () async {
                                    final ok = await dao.purchaseItem(
                                      userId: userId,
                                      itemId: item.id,
                                      price: item.price,
                                    );
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(ok ? '已购买 ${item.name}' : '购买失败：金币不够或已拥有')),
                                    );
                                  },
                                  child: Text('${item.price} 金币'),
                                ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text('背包 / 装扮', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 8),
                  if (inventory.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('背包还是空的。先去上面商店买点装扮。'),
                      ),
                    )
                  else
                    ...inventory.map(
                      (item) => Card(
                        child: ListTile(
                          leading: const Icon(Icons.inventory_2_outlined),
                          title: Text(_inventoryDisplayName(gameConfig, item.itemId)),
                          subtitle: Text(item.equipped ? '已装备中' : '已拥有，可装备'),
                          trailing: item.equipped
                              ? const Icon(Icons.check_circle, color: Colors.green)
                              : FilledButton.tonal(
                                  onPressed: () async {
                                    await dao.equipItem(userId: userId, itemId: item.itemId);
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('已装备 ${_inventoryDisplayName(gameConfig, item.itemId)}')),
                                    );
                                  },
                                  child: const Text('装备'),
                                ),
                        ),
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _PetStatusMiniCard extends StatelessWidget {
  final String emoji;
  final String label;
  final String value;

  const _PetStatusMiniCard({
    required this.emoji,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 2),
          Text(label, style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatCard({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Icon(icon),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

Map<String, dynamic> _findPet(Map<String, dynamic> gameConfig, String petId) {
  final species = ((gameConfig['pet']?['species'] as List?) ?? const [])
      .cast<Map>()
      .map((e) => e.cast<String, dynamic>())
      .toList();
  return species.firstWhere(
    (e) => e['id'] == petId,
    orElse: () => {'id': petId, 'name': '小兽'},
  );
}

Map<String, dynamic> _findStage(Map<String, dynamic> gameConfig, int level) {
  final stages = ((gameConfig['pet']?['stages'] as List?) ?? const [])
      .cast<Map>()
      .map((e) => e.cast<String, dynamic>())
      .toList()
    ..sort((a, b) => ((a['minLevel'] as num?) ?? 1).compareTo((b['minLevel'] as num?) ?? 1));

  Map<String, dynamic> current = stages.isNotEmpty ? stages.first : {'name': '成长中', 'minLevel': 1};
  for (final s in stages) {
    if (level >= ((s['minLevel'] as num?) ?? 1)) {
      current = s;
    }
  }
  return current;
}

Map<String, dynamic>? _findNextStage(Map<String, dynamic> gameConfig, int level) {
  final stages = ((gameConfig['pet']?['stages'] as List?) ?? const [])
      .cast<Map>()
      .map((e) => e.cast<String, dynamic>())
      .toList()
    ..sort((a, b) => ((a['minLevel'] as num?) ?? 1).compareTo((b['minLevel'] as num?) ?? 1));

  for (final s in stages) {
    if (level < ((s['minLevel'] as num?) ?? 1)) return s;
  }
  return null;
}

class _TodayGrowthSummary {
  final int xp;
  final int coin;
  final int minutes;

  const _TodayGrowthSummary({
    required this.xp,
    required this.coin,
    required this.minutes,
  });
}

_TodayGrowthSummary _todayGrowthSummary(
  List<RecentCompletion> recents,
  Map<String, dynamic> gameConfig,
) {
  final rewards = RewardService();
  var xp = 0;
  var coin = 0;
  var minutes = 0;

  for (final item in recents) {
    final reward = rewards.calc(
      minutes: item.minutes,
      source: item.source,
      game: gameConfig,
    );
    xp += reward.xp;
    coin += reward.coin;
    minutes += item.minutes;
  }

  return _TodayGrowthSummary(xp: xp, coin: coin, minutes: minutes);
}

int _xpToNextLevel(int level, int xp, Map<String, dynamic> gameConfig) {
  final leveling = (gameConfig['pet']?['leveling'] as Map?)?.cast<String, dynamic>() ?? const {};
  final maxLevel = (leveling['maxLevel'] as num?)?.toInt() ?? 999;
  final base = (leveling['xpPerLevelBase'] as num?)?.toInt() ?? 120;
  final growth = (leveling['xpPerLevelGrowth'] as num?)?.toInt() ?? 12;

  if (level >= maxLevel) return 0;

  var accumulated = 0;
  for (var lv = 1; lv < level; lv++) {
    accumulated += base + ((lv - 1) * growth);
  }

  final needThisLevel = base + ((level - 1) * growth);
  final current = (xp - accumulated).clamp(0, needThisLevel);
  return needThisLevel - current;
}

double _levelProgress(int level, int xp, Map<String, dynamic> gameConfig) {
  final leveling = (gameConfig['pet']?['leveling'] as Map?)?.cast<String, dynamic>() ?? const {};
  final base = (leveling['xpPerLevelBase'] as num?)?.toInt() ?? 120;
  final growth = (leveling['xpPerLevelGrowth'] as num?)?.toInt() ?? 12;

  var accumulated = 0;
  for (var lv = 1; lv < level; lv++) {
    accumulated += base + ((lv - 1) * growth);
  }
  final needThisLevel = base + ((level - 1) * growth);
  final current = (xp - accumulated).clamp(0, needThisLevel);
  if (needThisLevel <= 0) return 0;
  return current / needThisLevel;
}

List<Map<String, dynamic>> _availableSpecies(Map<String, dynamic> gameConfig, int streak) {
  final species = ((gameConfig['pet']?['species'] as List?) ?? const [])
      .cast<Map>()
      .map((e) => e.cast<String, dynamic>())
      .toList();

  final unlocked = <String>{
    for (final s in species)
      if (s['locked'] != true) s['id'].toString(),
  };

  final rules = ((gameConfig['pet']?['unlockRules'] as List?) ?? const [])
      .cast<Map>()
      .map((e) => e.cast<String, dynamic>());

  for (final rule in rules) {
    if (rule['type'] == 'streak_days' && streak >= ((rule['days'] as num?)?.toInt() ?? 9999)) {
      final pool = ((rule['reward'] as Map?)?['pool'] as List?) ?? const [];
      for (final id in pool) {
        unlocked.add(id.toString());
      }
    }
  }

  return species.where((s) => unlocked.contains(s['id'].toString())).toList();
}

String _petStateLabel(int streak, int level) {
  if (streak >= 7) return '庆祝态 · 最近喂得很顺';
  if (streak >= 3) return '专注态 · 节奏已经起来了';
  if (level <= 2) return '待机态 · 还在成长中';
  return '休息态 · 缓一下继续长';
}

String _petMoodText(int streak, int level) {
  if (streak >= 7) return '最近这波喂得真不错，我现在就是开心到想庆祝。';
  if (streak >= 3) return '状态已经起来了，你继续推，我继续陪跑。';
  if (level <= 2) return '我还在长身体，但已经准备好跟你一起升级了。';
  return streak > 0 ? '我在待命，别让这条连击断掉。' : '我在这儿等你开喂，先来一轮也行。';
}

String _dateOnly(DateTime t) {
  final y = t.year.toString().padLeft(4, '0');
  final m = t.month.toString().padLeft(2, '0');
  final d = t.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

String _hhmm(DateTime t) {
  final h = t.hour.toString().padLeft(2, '0');
  final m = t.minute.toString().padLeft(2, '0');
  return '$h:$m';
}

String _petEmoji(String? petId) {
  switch (petId) {
    case 'lobster':
      return '🦞';
    case 'cat':
      return '🐱';
    case 'dino':
      return '🦖';
    case 'penguin':
      return '🐧';
    case 'rabbit':
      return '🐰';
    case 'bear':
      return '🐻';
    case 'fox':
      return '🦊';
    case 'dog':
      return '🐶';
    default:
      return '🥚';
  }
}

class _ShopItem {
  final String id;
  final String name;
  final String type;
  final int price;
  final String rarityLabel;

  _ShopItem({
    required this.id,
    required this.name,
    required this.type,
    required this.price,
    required this.rarityLabel,
  });
}

List<_ShopItem> _shopItems(Map<String, dynamic> gameConfig) {
  final items = (gameConfig['items'] as Map?)?.cast<String, dynamic>() ?? const {};
  final result = <_ShopItem>[];

  for (final entry in items.entries) {
    final rarity = entry.key;
    final list = (entry.value as List?) ?? const [];
    for (final raw in list) {
      final item = (raw as Map).cast<String, dynamic>();
      result.add(
        _ShopItem(
          id: item['id']?.toString() ?? '',
          name: item['name']?.toString() ?? '未命名道具',
          type: item['type']?.toString() ?? 'item',
          price: (item['price'] as num?)?.toInt() ?? 0,
          rarityLabel: rarity,
        ),
      );
    }
  }

  return result;
}

String _inventoryDisplayName(Map<String, dynamic> gameConfig, String itemId) {
  for (final item in _shopItems(gameConfig)) {
    if (item.id == itemId) return item.name;
  }
  return itemId;
}

String _itemVisualBadge(Map<String, dynamic> gameConfig, String itemId) {
  _ShopItem? item;
  for (final candidate in _shopItems(gameConfig)) {
    if (candidate.id == itemId) {
      item = candidate;
      break;
    }
  }
  if (item == null) return '✨';
  switch (item.type) {
    case 'hat':
      return '🎩';
    case 'scarf':
      return '🧣';
    case 'decor':
      return '🪴';
    default:
      return '✨';
  }
}
