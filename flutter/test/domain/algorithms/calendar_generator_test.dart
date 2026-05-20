import 'package:flutter_test/flutter_test.dart';
import 'package:scheduler_cp/domain/models/shift_cycle_config.dart';
import 'package:scheduler_cp/domain/algorithms/calendar_generator.dart';

void main() {
  final refDate = ShiftCycleConfig.referenceDate;

  group('generateMonthCalendarDays', () {
    test('produces exactly 42 days', () {
      final days = generateMonthCalendarDays(2026, 5,
          referenceDate: refDate);
      expect(days.length, 42);
    });

    test('contains dates from multiple months (padding)', () {
      final days = generateMonthCalendarDays(2026, 5,
          referenceDate: refDate);
      final months = days.map((d) => d.date.month).toSet();
      expect(months.length, greaterThanOrEqualTo(2));
    });

    test('all days have ShiftType assigned', () {
      final days = generateMonthCalendarDays(2026, 5,
          referenceDate: refDate);
      for (final day in days) {
        expect(day.shiftType, isNotNull);
      }
    });

    test('some days are current month', () {
      final days = generateMonthCalendarDays(2026, 5,
          referenceDate: refDate);
      final currentMonthDays =
          days.where((d) => d.isCurrentMonth).length;
      expect(currentMonthDays, 31); // May has 31 days
    });

    test('custom team phase offset', () {
      final defaultDays = generateMonthCalendarDays(2026, 5,
          referenceDate: refDate);
      final offsetDays = generateMonthCalendarDays(2026, 5,
          teamPhaseOffset: 7, referenceDate: refDate);
      // Same dates, potentially different shifts
      for (int i = 0; i < 42; i++) {
        expect(defaultDays[i].date, offsetDays[i].date);
        expect(defaultDays[i].isCurrentMonth, offsetDays[i].isCurrentMonth);
      }
    });
  });
}
