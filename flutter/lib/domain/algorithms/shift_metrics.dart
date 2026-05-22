import '../models/shift_cycle_config.dart';
import '../models/shift_type.dart';
import '../bridge/ffi_bridge.dart';
import 'shift_calculator.dart';

/// 统计指定月份内某班次类型的出现天数
int countShiftTypeInMonth(
  int year,
  int month,
  ShiftType shiftType, {
  int teamPhaseOffset = 0,
  List<ShiftType>? customCycle,
  DateTime? referenceDate,
}) {
  // Try Rust FFI for default cycle
  if (customCycle == null || customCycle.length == ShiftCycleConfig.cycleLength) {
    final teamId = (teamPhaseOffset ~/ teamPhaseStepFor()) + 1;
    final stats = ffiGetMonthlyStats(
      year: year, month: month, teamId: teamId,
      referenceDate: referenceDate,
    );
    if (stats != null) {
      final key = _shiftTypeKey(shiftType);
      return stats[key] as int? ?? _dartCountInMonth(
          year, month, shiftType, teamPhaseOffset, customCycle, referenceDate);
    }
  }
  return _dartCountInMonth(year, month, shiftType, teamPhaseOffset, customCycle, referenceDate);
}

int _dartCountInMonth(int year, int month, ShiftType shiftType,
    int teamPhaseOffset, List<ShiftType>? customCycle, DateTime? referenceDate) {
  final daysInMonth = DateTime(year, month + 1, 0).day;
  int count = 0;
  for (int day = 1; day <= daysInMonth; day++) {
    final date = DateTime(year, month, day);
    if (getShiftTypeForDate(date, teamPhaseOffset: teamPhaseOffset,
        customCycle: customCycle, referenceDate: referenceDate) == shiftType) {
      count++;
    }
  }
  return count;
}

/// 统计月份内上班天数（非休且非学）
int countWorkDaysInMonth(
  int year,
  int month, {
  int teamPhaseOffset = 0,
  List<ShiftType>? customCycle,
  DateTime? referenceDate,
}) {
  if (customCycle == null || customCycle.length == ShiftCycleConfig.cycleLength) {
    final teamId = (teamPhaseOffset ~/ teamPhaseStepFor()) + 1;
    final stats = ffiGetMonthlyStats(
      year: year, month: month, teamId: teamId,
      referenceDate: referenceDate,
    );
    if (stats != null) {
      return stats['work_days'] as int? ??
          _dartCountWork(year, month, teamPhaseOffset, customCycle, referenceDate);
    }
  }
  return _dartCountWork(year, month, teamPhaseOffset, customCycle, referenceDate);
}

int _dartCountWork(int year, int month, int teamPhaseOffset,
    List<ShiftType>? customCycle, DateTime? referenceDate) {
  final daysInMonth = DateTime(year, month + 1, 0).day;
  int count = 0;
  for (int day = 1; day <= daysInMonth; day++) {
    final date = DateTime(year, month, day);
    final st = getShiftTypeForDate(date, teamPhaseOffset: teamPhaseOffset,
        customCycle: customCycle, referenceDate: referenceDate);
    if (st != ShiftType.REST && st != ShiftType.STUDY) count++;
  }
  return count;
}

/// 从今天往前数连续上班天数
int consecutiveWorkDays(
  DateTime today, {
  int teamPhaseOffset = 0,
  List<ShiftType>? customCycle,
  DateTime? referenceDate,
}) {
  if (customCycle == null || customCycle.length == ShiftCycleConfig.cycleLength) {
    final teamId = (teamPhaseOffset ~/ teamPhaseStepFor()) + 1;
    final result = ffiGetConsecutiveWorkDays(
      date: today, teamId: teamId,
      referenceDate: referenceDate,
    );
    if (result != null) {
      return result['consecutive_work_days'] as int? ??
          _dartConsecutive(today, teamPhaseOffset, customCycle, referenceDate);
    }
  }
  return _dartConsecutive(today, teamPhaseOffset, customCycle, referenceDate);
}

int _dartConsecutive(DateTime today, int teamPhaseOffset,
    List<ShiftType>? customCycle, DateTime? referenceDate) {
  int count = 0;
  var date = today;
  while (true) {
    final st = getShiftTypeForDate(date, teamPhaseOffset: teamPhaseOffset,
        customCycle: customCycle, referenceDate: referenceDate);
    if (st == ShiftType.REST || st == ShiftType.STUDY) break;
    count++;
    date = date.subtract(const Duration(days: 1));
  }
  return count;
}

/// 距下一个休息日的天数（不含今天）
int daysUntilNextRest(
  DateTime today, {
  int teamPhaseOffset = 0,
  List<ShiftType>? customCycle,
  DateTime? referenceDate,
}) {
  if (customCycle == null || customCycle.length == ShiftCycleConfig.cycleLength) {
    final teamId = (teamPhaseOffset ~/ teamPhaseStepFor()) + 1;
    final result = ffiGetDaysUntilRest(
      date: today, teamId: teamId,
      referenceDate: referenceDate,
    );
    if (result != null) {
      return result['days_until'] as int? ??
          _dartDaysUntilRest(today, teamPhaseOffset, customCycle, referenceDate);
    }
  }
  return _dartDaysUntilRest(today, teamPhaseOffset, customCycle, referenceDate);
}

int _dartDaysUntilRest(DateTime today, int teamPhaseOffset,
    List<ShiftType>? customCycle, DateTime? referenceDate) {
  int days = 0;
  var date = today.add(const Duration(days: 1));
  final maxSearch = (customCycle?.length ?? ShiftCycleConfig.cycleLength) + 1;
  while (days < maxSearch) {
    final st = getShiftTypeForDate(date, teamPhaseOffset: teamPhaseOffset,
        customCycle: customCycle, referenceDate: referenceDate);
    if (st == ShiftType.REST) return days;
    days++;
    date = date.add(const Duration(days: 1));
  }
  return 0;
}

String _shiftTypeKey(ShiftType t) {
  switch (t) {
    case ShiftType.MORNING: return 'morning';
    case ShiftType.AFTERNOON: return 'afternoon';
    case ShiftType.REST: return 'rest';
    case ShiftType.NIGHT: return 'night';
    case ShiftType.STUDY: return 'study';
  }
}
