import 'package:flutter_test/flutter_test.dart';
import 'package:scheduler_cp/domain/models/shift_type.dart';
import 'package:scheduler_cp/domain/models/alarm_time.dart';
import 'package:scheduler_cp/domain/models/alarm_settings.dart';

void main() {
  group('AlarmSettings', () {
    test('default constructor disables all alarms', () {
      final settings = AlarmSettings();
      for (final type in ShiftType.values) {
        expect(settings.isEnabled(type), isFalse);
      }
      expect(settings.isAnyEnabled(), isFalse);
    });

    test('isEnabled returns true when alarm is set', () {
      final settings = AlarmSettings().copyWithUpdate(
        ShiftType.MORNING,
        const AlarmTime(hour: 7, minute: 0),
      );
      expect(settings.isEnabled(ShiftType.MORNING), isTrue);
      expect(settings.isEnabled(ShiftType.AFTERNOON), isFalse);
      expect(settings.isAnyEnabled(), isTrue);
    });

    test('copyWithUpdate replaces existing alarm', () {
      final settings = AlarmSettings()
          .copyWithUpdate(ShiftType.MORNING, const AlarmTime(hour: 6, minute: 0))
          .copyWithUpdate(ShiftType.MORNING, const AlarmTime(hour: 7, minute: 30));
      expect(settings.alarms[ShiftType.MORNING]!.hour, 7);
      expect(settings.alarms[ShiftType.MORNING]!.minute, 30);
    });

    test('copyWithUpdate with null disables alarm', () {
      final settings = AlarmSettings()
          .copyWithUpdate(ShiftType.NIGHT, const AlarmTime(hour: 22, minute: 0))
          .copyWithUpdate(ShiftType.NIGHT, null);
      expect(settings.isEnabled(ShiftType.NIGHT), isFalse);
    });

    test('equality', () {
      final a = AlarmSettings().copyWithUpdate(
        ShiftType.MORNING,
        const AlarmTime(hour: 7, minute: 0),
      );
      final b = AlarmSettings().copyWithUpdate(
        ShiftType.MORNING,
        const AlarmTime(hour: 7, minute: 0),
      );
      final c = AlarmSettings().copyWithUpdate(
        ShiftType.MORNING,
        const AlarmTime(hour: 8, minute: 0),
      );

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });
  });
}
