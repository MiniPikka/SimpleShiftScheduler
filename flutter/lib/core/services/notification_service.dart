import 'package:flutter/foundation.dart';

/// 本地通知服务
///
/// flutter_local_notifications ^21.0.0 API 有破坏性变更。
/// 完整实现需要在真机测试时适配具体 API。
/// 参考: https://pub.dev/packages/flutter_local_notifications

class NotificationService {
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    debugPrint('NotificationService: stub initialized');
    // TODO: 真机测试时适配 flutter_local_notifications v21 API
  }

  static Future<void> show({
    required int id,
    required String title,
    required String body,
  }) async {
    debugPrint('NotificationService: [$id] $title - $body');
    // TODO: 实现实际通知
  }
}
