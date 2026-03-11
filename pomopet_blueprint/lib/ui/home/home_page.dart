import 'package:flutter/material.dart';

import '../../db/dao.dart';
import '../timer/timer_page.dart';
import '../today/today_page.dart';
import 'pet_page.dart';
import 'settings_page.dart';

/// Minimal Home shell with bottom navigation.
///
/// Tabs: Today / Timer / Pet / Settings
class HomePage extends StatefulWidget {
  final PomopetDao dao;
  final dynamic timer; // TimerService
  final dynamic rewards; // RewardService
  final Map<String, dynamic> gameConfig;
  final int userId;

  const HomePage({
    super.key,
    required this.dao,
    required this.timer,
    required this.rewards,
    required this.gameConfig,
    required this.userId,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      TodayPage(
        dao: widget.dao,
        gameConfig: widget.gameConfig,
        userId: widget.userId,
      ),
      TimerPage(
        dao: widget.dao,
        timer: widget.timer,
        rewards: widget.rewards,
        gameConfig: widget.gameConfig,
        userId: widget.userId,
      ),
      PetPage(
        dao: widget.dao,
        gameConfig: widget.gameConfig,
        userId: widget.userId,
      ),
      SettingsPage(dao: widget.dao, gameConfig: widget.gameConfig),
    ];

    return Scaffold(
      body: pages[index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (v) => setState(() => index = v),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.today), label: '今日'),
          NavigationDestination(icon: Icon(Icons.timer), label: '番茄'),
          NavigationDestination(icon: Icon(Icons.pets), label: '小兽'),
          NavigationDestination(icon: Icon(Icons.settings), label: '设置'),
        ],
      ),
    );
  }
}
