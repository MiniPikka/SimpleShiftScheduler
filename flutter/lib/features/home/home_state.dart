import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/shift_type.dart';
import '../../domain/models/runtime_shift_settings.dart';
import '../../domain/algorithms/shift_calculator.dart';
import '../../domain/algorithms/shift_metrics.dart';
import '../../data/providers.dart';
import 'alarm_settings_notifier.dart';

/// 首页状态 — 存储域数据，展示字符串由 UI 层通过 l10n 计算
class HomeState {
  final ShiftType shiftType;
  final int dayOfCycle;
  final int totalDays;
  final int daysUntilRest;
  final int monthlyWorkDays;
  final int monthTotalDays;
  final int consecutiveWorkDays;
  final String? alarmTime;

  const HomeState({
    this.shiftType = ShiftType.NIGHT,
    this.dayOfCycle = 12,
    this.totalDays = 42,
    this.daysUntilRest = 2,
    this.monthlyWorkDays = 11,
    this.monthTotalDays = 23,
    this.consecutiveWorkDays = 4,
    this.alarmTime,
  });

  HomeState copyWith({
    ShiftType? shiftType,
    int? dayOfCycle,
    int? totalDays,
    int? daysUntilRest,
    int? monthlyWorkDays,
    int? monthTotalDays,
    int? consecutiveWorkDays,
    String? alarmTime,
  }) {
    return HomeState(
      shiftType: shiftType ?? this.shiftType,
      dayOfCycle: dayOfCycle ?? this.dayOfCycle,
      totalDays: totalDays ?? this.totalDays,
      daysUntilRest: daysUntilRest ?? this.daysUntilRest,
      monthlyWorkDays: monthlyWorkDays ?? this.monthlyWorkDays,
      monthTotalDays: monthTotalDays ?? this.monthTotalDays,
      consecutiveWorkDays: consecutiveWorkDays ?? this.consecutiveWorkDays,
      alarmTime: alarmTime ?? this.alarmTime,
    );
  }
}

// ── 辅助函数 ──

/// 工作强度标签（纯函数，由 UI 层决定 locale 文案）
double workloadRatio(int workDays, int monthDays) {
  return monthDays > 0 ? workDays / monthDays : 0;
}

// ── Providers ──

final settingsProvider =
    NotifierProvider<SettingsNotifier, RuntimeShiftSettings>(
  SettingsNotifier.new,
);

final selectedTeamProvider =
    NotifierProvider<SelectedTeamNotifier, int>(SelectedTeamNotifier.new);

final homeProvider = NotifierProvider<HomeNotifier, HomeState>(
  HomeNotifier.new,
);

class SelectedTeamNotifier extends Notifier<int> {
  @override
  int build() {
    final settings = ref.watch(settingsProvider);
    return settings.defaultTeamId;
  }

  @override
  set state(int value) => super.state = value;
}

class HomeNotifier extends Notifier<HomeState> {
  @override
  HomeState build() {
    // Auto-refresh when settings or team change
    ref.listen(settingsProvider, (_, _) => Future.microtask(refresh));
    ref.listen(selectedTeamProvider, (_, _) => Future.microtask(refresh));
    // Initial refresh after first frame
    Future.microtask(refresh);
    return const HomeState();
  }

  void refresh() {
    final now = DateTime.now();
    final settings = ref.read(settingsProvider);
    final teamId = ref.read(selectedTeamProvider);

    final cycle = settings.isValid ? settings.shiftCycle : null;
    final refDate = settings.isValid ? settings.referenceDate : null;
    final phaseOffset = teamPhaseOffsetFor(teamId, customCycle: cycle);

    final shiftInfo = getShiftInfo(
      now,
      teamPhaseOffset: phaseOffset,
      customCycle: cycle,
      referenceDate: refDate,
    );

    final daysRest = daysUntilNextRest(now,
        teamPhaseOffset: phaseOffset,
        customCycle: cycle,
        referenceDate: refDate);

    final monthDays = DateTime(now.year, now.month + 1, 0).day;
    final workDays = countWorkDaysInMonth(
      now.year,
      now.month,
      teamPhaseOffset: phaseOffset,
      customCycle: cycle,
      referenceDate: refDate,
    );

    final consecWork = consecutiveWorkDays(now,
        teamPhaseOffset: phaseOffset,
        customCycle: cycle,
        referenceDate: refDate);

    final totalDays = cycle?.length ?? 42;

    // 今日班次对应的提醒时间
    final alarmSettings = ref.read(alarmSettingsProvider).value;
    final alarmTimeOfShift = alarmSettings?.alarms[shiftInfo.shiftType];
    final alarmTimeStr = alarmTimeOfShift?.serialize();

    state = state.copyWith(
      shiftType: shiftInfo.shiftType,
      dayOfCycle: shiftInfo.dayOfCycle,
      totalDays: totalDays,
      daysUntilRest: daysRest,
      monthlyWorkDays: workDays,
      monthTotalDays: monthDays,
      consecutiveWorkDays: consecWork,
      alarmTime: alarmTimeStr,
    );
  }

  void selectTeam(int teamId) {
    ref.read(selectedTeamProvider.notifier).state = teamId;
  }
}

/// 设置 Notifier：从 Hive 加载 + 自动持久化
class SettingsNotifier extends Notifier<RuntimeShiftSettings> {
  @override
  RuntimeShiftSettings build() {
    // Listen for repo availability, then load saved settings
    ref.listen(hiveRepoProvider, (prev, next) {
      next.whenData((repo) async {
        final saved = await repo.loadSettings();
        if (saved.isValid) {
          state = saved;
        }
      });
    });
    return RuntimeShiftSettings();
  }

  Future<void> update(RuntimeShiftSettings newSettings) async {
    state = newSettings;
    final repoAsync = ref.read(hiveRepoProvider);
    repoAsync.whenData((repo) {
      repo.saveSettings(newSettings);
    });
  }
}
