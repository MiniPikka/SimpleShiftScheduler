import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/shapes.dart';
import '../../core/utils/l10n.dart';
import '../../domain/models/leave_strategy.dart';
import '../../domain/algorithms/leave_optimizer.dart';
import '../../domain/algorithms/shift_calculator.dart';
import '../home/home_state.dart';

class LeaveOptimizerScreen extends ConsumerStatefulWidget {
  const LeaveOptimizerScreen({super.key});
  @override
  ConsumerState<LeaveOptimizerScreen> createState() => _LeaveOptimizerScreenState();
}

class _LeaveOptimizerScreenState extends ConsumerState<LeaveOptimizerScreen> {
  int _maxLeaveDays = 5;

  @override
  Widget build(BuildContext context) {
    final teamId = ref.watch(selectedTeamProvider);
    final settings = ref.watch(settingsProvider);
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final now = DateTime.now();
    final yearEnd = DateTime(now.year, 12, 31);
    final daysLeft = yearEnd.difference(now).inDays + 1;

    final cycle = settings.isValid ? settings.shiftCycle : null;
    final refDate = settings.isValid ? settings.referenceDate : null;
    final phaseOffset = teamPhaseOffsetFor(teamId, customCycle: cycle);
    final plans = findBestLeavePlans(today: now, daysToAnalyze: daysLeft, teamPhaseOffset: phaseOffset, customCycle: cycle, referenceDate: refDate, maxLeaveDays: _maxLeaveDays);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.leaveOptimizer)),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Text(l10n.leaveOptimizerExplain, style: theme.textTheme.bodySmall),
        Text('${now.year}年${now.month}月${now.day}日 — ${now.year}年12月31日 · ${localizedTeamName(teamId, l10n)}', style: theme.textTheme.bodySmall),
        const SizedBox(height: 12),
        Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 8, children: [
          Padding(padding: const EdgeInsets.only(top: 8), child: Text(l10n.maxLeave)),
          for (final d in [1, 2, 3, 4, 5])
            FilterChip(label: Text('$d'), selected: _maxLeaveDays == d, onSelected: (_) => setState(() => _maxLeaveDays = d)),
        ]),
        const SizedBox(height: 12),
        if (plans.isEmpty)
          Center(child: Padding(padding: const EdgeInsets.all(32), child: Text(l10n.noLeavePlanFound)))
        else
          ...plans.take(10).map((p) => _StrategyCard(plan: p)),
      ]),
    );
  }
}

class _StrategyCard extends StatelessWidget {
  final LeaveStrategy plan;
  const _StrategyCard({required this.plan});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = plan.score > 0.7 ? shiftMorning : shiftAfternoon;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: CpShapes.card),
      margin: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(borderRadius: CpShapes.card, border: Border(left: BorderSide(color: accentColor, width: 4))),
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text('请假 ${plan.leaveDays} 天 → 连休 ${plan.totalBreakDays} 天', style: theme.textTheme.headlineMedium)),
            _Tag('${plan.efficiency.toStringAsFixed(1)}x', shiftRest),
          ]),
          const SizedBox(height: 4),
          Text('${plan.breakStart.month}月${plan.breakStart.day}日 — ${plan.breakEnd.month}月${plan.breakEnd.day}日', style: theme.textTheme.bodyMedium),
          if (plan.overlappingHolidayNames.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('含 ${plan.overlappingHolidayNames.join("、")}', style: TextStyle(color: shiftStudy, fontWeight: FontWeight.w600)),
          ],
          const SizedBox(height: 4),
          Row(children: [
            _Tag('请假${plan.leaveDays}天', Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(width: 8),
            _Tag('周末+${plan.weekendOverlap}', Theme.of(context).colorScheme.onSurfaceVariant),
          ]),
        ]),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;
  final Color color;
  const _Tag(this.text, this.color);
  @override
  Widget build(BuildContext context) {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)), child: Text(text, style: TextStyle(fontSize: 11, color: color)));
  }
}
