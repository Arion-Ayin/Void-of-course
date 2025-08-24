// 별자리 계산을 위한 특별한 도구(Sweph)를 가져옵니다. 이 도구는 행성들의 위치를 계산하는 데 사용돼요.
import 'package:sweph/sweph.dart';
// 날짜를 '2025-08-13'처럼 예쁘게 꾸며주는 도구(포매터)를 가져옵니다. (intl은 Internationalization의 줄임말이에요)
import 'package:intl/intl.dart';

// AstroCalculator 클래스는 별자리 정보를 계산하는 모든 함수들을 모아둔 곳입니다. 마치 계산기처럼 여러 계산을 해줘요.
class AstroCalculator {
  // 12가지 별자리의 이모티콘(그림 글자)을 순서대로 저장해둔 목록이에요. (예: 양자리, 황소자리 등)
  static const List<String> zodiacSigns = [
    '♈', '♉', '♊', '♋', '♌', '♍', '♎', '♏', '♐', '♑', '♒', '♓',
  ];

  // 12가지 별자리의 영어 이름을 순서대로 저장해둔 목록이에요.
  static const List<String> zodiacNames = [
    'Aries', 'Taurus', 'Gemini', 'Cancer', 'Leo', 'Virgo', 'Libra', 'Scorpio', 'Sagittarius', 'Capricorn', 'Aquarius', 'Pisces',
  ];

  // 달의 8가지 위상(모양) 이름을 순서대로 저장해둔 목록이에요. (예: 초승달, 보름달 등)
    static const List<String> moonPhaseNames = [
    '🌑 New Moon',
    '🌒 Crescent Moon',
    '🌓 First Quarter',
    '🌔 Gibbous Moon',
    '🌕 Full Moon',
    '🌖 Disseminating Moon',
    '🌗 Last Quarter',
    '🌘 Balsamic Moon',
  ];

  // 주요 행성들의 목록을 저장해둔 곳이에요. Sweph 라이브러리에서 정해준 이름들이에요.
  static const List<HeavenlyBody> majorPlanets = [
    HeavenlyBody.SE_SUN, // 태양
    HeavenlyBody.SE_MERCURY, // 수성
    HeavenlyBody.SE_VENUS, // 금성
    HeavenlyBody.SE_MARS, // 화성
    HeavenlyBody.SE_JUPITER, // 목성
    HeavenlyBody.SE_SATURN, // 토성
    HeavenlyBody.SE_URANUS, // 천왕성
    HeavenlyBody.SE_NEPTUNE, // 해왕성
    HeavenlyBody.SE_PLUTO, // 명왕성
  ];

  // 주요 각도들을 저장해둔 목록이에요. (예: 0도, 60도, 90도 등)
  static const List<double> majorAspects = [0, 60, 90, 120, 180];

  // 날짜를 받아서 율리우스일(Julian Day)이라는 특별한 숫자로 바꿔주는 함수예요.
  // 율리우스일은 천문학에서 날짜를 계산할 때 사용하는 기준점 같은 거예요.
  double getJulianDay(DateTime date) {
    // 입력받은 날짜를 UTC(세계 표준시)로 바꿔요. 전 세계 어디서든 같은 시간을 기준으로 계산하기 위해서예요.
    final utcDate = date.toUtc();
    // Sweph 라이브러리에게 UTC 날짜를 율리우스일로 바꿔달라고 부탁해요.
    final jdList = Sweph.swe_utc_to_jd(
      utcDate.year, // 년도
      utcDate.month, // 월
      utcDate.day, // 일
      utcDate.hour, // 시
      utcDate.minute, // 분
      utcDate.second.toDouble(), // 초 (소수점 있는 숫자로 바꿔줘요)
      CalendarType.SE_GREG_CAL, // 그레고리력(우리가 쓰는 달력)을 사용한다고 알려줘요.
    );
    // 계산된 율리우스일 값 중에서 첫 번째 값을 돌려줘요.
    return jdList[0];
  }

  // 특정 행성(body)이 주어진 날짜(date)에 하늘에서 어느 위치(경도)에 있는지 계산하는 함수예요.
  double getLongitude(HeavenlyBody body, DateTime date) {
    // 먼저 날짜를 율리우스일로 바꿔요.
    final jd = getJulianDay(date);
    // Sweph 라이브러리에게 율리우스일과 행성 정보를 주고 위치를 계산해달라고 부탁해요.
    // SwephFlag.SEFLG_SWIEPH는 계산 방식을 알려주는 특별한 표시예요.
    final pos = Sweph.swe_calc_ut(jd, body, SwephFlag.SEFLG_SWIEPH);
    // 계산된 위치 정보 중에서 경도(longitude) 값을 돌려줘요. 만약 경도 값이 없으면 오류가 날 수 있어요.
    return pos.longitude!;
  }

  // 태양과 달이 주어진 날짜에 하늘에서 어느 위치(경도)에 있는지 계산하는 함수예요.
  Map<String, double> getSunMoonLongitude(DateTime date) {
    // 먼저 날짜를 율리우스일로 바꿔요.
    final jd = getJulianDay(date);
    // Sweph 라이브러리에게 태양의 위치를 계산해달라고 부탁해요.
    final sun = Sweph.swe_calc_ut(jd, HeavenlyBody.SE_SUN, SwephFlag.SEFLG_SWIEPH);
    // Sweph 라이브러리에게 달의 위치를 계산해달라고 부탁해요.
    final moon = Sweph.swe_calc_ut(jd, HeavenlyBody.SE_MOON, SwephFlag.SEFLG_SWIEPH);
    // 만약 태양이나 달의 경도 값이 없으면 (계산이 안되면) 오류를 발생시켜요.
    if (sun.longitude == null || moon.longitude == null) {
      throw Exception('Sun or Moon position not available.');
    }
    // 태양의 경도와 달의 경도를 'sun', 'moon'이라는 이름표를 붙여서 돌려줘요.
    return {'sun': sun.longitude!, 'moon': moon.longitude!};
  }

  // 주어진 날짜에 달의 위상(모양) 정보를 계산하는 함수예요.
  Map<String, dynamic> getMoonPhaseInfo(DateTime date) {
    // 태양과 달의 경도 위치를 가져와요.
    final positions = getSunMoonLongitude(date);
    // 태양의 경도 값을 sunLon 상자에 넣어요.
    final sunLon = positions['sun']!;
    // 달의 경도 값을 moonLon 상자에 넣어요.
    final moonLon = positions['moon']!;
    // 달의 경도에서 태양의 경도를 뺀 값을 계산해서 angle 상자에 넣어요. Sweph.swe_degnorm은 각도를 0~360도 사이로 맞춰줘요.
    final angle = Sweph.swe_degnorm(moonLon - sunLon);

    // 달의 위상 이름을 저장할 상자예요.
    String phaseName;
    // 사용자의 요청에 따라 달의 위상 구분을 표준적인 8단계로 수정합니다.
    // 이로써 발사믹 문(Balsamic Moon, 그믐달 마지막)이 뉴문(New Moon)으로 잘못 표시되는 문제를 해결합니다.
    if (angle < 45) {
      phaseName = '🌑 New Moon'; // 0-45도: 뉴문 (삭)
    } else if (angle < 90) {
      phaseName = '🌒 Crescent Moon'; // 45-90도: 초승달
    } else if (angle < 135) {
      phaseName = '🌓 First Quarter'; // 90-135도: 상현달
    } else if (angle < 180) {
      phaseName = '🌔 Gibbous Moon'; // 135-180도: 차오르는 달
    } else if (angle < 225) {
      phaseName = '🌕 Full Moon'; // 180-225도: 보름달 (망)
    } else if (angle < 270) {
      phaseName = '🌖 Disseminating Moon'; // 225-270도: 이지러지는 달
    } else if (angle < 315) {
      phaseName = '🌗 Last Quarter'; // 270-315도: 하현달
    } else {
      phaseName = '🌘 Balsamic Moon'; // 315-360도: 그믐달
    }
    
    // 계산된 달의 위상 이름을 'phaseName'이라는 이름표를 붙여서 돌려줘요.
    return {'phaseName': phaseName};
  }

  // 시간순으로 다음 주요 달의 위상을 정확히 찾는 함수
  Map<String, dynamic> findNextPrimaryPhase() {
    final now = DateTime.now();
    final phases = {
      0.0: '🌑 New Moon',
      90.0: '🌓 First Quarter',
      180.0: '🌕 Full Moon',
      270.0: '🌗 Last Quarter',
    };

    DateTime? bestTime;
    String? bestName;

    // 4개의 주요 위상 각각에 대해 다음 발생 시간을 찾고, 그 중 가장 빠른 시간을 선택
    for (var entry in phases.entries) {
      final targetAngle = entry.key;
      final name = entry.value;

      // 현재 태양과 달의 각도를 계산
      final positions = getSunMoonLongitude(now);
      final currentAngle = Sweph.swe_degnorm(positions['moon']! - positions['sun']!);

      // 목표 각도까지 남은 각도를 계산
      var deg_to_go = (targetAngle - currentAngle + 360) % 360;
      // 만약 목표 각도에 매우 가깝다면(이미 해당 위상에 있다면), 다음 주기의 같은 위상을 찾도록 360도를 더함
      if (deg_to_go < 0.5) {
        deg_to_go += 360;
      }

      // 달과 태양의 상대 속도(하루 약 12.19도)를 이용해 다음 위상까지 남은 시간을 추정
      var days_to_go = deg_to_go / 12.19;
      DateTime estimated_time = now.add(Duration(microseconds: (days_to_go * 24 * 3600 * 1000000).round()));

      // 추정된 시간 주변의 좁은 범위(4일) 내에서 정확한 시간을 탐색
      var time = _findSpecificPhaseTime(estimated_time, targetAngle, daysRange: 2);

      // 탐색된 시간이 현재 시간보다 이전인 경우 (추정이 약간 빗나간 경우), 한 달 뒤를 기준으로 다시 탐색하여 미래 시간을 찾음
      if (time != null && time.isBefore(now)) {
        time = _findSpecificPhaseTime(estimated_time.add(const Duration(days: 28)), targetAngle, daysRange: 3);
      }

      // 찾은 시간이 현재까지 찾은 가장 빠른 시간이면, 이 시간과 이름으로 업데이트
      if (time != null) {
        if (bestTime == null || time.isBefore(bestTime)) {
          bestTime = time;
          bestName = name;
        }
      }
    }

    return {'name': bestName, 'time': bestTime};
  }

  // 주어진 날짜에 달이 어떤 별자리에 있는지 이모티콘으로 알려주는 함수예요.
  String getMoonZodiacEmoji(DateTime date) {
    // 달의 경도 위치를 가져와요.
    final moonLon = getLongitude(HeavenlyBody.SE_MOON, date);
    // 달의 경도를 30으로 나누고 소수점을 버려서 별자리의 순서(인덱스)를 찾아요. (별자리 하나가 30도씩 차지해요)
    final signIndex = ((moonLon % 360) / 30).floor();
    // zodiacSigns 목록에서 해당 순서에 맞는 이모티콘을 돌려줘요.
    return zodiacSigns[signIndex];
  }

  // 주어진 날짜에 달이 어떤 별자리에 있는지 이름으로 알려주는 함수예요.
  String getMoonZodiacName(DateTime date) {
    // 달의 경도 위치를 가져와요.
    final moonLon = getLongitude(HeavenlyBody.SE_MOON, date);
    // 달의 경도를 30으로 나누고 소수점을 버려서 별자리의 순서(인덱스)를 찾아요.
    final signIndex = ((moonLon % 360) / 30).floor();
    // zodiacNames 목록에서 해당 순서에 맞는 이름을 돌려줘요.
    return zodiacNames[signIndex];
  }

  // 주어진 날짜에 달이 별자리에 들어가는 시간과 나가는 시간을 계산하는 함수예요.
  Map<String, DateTime?> getMoonSignTimes(DateTime date) {
    // 달의 경도 위치를 가져와요.
    final moonLon = getLongitude(HeavenlyBody.SE_MOON, date);
    // 달이 현재 있는 별자리의 시작 경도를 계산해요. (예: 10도면 0도, 40도면 30도)
    final currentSignLon = (moonLon / 30).floor() * 30.0;
    // 달이 다음으로 들어갈 별자리의 시작 경도를 계산해요. (360도를 넘으면 다시 0부터 시작해요)
    final nextSignLon = (currentSignLon + 30.0) % 360;

    // 달이 별자리에 들어간 시간을 저장할 상자예요. 처음에는 비어있어요.
    DateTime? signStartTime;
    // 달이 별자리에서 나가는 시간을 저장할 상자예요. 처음에는 비어있어요.
    DateTime? signEndTime;

    // 달이 현재 별자리에 들어간 시간을 찾습니다. 최대 3일 전까지 검색합니다.
    final utcStartTime = _findTimeOfLongitude(
      date.subtract(const Duration(days: 3)), // 지금 날짜에서 3일 전부터
      date, // 지금 날짜까지
      currentSignLon, // 현재 별자리의 시작 경도를 찾아요.
    );
    // 만약 시간을 찾았다면, 그 시간을 사용자가 사는 지역 시간으로 바꿔서 signStartTime에 저장해요.
    if (utcStartTime != null) {
      signStartTime = utcStartTime.toLocal();
    }

    // 달이 다음 별자리에 들어가는 시간을 찾습니다. 최대 3일 후까지 검색합니다.
    final utcEndTime = _findTimeOfLongitude(
      date, // 지금 날짜부터
      date.add(const Duration(days: 3)), // 지금 날짜에서 3일 후까지
      nextSignLon, // 다음 별자리의 시작 경도를 찾아요.
    );
    // 만약 시간을 찾았다면, 그 시간을 사용자가 사는 지역 시간으로 바꿔서 signEndTime에 저장해요.
    if (utcEndTime != null) {
      signEndTime = utcEndTime.toLocal();
    }

    // 달이 별자리에 들어간 시간과 나가는 시간을 'start', 'end'라는 이름표를 붙여서 돌려줘요.
    return {'start': signStartTime, 'end': signEndTime};
  }

  // 특정 위상(모양)이 언제 나타나는지 정확한 시간을 찾는 함수예요. (내부에서만 사용해요)
  DateTime? _findSpecificPhaseTime(DateTime date, double targetAngle, {int daysRange = 14}) {
    // 검색 시작 시간을 UTC로 설정해요. 주어진 날짜에서 daysRange만큼 빼요.
    DateTime utcStart = date.subtract(Duration(days: daysRange)).toUtc();
    // 검색 끝 시간을 UTC로 설정해요. 주어진 날짜에서 daysRange만큼 더해요.
    DateTime utcEnd = date.add(Duration(days: daysRange)).toUtc();
    
    // 100번 반복하면서 정확한 시간을 찾아요. (이진 탐색이라는 방법이에요)
    for (int i = 0; i < 100; i++) {
      // 만약 시작 시간과 끝 시간이 같으면 더 이상 찾을 필요가 없으니 멈춰요.
      if (utcStart.isAtSameMomentAs(utcEnd)) break;
      // 시작 시간과 끝 시간의 중간 시간을 계산해요.
      final mid = utcStart.add(Duration(milliseconds: utcEnd.difference(utcStart).inMilliseconds ~/ 2));
      // 만약 중간 시간이 시작 시간이나 끝 시간과 같으면 더 이상 찾을 수 없으니 멈춰요.
      if (mid.isAtSameMomentAs(utcStart) || mid.isAtSameMomentAs(utcEnd)) break;

      // 중간 시간에 태양과 달의 경도를 가져와요.
      final positions = getSunMoonLongitude(mid);
      final sunLon = positions['sun']!;
      final moonLon = positions['moon']!;
      // 중간 시간의 달과 태양의 각도 차이를 계산해요.
      final angle = Sweph.swe_degnorm(moonLon - sunLon);

      // 만약 계산된 각도가 목표 각도와 아주 조금만 차이 나면 (거의 같으면),
      if ((angle - targetAngle).abs() < 0.0005) {
        return mid.toLocal(); // 그 시간을 사용자가 사는 지역 시간으로 바꿔서 돌려줘요.
      }

      // 만약 계산된 각도가 목표 각도보다 작으면,
      if (angle < targetAngle) {
        utcStart = mid; // 시작 시간을 중간 시간으로 바꿔서 다시 검색해요.
      } else { // 만약 계산된 각도가 목표 각도보다 크면,
        utcEnd = mid; // 끝 시간을 중간 시간으로 바꿔서 다시 검색해요.
      }
    }
    // 100번 반복해도 찾지 못하면 아무것도 돌려주지 않아요.
    return null;
  }

  // 달이 특정 경도에 도달하는 시간을 찾는 함수예요. (내부에서만 사용해요)
  DateTime? _findTimeOfLongitude(
    DateTime start, // 검색 시작 시간
    DateTime end, // 검색 끝 시간
    double targetLon, // 목표 경도
  ) {
    // 목표 경도를 0~360도 사이로 맞춰줘요.
    targetLon = Sweph.swe_degnorm(targetLon);
    // 검색 시작 시간을 UTC로 바꿔요.
    DateTime utcStart = start.toUtc();
    // 검색 끝 시간을 UTC로 바꿔요.
    DateTime utcEnd = end.toUtc();

    // 시작 시간의 달 경도를 저장할 상자예요.
    double startLon;
    // 달의 위치를 계산하다가 오류가 날 수도 있으니 try-catch로 감싸요.
    try {
      startLon = Sweph.swe_degnorm(getLongitude(HeavenlyBody.SE_MOON, utcStart));
    } catch (e) {
      return null; // 위치를 계산할 수 없는 경우 아무것도 돌려주지 않아요.
    }

    // 시작 경도에서 목표 경도까지의 각도 차이를 계산해요.
    final targetFromStart = (targetLon - startLon + 360) % 360;

    // 검색 범위 내에 목표 각도가 있는지 확인합니다.
    // 끝 시간의 달 경도를 저장할 상자예요.
    double endLon;
    // 달의 위치를 계산하다가 오류가 날 수도 있으니 try-catch로 감싸요.
    try {
      endLon = Sweph.swe_degnorm(getLongitude(HeavenlyBody.SE_MOON, utcEnd));
    } catch (e) {
      return null; // 위치를 계산할 수 없는 경우 아무것도 돌려주지 않아요.
    }
    // 시작 경도에서 끝 경도까지의 각도 범위를 계산해요.
    final range = (endLon - startLon + 360) % 360;

    // 목표 각도가 검색 범위를 벗어나면 일찍 종료합니다.
    if (targetFromStart > range + 0.1) {
      return null;
    }

    // 이진 탐색으로 정확한 시간을 찾습니다. 100번 반복해요.
    for (int i = 0; i < 100; i++) {
      // 만약 시작 시간과 끝 시간이 같으면 더 이상 찾을 필요가 없으니 멈춰요.
      if (utcStart.isAtSameMomentAs(utcEnd)) break;
      // 시작 시간과 끝 시간의 중간 시간을 계산해요.
      final mid = utcStart.add(Duration(milliseconds: utcEnd.difference(utcStart).inMilliseconds ~/ 2));
      // 만약 중간 시간이 시작 시간이나 끝 시간과 같으면 더 이상 찾을 수 없으니 멈춰요.
      if (mid.isAtSameMomentAs(utcStart) || mid.isAtSameMomentAs(utcEnd)) break;

      // 중간 시간의 달 경도를 가져와요.
      final midLon = Sweph.swe_degnorm(getLongitude(HeavenlyBody.SE_MOON, mid));
      // 중간 시간의 달 경도와 목표 경도의 차이를 계산해요.
      final delta = Sweph.swe_degnorm(midLon - targetLon);

      // 만약 차이가 아주 작으면 (거의 같으면),
      if (delta < 0.0001 || delta > 359.9999) {
        return mid.toLocal(); // 그 시간을 사용자가 사는 지역 시간으로 바꿔서 돌려줘요. (정확한 시간을 찾았습니다.)
      }

      // 순환 경로를 따라 진행 상황을 비교하여 검색을 안내합니다.
      // 만약 중간 경도가 시작 경도에서 목표 경도 사이에 있다면,
      if (((midLon - startLon + 360) % 360) < targetFromStart) {
        utcStart = mid; // 시작 시간을 중간 시간으로 바꿔서 다시 검색해요.
      } else { // 그렇지 않다면,
        utcEnd = mid; // 끝 시간을 중간 시간으로 바꿔서 다시 검색해요.
      }
    }
    
    // 100회 반복 후에도 정확한 시간을 찾지 못한 경우, null을 반환하여 호출자가 처리하도록 합니다.
    return null;
  }

  // 달과 특정 행성(planet)이 특정 각도(targetDiff)를 이룰 때의 정확한 시간을 찾는 함수예요. (내부에서만 사용해요)
  DateTime? _findExactAspectTime(
      DateTime start, // 검색 시작 시간
      DateTime end, // 검색 끝 시간
      HeavenlyBody planet, // 대상 행성
      double targetDiff, // 목표 각도 차이
      ) {
    // 목표 각도 차이를 0~360도 사이로 맞춰줘요.
    targetDiff = Sweph.swe_degnorm(targetDiff);
    // 검색 시작 시간을 UTC로 바꿔요.
    DateTime utcStart = start.toUtc();
    // 검색 끝 시간을 UTC로 바꿔요.
    DateTime utcEnd = end.toUtc();

    // 시작 시간과 끝 시간의 달과 행성 간의 각도 차이를 저장할 상자예요.
    double startDiff, endDiff;
    // 위치를 계산하다가 오류가 날 수도 있으니 try-catch로 감싸요.
    try {
      // 시작 시간의 달 경도를 가져와요.
      final startMoonLon = getLongitude(HeavenlyBody.SE_MOON, utcStart);
      // 시작 시간의 대상 행성 경도를 가져와요.
      final startPlanetLon = getLongitude(planet, utcStart);
      // 시작 시간의 달과 행성 간의 각도 차이를 계산해요.
      startDiff = Sweph.swe_degnorm(startMoonLon - startPlanetLon);

      // 끝 시간의 달 경도를 가져와요.
      final endMoonLon = getLongitude(HeavenlyBody.SE_MOON, utcEnd);
      // 끝 시간의 대상 행성 경도를 가져와요.
      final endPlanetLon = getLongitude(planet, utcEnd);
      // 끝 시간의 달과 행성 간의 각도 차이를 계산해요.
      endDiff = Sweph.swe_degnorm(endMoonLon - endPlanetLon);
    } catch (e) {
      return null; // 위치를 계산할 수 없는 경우 아무것도 돌려주지 않아요.
    }

    // 시작 각도 차이에서 끝 각도 차이까지의 범위를 계산해요.
    final range = (endDiff - startDiff + 360) % 360;
    // 시작 각도 차이에서 목표 각도 차이까지의 거리를 계산해요.
    final targetFromStart = (targetDiff - startDiff + 360) % 360;

    // 목표 각도가 검색 범위를 벗어나면 일찍 종료합니다.
    if (targetFromStart > range + 0.01) {
      return null;
    }

    // 이진 탐색으로 정확한 시간을 찾습니다. 100번 반복해요.
    for (int i = 0; i < 100; i++) {
      // 시작 시간과 끝 시간이 같으면 멈춰요.
      if (utcStart.isAtSameMomentAs(utcEnd)) break;
      // 시작 시간과 끝 시간의 중간 시간을 계산해요.
      final mid = utcStart.add(Duration(milliseconds: utcEnd.difference(utcStart).inMilliseconds ~/ 2));
      // 중간 시간이 시작 시간이나 끝 시간과 같으면 멈춰요.
      if (mid.isAtSameMomentAs(utcStart) || mid.isAtSameMomentAs(utcEnd)) break;

      // 중간 시간의 달 경도를 가져와요.
      final moonLon = getLongitude(HeavenlyBody.SE_MOON, mid);
      // 중간 시간의 대상 행성 경도를 가져와요.
      final planetLon = getLongitude(planet, mid);
      // 중간 시간의 달과 행성 간의 각도 차이를 계산해요.
      final midDiff = Sweph.swe_degnorm(moonLon - planetLon);

      // 중간 각도 차이와 목표 각도 차이의 차이를 계산해요.
      final delta = Sweph.swe_degnorm(midDiff - targetDiff);
      // 만약 차이가 아주 작으면 (거의 같으면),
      if (delta < 0.001 || delta > 359.999) {
        // print('Aspect found at $mid: moonLon=$moonLon, planetLon=$planetLon, angle=$midDiff'); // 개발자용 메시지
        return mid.toLocal(); // 그 시간을 사용자가 사는 지역 시간으로 바꿔서 돌려줘요.
      }

      // 순환 경로를 따라 진행 상황을 비교하여 검색을 안내합니다.
      // 만약 중간 각도 차이가 시작 각도 차이에서 목표 각도 차이 사이에 있다면,
      if (((midDiff - startDiff + 360) % 360) < targetFromStart) {
        utcStart = mid; // 시작 시간을 중간 시간으로 바꿔서 다시 검색해요.
      } else { // 그렇지 않다면,
        utcEnd = mid; // 끝 시간을 중간 시간으로 바꿔서 다시 검색해요.
      }
    }
    // 100번 반복해도 찾지 못하면 아무것도 돌려주지 않아요.
    return null;
  }

  // 달이 특정 별자리에 머무는 동안 마지막으로 주요 행성들과 각도를 이루는 시간을 찾는 함수예요. (내부에서만 사용해요)
  DateTime? _findLastAspectTime(DateTime moonSignEntryTime, DateTime moonSignExitTime) {
    // 마지막 각도 시간을 저장할 상자예요. 처음에는 비어있어요.
    DateTime? lastAspectTime;

    // print('Searching aspects between $moonSignEntryTime and $moonSignExitTime'); // 개발자용 메시지

    // 모든 주요 행성들을 하나씩 살펴봐요.
    for (final planet in majorPlanets) {
      // 모든 주요 각도들을 하나씩 살펴봐요.
      for (final aspect in majorAspects) {
        // 목표 각도들을 저장할 목록이에요.
        List<double> targets = [aspect];
        // 만약 각도가 0도보다 크고 180도보다 작으면 (예: 60도), 반대편 각도(360-60=300도)도 추가해요.
        if (aspect > 0 && aspect < 180) {
          targets.add(360 - aspect);
        }

        // 목표 각도들을 하나씩 살펴봐요.
        for (final targetDiff in targets) {
          // _findExactAspectTime 함수를 사용해서 달과 행성이 해당 각도를 이룰 때의 시간을 찾아요.
          final aspectTime = _findExactAspectTime(
            moonSignEntryTime, // 달이 별자리에 들어간 시간부터
            moonSignExitTime, // 달이 별자리에서 나가는 시간까지
            planet, // 대상 행성
            targetDiff, // 목표 각도 차이
          );

          // 만약 시간을 찾았다면,
          if (aspectTime != null) {
            // print('Found aspect at $aspectTime with planet $planet, angle $targetDiff'); // 개발자용 메시지
            // 만약 lastAspectTime이 아직 정해지지 않았거나, 지금 찾은 시간이 lastAspectTime보다 더 미래라면,
            if (lastAspectTime == null || aspectTime.isAfter(lastAspectTime)) {
              lastAspectTime = aspectTime; // lastAspectTime을 지금 찾은 시간으로 바꿔요.
            }
          }
        }
      }
    }

    // print('Last aspect time: $lastAspectTime'); // 개발자용 메시지
    // 마지막 각도 시간을 돌려줘요.
    return lastAspectTime;
  }

  // 주어진 날짜에 해당하는 보이드 오브 코스(Void of Course) 기간을 찾는 함수예요.
  // 선택된 날짜에 이미 진행중이거나, 그 날에 시작될 첫 번째 보이드 정보를 찾도록 수정되었어요.
  Map<String, dynamic> findVoidOfCoursePeriod(DateTime date) {
    // 사용자가 선택한 날짜의 자정(0시 0분)을 기준으로 검색을 시작해요.
    // 이렇게 하면 그 날 전체에 대한 보이드 정보를 정확히 포착할 수 있어요.
    final dayStart = DateTime(date.year, date.month, date.day);
    var searchDate = dayStart;

    // 무한 루프에 빠지지 않도록 최대 5번까지만 다음 별자리를 탐색해요.
    for (int i = 0; i < 5; i++) {
      // 현재 검색 시간(searchDate)을 기준으로 달이 현재 속한 별자리의 시작과 끝 시간을 가져와요.
      final moonSignTimes = getMoonSignTimes(searchDate);
      final signStartTime = moonSignTimes['start'];
      final signEndTime = moonSignTimes['end'];

      // 만약 별자리 정보를 가져올 수 없다면, 계산을 중단하고 결과를 반환해요.
      if (signStartTime == null || signEndTime == null) {
        return {'start': null, 'end': null};
      }

      // 이 별자리 안에서 달이 마지막으로 주요 행성과 각도를 맺는 시간을 찾아요.
      final lastAspectTime = _findLastAspectTime(signStartTime, signEndTime);

      // 보이드 시작 시간(vocStart)을 정해요.
      DateTime? vocStart;
      if (lastAspectTime != null) {
        // 마지막 각도가 있었다면 그 시간이 보이드의 시작이에요.
        vocStart = lastAspectTime;
      } else {
        // 만약 각도가 없었다면, 달이 그 별자리에 들어선 순간부터 보이드 상태예요.
        vocStart = signStartTime;
      }
      // 보이드 종료 시간(vocEnd)은 달이 다음 별자리로 넘어가는 시간이에요.
      final vocEnd = signEndTime;

      // 찾은 보이드의 종료 시간이, 우리가 기준점으로 삼은 '그 날의 시작'보다 뒤라면,
      // 이 정보가 바로 사용자에게 보여줘야 할 올바른 보이드 정보예요.
      if (vocEnd.isAfter(dayStart)) {
        return {'start': vocStart, 'end': vocEnd};
      }

      // 만약 찾은 보이드가 이미 '그 날의 시작'보다 전에 끝나버렸다면,
      // 다음 정보를 찾기 위해 검색 기준 시간을 현재 보이드가 끝난 시간으로 옮겨서 다시 시도해요.
      searchDate = signEndTime;
    }

    // 여러 번 시도해도 유효한 보이드 정보를 찾지 못하면, 없음을 반환해요.
    return {'start': null, 'end': null};
  }

  // 달의 위상 이름(예: '🌑 New Moon')을 받아서 해당 이모티콘(예: '🌑')만 돌려주는 함수예요.
  String getMoonPhaseEmoji(String moonPhaseName) {
    // moonPhaseName에 따라 다른 이모티콘을 돌려줘요.
    switch (moonPhaseName) {
      case '🌑 New Moon':
        return '🌑';
      case '🌒 Crescent Moon':
        return '🌒';
      case '🌓 First Quarter':
        return '🌓';
      case '🌔 Gibbous Moon':
        return '🌔';
      case '🌕 Full Moon':
        return '🌕';
      case '🌖 Disseminating Moon':
        return '🌖';
      case '🌗 Last Quarter':
        return '🌗';
      case '🌘 Balsamic Moon':
        return '🌘';
      default:
        return '❓';
    }
  }

  // 달의 위상 이름(예: '🌑 New Moon')을 받아서 이름 부분(예: 'New Moon')만 돌려주는 함수예요.
  String getMoonPhaseNameOnly(String moonPhaseName) {
    // 정규 표현식(RegExp)을 사용해서 문자열의 시작 부분에 있는 이모티콘과 공백을 지워요.
    // ^\S+\s는 '문자열 시작(^)부터 공백이 아닌 문자(\S+)가 하나 이상 나오고 공백(\s)이 나오는 부분'을 찾아요.
    return moonPhaseName.replaceAll(RegExp(r'^\S+\s'), '');
  }
}