// astro_calculator.dart
import 'package:sweph/sweph.dart';
import 'package:intl/intl.dart';

class AstroCalculator {
  static const List<String> zodiacSigns = [
    '♈︎', '♉︎', '♊︎', '♋︎', '♌︎', '♍︎', '♎︎', '♏︎', '♐︎', '♑︎', '♒︎', '♓︎',
  ];

  static const List<String> zodiacNames = [
    'Aries', 'Taurus', 'Gemini', 'Cancer', 'Leo', 'Virgo', 'Libra', 'Scorpio', 'Sagittarius', 'Capricorn', 'Aquarius', 'Pisces',
  ];

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
    if (angle < 45) {
      phaseName = '🌑 New Moon';
    } else if (angle < 90) {
      phaseName = '🌒 Crescent Moon';
    } else if (angle < 135) {
      phaseName = '🌓 First Quarter';
    } else if (angle < 180) {
      phaseName = '🌔 Gibbous Moon';
    } else if (angle < 225) {
      phaseName = '🌕 Full Moon';
    } else if (angle < 270) {
      phaseName = '🌖 Disseminating Moon';
    } else if (angle < 315) {
      phaseName = '🌗 Last Quarter';
    } else {
      phaseName = '🌘 Balsamic Moon';
    }
    
    return {'phaseName': phaseName};
  }

  Map<String, dynamic> findNextPrimaryPhase(DateTime date) {
    final now = date;
    final phases = {
      0.0: '🌑 New Moon',
      90.0: '🌓 First Quarter',
      180.0: '🌕 Full Moon',
      270.0: '🌗 Last Quarter',
    };

    DateTime? bestTime;
    String? bestName;

    for (var entry in phases.entries) {
      final targetAngle = entry.key;
      final name = entry.value;

      final positions = getSunMoonLongitude(now);
      final currentAngle = Sweph.swe_degnorm(positions['moon']! - positions['sun']!);

      var deg_to_go = (targetAngle - currentAngle + 360) % 360;
      if (deg_to_go < 0.5) {
        deg_to_go += 360;
      }

      var days_to_go = deg_to_go / 12.19;
      DateTime estimated_time = now.add(Duration(microseconds: (days_to_go * 24 * 3600 * 1000000).round()));

      var time = _findSpecificPhaseTime(estimated_time, targetAngle, daysRange: 2);

      if (time != null && time.isBefore(now)) {
        time = _findSpecificPhaseTime(estimated_time.add(const Duration(days: 28)), targetAngle, daysRange: 3);
      }

      if (time != null) {
        if (bestTime == null || time.isBefore(bestTime)) {
          bestTime = time;
          bestName = name;
        }
      }
    }

    return {'name': bestName, 'time': bestTime};
  }

  Map<String, dynamic> findNextPhase(DateTime date) {
    final now = date;

    // 1. Determine the current phase angle
    final positions = getSunMoonLongitude(now);
    final currentAngle = Sweph.swe_degnorm(positions['moon']! - positions['sun']!);

    // 2. Determine the next phase angle and name
    double nextAngle;
    String nextName;

    if (currentAngle < 45) {
      nextAngle = 45.0;
      nextName = '🌒 Crescent Moon';
    } else if (currentAngle < 90) {
      nextAngle = 90.0;
      nextName = '🌓 First Quarter';
    } else if (currentAngle < 135) {
      nextAngle = 135.0;
      nextName = '🌔 Gibbous Moon';
    } else if (currentAngle < 180) {
      nextAngle = 180.0;
      nextName = '🌕 Full Moon';
    } else if (currentAngle < 225) {
      nextAngle = 225.0;
      nextName = '🌖 Disseminating Moon';
    } else if (currentAngle < 270) {
      nextAngle = 270.0;
      nextName = '🌗 Last Quarter';
    } else if (currentAngle < 315) {
      nextAngle = 315.0;
      nextName = '🌘 Balsamic Moon';
    } else { // currentAngle >= 315
      nextAngle = 0.0;
      nextName = '🌑 New Moon';
    }

    // 3. Find the exact time of the next phase
    var deg_to_go = (nextAngle - currentAngle + 360) % 360;
    if (deg_to_go == 0) deg_to_go = 360; // Should not happen, but for safety
    
    var days_to_go = deg_to_go / (360 / 29.530588861); // ~12.19 deg/day
    DateTime estimated_time = now.add(Duration(microseconds: (days_to_go * 24 * 3600 * 1000000).round()));

    // Now search around the estimated time.
    DateTime? final_time = _findSpecificPhaseTime(estimated_time, nextAngle, daysRange: 2);

    return {'name': nextName, 'time': final_time};
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
    );
    if (utcStartTime != null) {
      signStartTime = utcStartTime.toLocal();
    }

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
      if (utcStart.isAtSameMomentAs(utcEnd)) break;
      final mid = utcStart.add(Duration(milliseconds: utcEnd.difference(utcStart).inMilliseconds ~/ 2));
      if (mid.isAtSameMomentAs(utcStart) || mid.isAtSameMomentAs(utcEnd)) break;

      final positions = getSunMoonLongitude(mid);
      final sunLon = positions['sun']!;
      final moonLon = positions['moon']!;
      final angle = Sweph.swe_degnorm(moonLon - sunLon);

      final delta = Sweph.swe_degnorm(angle - targetAngle);

      if (delta < 0.0005 || delta > 359.9995) { // Found it
        return mid.toLocal();
      }

      if (delta < 180) { // angle is ahead of target, so we went too far
        utcEnd = mid;
      } else { // angle is behind target, so we need to go further
        utcStart = mid;
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
      return null;
    }

    final targetFromStart = (targetLon - startLon + 360) % 360;
    double endLon;
    try {
      endLon = Sweph.swe_degnorm(getLongitude(HeavenlyBody.SE_MOON, utcEnd));
    } catch (e) {
      return null;
    }
    final range = (endLon - startLon + 360) % 360;

    if (targetFromStart > range + 0.1) {
      return null;
    }

    for (int i = 0; i < 100; i++) {
      if (utcStart.isAtSameMomentAs(utcEnd)) break;
      final mid = utcStart.add(Duration(milliseconds: utcEnd.difference(utcStart).inMilliseconds ~/ 2));
      if (mid.isAtSameMomentAs(utcStart) || mid.isAtSameMomentAs(utcEnd)) break;

      final midLon = Sweph.swe_degnorm(getLongitude(HeavenlyBody.SE_MOON, mid));
      final delta = Sweph.swe_degnorm(midLon - targetLon);

      if (delta < 0.0001 || delta > 359.9999) {
        return mid.toLocal();
      }

      if (((midLon - startLon + 360) % 360) < targetFromStart) {
        utcStart = mid;
      } else {
        utcEnd = mid;
      }
    }
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
      return null;
    }

    final range = (endDiff - startDiff + 360) % 360;
    final targetFromStart = (targetDiff - startDiff + 360) % 360;

    if (targetFromStart > range + 0.01) {
      return null;
    }

    for (int i = 0; i < 100; i++) {
      if (utcStart.isAtSameMomentAs(utcEnd)) break;
      final mid = utcStart.add(Duration(milliseconds: utcEnd.difference(utcStart).inMilliseconds ~/ 2));
      if (mid.isAtSameMomentAs(utcStart) || mid.isAtSameMomentAs(utcEnd)) break;

      final moonLon = getLongitude(HeavenlyBody.SE_MOON, mid);
      final planetLon = getLongitude(planet, mid);
      final midDiff = Sweph.swe_degnorm(moonLon - planetLon);

      final delta = Sweph.swe_degnorm(midDiff - targetDiff);
      if (delta < 0.001 || delta > 359.999) {
        return mid.toLocal();
      }

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
            if (lastAspectTime == null || aspectTime.isAfter(lastAspectTime)) {
              lastAspectTime = aspectTime;
            }
          }
        }
      }
    }
    return lastAspectTime;
  }

  Map<String, dynamic> findVoidOfCoursePeriod(DateTime date) {
    final dayStart = DateTime(date.year, date.month, date.day);
    var searchDate = dayStart;

    for (int i = 0; i < 5; i++) {
      final moonSignTimes = getMoonSignTimes(searchDate);
      final signStartTime = moonSignTimes['start'];
      final signEndTime = moonSignTimes['end'];

      if (signStartTime == null || signEndTime == null) {
        return {'start': null, 'end': null};
      }

      final lastAspectTime = _findLastAspectTime(signStartTime, signEndTime);

      DateTime? vocStart;
      if (lastAspectTime != null) {
        vocStart = lastAspectTime;
      } else {
        vocStart = signStartTime;
      }
      final vocEnd = signEndTime;

      if (vocEnd.isAfter(dayStart)) {
        return {'start': vocStart, 'end': vocEnd};
      }
      searchDate = signEndTime;
    }
    return {'start': null, 'end': null};
  }

  String getMoonPhaseEmoji(String moonPhaseName) {
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

  String getMoonPhaseNameOnly(String moonPhaseName) {
    return moonPhaseName.replaceAll(RegExp(r'^\S+\s'), '');
  }
}