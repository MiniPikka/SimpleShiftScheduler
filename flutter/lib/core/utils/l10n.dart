import 'package:flutter/material.dart';
import '../../domain/models/shift_type.dart';
import '../../l10n/app_localizations.dart';

/// 统一本地化辅助层
///
/// 封装所有需要 Context 的本地化调用，保持 domain 层纯函数。
/// 对应 Android 版的 ShiftLabelMapper / TeamNameMapper / HolidayNameMapper。

// ── 辅助函数 ──

String localizedGreeting(int hour, AppLocalizations l10n) {
  if (hour >= 5 && hour < 12) return l10n.greetingMorning;
  if (hour >= 12 && hour < 18) return l10n.greetingAfternoon;
  if (hour >= 18 && hour < 23) return l10n.greetingEvening;
  return l10n.greetingNight;
}

String localizedShiftLabel(ShiftType type, AppLocalizations l10n) {
  switch (type) {
    case ShiftType.MORNING:
      return l10n.shiftMorning;
    case ShiftType.AFTERNOON:
      return l10n.shiftAfternoon;
    case ShiftType.REST:
      return l10n.shiftRest;
    case ShiftType.NIGHT:
      return l10n.shiftNight;
    case ShiftType.STUDY:
      return l10n.shiftStudy;
  }
}

String localizedShiftFullLabel(ShiftType type, AppLocalizations l10n) {
  switch (type) {
    case ShiftType.MORNING:
      return l10n.shiftMorningFull;
    case ShiftType.AFTERNOON:
      return l10n.shiftAfternoonFull;
    case ShiftType.REST:
      return l10n.shiftRestFull;
    case ShiftType.NIGHT:
      return l10n.shiftNightFull;
    case ShiftType.STUDY:
      return l10n.shiftStudyFull;
  }
}

String localizedTeamName(int teamId, AppLocalizations l10n) {
  switch (teamId) {
    case 1: return l10n.team1;
    case 2: return l10n.team2;
    case 3: return l10n.team3;
    case 4: return l10n.team4;
    case 5: return l10n.team5;
    case 6: return l10n.team6;
    default: return '$teamId';
  }
}

String localizedWeekday(int weekday, AppLocalizations l10n) {
  switch (weekday) {
    case DateTime.sunday: return l10n.weekSun;
    case DateTime.monday: return l10n.weekMon;
    case DateTime.tuesday: return l10n.weekTue;
    case DateTime.wednesday: return l10n.weekWed;
    case DateTime.thursday: return l10n.weekThu;
    case DateTime.friday: return l10n.weekFri;
    case DateTime.saturday: return l10n.weekSat;
    default: return '';
  }
}

// ── BuildContext 快捷扩展 ──

extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
