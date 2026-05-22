import 'dart:developer' as developer;

import 'dart:ui';


import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';

import 'package:flutter/foundation.dart';

import 'package:home_widget/home_widget.dart';

import 'package:intl/intl.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:sweph/sweph.dart';

import 'package:timezone/data/latest_all.dart' as tz_data;

import 'package:timezone/timezone.dart' as tz;


import 'astro_calculator.dart';


const int _widgetVocStartAlarmId = 110;

const int _widgetVocEndAlarmId = 111;


class WidgetService {

  static const String appGroupId = 'dev.lioluna.voidofcourse';

  static const String androidWidgetName = 'VocWidgetProvider';


  static final AstroCalculator _calculator = AstroCalculator();


  static const String _installedPrefKey = 'hasHomeWidgetInstalled';


  /// 홈 위젯 설치 여부 (앱·알람 콜백·네이티브 onEnabled 공통)

  static Future<bool> refreshInstalledFlag(
    SharedPreferences? prefs, {
    bool allowClear = true,
  }) async {
    final p = prefs ?? await SharedPreferences.getInstance();
    try {
      final widgets = await HomeWidget.getInstalledWidgets();
      if (widgets.isNotEmpty) {
        await p.setBool(_installedPrefKey, true);
        return true;
      }
      if (allowClear) {
        await p.setBool(_installedPrefKey, false);
        return false;
      }
      return p.getBool(_installedPrefKey) ?? false;
    } catch (e) {
      if (kDebugMode) {
        developer.log(
          'getInstalledWidgets failed, using pref: $e',
          name: 'WidgetService',
        );
      }
      return p.getBool(_installedPrefKey) ?? false;
    }
  }

  /// 알람·백그라운드: pref 우선 (getInstalledWidgets가 빈 목록을 줄 수 있음)
  static Future<bool> isEnabled([SharedPreferences? prefs]) async {
    final p = prefs ?? await SharedPreferences.getInstance();
    if (p.getBool(_installedPrefKey) ?? false) return true;
    return refreshInstalledFlag(p);
  }


  static Future<void> setInstallStatus(bool installed) async {

    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(_installedPrefKey, installed);

  }


  static Future<void> cancelRefreshAlarms() async {

    await AndroidAlarmManager.cancel(_widgetVocStartAlarmId);

    await AndroidAlarmManager.cancel(_widgetVocEndAlarmId);

  }


  /// 선택 타임존 기준 현재 보이드 또는 다음 보이드 구간 (앱 없이 알람에서도 재계산)

  static Future<({DateTime start, DateTime end})?> resolveCurrentVocPeriod(

    SharedPreferences prefs,

  ) async {

    await Sweph.init();

    tz_data.initializeTimeZones();


    final selectedTimezoneId =

        prefs.getString('selected_timezone') ??

        prefs.getString('cached_selected_timezone') ??

        'Asia/Seoul';

    final location = tz.getLocation(selectedTimezoneId);

    final utcNow = DateTime.now().toUtc();

    final tzNow = tz.TZDateTime.from(utcNow, location);


    DateTime searchDate = tz.TZDateTime(

      location,

      tzNow.year,

      tzNow.month,

      tzNow.day,

    ).toUtc();


    for (int i = 0; i < 10; i++) {

      final vocTimes = _calculator.findVoidOfCoursePeriod(searchDate);

      final start = vocTimes['start'] as DateTime?;

      final end = vocTimes['end'] as DateTime?;


      if (start == null || end == null) {

        searchDate = searchDate.add(const Duration(days: 1));

        continue;

      }


      if (utcNow.isAfter(start) && utcNow.isBefore(end)) {

        return (start: start, end: end);

      }

      if (end.isAfter(utcNow)) {

        return (start: start, end: end);

      }

      searchDate = end.add(const Duration(minutes: 1));

    }

    return null;

  }


  /// 보이드 시작/종료 시각 알람으로 위젯 갱신 (배터리: 하루 2회 수준, 폴링 없음)

  static Future<void> refreshFromPrefs({bool advanceAfterEnd = false}) async {

    try {

      DartPluginRegistrant.ensureInitialized();

      await AndroidAlarmManager.initialize();


      final prefs = await SharedPreferences.getInstance();

      if (!await refreshInstalledFlag(prefs, allowClear: false)) return;


      await prefs.reload();


      final period = await resolveCurrentVocPeriod(prefs);

      if (period == null) {

        if (kDebugMode) {

          developer.log('No VOC period for widget', name: 'WidgetService');

        }

        return;

      }


      await cacheVocPeriod(

        prefs,

        vocStart: period.start,

        vocEnd: period.end,

      );


      final utcNow = DateTime.now().toUtc();

      DateTime? nextVocStart;

      DateTime? nextVocEnd;

      if (utcNow.isAfter(period.start) && utcNow.isBefore(period.end)) {

        final next = await findNextVocPeriod(period.end);

        nextVocStart = next?.start;

        nextVocEnd = next?.end;

      }


      final moonZodiac = _calculator.getMoonZodiacEmoji(utcNow);


      await updateWidgetData(

        vocStart: period.start,

        vocEnd: period.end,

        nextVocStart: nextVocStart,

        nextVocEnd: nextVocEnd,

        moonZodiac: moonZodiac,

      );


      await scheduleRefreshAlarms(vocStart: period.start, vocEnd: period.end);

    } catch (e, stack) {

      if (kDebugMode) {

        developer.log(

          'refreshFromPrefs failed: $e\n$stack',

          name: 'WidgetService',

        );

      }

    }

  }


  static Future<({DateTime start, DateTime end})?> findNextVocPeriod(

    DateTime afterUtc,

  ) async {

    await Sweph.init();

    final utcNow = DateTime.now().toUtc();

    var searchDate = afterUtc.add(const Duration(minutes: 1));

    if (searchDate.isBefore(utcNow)) {

      searchDate = utcNow;

    }


    for (int i = 0; i < 10; i++) {

      final vocTimes = _calculator.findVoidOfCoursePeriod(searchDate);

      final start = vocTimes['start'] as DateTime?;

      final end = vocTimes['end'] as DateTime?;


      if (start == null || end == null) {

        searchDate = searchDate.add(const Duration(days: 1));

        continue;

      }

      if (end.isBefore(utcNow)) {

        searchDate = end.add(const Duration(minutes: 1));

        continue;

      }

      return (start: start, end: end);

    }

    return null;

  }




  static Future<void> cacheVocPeriod(

    SharedPreferences prefs, {

    required DateTime? vocStart,

    required DateTime? vocEnd,

  }) async {

    if (vocStart == null || vocEnd == null) return;

    await prefs.setString('cached_voc_start', vocStart.toIso8601String());

    await prefs.setString('cached_voc_end', vocEnd.toIso8601String());

  }


  static Future<void> updateWidgetData({

    required DateTime? vocStart,

    required DateTime? vocEnd,

    required DateTime? nextVocStart,

    required DateTime? nextVocEnd,

    required String moonZodiac,

  }) async {

    try {

      final now = DateTime.now().toUtc();


      var displayStart = vocStart;

      var displayEnd = vocEnd;


      if (displayEnd != null && now.isAfter(displayEnd)) {

        if (nextVocStart != null && nextVocEnd != null) {

          displayStart = nextVocStart;

          displayEnd = nextVocEnd;

        } else {

          final next = await findNextVocPeriod(displayEnd);

          if (next != null) {

            displayStart = next.start;

            displayEnd = next.end;

          }

        }

      }


      String widgetIcon = '✅';

      String widgetStartTimeText = 'N/A';

      String widgetEndTimeText = 'N/A';


      final prefs = await SharedPreferences.getInstance();

      final selectedTimezoneId =

          prefs.getString('selected_timezone') ?? 'Asia/Seoul';

      final location = tz.getLocation(selectedTimezoneId);

      final tzNow = tz.TZDateTime.from(now, location);


      bool isVocNow = false;

      if (displayStart != null && displayEnd != null) {

        isVocNow = now.isAfter(displayStart) && now.isBefore(displayEnd);

      }


      bool doesSelectedDateHaveVoc = false;

      if (displayStart != null && displayEnd != null) {

        final selectedDayStart = tz.TZDateTime(

          location,

          tzNow.year,

          tzNow.month,

          tzNow.day,

        );

        final selectedDayEnd = selectedDayStart.add(const Duration(days: 1));


        if (displayStart.isBefore(selectedDayEnd) &&

            displayEnd.isAfter(selectedDayStart)) {

          doesSelectedDateHaveVoc = true;

        }

      }


      final localeStr = prefs.getString('cached_language_code') ?? 'en';

      final dateFormat = DateFormat('MM/dd HH:mm', localeStr);


      if (isVocNow) {

        widgetIcon = '🚫';

        widgetStartTimeText = dateFormat.format(

          tz.TZDateTime.from(displayStart!, location),

        );

        widgetEndTimeText = dateFormat.format(

          tz.TZDateTime.from(displayEnd!, location),

        );

      } else if (doesSelectedDateHaveVoc &&

          displayStart != null &&

          displayStart.isAfter(now)) {

        widgetIcon = '🔔';

        widgetStartTimeText = dateFormat.format(

          tz.TZDateTime.from(displayStart, location),

        );

        widgetEndTimeText = dateFormat.format(

          tz.TZDateTime.from(displayEnd!, location),

        );

      } else if (displayStart != null && displayStart.isAfter(now)) {

        widgetIcon = '✅';

        widgetStartTimeText = dateFormat.format(

          tz.TZDateTime.from(displayStart, location),

        );

        if (displayEnd != null) {

          widgetEndTimeText = dateFormat.format(

            tz.TZDateTime.from(displayEnd, location),

          );

        }

      } else if (displayStart != null && displayEnd != null) {

        widgetIcon = '✅';

        widgetStartTimeText = dateFormat.format(

          tz.TZDateTime.from(displayStart, location),

        );

        widgetEndTimeText = dateFormat.format(

          tz.TZDateTime.from(displayEnd, location),

        );

      }


      await HomeWidget.saveWidgetData<String>('widget_icon', widgetIcon);

      await HomeWidget.saveWidgetData<String>(

        'widget_title_text',

        '🌙 Void of course  $moonZodiac',

      );

      await HomeWidget.saveWidgetData<String>(

        'widget_times_text',

        'Start : $widgetStartTimeText\nEnd   : $widgetEndTimeText',

      );

      await HomeWidget.updateWidget(androidName: androidWidgetName);


      if (kDebugMode) {

        developer.log(

          'Widget updated: $widgetIcon Start: $widgetStartTimeText End: $widgetEndTimeText',

          name: 'WidgetService',

        );

      }

    } catch (e) {

      if (kDebugMode) {

        developer.log('Error updating widget: $e', name: 'WidgetService');

      }

    }

  }


  /// 보이드 시작/종료 시각에만 깨움 (날씨 앱처럼 이벤트 기반, 상시 폴링 없음)

  static Future<void> scheduleRefreshAlarms({

    required DateTime vocStart,

    required DateTime vocEnd,

  }) async {

    if (!await refreshInstalledFlag(null, allowClear: false)) return;


    final utcNow = DateTime.now().toUtc();


    await AndroidAlarmManager.cancel(_widgetVocStartAlarmId);

    await AndroidAlarmManager.cancel(_widgetVocEndAlarmId);


    if (vocStart.isAfter(utcNow)) {

      await AndroidAlarmManager.oneShotAt(

        vocStart,

        _widgetVocStartAlarmId,

        _widgetVocStartAlarmCallback,

        exact: true,

        wakeup: true,

        allowWhileIdle: true,

        rescheduleOnReboot: true,

      );

      if (kDebugMode) {

        developer.log(

          'Widget alarm scheduled at voc start: $vocStart',

          name: 'WidgetService',

        );

      }

    }


    if (vocEnd.isAfter(utcNow)) {

      await AndroidAlarmManager.oneShotAt(

        vocEnd,

        _widgetVocEndAlarmId,

        _widgetVocEndAlarmCallback,

        exact: true,

        wakeup: true,

        allowWhileIdle: true,

        rescheduleOnReboot: true,

      );

      if (kDebugMode) {

        developer.log(

          'Widget alarm scheduled at voc end: $vocEnd',

          name: 'WidgetService',

        );

      }

    }

  }

}


@pragma('vm:entry-point')

Future<void> _widgetVocStartAlarmCallback() async {

  await WidgetService.refreshFromPrefs();

}


@pragma('vm:entry-point')

Future<void> _widgetVocEndAlarmCallback() async {

  await WidgetService.refreshFromPrefs();

}

