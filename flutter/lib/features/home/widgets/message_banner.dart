import 'package:flutter/material.dart';

/// MessageBanner — 上下文共情文案
///
/// 置于半透明卡片中，弱色文字，不大的视觉权重但给情绪价值

class MessageBanner extends StatelessWidget {
  final String message;

  const MessageBanner({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      color: theme.colorScheme.surface.withValues(alpha: 0.6),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            const Text('💬', style: TextStyle(fontSize: 14)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(message, style: theme.textTheme.bodySmall),
            ),
          ],
        ),
      ),
    );
  }
}
