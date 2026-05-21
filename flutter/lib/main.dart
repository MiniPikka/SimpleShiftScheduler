import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'app/routes.dart';
import 'core/theme/theme.dart';
import 'core/services/notification_service.dart';
import 'core/services/notification_scheduler.dart';
import 'core/services/calendar_service.dart';
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
  await _requestPermissions();
  runApp(const ProviderScope(child: SchedulerApp()));
}

/// Request necessary runtime permissions on first launch.
Future<void> _requestPermissions() async {
  if (Platform.isAndroid) {
    await Permission.notification.request();
    await Permission.calendarFullAccess.request();
  } else if (Platform.isIOS) {
    await Permission.notification.request();
  }
}

/// 监听提醒设置变化，自动调度通知和日历日程
class _NotificationScheduler extends ConsumerStatefulWidget {
  final Widget child;
  const _NotificationScheduler({required this.child});

  @override
  ConsumerState<_NotificationScheduler> createState() =>
      _NotificationSchedulerState();
}

class _NotificationSchedulerState
    extends ConsumerState<_NotificationScheduler> {
  Timer? _debounceTimer;
  bool _isSyncingCalendar = false;
  bool _needsResync = false;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repoAsync = ref.watch(hiveRepoProvider);
    ref.watch(alarmSettingsProvider);
    final settings = ref.watch(settingsProvider);

    ref.listen(alarmSettingsProvider, (prev, next) {
      _debouncedReschedule(repoAsync, next, settings);
    });

    ref.listen(hiveRepoProvider, (prev, next) {
      next.whenData((_) {
        _debouncedReschedule(
          repoAsync,
          ref.read(alarmSettingsProvider),
          ref.read(settingsProvider),
        );
      });
    });

    return widget.child;
  }

  /// Debounce reschedule calls to prevent duplicate syncs during cold start.
  void _debouncedReschedule(
    AsyncValue<dynamic> repoAsync,
    AlarmSettings alarmSettings,
    RuntimeShiftSettings settings,
  ) {
    if (!repoAsync.hasValue || !settings.isValid) return;

    _needsResync = true;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _performSync(repoAsync, alarmSettings, settings);
    });
  }

  Future<void> _performSync(
    AsyncValue<dynamic> repoAsync,
    AlarmSettings alarmSettings,
    RuntimeShiftSettings settings,
  ) async {
    if (_isSyncingCalendar || !_needsResync) return;
    _needsResync = false;
    _isSyncingCalendar = true;

    try {
      final teamId = ref.read(selectedTeamProvider);
      final phaseOffset = teamPhaseOffsetFor(
        teamId,
        customCycle: settings.shiftCycle,
      );

      // Schedule local notifications
      scheduleShiftNotifications(
        alarmSettings: alarmSettings,
        shiftCycle: settings.shiftCycle,
        teamPhaseOffset: phaseOffset,
        referenceDate: settings.referenceDate,
      );

      // Sync calendar events (only if any alarm is enabled)
      if (alarmSettings.isAnyEnabled()) {
        final refDateStr =
            '${settings.referenceDate.year}-'
            '${settings.referenceDate.month.toString().padLeft(2, '0')}-'
            '${settings.referenceDate.day.toString().padLeft(2, '0')}';
        await CalendarService.syncShiftEvents(
          shiftCycle: settings.shiftCycle,
          teamPhaseOffset: phaseOffset,
          alarmSettings: alarmSettings,
          referenceDate: refDateStr,
        );
      }
    } finally {
      _isSyncingCalendar = false;
      // If a new reschedule request arrived during sync, re-run
      if (_needsResync) {
        final teamId = ref.read(selectedTeamProvider);
        final phaseOffset = teamPhaseOffsetFor(
          teamId,
          customCycle: settings.shiftCycle,
        );
        final alarmSettings = ref.read(alarmSettingsProvider);
        final refDateStr =
            '${settings.referenceDate.year}-'
            '${settings.referenceDate.month.toString().padLeft(2, '0')}-'
            '${settings.referenceDate.day.toString().padLeft(2, '0')}';
        _needsResync = false;
        _isSyncingCalendar = true;
        try {
          scheduleShiftNotifications(
            alarmSettings: alarmSettings,
            shiftCycle: settings.shiftCycle,
            teamPhaseOffset: phaseOffset,
            referenceDate: settings.referenceDate,
          );
          if (alarmSettings.isAnyEnabled()) {
            await CalendarService.syncShiftEvents(
              shiftCycle: settings.shiftCycle,
              teamPhaseOffset: phaseOffset,
              alarmSettings: alarmSettings,
              referenceDate: refDateStr,
            );
          }
        } finally {
          _isSyncingCalendar = false;
        }
      }
    }
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
