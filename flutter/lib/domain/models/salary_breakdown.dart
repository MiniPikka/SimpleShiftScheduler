import 'shift_type.dart';

/// 津贴明细 — 对应 Android 版 SalaryBreakdown.kt
class SalaryBreakdown {
  final int year;
  final int month; // 1..12
  final Map<ShiftType, int> shiftCounts;
  final double shiftPremiumTotal;

  const SalaryBreakdown({
    required this.year,
    required this.month,
    required this.shiftCounts,
    required this.shiftPremiumTotal,
  });
}
