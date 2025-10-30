// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get home => '홈';

  @override
  String get settings => '설정';

  @override
  String get info => '정보';

  @override
  String get languageSettings => '언어 설정';

  @override
  String get korean => '한국어';

  @override
  String get english => '영어';

  @override
  String get community => '커뮤니티';

  @override
  String get darkMode => '다크 모드';

  @override
  String get voidAlarmTitle => '보이드 알람';

  @override
  String get voidAlarmEnabledMessage => '보이드 알람이 활성화되었습니다.\n6시간 이전부터 알람이 울립니다.';

  @override
  String get voidAlarmDisabledMessage => '보이드 알람이 비활성화되었습니다.';

  @override
  String get voidAlarmTimeTitle => '알림 시간';

  @override
  String voidAlarmTimeUnit(int count) {
    return '$count시간 전';
  }

  @override
  String voidAlarmTimeSetMessage(int count) {
    return '보이드 알림 시간이 $count시간 전으로 설정되었습니다.';
  }

  @override
  String get mailAppError => '메일 앱을 열 수 없습니다. 기본 메일 앱 설정을 확인해주세요.';

  @override
  String get contactEmail => 'Arion.Ayin@gmail.com';

  @override
  String get infoScreenTitle => '정보';

  @override
  String get headerSubtitle => '보이드 오브 코스 계산기';

  @override
  String get whoAreWeTitle => '우리는 누구인가요?';

  @override
  String get whoAreWeSubtitle => '• 아리온아인의 사명 : |||사자의 눈으로 세상을 헤아립니다.';

  @override
  String get whoIsItUsefulForTitle => '누구에게 유용한가요?';

  @override
  String get whoIsItUsefulForSubtitle => '• 간단한 택일이 필요하신 분들|||• 보이드 오브 코스 계산이 필요한 분들|||• 행동의 지표성이 필요한 분들';

  @override
  String get whyDidWeMakeThisAppTitle => '왜 이 앱을 만들었나요?';

  @override
  String get whyDidWeMakeThisAppSubtitle => '• 누구나 손쉽게 이 정보들에 접근 가능하면 좋겠다는 마음에';

  @override
  String get copyrightText => '© 2025 Arion Ayin. All rights reserved.';

  @override
  String get newMoon => '신월';

  @override
  String get crescentMoon => '초승달';

  @override
  String get firstQuarter => '상현달';

  @override
  String get gibbousMoon => '기울어진 달';

  @override
  String get fullMoon => '보름달';

  @override
  String get disseminatingMoon => '기울어가는 달';

  @override
  String get lastQuarter => '하현달';

  @override
  String get balsamicMoon => '그믐달';

  @override
  String get sunMoonPositionError => '태양 또는 달의 위치를 사용할 수 없습니다.';

  @override
  String get initializationError => '초기화 오류';

  @override
  String get calculationError => '계산 중 오류 발생';

  @override
  String vocStartsInMinutes(int minutesRemaining) {
    final intl.NumberFormat minutesRemainingNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
      
    );
    final String minutesRemainingString = minutesRemainingNumberFormat.format(minutesRemaining);

    return '$minutesRemainingString분 후에 보이드가 시작됩니다.';
  }

  @override
  String vocStartsInHours(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
      
    );
    final String countString = countNumberFormat.format(count);

    return '$countString시간 후에 보이드가 시작됩니다.';
  }

  @override
  String get vocStartsSoon => '보이드가 곧 시작됩니다.';

  @override
  String get vocNotificationTitle => 'Void of Course 알림';

  @override
  String get vocOngoingTitle => '보이드 중';

  @override
  String get vocOngoingBody => '지금은 보이드 시간입니다.';

  @override
  String get vocEndedTitle => '보이드 종료';

  @override
  String get vocEndedBody => '보이드가 종료되었습니다.';

  @override
  String get nextMoonPhaseTimePassed => '다음 달 위상 시간이 지났습니다.';

  @override
  String get moonSignEndTimePassed => '다음 달 싸인으로의 진입 시간이 지났습니다.';

  @override
  String get vocEndTimePassed => '보이드 기간이 종료되었습니다.';

  @override
  String timeToRefreshData(Object refreshReason) {
    return '데이터를 새로고침할 시간입니다: $refreshReason. 새로고침 중...';
  }

  @override
  String get voidAlarmExactAlarmDeniedMessage => '앱 설정에서 \'알람 및 리마인더\' 권한을 허용해주세요.';

  @override
  String get noUpcomingVocFound => '선택된 날짜에 예정된 보이드 기간이 없거나 이미 지났습니다. 알람이 예약되지 않았습니다.';

  @override
  String get errorSchedulingAlarm => '알람 예약 중 오류 발생';

  @override
  String get errorShowingImmediateAlarm => '즉시 알람 표시 중 오류 발생';

  @override
  String get calculating => '계산 중...';

  @override
  String get vocStartedTitle => '보이드 시작';

  @override
  String get vocStartedBody => '지금은 보이드 시간입니다.';

  @override
  String vocRemainingTimeHourMinute(int hours, int minutes) {
    return '남은 시간: $hours시간 $minutes분';
  }

  @override
  String vocRemainingTimeMinute(int minutes) {
    return '남은 시간: $minutes분';
  }

  @override
  String preVocNotificationBodyHourMinute(int hours, int minutes) {
    return '보이드 시작까지 $hours시간 $minutes분 남았습니다.';
  }

  @override
  String preVocNotificationBodyMinute(int minutes) {
    return '보이드 시작까지 $minutes분 남았습니다.';
  }

  @override
  String get notAvailable => '해당 없음';

  @override
  String get vocStatusIsVoc => '보이드 입니다';

  @override
  String get vocStatusHasVocToday => '금일 보이드가 있습니다.';

  @override
  String get vocStatusIsNotVoc => '보이드가 아닙니다';

  @override
  String get voidOfCourse => '보이드 오브 코스';

  @override
  String vocStartTime(String time) {
    return '시작 : $time';
  }

  @override
  String vocEndTime(String time) {
    return '종료 : $time';
  }

  @override
  String moonInSign(String sign) {
    return '달, $sign에 위치';
  }

  @override
  String nextSign(String time) {
    return '다음 싸인 : $time';
  }

  @override
  String get moonPhaseTitle => '달의 위상';

  @override
  String nextPhase(String time) {
    return '다음 상태 : $time';
  }
}
