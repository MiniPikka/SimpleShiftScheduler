import 'package:flutter_test/flutter_test.dart';
import 'package:scheduler_cp/domain/models/shift_type.dart';
import 'package:scheduler_cp/domain/models/shift_cycle_config.dart';
import 'package:scheduler_cp/domain/algorithms/shift_calculator.dart';
import 'package:scheduler_cp/domain/algorithms/shift_metrics.dart';

void main() {
  final refDate = ShiftCycleConfig.referenceDate; // 2025-12-15

  group('countShiftTypeInMonth', () {
    test('returns non-negative for all shift types', () {
      for (final type in ShiftType.values) {
        final count =
            countShiftTypeInMonth(2026, 5, type, referenceDate: refDate);
        expect(count, isNonNegative);
      }
    });

    test('total counts = days in month', () {
      int total = 0;
      for (final type in ShiftType.values) {
        total +=
            countShiftTypeInMonth(2026, 5, type, referenceDate: refDate);
      }
      expect(total, 31);
    });
  });

  group('countWorkDaysInMonth', () {
    test('work days + rest + study = month total', () {
      final workDays =
          countWorkDaysInMonth(2026, 5, referenceDate: refDate);
      final restDays = countShiftTypeInMonth(2026, 5, ShiftType.REST,
          referenceDate: refDate);
      final studyDays = countShiftTypeInMonth(2026, 5, ShiftType.STUDY,
          referenceDate: refDate);
      expect(workDays + restDays + studyDays, 31);
    });

    test('work days count is within month bounds', () {
      final count = countWorkDaysInMonth(2026, 5, referenceDate: refDate);
      expect(count, isNonNegative);
      expect(count, lessThanOrEqualTo(31));
    });
  });

  group('consecutiveWorkDays', () {
    test('returns 0 if today is REST', () {
      var date = refDate;
      while (getShiftTypeForDate(date, referenceDate: refDate) !=
          ShiftType.REST) {
        date = date.add(const Duration(days: 1));
      }
      expect(
          consecutiveWorkDays(date, referenceDate: refDate), 0);
    });

    test('returns >0 if today is work day', () {
      final count =
          consecutiveWorkDays(refDate, referenceDate: refDate);
      expect(count, greaterThan(0));
    });
  });

  group('daysUntilNextRest', () {
    test('returns within cycle length bounds', () {
      final days = daysUntilNextRest(refDate, referenceDate: refDate);
      expect(days, isNonNegative);
      expect(days, lessThanOrEqualTo(43));
    });

    test('returns 0 when next day is REST', () {
      var date = refDate;
      while (getShiftTypeForDate(date.add(const Duration(days: 1)),
              referenceDate: refDate) !=
          ShiftType.REST) {
        date = date.add(const Duration(days: 1));
      }
      expect(daysUntilNextRest(date, referenceDate: refDate), 0);
    });
  });
}
