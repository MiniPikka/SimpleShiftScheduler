/// 月度统计 — 对应 Android 版 MonthlyStats.kt
class MonthlyStats {
  final int morningCount;
  final int afternoonCount;
  final int restCount;
  final int nightCount;
  final int studyCount;

  const MonthlyStats({
    this.morningCount = 0,
    this.afternoonCount = 0,
    this.restCount = 0,
    this.nightCount = 0,
    this.studyCount = 0,
  });
}
