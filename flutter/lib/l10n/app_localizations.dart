import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ja'),
    Locale('ko'),
    Locale('zh'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In zh, this message translates to:
  /// **'倒班助手'**
  String get appTitle;

  /// No description provided for @homeTab.
  ///
  /// In zh, this message translates to:
  /// **'首页'**
  String get homeTab;

  /// No description provided for @calendarTab.
  ///
  /// In zh, this message translates to:
  /// **'日历'**
  String get calendarTab;

  /// No description provided for @profileTab.
  ///
  /// In zh, this message translates to:
  /// **'我的'**
  String get profileTab;

  /// No description provided for @greetingMorning.
  ///
  /// In zh, this message translates to:
  /// **'早上好'**
  String get greetingMorning;

  /// No description provided for @greetingAfternoon.
  ///
  /// In zh, this message translates to:
  /// **'下午好'**
  String get greetingAfternoon;

  /// No description provided for @greetingEvening.
  ///
  /// In zh, this message translates to:
  /// **'晚上好'**
  String get greetingEvening;

  /// No description provided for @greetingNight.
  ///
  /// In zh, this message translates to:
  /// **'夜班辛苦了'**
  String get greetingNight;

  /// No description provided for @shiftMorning.
  ///
  /// In zh, this message translates to:
  /// **'早'**
  String get shiftMorning;

  /// No description provided for @shiftAfternoon.
  ///
  /// In zh, this message translates to:
  /// **'中'**
  String get shiftAfternoon;

  /// No description provided for @shiftRest.
  ///
  /// In zh, this message translates to:
  /// **'休'**
  String get shiftRest;

  /// No description provided for @shiftNight.
  ///
  /// In zh, this message translates to:
  /// **'夜'**
  String get shiftNight;

  /// No description provided for @shiftStudy.
  ///
  /// In zh, this message translates to:
  /// **'学'**
  String get shiftStudy;

  /// No description provided for @shiftMorningFull.
  ///
  /// In zh, this message translates to:
  /// **'早班'**
  String get shiftMorningFull;

  /// No description provided for @shiftAfternoonFull.
  ///
  /// In zh, this message translates to:
  /// **'中班'**
  String get shiftAfternoonFull;

  /// No description provided for @shiftRestFull.
  ///
  /// In zh, this message translates to:
  /// **'休班'**
  String get shiftRestFull;

  /// No description provided for @shiftNightFull.
  ///
  /// In zh, this message translates to:
  /// **'夜班'**
  String get shiftNightFull;

  /// No description provided for @shiftStudyFull.
  ///
  /// In zh, this message translates to:
  /// **'学班'**
  String get shiftStudyFull;

  /// No description provided for @team1.
  ///
  /// In zh, this message translates to:
  /// **'一值'**
  String get team1;

  /// No description provided for @team2.
  ///
  /// In zh, this message translates to:
  /// **'二值'**
  String get team2;

  /// No description provided for @team3.
  ///
  /// In zh, this message translates to:
  /// **'三值'**
  String get team3;

  /// No description provided for @team4.
  ///
  /// In zh, this message translates to:
  /// **'四值'**
  String get team4;

  /// No description provided for @team5.
  ///
  /// In zh, this message translates to:
  /// **'五值'**
  String get team5;

  /// No description provided for @team6.
  ///
  /// In zh, this message translates to:
  /// **'六值'**
  String get team6;

  /// No description provided for @todayShift.
  ///
  /// In zh, this message translates to:
  /// **'今日班次'**
  String get todayShift;

  /// No description provided for @daysUntilRest.
  ///
  /// In zh, this message translates to:
  /// **'距休 {days} 天'**
  String daysUntilRest(Object days);

  /// No description provided for @restDay.
  ///
  /// In zh, this message translates to:
  /// **'休息日'**
  String get restDay;

  /// No description provided for @tomorrowRest.
  ///
  /// In zh, this message translates to:
  /// **'明天休息'**
  String get tomorrowRest;

  /// No description provided for @cycleProgress.
  ///
  /// In zh, this message translates to:
  /// **'第 {current} 天 · 共 {total} 天'**
  String cycleProgress(Object current, Object total);

  /// No description provided for @alarmTime.
  ///
  /// In zh, this message translates to:
  /// **'⏰ {time}'**
  String alarmTime(Object time);

  /// No description provided for @monthlyWork.
  ///
  /// In zh, this message translates to:
  /// **'本月上班'**
  String get monthlyWork;

  /// No description provided for @consecutiveWork.
  ///
  /// In zh, this message translates to:
  /// **'连续上班'**
  String get consecutiveWork;

  /// No description provided for @workloadEasy.
  ///
  /// In zh, this message translates to:
  /// **'轻松'**
  String get workloadEasy;

  /// No description provided for @workloadModerate.
  ///
  /// In zh, this message translates to:
  /// **'适中'**
  String get workloadModerate;

  /// No description provided for @workloadHard.
  ///
  /// In zh, this message translates to:
  /// **'辛苦'**
  String get workloadHard;

  /// No description provided for @statusNormal.
  ///
  /// In zh, this message translates to:
  /// **'正常'**
  String get statusNormal;

  /// No description provided for @statusWarning.
  ///
  /// In zh, this message translates to:
  /// **'注意调节'**
  String get statusWarning;

  /// No description provided for @statusRestNeeded.
  ///
  /// In zh, this message translates to:
  /// **'该休息了'**
  String get statusRestNeeded;

  /// No description provided for @leaveOptimizer.
  ///
  /// In zh, this message translates to:
  /// **'拼假神器'**
  String get leaveOptimizer;

  /// No description provided for @colleagueMode.
  ///
  /// In zh, this message translates to:
  /// **'同事模式'**
  String get colleagueMode;

  /// No description provided for @salaryPredictor.
  ///
  /// In zh, this message translates to:
  /// **'倒班津贴'**
  String get salaryPredictor;

  /// No description provided for @leaveOptimizerDesc.
  ///
  /// In zh, this message translates to:
  /// **'最佳请假方案'**
  String get leaveOptimizerDesc;

  /// No description provided for @colleagueModeDesc.
  ///
  /// In zh, this message translates to:
  /// **'共同休息日'**
  String get colleagueModeDesc;

  /// No description provided for @salaryPredictorDesc.
  ///
  /// In zh, this message translates to:
  /// **'本月收入'**
  String get salaryPredictorDesc;

  /// No description provided for @calendarTitle.
  ///
  /// In zh, this message translates to:
  /// **'倒班日历'**
  String get calendarTitle;

  /// No description provided for @today.
  ///
  /// In zh, this message translates to:
  /// **'今天'**
  String get today;

  /// No description provided for @teamLabel.
  ///
  /// In zh, this message translates to:
  /// **'班组：'**
  String get teamLabel;

  /// No description provided for @weekSun.
  ///
  /// In zh, this message translates to:
  /// **'日'**
  String get weekSun;

  /// No description provided for @weekMon.
  ///
  /// In zh, this message translates to:
  /// **'一'**
  String get weekMon;

  /// No description provided for @weekTue.
  ///
  /// In zh, this message translates to:
  /// **'二'**
  String get weekTue;

  /// No description provided for @weekWed.
  ///
  /// In zh, this message translates to:
  /// **'三'**
  String get weekWed;

  /// No description provided for @weekThu.
  ///
  /// In zh, this message translates to:
  /// **'四'**
  String get weekThu;

  /// No description provided for @weekFri.
  ///
  /// In zh, this message translates to:
  /// **'五'**
  String get weekFri;

  /// No description provided for @weekSat.
  ///
  /// In zh, this message translates to:
  /// **'六'**
  String get weekSat;

  /// No description provided for @statWork.
  ///
  /// In zh, this message translates to:
  /// **'上班'**
  String get statWork;

  /// No description provided for @statMorning.
  ///
  /// In zh, this message translates to:
  /// **'早班'**
  String get statMorning;

  /// No description provided for @statAfternoon.
  ///
  /// In zh, this message translates to:
  /// **'中班'**
  String get statAfternoon;

  /// No description provided for @statRest.
  ///
  /// In zh, this message translates to:
  /// **'休班'**
  String get statRest;

  /// No description provided for @statNight.
  ///
  /// In zh, this message translates to:
  /// **'夜班'**
  String get statNight;

  /// No description provided for @statStudy.
  ///
  /// In zh, this message translates to:
  /// **'学习'**
  String get statStudy;

  /// No description provided for @profileTitle.
  ///
  /// In zh, this message translates to:
  /// **'我的'**
  String get profileTitle;

  /// No description provided for @currentTeam.
  ///
  /// In zh, this message translates to:
  /// **'当前班组'**
  String get currentTeam;

  /// No description provided for @settingsTitle.
  ///
  /// In zh, this message translates to:
  /// **'设置'**
  String get settingsTitle;

  /// No description provided for @shiftRule.
  ///
  /// In zh, this message translates to:
  /// **'倒班规则'**
  String get shiftRule;

  /// No description provided for @shiftRuleDesc.
  ///
  /// In zh, this message translates to:
  /// **'自定义周期和班次'**
  String get shiftRuleDesc;

  /// No description provided for @alarmSettings.
  ///
  /// In zh, this message translates to:
  /// **'提醒设置'**
  String get alarmSettings;

  /// No description provided for @alarmSettingsDesc.
  ///
  /// In zh, this message translates to:
  /// **'班次提醒时间'**
  String get alarmSettingsDesc;

  /// No description provided for @alarmSettingsInfo.
  ///
  /// In zh, this message translates to:
  /// **'设置提醒时间后，系统会在对应班次日期发出通知提醒。夜班提醒会提前一天发出。建议在系统设置中允许通知权限以获得更好的提醒体验。'**
  String get alarmSettingsInfo;

  /// No description provided for @alarmNotSet.
  ///
  /// In zh, this message translates to:
  /// **'未设置'**
  String get alarmNotSet;

  /// No description provided for @leaveOptimizerExplain.
  ///
  /// In zh, this message translates to:
  /// **'基于你的倒班表 + 法定节假日，找到最佳请假方案'**
  String get leaveOptimizerExplain;

  /// No description provided for @maxLeave.
  ///
  /// In zh, this message translates to:
  /// **'最多请假：'**
  String get maxLeave;

  /// No description provided for @noLeavePlanFound.
  ///
  /// In zh, this message translates to:
  /// **'当前倒班表下未找到高效请假方案，尝试增加请假天数'**
  String get noLeavePlanFound;

  /// No description provided for @colleagueModeTitle.
  ///
  /// In zh, this message translates to:
  /// **'同事模式'**
  String get colleagueModeTitle;

  /// No description provided for @iam.
  ///
  /// In zh, this message translates to:
  /// **'我是'**
  String get iam;

  /// No description provided for @heis.
  ///
  /// In zh, this message translates to:
  /// **'他是'**
  String get heis;

  /// No description provided for @sameTeam.
  ///
  /// In zh, this message translates to:
  /// **'你们是同一个班组，休息日完全一致'**
  String get sameTeam;

  /// No description provided for @nextCommonRest.
  ///
  /// In zh, this message translates to:
  /// **'下次同时休息'**
  String get nextCommonRest;

  /// No description provided for @noCommonRest.
  ///
  /// In zh, this message translates to:
  /// **'暂无'**
  String get noCommonRest;

  /// No description provided for @daysUntil.
  ///
  /// In zh, this message translates to:
  /// **'距今 {days} 天'**
  String daysUntil(Object days);

  /// No description provided for @next30days.
  ///
  /// In zh, this message translates to:
  /// **'未来30天'**
  String get next30days;

  /// No description provided for @next60days.
  ///
  /// In zh, this message translates to:
  /// **'未来60天'**
  String get next60days;

  /// No description provided for @commonRestDaysList.
  ///
  /// In zh, this message translates to:
  /// **'共同休息日（共 {count} 次）'**
  String commonRestDaysList(Object count);

  /// No description provided for @noCommonRestFound.
  ///
  /// In zh, this message translates to:
  /// **'在分析范围内未找到共同休息日'**
  String get noCommonRestFound;

  /// No description provided for @dayCount.
  ///
  /// In zh, this message translates to:
  /// **'{days}天后'**
  String dayCount(Object days);

  /// No description provided for @statusToday.
  ///
  /// In zh, this message translates to:
  /// **'今天'**
  String get statusToday;

  /// No description provided for @salaryTitle.
  ///
  /// In zh, this message translates to:
  /// **'倒班津贴'**
  String get salaryTitle;

  /// No description provided for @premiumPerShift.
  ///
  /// In zh, this message translates to:
  /// **'班次补贴（元/班）'**
  String get premiumPerShift;

  /// No description provided for @monthlyPremium.
  ///
  /// In zh, this message translates to:
  /// **'本月倒班津贴'**
  String get monthlyPremium;

  /// No description provided for @whatIf.
  ///
  /// In zh, this message translates to:
  /// **'假设分析'**
  String get whatIf;

  /// No description provided for @ifMore.
  ///
  /// In zh, this message translates to:
  /// **'如果多上'**
  String get ifMore;

  /// No description provided for @whatIfResult.
  ///
  /// In zh, this message translates to:
  /// **'→ 津贴 +¥{amount}'**
  String whatIfResult(Object amount);

  /// No description provided for @messageRest.
  ///
  /// In zh, this message translates to:
  /// **'好好休息，享受属于你的时光'**
  String get messageRest;

  /// No description provided for @messageNight.
  ///
  /// In zh, this message translates to:
  /// **'夜班辛苦了，注意保暖别着凉'**
  String get messageNight;

  /// No description provided for @messageRestToday.
  ///
  /// In zh, this message translates to:
  /// **'今天是休息日，好好享受吧'**
  String get messageRestToday;

  /// No description provided for @messageRestTomorrow.
  ///
  /// In zh, this message translates to:
  /// **'明天就休息了，再坚持一下'**
  String get messageRestTomorrow;

  /// No description provided for @messageRestSoon.
  ///
  /// In zh, this message translates to:
  /// **'休息日很快就到，撑住'**
  String get messageRestSoon;

  /// No description provided for @messageConsecutive.
  ///
  /// In zh, this message translates to:
  /// **'连续上班辛苦了，注意劳逸结合'**
  String get messageConsecutive;

  /// No description provided for @messageDefault.
  ///
  /// In zh, this message translates to:
  /// **'累了就歇会儿，休息日很快就到'**
  String get messageDefault;

  /// No description provided for @monthYearFormat.
  ///
  /// In zh, this message translates to:
  /// **'{year}年{month}月'**
  String monthYearFormat(Object year, Object month);

  /// No description provided for @saveAndGenerate.
  ///
  /// In zh, this message translates to:
  /// **'保存并生成排班表'**
  String get saveAndGenerate;

  /// No description provided for @savedLabel.
  ///
  /// In zh, this message translates to:
  /// **'已保存'**
  String get savedLabel;

  /// No description provided for @discardChangesTitle.
  ///
  /// In zh, this message translates to:
  /// **'放弃修改？'**
  String get discardChangesTitle;

  /// No description provided for @discardChangesMsg.
  ///
  /// In zh, this message translates to:
  /// **'有未保存的修改，确定要离开吗？'**
  String get discardChangesMsg;

  /// No description provided for @continueEdit.
  ///
  /// In zh, this message translates to:
  /// **'继续编辑'**
  String get continueEdit;

  /// No description provided for @discard.
  ///
  /// In zh, this message translates to:
  /// **'放弃'**
  String get discard;

  /// No description provided for @cycleLengthLabel.
  ///
  /// In zh, this message translates to:
  /// **'周期长度'**
  String get cycleLengthLabel;

  /// No description provided for @dayUnit.
  ///
  /// In zh, this message translates to:
  /// **'天'**
  String get dayUnit;

  /// No description provided for @preset42Day.
  ///
  /// In zh, this message translates to:
  /// **'默认42天'**
  String get preset42Day;

  /// No description provided for @preset7Day.
  ///
  /// In zh, this message translates to:
  /// **'7天轮转'**
  String get preset7Day;

  /// No description provided for @preset14Day.
  ///
  /// In zh, this message translates to:
  /// **'14天轮转'**
  String get preset14Day;

  /// No description provided for @clearAllLabel.
  ///
  /// In zh, this message translates to:
  /// **'清空'**
  String get clearAllLabel;

  /// No description provided for @addShiftLabel.
  ///
  /// In zh, this message translates to:
  /// **'添加班次'**
  String get addShiftLabel;

  /// No description provided for @rotationSeqLabel.
  ///
  /// In zh, this message translates to:
  /// **'轮转序列（{count} 项）'**
  String rotationSeqLabel(Object count);

  /// No description provided for @previewLabel.
  ///
  /// In zh, this message translates to:
  /// **'预览'**
  String get previewLabel;

  /// No description provided for @startDateLabel.
  ///
  /// In zh, this message translates to:
  /// **'起始日期'**
  String get startDateLabel;

  /// No description provided for @defaultTeamLabel.
  ///
  /// In zh, this message translates to:
  /// **'默认班组'**
  String get defaultTeamLabel;

  /// No description provided for @teamGapLabel.
  ///
  /// In zh, this message translates to:
  /// **'班组间隔: {days} 天'**
  String teamGapLabel(Object days);

  /// No description provided for @yuanPerShift.
  ///
  /// In zh, this message translates to:
  /// **'元/班'**
  String get yuanPerShift;

  /// No description provided for @addAtLeastOne.
  ///
  /// In zh, this message translates to:
  /// **'请添加至少一个班次'**
  String get addAtLeastOne;

  /// No description provided for @versionInfo.
  ///
  /// In zh, this message translates to:
  /// **'倒班助手 CP v1.0.0'**
  String get versionInfo;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ja', 'ko', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
