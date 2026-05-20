import 'shift_type.dart';
import 'shift_cycle_config.dart';
import 'team.dart';

/// 运行时周期配置 — 对应 Android 版 RuntimeShiftSettings.kt
class RuntimeShiftSettings {
  final int cycleLength;
  final List<ShiftType> shiftCycle;
  final int defaultTeamId;
  final DateTime referenceDate;

  RuntimeShiftSettings({
    this.cycleLength = ShiftCycleConfig.cycleLength,
    this.shiftCycle = ShiftCycleConfig.shiftCycle,
    this.defaultTeamId = 1,
    DateTime? referenceDate,
  }) : referenceDate = referenceDate ?? ShiftCycleConfig.referenceDate;

  bool get isValid =>
      cycleLength >= 1 &&
      cycleLength <= 100 &&
      shiftCycle.length == cycleLength &&
      shiftCycle.every((t) => ShiftType.values.contains(t)) &&
      defaultTeamId >= 1 &&
      defaultTeamId <= Team.totalTeams;

  int get teamPhaseStep => cycleLength ~/ Team.totalTeams;
}
