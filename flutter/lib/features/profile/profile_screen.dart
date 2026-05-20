import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/shapes.dart';
import '../../core/utils/l10n.dart';
import '../home/home_state.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final teamId = ref.watch(selectedTeamProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.profileTitle)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: CpSpacing.maxContentWidth),
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
              _MenuItem(icon: Icons.settings_outlined, title: l10n.shiftRule, subtitle: l10n.shiftRuleDesc, onTap: () {}),
              const SizedBox(height: 8),
              _MenuItem(icon: Icons.notifications_outlined, title: l10n.alarmSettings, subtitle: l10n.alarmSettingsDesc, onTap: () => context.push('/alarm-settings')),
              const SizedBox(height: 24),
              Center(child: Text(l10n.versionInfo, style: Theme.of(context).textTheme.bodySmall)),
            ]),
          ),
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final VoidCallback onTap;
  const _MenuItem({required this.icon, required this.title, required this.subtitle, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(shape: RoundedRectangleBorder(borderRadius: CpShapes.card), child: InkWell(onTap: onTap, borderRadius: CpShapes.card, child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [
      Icon(icon, size: 22, color: theme.colorScheme.primary), const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: theme.textTheme.bodyLarge), Text(subtitle, style: theme.textTheme.bodySmall)])),
      Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant),
    ]))));
  }
}
