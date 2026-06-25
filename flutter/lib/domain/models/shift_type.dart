/// 班次类型枚举 — 对应 Android 版 ShiftType.kt
enum ShiftType {
  MORNING,
  AFTERNOON,
  REST,
  NIGHT,
  STUDY;

  /// Whether this is a working shift (Morning, Afternoon, or Night).
  bool get isWork =>
      this == MORNING || this == AFTERNOON || this == NIGHT;

  /// Whether this counts as rest (Rest or Study).
  bool get isRest => this == REST || this == STUDY;
}
