import '../models/common_rest_result.dart';
import '../models/shift_type.dart';
import 'shift_calculator.dart';

/// 查找两人共同休息日 — 对应 Android 版 findCommonRestDays()
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
  final offsetA = teamPhaseOffsetFor(teamAId, customCycle: customCycle);
  final offsetB = teamPhaseOffsetFor(teamBId, customCycle: customCycle);
  final resolver =
      teamNameResolver ?? (int id) => 'Shift ${String.fromCharCode(64 + id)}';
  final teamAName = resolver(teamAId);
  final teamBName = resolver(teamBId);

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
