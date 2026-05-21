import 'package:flutter_test/flutter_test.dart';
import 'package:scheduler_cp/domain/models/shift_type.dart';
import 'package:scheduler_cp/domain/models/salary_config.dart';

void main() {
  group('SalaryConfig', () {
    test('default is empty', () {
      const config = SalaryConfig();
      expect(config.shiftPremiums, isEmpty);
    });

    test('stores and reads premiums', () {
      final config = SalaryConfig(shiftPremiums: {
        ShiftType.MORNING: 50.0,
        ShiftType.NIGHT: 200.0,
      });
      expect(config.shiftPremiums[ShiftType.MORNING], 50.0);
      expect(config.shiftPremiums[ShiftType.NIGHT], 200.0);
      expect(config.shiftPremiums[ShiftType.AFTERNOON], isNull);
    });

    test('handles zero values', () {
      final config = SalaryConfig(shiftPremiums: {
        ShiftType.MORNING: 0,
      });
      expect(config.shiftPremiums[ShiftType.MORNING], 0);
    });
  });

  group('serialization round-trip', () {
    String serialize(Map<ShiftType, double> premiums) {
      return premiums.entries
          .map((e) => '${e.key.name}=${e.value}')
          .join(',');
    }

    Map<ShiftType, double> deserialize(String raw) {
      final premiums = <ShiftType, double>{};
      if (raw.isEmpty) return premiums;
      for (final entry in raw.split(',')) {
        final parts = entry.split('=');
        if (parts.length == 2) {
          final type = ShiftType.values.byName(parts[0].trim());
          final value = double.tryParse(parts[1].trim()) ?? 0;
          premiums[type] = value;
        }
      }
      return premiums;
    }

    test('all four shift types', () {
      final original = <ShiftType, double>{
        ShiftType.MORNING: 0,
        ShiftType.AFTERNOON: 50,
        ShiftType.NIGHT: 200,
        ShiftType.STUDY: 0,
      };
      final restored = deserialize(serialize(original));
      expect(restored[ShiftType.MORNING], 0);
      expect(restored[ShiftType.AFTERNOON], 50);
      expect(restored[ShiftType.NIGHT], 200);
      expect(restored[ShiftType.STUDY], 0);
    });

    test('single entry', () {
      final restored = deserialize(serialize({ShiftType.NIGHT: 180.0}));
      expect(restored[ShiftType.NIGHT], 180);
    });

    test('decimal value', () {
      final restored = deserialize(serialize({ShiftType.AFTERNOON: 12.5}));
      expect(restored[ShiftType.AFTERNOON], 12.5);
    });

    test('empty string returns empty map', () {
      expect(deserialize(''), isEmpty);
    });

    test('format is correct', () {
      final serialized = serialize({ShiftType.NIGHT: 200, ShiftType.MORNING: 50});
      expect(serialized.contains('NIGHT=200'), true);
      expect(serialized.contains('MORNING=50'), true);
    });

    test('negative values handled', () {
      final restored = deserialize(serialize({ShiftType.MORNING: -10}));
      expect(restored[ShiftType.MORNING], -10);
    });
  });

  group('inline edit logic', () {
    test('empty input returns 0', () {
      final v = _parseValue('');
      expect(v, 0.0);
    });

    test('valid integer', () {
      final v = _parseValue('200');
      expect(v, 200.0);
    });

    test('valid decimal', () {
      final v = _parseValue('12.5');
      expect(v, 12.5);
    });

    test('invalid returns 0', () {
      final v = _parseValue('abc');
      expect(v, 0.0);
    });

    test('negative returns 0', () {
      final v = _parseValue('-5');
      expect(v, 0.0);
    });

    test('whitespace trimmed', () {
      final v = _parseValue(' 50 ');
      expect(v, 50.0);
    });
  });
}

/// Mirror of the inline edit save logic from SalaryPredictorScreen.
double _parseValue(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return 0.0;
  final v = double.tryParse(trimmed) ?? 0.0;
  return v < 0 ? 0.0 : v;
}
