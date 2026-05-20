import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/shapes.dart';
import '../../core/utils/l10n.dart';
import '../../domain/models/shift_type.dart';
import '../../domain/models/salary_config.dart';
import '../../domain/algorithms/salary_calculator.dart';
import '../../domain/algorithms/shift_calculator.dart';
import '../home/home_state.dart';

class SalaryPredictorScreen extends ConsumerStatefulWidget {
  const SalaryPredictorScreen({super.key});
  @override
  ConsumerState<SalaryPredictorScreen> createState() => _SalaryPredictorScreenState();
}

class _SalaryPredictorScreenState extends ConsumerState<SalaryPredictorScreen> {
  final _config = SalaryConfig(shiftPremiums: {ShiftType.MORNING: 0, ShiftType.AFTERNOON: 50, ShiftType.NIGHT: 200, ShiftType.STUDY: 0});
  int _extraCount = 0;
  ShiftType _extraType = ShiftType.NIGHT;

  @override
  Widget build(BuildContext context) {
    final teamId = ref.watch(selectedTeamProvider);
    final settings = ref.watch(settingsProvider);
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final now = DateTime.now();

    final cycle = settings.isValid ? settings.shiftCycle : null;
    final refDate = settings.isValid ? settings.referenceDate : null;
    final phaseOffset = teamPhaseOffsetFor(teamId, customCycle: cycle);
    final counts = countAllShiftTypesInMonth(now.year, now.month, teamPhaseOffset: phaseOffset, customCycle: cycle, referenceDate: refDate);
    final breakdown = calculateSalaryBreakdown(_config, counts, now.year, now.month);
    final simulated = simulateExtraShifts(breakdown, _extraCount, _extraType, _config);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.salaryTitle)),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Card(shape: RoundedRectangleBorder(borderRadius: CpShapes.card), child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(l10n.premiumPerShift, style: theme.textTheme.bodySmall),
          const SizedBox(height: 8),
          Row(children: [_PremiumDot(shiftMorning, localizedShiftFullLabel(ShiftType.MORNING, l10n)), _PremiumDot(shiftAfternoon, localizedShiftFullLabel(ShiftType.AFTERNOON, l10n))]),
          Row(children: [_PremiumDot(shiftNight, localizedShiftFullLabel(ShiftType.NIGHT, l10n)), _PremiumDot(shiftStudy, localizedShiftFullLabel(ShiftType.STUDY, l10n))]),
        ]))),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('${now.year}年${now.month}月', style: theme.textTheme.headlineMedium), Text(localizedTeamName(teamId, l10n), style: theme.textTheme.bodyLarge)]),
        const SizedBox(height: 8),
        Card(shape: RoundedRectangleBorder(borderRadius: CpShapes.mainCard), child: Container(width: double.infinity, padding: const EdgeInsets.all(24), decoration: BoxDecoration(borderRadius: CpShapes.mainCard, gradient: LinearGradient(colors: [shiftMorning.withValues(alpha: 0.08), shiftStudy.withValues(alpha: 0.04)])), child: Column(children: [
          Text(l10n.monthlyPremium, style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 8),
          Text('¥${breakdown.shiftPremiumTotal.toStringAsFixed(0)}', style: theme.textTheme.displayLarge?.copyWith(color: shiftMorning)),
        ]))),
        const SizedBox(height: 12),
        _ShiftCountRow(localizedShiftFullLabel(ShiftType.MORNING, l10n), counts[ShiftType.MORNING] ?? 0, _config.shiftPremiums[ShiftType.MORNING] ?? 0, shiftMorning),
        _ShiftCountRow(localizedShiftFullLabel(ShiftType.AFTERNOON, l10n), counts[ShiftType.AFTERNOON] ?? 0, _config.shiftPremiums[ShiftType.AFTERNOON] ?? 0, shiftAfternoon),
        _ShiftCountRow(localizedShiftFullLabel(ShiftType.NIGHT, l10n), counts[ShiftType.NIGHT] ?? 0, _config.shiftPremiums[ShiftType.NIGHT] ?? 0, shiftNight),
        _ShiftCountRow(localizedShiftFullLabel(ShiftType.REST, l10n), counts[ShiftType.REST] ?? 0, 0, shiftRest),
        _ShiftCountRow(localizedShiftFullLabel(ShiftType.STUDY, l10n), counts[ShiftType.STUDY] ?? 0, _config.shiftPremiums[ShiftType.STUDY] ?? 0, shiftStudy),
        const SizedBox(height: 16),
        Card(shape: RoundedRectangleBorder(borderRadius: CpShapes.card), child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(l10n.whatIf, style: const TextStyle(fontWeight: FontWeight.bold)), const SizedBox(height: 8),
          Row(children: [
            Text(l10n.ifMore),
            DropdownButton<int>(value: _extraCount, items: List.generate(6, (i) => i).map((n) => DropdownMenuItem(value: n, child: Text('$n'))).toList(), onChanged: (n) => setState(() => _extraCount = n ?? 0)),
            const SizedBox(width: 8),
            DropdownButton<ShiftType>(value: _extraType, items: ShiftType.values.where((t) => t != ShiftType.REST).map((t) => DropdownMenuItem(value: t, child: Text(localizedShiftFullLabel(t, l10n)))).toList(), onChanged: (t) => setState(() => _extraType = t ?? ShiftType.NIGHT)),
          ]),
          if (_extraCount > 0) ...[
            const SizedBox(height: 8),
            Text(l10n.whatIfResult((simulated.shiftPremiumTotal - breakdown.shiftPremiumTotal).toStringAsFixed(0)), style: theme.textTheme.headlineMedium?.copyWith(color: cpSuccess)),
          ],
        ]))),
      ]),
    );
  }
}

class _PremiumDot extends StatelessWidget {
  final Color color;
  final String label;
  const _PremiumDot(this.color, this.label);
  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.all(4), child: Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 4),
      Text('$label 0', style: const TextStyle(fontSize: 13)),
    ]));
  }
}

class _ShiftCountRow extends StatelessWidget {
  final String label;
  final int count;
  final double premium;
  final Color color;
  const _ShiftCountRow(this.label, this.count, this.premium, this.color);
  @override
  Widget build(BuildContext context) {
    final total = premium * count;
    return Padding(padding: const EdgeInsets.symmetric(vertical: 2), child: Row(children: [
      Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 8),
      Text('$label $count', style: const TextStyle(fontSize: 14)),
      const Spacer(),
      if (total > 0) Text('¥${total.toStringAsFixed(0)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
    ]));
  }
}
