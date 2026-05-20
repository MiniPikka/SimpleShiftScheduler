import 'package:hive/hive.dart';
import '../../domain/models/shift_type.dart';
import '../../domain/models/runtime_shift_settings.dart';
import 'settings_repository.dart';

/// Hive 实现的设置持久化
///
/// 使用 JSON 兼容格式存储，避免复杂的 TypeAdapter。
/// Box key: 'runtime_settings', value: Map<String, dynamic>

class HiveSettingsRepository implements SettingsRepository {
  static const _boxName = 'settings';
  static const _key = 'runtime_settings';

  late Box<Map> _box;

  Future<void> init() async {
    _box = await Hive.openBox<Map>(_boxName);
  }

  @override
  Future<RuntimeShiftSettings> loadSettings() async {
    try {
      final raw = _box.get(_key);
      if (raw == null) return RuntimeShiftSettings();

      final cycleLength = raw['cycleLength'] as int? ?? 42;
      final shiftCycleRaw = raw['shiftCycle'] as String? ?? '';
      final defaultTeamId = raw['defaultTeamId'] as int? ?? 1;

      List<ShiftType> shiftCycle;
      if (shiftCycleRaw.isEmpty) {
        shiftCycle = ShiftCycleConfigFallback.shiftCycle;
      } else {
        shiftCycle = deserializeShiftCycle(shiftCycleRaw, cycleLength);
        if (shiftCycle.isEmpty) shiftCycle = ShiftCycleConfigFallback.shiftCycle;
      }

      return RuntimeShiftSettings(
        cycleLength: cycleLength,
        shiftCycle: shiftCycle,
        defaultTeamId: defaultTeamId,
      );
    } catch (_) {
      return RuntimeShiftSettings();
    }
  }

  @override
  Future<void> saveSettings(RuntimeShiftSettings settings) async {
    await _box.put(_key, {
      'cycleLength': settings.cycleLength,
      'shiftCycle': serializeShiftCycle(settings.shiftCycle),
      'defaultTeamId': settings.defaultTeamId,
    });
  }
}

/// 内置默认值（避免循环依赖 ShiftCycleConfig）
class ShiftCycleConfigFallback {
  static const cycleLength = 42;
  static const shiftCycle = <ShiftType>[
    ShiftType.MORNING, ShiftType.MORNING,
    ShiftType.AFTERNOON, ShiftType.AFTERNOON,
    ShiftType.REST,
    ShiftType.NIGHT, ShiftType.NIGHT,
    ShiftType.REST, ShiftType.REST,
    ShiftType.MORNING, ShiftType.MORNING,
    ShiftType.AFTERNOON, ShiftType.AFTERNOON,
    ShiftType.REST,
    ShiftType.NIGHT,
    ShiftType.REST, ShiftType.REST, ShiftType.REST,
    ShiftType.MORNING, ShiftType.MORNING,
    ShiftType.AFTERNOON,
    ShiftType.REST,
    ShiftType.NIGHT, ShiftType.NIGHT,
    ShiftType.REST, ShiftType.REST, ShiftType.REST,
    ShiftType.MORNING,
    ShiftType.AFTERNOON, ShiftType.AFTERNOON,
    ShiftType.REST,
    ShiftType.NIGHT, ShiftType.NIGHT,
    ShiftType.REST, ShiftType.REST,
    ShiftType.STUDY, ShiftType.STUDY, ShiftType.STUDY,
    ShiftType.STUDY, ShiftType.STUDY,
    ShiftType.REST, ShiftType.REST,
  ];
}
