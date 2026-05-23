import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../core/services/widget_service.dart';
import '../../core/utils/l10n.dart';
import '../../domain/models/shift_type.dart';
import '../../domain/models/widget_shift_data.dart';
import 'home_state.dart';
import 'widgets/hero_card.dart';
import 'widgets/stats_row.dart';
import 'widgets/tools_row.dart';
import 'widgets/message_banner.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  // Dedup guard: skip widget update if data unchanged
  static String? _lastWidgetFingerprint;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(homeProvider);
    final teamId = ref.watch(selectedTeamProvider);
    final settings = ref.watch(settingsProvider);
    final l10n = context.l10n;
    final now = DateTime.now();

    final teamName = localizedTeamName(teamId, l10n);
    final greeting = localizedGreeting(now.hour, l10n);
    final weekday = localizedWeekday(now.weekday, l10n);
    final dateText = l10n.fullDateFormat(now.year, now.month, now.day, weekday);
    final shiftLabel = localizedShiftLabel(state.shiftType, l10n);

    // Update desktop widget via domain pure function + dedup guard
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final wd = computeWidgetShiftData(
        today: now,
        settings: settings,
        shiftLabelResolver: (t) => localizedShiftLabel(t, l10n),
        teamNameResolver: (id) => localizedTeamName(id, l10n),
        dateFormatter: (d) => l10n.monthDayWeekday(d.month, d.day, localizedWeekday(d.weekday, l10n)),
      );
      final fp = '${wd.shiftLabel}|${wd.teamName}|${wd.dateLabel}|${wd.dayOfCycle}|${wd.totalDays}|${wd.daysUntilRest}|${wd.tomorrowShiftLabel}';
      if (fp == _lastWidgetFingerprint) return;
      _lastWidgetFingerprint = fp;
      WidgetService.update(
        shiftLabel: wd.shiftLabel,
        teamName: wd.teamName,
        dateLabel: wd.dateLabel,
        progressText: l10n.cycleProgress(wd.dayOfCycle, wd.totalDays),
        restText: wd.daysUntilRest == 0 ? l10n.restDay : wd.daysUntilRest == 1 ? l10n.tomorrowRest : l10n.daysUntilRest(wd.daysUntilRest),
        tomorrowShiftLabel: wd.tomorrowShiftLabel,
        shiftBadgeColor: shiftColor(wd.shiftType).toHex(),
        tomorrowDotColor: shiftColor(wd.tomorrowShiftType).toHex(),
      );
    });

    final ratio = workloadRatio(state.monthlyWorkDays, state.monthTotalDays);
    final workloadLabel = ratio <= 0.4 ? l10n.workloadEasy : ratio <= 0.6 ? l10n.workloadModerate : l10n.workloadHard;
    final consecDays = state.consecutiveWorkDays;
    final consecLabel = consecDays < 3 ? l10n.statusNormal : consecDays < 6 ? l10n.statusWarning : l10n.statusRestNeeded;

    String msg;
    if (state.shiftType == ShiftType.REST) {
      msg = l10n.messageRest;
    } else if (state.shiftType == ShiftType.NIGHT) {
      msg = l10n.messageNight;
    } else if (state.daysUntilRest == 0) {
      msg = l10n.messageRestToday;
    } else if (state.daysUntilRest == 1) {
      msg = l10n.messageRestTomorrow;
    } else if (state.daysUntilRest <= 3) {
      msg = l10n.messageRestSoon;
    } else if (state.consecutiveWorkDays >= 5) {
      msg = l10n.messageConsecutive;
    } else {
      msg = l10n.messageDefault;
    }

    final content = SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: CpSpacing.md, vertical: CpSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StaggeredItem(delayMs: 0, child: _GreetingRow(greeting: greeting, teamName: teamName, dateText: dateText)),
          const SizedBox(height: CpSpacing.sm),
          _StaggeredItem(delayMs: 80, child: HeroCard(
            shiftLabel: shiftLabel, shiftType: state.shiftType, teamName: teamName,
            alarmTime: state.alarmTime != null ? l10n.alarmTime(state.alarmTime!) : null,
            dayOfCycle: state.dayOfCycle, totalDays: state.totalDays, daysUntilRest: state.daysUntilRest,
            cycleProgressText: l10n.cycleProgress(state.dayOfCycle, state.totalDays),
            restLabel: state.daysUntilRest == 0 ? l10n.restDay : l10n.daysUntilRest(state.daysUntilRest),
          )),
          const SizedBox(height: CpSpacing.lg),
          _StaggeredItem(delayMs: 160, child: StatsRow(
            monthlyWorkDays: state.monthlyWorkDays, monthTotalDays: state.monthTotalDays,
            workloadLabel: workloadLabel, consecutiveWorkDays: state.consecutiveWorkDays,
            consecutiveStatus: consecLabel, monthlyWorkLabel: l10n.monthlyWork, consecutiveWorkLabel: l10n.consecutiveWork,
          )),
          const SizedBox(height: CpSpacing.lg),
          _StaggeredItem(delayMs: 240, child: ToolsRow(
            onLeaveOptimizer: () => context.push('/leave-optimizer'),
            onColleagueMode: () => context.push('/colleague-mode'),
            onSalaryPredictor: () => context.push('/salary-predictor'),
            leaveLabel: l10n.leaveOptimizer, leaveDesc: l10n.leaveOptimizerDesc,
            colleagueLabel: l10n.colleagueMode, colleagueDesc: l10n.colleagueModeDesc,
            salaryLabel: l10n.salaryPredictor, salaryDesc: l10n.salaryPredictorDesc,
          )),
          const SizedBox(height: CpSpacing.sm),
          _StaggeredItem(delayMs: 320, child: MessageBanner(message: msg)),
          const SizedBox(height: CpSpacing.sm),
        ],
      ),
    );

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: CpSpacing.maxContentWidth),
            child: RefreshIndicator(
              onRefresh: () async {
                ref.read(homeProvider.notifier).refresh();
              },
              child: content,
            ),
          ),
        ),
      ),
    );
  }
}

/// 错位入场动画：fadeIn + slideUp
class _StaggeredItem extends StatefulWidget {
  final int delayMs;
  final Widget child;
  const _StaggeredItem({required this.delayMs, required this.child});

  @override
  State<_StaggeredItem> createState() => _StaggeredItemState();
}

class _StaggeredItemState extends State<_StaggeredItem> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  late final Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _offset = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(Duration(milliseconds: widget.delayMs), () {
        if (mounted) _ctrl.forward();
      });
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _offset, child: widget.child),
    );
  }
}

class _GreetingRow extends StatelessWidget {
  final String greeting;
  final String teamName;
  final String dateText;
  const _GreetingRow({required this.greeting, required this.teamName, required this.dateText});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$greeting, $teamName', style: theme.textTheme.headlineLarge),
          const SizedBox(height: 2),
          Text(dateText, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}
