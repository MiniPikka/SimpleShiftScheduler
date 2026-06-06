import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

/// 本地通知服务
///
/// 封装 flutter_local_notifications v21 API，提供初始化和调度能力。
/// 对应 Android 版的 Calendar Provider 提醒系统。

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static const androidChannelId = 'shift_reminders';
  static const androidChannelName = '倒班提醒';
  static const androidChannelDesc = '班次提醒通知';

  static FlutterLocalNotificationsPlugin get plugin => _plugin;

  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    tz_data.initializeTimeZones();

    InitializationSettings settings;
    if (Platform.isAndroid) {
      settings = const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      );
    } else if (Platform.isIOS) {
      settings = const InitializationSettings(
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      );
    } else {
      // Linux: uses DBus org.freedesktop.Notifications
      settings = const InitializationSettings(
        linux: LinuxInitializationSettings(defaultActionName: 'Open'),
      );
    }

    await _plugin.initialize(settings: settings);
  }

  /// 调度一个班次提醒通知
  ///
  /// [id] 确定性通知 ID（同一天同一通知会被覆盖）
  /// [scheduledDate] 提醒触发时间（本地时区）
  static Future<void> scheduleShiftReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    // 如果时间已过则不调度
    if (scheduledDate.isBefore(DateTime.now())) return;

    final tzDate = tz.TZDateTime.from(scheduledDate, tz.local);

    final androidDetails = AndroidNotificationDetails(
      androidChannelId,
      androidChannelName,
      channelDescription: androidChannelDesc,
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tzDate,
      notificationDetails:
          NotificationDetails(android: androidDetails, iOS: iosDetails),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: null,
    );
  }

  /// 取消指定的通知
  static Future<void> cancelShiftReminder(int id) async {
    await _plugin.cancel(id: id);
  }

  /// 取消全部待发送的通知
  static Future<void> cancelAllShiftReminders() async {
    await _plugin.cancelAll();
  }

  /// 查询待发送的通知数量
  static Future<int> pendingCount() async {
    final pending = await _plugin.pendingNotificationRequests();
    return pending.length;
  }
}
