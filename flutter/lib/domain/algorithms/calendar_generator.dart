import '../models/calendar_day_info.dart';
import '../models/shift_type.dart';
import '../models/shift_cycle_config.dart';
import '../bridge/ffi_bridge.dart';
import 'shift_calculator.dart';

const int calendarGridDays = 42;

/// 生成 7×7 月历数据 — 优先走 Rust FFI 批量查，失败回退逐天 Dart。
List<CalendarDayInfo> generateMonthCalendarDays(
  int year,
  int month, {
  int firstDayOfWeek = DateTime.sunday, // 1=Mon..7=Sun in Dart
  int teamPhaseOffset = 0,
  List<ShiftType>? customCycle,
  DateTime? referenceDate,
}) {
  final firstDay = DateTime(year, month, 1);
  final dow = firstDay.weekday;
  final leadingDays = (dow - (firstDayOfWeek == DateTime.sunday ? 7 : 1) + 7) % 7;
  final gridStartDate = firstDay.subtract(Duration(days: leadingDays));
  final gridEndDate = gridStartDate.add(const Duration(days: calendarGridDays - 1));

  // Try Rust FFI batch for default cycle
  if (customCycle == null || customCycle.length == ShiftCycleConfig.cycleLength) {
    final refDate = referenceDate ?? ShiftCycleConfig.referenceDate;
    final teamId = (teamPhaseOffset ~/ teamPhaseStepFor()) + 1;
    final batch = ffiGetShiftInfoRange(
      startDate: gridStartDate,
      endDate: gridEndDate,
      teamId: teamId,
      cycleLength: customCycle?.length ?? 0,
      referenceDate: refDate,
    );
    if (batch != null) {
      return List.generate(calendarGridDays, (offset) {
        final entry = batch[offset];
        return CalendarDayInfo(
          date: gridStartDate.add(Duration(days: offset)),
          shiftType: parseShiftType(entry['shift_type'] as String),
          isCurrentMonth: DateTime.parse(entry['date'] as String).month == month,
        );
      });
    }
  }

  // Fallback to per-day pure Dart
  return List.generate(calendarGridDays, (offset) {
    final date = gridStartDate.add(Duration(days: offset));
    final shiftType = getShiftTypeForDate(
      date,
      teamPhaseOffset: teamPhaseOffset,
      customCycle: customCycle,
      referenceDate: referenceDate,
    );
    return CalendarDayInfo(
      date: date,
      shiftType: shiftType,
      isCurrentMonth: date.month == month,
    );
  });
}
