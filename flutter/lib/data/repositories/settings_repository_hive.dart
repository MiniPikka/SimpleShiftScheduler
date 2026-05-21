import 'package:hive/hive.dart';
import '../../domain/models/shift_type.dart';
import '../../domain/models/runtime_shift_settings.dart';
import '../../domain/models/alarm_time.dart';
import '../../domain/models/alarm_settings.dart';
import '../../domain/models/salary_config.dart';
import 'settings_repository.dart';

/// Hive 实现的设置持久化
///
/// 使用 JSON 兼容格式存储，避免复杂的 TypeAdapter。
/// Box key: 'settings', value: Map<String, dynamic>

class HiveSettingsRepository implements SettingsRepository {
  static const _boxName = 'settings';
  static const _alarmBoxName = 'alarm_settings';
  static const _salaryBoxName = 'salary_config';
  static const _key = 'runtime_settings';
  static const _alarmKeyPrefix = 'alarm_time_';
  static const _salaryKey = 'premiums';

  late Box<Map> _box;
  late Box<String> _alarmBox;
  late Box<String> _salaryBox;

  Future<void> init() async {
    _box = await Hive.openBox<Map>(_boxName);
    _alarmBox = await Hive.openBox<String>(_alarmBoxName);
    _salaryBox = await Hive.openBox<String>(_salaryBoxName);
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

  // ── 提醒设置持久化 ──

  String _alarmKey(ShiftType type) => '$_alarmKeyPrefix${type.name.toLowerCase()}';

  @override
  Future<AlarmSettings> loadAlarmSettings() async {
    try {
      final alarms = <ShiftType, AlarmTime?>{};
      for (final type in ShiftType.values) {
        final raw = _alarmBox.get(_alarmKey(type));
        alarms[type] = AlarmTime.deserialize(raw ?? '');
      }
      return AlarmSettings(alarms: alarms);
    } catch (_) {
      return AlarmSettings();
    }
  }

  @override
  Future<void> saveAlarmSettings(AlarmSettings settings) async {
    for (final type in ShiftType.values) {
      final time = settings.alarms[type];
      await _alarmBox.put(_alarmKey(type), time?.serialize() ?? '');
    }
  }

  // ── 津贴配置持久化 ──

  @override
  Future<SalaryConfig> loadSalaryConfig() async {
    try {
      final raw = _salaryBox.get(_salaryKey) ?? '';
      if (raw.isEmpty) return const SalaryConfig();
      final premiums = <ShiftType, double>{};
      for (final entry in raw.split(',')) {
        final parts = entry.split('=');
        if (parts.length == 2) {
          final type = ShiftType.values.byName(parts[0].trim());
          final value = double.tryParse(parts[1].trim()) ?? 0;
          premiums[type] = value;
        }
      }
      return SalaryConfig(shiftPremiums: premiums);
    } catch (_) {
      return const SalaryConfig();
    }
  }

  @override
  Future<void> saveSalaryConfig(SalaryConfig config) async {
    final raw = config.shiftPremiums.entries
        .map((e) => '${e.key.name}=${e.value}')
        .join(',');
    await _salaryBox.put(_salaryKey, raw);
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
