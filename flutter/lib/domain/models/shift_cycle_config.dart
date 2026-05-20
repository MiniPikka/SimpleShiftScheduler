import 'shift_type.dart';

/// 倒班周期配置常量 — 对应 Android 版 ShiftCycleConfig.kt
class ShiftCycleConfig {
  static const cycleLength = 42;
  // DateTime cannot be const in Dart, so we use number values
  static final referenceDate = DateTime(2025, 12, 15);

  static const shiftCycle = <ShiftType>[
    ShiftType.MORNING, ShiftType.MORNING,  // day 1-2
    ShiftType.AFTERNOON, ShiftType.AFTERNOON,  // day 3-4
    ShiftType.REST,  // day 5
    ShiftType.NIGHT, ShiftType.NIGHT,  // day 6-7
    ShiftType.REST, ShiftType.REST,  // day 8-9
    ShiftType.MORNING, ShiftType.MORNING,  // day 10-11
    ShiftType.AFTERNOON, ShiftType.AFTERNOON,  // day 12-13
    ShiftType.REST,  // day 14
    ShiftType.NIGHT,  // day 15
    ShiftType.REST, ShiftType.REST, ShiftType.REST,  // day 16-18
    ShiftType.MORNING, ShiftType.MORNING,  // day 19-20
    ShiftType.AFTERNOON,  // day 21
    ShiftType.REST,  // day 22
    ShiftType.NIGHT, ShiftType.NIGHT,  // day 23-24
    ShiftType.REST, ShiftType.REST, ShiftType.REST,  // day 25-27
    ShiftType.MORNING,  // day 28
    ShiftType.AFTERNOON, ShiftType.AFTERNOON,  // day 29-30
    ShiftType.REST,  // day 31
    ShiftType.NIGHT, ShiftType.NIGHT,  // day 32-33
    ShiftType.REST, ShiftType.REST,  // day 34-35
    ShiftType.STUDY, ShiftType.STUDY, ShiftType.STUDY,  // day 36-38
    ShiftType.STUDY, ShiftType.STUDY,  // day 39-40
    ShiftType.REST, ShiftType.REST,  // day 41-42
  ];
}
