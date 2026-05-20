import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app/routes.dart';
import 'core/theme/theme.dart';
import 'core/services/notification_service.dart';
import 'core/services/notification_scheduler.dart';
import 'core/services/share_service.dart';
import 'core/services/supabase_service.dart';
import 'data/providers.dart';
import 'domain/models/runtime_shift_settings.dart';
import 'domain/models/alarm_settings.dart';
import 'domain/algorithms/shift_calculator.dart';
import 'features/home/home_state.dart';
import 'features/home/alarm_settings_notifier.dart';
import 'l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await NotificationService.init();
  await SupabaseService.init();
  await cleanupOldShareImages();
  runApp(const ProviderScope(child: SchedulerApp()));
}

/// 监听提醒设置变化，自动调度通知
class _NotificationScheduler extends ConsumerStatefulWidget {
  final Widget child;
  const _NotificationScheduler({required this.child});

  @override
  ConsumerState<_NotificationScheduler> createState() =>
      _NotificationSchedulerState();
}

class _NotificationSchedulerState
    extends ConsumerState<_NotificationScheduler> {
  @override
  Widget build(BuildContext context) {
    final repoAsync = ref.watch(hiveRepoProvider);
    final alarmSettings = ref.watch(alarmSettingsProvider);
    final settings = ref.watch(settingsProvider);

    ref.listen(alarmSettingsProvider, (prev, next) {
      _reschedule(repoAsync, next, settings);
    });

    // 首次加载完成后调度
    ref.listen(hiveRepoProvider, (prev, next) {
      next.whenData((_) {
        _reschedule(repoAsync, alarmSettings, settings);
      });
    });

    return widget.child;
  }

  void _reschedule(
    AsyncValue<dynamic> repoAsync,
    AlarmSettings alarmSettings,
    RuntimeShiftSettings settings,
  ) {
    if (!repoAsync.hasValue || !settings.isValid) return;
    final teamId = ref.read(selectedTeamProvider);
    final phaseOffset = teamPhaseOffsetFor(teamId, customCycle: settings.shiftCycle);
    scheduleShiftNotifications(
      alarmSettings: alarmSettings,
      shiftCycle: settings.shiftCycle,
      teamPhaseOffset: phaseOffset,
      referenceDate: settings.referenceDate,
    );
  }
}

class SchedulerApp extends StatelessWidget {
  const SchedulerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return _NotificationScheduler(
      child: MaterialApp.router(
        title: '倒班助手',
        debugShowCheckedModeBanner: false,
        theme: CpTheme.light,
        darkTheme: CpTheme.dark,
        themeMode: ThemeMode.system,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );
  }
}
