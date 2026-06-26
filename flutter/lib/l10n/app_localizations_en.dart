// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Shift Mate';

  @override
  String get homeTab => 'Home';

  @override
  String get calendarTab => 'Calendar';

  @override
  String get profileTab => 'Me';

  @override
  String get greetingMorning => 'Good Morning';

  @override
  String get greetingAfternoon => 'Good Afternoon';

  @override
  String get greetingEvening => 'Good Evening';

  @override
  String get greetingNight => 'Night Shift Hero';

  @override
  String get shiftMorning => 'AM';

  @override
  String get shiftAfternoon => 'PM';

  @override
  String get shiftRest => 'Off';

  @override
  String get shiftNight => 'NT';

  @override
  String get shiftStudy => 'TR';

  @override
  String get shiftMorningFull => 'Morning';

  @override
  String get shiftAfternoonFull => 'Afternoon';

  @override
  String get shiftRestFull => 'Rest';

  @override
  String get shiftNightFull => 'Night';

  @override
  String get shiftStudyFull => 'Training';

  @override
  String get team1 => 'Shift A';

  @override
  String get team2 => 'Shift B';

  @override
  String get team3 => 'Shift C';

  @override
  String get team4 => 'Shift D';

  @override
  String get team5 => 'Shift E';

  @override
  String get team6 => 'Shift F';

  @override
  String get todayShift => 'Today\'s Shift';

  @override
  String daysUntilRest(Object days) {
    return '${days}d until rest';
  }

  @override
  String get restDay => 'Rest Day';

  @override
  String get tomorrowRest => 'Rest Tomorrow';

  @override
  String cycleProgress(Object current, Object total) {
    return 'Day $current / $total';
  }

  @override
  String alarmTime(Object time) {
    return '⏰ $time';
  }

  @override
  String get monthlyWork => 'Monthly Work';

  @override
  String get consecutiveWork => 'Consecutive';

  @override
  String get workloadEasy => 'Easy';

  @override
  String get workloadModerate => 'Fair';

  @override
  String get workloadHard => 'Hard';

  @override
  String get statusNormal => 'Normal';

  @override
  String get statusWarning => 'Take Care';

  @override
  String get statusRestNeeded => 'Rest Needed';

  @override
  String get leaveOptimizer => 'Leave Optimizer';

  @override
  String get colleagueMode => 'Colleague Mode';

  @override
  String get salaryPredictor => 'Shift Pay';

  @override
  String get leaveOptimizerDesc => 'Best leave plans';

  @override
  String get colleagueModeDesc => 'Common rest days';

  @override
  String get salaryPredictorDesc => 'Monthly pay';

  @override
  String get calendarTitle => 'Shift Calendar';

  @override
  String get today => 'Today';

  @override
  String get teamLabel => 'Team: ';

  @override
  String get weekSun => 'Sun';

  @override
  String get weekMon => 'Mon';

  @override
  String get weekTue => 'Tue';

  @override
  String get weekWed => 'Wed';

  @override
  String get weekThu => 'Thu';

  @override
  String get weekFri => 'Fri';

  @override
  String get weekSat => 'Sat';

  @override
  String get statWork => 'Work';

  @override
  String get statMorning => 'Morning';

  @override
  String get statAfternoon => 'Afternoon';

  @override
  String get statRest => 'Rest';

  @override
  String get statNight => 'Night';

  @override
  String get statStudy => 'Study';

  @override
  String get profileTitle => 'Me';

  @override
  String get currentTeam => 'Current Team';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get shiftRule => 'Shift Rules';

  @override
  String get shiftRuleDesc => 'Custom cycle & shifts';

  @override
  String get alarmSettings => 'Reminder';

  @override
  String get alarmSettingsDesc => 'Shift time alerts';

  @override
  String get alarmSettingsInfo =>
      'Set a reminder time and you\'ll receive a notification on each shift day. Night shift reminders are sent one day earlier. Allow notification permissions in system settings for the best experience.';

  @override
  String get alarmNotSet => 'Not set';

  @override
  String get leaveOptimizerExplain =>
      'Find the best leave plans based on your shift schedule and public holidays';

  @override
  String get maxLeave => 'Max leave: ';

  @override
  String get noLeavePlanFound =>
      'No efficient leave plan found. Try increasing the max leave days.';

  @override
  String leaveAnalyzeRange(
    Object startYear,
    Object startMonth,
    Object startDay,
    Object endYear,
  ) {
    return '$startMonth/$startDay/$startYear — 12/31/$endYear';
  }

  @override
  String leavePlanFormat(Object leaveDays, Object breakDays) {
    return '$leaveDays day(s) off → $breakDays day(s) break';
  }

  @override
  String leaveDateRange(
    Object startMonth,
    Object startDay,
    Object endMonth,
    Object endDay,
  ) {
    return '$startMonth/$startDay — $endMonth/$endDay';
  }

  @override
  String leaveWithHolidays(Object holidays) {
    return '+ $holidays';
  }

  @override
  String leaveDayCount(Object days) {
    return '${days}d off';
  }

  @override
  String leaveWeekendPlus(Object count) {
    return 'Weekend +$count';
  }

  @override
  String get colleagueModeTitle => 'Colleague Mode';

  @override
  String get iam => 'I am';

  @override
  String get heis => 'They are';

  @override
  String get sameTeam => 'You are on the same team. All rest days match.';

  @override
  String get nextCommonRest => 'Next Shared Rest';

  @override
  String get noCommonRest => 'None';

  @override
  String daysUntil(Object days) {
    return '$days days away';
  }

  @override
  String get next30days => 'Next 30 Days';

  @override
  String get next60days => 'Next 60 Days';

  @override
  String commonRestDaysList(Object count) {
    return 'Shared Rest Days ($count total)';
  }

  @override
  String get noCommonRestFound =>
      'No shared rest days found in the analysis range.';

  @override
  String dayCount(Object days) {
    return '${days}d later';
  }

  @override
  String get statusToday => 'Today';

  @override
  String fullDateFormat(Object year, Object month, Object day, Object weekday) {
    return '$weekday, $month/$day/$year';
  }

  @override
  String monthDay(Object month, Object day) {
    return '$month/$day';
  }

  @override
  String monthDayWeekday(Object month, Object day, Object weekday) {
    return '$month/$day $weekday';
  }

  @override
  String shareRenderError(Object error) {
    return 'Render failed: $error';
  }

  @override
  String shareSubject(Object teamA, Object teamB) {
    return '$teamA & $teamB Shared Rest';
  }

  @override
  String dateRangeYearEnd(Object startDate, Object year) {
    return '$startDate — $year/12/31';
  }

  @override
  String get salaryTitle => 'Shift Pay';

  @override
  String get premiumPerShift => 'Premium per shift (CNY)';

  @override
  String get monthlyPremium => 'Monthly Shift Pay';

  @override
  String get whatIf => 'What-if Analysis';

  @override
  String get ifMore => 'If extra';

  @override
  String whatIfResult(Object amount) {
    return '→ Pay +¥$amount';
  }

  @override
  String get messageRest => 'Enjoy your well-deserved rest';

  @override
  String get messageNight => 'Night shift warrior, stay warm';

  @override
  String get messageRestToday => 'It\'s a rest day, enjoy!';

  @override
  String get messageRestTomorrow => 'Rest day is tomorrow, hang in there';

  @override
  String get messageRestSoon => 'Rest day coming soon, keep going';

  @override
  String get messageConsecutive => 'Long stretch — take care of yourself';

  @override
  String get messageDefault => 'Take it easy, rest day will come';

  @override
  String monthYearFormat(Object year, Object month) {
    return '$month/$year';
  }

  @override
  String get saveAndGenerate => 'Save & Generate';

  @override
  String get savedLabel => 'Saved';

  @override
  String get discardChangesTitle => 'Discard changes?';

  @override
  String get discardChangesMsg => 'You have unsaved changes. Leave anyway?';

  @override
  String get continueEdit => 'Keep Editing';

  @override
  String get discard => 'Discard';

  @override
  String get cycleLengthLabel => 'Cycle Length';

  @override
  String get dayUnit => 'days';

  @override
  String get preset42Day => 'Default 42';

  @override
  String get preset7Day => '7-day';

  @override
  String get preset14Day => '14-day';

  @override
  String get clearAllLabel => 'Clear All';

  @override
  String get addShiftLabel => 'Add Shift';

  @override
  String rotationSeqLabel(Object count) {
    return 'Sequence ($count items)';
  }

  @override
  String get previewLabel => 'Preview';

  @override
  String get startDateLabel => 'Start Date';

  @override
  String get defaultTeamLabel => 'Default Team';

  @override
  String teamGapLabel(Object days) {
    return 'Team gap: $days days';
  }

  @override
  String get yuanPerShift => 'CNY/shift';

  @override
  String get addAtLeastOne => 'Add at least one shift';

  @override
  String get slogan => 'ShiftMate · Your Smart Shift Companion';

  @override
  String analysisRange(Object range) {
    return 'Analysis range: $range';
  }

  @override
  String countTimes(Object count) {
    return '$count time(s)';
  }

  @override
  String get scanToDownload => 'Scan to download ShiftMate';

  @override
  String get versionInfo => 'Shift Mate CP v1.0.0';

  @override
  String shiftRelayPredecessor(Object team) {
    return 'Close of $team';
  }

  @override
  String shiftRelaySuccessor(Object team) {
    return '$team closing you';
  }

  @override
  String shiftRelayStatus(Object shift) {
    return '$shift today';
  }
}
