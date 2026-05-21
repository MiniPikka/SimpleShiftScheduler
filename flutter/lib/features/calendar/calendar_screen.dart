import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/shapes.dart';
import '../../core/utils/l10n.dart';
import '../../domain/models/shift_type.dart';
import '../../domain/algorithms/calendar_generator.dart';
import '../../domain/algorithms/shift_calculator.dart';
import '../../domain/algorithms/shift_metrics.dart';
import '../home/home_state.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});
  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late int year, month;
  final _weekKeys = [DateTime.sunday, DateTime.monday, DateTime.tuesday, DateTime.wednesday, DateTime.thursday, DateTime.friday, DateTime.saturday];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    year = now.year;
    month = now.month;
  }

  void _prevMonth() { setState(() { month--; if (month < 1) { month = 12; year--; } }); }
  void _nextMonth() { setState(() { month++; if (month > 12) { month = 1; year++; } }); }
  void _goToToday() { final now = DateTime.now(); setState(() { year = now.year; month = now.month; }); }

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
    final days = generateMonthCalendarDays(year, month, teamPhaseOffset: phaseOffset, customCycle: cycle, referenceDate: refDate);
    final isCurrentMonth = year == now.year && month == now.month;

    final stats = <ShiftType, int>{};
    for (final type in ShiftType.values) {
      stats[type] = countShiftTypeInMonth(year, month, type, teamPhaseOffset: phaseOffset, customCycle: cycle, referenceDate: refDate);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.calendarTitle),
        actions: [if (!isCurrentMonth) TextButton(onPressed: _goToToday, child: Text(l10n.today))],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: CpSpacing.maxContentWidth),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(CpSpacing.sm),
              child: Column(children: [
                Row(children: [
                  Text('${l10n.teamLabel}'),
                  DropdownButton<int>(
                    value: teamId,
                    items: List.generate(6, (i) => i + 1).map((id) => DropdownMenuItem(value: id, child: Text(localizedTeamName(id, l10n)))).toList(),
                    onChanged: (id) { if (id != null) { ref.read(selectedTeamProvider.notifier).state = id; ref.read(homeProvider.notifier).refresh(); } },
                  ),
                ]),
                const SizedBox(height: 12),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  switchInCurve: Curves.easeOut,
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(begin: const Offset(0.06, 0), end: Offset.zero).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: Column(key: ValueKey('$year-$month'), children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      IconButton(onPressed: _prevMonth, icon: const Icon(Icons.chevron_left)),
                      Text('$year年${month}月', style: theme.textTheme.headlineMedium),
                      IconButton(onPressed: _nextMonth, icon: const Icon(Icons.chevron_right)),
                    ]),
                    const SizedBox(height: 8),
                    Row(children: _weekKeys.map((wk) => Expanded(child: Center(child: Text(localizedWeekday(wk, l10n), style: theme.textTheme.bodySmall?.copyWith(color: (wk == DateTime.sunday || wk == DateTime.saturday) ? theme.colorScheme.primary : null))))).toList()),
                    const SizedBox(height: 4),
                    Wrap(children: days.map((day) {
                      final isToday = day.date.year == now.year && day.date.month == now.month && day.date.day == now.day;
                      final color = shiftColor(day.shiftType);
                      final dimmed = !day.isCurrentMonth;
                      return SizedBox(
                        width: (MediaQuery.of(context).size.width - 32) / 7,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 2),
                          decoration: isToday ? BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: theme.colorScheme.primary, width: 2)) : null,
                          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                          child: Column(mainAxisSize: MainAxisSize.min, children: [
                            Text('${day.date.day}', style: TextStyle(fontSize: 13, fontWeight: isToday ? FontWeight.bold : FontWeight.normal, color: dimmed ? theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4) : null)),
                            const SizedBox(height: 1),
                            Container(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1), decoration: BoxDecoration(color: dimmed ? color.withValues(alpha: 0.06) : color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(4)), child: Text(localizedShiftLabel(day.shiftType, l10n), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: dimmed ? color.withValues(alpha: 0.5) : color))),
                          ]),
                        ),
                      );
                    }).toList()),
                  ]),
                ),
                const SizedBox(height: 16),
                Card(shape: RoundedRectangleBorder(borderRadius: CpShapes.card), child: Padding(padding: const EdgeInsets.all(16), child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                  _StatItem(l10n.statMorning, '${stats[ShiftType.MORNING] ?? 0}', shiftMorning),
                  _StatItem(l10n.statAfternoon, '${stats[ShiftType.AFTERNOON] ?? 0}', shiftAfternoon),
                  _StatItem(l10n.statRest, '${stats[ShiftType.REST] ?? 0}', shiftRest),
                  _StatItem(l10n.statNight, '${stats[ShiftType.NIGHT] ?? 0}', shiftNight),
                  _StatItem(l10n.statStudy, '${stats[ShiftType.STUDY] ?? 0}', shiftStudy),
                ]))),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label, value;
  final Color color;
  const _StatItem(this.label, this.value, this.color);
  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Text(value, style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: color, fontWeight: FontWeight.bold)),
      Text(label, style: Theme.of(context).textTheme.bodySmall),
    ]);
  }
}
