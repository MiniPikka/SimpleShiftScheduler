import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/shapes.dart';
import '../../core/utils/l10n.dart';
import '../../domain/models/shift_type.dart';
import '../../domain/models/shift_cycle_config.dart';
import '../../domain/models/team.dart';
import 'shift_rule_notifier.dart';

class ShiftRuleScreen extends ConsumerStatefulWidget {
  const ShiftRuleScreen({super.key});
  @override
  ConsumerState<ShiftRuleScreen> createState() => _ShiftRuleScreenState();
}

class _ShiftRuleScreenState extends ConsumerState<ShiftRuleScreen> {
  final _lenCtrl = TextEditingController();

  @override
  void dispose() {
    _lenCtrl.dispose();
    super.dispose();
  }

  // ── Presets ──────────────────────────────────────────────

  static const _preset7 = [
    ShiftType.MORNING,
    ShiftType.AFTERNOON,
    ShiftType.REST,
    ShiftType.NIGHT,
    ShiftType.REST,
    ShiftType.REST,
    ShiftType.REST,
  ];

  static const _preset14 = [
    ShiftType.MORNING, ShiftType.MORNING,
    ShiftType.AFTERNOON, ShiftType.AFTERNOON,
    ShiftType.REST,
    ShiftType.NIGHT, ShiftType.NIGHT,
    ShiftType.REST, ShiftType.REST,
    ShiftType.MORNING, ShiftType.MORNING,
    ShiftType.AFTERNOON, ShiftType.AFTERNOON,
    ShiftType.REST, ShiftType.REST,
  ];

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(shiftRuleProvider);
    final notifier = ref.read(shiftRuleProvider.notifier);
    final l10n = context.l10n;
    final theme = Theme.of(context);

    if (state.isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.shiftRule)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Sync length controller
    final lenText = '${state.cycleLength}';
    if (_lenCtrl.text != lenText) {
      _lenCtrl.text = lenText;
    }

    return PopScope(
      canPop: !state.isDirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('放弃修改？'),
            content: const Text('有未保存的修改，确定要离开吗？'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('继续编辑')),
              FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('放弃')),
            ],
          ),
        );
        if (ok == true && context.mounted) context.pop();
      },
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.shiftRule)),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── ① Cycle length ──
              Card(
                shape: RoundedRectangleBorder(borderRadius: CpShapes.card),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(children: [
                    const Text('周期长度', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 72,
                      child: TextField(
                        controller: _lenCtrl,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
                        onSubmitted: (v) {
                          final n = int.tryParse(v);
                          if (n != null) notifier.setCycleLength(n);
                        },
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text('天', style: TextStyle(fontSize: 14)),
                    const Spacer(),
                    Text('${state.sequence.length} 项',
                        style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
                  ]),
                ),
              ),

              const SizedBox(height: 12),

              // ── ② Presets ──
              Wrap(spacing: 8, runSpacing: 4, children: [
                ActionChip(
                  avatar: const Icon(Icons.restore, size: 16),
                  label: const Text('默认42天'),
                  onPressed: () => notifier.applyPreset(ShiftCycleConfig.shiftCycle),
                  visualDensity: VisualDensity.compact,
                ),
                ActionChip(
                  label: const Text('7天轮转'),
                  onPressed: () => notifier.applyPreset(_preset7),
                  visualDensity: VisualDensity.compact,
                ),
                ActionChip(
                  label: const Text('14天轮转'),
                  onPressed: () => notifier.applyPreset(_preset14),
                  visualDensity: VisualDensity.compact,
                ),
                ActionChip(
                  avatar: const Icon(Icons.delete_outline, size: 16),
                  label: const Text('清空'),
                  onPressed: () => notifier.clearAll(),
                  visualDensity: VisualDensity.compact,
                ),
              ]),

              const SizedBox(height: 16),

              // ── ③ Add buttons ──
              const Text('添加班次', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 4, children: [
                _AddButton(ShiftType.MORNING, localizedShiftFullLabel(ShiftType.MORNING, l10n), shiftMorning, () => notifier.addShift(ShiftType.MORNING)),
                _AddButton(ShiftType.AFTERNOON, localizedShiftFullLabel(ShiftType.AFTERNOON, l10n), shiftAfternoon, () => notifier.addShift(ShiftType.AFTERNOON)),
                _AddButton(ShiftType.REST, localizedShiftFullLabel(ShiftType.REST, l10n), shiftRest, () => notifier.addShift(ShiftType.REST)),
                _AddButton(ShiftType.NIGHT, localizedShiftFullLabel(ShiftType.NIGHT, l10n), shiftNight, () => notifier.addShift(ShiftType.NIGHT)),
                _AddButton(ShiftType.STUDY, localizedShiftFullLabel(ShiftType.STUDY, l10n), shiftStudy, () => notifier.addShift(ShiftType.STUDY)),
              ]),

              const SizedBox(height: 16),

              // ── ④ Sequence chips ──
              Card(
                shape: RoundedRectangleBorder(borderRadius: CpShapes.card),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('轮转序列（${state.sequence.length} 项）',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      if (state.sequence.isEmpty)
                        Text('请添加至少一个班次',
                            style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurfaceVariant)),
                      Wrap(spacing: 4, runSpacing: 4, children: List.generate(state.sequence.length, (i) {
                        final type = state.sequence[i];
                        final color = shiftColor(type);
                        return Chip(
                          avatar: CircleAvatar(
                            backgroundColor: color,
                            radius: 6,
                          ),
                          label: Text('${i + 1}. ${localizedShiftLabel(type, l10n)}',
                              style: const TextStyle(fontSize: 12)),
                          deleteIcon: const Icon(Icons.close, size: 16),
                          onDeleted: () => notifier.removeShift(i),
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        );
                      })),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ── ⑤ Date + Team ──
              Card(
                shape: RoundedRectangleBorder(borderRadius: CpShapes.card),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: state.startDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2035),
                        );
                        if (picked != null) notifier.setStartDate(picked);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(children: [
                          const Icon(Icons.calendar_today, size: 20),
                          const SizedBox(width: 12),
                          const Text('起始日期', style: TextStyle(fontSize: 14)),
                          const Spacer(),
                          Text(
                            '${state.startDate.year}-${state.startDate.month.toString().padLeft(2, '0')}-${state.startDate.day.toString().padLeft(2, '0')}',
                            style: TextStyle(fontSize: 14, color: theme.colorScheme.primary, fontWeight: FontWeight.w600),
                          ),
                          const Icon(Icons.chevron_right, size: 20),
                        ]),
                      ),
                    ),
                    const Divider(),
                    Row(children: [
                      const Icon(Icons.group_outlined, size: 20),
                      const SizedBox(width: 12),
                      const Text('默认班组', style: TextStyle(fontSize: 14)),
                      const Spacer(),
                      DropdownButton<int>(
                        value: state.defaultTeamId,
                        underline: const SizedBox(),
                        isDense: true,
                        items: List.generate(Team.totalTeams, (i) => i + 1)
                            .map((id) => DropdownMenuItem(
                                value: id,
                                child: Text(localizedTeamName(id, l10n))))
                            .toList(),
                        onChanged: (id) {
                          if (id != null) notifier.setDefaultTeam(id);
                        },
                      ),
                    ]),
                  ]),
                ),
              ),

              const SizedBox(height: 12),

              // ── ⑥ Preview ──
              Card(
                shape: RoundedRectangleBorder(borderRadius: CpShapes.card),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('预览', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Text('班组间隔: ${state.cycleLength ~/ Team.totalTeams} 天',
                        style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurfaceVariant)),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 2,
                      runSpacing: 2,
                      children: List.generate(state.sequence.length > 20 ? 20 : state.sequence.length, (i) {
                        return Container(
                          width: 8, height: 8,
                          margin: const EdgeInsets.all(1),
                          decoration: BoxDecoration(
                            color: shiftColor(state.sequence[i]),
                            shape: BoxShape.circle,
                          ),
                        );
                      }),
                    ),
                    if (state.sequence.length > 20)
                      Text('  ... 等共 ${state.sequence.length} 项',
                          style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant)),
                  ]),
                ),
              ),

              const SizedBox(height: 20),

              // ── ⑦ Save ──
              SizedBox(
                width: double.infinity,
                child: state.isSaved
                    ? FilledButton.tonalIcon(
                        style: FilledButton.styleFrom(backgroundColor: Colors.green.withValues(alpha: 0.15)),
                        onPressed: null,
                        icon: const Icon(Icons.check_circle, color: Colors.green),
                        label: const Text('已保存', style: TextStyle(color: Colors.green)),
                      )
                    : FilledButton.icon(
                        onPressed: state.isDirty ? () => notifier.save() : null,
                        icon: const Icon(Icons.save),
                        label: const Text('保存并生成排班表'),
                      ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Add button ──

class _AddButton extends StatelessWidget {
  final ShiftType type;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _AddButton(this.type, this.label, this.color, this.onTap);

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonal(
      style: FilledButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.12),
        foregroundColor: color,
        visualDensity: VisualDensity.compact,
      ),
      onPressed: onTap,
      child: Text(label),
    );
  }
}
