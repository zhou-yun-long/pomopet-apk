import 'package:flutter/material.dart';

import '../../db/app_db.dart';
import '../../db/dao.dart';

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
                        ],
                      ),
                    ),
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
