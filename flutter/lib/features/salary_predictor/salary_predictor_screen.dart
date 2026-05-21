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
import 'salary_config_notifier.dart';

class SalaryPredictorScreen extends ConsumerStatefulWidget {
  const SalaryPredictorScreen({super.key});
  @override
  ConsumerState<SalaryPredictorScreen> createState() =>
      _SalaryPredictorScreenState();
}

class _SalaryPredictorScreenState
    extends ConsumerState<SalaryPredictorScreen> {
  bool _settingsExpanded = true;
  late int _year, _month;
  int _teamId = 1;

  // Inline editing state — no dialog, no Navigator
  ShiftType? _editingType;
  final _editCtrl = TextEditingController();
  final _editFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _year = now.year;
    _month = now.month;
  }

  @override
  void dispose() {
    _editCtrl.dispose();
    _editFocus.dispose();
    super.dispose();
  }

  void _startEdit(ShiftType type, double current) {
    setState(() {
      _editingType = type;
      _editCtrl.text = current == 0 ? '' : current.toStringAsFixed(current.truncateToDouble() == current ? 0 : 1);
    });
    _editFocus.requestFocus();
  }

  void _saveEdit() {
    final type = _editingType;
    if (type == null) return;
    final raw = _editCtrl.text.trim();
    final v = raw.isEmpty ? 0.0 : (double.tryParse(raw) ?? 0.0);
    ref.read(salaryConfigProvider.notifier).updatePremium(type, v < 0 ? 0.0 : v);
    setState(() => _editingType = null);
    _editFocus.unfocus();
  }

  void _cancelEdit() {
    setState(() => _editingType = null);
    _editFocus.unfocus();
  }

  void _prevMonth() {
    setState(() { _month--; if (_month < 1) { _month = 12; _year--; } });
  }

  void _nextMonth() {
    setState(() { _month++; if (_month > 12) { _month = 1; _year++; } });
  }

  @override
  Widget build(BuildContext context) {
    final teamId = _teamId;
    final settings = ref.watch(settingsProvider);
    final config = ref.watch(salaryConfigProvider);
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final now = DateTime.now();

    final cycle = settings.isValid ? settings.shiftCycle : null;
    final refDate = settings.isValid ? settings.referenceDate : null;
    final phaseOffset = teamPhaseOffsetFor(teamId, customCycle: cycle);
    final counts = countAllShiftTypesInMonth(
      _year, _month, teamPhaseOffset: phaseOffset, customCycle: cycle, referenceDate: refDate,
    );
    final breakdown = calculateSalaryBreakdown(config, counts, _year, _month);

    final isCurrentMonth = _year == now.year && _month == now.month;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.salaryTitle)),
      body: GestureDetector(
        onTap: () {
          // Tap outside to cancel editing
          if (_editingType != null) _cancelEdit();
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Premium settings ──
            Card(
              shape: RoundedRectangleBorder(borderRadius: CpShapes.card),
              child: Column(children: [
                InkWell(
                  borderRadius: CpShapes.card,
                  onTap: () => setState(() => _settingsExpanded = !_settingsExpanded),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(children: [
                      Icon(_settingsExpanded ? Icons.expand_less : Icons.expand_more, size: 20),
                      const SizedBox(width: 4),
                      Text(l10n.premiumPerShift, style: theme.textTheme.titleSmall),
                      const Spacer(),
                      Text('¥${breakdown.shiftPremiumTotal.toStringAsFixed(0)}',
                          style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.primary)),
                    ]),
                  ),
                ),
                if (_settingsExpanded)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(children: [
                      _buildPremiumRow(ShiftType.MORNING, localizedShiftFullLabel(ShiftType.MORNING, l10n), shiftMorning, config),
                      _buildPremiumRow(ShiftType.AFTERNOON, localizedShiftFullLabel(ShiftType.AFTERNOON, l10n), shiftAfternoon, config),
                      _buildPremiumRow(ShiftType.NIGHT, localizedShiftFullLabel(ShiftType.NIGHT, l10n), shiftNight, config),
                      _buildPremiumRow(ShiftType.STUDY, localizedShiftFullLabel(ShiftType.STUDY, l10n), shiftStudy, config),
                    ]),
                  ),
              ]),
            ),

            const SizedBox(height: 16),

            // ── Month + Team row ──
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Row(children: [
                IconButton(onPressed: _prevMonth, icon: const Icon(Icons.chevron_left), visualDensity: VisualDensity.compact),
                Text(l10n.monthYearFormat(_year, _month), style: theme.textTheme.headlineMedium),
                IconButton(onPressed: _nextMonth, icon: const Icon(Icons.chevron_right), visualDensity: VisualDensity.compact),
                if (!isCurrentMonth)
                  TextButton(onPressed: () { setState(() { _year = now.year; _month = now.month; }); }, child: Text(l10n.today, style: const TextStyle(fontSize: 12))),
              ]),
              DropdownButton<int>(
                value: teamId, underline: const SizedBox(),
                items: List.generate(6, (i) => i + 1).map((id) => DropdownMenuItem(value: id, child: Text(localizedTeamName(id, l10n)))).toList(),
                onChanged: (id) { if (id != null) setState(() => _teamId = id); },
              ),
            ]),

            const SizedBox(height: 8),

            // ── Total card ──
            Card(
              shape: RoundedRectangleBorder(borderRadius: CpShapes.mainCard),
              child: Container(
                width: double.infinity, padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: CpShapes.mainCard,
                  gradient: LinearGradient(colors: [shiftMorning.withValues(alpha: 0.08), shiftStudy.withValues(alpha: 0.04)]),
                ),
                child: Column(children: [
                  Text(l10n.monthlyPremium, style: const TextStyle(fontSize: 14)),
                  const SizedBox(height: 8),
                  Text('¥${breakdown.shiftPremiumTotal.toStringAsFixed(0)}', style: theme.textTheme.displayLarge?.copyWith(color: shiftMorning)),
                ]),
              ),
            ),

            const SizedBox(height: 12),

            // ── Breakdown ──
            _ShiftCountRow(localizedShiftFullLabel(ShiftType.MORNING, l10n), counts[ShiftType.MORNING] ?? 0, config.shiftPremiums[ShiftType.MORNING] ?? 0, shiftMorning),
            _ShiftCountRow(localizedShiftFullLabel(ShiftType.AFTERNOON, l10n), counts[ShiftType.AFTERNOON] ?? 0, config.shiftPremiums[ShiftType.AFTERNOON] ?? 0, shiftAfternoon),
            _ShiftCountRow(localizedShiftFullLabel(ShiftType.NIGHT, l10n), counts[ShiftType.NIGHT] ?? 0, config.shiftPremiums[ShiftType.NIGHT] ?? 0, shiftNight),
            _ShiftCountRow(localizedShiftFullLabel(ShiftType.REST, l10n), counts[ShiftType.REST] ?? 0, 0, shiftRest),
            _ShiftCountRow(localizedShiftFullLabel(ShiftType.STUDY, l10n), counts[ShiftType.STUDY] ?? 0, config.shiftPremiums[ShiftType.STUDY] ?? 0, shiftStudy),
          ],
        ),
      ),
    );
  }

  // ── Premium row: inline editing ──

  Widget _buildPremiumRow(ShiftType type, String label, Color color, SalaryConfig config) {
    final value = config.shiftPremiums[type] ?? 0;
    final isEditing = _editingType == type;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: isEditing
          ? Row(children: [
              Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              SizedBox(width: 28, child: Text(label, style: const TextStyle(fontSize: 14))),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _editCtrl,
                  focusNode: _editFocus,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _saveEdit(),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(icon: const Icon(Icons.check, color: Colors.green), onPressed: _saveEdit, visualDensity: VisualDensity.compact),
              IconButton(icon: const Icon(Icons.close, color: Colors.grey), onPressed: _cancelEdit, visualDensity: VisualDensity.compact),
            ])
          : InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => _startEdit(type, value),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                child: Row(children: [
                  Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  Text(label, style: const TextStyle(fontSize: 14)),
                  const Spacer(),
                  Text(value == 0 ? context.l10n.alarmNotSet : '¥${value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 1)}',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                          color: value > 0 ? color : Theme.of(context).colorScheme.onSurfaceVariant)),
                  const SizedBox(width: 4),
                  Text(context.l10n.yuanPerShift, style: const TextStyle(fontSize: 13)),
                  const SizedBox(width: 4),
                  Icon(Icons.edit, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
                ]),
              ),
            ),
    );
  }
}

// ── Shift count row ──

class _ShiftCountRow extends StatelessWidget {
  final String label;
  final int count;
  final double premium;
  final Color color;
  const _ShiftCountRow(this.label, this.count, this.premium, this.color);

  @override
  Widget build(BuildContext context) {
    final total = premium * count;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text('$label $count', style: const TextStyle(fontSize: 14)),
        const Spacer(),
        if (total > 0)
          Text('¥${total.toStringAsFixed(0)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}
