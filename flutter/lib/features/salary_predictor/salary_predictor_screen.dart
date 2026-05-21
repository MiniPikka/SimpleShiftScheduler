import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  bool _settingsExpanded = false;
  late int _year, _month;
  int _teamId = 1;
  int _extraCount = 0;
  ShiftType _extraType = ShiftType.NIGHT;

  // Text controllers for premium editing — lazily initialized
  final _controllers = <ShiftType, TextEditingController>{};

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _year = now.year;
    _month = now.month;
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _controllerFor(ShiftType type, double value) {
    if (!_controllers.containsKey(type)) {
      _controllers[type] = TextEditingController(
        text: value == 0 ? '' : value.toString(),
      );
    }
    return _controllers[type]!;
  }

  void _syncControllers(SalaryConfig config) {
    for (final type in ShiftType.values) {
      if (type == ShiftType.REST) continue;
      final value = config.shiftPremiums[type] ?? 0;
      final c = _controllerFor(type, value);
      final expected = value == 0 ? '' : value.toString();
      if (c.text != expected) {
        c.text = expected;
      }
    }
  }

  void _prevMonth() {
    setState(() {
      _month--;
      if (_month < 1) {
        _month = 12;
        _year--;
      }
    });
  }

  void _nextMonth() {
    setState(() {
      _month++;
      if (_month > 12) {
        _month = 1;
        _year++;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final teamId = _teamId;
    final settings = ref.watch(settingsProvider);
    final config = ref.watch(salaryConfigProvider);
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final now = DateTime.now();

    // Keep controllers in sync with persisted config
    _syncControllers(config);

    final cycle = settings.isValid ? settings.shiftCycle : null;
    final refDate = settings.isValid ? settings.referenceDate : null;
    final phaseOffset =
        teamPhaseOffsetFor(teamId, customCycle: cycle);
    final counts = countAllShiftTypesInMonth(
      _year, _month,
      teamPhaseOffset: phaseOffset,
      customCycle: cycle,
      referenceDate: refDate,
    );
    final breakdown = calculateSalaryBreakdown(
      config, counts, _year, _month,
    );
    final simulated =
        simulateExtraShifts(breakdown, _extraCount, _extraType, config);

    final isCurrentMonth =
        _year == now.year && _month == now.month;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.salaryTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Collapsible settings card ──
          Card(
            shape: RoundedRectangleBorder(borderRadius: CpShapes.card),
            child: InkWell(
              borderRadius: CpShapes.card,
              onTap: () =>
                  setState(() => _settingsExpanded = !_settingsExpanded),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _settingsExpanded
                              ? Icons.expand_less
                              : Icons.expand_more,
                          size: 20,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(l10n.premiumPerShift,
                            style: theme.textTheme.titleSmall),
                        const Spacer(),
                        if (!_settingsExpanded)
                          Text(
                            '${l10n.monthlyPremium}: ¥${breakdown.shiftPremiumTotal.toStringAsFixed(0)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.primary,
                            ),
                          ),
                      ],
                    ),
                    if (_settingsExpanded) ...[
                      const SizedBox(height: 12),
                      _PremiumRow(
                        type: ShiftType.MORNING,
                        label: localizedShiftFullLabel(
                            ShiftType.MORNING, l10n),
                        color: shiftMorning,
                        controller:
                            _controllerFor(ShiftType.MORNING,
                                config.shiftPremiums[ShiftType.MORNING] ?? 0),
                        onChanged: (v) => ref
                            .read(salaryConfigProvider.notifier)
                            .updatePremium(ShiftType.MORNING, v),
                      ),
                      _PremiumRow(
                        type: ShiftType.AFTERNOON,
                        label: localizedShiftFullLabel(
                            ShiftType.AFTERNOON, l10n),
                        color: shiftAfternoon,
                        controller: _controllerFor(ShiftType.AFTERNOON,
                            config.shiftPremiums[ShiftType.AFTERNOON] ?? 0),
                        onChanged: (v) => ref
                            .read(salaryConfigProvider.notifier)
                            .updatePremium(ShiftType.AFTERNOON, v),
                      ),
                      _PremiumRow(
                        type: ShiftType.NIGHT,
                        label: localizedShiftFullLabel(
                            ShiftType.NIGHT, l10n),
                        color: shiftNight,
                        controller:
                            _controllerFor(ShiftType.NIGHT,
                                config.shiftPremiums[ShiftType.NIGHT] ?? 0),
                        onChanged: (v) => ref
                            .read(salaryConfigProvider.notifier)
                            .updatePremium(ShiftType.NIGHT, v),
                      ),
                      _PremiumRow(
                        type: ShiftType.STUDY,
                        label: localizedShiftFullLabel(
                            ShiftType.STUDY, l10n),
                        color: shiftStudy,
                        controller:
                            _controllerFor(ShiftType.STUDY,
                                config.shiftPremiums[ShiftType.STUDY] ?? 0),
                        onChanged: (v) => ref
                            .read(salaryConfigProvider.notifier)
                            .updatePremium(ShiftType.STUDY, v),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ── Month + Team row ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                IconButton(
                  onPressed: _prevMonth,
                  icon: const Icon(Icons.chevron_left),
                  visualDensity: VisualDensity.compact,
                ),
                Text('$_year年$_month月',
                    style: theme.textTheme.headlineMedium),
                IconButton(
                  onPressed: _nextMonth,
                  icon: const Icon(Icons.chevron_right),
                  visualDensity: VisualDensity.compact,
                ),
                if (!isCurrentMonth)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _year = now.year;
                        _month = now.month;
                      });
                    },
                    child: Text(l10n.today, style: const TextStyle(fontSize: 12)),
                  ),
              ]),
              DropdownButton<int>(
                value: teamId,
                underline: const SizedBox(),
                items: List.generate(6, (i) => i + 1)
                    .map((id) => DropdownMenuItem(
                        value: id,
                        child: Text(localizedTeamName(id, l10n),
                            style: theme.textTheme.bodyMedium)))
                    .toList(),
                onChanged: (id) {
                  if (id != null) setState(() => _teamId = id);
                },
              ),
            ],
          ),

          const SizedBox(height: 8),

          // ── Premium total card ──
          Card(
            shape: RoundedRectangleBorder(borderRadius: CpShapes.mainCard),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: CpShapes.mainCard,
                gradient: LinearGradient(
                  colors: [
                    shiftMorning.withValues(alpha: 0.08),
                    shiftStudy.withValues(alpha: 0.04),
                  ],
                ),
              ),
              child: Column(children: [
                Text(l10n.monthlyPremium,
                    style: const TextStyle(fontSize: 14)),
                const SizedBox(height: 8),
                Text(
                  '¥${breakdown.shiftPremiumTotal.toStringAsFixed(0)}',
                  style: theme.textTheme.displayLarge
                      ?.copyWith(color: shiftMorning),
                ),
              ]),
            ),
          ),

          const SizedBox(height: 12),

          // ── Shift breakdown ──
          _ShiftCountRow(
            localizedShiftFullLabel(ShiftType.MORNING, l10n),
            counts[ShiftType.MORNING] ?? 0,
            config.shiftPremiums[ShiftType.MORNING] ?? 0,
            shiftMorning,
          ),
          _ShiftCountRow(
            localizedShiftFullLabel(ShiftType.AFTERNOON, l10n),
            counts[ShiftType.AFTERNOON] ?? 0,
            config.shiftPremiums[ShiftType.AFTERNOON] ?? 0,
            shiftAfternoon,
          ),
          _ShiftCountRow(
            localizedShiftFullLabel(ShiftType.NIGHT, l10n),
            counts[ShiftType.NIGHT] ?? 0,
            config.shiftPremiums[ShiftType.NIGHT] ?? 0,
            shiftNight,
          ),
          _ShiftCountRow(
            localizedShiftFullLabel(ShiftType.REST, l10n),
            counts[ShiftType.REST] ?? 0,
            0,
            shiftRest,
          ),
          _ShiftCountRow(
            localizedShiftFullLabel(ShiftType.STUDY, l10n),
            counts[ShiftType.STUDY] ?? 0,
            config.shiftPremiums[ShiftType.STUDY] ?? 0,
            shiftStudy,
          ),

          const SizedBox(height: 16),

          // ── What-if analysis ──
          Card(
            shape: RoundedRectangleBorder(borderRadius: CpShapes.card),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.whatIf,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(children: [
                    Text(l10n.ifMore, style: theme.textTheme.bodyMedium),
                    const SizedBox(width: 8),
                    ...List.generate(6, (i) => i).map((n) => Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: FilterChip(
                            label: Text('$n'),
                            selected: _extraCount == n,
                            onSelected: (_) =>
                                setState(() => _extraCount = n),
                            visualDensity: VisualDensity.compact,
                          ),
                        )),
                  ]),
                  const SizedBox(height: 8),
                  Row(children: [
                    Text(l10n.shiftStudy,
                        style: theme.textTheme.bodyMedium),
                    const SizedBox(width: 8),
                    DropdownButton<ShiftType>(
                      value: _extraType,
                      underline: const SizedBox(),
                      items: ShiftType.values
                          .where((t) => t != ShiftType.REST)
                          .map((t) => DropdownMenuItem(
                              value: t,
                              child: Text(
                                  localizedShiftFullLabel(t, l10n))))
                          .toList(),
                      onChanged: (t) {
                        if (t != null)
                          setState(() => _extraType = t);
                      },
                    ),
                  ]),
                  if (_extraCount > 0) ...[
                    const SizedBox(height: 8),
                    Text(
                      l10n.whatIfResult((simulated.shiftPremiumTotal -
                              breakdown.shiftPremiumTotal)
                          .toStringAsFixed(0)),
                      style: theme.textTheme.headlineMedium
                          ?.copyWith(color: cpSuccess),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Editable premium row ──

class _PremiumRow extends StatelessWidget {
  final ShiftType type;
  final String label;
  final Color color;
  final TextEditingController controller;
  final ValueChanged<double> onChanged;

  const _PremiumRow({
    required this.type,
    required this.label,
    required this.color,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        SizedBox(
            width: 32,
            child: Text(label,
                style: const TextStyle(fontSize: 14))),
        const SizedBox(width: 8),
        SizedBox(
          width: 100,
          child: TextField(
            controller: controller,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
            ],
            decoration: const InputDecoration(
              isDense: true,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              border: OutlineInputBorder(),
            ),
            onChanged: (raw) {
              final v = double.tryParse(raw);
              if (v != null && v >= 0) onChanged(v);
            },
          ),
        ),
        const SizedBox(width: 4),
        const Text('元/班', style: TextStyle(fontSize: 13)),
      ]),
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
        Container(
          width: 10,
          height: 10,
          decoration:
              BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text('$label $count', style: const TextStyle(fontSize: 14)),
        const Spacer(),
        if (total > 0)
          Text('¥${total.toStringAsFixed(0)}',
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}
