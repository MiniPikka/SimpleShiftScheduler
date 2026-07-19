import 'package:flutter_test/flutter_test.dart';
import 'package:scheduler_cp/domain/models/shift_type.dart';
import 'package:scheduler_cp/domain/models/shift_cycle_config.dart';
import 'package:scheduler_cp/domain/algorithms/shift_calculator.dart';

void main() {
  final refDate = ShiftCycleConfig.referenceDate; // 2025-12-15

  group('calculateDayOffset', () {
    test('reference date = 0', () {
      expect(calculateDayOffset(refDate, referenceDate: refDate), 0);
    });
    test('reference date + 1 day = 1', () {
      expect(calculateDayOffset(refDate.add(const Duration(days: 1)), referenceDate: refDate), 1);
    });
    test('reference date - 1 day = -1', () {
      expect(calculateDayOffset(refDate.subtract(const Duration(days: 1)), referenceDate: refDate), -1);
    });
    test('42 days later = 42', () {
      expect(calculateDayOffset(refDate.add(const Duration(days: 42)), referenceDate: refDate), 42);
    });
  });

  group('normalizeCycleIndex', () {
    test('0 → 0', () {
      expect(normalizeCycleIndex(0, cycleLength: 42), 0);
    });
    test('1 → 1', () {
      expect(normalizeCycleIndex(1, cycleLength: 42), 1);
    });
    test('41 → 41', () {
      expect(normalizeCycleIndex(41, cycleLength: 42), 41);
    });
    test('42 → 0 (wrap)', () {
      expect(normalizeCycleIndex(42, cycleLength: 42), 0);
    });
    test('-1 → 41 (negative wrap)', () {
      expect(normalizeCycleIndex(-1, cycleLength: 42), 41);
    });
    test('custom cycle length 7', () {
      expect(normalizeCycleIndex(7, cycleLength: 7), 0);
      expect(normalizeCycleIndex(8, cycleLength: 7), 1);
    });
  });

  group('getShiftTypeForDate', () {
    test('reference date is MORNING (day 1 of cycle)', () {
      expect(getShiftTypeForDate(refDate, referenceDate: refDate), ShiftType.MORNING);
    });
    test('reference date + 4 is REST (day 5)', () {
      expect(getShiftTypeForDate(refDate.add(const Duration(days: 4)), referenceDate: refDate), ShiftType.REST);
    });
    test('reference date + 42 wraps back to MORNING', () {
      expect(getShiftTypeForDate(refDate.add(const Duration(days: 42)), referenceDate: refDate), ShiftType.MORNING);
    });
    test('custom cycle works', () {
      final custom = [ShiftType.NIGHT, ShiftType.REST, ShiftType.MORNING];
      expect(
        getShiftTypeForDate(refDate, customCycle: custom, referenceDate: refDate),
        ShiftType.NIGHT,
      );
    });
  });

  group('getShiftInfo', () {
    test('reference date → dayOfCycle=1, MORNING', () {
      final info = getShiftInfo(refDate, referenceDate: refDate);
      expect(info.dayOfCycle, 1);
      expect(info.shiftType, ShiftType.MORNING);
    });
    test('reference date + 41 → dayOfCycle=42, REST', () {
      final info = getShiftInfo(refDate.add(const Duration(days: 41)), referenceDate: refDate);
      expect(info.dayOfCycle, 42);
      expect(info.shiftType, ShiftType.REST);
    });
    test('custom cycle → dayOfCycle in custom range', () {
      final custom = [ShiftType.NIGHT, ShiftType.REST, ShiftType.MORNING];
      final info = getShiftInfo(refDate, customCycle: custom, referenceDate: refDate);
      expect(info.dayOfCycle, 1);
      expect(info.shiftType, ShiftType.NIGHT);
    });
  });

  group('teamPhaseOffset', () {
    test('team 1 → offset 0', () {
      expect(teamPhaseOffsetFor(1), 0);
    });
    test('team 2 → offset 7', () {
      expect(teamPhaseOffsetFor(2), 7);
    });
    test('team 6 → offset 35', () {
      expect(teamPhaseOffsetFor(6), 35);
    });
    test('teamPhaseStepFor default = 7', () {
      expect(teamPhaseStepFor(), 7);
    });
    test('teamPhaseStepFor custom cycle 30 = 5', () {
      final custom = List.filled(30, ShiftType.MORNING);
      expect(teamPhaseStepFor(customCycle: custom), 5);
    });
  });

  // 已对照 2026 年 7 月实际排班核实（默认周期）：
  //   07-18: 一值夜 二值中 三值早 四值休
  //   07-19: 一值夜 二值休 三值中 四值早
  //   07-20: 一值休 二值夜 三值休 四值中
  // 标记为 07-19 的夜班实际为 07-18 晚 22:00 → 07-19 早 08:00。
  group('findShiftHandover', () {
    final d719 = DateTime(2026, 7, 19);

    test('夜班前序取前一晚的中班班组', () {
      // 一值 7-19 夜班：7-18 22:00 上岗时接的是 7-18 中班（二值），
      // 不是 7-19 中班（三值）
      final ho = findShiftHandover(date: d719, teamId: 1)!;
      expect(ho.predTeam, 2);
      expect(ho.predShift, ShiftType.AFTERNOON);
      expect(ho.succTeam, 4); // 7-19 早 08:00 四值接班
      expect(ho.succShift, ShiftType.MORNING);
    });

    test('中班后继取次日的夜班班组', () {
      // 三值 7-19 中班：22:00 下班时来接的是 7-20 夜班（二值），
      // 不是 7-19 夜班（一值，早已下班回家）
      final ho = findShiftHandover(date: d719, teamId: 3)!;
      expect(ho.predTeam, 4);
      expect(ho.predShift, ShiftType.MORNING);
      expect(ho.succTeam, 2);
      expect(ho.succShift, ShiftType.NIGHT);
    });

    test('早班交接在同一天内', () {
      final ho = findShiftHandover(date: d719, teamId: 4)!;
      expect(ho.predTeam, 1);
      expect(ho.predShift, ShiftType.NIGHT);
      expect(ho.succTeam, 3);
      expect(ho.succShift, ShiftType.AFTERNOON);
    });

    test('休息日无交接', () {
      expect(findShiftHandover(date: d719, teamId: 2), isNull);
    });

    test('中→夜交接双方信息对称', () {
      // 三值 7-19 中班的后继是二值；二值 7-20 夜班的前序必须是三值
      final d720 = DateTime(2026, 7, 20);
      final hoA = findShiftHandover(date: d719, teamId: 3)!;
      final hoB = findShiftHandover(date: d720, teamId: hoA.succTeam)!;
      expect(hoB.predTeam, 3);
      expect(hoB.predShift, ShiftType.AFTERNOON);
    });
  });
}
