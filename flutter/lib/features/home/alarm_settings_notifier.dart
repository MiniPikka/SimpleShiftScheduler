import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/shift_type.dart';
import '../../domain/models/alarm_time.dart';
import '../../domain/models/alarm_settings.dart';
import '../../data/providers.dart';

/// 提醒设置 Provider — 从 Hive 加载 + 自动持久化
final alarmSettingsProvider =
    StateNotifierProvider<AlarmSettingsNotifier, AlarmSettings>(
  (ref) => AlarmSettingsNotifier(ref),
);

class AlarmSettingsNotifier extends StateNotifier<AlarmSettings> {
  final Ref _ref;

  AlarmSettingsNotifier(this._ref) : super(AlarmSettings()) {
    _load();
  }

  Future<void> _load() async {
    final repoAsync = _ref.read(hiveRepoProvider);
    repoAsync.whenData((repo) async {
      final saved = await repo.loadAlarmSettings();
      if (mounted) {
        state = saved;
      }
    });
  }

  /// 更新某个班次的提醒时间（立即自动保存，与 Android 版一致）
  Future<void> updateAlarmTime(ShiftType type, AlarmTime? time) async {
    state = state.copyWithUpdate(type, time);
    final repoAsync = _ref.read(hiveRepoProvider);
    repoAsync.whenData((repo) {
      repo.saveAlarmSettings(state);
    });
  }
}
