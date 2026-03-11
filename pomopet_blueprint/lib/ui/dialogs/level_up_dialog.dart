import 'package:flutter/material.dart';

class LevelUpDialog extends StatelessWidget {
  final int newLevel;
  const LevelUpDialog({super.key, required this.newLevel});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('升级啦！'),
      content: Text('小兽长大了一点点。\n\n当前等级：Lv.$newLevel'),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('太好了'),
        )
      ],
    );
  }
}
