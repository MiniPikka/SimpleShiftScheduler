import '../models/shift_type.dart';
import '../models/shift_cycle_config.dart';
import '../models/shift_info.dart';
import '../models/team.dart';

/// 计算日期偏移天数 — 对应 Android 版 calculateDayOffset()
int calculateDayOffset(DateTime date, {DateTime? referenceDate}) {
  final ref = referenceDate ?? ShiftCycleConfig.referenceDate;
  return date.difference(ref).inDays;
}

/// 归一化周期索引到 0..cycleLength-1 — 对应 Android 版 normalizeCycleIndex()
int normalizeCycleIndex(int offsetDays, {int? cycleLength}) {
  final len = cycleLength ?? ShiftCycleConfig.cycleLength;
  return (offsetDays % len + len) % len;
}

/// 获取指定日期的班次类型 — 对应 Android 版 getShiftTypeForDate()
ShiftType getShiftTypeForDate(
  DateTime date, {
  int teamPhaseOffset = 0,
  List<ShiftType>? customCycle,
  DateTime? referenceDate,
}) {
  final cycle = customCycle ?? ShiftCycleConfig.shiftCycle;
  final offsetDays =
      calculateDayOffset(date, referenceDate: referenceDate) + teamPhaseOffset;
  final cycleIndex = normalizeCycleIndex(offsetDays, cycleLength: cycle.length);
  return cycle[cycleIndex];
}

/// 获取指定日期的完整班次信息 — 对应 Android 版 getShiftInfo()
ShiftInfo getShiftInfo(
  DateTime date, {
  int teamPhaseOffset = 0,
  List<ShiftType>? customCycle,
  DateTime? referenceDate,
}) {
  final cycle = customCycle ?? ShiftCycleConfig.shiftCycle;
  final offsetDays =
      calculateDayOffset(date, referenceDate: referenceDate) + teamPhaseOffset;
  final cycleIndex = normalizeCycleIndex(offsetDays, cycleLength: cycle.length);
  return ShiftInfo(
    date: date,
    dayOfCycle: cycleIndex + 1,
    shiftType: cycle[cycleIndex],
  );
}

/// 计算班组相位偏移步长 — 对应 Android 版 teamPhaseStepFor()
int teamPhaseStepFor({List<ShiftType>? customCycle}) {
  final totalDays = customCycle?.length ?? ShiftCycleConfig.cycleLength;
  return totalDays ~/ Team.totalTeams;
}

/// 计算指定班组的相位偏移 — 对应 Android 版 teamPhaseOffsetFor()
int teamPhaseOffsetFor(int teamId, {List<ShiftType>? customCycle}) {
  final step = teamPhaseStepFor(customCycle: customCycle);
  return (teamId - 1) * step;
}
