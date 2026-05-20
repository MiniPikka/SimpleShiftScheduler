import 'package:flutter/foundation.dart';

/// 提醒时间模型 — 对应 Android 版 AlarmTime.kt
@immutable
class AlarmTime {
  final int hour; // 0..23
  final int minute; // 0..59

  const AlarmTime({required this.hour, required this.minute})
      : assert(hour >= 0 && hour <= 23, 'hour must be 0..23'),
        assert(minute >= 0 && minute <= 59, 'minute must be 0..59');

  /// 序列化为 "HH:mm" 格式（与 Android 版一致）
  String serialize() => '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  /// 从 "HH:mm" 格式反序列化，解析失败返回 null
  static AlarmTime? deserialize(String raw) {
    if (raw.isEmpty) return null;
    try {
      final parts = raw.split(':');
      if (parts.length != 2) return null;
      final h = int.parse(parts[0]);
      final m = int.parse(parts[1]);
      if (h < 0 || h > 23 || m < 0 || m > 59) return null;
      return AlarmTime(hour: h, minute: m);
    } catch (_) {
      return null;
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AlarmTime && hour == other.hour && minute == other.minute;

  @override
  int get hashCode => hour * 60 + minute;

  @override
  String toString() => 'AlarmTime(${serialize()})';
}
