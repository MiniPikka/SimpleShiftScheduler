import 'package:flutter_test/flutter_test.dart';
import 'package:scheduler_cp/domain/models/shift_cycle_config.dart';
import 'package:scheduler_cp/domain/algorithms/colleague_mode.dart';

void main() {
  group('findCommonRestDays', () {
    test('same team finds all rest days as common', () {
      final result = findCommonRestDays(
        teamAId: 1,
        teamBId: 1,
        today: ShiftCycleConfig.referenceDate,
        referenceDate: ShiftCycleConfig.referenceDate,
      );
      expect(result.totalCount, greaterThan(0));
      expect(result.nextCommonRestDate, isNotNull);
    });

    test('different teams find intersection', () {
      final result = findCommonRestDays(
        teamAId: 1,
        teamBId: 3,
        today: ShiftCycleConfig.referenceDate,
        daysToAnalyze: 365,
        referenceDate: ShiftCycleConfig.referenceDate,
      );
      expect(result.totalCount, isNonNegative);
      expect(result.countIn30Days, lessThanOrEqualTo(30));
      expect(result.countIn60Days, lessThanOrEqualTo(60));
    });

    test('nextCommonRestDate is earliest in list', () {
      final result = findCommonRestDays(
        teamAId: 1,
        teamBId: 2,
        today: ShiftCycleConfig.referenceDate,
        daysToAnalyze: 365,
        referenceDate: ShiftCycleConfig.referenceDate,
      );
      if (result.commonRestDates.isNotEmpty) {
        expect(result.nextCommonRestDate, result.commonRestDates.first);
      }
    });

    test('daysUntilNext is correctly calculated', () {
      final today = ShiftCycleConfig.referenceDate;
      final result = findCommonRestDays(
        teamAId: 1,
        teamBId: 2,
        today: today,
        daysToAnalyze: 365,
        referenceDate: ShiftCycleConfig.referenceDate,
      );
      if (result.nextCommonRestDate != null) {
        expect(result.daysUntilNext,
            result.nextCommonRestDate!.difference(today).inDays);
      }
    });

    test('count30 and count60 are accurate', () {
      final today = ShiftCycleConfig.referenceDate;
      final result = findCommonRestDays(
        teamAId: 1,
        teamBId: 2,
        today: today,
        daysToAnalyze: 365,
        referenceDate: ShiftCycleConfig.referenceDate,
      );
      final manual30 = result.commonRestDates
          .where((d) => d.difference(today).inDays < 30)
          .length;
      final manual60 = result.commonRestDates
          .where((d) => d.difference(today).inDays < 60)
          .length;
      expect(result.countIn30Days, manual30);
      expect(result.countIn60Days, manual60);
    });

    test('team names are populated', () {
      final result = findCommonRestDays(
        teamAId: 1,
        teamBId: 3,
        today: ShiftCycleConfig.referenceDate,
        referenceDate: ShiftCycleConfig.referenceDate,
      );
      expect(result.teamAName, isNotEmpty);
      expect(result.teamBName, isNotEmpty);
    });

    test('result has all fields non-null except next when empty', () {
      final result = findCommonRestDays(
        teamAId: 1,
        teamBId: 2,
        today: ShiftCycleConfig.referenceDate,
        daysToAnalyze: 365,
        referenceDate: ShiftCycleConfig.referenceDate,
      );
      expect(result.commonRestDates, isNotNull);
      expect(result.totalCount, isNotNull);
    });
  });
}
