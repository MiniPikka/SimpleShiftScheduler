import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/shapes.dart';
import '../../core/utils/l10n.dart';
import '../../core/services/share_service.dart';
import '../../domain/algorithms/colleague_mode.dart';
import '../home/home_state.dart';

class ColleagueModeScreen extends ConsumerStatefulWidget {
  const ColleagueModeScreen({super.key});
  @override
  ConsumerState<ColleagueModeScreen> createState() => _ColleagueModeScreenState();
}

class _ColleagueModeScreenState extends ConsumerState<ColleagueModeScreen> {
  late int _teamAId, _teamBId;

  @override
  void initState() {
    super.initState();
    _teamAId = ref.read(selectedTeamProvider);
    _teamBId = _teamAId < 6 ? _teamAId + 1 : 1;
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final now = DateTime.now();

    final cycle = settings.isValid ? settings.shiftCycle : null;
    final refDate = settings.isValid ? settings.referenceDate : null;
    final result = findCommonRestDays(teamAId: _teamAId, teamBId: _teamBId, today: now, customCycle: cycle, referenceDate: refDate, teamNameResolver: (id) => localizedTeamName(id, l10n));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.colleagueModeTitle),
        actions: [
          if (_teamAId != _teamBId && result.nextCommonRestDate != null)
            IconButton(
              icon: const Icon(Icons.share_outlined),
              tooltip: 'Share',
              onPressed: () => _shareResult(result, l10n),
            ),
        ],
      ),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Row(children: [
          Expanded(child: _TeamPicker(label: l10n.iam, value: _teamAId, onChanged: (id) => setState(() => _teamAId = id))),
          IconButton(icon: const Icon(Icons.swap_horiz), onPressed: () => setState(() { final t = _teamAId; _teamAId = _teamBId; _teamBId = t; })),
          Expanded(child: _TeamPicker(label: l10n.heis, value: _teamBId, onChanged: (id) => setState(() => _teamBId = id))),
        ]),
        const SizedBox(height: 16),
        if (_teamAId == _teamBId)
          Card(child: Padding(padding: const EdgeInsets.all(16), child: Text(l10n.sameTeam, style: theme.textTheme.bodyLarge)))
        else ...[
          Card(
            shape: RoundedRectangleBorder(borderRadius: CpShapes.mainCard),
            child: Container(
              width: double.infinity, padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(borderRadius: CpShapes.mainCard, gradient: LinearGradient(colors: [shiftNight.withValues(alpha: 0.08), shiftStudy.withValues(alpha: 0.04)])),
              child: Column(children: [
                Text(l10n.nextCommonRest, style: const TextStyle(fontSize: 14)),
                const SizedBox(height: 8),
                Text(result.nextCommonRestDate != null ? '${result.nextCommonRestDate!.month}月${result.nextCommonRestDate!.day}日' : l10n.noCommonRest, style: theme.textTheme.displayLarge),
                if (result.daysUntilNext != null) ...[
                  const SizedBox(height: 4),
                  Text(l10n.daysUntil(result.daysUntilNext!), style: theme.textTheme.bodyLarge),
                ],
              ]),
            ),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _StatCard(l10n.next30days, l10n.dayCount(result.countIn30Days), shiftRest)),
            const SizedBox(width: 12),
            Expanded(child: _StatCard(l10n.next60days, l10n.dayCount(result.countIn60Days), shiftAfternoon)),
          ]),
          const SizedBox(height: 12),
          Text(l10n.commonRestDaysList(result.totalCount), style: theme.textTheme.bodyLarge),
          const SizedBox(height: 8),
          if (result.commonRestDates.isEmpty)
            Center(child: Padding(padding: const EdgeInsets.all(16), child: Text(l10n.noCommonRestFound)))
          else
            ...result.commonRestDates.take(20).map((date) {
              final diffDays = date.difference(now).inDays;
              return ListTile(
                dense: true,
                title: Text('${date.month}月${date.day}日 ${localizedWeekday(date.weekday, l10n)}'),
                trailing: Text(diffDays == 0 ? l10n.statusToday : l10n.dayCount(diffDays), style: TextStyle(color: diffDays == 0 ? shiftRest : null)),
              );
            }),
        ],
      ]),
    );
  }

  void _shareResult(result, l10n) {
    if (result.nextCommonRestDate == null) return;
    final nextDate = result.nextCommonRestDate!;
    final weekday = localizedWeekday(nextDate.weekday, l10n);
    final text = '''
【倒班助手 - 同事模式】
${l10n.nextCommonRest}：${nextDate.month}月${nextDate.day}日 $weekday
${l10n.daysUntil(result.daysUntilNext!)}
${l10n.next30days}：${result.countIn30Days} 次
${l10n.next60days}：${result.countIn60Days} 次

${result.teamAName} & ${result.teamBName}
—— 来自倒班助手''';
    shareText(text, subject: '${result.teamAName} & ${result.teamBName} 共同休息');
  }
}

class _TeamPicker extends StatelessWidget {
  final String label;
  final int value;
  final ValueChanged<int> onChanged;
  const _TeamPicker({required this.label, required this.value, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(children: [
      Text(label, style: Theme.of(context).textTheme.bodySmall),
      DropdownButton<int>(value: value, underline: const SizedBox.shrink(), items: List.generate(6, (i) => i + 1).map((id) => DropdownMenuItem(value: id, child: Text(localizedTeamName(id, l10n)))).toList(), onChanged: (id) => id != null ? onChanged(id) : null),
    ])));
  }
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final Color color;
  const _StatCard(this.label, this.value, this.color);
  @override
  Widget build(BuildContext context) {
    return Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
      Text(value, style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: color, fontWeight: FontWeight.bold)),
      Text(label, style: Theme.of(context).textTheme.bodySmall),
    ])));
  }
}
