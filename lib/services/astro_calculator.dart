// 이 파일은 별자리와 달의 움직임 같은 것을 계산하는 '점성술 계산기'예요.
// 달이 어떤 별자리에 있는지, 달의 모양(위상)은 어떤지 같은 것을 알려줘요.
// 'sweph'라는 아주 정확한 계산을 해주는 도구를 사용해요.

import 'package:sweph/sweph.dart'; // 천문학 계산을 위한 'sweph' 도구를 가져와요.
import 'package:intl/intl.dart'; // 날짜와 시간을 보기 좋게 바꾸는 도구를 가져와요.

// 점성술에 필요한 것들을 계산하는 특별한 상자(클래스)예요.
class AstroCalculator {
  // 열두 별자리의 기호를 순서대로 적어놓은 목록이에요.
  static const List<String> zodiacSigns = [
    '♈︎', '♉︎', '♊︎', '♋︎', '♌︎', '♍︎', '♎︎', '♏︎', '♐︎', '♑︎', '♒︎', '♓︎',
  ];

  // 열두 별자리의 영어 이름을 순서대로 적어놓은 목록이에요.
  static const List<String> zodiacNames = [
    'Aries', 'Taurus', 'Gemini', 'Cancer', 'Leo', 'Virgo', 'Libra', 'Scorpio', 'Sagittarius', 'Capricorn', 'Aquarius', 'Pisces',
  ];

  // 달의 모양(위상)을 이름과 함께 적어놓은 목록이에요.
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

  // 해와 달을 제외한 주요 행성들을 목록으로 만들었어요.
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

  // 점성술에서 중요하다고 여기는 각도(어스펙트)들을 목록으로 만들었어요.
  static const List<double> majorAspects = [0, 60, 90, 120, 180];

  // 날짜와 시간을 '줄리안 데이'라는 특별한 숫자로 바꿔주는 함수예요.
  // 천문학자들은 이 숫자로 날짜를 더 쉽게 계산해요.
  double getJulianDay(DateTime date) {
    final utcDate = date.toUtc(); // 시간을 모든 나라에서 똑같은 'UTC' 시간으로 바꿔요.
    final jdList = Sweph.swe_utc_to_jd( // 'sweph' 도구를 써서 줄리안 데이를 계산해요.
      utcDate.year,
      utcDate.month,
      utcDate.day,
      utcDate.hour,
      utcDate.minute,
      utcDate.second.toDouble(),
      CalendarType.SE_GREG_CAL,
    );
    return jdList[0]; // 계산된 줄리안 데이 숫자만 가져와요.
  }

  // 어떤 별이나 행성의 위치(경도)를 찾아주는 함수예요.
  double getLongitude(HeavenlyBody body, DateTime date) {
    final jd = getJulianDay(date); // 먼저 날짜를 줄리안 데이로 바꿔요.
    final pos = Sweph.swe_calc_ut(jd, body, SwephFlag.SEFLG_SWIEPH); // 'sweph' 도구로 위치를 계산해요.
    return pos.longitude!; // 계산된 경도(위치)를 알려줘요.
  }

  // 해와 달의 위치(경도)를 동시에 찾아주는 함수예요.
  Map<String, double> getSunMoonLongitude(DateTime date) {
    final jd = getJulianDay(date); // 날짜를 줄리안 데이로 바꿔요.
    final sun = Sweph.swe_calc_ut(jd, HeavenlyBody.SE_SUN, SwephFlag.SEFLG_SWIEPH); // 해의 위치를 계산해요.
    final moon = Sweph.swe_calc_ut(jd, HeavenlyBody.SE_MOON, SwephFlag.SEFLG_SWIEPH); // 달의 위치를 계산해요.
    // 만약 위치를 찾지 못했다면, '오류가 났어요'라고 알려줘요.
    if (sun.longitude == null || moon.longitude == null) {
      throw Exception('Sun or Moon position not available.');
    }
    return {'sun': sun.longitude!, 'moon': moon.longitude!}; // 해와 달의 위치를 알려줘요.
  }

  // 달의 현재 모양(위상)이 무엇인지 찾아주는 함수예요.
  Map<String, dynamic> getMoonPhaseInfo(DateTime date) {
    final positions = getSunMoonLongitude(date); // 해와 달의 위치를 가져와요.
    final sunLon = positions['sun']!;
    final moonLon = positions['moon']!;
    final angle = Sweph.swe_degnorm(moonLon - sunLon); // 해와 달 사이의 각도를 계산해요.

    String phaseName; // 달의 모양 이름을 담을 상자예요.
    if (angle < 45) {
      phaseName = '🌑 New Moon'; // 각도가 45도보다 작으면 '초승달'
    } else if (angle < 90) {
      phaseName = '🌒 Crescent Moon'; // 각도가 90도보다 작으면 '상현달'
    } else if (angle < 135) {
      phaseName = '🌓 First Quarter';
    } else if (angle < 180) {
      phaseName = '🌔 Gibbous Moon';
    } else if (angle < 225) {
      phaseName = '🌕 Full Moon'; // 각도가 180도보다 작으면 '보름달'
    } else if (angle < 270) {
      phaseName = '🌖 Disseminating Moon';
    } else if (angle < 315) {
      phaseName = '🌗 Last Quarter';
    } else {
      phaseName = '🌘 Balsamic Moon';
    }
    
    return {'phaseName': phaseName}; // 달의 모양 이름을 알려줘요.
  }

  // 다음 주요 달의 모양(초승달, 상현달, 보름달, 하현달)이 언제인지 찾아주는 함수예요.
  Map<String, dynamic> findNextPrimaryPhase(DateTime date) {
    final now = date;

    // 주요 달 모양과 그 각도를 미리 정해놔요.
    final phases = {
      0.0: '🌑 New Moon',
      90.0: '🌓 First Quarter',
      180.0: '🌕 Full Moon',
      270.0: '🌗 Last Quarter',
    };

    DateTime? bestTime; // 가장 가까운 시간을 담을 상자예요.
    String? bestName; // 가장 가까운 달 모양 이름을 담을 상자예요.

    // 각 달 모양을 차례대로 확인해요.
    for (var entry in phases.entries) {
      final targetAngle = entry.key;
      final name = entry.value;

      final positions = getSunMoonLongitude(now);
      final currentAngle = Sweph.swe_degnorm(positions['moon']! - positions['sun']!);

      // 목표 각도까지 얼마나 남았는지 계산해요.
      var deg_to_go = (targetAngle - currentAngle + 360) % 360;
      if (deg_to_go < 0.5) {
        deg_to_go += 360;
      }

      // 달은 하루에 약 12.19도씩 움직여요. 이걸로 대략적인 시간을 계산해요.
      var days_to_go = deg_to_go / 12.19;
      DateTime estimated_time = now.add(Duration(microseconds: (days_to_go * 24 * 3600 * 1000000).round()));

      // 정확한 시간을 다시 찾아봐요.
      var time = _findSpecificPhaseTime(estimated_time, targetAngle, daysRange: 2);

      // 만약 찾은 시간이 지금보다 전이라면, 다음 달 주기로 넘어가서 다시 찾아봐요.
      if (time != null && time.isBefore(now)) {
        time = _findSpecificPhaseTime(estimated_time.add(const Duration(days: 28)), targetAngle, daysRange: 3);
      }

      // 가장 가까운 시간을 찾아서 저장해요.
      if (time != null) {
        if (bestTime == null || time.isBefore(bestTime)) {
          bestTime = time;
          bestName = name;
        }
      }
    }

    return {'name': bestName, 'time': bestTime}; // 가장 가까운 달 모양과 시간을 알려줘요.
  }

  // 다음 달 모양이 언제인지 찾아주는 함수예요. (주요 모양이 아니라도)
  Map<String, dynamic> findNextPhase(DateTime date) {
    final now = date;

    // 1. 현재 해와 달의 각도를 계산해요.
    final positions = getSunMoonLongitude(now);
    final currentAngle = Sweph.swe_degnorm(positions['moon']! - positions['sun']!);

    // 2. 현재 각도에 따라 다음 달 모양의 각도와 이름을 정해요.
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
    } else { // 현재 각도가 315도 이상이라면, 다음은 다시 초승달(New Moon)이에요.
      nextAngle = 0.0;
      nextName = '🌑 New Moon';
    }

    // 3. 다음 달 모양이 나타나는 정확한 시간을 찾아봐요.
    var deg_to_go = (nextAngle - currentAngle + 360) % 360;
    if (deg_to_go == 0) deg_to_go = 360; // 안전을 위한 코드예요.
    
    var days_to_go = deg_to_go / (360 / 29.530588861); // 달 주기를 이용해 대략적인 시간을 계산해요.
    DateTime estimated_time = now.add(Duration(microseconds: (days_to_go * 24 * 3600 * 1000000).round()));

    // 대략적인 시간을 기준으로 정확한 시간을 다시 찾아봐요.
    DateTime? final_time = _findSpecificPhaseTime(estimated_time, nextAngle, daysRange: 2);

    return {'name': nextName, 'time': final_time}; // 다음 달 모양과 시간을 알려줘요.
  }

  // 달이 현재 어떤 별자리에 있는지 기호로 알려주는 함수예요.
  String getMoonZodiacEmoji(DateTime date) {
    final moonLon = getLongitude(HeavenlyBody.SE_MOON, date); // 달의 위치를 가져와요.
    final signIndex = ((moonLon % 360) / 30).floor(); // 위치를 별자리 번호로 바꿔요.
    return zodiacSigns[signIndex]; // 별자리 기호를 알려줘요.
  }

  // 달이 현재 어떤 별자리에 있는지 이름으로 알려주는 함수예요.
  String getMoonZodiacName(DateTime date) {
    final moonLon = getLongitude(HeavenlyBody.SE_MOON, date); // 달의 위치를 가져와요.
    final signIndex = ((moonLon % 360) / 30).floor(); // 위치를 별자리 번호로 바꿔요.
    return zodiacNames[signIndex]; // 별자리 이름을 알려줘요.
  }

  // 달이 특정 별자리에 들어오고 나가는 시간을 찾아주는 함수예요.
  Map<String, DateTime?> getMoonSignTimes(DateTime date) {
    final moonLon = getLongitude(HeavenlyBody.SE_MOON, date); // 달의 위치를 가져와요.
    final currentSignLon = (moonLon / 30).floor() * 30.0; // 현재 별자리의 시작 위치를 찾아요.
    final nextSignLon = (currentSignLon + 30.0) % 360; // 다음 별자리의 시작 위치를 찾아요.

    DateTime? signStartTime; // 별자리에 들어오는 시간
    DateTime? signEndTime; // 별자리에서 나가는 시간

    // 달이 현재 별자리에 들어온 시간을 찾아봐요.
    final utcStartTime = _findTimeOfLongitude(
      date.subtract(const Duration(days: 3)), // 3일 전부터 오늘까지 찾아봐요.
      date,
      currentSignLon,
    );
    if (utcStartTime != null) {
      signStartTime = utcStartTime.toLocal(); // 시간을 우리나라 시간으로 바꿔요.
    }

    // 달이 다음 별자리로 나가는 시간을 찾아봐요.
    final utcEndTime = _findTimeOfLongitude(
      date,
      date.add(const Duration(days: 3)), // 오늘부터 3일 후까지 찾아봐요.
      nextSignLon,
    );
    if (utcEndTime != null) {
      signEndTime = utcEndTime.toLocal(); // 시간을 우리나라 시간으로 바꿔요.
    }

    return {'start': signStartTime, 'end': signEndTime}; // 들어오고 나가는 시간을 알려줘요.
  }

  // 달 모양(위상)이 정확히 언제 나타나는지 찾아주는 숨겨진 함수예요. (다른 함수에서만 사용)
  // '이분법'이라는 똑똑한 방법으로 시간을 아주 정확하게 찾아요.
  DateTime? _findSpecificPhaseTime(DateTime date, double targetAngle, {int daysRange = 14}) {
    DateTime utcStart = date.subtract(Duration(days: daysRange)).toUtc(); // 찾기 시작하는 시간
    DateTime utcEnd = date.add(Duration(days: daysRange)).toUtc(); // 찾기 끝나는 시간
    
    // 100번 반복해서 아주 정확한 시간을 찾을 때까지 범위를 반씩 줄여나가요.
    for (int i = 0; i < 100; i++) {
      if (utcStart.isAtSameMomentAs(utcEnd)) break;
      final mid = utcStart.add(Duration(milliseconds: utcEnd.difference(utcStart).inMilliseconds ~/ 2)); // 중간 시간을 찾아요.
      if (mid.isAtSameMomentAs(utcStart) || mid.isAtSameMomentAs(utcEnd)) break;

      final positions = getSunMoonLongitude(mid);
      final sunLon = positions['sun']!;
      final moonLon = positions['moon']!;
      final angle = Sweph.swe_degnorm(moonLon - sunLon); // 중간 시간의 해와 달 각도를 계산해요.

      final delta = Sweph.swe_degnorm(angle - targetAngle);

      // 만약 찾은 각도가 목표 각도와 아주 비슷하면 시간을 알려주고 끝내요.
      if (delta < 0.0005 || delta > 359.9995) {
        return mid.toLocal();
      }

      // 만약 각도가 목표보다 앞서면 끝나는 시간을 중간으로 바꿔서 범위를 줄여요.
      if (delta < 180) {
        utcEnd = mid;
      } else { // 각도가 목표보다 뒤에 있으면 시작 시간을 중간으로 바꿔서 범위를 줄여요.
        utcStart = mid;
      }
    }
    return null; // 못 찾으면 '없어요'라고 알려줘요.
  }

  // 달이 특정 위치(경도)에 도착하는 시간을 찾아주는 숨겨진 함수예요.
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

    // 100번 반복해서 시간을 아주 정확하게 찾아요.
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

  // 달과 다른 행성 사이의 각도가 정확히 언제 나타나는지 찾아주는 숨겨진 함수예요.
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

    // 100번 반복해서 시간을 아주 정확하게 찾아요.
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

  // 달이 특정 별자리를 지나기 전에 마지막으로 행성들과 '좋은 만남'을 갖는 시간을 찾아주는 함수예요.
  DateTime? _findLastAspectTime(DateTime moonSignEntryTime, DateTime moonSignExitTime) {
    DateTime? lastAspectTime;

    // 모든 중요한 행성과 중요한 각도를 하나씩 확인해요.
    for (final planet in majorPlanets) {
      for (final aspect in majorAspects) {
        List<double> targets = [aspect];
        if (aspect > 0 && aspect < 180) { // 0도, 180도 외에 다른 각도도 반대쪽 각도를 추가해요.
          targets.add(360 - aspect);
        }

        for (final targetDiff in targets) {
          // 달이 별자리에 머무는 시간 동안 각도가 만들어지는지 찾아봐요.
          final aspectTime = _findExactAspectTime(
            moonSignEntryTime,
            moonSignExitTime,
            planet,
            targetDiff,
          );

          if (aspectTime != null) {
            // 가장 마지막에 나타난 각도의 시간을 저장해요.
            if (lastAspectTime == null || aspectTime.isAfter(lastAspectTime)) {
              lastAspectTime = aspectTime;
            }
          }
        }
      }
    }
    return lastAspectTime;
  }

  // 달이 힘을 잃는 시간(Void-of-Course, 보이드 오브 코스)을 찾아주는 함수예요.
  // 이 시간은 달이 다음 별자리로 가기 전에 다른 행성들과 중요한 만남이 없는 때를 말해요.
  Map<String, dynamic> findVoidOfCoursePeriod(DateTime date) {
    final dayStart = DateTime(date.year, date.month, date.day);
    var searchDate = dayStart;

    // 며칠간 반복해서 보이드 오브 코스 시간을 찾아요.
    for (int i = 0; i < 5; i++) {
      final moonSignTimes = getMoonSignTimes(searchDate); // 달이 별자리에 머무는 시간을 가져와요.
      final signStartTime = moonSignTimes['start'];
      final signEndTime = moonSignTimes['end'];

      if (signStartTime == null || signEndTime == null) {
        return {'start': null, 'end': null}; // 시간을 찾지 못하면 포기해요.
      }

      final lastAspectTime = _findLastAspectTime(signStartTime, signEndTime); // 마지막 만남 시간을 찾아봐요.

      DateTime? vocStart;
      if (lastAspectTime != null) {
        vocStart = lastAspectTime; // 마지막 만남 이후부터 보이드 시작이에요.
      } else {
        vocStart = signStartTime; // 만약 마지막 만남이 없으면 별자리에 들어온 순간부터 보이드 시작이에요.
      }
      final vocEnd = signEndTime; // 보이드 끝은 별자리에서 나가는 시간이에요.

      // 만약 오늘 이후에 보이드 오브 코스 시간이 있다면, 그 시간을 알려줘요.
      if (vocEnd.isAfter(dayStart)) {
        return {'start': vocStart, 'end': vocEnd};
      }
      // 오늘이 아니면 다음 별자리로 넘어가서 다시 찾아봐요.
      searchDate = signEndTime;
    }
    return {'start': null, 'end': null}; // 5일 내에 못 찾으면 '없어요'라고 알려줘요.
  }

  // 달의 모양 이름에 맞는 이모티콘을 찾아주는 함수예요.
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
        return '❓'; // 알 수 없는 이름이면 물음표를 보내요.
    }
  }

  // 달 모양 이름에서 이모티콘을 빼고 글씨만 남기는 함수예요.
  String getMoonPhaseNameOnly(String moonPhaseName) {
    return moonPhaseName.replaceAll(RegExp(r'^\S+\s'), ''); // 이모티콘을 찾아 지워요.
  }
}