import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

class PomopetConfig {
  final Map<String, dynamic> strings;
  final Map<String, dynamic> events;
  final Map<String, dynamic> game;
  final Map<String, dynamic> presets;

  PomopetConfig({
    required this.strings,
    required this.events,
    required this.game,
    required this.presets,
  });
}

/// Minimal asset-only config loader.
///
/// Hot-update cache loading can be added on top of this.
class ConfigLoader {
  Future<Map<String, dynamic>> _loadJson(String path) async {
    final s = await rootBundle.loadString(path);
    return jsonDecode(s) as Map<String, dynamic>;
  }

  Future<PomopetConfig> loadAssets() async {
    final strings = await _loadJson('assets/config/strings_zh.json');
    final events = await _loadJson('assets/config/events.json');
    final game = await _loadJson('assets/config/game_config.json');
    final presets = await _loadJson('assets/config/timer_presets.json');
    return PomopetConfig(strings: strings, events: events, game: game, presets: presets);
  }
}
