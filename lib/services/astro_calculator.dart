// astro_calculator.dart

// 별자리 계산을 위한 특별한 도구(Sweph)를 가져옵니다.
import 'package:sweph/sweph.dart';
// 날짜를 '2025-08-13'처럼 예쁘게 꾸며주는 도구(포매터)를 가져옵니다.
import 'package:intl/intl.dart';

// AstroCalculator 클래스는 별자리 정보를 계산하는 모든 함수들을 모아둔 곳입니다.
class AstroCalculator {
  // '별자리 기호' 목록입니다. 이 목록을 보고 별자리 기호를 찾습니다.
  static const List<String> zodiacSigns = [
    '♈', '♉', '♊', '♋', '♌', '♍', '♎', '♏', '♐', '♑', '♒', '♓',
  ];

  // '별자리 이름' 목록입니다. 이 목록을 보고 별자리 이름을 찾습니다.
  static const List<String> zodiacNames = [
    'Aries', 'Taurus', 'Gemini', 'Cancer', 'Leo', 'Virgo', 'Libra', 'Scorpio', 'Sagittarius', 'Capricorn', 'Aquarius', 'Pisces',
  ];

  // '달의 위상 이름' 목록입니다. 이 목록을 보고 달의 위상 이름을 찾습니다.
  static const List<String> moonPhaseNames = [
    '🌑 New Moon', '🌒 Waxing Crescent', '🌓 First Quarter', '🌔 Waxing Gibbous', '🌕 Full Moon', '🌖 Waning Gibbous', '🌗 Last Quarter', '🌘 Waning Crescent',
  ];

  // '주요 행성' 목록입니다. 이 행성들의 위치를 계산합니다.
  static const List<HeavenlyBody> majorPlanets = [
    HeavenlyBody.SE_SUN,
    HeavenlyBody.SE_MERCURY,
    HeavenlyBody.SE_VENUS,
    HeavenlyBody.SE_MARS,
    HeavenlyBody.SE_JUPITER,
    HeavenlyBody.SE_SATURN,
    HeavenlyBody.SE_URANUS,
    HeavenlyBody.SE_NEPTUNE,
    HeavenlyBody.SE_PLUTO,
  ];

  // '주요 각도(어스펙트)' 목록입니다. 이 각도를 기준으로 보이드 오브 코스를 계산합니다.
  static const List<double> majorAspects = [0, 60, 90, 120, 180];

  // 날짜를 '줄리안 데이'라는 특별한 날짜 형식으로 바꾸는 함수입니다.
  // Sweph 라이브러리는 이 줄리안 데이를 사용해 계산합니다.
  double getJulianDay(DateTime date) {
    // 현재 날짜를 세계 표준 시간(UTC)으로 바꿉니다.
    final utcDate = date.toUtc();
    // Sweph 도구를 사용해 줄리안 데이로 바꿉니다.
    final jdList = Sweph.swe_utc_to_jd(
      // 연도를 넣고,
      utcDate.year,
      // 월을 넣고,
      utcDate.month,
      // 일을 넣고,
      utcDate.day,
      // 시간을 넣고,
      utcDate.hour,
      // 분을 넣고,
      utcDate.minute,
      // 초를 넣습니다.
      utcDate.second.toDouble(),
      // '그레고리력'을 사용한다고 알려줍니다.
      CalendarType.SE_GREG_CAL,
    );
    // 계산된 줄리안 데이 값을 반환합니다.
    return jdList[0];
  }

  // 특정 행성의 '경도(하늘에서의 위치)'를 계산하는 함수입니다.
  double getLongitude(HeavenlyBody body, DateTime date) {
    // 줄리안 데이를 가져옵니다.
    final jd = getJulianDay(date);
    // Sweph 도구를 사용해 행성의 위치(경도)를 계산합니다.
    final pos = Sweph.swe_calc_ut(jd, body, SwephFlag.SEFLG_SWIEPH);
    // 계산된 경도 값을 반환합니다.
    return pos.longitude!;
  }

  // 태양과 달의 경도를 동시에 계산하는 함수입니다.
  Map<String, double> getSunMoonLongitude(DateTime date) {
    // 줄리안 데이를 가져옵니다.
    final jd = getJulianDay(date);
    // Sweph 도구를 사용해 태양의 위치를 계산합니다.
    final sun = Sweph.swe_calc_ut(
      jd,
      HeavenlyBody.SE_SUN,
      SwephFlag.SEFLG_SWIEPH,
    );
    // Sweph 도구를 사용해 달의 위치를 계산합니다.
    final moon = Sweph.swe_calc_ut(
      jd,
      HeavenlyBody.SE_MOON,
      SwephFlag.SEFLG_SWIEPH,
    );
    // 만약 위치 정보가 없다면 오류를 발생시킵니다.
    if (sun.longitude == null || moon.longitude == null) {
      throw Exception('Sun or Moon position not available.');
    }
    // 태양과 달의 경도를 지도(Map) 형태로 반환합니다.
    return {'sun': sun.longitude!, 'moon': moon.longitude!};
  }

  // 달의 위상(모양)을 계산하는 함수입니다.
  Map<String, dynamic> getMoonPhaseInfo(DateTime date) {
    final positions = getSunMoonLongitude(date);
    final sunLon = positions['sun']!;
    final moonLon = positions['moon']!;
    // 태양과 달의 각도 차이를 계산합니다.
    final angle = Sweph.swe_degnorm(moonLon - sunLon);

    String phaseName;

    // 각도에 따라 8개의 달 위상 중 하나를 결정합니다.
    // 각 위상은 45도씩 차지하도록 대칭적으로 설정합니다.
    if (angle >= 337.5 || angle < 22.5) {
      phaseName = '🌑 New Moon';
    } else if (angle < 67.5) {
      phaseName = '🌒 Waxing Crescent';
    } else if (angle < 112.5) {
      phaseName = '🌓 First Quarter';
    } else if (angle < 157.5) {
      phaseName = '🌔 Waxing Gibbous';
    } else if (angle < 202.5) {
      phaseName = '🌕 Full Moon';
    } else if (angle < 247.5) {
      phaseName = '🌖 Waning Gibbous';
    } else if (angle < 292.5) {
      phaseName = '🌗 Last Quarter';
    } else { // angle < 337.5
      phaseName = '🌘 Waning Crescent';
    }

    // 다음 주요 위상(삭, 상현, 망, 하현) 정보를 찾습니다.
    final nextPhaseInfo = _findNextPrimaryPhase(date);

    // 현재 위상 이름과 다음 주요 위상 정보를 반환합니다.
    return {
      'phaseName': phaseName,
      'nextPhaseName': nextPhaseInfo['name'],
      'nextPhaseTime': nextPhaseInfo['time'],
    };
  }

  // 다음 주요 위상(삭, 상현, 망, 하현)의 시간과 이름을 찾는 함수입니다.
  Map<String, dynamic> _findNextPrimaryPhase(DateTime date) {
    final phases = {
      0.0: '🌑 New Moon',
      90.0: '🌓 First Quarter',
      180.0: '🌕 Full Moon',
      270.0: '🌗 Last Quarter',
    };

    DateTime? nextPhaseTime;
    String? nextPhaseName;

    // 각 주요 위상에 대해 다음 발생 시간을 찾습니다.
    for (var entry in phases.entries) {
      final angle = entry.key;
      final name = entry.value;
      // 30일 이내에 해당 각도가 되는 시간을 찾습니다.
      DateTime? time = _findSpecificPhaseTime(date, angle, daysRange: 30);

      // 찾은 시간이 현재 시간 이후인지 확인합니다.
      if (time != null && time.isAfter(date)) {
        // 가장 가까운 다음 위상 시간을 저장합니다.
        if (nextPhaseTime == null || time.isBefore(nextPhaseTime)) {
          nextPhaseTime = time;
          nextPhaseName = name;
        }
      }
    }

    return {'name': nextPhaseName, 'time': nextPhaseTime};
  }

  // 달이 현재 어느 별자리에 있는지 이모티콘으로 반환합니다.
  String getMoonZodiacEmoji(DateTime date) {
    // 달의 경도를 가져옵니다.
    final moonLon = getLongitude(HeavenlyBody.SE_MOON, date);
    // 경도를 30으로 나누어 별자리의 번호(인덱스)를 찾습니다.
    final signIndex = ((moonLon % 360) / 30).floor();
    // 별자리 기호 목록에서 해당 별자리의 이모티콘을 반환합니다.
    return zodiacSigns[signIndex];
  }

  // 달이 현재 어느 별자리에 있는지 영어 이름으로 반환합니다.
  String getMoonZodiacName(DateTime date) {
    // 달의 경도를 가져옵니다.
    final moonLon = getLongitude(HeavenlyBody.SE_MOON, date);
    // 경도를 30으로 나누어 별자리의 번호(인덱스)를 찾습니다.
    final signIndex = ((moonLon % 360) / 30).floor();
    // 별자리 이름 목록에서 해당 별자리의 이름을 반환합니다.
    return zodiacNames[signIndex];
  }

  // 달이 한 별자리에 머무는 시작 시간과 종료 시간을 찾는 함수입니다.
  Map<String, DateTime?> getMoonSignTimes(DateTime date) {
    // 달의 경도를 가져옵니다.
    final moonLon = getLongitude(HeavenlyBody.SE_MOON, date);
    // 현재 달이 있는 별자리의 시작 경도를 찾습니다.
    final currentSignLon = (moonLon / 30).floor() * 30.0;
    // 다음 별자리의 시작 경도를 찾습니다.
    final nextSignLon = (currentSignLon + 30.0) % 360;

    DateTime? signStartTime;
    DateTime? signEndTime;

    // 현재 별자리에 진입한 시간을 찾습니다.
    final utcStartTime = _findTimeOfLongitude(
      // 3일 전부터 현재까지 시간을 찾습니다.
      date.subtract(const Duration(days: 3)),
      date,
      currentSignLon,
      isAscending: false, // 경도가 줄어드는 방향으로 찾습니다.
    );
    // 찾은 시간이 있다면, 로컬 시간으로 변환하여 저장합니다.
    if (utcStartTime != null) {
      signStartTime = utcStartTime.toLocal();
    }

    // 다음 별자리로 넘어가는 시간을 찾습니다.
    final utcEndTime = _findTimeOfLongitude(
      // 현재부터 3일 후까지 시간을 찾습니다.
      date,
      date.add(const Duration(days: 3)),
      nextSignLon,
      isAscending: true, // 경도가 늘어나는 방향으로 찾습니다.
    );
    // 찾은 시간이 있다면, 로컬 시간으로 변환하여 저장합니다.
    if (utcEndTime != null) {
      signEndTime = utcEndTime.toLocal();
    }

    // 시작 시간과 종료 시간을 지도(Map) 형태로 반환합니다.
    return {'start': signStartTime, 'end': signEndTime};
  }

  // 달의 특정 위상(예: 신월, 만월)이 발생하는 정확한 시간을 찾는 함수입니다.
  // 이진 탐색(binary search)이라는 방법을 사용합니다.
  DateTime? _findSpecificPhaseTime(DateTime date, double targetAngle, {int daysRange = 14}) {
    // 검색 시작 시간을 세계 표준시(UTC)로 정합니다.
    DateTime utcStart = date.subtract(Duration(days: daysRange)).toUtc();
    // 검색 끝 시간을 세계 표준시(UTC)로 정합니다.
    DateTime utcEnd = date.add(Duration(days: daysRange)).toUtc();

    // 100번 반복하면서 정밀한 시간을 찾습니다.
    for (int i = 0; i < 100; i++) {
      // 시작과 끝 시간의 중간 시간을 찾습니다.
      final mid = utcStart.add(Duration(milliseconds: utcEnd.difference(utcStart).inMilliseconds ~/ 2));
      // 중간 시간에서의 태양과 달의 위치를 가져옵니다.
      final positions = getSunMoonLongitude(mid);
      final sunLon = positions['sun']!;
      final moonLon = positions['moon']!;
      // 각도를 계산합니다.
      final angle = Sweph.swe_degnorm(moonLon - sunLon);

      // 만약 각도가 목표 각도와 거의 같다면,
      if ((angle - targetAngle).abs() < 0.0001) {
        // 찾은 시간을 로컬 시간으로 변환하여 반환합니다.
        return mid.toLocal();
      }

      // 만약 각도가 목표보다 작다면, 검색 시작 시간을 중간 시간으로 바꿉니다.
      if (angle < targetAngle) {
        utcStart = mid;
      } else {
        // 각도가 목표보다 크다면, 검색 끝 시간을 중간 시간으로 바꿉니다.
        utcEnd = mid;
      }
    }
    // 시간을 찾지 못하면 null을 반환합니다.
    return null;
  }

  // 달이 특정 경도에 도달하는 정확한 시간을 찾는 함수입니다.
  DateTime? _findTimeOfLongitude(
      DateTime start,
      DateTime end,
      double targetLon, {
        required bool isAscending,
      }) {
    // 목표 경도 값을 0~360도 사이로 정규화합니다.
    targetLon = Sweph.swe_degnorm(targetLon);
    // 검색 시작 시간을 세계 표준시(UTC)로 정합니다.
    DateTime utcStart = start.toUtc();
    // 검색 끝 시간을 세계 표준시(UTC)로 정합니다.
    DateTime utcEnd = end.toUtc();

    // 100번 반복하면서 정밀한 시간을 찾습니다.
    for (int i = 0; i < 100; i++) {
      // 시작과 끝 시간의 중간 시간을 찾습니다.
      final mid = utcStart.add(Duration(milliseconds: utcEnd.difference(utcStart).inMilliseconds ~/ 2));
      // 중간 시간에서의 달의 경도를 가져옵니다.
      final midLon = Sweph.swe_degnorm(getLongitude(HeavenlyBody.SE_MOON, mid));

      // 만약 경도가 목표 경도와 거의 같다면,
      if ((midLon - targetLon).abs() < 0.0001) return mid;

      // 달의 경도가 증가하는 방향으로 찾을 때
      if (isAscending) {
        // 중간 경도가 목표보다 작으면 시작 시간을 중간으로 바꿉니다.
        if (midLon < targetLon) {
          utcStart = mid;
        } else {
          // 크면 끝 시간을 중간으로 바꿉니다.
          utcEnd = mid;
        }
      } else { // 달의 경도가 감소하는 방향으로 찾을 때
        // 중간 경도가 목표보다 크면 시작 시간을 중간으로 바꿉니다.
        if (midLon > targetLon) {
          utcStart = mid;
        } else {
          // 작으면 끝 시간을 중간으로 바꿉니다.
          utcEnd = mid;
        }
      }
    }
    // 시간을 찾지 못하면 시작 시간을 반환합니다.
    return utcStart;
  }

  // 달이 특정 행성과 특정 각도를 맺는 정확한 시간을 찾는 함수입니다.
  DateTime? _findExactAspectTime(
      DateTime start,
      DateTime end,
      HeavenlyBody planet,
      double targetDiff,
      ) {
    // 목표 각도 값을 0~360도 사이로 정규화합니다.
    targetDiff = Sweph.swe_degnorm(targetDiff);
    // 검색 시작 시간을 세계 표준시(UTC)로 정합니다.
    DateTime utcStart = start.toUtc();
    // 검색 끝 시간을 세계 표준시(UTC)로 정합니다.
    DateTime utcEnd = end.toUtc();

    // 100번 반복하면서 정밀한 시간을 찾습니다.
    for (int i = 0; i < 100; i++) {
      // 시작과 끝 시간의 중간 시간을 찾습니다.
      final mid = utcStart.add(Duration(milliseconds: utcEnd.difference(utcStart).inMilliseconds ~/ 2));
      // 중간 시간에서의 달의 경도를 가져옵니다.
      final moonLon = getLongitude(HeavenlyBody.SE_MOON, mid);
      // 중간 시간에서의 행성의 경도를 가져옵니다.
      final planetLon = getLongitude(planet, mid);
      // 달과 행성 사이의 각도를 계산합니다.
      final midDiff = Sweph.swe_degnorm(moonLon - planetLon);

      // 만약 각도가 목표 각도와 거의 같다면,
      if ((midDiff - targetDiff).abs() < 0.0001) {
        // 찾은 시간을 반환합니다.
        return mid;
      }

      // 중간 각도가 목표보다 작으면 시작 시간을 중간으로 바꿉니다.
      if (midDiff < targetDiff) {
        utcStart = mid;
      } else {
        // 크면 끝 시간을 중간으로 바꿉니다.
        utcEnd = mid;
      }
    }
    // 시간을 찾지 못하면 null을 반환합니다.
    return null;
  }

  // 보이드 오브 코스 기간의 시작 시간을 찾는 핵심 함수입니다.
  // 달이 한 별자리에 있는 동안 마지막으로 주요 행성과 각도를 맺은 시간을 찾습니다.
  DateTime? _findLastAspectTime(DateTime moonSignEntryTime, DateTime moonSignExitTime) {
    // 마지막 어스펙트 시간을 저장할 변수를 준비합니다.
    DateTime? lastAspectTime;

    // 모든 주요 행성들에 대해 반복합니다.
    for (final planet in majorPlanets) {
      // 모든 주요 각도(어스펙트)에 대해 반복합니다.
      for (final aspect in majorAspects) {
        // 0도, 180도 같은 각도 외에 다른 각도도 찾기 위한 목록을 만듭니다.
        List<double> targets = [aspect];
        if (aspect > 0 && aspect < 180) {
          targets.add(360 - aspect);
        }

        // 목표 각도에 대해 반복합니다.
        for (final targetDiff in targets) {
          // 달이 별자리에 있는 기간 동안 어스펙트가 발생한 시간을 찾습니다.
          final aspectTime = _findExactAspectTime(
            moonSignEntryTime,
            moonSignExitTime,
            planet,
            targetDiff,
          );

          // 만약 어스펙트 시간을 찾았고, 이 시간이 이전에 찾은 시간보다 더 늦다면,
          if (aspectTime != null && (lastAspectTime == null || aspectTime.isAfter(lastAspectTime))) {
            // 마지막 어스펙트 시간을 업데이트합니다.
            lastAspectTime = aspectTime;
          }
        }
      }
    }

    // 최종적으로 가장 늦은 어스펙트 시간을 반환합니다.
    return lastAspectTime;
  }

  // 보이드 오브 코스 기간을 계산하는 함수입니다.
  Map<String, dynamic> findVoidOfCoursePeriod(DateTime date) {
    // 달이 별자리에 있는 시작 시간과 종료 시간을 가져옵니다.
    final moonSignTimes = getMoonSignTimes(date);
    final signStartTime = moonSignTimes['start'];
    final signEndTime = moonSignTimes['end'];

    // 만약 시작/종료 시간이 없으면 null을 반환합니다.
    if (signStartTime == null || signEndTime == null) {
      return {'start': null, 'end': null};
    }

    // ⭐ 보이드 오브 코스를 찾는 핵심 로직입니다.
    // 달이 별자리에 있는 기간 동안 마지막 어스펙트 시간을 찾습니다.
    final lastAspectTime = _findLastAspectTime(signStartTime, signEndTime);

    // 마지막 어스펙트 시간이 있고, 그 시간이 별자리 종료 시간보다 이전이라면,
    if (lastAspectTime != null && lastAspectTime.isBefore(signEndTime)) {
      // 보이드 오브 코스 기간은 마지막 어스펙트 시간부터 별자리가 끝나는 시간까지입니다.
      return {'start': lastAspectTime.toLocal(), 'end': signEndTime};
    }

    // 만약 마지막 어스펙트 시간이 별자리 종료 시간보다 늦거나 없다면,
    // 현재는 보이드 기간이 아닙니다.
    return {'start': null, 'end': null};
  }
}