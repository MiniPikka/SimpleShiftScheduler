// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => '倒班アシスト';

  @override
  String get homeTab => 'ホーム';

  @override
  String get calendarTab => 'カレンダー';

  @override
  String get profileTab => 'マイ';

  @override
  String get greetingMorning => 'おはようございます';

  @override
  String get greetingAfternoon => 'こんにちは';

  @override
  String get greetingEvening => 'こんばんは';

  @override
  String get greetingNight => '夜勤お疲れ様です';

  @override
  String get shiftMorning => '早';

  @override
  String get shiftAfternoon => '中';

  @override
  String get shiftRest => '休';

  @override
  String get shiftNight => '夜';

  @override
  String get shiftStudy => '学';

  @override
  String get shiftMorningFull => '早番';

  @override
  String get shiftAfternoonFull => '中番';

  @override
  String get shiftRestFull => '休番';

  @override
  String get shiftNightFull => '夜番';

  @override
  String get shiftStudyFull => '研修';

  @override
  String get team1 => '1直';

  @override
  String get team2 => '2直';

  @override
  String get team3 => '3直';

  @override
  String get team4 => '4直';

  @override
  String get team5 => '5直';

  @override
  String get team6 => '6直';

  @override
  String get todayShift => '本日のシフト';

  @override
  String daysUntilRest(Object days) {
    return '休みまで $days 日';
  }

  @override
  String get restDay => '休日';

  @override
  String get tomorrowRest => '明日休み';

  @override
  String cycleProgress(Object current, Object total) {
    return '$current 日目 / 全 $total 日';
  }

  @override
  String alarmTime(Object time) {
    return '⏰ $time';
  }

  @override
  String get monthlyWork => '今月の勤務';

  @override
  String get consecutiveWork => '連続勤務';

  @override
  String get workloadEasy => '余裕';

  @override
  String get workloadModerate => '適度';

  @override
  String get workloadHard => '多忙';

  @override
  String get statusNormal => '正常';

  @override
  String get statusWarning => '要注意';

  @override
  String get statusRestNeeded => '休息必要';

  @override
  String get leaveOptimizer => '休暇最適化';

  @override
  String get colleagueMode => '同僚モード';

  @override
  String get salaryPredictor => 'シフト手当';

  @override
  String get leaveOptimizerDesc => '最適な休暇プラン';

  @override
  String get colleagueModeDesc => '共通休日';

  @override
  String get salaryPredictorDesc => '今月の収入';

  @override
  String get calendarTitle => 'シフトカレンダー';

  @override
  String get today => '今日';

  @override
  String get teamLabel => 'チーム：';

  @override
  String get weekSun => '日';

  @override
  String get weekMon => '月';

  @override
  String get weekTue => '火';

  @override
  String get weekWed => '水';

  @override
  String get weekThu => '木';

  @override
  String get weekFri => '金';

  @override
  String get weekSat => '土';

  @override
  String get statWork => '勤務';

  @override
  String get statMorning => '早番';

  @override
  String get statAfternoon => '中番';

  @override
  String get statRest => '休み';

  @override
  String get statNight => '夜勤';

  @override
  String get statStudy => '研修';

  @override
  String get profileTitle => 'マイ';

  @override
  String get currentTeam => '現在のチーム';

  @override
  String get settingsTitle => '設定';

  @override
  String get shiftRule => 'シフトルール';

  @override
  String get shiftRuleDesc => 'カスタムサイクル';

  @override
  String get alarmSettings => 'リマインダー';

  @override
  String get alarmSettingsDesc => 'シフト通知時刻';

  @override
  String get alarmSettingsInfo =>
      'リマインダー時間を設定すると、各シフト日に通知が届きます。夜勤の通知は1日前に送信されます。システム設定で通知を許可してください。';

  @override
  String get alarmNotSet => '未設定';

  @override
  String get leaveOptimizerExplain => 'シフト表と祝日に基づいて最適な休暇プランを見つける';

  @override
  String get maxLeave => '最大休暇：';

  @override
  String get noLeavePlanFound => '効率的な休暇プランが見つかりません。最大休暇日数を増やしてみてください。';

  @override
  String leaveAnalyzeRange(
    Object startYear,
    Object startMonth,
    Object startDay,
    Object endYear,
  ) {
    return '$startYear年$startMonth月$startDay日 — $endYear年12月31日';
  }

  @override
  String leavePlanFormat(Object leaveDays, Object breakDays) {
    return '$leaveDays日休 → $breakDays日連休';
  }

  @override
  String leaveDateRange(
    Object startMonth,
    Object startDay,
    Object endMonth,
    Object endDay,
  ) {
    return '$startMonth月$startDay日 — $endMonth月$endDay日';
  }

  @override
  String leaveWithHolidays(Object holidays) {
    return '$holidays 含む';
  }

  @override
  String leaveDayCount(Object days) {
    return '$days日休';
  }

  @override
  String leaveWeekendPlus(Object count) {
    return '週末+$count';
  }

  @override
  String get colleagueModeTitle => '同僚モード';

  @override
  String get iam => '自分';

  @override
  String get heis => '相手';

  @override
  String get sameTeam => '同じチームです。休日は完全に一致します。';

  @override
  String get nextCommonRest => '次の共通休日';

  @override
  String get noCommonRest => 'なし';

  @override
  String daysUntil(Object days) {
    return 'あと $days 日';
  }

  @override
  String get next30days => '30日以内';

  @override
  String get next60days => '60日以内';

  @override
  String commonRestDaysList(Object count) {
    return '共通休日（計 $count 回）';
  }

  @override
  String get noCommonRestFound => '分析範囲内に共通休日が見つかりません。';

  @override
  String dayCount(Object days) {
    return '$days日後';
  }

  @override
  String get statusToday => '今日';

  @override
  String fullDateFormat(Object year, Object month, Object day, Object weekday) {
    return '$year年$month月$day日 $weekday';
  }

  @override
  String monthDay(Object month, Object day) {
    return '$month月$day日';
  }

  @override
  String monthDayWeekday(Object month, Object day, Object weekday) {
    return '$month月$day日 $weekday';
  }

  @override
  String shareRenderError(Object error) {
    return 'レンダリング失敗: $error';
  }

  @override
  String shareSubject(Object teamA, Object teamB) {
    return '$teamA & $teamB 共通休日';
  }

  @override
  String dateRangeYearEnd(Object startDate, Object year) {
    return '$startDate — $year/12/31';
  }

  @override
  String get salaryTitle => 'シフト手当';

  @override
  String get premiumPerShift => 'シフト別手当（元）';

  @override
  String get monthlyPremium => '今月のシフト手当';

  @override
  String get whatIf => 'シミュレーション';

  @override
  String get ifMore => '追加で';

  @override
  String whatIfResult(Object amount) {
    return '→ 手当 +¥$amount';
  }

  @override
  String get messageRest => 'ゆっくり休んでください';

  @override
  String get messageNight => '夜勤お疲れ様、暖かくしてね';

  @override
  String get messageRestToday => '今日は休日です、楽しんで！';

  @override
  String get messageRestTomorrow => '明日は休み、もう少しです';

  @override
  String get messageRestSoon => 'もうすぐ休み、がんばって';

  @override
  String get messageConsecutive => '連続勤務お疲れ様、体調に気をつけて';

  @override
  String get messageDefault => '無理せず、もうすぐ休みです';

  @override
  String monthYearFormat(Object year, Object month) {
    return '$year年$month月';
  }

  @override
  String get saveAndGenerate => '保存して生成';

  @override
  String get savedLabel => '保存済み';

  @override
  String get discardChangesTitle => '変更を破棄しますか？';

  @override
  String get discardChangesMsg => '保存されていない変更があります。本当に終了しますか？';

  @override
  String get continueEdit => '編集を続ける';

  @override
  String get discard => '破棄';

  @override
  String get cycleLengthLabel => 'サイクル長';

  @override
  String get dayUnit => '日';

  @override
  String get preset42Day => 'デフォルト42日';

  @override
  String get preset7Day => '7日ローテ';

  @override
  String get preset14Day => '14日ローテ';

  @override
  String get clearAllLabel => 'クリア';

  @override
  String get addShiftLabel => 'シフト追加';

  @override
  String rotationSeqLabel(Object count) {
    return 'ローテーション（$count 項目）';
  }

  @override
  String get previewLabel => 'プレビュー';

  @override
  String get startDateLabel => '開始日';

  @override
  String get defaultTeamLabel => 'デフォルトチーム';

  @override
  String teamGapLabel(Object days) {
    return 'チーム間隔: $days 日';
  }

  @override
  String get yuanPerShift => '元/シフト';

  @override
  String get addAtLeastOne => '少なくとも1つのシフトを追加してください';

  @override
  String get slogan => 'ShiftMate · スマートシフト管理';

  @override
  String analysisRange(Object range) {
    return '分析範囲：$range';
  }

  @override
  String countTimes(Object count) {
    return '$count 回';
  }

  @override
  String get scanToDownload => 'スキャンしてダウンロード';

  @override
  String get versionInfo => '倒班アシスト CP v1.0.0';
}
