import 'package:flutter_test/flutter_test.dart';
import 'package:scheduler_cp/domain/models/shift_type.dart';
import 'package:scheduler_cp/features/home/home_state.dart';

void main() {
  group('HomeState', () {
    test('default values are set', () {
      const state = HomeState();
      expect(state.shiftType, ShiftType.NIGHT);
      expect(state.dayOfCycle, 12);
      expect(state.totalDays, 42);
    });

    test('copyWith updates fields', () {
      const state = HomeState();
      final updated = state.copyWith(shiftType: ShiftType.MORNING, dayOfCycle: 5);
      expect(updated.shiftType, ShiftType.MORNING);
      expect(updated.dayOfCycle, 5);
      expect(updated.totalDays, 42); // unchanged
    });

    test('all fields can be copied', () {
      const state = HomeState();
      final updated = state.copyWith(
        shiftType: ShiftType.REST,
        dayOfCycle: 1,
        totalDays: 30,
        daysUntilRest: 5,
        monthlyWorkDays: 15,
        monthTotalDays: 30,
        consecutiveWorkDays: 3,
        alarmTime: '08:00',
      );
      expect(updated.shiftType, ShiftType.REST);
      expect(updated.dayOfCycle, 1);
      expect(updated.totalDays, 30);
      expect(updated.daysUntilRest, 5);
      expect(updated.monthlyWorkDays, 15);
      expect(updated.monthTotalDays, 30);
      expect(updated.consecutiveWorkDays, 3);
      expect(updated.alarmTime, '08:00');
    });
  });

  group('workloadRatio', () {
    test('returns correct ratio', () {
      expect(workloadRatio(10, 31), closeTo(0.32, 0.01));
      expect(workloadRatio(0, 0), 0);
      expect(workloadRatio(31, 31), 1.0);
    });
  });
}
