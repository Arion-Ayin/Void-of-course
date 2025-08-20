// 별자리 계산을 위한 특별한 도구(Sweph)를 가져옵니다.
import 'package:sweph/sweph.dart';
// 날짜를 '2025-08-13'처럼 예쁘게 꾸며주는 도구(포매터)를 가져옵니다.
import 'package:intl/intl.dart';

// AstroCalculator 클래스는 별자리 정보를 계산하는 모든 함수들을 모아둔 곳입니다.
class AstroCalculator {
  static const List<String> zodiacSigns = [
    '♈', '♉', '♊', '♋', '♌', '♍', '♎', '♏', '♐', '♑', '♒', '♓',
  ];

  static const List<String> zodiacNames = [
    'Aries', 'Taurus', 'Gemini', 'Cancer', 'Leo', 'Virgo', 'Libra', 'Scorpio', 'Sagittarius', 'Capricorn', 'Aquarius', 'Pisces',
  ];

  static const List<String> moonPhaseNames = [
    '🌑 New Moon', '🌒 Waxing Crescent', '🌓 First Quarter', '🌔 Waxing Gibbous', '🌕 Full Moon', '🌖 Waning Gibbous', '🌗 Last Quarter', '🌘 Waning Crescent',
  ];

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

  static const List<double> majorAspects = [0, 60, 90, 120, 180];

  double getJulianDay(DateTime date) {
    final utcDate = date.toUtc();
    final jdList = Sweph.swe_utc_to_jd(
      utcDate.year,
      utcDate.month,
      utcDate.day,
      utcDate.hour,
      utcDate.minute,
      utcDate.second.toDouble(),
      CalendarType.SE_GREG_CAL,
    );
    return jdList[0];
  }

  double getLongitude(HeavenlyBody body, DateTime date) {
    final jd = getJulianDay(date);
    final pos = Sweph.swe_calc_ut(jd, body, SwephFlag.SEFLG_SWIEPH);
    return pos.longitude!;
  }

  Map<String, double> getSunMoonLongitude(DateTime date) {
    final jd = getJulianDay(date);
    final sun = Sweph.swe_calc_ut(jd, HeavenlyBody.SE_SUN, SwephFlag.SEFLG_SWIEPH);
    final moon = Sweph.swe_calc_ut(jd, HeavenlyBody.SE_MOON, SwephFlag.SEFLG_SWIEPH);
    if (sun.longitude == null || moon.longitude == null) {
      throw Exception('Sun or Moon position not available.');
    }
    return {'sun': sun.longitude!, 'moon': moon.longitude!};
  }

  Map<String, dynamic> getMoonPhaseInfo(DateTime date) {
    final positions = getSunMoonLongitude(date);
    final sunLon = positions['sun']!;
    final moonLon = positions['moon']!;
    final angle = Sweph.swe_degnorm(moonLon - sunLon);

    String phaseName;
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
    } else {
      phaseName = '🌘 Waning Crescent';
    }

    final nextPhaseInfo = _findNextPrimaryPhase(date);
    return {
      'phaseName': phaseName,
      'nextPhaseName': nextPhaseInfo['name'],
      'nextPhaseTime': nextPhaseInfo['time'],
    };
  }

  Map<String, dynamic> _findNextPrimaryPhase(DateTime date) {
    final phases = {
      0.0: '🌑 New Moon',
      90.0: '🌓 First Quarter',
      180.0: '🌕 Full Moon',
      270.0: '🌗 Last Quarter',
    };

    DateTime? nextPhaseTime;
    String? nextPhaseName;

    for (var entry in phases.entries) {
      final angle = entry.key;
      final name = entry.value;
      DateTime? time = _findSpecificPhaseTime(date, angle, daysRange: 30);
      if (time != null && time.isAfter(date)) {
        if (nextPhaseTime == null || time.isBefore(nextPhaseTime)) {
          nextPhaseTime = time;
          nextPhaseName = name;
        }
      }
    }

    return {'name': nextPhaseName, 'time': nextPhaseTime};
  }

  String getMoonZodiacEmoji(DateTime date) {
    final moonLon = getLongitude(HeavenlyBody.SE_MOON, date);
    final signIndex = ((moonLon % 360) / 30).floor();
    return zodiacSigns[signIndex];
  }

  String getMoonZodiacName(DateTime date) {
    final moonLon = getLongitude(HeavenlyBody.SE_MOON, date);
    final signIndex = ((moonLon % 360) / 30).floor();
    return zodiacNames[signIndex];
  }

  Map<String, DateTime?> getMoonSignTimes(DateTime date) {
    final moonLon = getLongitude(HeavenlyBody.SE_MOON, date);
    final currentSignLon = (moonLon / 30).floor() * 30.0;
    final nextSignLon = (currentSignLon + 30.0) % 360;

    DateTime? signStartTime;
    DateTime? signEndTime;

    final utcStartTime = _findTimeOfLongitude(
      date.subtract(const Duration(days: 3)),
      date,
      currentSignLon,
      isAscending: false,
    );
    if (utcStartTime != null) {
      signStartTime = utcStartTime.toLocal();
    }

    final utcEndTime = _findTimeOfLongitude(
      date,
      date.add(const Duration(days: 3)),
      nextSignLon,
      isAscending: true,
    );
    if (utcEndTime != null) {
      signEndTime = utcEndTime.toLocal();
    }

    return {'start': signStartTime, 'end': signEndTime};
  }

  DateTime? _findSpecificPhaseTime(DateTime date, double targetAngle, {int daysRange = 14}) {
    DateTime utcStart = date.subtract(Duration(days: daysRange)).toUtc();
    DateTime utcEnd = date.add(Duration(days: daysRange)).toUtc();

    for (int i = 0; i < 100; i++) {
      final mid = utcStart.add(Duration(milliseconds: utcEnd.difference(utcStart).inMilliseconds ~/ 2));
      final positions = getSunMoonLongitude(mid);
      final sunLon = positions['sun']!;
      final moonLon = positions['moon']!;
      final angle = Sweph.swe_degnorm(moonLon - sunLon);

      if ((angle - targetAngle).abs() < 0.0005) {
        return mid.toLocal();
      }

      if (angle < targetAngle) {
        utcStart = mid;
      } else {
        utcEnd = mid;
      }
    }
    return null;
  }

  DateTime? _findTimeOfLongitude(
      DateTime start,
      DateTime end,
      double targetLon, {
        required bool isAscending,
      }) {
    targetLon = Sweph.swe_degnorm(targetLon);
    DateTime utcStart = start.toUtc();
    DateTime utcEnd = end.toUtc();

    for (int i = 0; i < 100; i++) {
      final mid = utcStart.add(Duration(milliseconds: utcEnd.difference(utcStart).inMilliseconds ~/ 2));
      final midLon = Sweph.swe_degnorm(getLongitude(HeavenlyBody.SE_MOON, mid));

      if ((midLon - targetLon).abs() < 0.0001) return mid.toLocal(); // toLocal()로 KST 반환

      if (isAscending) {
        if (midLon < targetLon) {
          utcStart = mid;
        } else {
          utcEnd = mid;
        }
      } else {
        if (midLon > targetLon) {
          utcStart = mid;
        } else {
          utcEnd = mid;
        }
      }
    }
    return utcStart.toLocal();
  }

  DateTime? _findExactAspectTime(
      DateTime start,
      DateTime end,
      HeavenlyBody planet,
      double targetDiff,
      ) {
    targetDiff = Sweph.swe_degnorm(targetDiff);
    DateTime utcStart = start.toUtc();
    DateTime utcEnd = end.toUtc();

    for (int i = 0; i < 100; i++) {
      final mid = utcStart.add(Duration(milliseconds: utcEnd.difference(utcStart).inMilliseconds ~/ 2));
      final moonLon = getLongitude(HeavenlyBody.SE_MOON, mid);
      final planetLon = getLongitude(planet, mid);
      final midDiff = Sweph.swe_degnorm(moonLon - planetLon);

      if ((midDiff - targetDiff).abs() < 0.0003) { // 허용 오차 감소
        print('Aspect found at $mid: moonLon=$moonLon, planetLon=$planetLon, angle=$midDiff');
        return mid.toLocal();
      }

      if (midDiff < targetDiff) {
        utcStart = mid;
      } else {
        utcEnd = mid;
      }
    }
    return null;
  }

  DateTime? _findLastAspectTime(DateTime moonSignEntryTime, DateTime moonSignExitTime) {
    DateTime? lastAspectTime;

    final extendedMoonSignExitTime = moonSignExitTime.add(const Duration(minutes: 10)); // 버퍼 증가

    print('Searching aspects between $moonSignEntryTime and $moonSignExitTime');

    for (final planet in majorPlanets) {
      for (final aspect in majorAspects) {
        List<double> targets = [aspect];
        if (aspect > 0 && aspect < 180) {
          targets.add(360 - aspect);
        }

        for (final targetDiff in targets) {
          final aspectTime = _findExactAspectTime(
            moonSignEntryTime,
            moonSignExitTime.add(Duration(seconds: 1)), // 버퍼 추가
            planet,
            targetDiff,
          );

          if (aspectTime != null &&
              (aspectTime.isAfter(moonSignEntryTime) || aspectTime.isAtSameMomentAs(moonSignEntryTime)) &&
              (aspectTime.isBefore(moonSignExitTime) || aspectTime.isAtSameMomentAs(moonSignExitTime))) {
            print('Found aspect at $aspectTime with planet $planet, angle $targetDiff');
            if (lastAspectTime == null || aspectTime.isAfter(lastAspectTime)) {
              lastAspectTime = aspectTime;
            }
          }
        }
      }
    }

    print('Last aspect time: $lastAspectTime');
    return lastAspectTime;
  }

  Map<String, dynamic> findVoidOfCoursePeriod(DateTime date) {
    final moonSignTimes = getMoonSignTimes(date);
    final signStartTime = moonSignTimes['start'];
    final signEndTime = moonSignTimes['end'];

    if (signStartTime == null || signEndTime == null) {
      print('No sign times available for $date');
      return {'start': null, 'end': null};
    }

    print('Moon sign period for $date: $signStartTime to $signEndTime');

    // 입력 날짜가 현재 별자리 기간 내이거나 종료 시간과 같은 경우
    if ((date.isAfter(signStartTime) || date.isAtSameMomentAs(signStartTime)) &&
        (date.isBefore(signEndTime) || date.isAtSameMomentAs(signEndTime))) {
      print('Date $date is within or at the end of current moon sign period');
      final lastAspectTime = _findLastAspectTime(signStartTime, signEndTime);

      if (lastAspectTime != null &&
          (lastAspectTime.isBefore(signEndTime) || lastAspectTime.isAtSameMomentAs(signEndTime))) {
        print('VoC found: $lastAspectTime to $signEndTime');
        return {'start': lastAspectTime, 'end': signEndTime};
      } else {
        print('No VoC period in current sign for $date');
        return {'start': null, 'end': null};
      }
    } else {
      print('Date $date is outside current moon sign period ($signStartTime to $signEndTime)');
      return {'start': null, 'end': null};
    }
  }

  // 달의 위상 이름에 따라 해당하는 이모티콘을 반환하는 함수입니다.
  String getMoonPhaseEmoji(String moonPhaseName) {
    switch (moonPhaseName) {
      case '🌑 New Moon':
        return '🌑';
      case '🌒 Waxing Crescent':
        return '🌒';
      case '🌓 First Quarter':
        return '🌓';
      case '🌔 Waxing Gibbous':
        return '🌔';
      case '🌕 Full Moon':
        return '🌕';
      case '🌖 Waning Gibbous':
        return '🌖';
      case '🌗 Last Quarter':
        return '🌗';
      case '🌘 Waning Crescent':
        return '🌘';
      default:
        return '❓'; // 알 수 없는 위상일 경우 물음표 이모티콘을 반환합니다.
    }
  }

  // 달의 위상 이름에서 이모지를 제거하고 순수한 이름만 반환하는 함수입니다.
  String getMoonPhaseNameOnly(String moonPhaseName) {
    // 이모지와 공백을 제거합니다.
    return moonPhaseName.replaceAll(RegExp(r'^\S+\s'), '');
  }
}