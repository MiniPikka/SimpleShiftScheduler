import '../../domain/models/shift_type.dart';
import '../../domain/models/alarm_time.dart';
import '../../domain/models/alarm_settings.dart';
import '../../domain/algorithms/shift_calculator.dart';
import 'notification_service.dart';

/// 通知调度器
///
/// 根据倒班表 + 提醒设置，为未来 N 天调度通知。
/// 对应 Android 版的 CalendarSyncManager + CalendarEventManager 的调度逻辑。

/// 为未来 daysAhead 天调度班次提醒通知
///
/// 每次调用先取消全部旧通知，再重新调度。调用方负责在设置变更时触发。
Future<void> scheduleShiftNotifications({
  required AlarmSettings alarmSettings,
  required List<ShiftType> shiftCycle,
  required int teamPhaseOffset,
  DateTime? referenceDate,
  int daysAhead = 30,
}) async {
  // 取消全部旧通知
  await NotificationService.cancelAllShiftReminders();

  if (!alarmSettings.isAnyEnabled()) return;

  final today = DateTime.now();
  // 从今天开始：今天的提醒可能还没过，也应该调度
  final startOfToday = DateTime(today.year, today.month, today.day);

  for (int offset = 0; offset < daysAhead; offset++) {
    final date = startOfToday.add(Duration(days: offset));
    final shiftType = getShiftTypeForDate(
      date,
      teamPhaseOffset: teamPhaseOffset,
      customCycle: shiftCycle,
      referenceDate: referenceDate,
    );

    final alarmTime = alarmSettings.alarms[shiftType];
    if (alarmTime == null) continue;

    // 对于 NIGHT 班次，提醒事件日期前移一天
    // （夜班前一天晚上发车，如 5月13日夜班 → 5月12日提醒）
    final eventDate = shiftType == ShiftType.NIGHT ? date.subtract(const Duration(days: 1)) : date;

    final scheduledDate = DateTime(
      eventDate.year,
      eventDate.month,
      eventDate.day,
      alarmTime.hour,
      alarmTime.minute,
    );

    // 计算确定性通知 ID（与 Android 版 requestCode 策略一致）
    final daysSinceEpoch = date.difference(DateTime(1970, 1, 1)).inDays;
    final notificationId = (daysSinceEpoch * 10) + shiftType.index;

    await NotificationService.scheduleShiftReminder(
      id: notificationId,
      title: '${_shiftLabel(shiftType)}班提醒',
      body: '倒班助手 · ${_shiftLabel(shiftType)}班',
      scheduledDate: scheduledDate,
    );
  }
}

/// 班次类型对应的中文标签（通知中使用，无需 l10n 多语言）
String _shiftLabel(ShiftType type) {
  switch (type) {
    case ShiftType.MORNING:
      return '早';
    case ShiftType.AFTERNOON:
      return '中';
    case ShiftType.REST:
      return '休';
    case ShiftType.NIGHT:
      return '夜';
    case ShiftType.STUDY:
      return '学';
  }
}
