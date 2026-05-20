/// 共同休息结果 — 对应 Android 版 CommonRestResult.kt
class CommonRestResult {
  final String teamAName;
  final String teamBName;
  final DateTime? nextCommonRestDate;
  final int? daysUntilNext;
  final List<DateTime> commonRestDates;
  final int totalCount;
  final int countIn30Days;
  final int countIn60Days;

  const CommonRestResult({
    required this.teamAName,
    required this.teamBName,
    this.nextCommonRestDate,
    this.daysUntilNext,
    required this.commonRestDates,
    required this.totalCount,
    required this.countIn30Days,
    required this.countIn60Days,
  });
}
