import 'package:flutter/material.dart';

import '../../db/dao.dart';

class SettingsPage extends StatefulWidget {
  final PomopetDao dao;
  final Map<String, dynamic> gameConfig;

  const SettingsPage({
    super.key,
    required this.dao,
    required this.gameConfig,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String mode = 'mixed';
  String theme = 'tomato_strong';
  String cutoff = '00:00';
  bool finishNotify = true;
  bool ongoingNotify = true;
  bool loading = true;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final bundle = await widget.dao.getSettingsBundle(widget.gameConfig);
    if (!mounted) return;
    setState(() {
      mode = bundle['mode']?.toString() ?? 'mixed';
      theme = bundle['theme']?.toString() ?? 'tomato_strong';
      cutoff = bundle['dayCutoff']?.toString() ?? '00:00';
      finishNotify = bundle['finishNotify'] == true;
      ongoingNotify = bundle['ongoingNotify'] == true;
      loading = false;
    });
  }

  Future<void> _save() async {
    setState(() => saving = true);
    await widget.dao.saveSettingsBundle(
      mode: mode,
      theme: theme,
      dayCutoff: cutoff,
      finishNotify: finishNotify,
      ongoingNotify: ongoingNotify,
    );
    if (!mounted) return;
    setState(() => saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('设置已保存到本地')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const Text('记录模式', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                RadioListTile<String>(
                  value: 'mixed',
                  groupValue: mode,
                  title: const Text('混合模式'),
                  subtitle: const Text('番茄钟 + 截图证明 + 手动补录'),
                  onChanged: (v) => setState(() => mode = v!),
                ),
                RadioListTile<String>(
                  value: 'timer',
                  groupValue: mode,
                  title: const Text('只用番茄钟'),
                  subtitle: const Text('最克制，最像专注产品'),
                  onChanged: (v) => setState(() => mode = v!),
                ),
                RadioListTile<String>(
                  value: 'proof',
                  groupValue: mode,
                  title: const Text('偏截图证明'),
                  subtitle: const Text('适合做任务打卡/学习记录'),
                  onChanged: (v) => setState(() => mode = v!),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text('主题风格', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                RadioListTile<String>(
                  value: 'tomato_strong',
                  groupValue: theme,
                  title: const Text('番茄强'),
                  subtitle: const Text('更热烈，更有“开始专注”的推动感'),
                  onChanged: (v) => setState(() => theme = v!),
                ),
                RadioListTile<String>(
                  value: 'fresh_blue',
                  groupValue: theme,
                  title: const Text('清爽蓝'),
                  subtitle: const Text('更平静，适合长时间陪伴'),
                  onChanged: (v) => setState(() => theme = v!),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text('日切时间', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('当前：$cutoff', style: const TextStyle(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final c in const ['00:00', '03:00', '04:00', '05:00'])
                        ChoiceChip(
                          label: Text(c),
                          selected: cutoff == c,
                          onSelected: (_) => setState(() => cutoff = c),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('通知', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  value: ongoingNotify,
                  onChanged: (v) => setState(() => ongoingNotify = v),
                  title: const Text('专注中常驻通知'),
                ),
                SwitchListTile(
                  value: finishNotify,
                  onChanged: (v) => setState(() => finishNotify = v),
                  title: const Text('完成时提醒'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: saving ? null : _save,
            child: Text(saving ? '保存中...' : '保存设置'),
          ),
          const SizedBox(height: 10),
          Text(
            '这一版已经把设置真正写入本地数据库；主题动态切换可作为下一轮再接。',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
