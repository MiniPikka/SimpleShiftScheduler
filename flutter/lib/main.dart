import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app/routes.dart';
import 'core/theme/theme.dart';
import 'core/services/notification_service.dart';
import 'core/services/supabase_service.dart';
import 'l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await NotificationService.init();
  await SupabaseService.init();
  runApp(const ProviderScope(child: SchedulerApp()));
}

class SchedulerApp extends StatelessWidget {
  const SchedulerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: '倒班助手',
      debugShowCheckedModeBanner: false,
      theme: CpTheme.light,
      darkTheme: CpTheme.dark,
      themeMode: ThemeMode.system,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    );
  }
}
