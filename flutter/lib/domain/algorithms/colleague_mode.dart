import '../models/common_rest_result.dart';
import '../models/shift_type.dart';
import '../models/shift_cycle_config.dart';
import '../bridge/ffi_bridge.dart';
import 'shift_calculator.dart';

/// 查找两人共同休息日 — 优先走 Rust FFI
CommonRestResult findCommonRestDays({
  required int teamAId,
  required int teamBId,
  DateTime? today,
  int daysToAnalyze = 365,
  List<ShiftType>? customCycle,
  DateTime? referenceDate,
  String Function(int)? teamNameResolver,
}) {
  final t = today ?? DateTime.now();
  final resolver = teamNameResolver ?? (int id) => 'Shift ${String.fromCharCode(64 + id)}';
  final teamAName = resolver(teamAId);
  final teamBName = resolver(teamBId);

  // Try Rust FFI
  if (customCycle == null || customCycle.length == ShiftCycleConfig.cycleLength) {
    final result = ffiGetCommonRestDays(
      teamA: teamAId, teamB: teamBId, today: t,
      daysToAnalyze: daysToAnalyze,
      referenceDate: referenceDate,
    );
    if (result != null) {
      final dates = (result['common_rest_dates'] as List?)
          ?.map((d) => DateTime.parse(d as String))
          .toList() ?? [];
      final next = result['next_common_rest'] as String?;
      return CommonRestResult(
        teamAName: teamAName,
        teamBName: teamBName,
        nextCommonRestDate: next != null ? DateTime.parse(next) : null,
        daysUntilNext: result['days_until_next'] as int?,
        commonRestDates: dates,
        totalCount: dates.length,
        countIn30Days: result['count_30_days'] as int? ?? 0,
        countIn60Days: result['count_60_days'] as int? ?? 0,
      );
    }
  }
  final offsetA = teamPhaseOffsetFor(teamAId, customCycle: customCycle);
  final offsetB = teamPhaseOffsetFor(teamBId, customCycle: customCycle);

  final commonDates = <DateTime>[];
  for (int i = 0; i < daysToAnalyze; i++) {
    final date = t.add(Duration(days: i));
    final shiftA = getShiftTypeForDate(date,
        teamPhaseOffset: offsetA,
        customCycle: customCycle,
        referenceDate: referenceDate);
    final shiftB = getShiftTypeForDate(date,
        teamPhaseOffset: offsetB,
        customCycle: customCycle,
        referenceDate: referenceDate);
    final isRestA = shiftA == ShiftType.REST || shiftA == ShiftType.STUDY;
    final isRestB = shiftB == ShiftType.REST || shiftB == ShiftType.STUDY;
    if (isRestA && isRestB) {
      commonDates.add(date);
    }
  }

  final next = commonDates.isNotEmpty ? commonDates.first : null;
  final daysUntil = next?.difference(t).inDays;
  final count30 =
      commonDates.where((d) => d.difference(t).inDays < 30).length;
  final count60 =
      commonDates.where((d) => d.difference(t).inDays < 60).length;

  return CommonRestResult(
    teamAName: teamAName,
    teamBName: teamBName,
    nextCommonRestDate: next,
    daysUntilNext: daysUntil,
    commonRestDates: commonDates,
    totalCount: commonDates.length,
    countIn30Days: count30,
    countIn60Days: count60,
  );
}
