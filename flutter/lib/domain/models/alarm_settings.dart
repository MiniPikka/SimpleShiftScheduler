import 'package:flutter/foundation.dart';
import 'shift_type.dart';
import 'alarm_time.dart';

/// 提醒设置模型 — 对应 Android 版 AlarmSettings.kt
///
/// 每个班次类型可独立设置提醒时间，null 表示该班次不提醒。
@immutable
class AlarmSettings {
  final Map<ShiftType, AlarmTime?> alarms;

  AlarmSettings({Map<ShiftType, AlarmTime?>? alarms})
      : alarms = alarms ??
            {for (final t in ShiftType.values) t: null};

  /// 某个班次是否启用了提醒
  bool isEnabled(ShiftType type) => alarms[type] != null;

  /// 是否至少有一个班次启用了提醒
  bool isAnyEnabled() => alarms.values.any((t) => t != null);

  AlarmSettings copyWithUpdate(ShiftType type, AlarmTime? time) {
    final newAlarms = Map<ShiftType, AlarmTime?>.from(alarms);
    newAlarms[type] = time;
    return AlarmSettings(alarms: newAlarms);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AlarmSettings &&
          alarms.length == other.alarms.length &&
          alarms.entries.every((e) => other.alarms[e.key] == e.value);

  @override
  int get hashCode => Object.hashAll(alarms.entries.expand((e) => [e.key, e.value]));

  @override
  String toString() => 'AlarmSettings(${alarms.entries.map((e) => '${e.key.name}=${e.value?.serialize() ?? "off"}').join(', ')})';
}
