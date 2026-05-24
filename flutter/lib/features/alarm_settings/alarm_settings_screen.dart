import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/spacing.dart';
import '../../core/utils/responsive.dart';
import '../../core/theme/shapes.dart';
import '../../core/theme/colors.dart';
import '../../core/utils/l10n.dart';
import '../../domain/models/shift_type.dart';
import '../../domain/models/alarm_time.dart';
import '../home/alarm_settings_notifier.dart';

class AlarmSettingsScreen extends ConsumerWidget {
  const AlarmSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final alarmSettings = ref.watch(alarmSettingsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.alarmSettings)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: contentMaxWidth(context)),
            child: ListView(
              padding: const EdgeInsets.all(CpSpacing.md),
              children: [
                // 说明卡片
                Card(
                  shape: RoundedRectangleBorder(borderRadius: CpShapes.card),
                  child: Padding(
                    padding: const EdgeInsets.all(CpSpacing.sm),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline, size: 20),
                        const SizedBox(width: CpSpacing.xs),
                        Expanded(
                          child: Text(
                            l10n.alarmSettingsInfo,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: CpSpacing.sm),
                // 提醒设置卡片
                Card(
                  shape: RoundedRectangleBorder(borderRadius: CpShapes.card),
                  child: Padding(
                    padding: const EdgeInsets.all(CpSpacing.sm),
                    child: Column(
                      children: ShiftType.values
                          .map((type) => _ShiftAlarmRow(
                                shiftType: type,
                                alarmTime: alarmSettings.alarms[type],
                                onEdit: (time) => ref
                                    .read(alarmSettingsProvider.notifier)
                                    .updateAlarmTime(type, time),
                                onRemove: () => ref
                                    .read(alarmSettingsProvider.notifier)
                                    .updateAlarmTime(type, null),
                              ))
                          .toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ShiftAlarmRow extends StatelessWidget {
  final ShiftType shiftType;
  final AlarmTime? alarmTime;
  final ValueChanged<AlarmTime> onEdit;
  final VoidCallback onRemove;

  const _ShiftAlarmRow({
    required this.shiftType,
    required this.alarmTime,
    required this.onEdit,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final color = shiftColor(shiftType);
    final hasAlarm = alarmTime != null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        borderRadius: CpShapes.button,
        onTap: () => _showTimePicker(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  localizedShiftFullLabel(shiftType, l10n),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
              Text(
                hasAlarm ? alarmTime!.serialize() : l10n.alarmNotSet,
                style: TextStyle(
                  color: hasAlarm
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: hasAlarm ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              if (hasAlarm) ...[
                const SizedBox(width: 12),
                InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: onRemove,
                  child: Icon(
                    Icons.close,
                    size: 16,
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right,
                size: 18,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showTimePicker(BuildContext context) async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: alarmTime?.hour ?? 7,
        minute: alarmTime?.minute ?? 0,
      ),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );

    if (time != null && context.mounted) {
      onEdit(AlarmTime(hour: time.hour, minute: time.minute));
    }
  }
}
