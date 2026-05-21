import '../../domain/models/runtime_shift_settings.dart';
import '../../domain/models/shift_type.dart';
import '../../domain/models/alarm_settings.dart';
import '../../domain/models/salary_config.dart';

/// 设置持久化抽象接口
///
/// Android 版使用 DataStore Preferences，CP 版使用 Hive 实现。
/// 序列化格式保持一致：逗号分隔枚举名（如 "MORNING,AFTERNOON,REST"）。

abstract class SettingsRepository {
  /// 加载运行时设置，首次安装返回默认值
  Future<RuntimeShiftSettings> loadSettings();

  /// 保存运行时设置
  Future<void> saveSettings(RuntimeShiftSettings settings);

  /// 加载提醒设置，首次安装返回默认值（全部禁用）
  Future<AlarmSettings> loadAlarmSettings();

  /// 保存提醒设置
  Future<void> saveAlarmSettings(AlarmSettings settings);

  /// 加载津贴配置，首次安装返回默认值（全部 0）
  Future<SalaryConfig> loadSalaryConfig();

  /// 保存津贴配置
  Future<void> saveSalaryConfig(SalaryConfig config);
}

/// 序列化：List<ShiftType> → 逗号分隔字符串
String serializeShiftCycle(List<ShiftType> cycle) {
  return cycle.map((t) => t.name).join(',');
}

/// 反序列化：逗号分隔字符串 → List<ShiftType>
List<ShiftType> deserializeShiftCycle(String raw, int expectedLength) {
  if (raw.isEmpty) return [];
  try {
    final parts = raw.split(',');
    final result = parts.map((s) => ShiftType.values.byName(s.trim())).toList();
    if (result.length != expectedLength) return [];
    return result;
  } catch (_) {
    return []; // 解析失败回退
  }
}
