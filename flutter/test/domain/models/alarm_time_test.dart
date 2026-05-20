import 'package:flutter_test/flutter_test.dart';
import 'package:scheduler_cp/domain/models/alarm_time.dart';

void main() {
  group('AlarmTime', () {
    test('creates with valid hour and minute', () {
      final t = const AlarmTime(hour: 7, minute: 30);
      expect(t.hour, 7);
      expect(t.minute, 30);
    });

    test('creates with boundary values', () {
      const AlarmTime(hour: 0, minute: 0);
      const AlarmTime(hour: 23, minute: 59);
    });

    test('serializes to HH:mm format', () {
      const t = AlarmTime(hour: 7, minute: 5);
      expect(t.serialize(), '07:05');
    });

    test('serializes with padding', () {
      const t = AlarmTime(hour: 22, minute: 0);
      expect(t.serialize(), '22:00');
    });

    test('deserializes valid string', () {
      final t = AlarmTime.deserialize('14:30');
      expect(t, isNotNull);
      expect(t!.hour, 14);
      expect(t.minute, 30);
    });

    test('deserialize returns null for empty string', () {
      expect(AlarmTime.deserialize(''), isNull);
    });

    test('deserialize returns null for invalid format', () {
      expect(AlarmTime.deserialize('abc'), isNull);
      expect(AlarmTime.deserialize('12:60'), isNull);
      expect(AlarmTime.deserialize('24:00'), isNull);
      expect(AlarmTime.deserialize('-1:00'), isNull);
    });

    test('equality and hashCode', () {
      const a = AlarmTime(hour: 7, minute: 30);
      const b = AlarmTime(hour: 7, minute: 30);
      const c = AlarmTime(hour: 8, minute: 0);

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
      expect(a.hashCode, equals(b.hashCode));
    });
  });
}
