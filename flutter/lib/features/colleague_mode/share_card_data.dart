/// 分享卡片数据模型 — 对应 Android 版 ShareCardData
///
/// 纯数据类，不依赖任何 UI/ViewModel/Context。可在后台线程安全构建。
class ShareCardData {
  final String teamAName;
  final String teamBName;
  final String nextCommonRestDate; // "5月28日"
  final String nextCommonRestWeekday; // "星期三"
  final int daysUntilNext;
  final int countIn30Days;
  final int countIn60Days;
  final List<String> commonRestDateItems; // 最多 12 项，每项 "5月28日 星期三"
  final String dateRange; // "2026/05/20 — 12/31"

  const ShareCardData({
    required this.teamAName,
    required this.teamBName,
    required this.nextCommonRestDate,
    required this.nextCommonRestWeekday,
    required this.daysUntilNext,
    required this.countIn30Days,
    required this.countIn60Days,
    required this.commonRestDateItems,
    required this.dateRange,
  });
}
