// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => '교대 도우미';

  @override
  String get homeTab => '홈';

  @override
  String get calendarTab => '달력';

  @override
  String get profileTab => 'MY';

  @override
  String get greetingMorning => '좋은 아침입니다';

  @override
  String get greetingAfternoon => '좋은 오후입니다';

  @override
  String get greetingEvening => '좋은 저녁입니다';

  @override
  String get greetingNight => '야간 근무 수고하세요';

  @override
  String get shiftMorning => '조';

  @override
  String get shiftAfternoon => '중';

  @override
  String get shiftRest => '휴';

  @override
  String get shiftNight => '야';

  @override
  String get shiftStudy => '학';

  @override
  String get shiftMorningFull => '조번';

  @override
  String get shiftAfternoonFull => '중번';

  @override
  String get shiftRestFull => '휴번';

  @override
  String get shiftNightFull => '야번';

  @override
  String get shiftStudyFull => '연수';

  @override
  String get team1 => '1조';

  @override
  String get team2 => '2조';

  @override
  String get team3 => '3조';

  @override
  String get team4 => '4조';

  @override
  String get team5 => '5조';

  @override
  String get team6 => '6조';

  @override
  String get todayShift => '오늘 근무';

  @override
  String daysUntilRest(Object days) {
    return '휴식까지 $days일';
  }

  @override
  String get restDay => '휴일';

  @override
  String get tomorrowRest => '내일 휴식';

  @override
  String cycleProgress(Object current, Object total) {
    return '$current일차 / 총 $total일';
  }

  @override
  String alarmTime(Object time) {
    return '⏰ $time';
  }

  @override
  String get monthlyWork => '이번달 근무';

  @override
  String get consecutiveWork => '연속 근무';

  @override
  String get workloadEasy => '여유';

  @override
  String get workloadModerate => '적당';

  @override
  String get workloadHard => '힘듦';

  @override
  String get statusNormal => '정상';

  @override
  String get statusWarning => '주의';

  @override
  String get statusRestNeeded => '휴식필요';

  @override
  String get leaveOptimizer => '휴가 플래너';

  @override
  String get colleagueMode => '동료 모드';

  @override
  String get salaryPredictor => '근무 수당';

  @override
  String get leaveOptimizerDesc => '최적의 휴가 계획';

  @override
  String get colleagueModeDesc => '공동 휴일';

  @override
  String get salaryPredictorDesc => '이번달 수입';

  @override
  String get calendarTitle => '근무 달력';

  @override
  String get today => '오늘';

  @override
  String get teamLabel => '팀: ';

  @override
  String get weekSun => '일';

  @override
  String get weekMon => '월';

  @override
  String get weekTue => '화';

  @override
  String get weekWed => '수';

  @override
  String get weekThu => '목';

  @override
  String get weekFri => '금';

  @override
  String get weekSat => '토';

  @override
  String get statWork => '근무';

  @override
  String get statMorning => '조번';

  @override
  String get statAfternoon => '중번';

  @override
  String get statRest => '휴식';

  @override
  String get statNight => '야간';

  @override
  String get statStudy => '연수';

  @override
  String get profileTitle => 'MY';

  @override
  String get currentTeam => '현재 팀';

  @override
  String get settingsTitle => '설정';

  @override
  String get shiftRule => '근무 규칙';

  @override
  String get shiftRuleDesc => '맞춤 주기 및 근무';

  @override
  String get alarmSettings => '알림 설정';

  @override
  String get alarmSettingsDesc => '근무 알림 시간';

  @override
  String get alarmSettingsInfo =>
      '알림 시간을 설정하면 근무일에 알림이 발송됩니다. 야간 근무 알림은 하루 전에 발송됩니다. 시스템 설정에서 알림을 허용해 주세요.';

  @override
  String get alarmNotSet => '설정 안 함';

  @override
  String get leaveOptimizerExplain => '근무표와 공휴일에 기반하여 최적의 휴가 계획을 찾습니다';

  @override
  String get maxLeave => '최대 휴가: ';

  @override
  String get noLeavePlanFound => '효율적인 휴가 계획을 찾을 수 없습니다. 최대 휴가 일수를 늘려보세요.';

  @override
  String get colleagueModeTitle => '동료 모드';

  @override
  String get iam => '나는';

  @override
  String get heis => '상대는';

  @override
  String get sameTeam => '같은 팀입니다. 모든 휴일이 일치합니다.';

  @override
  String get nextCommonRest => '다음 공동 휴일';

  @override
  String get noCommonRest => '없음';

  @override
  String daysUntil(Object days) {
    return '앞으로 $days일';
  }

  @override
  String get next30days => '30일 이내';

  @override
  String get next60days => '60일 이내';

  @override
  String commonRestDaysList(Object count) {
    return '공동 휴일 (총 $count회)';
  }

  @override
  String get noCommonRestFound => '분석 범위 내 공동 휴일이 없습니다.';

  @override
  String dayCount(Object days) {
    return '$days일 후';
  }

  @override
  String get statusToday => '오늘';

  @override
  String get salaryTitle => '근무 수당';

  @override
  String get premiumPerShift => '근무별 수당 (원)';

  @override
  String get monthlyPremium => '이번달 근무 수당';

  @override
  String get whatIf => '가상 분석';

  @override
  String get ifMore => '추가 근무';

  @override
  String whatIfResult(Object amount) {
    return '→ 수당 +¥$amount';
  }

  @override
  String get messageRest => '편히 쉬세요, 당신의 시간입니다';

  @override
  String get messageNight => '야간 근무 수고하세요, 감기 조심하세요';

  @override
  String get messageRestToday => '오늘은 휴일입니다, 즐기세요!';

  @override
  String get messageRestTomorrow => '내일 휴식, 조금만 더 힘내세요';

  @override
  String get messageRestSoon => '곧 휴일입니다, 화이팅';

  @override
  String get messageConsecutive => '연속 근무 수고하세요, 건강 챙기세요';

  @override
  String get messageDefault => '무리하지 마세요, 곧 휴식입니다';

  @override
  String monthYearFormat(Object year, Object month) {
    return '$year년 $month월';
  }

  @override
  String get saveAndGenerate => '저장 및 생성';

  @override
  String get savedLabel => '저장됨';

  @override
  String get discardChangesTitle => '변경 사항을 취소할까요?';

  @override
  String get discardChangesMsg => '저장되지 않은 변경 사항이 있습니다. 정말 나가시겠습니까?';

  @override
  String get continueEdit => '계속 편집';

  @override
  String get discard => '취소';

  @override
  String get cycleLengthLabel => '주기 길이';

  @override
  String get dayUnit => '일';

  @override
  String get preset42Day => '기본 42일';

  @override
  String get preset7Day => '7일 로테이션';

  @override
  String get preset14Day => '14일 로테이션';

  @override
  String get clearAllLabel => '초기화';

  @override
  String get addShiftLabel => '근무 추가';

  @override
  String rotationSeqLabel(Object count) {
    return '로테이션 ($count 항목)';
  }

  @override
  String get previewLabel => '미리보기';

  @override
  String get startDateLabel => '시작일';

  @override
  String get defaultTeamLabel => '기본 팀';

  @override
  String teamGapLabel(Object days) {
    return '팀 간격: $days 일';
  }

  @override
  String get yuanPerShift => '위안/근무';

  @override
  String get addAtLeastOne => '최소 하나의 근무를 추가하세요';

  @override
  String get versionInfo => '교대 도우미 CP v1.0.0';
}
