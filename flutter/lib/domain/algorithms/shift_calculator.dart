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

/// 获取指定日期的班次类型 — 优先走 Rust FFI，失败回退纯 Dart。
ShiftType getShiftTypeForDate(
  DateTime date, {
  int teamPhaseOffset = 0,
  List<ShiftType>? customCycle,
  DateTime? referenceDate,
}) {
  // Try Rust FFI for default cycle
  if (customCycle == null || customCycle.length == ShiftCycleConfig.cycleLength) {
    final refDate = referenceDate ?? ShiftCycleConfig.referenceDate;
    final teamId = (teamPhaseOffset ~/ teamPhaseStepFor()) + 1;
    final result = ffiGetShiftTypeForDate(
      date: date,
      teamId: teamId,
      cycleLength: customCycle?.length ?? 0,
      referenceDate: refDate,
    );
    if (result != null) {
      return parseShiftType(result['shift_type'] as String);
    }
  }

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
        shiftType: parseShiftType(result['shift_type'] as String),
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

/// 交接班查询结果 — 班组及交接时刻对方所在的班次类型。
///
/// 班次类型必须取交接时刻的班次，而非查询日当天的班次：
/// 例如 7-19 夜班（7-18 晚 22:00 上岗）的前序班组二值在 7-19 当天是休班，
/// 但交接时他在上 7-18 的中班。
typedef ShiftHandover = ({
  int predTeam,
  ShiftType predShift,
  int succTeam,
  ShiftType succShift,
});

/// 计算交接班关系 — 基于班次类型而非班组编号。
///
/// 交接顺序：夜 → 早 → 中 → 夜
/// - 如果你是早班：你接夜班的班，中班接你的班
/// - 如果你是中班：你接早班的班，夜班接你的班
/// - 如果你是夜班：你接中班的班，早班接你的班
/// - 如果你是休/学：不上班，没有交接
///
/// 跨天约定（与夜班提醒一致）：班次按结束日标记。夜班（前一晚 ~22:00 上岗、
/// 当天早上 8 点下班）的 中→夜 交接发生在前一个日历日的晚上：
/// - 夜班的前序（中班）查 `date - 1`
/// - 中班的后继（夜班）查 `date + 1`
/// - 早班两次交接都在同一天内，不受影响
///
/// 返回 [ShiftHandover] 或 `null`（休息/学习日）。
ShiftHandover? findShiftHandover({
  required DateTime date,
  required int teamId,
  List<ShiftType>? customCycle,
  DateTime? referenceDate,
}) {
  final phaseOffset = teamPhaseOffsetFor(teamId, customCycle: customCycle);
  final myShift = getShiftTypeForDate(date,
      teamPhaseOffset: phaseOffset,
      customCycle: customCycle,
      referenceDate: referenceDate);

  if (myShift.isRest) return null; // 不上班，不交接

  // 交接顺序：夜 → 早 → 中 → 夜
  final predShift = switch (myShift) {
    ShiftType.MORNING => ShiftType.NIGHT,
    ShiftType.AFTERNOON => ShiftType.MORNING,
    ShiftType.NIGHT => ShiftType.AFTERNOON,
    _ => throw StateError('unreachable'),
  };
  final succShift = switch (myShift) {
    ShiftType.MORNING => ShiftType.AFTERNOON,
    ShiftType.AFTERNOON => ShiftType.NIGHT,
    ShiftType.NIGHT => ShiftType.MORNING,
    _ => throw StateError('unreachable'),
  };

  // 跨天修正：中→夜 交接发生在我（或后继）上岗的前一晚
  final predDate = myShift == ShiftType.NIGHT
      ? date.subtract(const Duration(days: 1))
      : date;
  final succDate = succShift == ShiftType.NIGHT
      ? date.add(const Duration(days: 1))
      : date;

  // 遍历所有班组，找到交接日当天上前序/后继班次类型的班组
  int? predTeam, succTeam;
  for (var t = 1; t <= Team.totalTeams; t++) {
    if (t == teamId) continue;
    final offset = teamPhaseOffsetFor(t, customCycle: customCycle);
    if (predTeam == null &&
        getShiftTypeForDate(predDate,
            teamPhaseOffset: offset,
            customCycle: customCycle,
            referenceDate: referenceDate) ==
        predShift) {
      predTeam = t;
    }
    if (succTeam == null &&
        getShiftTypeForDate(succDate,
            teamPhaseOffset: offset,
            customCycle: customCycle,
            referenceDate: referenceDate) ==
        succShift) {
      succTeam = t;
    }
    if (predTeam != null && succTeam != null) break;
  }

  if (predTeam != null && succTeam != null) {
    return (
      predTeam: predTeam,
      predShift: predShift,
      succTeam: succTeam,
      succShift: succShift,
    );
  }
  return null;
}

/// 循环顺序中当前班组的后继班组 — 对应 Rust successor_team_id()。
int successorTeamId(int teamId, [int totalTeams = Team.totalTeams]) {
  return (teamId % totalTeams) + 1;
}

/// 循环顺序中当前班组的前序班组 — 对应 Rust predecessor_team_id()。
int predecessorTeamId(int teamId, [int totalTeams = Team.totalTeams]) {
  return (teamId + totalTeams - 2) % totalTeams + 1;
}

ShiftType parseShiftType(String s) {
  switch (s) {
    case 'morning': return ShiftType.MORNING;
    case 'afternoon': return ShiftType.AFTERNOON;
    case 'rest': return ShiftType.REST;
    case 'night': return ShiftType.NIGHT;
    case 'study': return ShiftType.STUDY;
    default: return ShiftType.REST;
  }
}
