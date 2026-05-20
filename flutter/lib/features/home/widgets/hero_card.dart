import 'package:flutter/material.dart';
import '../../../domain/models/shift_type.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/shapes.dart';

class HeroCard extends StatelessWidget {
  final String shiftLabel;
  final ShiftType shiftType;
  final String teamName;
  final String? alarmTime;
  final int dayOfCycle;
  final int totalDays;
  final int daysUntilRest;
  final String cycleProgressText;
  final String restLabel;

  const HeroCard({
    super.key,
    required this.shiftLabel,
    required this.shiftType,
    required this.teamName,
    this.alarmTime,
    required this.dayOfCycle,
    required this.totalDays,
    required this.daysUntilRest,
    required this.cycleProgressText,
    required this.restLabel,
  });

  @override
  Widget build(BuildContext context) {
    final color = shiftColor(shiftType);
    final progress = totalDays > 0 ? dayOfCycle / totalDays : 0.0;
    final theme = Theme.of(context);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: CpShapes.mainCard),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: CpShapes.mainCard,
          gradient: LinearGradient(
            colors: [color.withValues(alpha: 0.08), theme.colorScheme.surface],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Text(shiftLabel,
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(children: [
                    Text('$teamName · ${shiftLabel}班',
                        style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const Spacer(),
                    if (alarmTime != null)
                      _Tag(text: alarmTime!, color: theme.colorScheme.onSurfaceVariant),
                  ]),
                  const SizedBox(height: 8),
                  _RestBadge(label: restLabel, isRestDay: daysUntilRest == 0),
                  const SizedBox(height: 12),
                  Row(children: [
                    Text(cycleProgressText, style: theme.textTheme.bodySmall),
                    const SizedBox(width: 8),
                    Text('${(progress * 100).round()}%',
                        style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold)),
                  ]),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress, minHeight: 4,
                      backgroundColor: color.withValues(alpha: 0.12),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RestBadge extends StatelessWidget {
  final String label;
  final bool isRestDay;
  const _RestBadge({required this.label, required this.isRestDay});

  @override
  Widget build(BuildContext context) {
    final bgColor = isRestDay ? shiftRest.withValues(alpha: 0.15) : shiftNight.withValues(alpha: 0.10);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
      child: Text(label,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
              color: isRestDay ? shiftRest : null)),
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;
  final Color color;
  const _Tag({required this.text, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(text, style: const TextStyle(fontSize: 11)),
    );
  }
}
