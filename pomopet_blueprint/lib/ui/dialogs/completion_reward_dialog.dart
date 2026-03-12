import 'dart:io';

import 'package:flutter/material.dart';

class CompletionRewardDialog extends StatelessWidget {
  final String source;
  final int minutes;
  final int xp;
  final int coin;
  final int streak;
  final bool leveledUp;
  final int? newLevel;
  final String? attachmentPath;

  const CompletionRewardDialog({
    super.key,
    required this.source,
    required this.minutes,
    required this.xp,
    required this.coin,
    required this.streak,
    required this.leveledUp,
    this.newLevel,
    this.attachmentPath,
  });

  bool get _isProof => source == 'proof';

  String get _title {
    switch (source) {
      case 'proof':
        return '凭证喂养成功';
      case 'timer':
        return '这一轮喂养成功';
      case 'manual':
      default:
        return '完成已入账';
    }
  }

  String get _subtitle {
    switch (source) {
      case 'proof':
        return '这次不仅完成了，还把凭证认真交给了小兽。';
      case 'timer':
        return '番茄完成已经记进成长记录里了。';
      case 'manual':
      default:
        return '这次完成已经被小兽认真记住。';
    }
  }

  String get _sourceBadge {
    switch (source) {
      case 'proof':
        return '📸 凭证完成';
      case 'timer':
        return '🍅 番茄完成';
      case 'manual':
      default:
        return '✍️ 补录完成';
    }
  }

  String get _heroEmoji {
    switch (source) {
      case 'proof':
        return '🏅';
      case 'timer':
        return '🎉';
      case 'manual':
      default:
        return '✨';
    }
  }

  List<Color> _heroGradient(ColorScheme colorScheme) {
    switch (source) {
      case 'proof':
        return [
          const Color(0xFFFFD66B),
          colorScheme.secondary,
        ];
      case 'timer':
        return [
          colorScheme.primary,
          colorScheme.secondary,
        ];
      case 'manual':
      default:
        return [
          colorScheme.primary.withValues(alpha: 0.82),
          colorScheme.tertiary,
        ];
    }
  }

  String get _footerText {
    if (leveledUp && newLevel != null) {
      return '小兽升级到了 Lv.$newLevel，这次喂养非常值。';
    }
    switch (source) {
      case 'proof':
        return '这次是带凭证的完整喂养，仪式感是到位的。';
      case 'timer':
        return '继续保持，下一轮还能把小兽再往前推一点。';
      case 'manual':
      default:
        return '先记下来也很好，别让真实完成白白溜走。';
    }
  }

  String get _ctaText {
    if (leveledUp) return '去看看升级';
    switch (source) {
      case 'proof':
        return '继续喂，保持这手感';
      case 'timer':
        return '继续喂小兽';
      case 'manual':
      default:
        return '继续记下一轮';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: _heroGradient(colorScheme)),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                Container(
                  width: 78,
                  height: 78,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.24),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.34)),
                  ),
                  child: Text(_heroEmoji, style: const TextStyle(fontSize: 36)),
                ),
                const SizedBox(height: 14),
                Text(
                  _title,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  _subtitle,
                  style: const TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$_sourceBadge · $minutes 分钟',
                    style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                ),
                if (_isProof) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      '已收下凭证 · 这次完成会被认真记住',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (_isProof && attachmentPath != null && attachmentPath!.isNotEmpty) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.file(
                  File(attachmentPath!),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _ProofImageFallback(),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3CC),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                '这就是你刚刚交上来的凭证，小兽已经当场收下。',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _RewardStatCard(
                  emoji: _isProof ? '🌟' : '⭐',
                  label: _isProof ? '经验奖励' : '经验',
                  value: '+$xp XP',
                  accent: _isProof ? colorScheme.secondary : colorScheme.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _RewardStatCard(
                  emoji: _isProof ? '💰' : '🪙',
                  label: _isProof ? '金币奖励' : '金币',
                  value: '+$coin',
                  accent: _isProof ? const Color(0xFFFFC94D) : colorScheme.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _isProof
                  ? const Color(0xFFFFF8E5)
                  : Colors.black.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(18),
              border: _isProof
                  ? Border.all(color: const Color(0xFFFFD66B).withValues(alpha: 0.55))
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isProof ? '🏅 完整喂养已确认 · 连击 $streak 天' : '🔥 当前连击：$streak 天',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(_footerText),
              ],
            ),
          ),
        ],
      ),
      actions: [
        FilledButton(
          style: _isProof
              ? FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFE0A800),
                  foregroundColor: Colors.black,
                )
              : null,
          onPressed: () => Navigator.of(context).pop(),
          child: Text(_ctaText),
        ),
      ],
    );
  }
}

class _ProofImageFallback extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
      alignment: Alignment.center,
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('📸', style: TextStyle(fontSize: 34)),
          SizedBox(height: 8),
          Text('凭证已收下', style: TextStyle(fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class _RewardStatCard extends StatelessWidget {
  final String emoji;
  final String label;
  final String value;
  final Color accent;

  const _RewardStatCard({
    required this.emoji,
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 2),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
