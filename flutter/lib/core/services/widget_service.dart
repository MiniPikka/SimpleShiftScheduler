import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// 桌面小组件更新服务
///
/// 通过 MethodChannel 与原生 Android Widget 通信。
/// Dart → Kotlin: 发送班次数据 → SharedPreferences → Widget 更新

class WidgetService {
  static const _channel = MethodChannel('com.simpleshift.scheduler_cp/widget');

  /// 更新 Widget 显示数据
  static Future<void> update({
    required String shiftLabel,
    required String teamName,
    required String dateLabel,
    required String progressText,
    required String restText,
    required String tomorrowShiftLabel,
    required String shiftBadgeColor,
    required String tomorrowDotColor,
  }) async {
    try {
      await _channel.invokeMethod('updateWidget', {
        'shift_label': shiftLabel,
        'team_name': teamName,
        'date_label': dateLabel,
        'progress_text': progressText,
        'rest_text': restText,
        'tomorrow_shift_label': tomorrowShiftLabel,
        'shift_badge_color': shiftBadgeColor,
        'tomorrow_dot_color': tomorrowDotColor,
      });
    } catch (e) {
      debugPrint('WidgetService: update failed — $e');
    }
  }
}
