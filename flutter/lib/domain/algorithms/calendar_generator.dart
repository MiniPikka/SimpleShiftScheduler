import '../models/calendar_day_info.dart';
import '../models/shift_type.dart';
import 'shift_calculator.dart';

const int calendarGridDays = 42;

/// 生成 7×7 月历数据 — 对应 Android 版 generateMonthCalendarDays()
List<CalendarDayInfo> generateMonthCalendarDays(
  int year,
  int month, {
  int firstDayOfWeek = DateTime.sunday, // 1=Mon..7=Sun in Dart
  int teamPhaseOffset = 0,
  List<ShiftType>? customCycle,
  DateTime? referenceDate,
}) {
  final firstDay = DateTime(year, month, 1);
  // Dart: DateTime.sunday=7, so we adjust offset calculation
  final dow = firstDay.weekday; // 1=Mon..7=Sun
  final leadingDays = (dow - (firstDayOfWeek == DateTime.sunday ? 7 : 1) + 7) % 7;
  final gridStartDate = firstDay.subtract(Duration(days: leadingDays));

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
