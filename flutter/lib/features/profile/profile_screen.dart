import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/spacing.dart';
import '../../core/utils/responsive.dart';
import '../../core/theme/shapes.dart';
import '../../core/utils/l10n.dart';
import '../../core/services/linux_calendar_sync.dart';
import '../../domain/models/runtime_shift_settings.dart';
import '../home/home_state.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final teamId = ref.watch(selectedTeamProvider);
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.profileTitle)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: contentMaxWidth(context)),
            child: ListView(padding: const EdgeInsets.all(CpSpacing.md), children: [
              Card(shape: RoundedRectangleBorder(borderRadius: CpShapes.card), child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [
                const Icon(Icons.group_outlined, size: 24), const SizedBox(width: 12),
                Text(l10n.currentTeam), const Spacer(),
                DropdownButton<int>(value: teamId, underline: const SizedBox.shrink(), items: List.generate(6, (i) => i + 1).map((id) => DropdownMenuItem(value: id, child: Text(localizedTeamName(id, l10n)))).toList(), onChanged: (id) { if (id != null) { ref.read(selectedTeamProvider.notifier).state = id; ref.read(homeProvider.notifier).refresh(); } }),
              ]))),
              const SizedBox(height: 12),
              _MenuItem(icon: Icons.calendar_month_outlined, title: l10n.leaveOptimizer, subtitle: l10n.leaveOptimizerDesc, onTap: () => context.push('/leave-optimizer')),
              const SizedBox(height: 8),
              _MenuItem(icon: Icons.people_outline, title: l10n.colleagueMode, subtitle: l10n.colleagueModeDesc, onTap: () => context.push('/colleague-mode')),
              const SizedBox(height: 8),
              _MenuItem(icon: Icons.payments_outlined, title: l10n.salaryPredictor, subtitle: l10n.salaryPredictorDesc, onTap: () => context.push('/salary-predictor')),
              const SizedBox(height: 8),
              Padding(padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4), child: Text(l10n.settingsTitle, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
              _MenuItem(icon: Icons.settings_outlined, title: l10n.shiftRule, subtitle: l10n.shiftRuleDesc, onTap: () => context.push('/shift-rule')),
              const SizedBox(height: 8),
              _MenuItem(icon: Icons.notifications_outlined, title: l10n.alarmSettings, subtitle: l10n.alarmSettingsDesc, onTap: () => context.push('/alarm-settings')),
              // Linux desktop: calendar ICS integration
              if (Platform.isLinux) ...[
                const SizedBox(height: 8),
                Padding(padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4), child: const Text('Linux', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
                _MenuItem(
                  icon: Icons.calendar_today,
                  title: 'Export ICS',
                  subtitle: 'Export schedule to ICS file',
                  onTap: () => _exportIcs(context, ref, settings),
                ),
                const SizedBox(height: 8),
                _MenuItem(
                  icon: Icons.open_in_new,
                  title: 'Open in Calendar',
                  subtitle: 'Open ICS with default calendar app',
                  onTap: () async {
                    final ok = await LinuxCalendarSync.openWithDefaultApp();
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(ok ? 'Opened calendar' : 'No ICS file found. Export first.')),
                    );
                  },
                ),
                const SizedBox(height: 8),
                const _SystemdTimerStatus(),
              ],
              const SizedBox(height: 24),
              Center(child: Text(l10n.versionInfo, style: Theme.of(context).textTheme.bodySmall)),
            ]),
          ),
        ),
      ),
    );
  }

  Future<void> _exportIcs(BuildContext context, WidgetRef ref, RuntimeShiftSettings settings) async {
    final teamId = ref.read(selectedTeamProvider);
    final count = await LinuxCalendarSync.sync(
      teamId: teamId,
      cycleLength: settings.shiftCycle.length,
      referenceDate: settings.referenceDate,
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(
        count > 0
            ? 'ICS exported ($count events) — Opening calendar...'
            : 'ICS export failed. Check FFI bridge.',
      )),
    );
    if (count > 0) await LinuxCalendarSync.openWithDefaultApp();
  }
}

/// Shows whether the banban systemd timer is active.
class _SystemdTimerStatus extends StatelessWidget {
  const _SystemdTimerStatus();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: LinuxCalendarSync.isSystemdTimerActive(),
      builder: (context, snapshot) {
        final active = snapshot.data ?? false;
        return _MenuItem(
          icon: active ? Icons.check_circle_outline : Icons.info_outline,
          title: active ? 'Auto-sync active' : 'Auto-sync not installed',
          subtitle: active
              ? 'Systemd timer is running'
              : 'Run \'banban install\' to set up',
          onTap: null,
        );
      },
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final VoidCallback? onTap;
  const _MenuItem({required this.icon, required this.title, required this.subtitle, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final child = Padding(padding: const EdgeInsets.all(16), child: Row(children: [
      Icon(icon, size: 22, color: theme.colorScheme.primary), const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: theme.textTheme.bodyLarge), Text(subtitle, style: theme.textTheme.bodySmall)])),
      if (onTap != null) Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant),
    ]));
    if (onTap == null) {
      return Card(shape: RoundedRectangleBorder(borderRadius: CpShapes.card), child: child);
    }
    return Card(shape: RoundedRectangleBorder(borderRadius: CpShapes.card), child: InkWell(onTap: onTap, borderRadius: CpShapes.card, child: child));
  }
}
