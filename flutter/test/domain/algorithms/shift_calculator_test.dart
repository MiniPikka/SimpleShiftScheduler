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
}
