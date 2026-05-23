// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => '倒班助手';

  @override
  String get homeTab => '首页';

  @override
  String get calendarTab => '日历';

  @override
  String get profileTab => '我的';

  @override
  String get greetingMorning => '早上好';

  @override
  String get greetingAfternoon => '下午好';

  @override
  String get greetingEvening => '晚上好';

  @override
  String get greetingNight => '夜班辛苦了';

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
  String get shiftMorningFull => '早班';

  @override
  String get shiftAfternoonFull => '中班';

  @override
  String get shiftRestFull => '休班';

  @override
  String get shiftNightFull => '夜班';

  @override
  String get shiftStudyFull => '学班';

  @override
  String get team1 => '一值';

  @override
  String get team2 => '二值';

  @override
  String get team3 => '三值';

  @override
  String get team4 => '四值';

  @override
  String get team5 => '五值';

  @override
  String get team6 => '六值';

  @override
  String get todayShift => '今日班次';

  @override
  String daysUntilRest(Object days) {
    return '距休 $days 天';
  }

  @override
  String get restDay => '休息日';

  @override
  String get tomorrowRest => '明天休息';

  @override
  String cycleProgress(Object current, Object total) {
    return '第 $current 天 · 共 $total 天';
  }

  @override
  String alarmTime(Object time) {
    return '⏰ $time';
  }

  @override
  String get monthlyWork => '本月上班';

  @override
  String get consecutiveWork => '连续上班';

  @override
  String get workloadEasy => '轻松';

  @override
  String get workloadModerate => '适中';

  @override
  String get workloadHard => '辛苦';

  @override
  String get statusNormal => '正常';

  @override
  String get statusWarning => '注意调节';

  @override
  String get statusRestNeeded => '该休息了';

  @override
  String get leaveOptimizer => '拼假神器';

  @override
  String get colleagueMode => '同事模式';

  @override
  String get salaryPredictor => '倒班津贴';

  @override
  String get leaveOptimizerDesc => '最佳请假方案';

  @override
  String get colleagueModeDesc => '共同休息日';

  @override
  String get salaryPredictorDesc => '本月收入';

  @override
  String get calendarTitle => '倒班日历';

  @override
  String get today => '今天';

  @override
  String get teamLabel => '班组：';

  @override
  String get weekSun => '日';

  @override
  String get weekMon => '一';

  @override
  String get weekTue => '二';

  @override
  String get weekWed => '三';

  @override
  String get weekThu => '四';

  @override
  String get weekFri => '五';

  @override
  String get weekSat => '六';

  @override
  String get statWork => '上班';

  @override
  String get statMorning => '早班';

  @override
  String get statAfternoon => '中班';

  @override
  String get statRest => '休班';

  @override
  String get statNight => '夜班';

  @override
  String get statStudy => '学习';

  @override
  String get profileTitle => '我的';

  @override
  String get currentTeam => '当前班组';

  @override
  String get settingsTitle => '设置';

  @override
  String get shiftRule => '倒班规则';

  @override
  String get shiftRuleDesc => '自定义周期和班次';

  @override
  String get alarmSettings => '提醒设置';

  @override
  String get alarmSettingsDesc => '班次提醒时间';

  @override
  String get alarmSettingsInfo =>
      '设置提醒时间后，系统会在对应班次日期发出通知提醒。夜班提醒会提前一天发出。建议在系统设置中允许通知权限以获得更好的提醒体验。';

  @override
  String get alarmNotSet => '未设置';

  @override
  String get leaveOptimizerExplain => '基于你的倒班表 + 法定节假日，找到最佳请假方案';

  @override
  String get maxLeave => '最多请假：';

  @override
  String get noLeavePlanFound => '当前倒班表下未找到高效请假方案，尝试增加请假天数';

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
    return '请假 $leaveDays 天 → 连休 $breakDays 天';
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
    return '含 $holidays';
  }

  @override
  String leaveDayCount(Object days) {
    return '请假$days天';
  }

  @override
  String leaveWeekendPlus(Object count) {
    return '周末+$count';
  }

  @override
  String get colleagueModeTitle => '同事模式';

  @override
  String get iam => '我是';

  @override
  String get heis => '他是';

  @override
  String get sameTeam => '你们是同一个班组，休息日完全一致';

  @override
  String get nextCommonRest => '下次同时休息';

  @override
  String get noCommonRest => '暂无';

  @override
  String daysUntil(Object days) {
    return '距今 $days 天';
  }

  @override
  String get next30days => '未来30天';

  @override
  String get next60days => '未来60天';

  @override
  String commonRestDaysList(Object count) {
    return '共同休息日（共 $count 次）';
  }

  @override
  String get noCommonRestFound => '在分析范围内未找到共同休息日';

  @override
  String dayCount(Object days) {
    return '$days天后';
  }

  @override
  String get statusToday => '今天';

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
    return '渲染失败: $error';
  }

  @override
  String shareSubject(Object teamA, Object teamB) {
    return '$teamA & $teamB 共同休息';
  }

  @override
  String dateRangeYearEnd(Object startDate, Object year) {
    return '$startDate — $year/12/31';
  }

  @override
  String get salaryTitle => '倒班津贴';

  @override
  String get premiumPerShift => '班次补贴（元/班）';

  @override
  String get monthlyPremium => '本月倒班津贴';

  @override
  String get whatIf => '假设分析';

  @override
  String get ifMore => '如果多上';

  @override
  String whatIfResult(Object amount) {
    return '→ 津贴 +¥$amount';
  }

  @override
  String get messageRest => '好好休息，享受属于你的时光';

  @override
  String get messageNight => '夜班辛苦了，注意保暖别着凉';

  @override
  String get messageRestToday => '今天是休息日，好好享受吧';

  @override
  String get messageRestTomorrow => '明天就休息了，再坚持一下';

  @override
  String get messageRestSoon => '休息日很快就到，撑住';

  @override
  String get messageConsecutive => '连续上班辛苦了，注意劳逸结合';

  @override
  String get messageDefault => '累了就歇会儿，休息日很快就到';

  @override
  String monthYearFormat(Object year, Object month) {
    return '$year年$month月';
  }

  @override
  String get saveAndGenerate => '保存并生成排班表';

  @override
  String get savedLabel => '已保存';

  @override
  String get discardChangesTitle => '放弃修改？';

  @override
  String get discardChangesMsg => '有未保存的修改，确定要离开吗？';

  @override
  String get continueEdit => '继续编辑';

  @override
  String get discard => '放弃';

  @override
  String get cycleLengthLabel => '周期长度';

  @override
  String get dayUnit => '天';

  @override
  String get preset42Day => '默认42天';

  @override
  String get preset7Day => '7天轮转';

  @override
  String get preset14Day => '14天轮转';

  @override
  String get clearAllLabel => '清空';

  @override
  String get addShiftLabel => '添加班次';

  @override
  String rotationSeqLabel(Object count) {
    return '轮转序列（$count 项）';
  }

  @override
  String get previewLabel => '预览';

  @override
  String get startDateLabel => '起始日期';

  @override
  String get defaultTeamLabel => '默认班组';

  @override
  String teamGapLabel(Object days) {
    return '班组间隔: $days 天';
  }

  @override
  String get yuanPerShift => '元/班';

  @override
  String get addAtLeastOne => '请添加至少一个班次';

  @override
  String get slogan => '倒班助手 · 你的智能排班管家';

  @override
  String analysisRange(Object range) {
    return '分析范围：$range';
  }

  @override
  String countTimes(Object count) {
    return '$count 次';
  }

  @override
  String get scanToDownload => '扫码下载倒班助手';

  @override
  String get versionInfo => '倒班助手 CP v1.0.0';
}
