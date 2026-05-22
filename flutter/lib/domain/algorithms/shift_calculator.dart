import '../models/shift_type.dart';
import '../models/shift_cycle_config.dart';
import '../models/shift_info.dart';
import '../models/team.dart';
import '../bridge/ffi_bridge.dart';

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

/// 获取指定日期的完整班次信息 — 优先走 Rust FFI，失败回退纯 Dart。
ShiftInfo getShiftInfo(
  DateTime date, {
  int teamPhaseOffset = 0,
  List<ShiftType>? customCycle,
  DateTime? referenceDate,
}) {
  // Try Rust FFI first
  if (customCycle == null || customCycle.length == ShiftCycleConfig.cycleLength) {
    final refDate = referenceDate ?? ShiftCycleConfig.referenceDate;
    final teamId = (teamPhaseOffset ~/ teamPhaseStepFor()) + 1;
    final result = ffiGetShiftInfo(
      date: date,
      teamId: teamId,
      cycleLength: customCycle?.length ?? 0,
      referenceDate: refDate,
    );
    if (result != null) {
      return ShiftInfo(
        date: date,
        dayOfCycle: result['day_of_cycle'] as int,
        shiftType: _parseShiftType(result['shift_type'] as String),
      );
    }
  }

  // Fallback to pure Dart
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

String _fmt(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

ShiftType _parseShiftType(String s) {
  switch (s) {
    case 'morning': return ShiftType.MORNING;
    case 'afternoon': return ShiftType.AFTERNOON;
    case 'rest': return ShiftType.REST;
    case 'night': return ShiftType.NIGHT;
    case 'study': return ShiftType.STUDY;
    default: return ShiftType.REST;
  }
}
