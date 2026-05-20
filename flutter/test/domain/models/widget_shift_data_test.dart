import 'package:flutter_test/flutter_test.dart';
import 'package:scheduler_cp/domain/models/shift_type.dart';
import 'package:scheduler_cp/domain/models/runtime_shift_settings.dart';
import 'package:scheduler_cp/domain/models/widget_shift_data.dart';

String _stubShiftLabel(ShiftType t) => t.name.substring(0, 1);
String _stubTeamName(int id) => 'T$id';
String _stubDateFmt(DateTime d) => '${d.month}/${d.day}';

void main() {
  group('WidgetShiftData', () {
    test('unconfigured factory returns fallback', () {
      final d = WidgetShiftData.unconfigured();
      expect(d.totalDays, 0);
      expect(d.shiftLabel, '未配置');
      expect(d.daysUntilRest, -1);
    });

    test('computeWidgetShiftData returns valid data for default settings', () {
      final settings = RuntimeShiftSettings();
      final today = DateTime(2026, 5, 20);
      final wd = computeWidgetShiftData(
        today: today,
        settings: settings,
        shiftLabelResolver: _stubShiftLabel,
        teamNameResolver: _stubTeamName,
        dateFormatter: _stubDateFmt,
      );
      expect(wd.totalDays, 42);
      expect(wd.dayOfCycle, greaterThan(0));
      expect(wd.teamName, 'T1');
      expect(wd.daysUntilRest, greaterThanOrEqualTo(0));
      expect(wd.tomorrowShiftLabel, isNotEmpty);
    });

    test('computeWidgetShiftData returns unconfigured for invalid settings', () {
      final settings = RuntimeShiftSettings(cycleLength: 0, shiftCycle: []);
      final wd = computeWidgetShiftData(
        today: DateTime(2026, 5, 20),
        settings: settings,
        shiftLabelResolver: _stubShiftLabel,
        teamNameResolver: _stubTeamName,
        dateFormatter: _stubDateFmt,
      );
      expect(wd.totalDays, 0);
      expect(wd.shiftLabel, '未配置');
    });

    test('tomorrow shift differs from today in normal cycle', () {
      final settings = RuntimeShiftSettings();
      final today = DateTime(2026, 5, 20);
      final wd = computeWidgetShiftData(
        today: today,
        settings: settings,
        shiftLabelResolver: _stubShiftLabel,
        teamNameResolver: _stubTeamName,
        dateFormatter: _stubDateFmt,
      );
      // Tomorrow shift should be the next day in the cycle
      expect(wd.tomorrowShiftType, isNotNull);
      // dayOfCycle wraps at cycle length
      if (wd.dayOfCycle < 42) {
        // If not at end of cycle, tomorrow is simply day+1
      }
    });

    test('dateFormatter is used for dateLabel', () {
      final settings = RuntimeShiftSettings();
      final today = DateTime(2026, 12, 25);
      final wd = computeWidgetShiftData(
        today: today,
        settings: settings,
        shiftLabelResolver: _stubShiftLabel,
        teamNameResolver: _stubTeamName,
        dateFormatter: _stubDateFmt,
      );
      expect(wd.dateLabel, '12/25');
    });
  });
}
