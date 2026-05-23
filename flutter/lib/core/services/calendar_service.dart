import 'package:flutter/services.dart';
import '../../domain/models/shift_type.dart';
import '../../domain/models/shift_cycle_config.dart';
import '../../domain/models/alarm_settings.dart';
import '../../domain/algorithms/shift_calculator.dart';
import '../../domain/bridge/ffi_bridge.dart';

/// Bridges to the native Android CalendarEventManager via MethodChannel.
///
/// Shift calculation prioritizes Rust FFI batch — one call for the entire date range.
/// Dart per-day loop is the fallback.
class CalendarService {
  static const _channel = MethodChannel('com.simpleshift.scheduler_cp/calendar');

  /// Sync shift events to the system calendar.
  static Future<int> syncShiftEvents({
    required List<ShiftType> shiftCycle,
    required int teamPhaseOffset,
    required AlarmSettings alarmSettings,
    required String referenceDate,
    int daysAhead = 365,
  }) async {
    if (!alarmSettings.isAnyEnabled()) return 0;

    final today = DateTime.now();
    final refDate = DateTime.tryParse(referenceDate) ?? DateTime(2025, 12, 15);
    final endDate = today.add(Duration(days: daysAhead - 1));

    // Try batch FFI for default cycle
    List<Map<String, dynamic>>? batch;
    if (shiftCycle.length == ShiftCycleConfig.cycleLength) {
      final teamId = (teamPhaseOffset ~/ teamPhaseStepFor()) + 1;
      batch = ffiGetShiftInfoRange(
        startDate: today,
        endDate: endDate,
        teamId: teamId,
        cycleLength: shiftCycle.length,
        referenceDate: refDate,
      );
    }

    final events = <Map<String, dynamic>>[];

    for (int offset = 0; offset < daysAhead; offset++) {
      final date = today.add(Duration(days: offset));
      final dateStr =
          '${date.year}-'
          '${date.month.toString().padLeft(2, '0')}-'
          '${date.day.toString().padLeft(2, '0')}';

      final shiftType = _shiftTypeFromBatch(batch, offset) ??
          getShiftTypeForDate(
            date,
            teamPhaseOffset: teamPhaseOffset,
            customCycle: shiftCycle,
            referenceDate: refDate,
          );

      final alarmTime = alarmSettings.alarms[shiftType];
      if (alarmTime == null) continue;

      // NIGHT shift: event goes on the previous day
      final eventDate = shiftType == ShiftType.NIGHT
          ? date.subtract(const Duration(days: 1))
          : date;

      final triggerAt = DateTime(
        eventDate.year, eventDate.month, eventDate.day,
        alarmTime.hour, alarmTime.minute,
      );

      if (triggerAt.isBefore(DateTime.now())) continue;

      events.add({
        'date_key': dateStr,
        'shift_index': shiftType.index,
        'event_year': eventDate.year,
        'event_month': eventDate.month,
        'event_day': eventDate.day,
        'trigger_hour': alarmTime.hour,
        'trigger_minute': alarmTime.minute,
      });
    }

    if (events.isEmpty) return 0;

    try {
      final result = await _channel.invokeMethod<int>('syncShiftEvents', {
        'events': events,
      });
      return result ?? 0;
    } catch (e) {
      return 0;
    }
  }

  static ShiftType? _shiftTypeFromBatch(List<Map<String, dynamic>>? batch, int offset) {
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

  /// Delete all shift events from the system calendar.
  static Future<void> deleteAllEvents() async {
    try {
      await _channel.invokeMethod('deleteAllEvents');
    } catch (_) {}
  }
}
