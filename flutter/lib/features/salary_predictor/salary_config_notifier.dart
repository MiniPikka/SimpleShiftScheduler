import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/shift_type.dart';
import '../../domain/models/salary_config.dart';
import '../../data/providers.dart';

/// 津贴配置 Provider — 从 Hive 加载 + 自动持久化
final salaryConfigProvider =
    NotifierProvider<SalaryConfigNotifier, SalaryConfig>(
  SalaryConfigNotifier.new,
);

class SalaryConfigNotifier extends Notifier<SalaryConfig> {
  @override
  SalaryConfig build() {
    // Listen for repo availability, then load saved config
    ref.listen(hiveRepoProvider, (prev, next) {
      next.whenData((repo) async {
        final saved = await repo.loadSalaryConfig();
        state = saved;
      });
    });
    return const SalaryConfig();
  }

  /// 更新某个班次的津贴金额（立即自动保存）
  Future<void> updatePremium(ShiftType type, double value) async {
    final newPremiums = Map<ShiftType, double>.from(state.shiftPremiums);
    newPremiums[type] = value;
    state = SalaryConfig(shiftPremiums: newPremiums);

    final repoAsync = ref.read(hiveRepoProvider);
    repoAsync.whenData((repo) async {
      await repo.saveSalaryConfig(state);
    });
  }
}
