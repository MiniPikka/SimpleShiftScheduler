import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/shapes.dart';

class ToolsRow extends StatelessWidget {
  final VoidCallback? onLeaveOptimizer, onColleagueMode, onSalaryPredictor;
  final String leaveLabel, leaveDesc, colleagueLabel, colleagueDesc, salaryLabel, salaryDesc;

  const ToolsRow({
    super.key,
    this.onLeaveOptimizer, this.onColleagueMode, this.onSalaryPredictor,
    required this.leaveLabel, required this.leaveDesc,
    required this.colleagueLabel, required this.colleagueDesc,
    required this.salaryLabel, required this.salaryDesc,
  });

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(child: _ToolCard(icon: Icons.calendar_month_outlined, label: leaveLabel, description: leaveDesc, iconColor: shiftRest, onTap: onLeaveOptimizer ?? () {})),
      const SizedBox(width: 12),
      Expanded(child: _ToolCard(icon: Icons.people_outline, label: colleagueLabel, description: colleagueDesc, iconColor: shiftStudy, onTap: onColleagueMode ?? () {})),
      const SizedBox(width: 12),
      Expanded(child: _ToolCard(icon: Icons.payments_outlined, label: salaryLabel, description: salaryDesc, iconColor: shiftMorning, onTap: onSalaryPredictor ?? () {})),
    ]);
  }
}

class _ToolCard extends StatelessWidget {
  final IconData icon;
  final String label, description;
  final Color iconColor;
  final VoidCallback onTap;
  const _ToolCard({required this.icon, required this.label, required this.description, required this.iconColor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: CpShapes.card),
      child: InkWell(
        onTap: onTap, borderRadius: CpShapes.card,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 36, height: 36,
                decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                alignment: Alignment.center, child: Icon(icon, size: 20, color: iconColor)),
            const SizedBox(height: 8),
            Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(description, style: Theme.of(context).textTheme.bodySmall),
          ]),
        ),
      ),
    );
  }
}
