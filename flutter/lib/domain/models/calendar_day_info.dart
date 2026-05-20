import 'shift_type.dart';

/// 日历日信息 — 对应 Android 版 CalendarDayInfo.kt
class CalendarDayInfo {
  final DateTime date;
  final ShiftType shiftType;
  final bool isCurrentMonth;

  const CalendarDayInfo({
    required this.date,
    required this.shiftType,
    required this.isCurrentMonth,
  });
}
