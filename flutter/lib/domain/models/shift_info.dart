import 'shift_type.dart';

/// 班次查询结果 — 对应 Android 版 ShiftInfo.kt
class ShiftInfo {
  final DateTime date;
  final int dayOfCycle;  // 1..cycleLength
  final ShiftType shiftType;

  const ShiftInfo({
    required this.date,
    required this.dayOfCycle,
    required this.shiftType,
  });
}
