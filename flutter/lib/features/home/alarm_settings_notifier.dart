import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/shift_type.dart';
import '../../domain/models/alarm_time.dart';
import '../../domain/models/alarm_settings.dart';
import '../../data/providers.dart';
import '../../data/repositories/settings_repository_hive.dart';

/// 提醒设置 Provider — 从 Hive 加载 + 自动持久化
///
/// 使用 [AsyncNotifier] 以正确等待 [hiveRepoProvider] 异步初始化完成后再加载。
/// 此前使用 [StateNotifier] + [FutureProvider.whenData] 存在竞态：构造时
/// [hiveRepoProvider] 尚未解析，[whenData] 对 [AsyncLoading] 是空操作，
/// 导致保存的设置永远无法加载（所有提醒静默丢失）。
final alarmSettingsProvider =
    AsyncNotifierProvider<AsyncAlarmSettingsNotifier, AlarmSettings>(
  AsyncAlarmSettingsNotifier.new,
);

class AsyncAlarmSettingsNotifier extends AsyncNotifier<AlarmSettings> {
  HiveSettingsRepository? _repo;

  @override
  Future<AlarmSettings> build() async {
    final repo = await ref.read(hiveRepoProvider.future);
    _repo = repo;
    return repo.loadAlarmSettings();
  }

  /// 更新某个班次的提醒时间（立即自动保存，与 Android 版一致）
  Future<void> updateAlarmTime(ShiftType type, AlarmTime? time) async {
    final current = state.value ?? AlarmSettings();
    final updated = current.copyWithUpdate(type, time);
    state = AsyncData(updated);

    final repo = _repo;
    if (repo != null) {
      await repo.saveAlarmSettings(updated);
    }
  }
}
