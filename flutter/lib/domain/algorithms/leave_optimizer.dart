import '../models/leave_strategy.dart';
import '../models/shift_cycle_config.dart';
import '../models/shift_type.dart';
import 'shift_calculator.dart';
import 'holiday_data.dart';

// ── Internal day status ──

class DayStatus {
  final DateTime date;
  final bool isRest;
  final bool isHoliday;
  final bool isWeekend;
  final bool isAdjustedWorkDay;
  final String? holidayName;

  const DayStatus({
    required this.date,
    required this.isRest,
    required this.isHoliday,
    required this.isWeekend,
    required this.isAdjustedWorkDay,
    this.holidayName,
  });

  bool get isOff =>
      isRest ||
      (isHoliday && !isAdjustedWorkDay) ||
      (isWeekend && !isAdjustedWorkDay);
}

// ── Internal helpers ──

List<DayStatus> buildDailyStatus({
  required DateTime startDate,
  required int days,
  int teamPhaseOffset = 0,
  List<ShiftType>? customCycle,
  DateTime? referenceDate,
  required Map<DateTime, HolidayInfo> holidays,
}) {
  return List.generate(days, (offset) {
    final date = startDate.add(Duration(days: offset));
    final shiftType = getShiftTypeForDate(
      date,
      teamPhaseOffset: teamPhaseOffset,
      customCycle: customCycle,
      referenceDate: referenceDate,
    );
    final isRest =
        shiftType == ShiftType.REST || shiftType == ShiftType.STUDY;
    final holidayInfo = holidays[date];
    final isHoliday = holidayInfo?.isHoliday == true;
    final isAdjustedWorkDay =
        holidayInfo != null && !holidayInfo.isHoliday;

    return DayStatus(
      date: date,
      isRest: isRest,
      isHoliday: isHoliday,
      isWeekend: isWeekend(date),
      isAdjustedWorkDay: isAdjustedWorkDay,
      holidayName: isHoliday ? holidayInfo?.name : null,
    );
  });
}

// ── Public API ──

/// 间隙桥接法：查找最佳请假方案 — 对应 Android 版 findBestLeavePlans()
List<LeaveStrategy> findBestLeavePlans({
  DateTime? today,
  int daysToAnalyze = 365,
  int teamPhaseOffset = 0,
  List<ShiftType>? customCycle,
  DateTime? referenceDate,
  Map<DateTime, HolidayInfo>? holidays,
  int maxLeaveDays = 5,
}) {
  if (daysToAnalyze < 1 || maxLeaveDays < 1) return [];

  final raw = today ?? DateTime.now();
  // Normalize to midnight: DateTime(2026, 6, 19, 0, 0, 0) matches holiday map keys
  final t = DateTime(raw.year, raw.month, raw.day);
  final ref = referenceDate ?? ShiftCycleConfig.referenceDate;
  final hols = holidays ?? getChinaHolidays();

  final status = buildDailyStatus(
    startDate: t,
    days: daysToAnalyze,
    teamPhaseOffset: teamPhaseOffset,
    customCycle: customCycle,
    referenceDate: ref,
    holidays: hols,
  );

  final n = status.length;

  // Precompute consecutive rest before/after each index
  final restBefore = List.filled(n, 0);
  final restAfter = List.filled(n, 0);

  for (int i = 1; i < n; i++) {
    restBefore[i] = status[i - 1].isOff ? restBefore[i - 1] + 1 : 0;
  }
  for (int i = n - 2; i >= 0; i--) {
    restAfter[i] = status[i + 1].isOff ? restAfter[i + 1] + 1 : 0;
  }

  final strategies = <LeaveStrategy>[];

  // Start from 2: single-day leave is trivial (user doesn't need the app for that).
  // Unless maxLeaveDays == 1 (user explicitly filtered to 1).
  final minLeaveDays = maxLeaveDays == 1 ? 1 : 2;
  for (int leaveDays = minLeaveDays; leaveDays <= maxLeaveDays; leaveDays++) {
    for (int startIdx = 0; startIdx <= n - leaveDays; startIdx++) {
      // All leave days must be work days (only exclude shift rest/study, not weekends)
      // Weekends and holidays are naturally off but can be bridged without leave
      var anyRest = false;
      for (int j = 0; j < leaveDays; j++) {
        if (status[startIdx + j].isRest) {
          anyRest = true;
          break;
        }
      }
      if (anyRest) continue;

      final leftRest = restBefore[startIdx];
      final rightRest = restAfter[startIdx + leaveDays - 1];

      final totalBreak = leftRest + leaveDays + rightRest;
      if (totalBreak <= leaveDays) continue;

      final gapStart = startIdx - leftRest;
      final gapEnd = startIdx + leaveDays - 1 + rightRest;

      final breakStartDate = status[gapStart].date;
      final breakEndDate = status[gapEnd].date;

      // Calculate family overlap
      int holidayOverlap = 0;
      int weekendOverlap = 0;
      final holidayNames = <String>{};

      for (int idx = gapStart; idx <= gapEnd; idx++) {
        final ds = status[idx];
        if (ds.isHoliday) {
          holidayOverlap++;
          if (ds.holidayName != null) holidayNames.add(ds.holidayName!);
        }
        if (ds.isWeekend && !ds.isAdjustedWorkDay) {
          weekendOverlap++;
        }
      }

      final leaveDateList = List.generate(
          leaveDays, (j) => status[startIdx + j].date);

      final efficiency = totalBreak / leaveDays;

      strategies.add(LeaveStrategy(
        leaveDays: leaveDays,
        totalBreakDays: totalBreak,
        leaveDates: leaveDateList,
        breakStart: breakStartDate,
        breakEnd: breakEndDate,
        holidayOverlap: holidayOverlap,
        weekendOverlap: weekendOverlap,
        overlappingHolidayNames: holidayNames.toList(),
        efficiency: efficiency,
        score: 0,
      ));
    }
  }

  // Deduplicate: same (breakStart, breakEnd) → keep fewest leave days
  final deduped = <String, LeaveStrategy>{};
  for (final s in strategies) {
    final key = '${s.breakStart}_${s.breakEnd}';
    if (!deduped.containsKey(key) || deduped[key]!.leaveDays > s.leaveDays) {
      deduped[key] = s;
    }
  }
  if (deduped.isEmpty) return [];

  final dedupedList = deduped.values.toList();

  // Compute scores
  final maxEfficiency = dedupedList
      .map((s) => s.efficiency)
      .reduce((a, b) => a > b ? a : b);
  final maxBreak = dedupedList
      .map((s) => s.totalBreakDays)
      .reduce((a, b) => a > b ? a : b);
  final maxFamilyBonus = dedupedList
      .map((s) => s.holidayOverlap * 2 + s.weekendOverlap)
      .reduce((a, b) => a > b ? a : b)
      .clamp(1, 999);

  final scored = dedupedList.map((strategy) {
    final effScore = maxEfficiency > 0 ? strategy.efficiency / maxEfficiency : 0.0;
    final lenScore = maxBreak > 0 ? strategy.totalBreakDays / maxBreak : 0.0;
    final familyBonus = strategy.holidayOverlap * 2 + strategy.weekendOverlap;
    final famScore = familyBonus / maxFamilyBonus;
    final score = 0.50 * effScore + 0.25 * lenScore + 0.25 * famScore;
    return LeaveStrategy(
      leaveDays: strategy.leaveDays,
      totalBreakDays: strategy.totalBreakDays,
      leaveDates: strategy.leaveDates,
      breakStart: strategy.breakStart,
      breakEnd: strategy.breakEnd,
      holidayOverlap: strategy.holidayOverlap,
      weekendOverlap: strategy.weekendOverlap,
      overlappingHolidayNames: strategy.overlappingHolidayNames,
      efficiency: strategy.efficiency,
      score: score,
    );
  }).toList();

  scored.sort((a, b) => b.score.compareTo(a.score));
  return scored;
}
