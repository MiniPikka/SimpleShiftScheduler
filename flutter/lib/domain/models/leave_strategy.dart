/// 请假策略 — 对应 Android 版 LeaveStrategy.kt
class LeaveStrategy {
  final int leaveDays;
  final int totalBreakDays;
  final List<DateTime> leaveDates;
  final DateTime breakStart;
  final DateTime breakEnd;
  final int holidayOverlap;
  final int weekendOverlap;
  final List<String> overlappingHolidayNames;
  final double efficiency;
  final double score;

  const LeaveStrategy({
    required this.leaveDays,
    required this.totalBreakDays,
    required this.leaveDates,
    required this.breakStart,
    required this.breakEnd,
    required this.holidayOverlap,
    required this.weekendOverlap,
    required this.overlappingHolidayNames,
    required this.efficiency,
    required this.score,
  });
}
