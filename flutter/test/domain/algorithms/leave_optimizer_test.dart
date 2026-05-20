import 'package:flutter_test/flutter_test.dart';
import 'package:scheduler_cp/domain/algorithms/leave_optimizer.dart';
import 'package:scheduler_cp/domain/algorithms/holiday_data.dart';
import 'package:scheduler_cp/domain/models/shift_cycle_config.dart';

void main() {
  final refDate = ShiftCycleConfig.referenceDate;
  final holidays = getChinaHolidays();

  group('buildDailyStatus', () {
    test('produces correct number of days', () {
      final status = buildDailyStatus(
        startDate: refDate,
        days: 30,
        teamPhaseOffset: 0,
        customCycle: null,
        referenceDate: refDate,
        holidays: holidays,
      );
      expect(status.length, 30);
    });

    test('first day matches startDate', () {
      final start = DateTime(2026, 5, 20);
      final status = buildDailyStatus(
        startDate: start,
        days: 10,
        teamPhaseOffset: 0,
        customCycle: null,
        referenceDate: refDate,
        holidays: holidays,
      );
      expect(status.first.date, start);
    });
  });

  group('findBestLeavePlans', () {
    test('returns non-empty list for default settings', () {
      final plans = findBestLeavePlans(
        today: refDate,
        teamPhaseOffset: 0,
        referenceDate: refDate,
      );
      expect(plans.isNotEmpty, true);
    });

    test('returns empty for maxLeaveDays=0', () {
      final plans = findBestLeavePlans(
        today: refDate,
        maxLeaveDays: 0,
      );
      expect(plans.isEmpty, true);
    });

    test('returns empty for daysToAnalyze=0', () {
      final plans = findBestLeavePlans(
        today: refDate,
        daysToAnalyze: 0,
      );
      expect(plans.isEmpty, true);
    });

    test('strategies are sorted by score descending', () {
      final plans = findBestLeavePlans(
        today: refDate,
        referenceDate: refDate,
      );
      if (plans.length >= 2) {
        for (int i = 0; i < plans.length - 1; i++) {
          expect(plans[i].score, greaterThanOrEqualTo(plans[i + 1].score));
        }
      }
    });

    test('leave days within maxLeaveDays', () {
      final plans = findBestLeavePlans(
        today: refDate,
        maxLeaveDays: 3,
        referenceDate: refDate,
      );
      for (final p in plans) {
        expect(p.leaveDays, lessThanOrEqualTo(3));
      }
    });

    test('break days > leave days', () {
      final plans = findBestLeavePlans(
        today: refDate,
        referenceDate: refDate,
      );
      for (final p in plans) {
        expect(p.totalBreakDays, greaterThan(p.leaveDays));
      }
    });

    test('all fields are populated', () {
      final plans = findBestLeavePlans(
        today: refDate,
        referenceDate: refDate,
      );
      if (plans.isNotEmpty) {
        final p = plans.first;
        expect(p.leaveDays, isNonNegative);
        expect(p.totalBreakDays, greaterThan(0));
        expect(p.leaveDates.isNotEmpty, true);
        expect(p.score, greaterThan(0));
      }
    });

    test('no duplicate break ranges', () {
      final plans = findBestLeavePlans(
        today: refDate,
        referenceDate: refDate,
      );
      final ranges = <String>{};
      for (final p in plans) {
        final key = '${p.breakStart}_${p.breakEnd}';
        expect(ranges.contains(key), false);
        ranges.add(key);
      }
    });

    test('custom cycle produces results', () {
      final custom = ShiftCycleConfig.shiftCycle;
      final plans = findBestLeavePlans(
        today: refDate,
        customCycle: custom,
        referenceDate: refDate,
      );
      expect(plans.isNotEmpty, true);
    });
  });
}
