import '../models/shift_cycle_config.dart';
import '../models/shift_type.dart';
import 'shift_calculator.dart';

/// 统计指定月份内某班次类型的出现天数 — 对应 Android 版 countShiftTypeInMonth()
int countShiftTypeInMonth(
  int year,
  int month,
  ShiftType shiftType, {
  int teamPhaseOffset = 0,
  List<ShiftType>? customCycle,
  DateTime? referenceDate,
}) {
  final daysInMonth = DateTime(year, month + 1, 0).day;
  int count = 0;
  for (int day = 1; day <= daysInMonth; day++) {
    final date = DateTime(year, month, day);
    if (getShiftTypeForDate(date,
            teamPhaseOffset: teamPhaseOffset,
            customCycle: customCycle,
            referenceDate: referenceDate) ==
        shiftType) {
      count++;
    }
  }
  return count;
}

/// 统计月份内上班天数（非休且非学）— 对应 Android 版 countWorkDaysInMonth()
int countWorkDaysInMonth(
  int year,
  int month, {
  int teamPhaseOffset = 0,
  List<ShiftType>? customCycle,
  DateTime? referenceDate,
}) {
  final daysInMonth = DateTime(year, month + 1, 0).day;
  int count = 0;
  for (int day = 1; day <= daysInMonth; day++) {
    final date = DateTime(year, month, day);
    final shiftType = getShiftTypeForDate(date,
        teamPhaseOffset: teamPhaseOffset,
        customCycle: customCycle,
        referenceDate: referenceDate);
    if (shiftType != ShiftType.REST && shiftType != ShiftType.STUDY) {
      count++;
    }
  }
  return count;
}

/// 从今天往前数连续上班天数 — 对应 Android 版 consecutiveWorkDays()
int consecutiveWorkDays(
  DateTime today, {
  int teamPhaseOffset = 0,
  List<ShiftType>? customCycle,
  DateTime? referenceDate,
}) {
  int count = 0;
  var date = today;
  while (true) {
    final shiftType = getShiftTypeForDate(date,
        teamPhaseOffset: teamPhaseOffset,
        customCycle: customCycle,
        referenceDate: referenceDate);
    if (shiftType == ShiftType.REST || shiftType == ShiftType.STUDY) break;
    count++;
    date = date.subtract(const Duration(days: 1));
  }
  return count;
}

/// 距下一个休息日的天数（不含今天）— 对应 Android 版 daysUntilNextRest()
int daysUntilNextRest(
  DateTime today, {
  int teamPhaseOffset = 0,
  List<ShiftType>? customCycle,
  DateTime? referenceDate,
}) {
  int days = 0;
  var date = today.add(const Duration(days: 1));
  final maxSearch =
      (customCycle?.length ?? ShiftCycleConfig.cycleLength) + 1;
  while (days < maxSearch) {
    final shiftType = getShiftTypeForDate(date,
        teamPhaseOffset: teamPhaseOffset,
        customCycle: customCycle,
        referenceDate: referenceDate);
    if (shiftType == ShiftType.REST) return days;
    days++;
    date = date.add(const Duration(days: 1));
  }
  return 0;
}
