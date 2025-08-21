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
    
    return {'phaseName': phaseName};
  }

  // 매개변수 'date'를 제거합니다.
  Map<String, dynamic> findNextPrimaryPhase() {
    // 이제 함수 호출 시 매개변수를 전달할 필요가 없습니다.
    final now = DateTime.now();

    final phases = {
      0.0: '🌑 New Moon',
      90.0: '🌓 First Quarter',
      180.0: '🌕 Full Moon',
      270.0: '🌗 Last Quarter',
    };

    DateTime? nextPhaseTime;
    String? nextPhaseName;

    // 현재 위상을 찾습니다.
    final positions = getSunMoonLongitude(now);
    final sunLon = positions['sun']!;
    final moonLon = positions['moon']!;
    final currentAngle = Sweph.swe_degnorm(moonLon - sunLon);

    List<double> anglesToSearch = [];
    for (var angle in phases.keys) {
      if (angle >= currentAngle) {
        anglesToSearch.add(angle);
      }
    }
    if (anglesToSearch.isEmpty) {
      anglesToSearch = phases.keys.toList();
    }
    anglesToSearch.sort();

    for (var angle in anglesToSearch) {
      final name = phases[angle];
      DateTime? time = _findSpecificPhaseTime(now, angle, daysRange: 30);
      
      if (time != null && time.isAfter(now)) {
        if (nextPhaseTime == null || time.isBefore(nextPhaseTime)) {
          nextPhaseTime = time;
          nextPhaseName = name;
        }
      }
    }

    if (nextPhaseTime == null) {
      final nextMonthDate = now.add(Duration(days: 30));
      for (var angle in phases.keys) {
        final name = phases[angle];
        DateTime? time = _findSpecificPhaseTime(nextMonthDate, angle, daysRange: 30);
        if (time != null && (nextPhaseTime == null || time.isBefore(nextPhaseTime))) {
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

    // 달이 현재 별자리에 들어간 시간을 찾습니다. 최대 3일 전까지 검색합니다.
    final utcStartTime = _findTimeOfLongitude(
      date.subtract(const Duration(days: 3)),
      date,
      currentSignLon,
    );
    if (utcStartTime != null) {
      signStartTime = utcStartTime.toLocal();
    }

    // 달이 다음 별자리에 들어가는 시간을 찾습니다. 최대 3일 후까지 검색합니다.
    final utcEndTime = _findTimeOfLongitude(
      date,
      date.add(const Duration(days: 3)),
      nextSignLon,
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
    double targetLon,
  ) {
    targetLon = Sweph.swe_degnorm(targetLon);
    DateTime utcStart = start.toUtc();
    DateTime utcEnd = end.toUtc();

    double startLon;
    try {
      startLon = Sweph.swe_degnorm(getLongitude(HeavenlyBody.SE_MOON, utcStart));
    } catch (e) {
      return null; // 위치를 계산할 수 없는 경우
    }

    final targetFromStart = (targetLon - startLon + 360) % 360;

    // 검색 범위 내에 목표 각도가 있는지 확인합니다.
    double endLon;
    try {
      endLon = Sweph.swe_degnorm(getLongitude(HeavenlyBody.SE_MOON, utcEnd));
    } catch (e) {
      return null; // 위치를 계산할 수 없는 경우
    }
    final range = (endLon - startLon + 360) % 360;

    // 목표 각도가 검색 범위를 벗어나면 일찍 종료합니다.
    if (targetFromStart > range + 0.1) {
      return null;
    }

    // 이진 탐색으로 정확한 시간을 찾습니다.
    for (int i = 0; i < 100; i++) {
      if (utcStart.isAtSameMomentAs(utcEnd)) break;
      final mid = utcStart.add(Duration(milliseconds: utcEnd.difference(utcStart).inMilliseconds ~/ 2));
      if (mid.isAtSameMomentAs(utcStart) || mid.isAtSameMomentAs(utcEnd)) break;

      final midLon = Sweph.swe_degnorm(getLongitude(HeavenlyBody.SE_MOON, mid));
      final delta = Sweph.swe_degnorm(midLon - targetLon);

      if (delta < 0.0001 || delta > 359.9999) {
        return mid.toLocal(); // 정확한 시간을 찾았습니다.
      }

      // 순환 경로를 따라 진행 상황을 비교하여 검색을 안내합니다.
      if (((midLon - startLon + 360) % 360) < targetFromStart) {
        utcStart = mid;
      } else {
        utcEnd = mid;
      }
    }
    
    // 100회 반복 후에도 정확한 시간을 찾지 못한 경우, null을 반환하여 호출자가 처리하도록 합니다.
    return null;
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

    double startDiff, endDiff;
    try {
      final startMoonLon = getLongitude(HeavenlyBody.SE_MOON, utcStart);
      final startPlanetLon = getLongitude(planet, utcStart);
      startDiff = Sweph.swe_degnorm(startMoonLon - startPlanetLon);

      final endMoonLon = getLongitude(HeavenlyBody.SE_MOON, utcEnd);
      final endPlanetLon = getLongitude(planet, utcEnd);
      endDiff = Sweph.swe_degnorm(endMoonLon - endPlanetLon);
    } catch (e) {
      return null; // Position not available
    }

    final range = (endDiff - startDiff + 360) % 360;
    final targetFromStart = (targetDiff - startDiff + 360) % 360;

    // Exit early if the target aspect is not within the search window.
    if (targetFromStart > range + 0.01) {
      return null;
    }

    // Binary search for the exact time.
    for (int i = 0; i < 100; i++) {
      final mid = utcStart.add(Duration(milliseconds: utcEnd.difference(utcStart).inMilliseconds ~/ 2));
      if (mid.isAtSameMomentAs(utcStart) || mid.isAtSameMomentAs(utcEnd)) break;

      final moonLon = getLongitude(HeavenlyBody.SE_MOON, mid);
      final planetLon = getLongitude(planet, mid);
      final midDiff = Sweph.swe_degnorm(moonLon - planetLon);

      final delta = Sweph.swe_degnorm(midDiff - targetDiff);
      if (delta < 0.001 || delta > 359.999) {
        // print('Aspect found at $mid: moonLon=$moonLon, planetLon=$planetLon, angle=$midDiff');
        return mid.toLocal();
      }

      // Guide the search by comparing the progress along the circular path.
      if (((midDiff - startDiff + 360) % 360) < targetFromStart) {
        utcStart = mid;
      } else {
        utcEnd = mid;
      }
    }
    return null;
  }

  DateTime? _findLastAspectTime(DateTime moonSignEntryTime, DateTime moonSignExitTime) {
    DateTime? lastAspectTime;

    // print('Searching aspects between $moonSignEntryTime and $moonSignExitTime');

    for (final planet in majorPlanets) {
      for (final aspect in majorAspects) {
        List<double> targets = [aspect];
        if (aspect > 0 && aspect < 180) {
          targets.add(360 - aspect);
        }

        for (final targetDiff in targets) {
          final aspectTime = _findExactAspectTime(
            moonSignEntryTime,
            moonSignExitTime,
            planet,
            targetDiff,
          );

          if (aspectTime != null) {
            // print('Found aspect at $aspectTime with planet $planet, angle $targetDiff');
            if (lastAspectTime == null || aspectTime.isAfter(lastAspectTime)) {
              lastAspectTime = aspectTime;
            }
          }
        }
      }
    }

    // print('Last aspect time: $lastAspectTime');
    return lastAspectTime;
  }

  Map<String, dynamic> findVoidOfCoursePeriod(DateTime date) {
    final moonSignTimes = getMoonSignTimes(date);
    final signStartTime = moonSignTimes['start'];
    final signEndTime = moonSignTimes['end'];

    if (signStartTime == null || signEndTime == null) {
      // print('No sign times available for $date');
      return {'start': null, 'end': null};
    }

    // print('Moon sign period for $date: $signStartTime to $signEndTime');

    final lastAspectTime = _findLastAspectTime(signStartTime, signEndTime);

    if (lastAspectTime != null) {
      // VoC starts from the last aspect and ends when moon changes sign.
      // print('VoC found: $lastAspectTime to $signEndTime');
      return {'start': lastAspectTime, 'end': signEndTime};
    } else {
      // If there are no aspects, the moon is VoC for the entire sign.
      // print('No aspects in sign. VoC is from sign entry: $signStartTime to $signEndTime');
      return {'start': signStartTime, 'end': signEndTime};
    }
  }

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
        return '❓';
    }
  }

  String getMoonPhaseNameOnly(String moonPhaseName) {
    return moonPhaseName.replaceAll(RegExp(r'^\S+\s'), '');
  }
}
