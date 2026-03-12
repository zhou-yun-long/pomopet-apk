import 'package:flutter/material.dart';

import '../../theme/pomopet_theme.dart';
import '../../timer/timer_service.dart';
import '../../db/dao.dart';
import '../../services/reward_service.dart';
import '../dialogs/completion_reward_dialog.dart';
import '../dialogs/level_up_dialog.dart';
import '../sheets/log_completion_sheet.dart';
import '../sheets/proof_log_sheet.dart';
import 'select_task_sheet.dart';
import '../../utils/day_cutoff.dart';
import 'tomato_progress_ring.dart';

/// Minimal Timer page skeleton.
///
/// Wire real app state with Provider/Riverpod/Bloc as you like.
class TimerPage extends StatefulWidget {
  final PomopetDao dao;
  final TimerService timer;
  final RewardService rewards;
  final Map<String, dynamic> gameConfig;
  final int userId;

  const TimerPage({
    super.key,
    required this.dao,
    required this.timer,
    required this.rewards,
    required this.gameConfig,
    required this.userId,
  });

  @override
  State<TimerPage> createState() => _TimerPageState();
}

class _TimerPageState extends State<TimerPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('番茄钟')),
      body: StreamBuilder(
        stream: widget.dao.watchActiveSession(),
        builder: (context, snapshot) {
          final s = snapshot.data;
          final now = DateTime.now();

          final planned = s?.plannedMinutes ?? 25;
          final endAt = s?.endAt ?? now.add(Duration(minutes: planned));
          final remaining = endAt.difference(now).inSeconds;
          final total = planned * 60;
          final progress = total <= 0 ? 0.0 : (1.0 - (remaining / total)).clamp(0.0, 1.0);

          return Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      children: [
                        TomatoProgressRing(progress: progress),
                        const SizedBox(height: 18),
                        Text(
                          _mmss(remaining),
                          style: const TextStyle(fontSize: 38, fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 12),
                        if (s != null && s.status == 'finished')
                          FilledButton(
                            onPressed: () async {
                              final res = await LogCompletionSheet.show(
                                context,
                                dao: widget.dao,
                                title: '番茄完成！怎么记这轮？',
                                defaultMinutes: s.plannedMinutes,
                              );
                              if (res == null) return;

                              if (res.taskId == null) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('请先选择一个任务再入账')),
                                );
                                return;
                              }

                              String source = 'timer';
                              String? attachmentPath;
                              var minutes = res.minutes;

                              if (res.withProof) {
                                final proof = await ProofLogSheet.show(
                                  context,
                                  dao: widget.dao,
                                  title: '给这轮番茄补一张截图凭证',
                                  defaultMinutes: res.minutes,
                                );
                                if (proof == null) return;
                                source = 'proof';
                                minutes = proof.minutes;
                                attachmentPath = proof.attachmentPath;
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
                                rewards: widget.rewards,
                                game: widget.gameConfig,
                                userId: widget.userId,
                                taskId: res.taskId!,
                                dateYYYYMMDD: date,
                                minutes: minutes,
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
                                  minutes: minutes,
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
                            },
                            child: const Text('记为完成'),
                          ),
                        const SizedBox(height: 6),
                        Text(
                          s?.status == 'finished'
                              ? '庆祝中 · 直接入账，或者补一张截图凭证'
                              : (s?.status == 'paused' ? '休息中 · 点一下继续，把这轮接上' : '专注中 · 小兽正在陪跑'),
                          style: const TextStyle(color: PomopetTheme.subText),
                        )
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: () async {
                          if (s == null) {
                            final sel = await SelectTaskSheet.show(context, dao: widget.dao);
                            if (sel == null) return;
                            await widget.timer.startFocus(
                              userId: widget.userId,
                              taskId: sel.taskId,
                              presetId: 'classic_25_5',
                              focusMinutes: 25,
                            );
                          } else if (s.status == 'paused') {
                            await widget.timer.resume(s.id);
                          } else {
                            await widget.timer.pause(s.id);
                          }
                        },
                        child: Text(s == null ? '开始专注' : (s.status == 'paused' ? '继续专注' : '暂停')),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: s == null
                            ? null
                            : () async {
                                await widget.timer.stop(s.id);
                              },
                        child: const Text('结束本次'),
                      ),
                    )
                  ],
                )
              ],
            ),
          );
        },
      ),
    );
  }

  String _mmss(int seconds) {
    final s = seconds < 0 ? 0 : seconds;
    final m = (s ~/ 60).toString().padLeft(2, '0');
    final ss = (s % 60).toString().padLeft(2, '0');
    return '$m:$ss';
  }
}
