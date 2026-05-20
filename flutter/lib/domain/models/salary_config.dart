import 'shift_type.dart';

/// 津贴配置 — 对应 Android 版 SalaryConfig.kt
class SalaryConfig {
  final Map<ShiftType, double> shiftPremiums;

  const SalaryConfig({this.shiftPremiums = const {}});
}
