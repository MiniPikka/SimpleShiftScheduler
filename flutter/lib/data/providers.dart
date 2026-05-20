import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'repositories/settings_repository_hive.dart';

/// Hive 仓库 Provider（异步初始化）
final hiveRepoProvider = FutureProvider<HiveSettingsRepository>((ref) async {
  final repo = HiveSettingsRepository();
  await repo.init();
  return repo;
});
