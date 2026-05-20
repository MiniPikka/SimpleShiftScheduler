import 'package:flutter_test/flutter_test.dart';
import 'package:scheduler_cp/domain/models/shift_type.dart';
import 'package:scheduler_cp/domain/models/shift_cycle_config.dart';
import 'package:scheduler_cp/domain/models/salary_config.dart';
import 'package:scheduler_cp/domain/algorithms/salary_calculator.dart';

void main() {
  final refDate = ShiftCycleConfig.referenceDate;

  group('countAllShiftTypesInMonth', () {
    test('total equals days in month', () {
      final counts = countAllShiftTypesInMonth(2026, 5,
          referenceDate: refDate);
      final total = counts.values.fold<int>(0, (a, b) => a + b);
      expect(total, 31);
    });

    test('all 5 shift types present', () {
      final counts = countAllShiftTypesInMonth(2026, 5,
          referenceDate: refDate);
      expect(counts.length, 5);
      for (final type in ShiftType.values) {
        expect(counts.containsKey(type), true);
      }
    });
  });

  group('calculateSalaryBreakdown', () {
    test('zero config produces zero total', () {
      final config = SalaryConfig();
      final counts = {
        ShiftType.MORNING: 8,
        ShiftType.AFTERNOON: 7,
        ShiftType.NIGHT: 7,
        ShiftType.REST: 8,
        ShiftType.STUDY: 1,
      };
      final breakdown =
          calculateSalaryBreakdown(config, counts, 2026, 5);
      expect(breakdown.shiftPremiumTotal, 0.0);
    });

    test('correctly computes total with premiums', () {
      final config = SalaryConfig(shiftPremiums: {
        ShiftType.MORNING: 0.0,
        ShiftType.AFTERNOON: 50.0,
        ShiftType.NIGHT: 200.0,
        ShiftType.STUDY: 0.0,
      });
      final counts = {
        ShiftType.MORNING: 8,
        ShiftType.AFTERNOON: 7,
        ShiftType.NIGHT: 7,
        ShiftType.REST: 8,
        ShiftType.STUDY: 1,
      };
      final breakdown =
          calculateSalaryBreakdown(config, counts, 2026, 5);
      // 7*50 + 7*200 = 350 + 1400 = 1750
      expect(breakdown.shiftPremiumTotal, 1750.0);
    });
  });

  group('simulateExtraShifts', () {
    test('adds extra shifts correctly', () {
      final config = SalaryConfig(shiftPremiums: {
        ShiftType.NIGHT: 200.0,
      });
      final counts = {
        ShiftType.MORNING: 8,
        ShiftType.AFTERNOON: 7,
        ShiftType.NIGHT: 7,
        ShiftType.REST: 8,
        ShiftType.STUDY: 1,
      };
      final current =
          calculateSalaryBreakdown(config, counts, 2026, 5);
      final simulated = simulateExtraShifts(
          current, 2, ShiftType.NIGHT, config);
      expect(simulated.shiftPremiumTotal,
          current.shiftPremiumTotal + 400.0);
      expect(simulated.shiftCounts[ShiftType.NIGHT], 9);
    });
  });
}
