import '../../domain/models/shift_type.dart';
import '../../domain/models/shift_cycle_config.dart';
import '../../domain/models/alarm_settings.dart';
import '../../domain/algorithms/shift_calculator.dart';
import '../../domain/bridge/ffi_bridge.dart';
import 'notification_service.dart';

/// Schedule shift reminders for the next daysAhead days.
///
/// Prioritizes Rust FFI batch — one call for the entire date range.
/// Dart per-day loop is the fallback.
Future<void> scheduleShiftNotifications({
  required AlarmSettings alarmSettings,
  required List<ShiftType> shiftCycle,
  required int teamPhaseOffset,
  DateTime? referenceDate,
  int daysAhead = 30,
}) async {
  await NotificationService.cancelAllShiftReminders();

  if (!alarmSettings.isAnyEnabled()) return;

  final startOfToday = DateTime.now();
  final endDate = startOfToday.add(Duration(days: daysAhead - 1));

  // Try batch FFI for default cycle
  List<Map<String, dynamic>>? batch;
  if (shiftCycle.length == ShiftCycleConfig.cycleLength) {
    final teamId = (teamPhaseOffset ~/ teamPhaseStepFor()) + 1;
    batch = ffiGetShiftInfoRange(
      startDate: startOfToday,
      endDate: endDate,
      teamId: teamId,
      cycleLength: shiftCycle.length,
      referenceDate: referenceDate,
    );
  }

  for (int offset = 0; offset < daysAhead; offset++) {
    final date = startOfToday.add(Duration(days: offset));
    final shiftType = _shiftTypeFromBatch(batch, offset) ??
        getShiftTypeForDate(
          date,
          teamPhaseOffset: teamPhaseOffset,
          customCycle: shiftCycle,
          referenceDate: referenceDate,
        );

    final alarmTime = alarmSettings.alarms[shiftType];
    if (alarmTime == null) continue;

    final eventDate = shiftType == ShiftType.NIGHT ? date.subtract(const Duration(days: 1)) : date;

    final scheduledDate = DateTime(
      eventDate.year,
      eventDate.month,
      eventDate.day,
      alarmTime.hour,
      alarmTime.minute,
    );

    final daysSinceEpoch = date.difference(DateTime(1970, 1, 1)).inDays;
    final notificationId = (daysSinceEpoch * 10) + shiftType.index;

    await NotificationService.scheduleShiftReminder(
      id: notificationId,
      title: '${_shiftLabel(shiftType)} shift reminder',
      body: 'ShiftMate · ${_shiftLabel(shiftType)}',
      scheduledDate: scheduledDate,
    );
  }
}

ShiftType? _shiftTypeFromBatch(List<Map<String, dynamic>>? batch, int offset) {
  if (batch == null || offset >= batch.length) return null;
  switch (batch[offset]['shift_type'] as String?) {
    case 'morning': return ShiftType.MORNING;
    case 'afternoon': return ShiftType.AFTERNOON;
    case 'rest': return ShiftType.REST;
    case 'night': return ShiftType.NIGHT;
    case 'study': return ShiftType.STUDY;
    default: return null;
  }
}

String _shiftLabel(ShiftType type) {
  switch (type) {
    case ShiftType.MORNING: return 'Morning';
    case ShiftType.AFTERNOON: return 'Afternoon';
    case ShiftType.REST: return 'Rest';
    case ShiftType.NIGHT: return 'Night';
    case ShiftType.STUDY: return 'Study';
  }
}
