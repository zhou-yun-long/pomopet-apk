import 'package:flutter/material.dart';

import '../../db/app_db.dart';
import '../../db/dao.dart';

class SelectTaskResult {
  final int? taskId;
  final String? taskName;
  SelectTaskResult({required this.taskId, required this.taskName});
}

/// Bottom sheet for choosing a task before starting a focus session.
class SelectTaskSheet extends StatelessWidget {
  final PomopetDao dao;

  const SelectTaskSheet({super.key, required this.dao});

  static Future<SelectTaskResult?> show(BuildContext context, {required PomopetDao dao}) {
    return showModalBottomSheet<SelectTaskResult>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => SelectTaskSheet(dao: dao),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(left: 16, right: 16, top: 8, bottom: bottomInset + 16),
      child: FutureBuilder(
        future: dao.listVisibleTasks(),
        builder: (context, snapshot) {
          final tasks = snapshot.data ?? const <TaskData>[];

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('选择任务', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
              const SizedBox(height: 10),
              if (tasks.isEmpty)
                const Text('还没有任务，先去「今天」页新增一个。')
              else
                ...[
                  for (final t in tasks)
                    Card(
                      child: ListTile(
                        title: Text(t.name, style: const TextStyle(fontWeight: FontWeight.w900)),
                        subtitle: Text('${t.targetMinutes} 分钟 · ${t.required ? '必做' : '可选'} · ${t.status}'),
                        onTap: () => Navigator.pop(
                          context,
                          SelectTaskResult(taskId: t.id, taskName: t.name),
                        ),
                      ),
                    ),
                ],
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => Navigator.pop(context, SelectTaskResult(taskId: null, taskName: '无任务')),
                child: const Text('不选任务，直接开始'),
              ),
            ],
          );
        },
      ),
    );
  }
}
