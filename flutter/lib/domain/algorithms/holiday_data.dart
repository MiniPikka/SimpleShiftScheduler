// 中国法定节假日数据 — 优先走 Rust FFI（holiday-engine crate），失败回退纯 Dart。
// 2026 年数据来自国务院官方发布。
// 2027 年数据基于农历推算，标记"[待确认]"。
// 每年 11-12 月国务院发布下一年安排后更新此文件。

import '../bridge/ffi_bridge.dart';

class HolidayInfo {
  final DateTime date;
  final String? name;
  final bool isHoliday; // true=放假, false=调休上班

  const HolidayInfo({
    required this.date,
    this.name,
    required this.isHoliday,
  });
}

/// 中国法定节假日 Map（date → info）— 优先走 Rust FFI，失败回退纯 Dart。
Map<DateTime, HolidayInfo> getChinaHolidays() {
  // Try Rust FFI first
  final ffiResult = ffiGetHolidays();
  if (ffiResult != null && ffiResult['holidays'] != null) {
    final map = <DateTime, HolidayInfo>{};
    for (final entry in ffiResult['holidays']) {
      final date = DateTime.parse(entry['date'] as String);
      map[date] = HolidayInfo(
        date: date,
        name: entry['name'] as String?,
        isHoliday: entry['is_holiday'] as bool,
      );
    }
    return map;
  }

  final holidays = <HolidayInfo>[];

  // === 2026 Official Holidays (国办发明电〔2025〕) ===

  // 元旦: Jan 1
  holidays.add(HolidayInfo(
      date: DateTime(2026, 1, 1), name: '元旦', isHoliday: true));

  // 春节: Feb 15-21
  for (int d = 0; d < 7; d++) {
    holidays.add(HolidayInfo(
        date: DateTime(2026, 2, 15).add(Duration(days: d)),
        name: '春节',
        isHoliday: true));
  }
  // 调休上班
  holidays.add(HolidayInfo(
      date: DateTime(2026, 2, 14), name: '春节调休', isHoliday: false));
  holidays.add(HolidayInfo(
      date: DateTime(2026, 2, 28), name: '春节调休', isHoliday: false));

  // 清明节: Apr 5-6
  holidays.add(
      HolidayInfo(date: DateTime(2026, 4, 5), name: '清明节', isHoliday: true));
  holidays.add(
      HolidayInfo(date: DateTime(2026, 4, 6), name: '清明节', isHoliday: true));

  // 劳动节: May 1-5
  for (int d = 0; d < 5; d++) {
    holidays.add(HolidayInfo(
        date: DateTime(2026, 5, 1).add(Duration(days: d)),
        name: '劳动节',
        isHoliday: true));
  }
  holidays.add(HolidayInfo(
      date: DateTime(2026, 5, 9), name: '劳动节调休', isHoliday: false));

  // 端午节: Jun 19-21
  for (int d = 0; d < 3; d++) {
    holidays.add(HolidayInfo(
        date: DateTime(2026, 6, 19).add(Duration(days: d)),
        name: '端午节',
        isHoliday: true));
  }

  // 中秋节: Sep 25-27
  for (int d = 0; d < 3; d++) {
    holidays.add(HolidayInfo(
        date: DateTime(2026, 9, 25).add(Duration(days: d)),
        name: '中秋节',
        isHoliday: true));
  }

  // 国庆节: Oct 1-7
  for (int d = 0; d < 7; d++) {
    holidays.add(HolidayInfo(
        date: DateTime(2026, 10, 1).add(Duration(days: d)),
        name: '国庆节',
        isHoliday: true));
  }
  // 调休
  holidays.add(HolidayInfo(
      date: DateTime(2026, 9, 27), name: '国庆节调休', isHoliday: false));
  holidays.add(HolidayInfo(
      date: DateTime(2026, 10, 10), name: '国庆节调休', isHoliday: false));

  // === 2027 Estimated (待确认) ===

  // 元旦: Jan 1-3
  for (int d = 0; d < 3; d++) {
    holidays.add(HolidayInfo(
        date: DateTime(2027, 1, 1).add(Duration(days: d)),
        name: '元旦[待确认]',
        isHoliday: true));
  }

  // 春节: Feb 5-11
  for (int d = 0; d < 7; d++) {
    holidays.add(HolidayInfo(
        date: DateTime(2027, 2, 5).add(Duration(days: d)),
        name: '春节[待确认]',
        isHoliday: true));
  }
  holidays.add(HolidayInfo(
      date: DateTime(2027, 1, 31), name: '春节调休[待确认]', isHoliday: false));
  holidays.add(HolidayInfo(
      date: DateTime(2027, 2, 13), name: '春节调休[待确认]', isHoliday: false));

  // 清明节: Apr 5
  holidays.add(HolidayInfo(
      date: DateTime(2027, 4, 5), name: '清明节[待确认]', isHoliday: true));

  // 劳动节: May 1-5
  for (int d = 0; d < 5; d++) {
    holidays.add(HolidayInfo(
        date: DateTime(2027, 5, 1).add(Duration(days: d)),
        name: '劳动节[待确认]',
        isHoliday: true));
  }
  holidays.add(HolidayInfo(
      date: DateTime(2027, 5, 8), name: '劳动节调休[待确认]', isHoliday: false));

  return {for (final h in holidays) h.date: h};
}

bool isWeekend(DateTime date) {
  return date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
}

/// 是否为"自然休息日"（节假日或周末，且非调休工作日）
bool isNaturallyOff(DateTime date, Map<DateTime, HolidayInfo> holidays) {
  // Normalize to midnight: DateTime equality includes time component
  final d = DateTime(date.year, date.month, date.day);
  final info = holidays[d];
  if (info != null) return info.isHoliday;
  return isWeekend(date);
}
