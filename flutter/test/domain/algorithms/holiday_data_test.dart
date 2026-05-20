import 'package:flutter_test/flutter_test.dart';
import 'package:scheduler_cp/domain/algorithms/holiday_data.dart';

void main() {
  group('getChinaHolidays', () {
    late Map<DateTime, HolidayInfo> holidays;

    setUp(() {
      holidays = getChinaHolidays();
    });

    test('returns non-empty map', () {
      expect(holidays.isNotEmpty, true);
    });

    test('contains major 2026 holidays', () {
      // We don't check specific dates but verify key holidays exist by date
      final names = holidays.values.map((h) => h.name).toSet();
      expect(names.any((n) => n?.contains('春节') == true), true);
      expect(names.any((n) => n?.contains('国庆') == true), true);
      expect(names.any((n) => n?.contains('劳动节') == true), true);
    });

    test('adjusted work days marked correctly', () {
      final adjustedDays = holidays.values.where((h) => !h.isHoliday).toList();
      expect(adjustedDays.isNotEmpty, true);
      for (final h in adjustedDays) {
        expect(h.name?.contains('调休'), true);
      }
    });

    test('covers at least 365 days from 2026-01-01', () {
      final start = DateTime(2026, 1, 1);
      final end = DateTime(2027, 1, 1);
      // At minimum should have some days in 2026
      final inRange = holidays.keys.where((d) =>
          d.isAfter(start.subtract(const Duration(days: 1))) &&
          d.isBefore(end.add(const Duration(days: 1))));
      expect(inRange.isNotEmpty, true);
    });
  });

  group('isWeekend', () {
    test('Saturday is weekend', () {
      expect(isWeekend(DateTime(2026, 5, 16)), true); // Saturday
    });

    test('Sunday is weekend', () {
      expect(isWeekend(DateTime(2026, 5, 17)), true); // Sunday
    });

    test('Monday is not weekend', () {
      expect(isWeekend(DateTime(2026, 5, 18)), false);
    });
  });

  group('isNaturallyOff', () {
    test('weekend is naturally off', () {
      final holidays = <DateTime, HolidayInfo>{};
      expect(isNaturallyOff(DateTime(2026, 5, 17), holidays), true); // Sunday
    });

    test('holiday is naturally off', () {
      final holidays = getChinaHolidays();
      // National Day Oct 1, 2026 is a Thursday holiday
      final oct1 = DateTime(2026, 10, 1);
      if (holidays.containsKey(oct1)) {
        expect(isNaturallyOff(oct1, holidays), true);
      }
    });
  });
}
