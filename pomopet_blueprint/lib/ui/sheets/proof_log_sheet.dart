import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../db/app_db.dart';
import '../../db/dao.dart';

class ProofLogResult {
  final int taskId;
  final int minutes;
  final String attachmentPath;

  ProofLogResult({
    required this.taskId,
    required this.minutes,
    required this.attachmentPath,
  });
}

class ProofLogSheet extends StatefulWidget {
  final PomopetDao dao;
  final String title;
  final int defaultMinutes;

  const ProofLogSheet({
    super.key,
    required this.dao,
    required this.title,
    required this.defaultMinutes,
  });

  static Future<ProofLogResult?> show(
    BuildContext context, {
    required PomopetDao dao,
    required String title,
    required int defaultMinutes,
  }) {
    return showModalBottomSheet<ProofLogResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => ProofLogSheet(dao: dao, title: title, defaultMinutes: defaultMinutes),
    );
  }

  @override
  State<ProofLogSheet> createState() => _ProofLogSheetState();
}

class _ProofLogSheetState extends State<ProofLogSheet> {
  final ImagePicker _picker = ImagePicker();
  XFile? _picked;
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

  Future<void> _pick() async {
    final file = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 90);
    if (file == null || !mounted) return;
    setState(() => _picked = file);
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
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('凭证说明', style: TextStyle(fontWeight: FontWeight.w900)),
                    SizedBox(height: 4),
                    Text('传一张完成截图，这次记录会被标成「已凭证」。'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.tonalIcon(
                onPressed: _pick,
                icon: const Icon(Icons.photo_library_outlined),
                label: Text(_picked == null ? '选择截图' : '重新选择截图'),
              ),
              const SizedBox(height: 10),
              if (_picked != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.file(
                        File(_picked!.path),
                        height: 160,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text('本次完成将显示为：已凭证', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                    ),
                  ],
                )
              else
                const Text('还没有选择截图。'),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: _taskId,
                items: [
                  for (final t in tasks) DropdownMenuItem<int>(value: t.id, child: Text(t.name)),
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
                onPressed: () {
                  if (_taskId == null || _picked == null) return;
                  final minutes = int.tryParse(_minutes.text.trim()) ?? widget.defaultMinutes;
                  Navigator.of(context).pop(
                    ProofLogResult(
                      taskId: _taskId!,
                      minutes: minutes,
                      attachmentPath: _picked!.path,
                    ),
                  );
                },
                child: const Text('确认截图入账'),
              ),
              const SizedBox(height: 8),
            ],
          );
        },
      ),
    );
  }
}
