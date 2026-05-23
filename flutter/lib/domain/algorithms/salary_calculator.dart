import '../models/salary_breakdown.dart';
import '../models/salary_config.dart';
import '../models/shift_type.dart';
import '../models/shift_cycle_config.dart';
import '../bridge/ffi_bridge.dart';
import 'shift_calculator.dart';

/// 统计当月所有班次类型出现次数 — 优先走 Rust FFI，失败回退纯 Dart。
Map<ShiftType, int> countAllShiftTypesInMonth(
  int year,
  int month, {
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
      return {
        ShiftType.MORNING: stats['morning'] as int? ?? 0,
        ShiftType.AFTERNOON: stats['afternoon'] as int? ?? 0,
        ShiftType.REST: stats['rest'] as int? ?? 0,
        ShiftType.NIGHT: stats['night'] as int? ?? 0,
        ShiftType.STUDY: stats['study'] as int? ?? 0,
      };
    }
  }

  // Fallback to pure Dart
  final counts = <ShiftType, int>{};
  for (final type in ShiftType.values) {
    counts[type] = 0;
  }
  final daysInMonth = DateTime(year, month + 1, 0).day;
  for (int day = 1; day <= daysInMonth; day++) {
    final date = DateTime(year, month, day);
    final shiftType = getShiftTypeForDate(date,
        teamPhaseOffset: teamPhaseOffset,
        customCycle: customCycle,
        referenceDate: referenceDate);
    counts[shiftType] = (counts[shiftType] ?? 0) + 1;
  }
  return counts;
}

/// 计算倒班津贴明细 — 对应 Android 版 calculateSalaryBreakdown()
SalaryBreakdown calculateSalaryBreakdown(
    SalaryConfig config, Map<ShiftType, int> shiftCounts, int year, int month) {
  double total = 0;
  for (final type in ShiftType.values) {
    final premium = config.shiftPremiums[type] ?? 0.0;
    final count = shiftCounts[type] ?? 0;
    total += premium * count;
  }
  return SalaryBreakdown(
    year: year,
    month: month,
    shiftCounts: Map.from(shiftCounts),
    shiftPremiumTotal: total,
  );
}

/// 假设分析：多上 X 天某班次 — 对应 Android 版 simulateExtraShifts()
SalaryBreakdown simulateExtraShifts(
    SalaryBreakdown current, int extraCount, ShiftType extraShiftType,
    SalaryConfig config) {
  final extraAmount = (config.shiftPremiums[extraShiftType] ?? 0.0) * extraCount;
  final newCounts = Map<ShiftType, int>.from(current.shiftCounts);
  newCounts[extraShiftType] = (newCounts[extraShiftType] ?? 0) + extraCount;
  return SalaryBreakdown(
    year: current.year,
    month: current.month,
    shiftCounts: newCounts,
    shiftPremiumTotal: current.shiftPremiumTotal + extraAmount,
  );
}
