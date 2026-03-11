import 'package:flutter/material.dart';

import '../../db/dao.dart';

class LogCompletionResult {
  final int taskId;
  final int minutes;
  LogCompletionResult({required this.taskId, required this.minutes});
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
        future: widget.dao.listActiveTasks(),
        builder: (context, snapshot) {
          final tasks = snapshot.data ?? const [];
          _taskId ??= tasks.isNotEmpty ? tasks.first.id : null;

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(widget.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: _taskId,
                items: [
                  for (final t in tasks) DropdownMenuItem(value: t.id, child: Text(t.name)),
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
              const SizedBox(height: 14),
              FilledButton(
                onPressed: _taskId == null
                    ? null
                    : () {
                        final minutes = int.tryParse(_minutes.text.trim()) ?? widget.defaultMinutes;
                        Navigator.of(context).pop(LogCompletionResult(taskId: _taskId!, minutes: minutes));
                      },
                child: const Text('确认入账'),
              ),
              const SizedBox(height: 8),
            ],
          );
        },
      ),
    );
  }
}
