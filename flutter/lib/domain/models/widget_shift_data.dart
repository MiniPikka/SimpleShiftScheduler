import '../models/shift_type.dart';
import '../models/runtime_shift_settings.dart';
import '../models/team.dart';
import '../algorithms/shift_calculator.dart';
import '../algorithms/shift_metrics.dart';

/// Widget 显示数据 — 对应 Android 版 WidgetShiftData
class WidgetShiftData {
  final String dateLabel; // "5月20日 周三"
  final String shiftLabel; // "早"
  final ShiftType shiftType;
  final int dayOfCycle; // 1-based
  final int totalDays; // 0 = 未配置
  final String teamName; // "一值"
  final int daysUntilRest; // -1 = 未配置/无休班
  final String tomorrowShiftLabel; // "中"
  final ShiftType tomorrowShiftType;
  final String handoverText; // "← 接一值(夜) · 二值(中)接我的班 →"

  const WidgetShiftData({
    required this.dateLabel,
    required this.shiftLabel,
    required this.shiftType,
    required this.dayOfCycle,
    required this.totalDays,
    required this.teamName,
    required this.daysUntilRest,
    required this.tomorrowShiftLabel,
    required this.tomorrowShiftType,
    this.handoverText = '',
  });

  /// 兜底数据：未配置时显示引导文案
  factory WidgetShiftData.unconfigured() => const WidgetShiftData(
        dateLabel: '',
        shiftLabel: '未配置',
        shiftType: ShiftType.REST,
        dayOfCycle: 0,
        totalDays: 0,
        teamName: '',
        daysUntilRest: -1,
        tomorrowShiftLabel: '',
        tomorrowShiftType: ShiftType.REST,
      );
}

/// 计算 Widget 显示数据 — 对应 Android 版 computeWidgetShiftData()
///
/// 纯函数，复用 getShiftInfo() + daysUntilNextRest() + findShiftHandover()。
/// settings.isValid == false 时返回 WidgetShiftData.unconfigured()。
WidgetShiftData computeWidgetShiftData({
  required DateTime today,
  required RuntimeShiftSettings settings,
  required String Function(ShiftType) shiftLabelResolver,
  required String Function(int) teamNameResolver,
  required String Function(DateTime) dateFormatter,
}) {
  if (!settings.isValid) return WidgetShiftData.unconfigured();

  final teamPhaseOffset =
      (settings.defaultTeamId - 1) * (settings.shiftCycle.length ~/ Team.totalTeams);

  final todayInfo = getShiftInfo(
    today,
    teamPhaseOffset: teamPhaseOffset,
    customCycle: settings.shiftCycle,
    referenceDate: settings.referenceDate,
  );

  final tomorrowInfo = getShiftInfo(
    today.add(const Duration(days: 1)),
    teamPhaseOffset: teamPhaseOffset,
    customCycle: settings.shiftCycle,
    referenceDate: settings.referenceDate,
  );

  final daysRest = daysUntilNextRest(
    today,
    teamPhaseOffset: teamPhaseOffset,
    customCycle: settings.shiftCycle,
    referenceDate: settings.referenceDate,
  );

  final handover = findShiftHandover(
    date: today,
    teamId: settings.defaultTeamId,
    customCycle: settings.shiftCycle,
    referenceDate: settings.referenceDate,
  );
  final handoverText = handover != null
      ? '← 接${teamNameResolver(handover.predTeam)}(${shiftLabelResolver(handover.predShift)}) · ${teamNameResolver(handover.succTeam)}(${shiftLabelResolver(handover.succShift)})接我的班 →'
      : '';

  return WidgetShiftData(
    dateLabel: dateFormatter(today),
    shiftLabel: shiftLabelResolver(todayInfo.shiftType),
    shiftType: todayInfo.shiftType,
    dayOfCycle: todayInfo.dayOfCycle,
    totalDays: settings.shiftCycle.length,
    teamName: teamNameResolver(settings.defaultTeamId),
    daysUntilRest: daysRest,
    tomorrowShiftLabel: shiftLabelResolver(tomorrowInfo.shiftType),
    tomorrowShiftType: tomorrowInfo.shiftType,
    handoverText: handoverText,
  );
}
