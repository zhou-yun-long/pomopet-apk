import 'package:drift/drift.dart';
import 'package:flutter/material.dart';

import 'app_bootstrap.dart';
import 'app_nav.dart';
import 'config/config_loader.dart';
import 'db/app_db.dart';
import 'db/dao.dart';
import 'services/reward_service.dart';
import 'theme/pomopet_theme.dart';
import 'ui/home/home_page.dart';

/// Minimal runnable skeleton (paste into a real Flutter project main.dart).
///
/// This blueprint does not include pubspec/plugin setup. Use this as reference.
Future<void> main() async {
  final runtime = await bootstrapPomopet();
  final config = await ConfigLoader().loadAssets();

  final existingUser = await (runtime.db.select(runtime.db.users)..limit(1)).getSingleOrNull();
  final userId = existingUser?.id ??
      await runtime.db.into(runtime.db.users).insert(
            UsersCompanion.insert(petId: const Value('lobster')),
          );

  runApp(PomopetApp(
    dao: PomopetDao(runtime.db),
    timer: runtime.timer,
    rewards: RewardService(),
    gameConfig: config.game,
    userId: userId,
  ));
}

class PomopetApp extends StatelessWidget {
  final PomopetDao dao;
  final dynamic timer; // TimerService
  final RewardService rewards;
  final Map<String, dynamic> gameConfig;
  final int userId;

  const PomopetApp({
    super.key,
    required this.dao,
    required this.timer,
    required this.rewards,
    required this.gameConfig,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<String?>(
      stream: dao.watchSetting('theme'),
      builder: (context, snapshot) {
        final themeId = snapshot.data ??
            (gameConfig['defaults']?['theme'] as String?) ??
            'tomato_strong';

        return MaterialApp(
          navigatorKey: pomopetNavKey,
          theme: PomopetTheme.byId(themeId),
          home: HomePage(
            dao: dao,
            timer: timer,
            rewards: rewards,
            gameConfig: gameConfig,
            userId: userId,
          ),
        );
      },
    );
  }
}
