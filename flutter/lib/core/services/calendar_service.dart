import 'package:flutter/services.dart';
import '../../domain/models/shift_type.dart';
import '../../domain/models/alarm_settings.dart';
import '../../domain/algorithms/shift_calculator.dart';

/// Bridges to the native Android CalendarEventManager via MethodChannel.
///
/// All shift calculation happens in Dart (single source of truth).
/// Kotlin side only handles Calendar Provider CRUD — no algorithm duplication.
class CalendarService {
  static const _channel = MethodChannel('com.simpleshift.scheduler_cp/calendar');

  /// Sync shift events to the system calendar.
  ///
  /// Computes all (date, shift, alarmTime) tuples in Dart,
  /// then passes them as a flat list to Kotlin for calendar insertion.
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
    final events = <Map<String, dynamic>>[];

    for (int offset = 0; offset < daysAhead; offset++) {
      final date = today.add(Duration(days: offset));
      final dateStr =
          '${date.year}-'
          '${date.month.toString().padLeft(2, '0')}-'
          '${date.day.toString().padLeft(2, '0')}';

      final shiftType = getShiftTypeForDate(
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

      // Skip past events
      if (triggerAt.isBefore(DateTime.now())) continue;

      events.add({
        'date_key': dateStr,           // original shift date for dedup key
        'shift_index': shiftType.index, // 0=MORNING, 1=AFTERNOON, 2=REST, 3=NIGHT, 4=STUDY
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

  /// Delete all shift events from the system calendar.
  static Future<void> deleteAllEvents() async {
    try {
      await _channel.invokeMethod('deleteAllEvents');
    } catch (_) {}
  }
}
