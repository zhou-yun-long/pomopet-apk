import 'dart:io';

import 'package:flutter/material.dart';

import '../../db/app_db.dart';
import '../../db/dao.dart';
import '../../services/reward_service.dart';
import '../../utils/day_cutoff.dart';
import '../dialogs/completion_reward_dialog.dart';
import '../dialogs/level_up_dialog.dart';
import '../sheets/log_completion_sheet.dart';
import '../sheets/proof_log_sheet.dart';

/// Today page: minimal task list + quick add.
///
/// Goal: make the app feel like a real product ASAP.
class TodayPage extends StatefulWidget {
  final PomopetDao dao;
  final Map<String, dynamic> gameConfig;
  final int userId;

  const TodayPage({
    super.key,
    required this.dao,
    required this.gameConfig,
    required this.userId,
  });

  @override
  State<TodayPage> createState() => _TodayPageState();
}

class _TodayPageState extends State<TodayPage> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: widget.dao.getSetting('dayCutoff'),
      builder: (context, cutoffSnap) {
        final cutoff = cutoffSnap.data ?? (widget.gameConfig['defaults']?['dayCutoff'] as String?) ?? '00:00';
        final date = logicalDate(DateTime.now(), cutoff: cutoff);

        return Scaffold(
          appBar: AppBar(
            title: const Text('今天'),
            actions: [
              IconButton(
                tooltip: '新增任务',
                onPressed: () => _showCreateTaskDialog(context),
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FutureBuilder<int>(
                  future: widget.dao.getTotalMinutesByDate(date),
                  builder: (context, snap) {
                    final minutes = snap.data ?? 0;
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            const Icon(Icons.local_fire_department),
                            const SizedBox(width: 10),
                            Text(
                              '今日累计：$minutes 分钟',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                            ),
                            const Spacer(),
                            Text(
                              date,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('快速记录', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _quickLog(context, source: 'manual', title: '手动补录完成'),
                                icon: const Icon(Icons.edit_note),
                                label: const Text('手动补录'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: FilledButton.tonalIcon(
                                onPressed: () => _quickLog(context, source: 'proof', title: '截图证明完成'),
                                icon: const Icon(Icons.photo_camera_back_outlined),
                                label: const Text('截图证明'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('任务', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                Expanded(
                  child: StreamBuilder(
                    stream: widget.dao.watchVisibleTasks(),
                    builder: (context, snapshot) {
                      final tasks = snapshot.data ?? const <Task>[];

                      if (tasks.isEmpty) {
                        return _EmptyState(onAdd: () => _showCreateTaskDialog(context));
                      }

                      return FutureBuilder<Map<int, int>>(
                        future: widget.dao.getMinutesByTaskOnDate(date),
                        builder: (context, minutesSnap) {
                          final minutesByTask = minutesSnap.data ?? const <int, int>{};

                          return ListView(
                            children: [
                              const SizedBox(height: 4),
                              for (final t in tasks) ...[
                                _TaskCard(
                                  task: t,
                                  todayMinutes: minutesByTask[t.id] ?? 0,
                                  onTogglePause: () async {
                                    final paused = t.status == 'paused';
                                    await widget.dao.setTaskStatus(t.id, paused ? 'active' : 'paused');
                                  },
                                  onEdit: () => _showEditTaskDialog(context, t),
                                  onArchive: () => widget.dao.archiveTask(t.id),
                                ),
                                const SizedBox(height: 8),
                              ],
                              const SizedBox(height: 10),
                              const Text('最近完成', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
                              const SizedBox(height: 8),
                              FutureBuilder(
                                future: widget.dao.listRecentCompletions(dateYYYYMMDD: date, limit: 8),
                                builder: (context, recSnap) {
                                  final recents = recSnap.data ?? const <RecentCompletion>[];
                                  if (recents.isEmpty) {
                                    return const Text('今天还没有完成记录。去跑一个番茄喂小兽。');
                                  }
                                  return Column(
                                    children: [
                                      for (var i = 0; i < recents.length; i++)
                                        _GrowthFeedCard(
                                          completion: recents[i],
                                          isFirst: i == 0,
                                          isLast: i == recents.length - 1,
                                        ),
                                    ],
                                  );
                                },
                              ),
                              const SizedBox(height: 80),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showCreateTaskDialog(context),
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  Future<void> _quickLog(
    BuildContext context, {
    required String source,
    required String title,
  }) async {
    int? taskId;
    int? minutes;
    String? attachmentPath;

    if (source == 'proof') {
      final res = await ProofLogSheet.show(
        context,
        dao: widget.dao,
        title: title,
        defaultMinutes: 25,
      );
      if (res == null) return;
      taskId = res.taskId;
      minutes = res.minutes;
      attachmentPath = res.attachmentPath;
    } else {
      final res = await LogCompletionSheet.show(
        context,
        dao: widget.dao,
        title: title,
        defaultMinutes: 25,
      );
      if (res == null || res.taskId == null) return;
      taskId = res.taskId!;
      minutes = res.minutes;
    }

    final cutoff = await widget.dao.getSetting('dayCutoff') ??
        (widget.gameConfig['defaults']?['dayCutoff'] as String?) ??
        '00:00';
    final date = logicalDate(DateTime.now(), cutoff: cutoff);

    final before = await (widget.dao.db.select(widget.dao.db.users)
          ..where((u) => u.id.equals(widget.userId)))
        .getSingle();

    final reward = await logCompletionTx(
      db: widget.dao.db,
      rewards: RewardService(),
      game: widget.gameConfig,
      userId: widget.userId,
      taskId: taskId!,
      dateYYYYMMDD: date,
      minutes: minutes!,
      source: source,
      attachmentPath: attachmentPath,
      dao: widget.dao,
    );

    final after = await (widget.dao.db.select(widget.dao.db.users)
          ..where((u) => u.id.equals(widget.userId)))
        .getSingle();

    if (!context.mounted) return;
    await showDialog(
      context: context,
      builder: (_) => CompletionRewardDialog(
        source: source,
        minutes: minutes!,
        xp: reward.xp,
        coin: reward.coin,
        streak: after.streak,
        leveledUp: after.level > before.level,
        newLevel: after.level,
        attachmentPath: attachmentPath,
      ),
    );

    if (!context.mounted) return;
    if (after.level > before.level) {
      await showDialog(
        context: context,
        builder: (_) => LevelUpDialog(newLevel: after.level),
      );
    }
  }

  Future<void> _showCreateTaskDialog(BuildContext context) async {
    final res = await showDialog<_TaskDraft>(
      context: context,
      builder: (_) => _TaskDialog(title: '新增任务'),
    );
    if (res == null) return;
    await widget.dao.createTask(
      name: res.name,
      targetMinutes: res.targetMinutes,
      required: res.required,
    );
  }

  Future<void> _showEditTaskDialog(BuildContext context, Task task) async {
    final res = await showDialog<_TaskDraft>(
      context: context,
      builder: (_) => _TaskDialog(
        title: '编辑任务',
        initialName: task.name,
        initialMinutes: task.targetMinutes,
        initialRequired: task.required,
      ),
    );
    if (res == null) return;
    await widget.dao.updateTask(
      task.id,
      name: res.name,
      targetMinutes: res.targetMinutes,
      required: res.required,
    );
  }
}

String _hhmm(DateTime t) {
  final h = t.hour.toString().padLeft(2, '0');
  final m = t.minute.toString().padLeft(2, '0');
  return '$h:$m';
}

class _GrowthFeedCard extends StatelessWidget {
  final RecentCompletion completion;
  final bool isFirst;
  final bool isLast;

  const _GrowthFeedCard({
    required this.completion,
    required this.isFirst,
    required this.isLast,
  });

  bool get _hasPreview => completion.attachmentPath != null && completion.attachmentPath!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final accent = _sourceAccent(context, completion.source);
    final title = _growthTitle(completion);
    final desc = _growthDescription(completion);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                if (!isFirst)
                  Container(width: 2, height: 10, color: accent.withValues(alpha: 0.25)),
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent.withValues(alpha: 0.14),
                  ),
                  child: Text(_sourceEmoji(completion.source), style: const TextStyle(fontSize: 14)),
                ),
                if (!isLast)
                  Container(width: 2, height: _hasPreview ? 180 : 116, color: accent.withValues(alpha: 0.25)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_hasPreview)
                    SizedBox(
                      height: 148,
                      width: double.infinity,
                      child: Image.file(
                        File(completion.attachmentPath!),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
                          alignment: Alignment.center,
                          child: Text('📸 ${completion.taskName}', style: const TextStyle(fontWeight: FontWeight.w900)),
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                            ),
                            const SizedBox(width: 10),
                            Text(_hhmm(completion.createdAt), style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(desc),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _FeedChip(label: _sourceLabel(completion.source)),
                            _FeedChip(label: '${completion.minutes} 分钟'),
                            if (completion.source == 'proof') const _FeedChip(label: '已凭证', highlighted: true),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedChip extends StatelessWidget {
  final String label;
  final bool highlighted;

  const _FeedChip({required this.label, this.highlighted = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: highlighted
            ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.12)
            : Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
    );
  }
}

Color _sourceAccent(BuildContext context, String source) {
  switch (source) {
    case 'proof':
      return const Color(0xFFE0A800);
    case 'manual':
      return Theme.of(context).colorScheme.tertiary;
    case 'timer':
    default:
      return Theme.of(context).colorScheme.primary;
  }
}

String _growthTitle(RecentCompletion completion) {
  switch (completion.source) {
    case 'proof':
      return '你完成了「${completion.taskName}」，还顺手交了凭证';
    case 'manual':
      return '你把「${completion.taskName}」认真补录进今天的成长里';
    case 'timer':
    default:
      return '你完成了一轮「${completion.taskName}」';
  }
}

String _growthDescription(RecentCompletion completion) {
  switch (completion.source) {
    case 'proof':
      return '这轮一共 ${completion.minutes} 分钟，小兽不只吃到了进度，还收到了明确凭证。';
    case 'manual':
      return '这次补录了 ${completion.minutes} 分钟，真实完成没有被白白漏掉。';
    case 'timer':
    default:
      return '这轮番茄推进了 ${completion.minutes} 分钟，小兽已经把它记成一次正经喂养。';
  }
}

class _TaskCard extends StatelessWidget {
  final Task task;
  final int todayMinutes;
  final VoidCallback onTogglePause;
  final VoidCallback onEdit;
  final VoidCallback onArchive;

  const _TaskCard({
    required this.task,
    required this.todayMinutes,
    required this.onTogglePause,
    required this.onEdit,
    required this.onArchive,
  });

  @override
  Widget build(BuildContext context) {
    final paused = task.status == 'paused';
    return Card(
      child: ListTile(
        title: Text(
          task.name,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            decoration: paused ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Text('${task.targetMinutes} 分钟 · 今日 $todayMinutes 分钟 · ${task.required ? '必做' : '可选'}'),
        leading: Icon(paused ? Icons.pause_circle : Icons.check_circle_outline),
        onTap: onTogglePause,
        trailing: PopupMenuButton<String>(
          onSelected: (v) async {
            if (v == 'edit') {
              onEdit();
            } else if (v == 'archive') {
              onArchive();
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'edit', child: Text('编辑')),
            PopupMenuItem(value: 'archive', child: Text('归档')),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '还没有任务。\n先加一个「必做」任务，小兽才知道今天该怎么长。',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('新增任务'),
            )
          ],
        ),
      ),
    );
  }
}

class _TaskDraft {
  final String name;
  final int targetMinutes;
  final bool required;
  _TaskDraft({required this.name, required this.targetMinutes, required this.required});
}

class _TaskDialog extends StatefulWidget {
  final String title;
  final String? initialName;
  final int? initialMinutes;
  final bool? initialRequired;

  const _TaskDialog({
    required this.title,
    this.initialName,
    this.initialMinutes,
    this.initialRequired,
  });

  @override
  State<_TaskDialog> createState() => _TaskDialogState();
}

class _TaskDialogState extends State<_TaskDialog> {
  late final TextEditingController name;
  int minutes = 30;
  bool required = false;

  @override
  void initState() {
    super.initState();
    name = TextEditingController(text: widget.initialName ?? '');
    minutes = widget.initialMinutes ?? 30;
    required = widget.initialRequired ?? false;
  }

  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: name,
            decoration: const InputDecoration(labelText: '任务名'),
            autofocus: true,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('目标时长'),
              const Spacer(),
              Text('$minutes min', style: const TextStyle(fontWeight: FontWeight.w900)),
            ],
          ),
          Slider(
            value: minutes.toDouble(),
            min: 5,
            max: 120,
            divisions: 23,
            label: '$minutes',
            onChanged: (v) => setState(() => minutes = v.round()),
          ),
          CheckboxListTile(
            value: required,
            onChanged: (v) => setState(() => required = v ?? false),
            contentPadding: EdgeInsets.zero,
            title: const Text('必做'),
            subtitle: const Text('必做任务会影响 streak/奖励（下一步实现）'),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
        FilledButton(
          onPressed: () {
            final n = name.text.trim();
            if (n.isEmpty) return;
            Navigator.pop(context, _TaskDraft(name: n, targetMinutes: minutes, required: required));
          },
          child: const Text('保存'),
        ),
      ],
    );
  }
}
