import 'package:flutter/material.dart';

import '../../db/app_db.dart';
import '../../db/dao.dart';

class LogCompletionResult {
  final int? taskId;
  final int minutes;
  final bool withProof;

  LogCompletionResult({
    required this.taskId,
    required this.minutes,
    this.withProof = false,
  });
}

/// Bottom sheet for confirming a completion log.
///
/// - select task
/// - confirm minutes
class LogCompletionSheet extends StatefulWidget {
  final PomopetDao dao;
  final String title;
  final int defaultMinutes;

  const LogCompletionSheet({
    super.key,
    required this.dao,
    required this.title,
    required this.defaultMinutes,
  });

  static Future<LogCompletionResult?> show(
    BuildContext context, {
    required PomopetDao dao,
    required String title,
    required int defaultMinutes,
  }) {
    return showModalBottomSheet<LogCompletionResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => LogCompletionSheet(dao: dao, title: title, defaultMinutes: defaultMinutes),
    );
  }

  @override
  State<LogCompletionSheet> createState() => _LogCompletionSheetState();
}

class _LogCompletionSheetState extends State<LogCompletionSheet> {
  int? _taskId;
  bool _allowNoTask = false;
  late final TextEditingController _minutes;

  @override
  void initState() {
    super.initState();
    _minutes = TextEditingController(text: widget.defaultMinutes.toString());
  }

  @override
  void dispose() {
    _minutes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(left: 16, right: 16, bottom: bottomInset + 16, top: 8),
      child: FutureBuilder(
        future: widget.dao.listVisibleTasks(),
        builder: (context, snapshot) {
          final tasks = snapshot.data ?? const <Task>[];
          _taskId ??= tasks.isNotEmpty ? tasks.first.id : null;

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(widget.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
              const SizedBox(height: 12),
              DropdownButtonFormField<int?>(
                value: _taskId,
                items: [
                  if (_allowNoTask) const DropdownMenuItem<int?>(value: null, child: Text('（不选任务）')),
                  for (final t in tasks) DropdownMenuItem<int?>(value: t.id, child: Text(t.name)),
                ],
                onChanged: (v) => setState(() => _taskId = v),
                decoration: const InputDecoration(labelText: '记到哪个任务？'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _minutes,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: '多少分钟？'),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('入账方式', style: TextStyle(fontWeight: FontWeight.w900)),
                    SizedBox(height: 4),
                    Text('直接记完成，或者顺手补一张截图凭证。'),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              FilledButton(
                onPressed: () {
                  final minutes = int.tryParse(_minutes.text.trim()) ?? widget.defaultMinutes;
                  Navigator.of(context).pop(
                    LogCompletionResult(taskId: _taskId, minutes: minutes),
                  );
                },
                child: const Text('直接入账'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () {
                  final minutes = int.tryParse(_minutes.text.trim()) ?? widget.defaultMinutes;
                  Navigator.of(context).pop(
                    LogCompletionResult(taskId: _taskId, minutes: minutes, withProof: true),
                  );
                },
                icon: const Icon(Icons.photo_camera_back_outlined),
                label: const Text('带截图入账'),
              ),
              const SizedBox(height: 8),
            ],
          );
        },
      ),
    );
  }
}
