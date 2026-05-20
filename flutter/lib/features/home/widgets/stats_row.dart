import 'package:flutter/material.dart';
import '../../../core/theme/shapes.dart';

class StatsRow extends StatelessWidget {
  final int monthlyWorkDays;
  final int monthTotalDays;
  final String workloadLabel;
  final int consecutiveWorkDays;
  final String consecutiveStatus;
  final String monthlyWorkLabel;
  final String consecutiveWorkLabel;

  const StatsRow({
    super.key,
    required this.monthlyWorkDays,
    required this.monthTotalDays,
    required this.workloadLabel,
    required this.consecutiveWorkDays,
    required this.consecutiveStatus,
    required this.monthlyWorkLabel,
    required this.consecutiveWorkLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(child: _StatCard(title: monthlyWorkLabel, value: '$monthlyWorkDays', subtitle: '/$monthTotalDays', tag: workloadLabel)),
      const SizedBox(width: 16),
      Expanded(child: _StatCard(title: consecutiveWorkLabel, value: '$consecutiveWorkDays', subtitle: '', tag: consecutiveStatus)),
    ]);
  }
}

class _StatCard extends StatelessWidget {
  final String title, value, subtitle, tag;
  const _StatCard({required this.title, required this.value, required this.subtitle, required this.tag});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: CpShapes.card),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Text(title, style: theme.textTheme.bodySmall),
          const SizedBox(height: 4),
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(value, style: theme.textTheme.displayLarge),
            const SizedBox(width: 2),
            Padding(padding: const EdgeInsets.only(bottom: 6), child: Text(subtitle, style: theme.textTheme.bodyMedium)),
          ]),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(color: theme.colorScheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Text(tag, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: theme.colorScheme.primary)),
          ),
        ]),
      ),
    );
  }
}
