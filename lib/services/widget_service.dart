import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;

class WidgetService {
  static const String appGroupId =
      'dev.lioluna.voidofcourse'; // Not strictly needed for Android but good practice
  static const String androidWidgetName = 'VocWidgetProvider';

  static Future<void> updateWidgetData({
    required DateTime? vocStart,
    required DateTime? vocEnd,
    required DateTime? nextVocStart,
    required DateTime? nextVocEnd,
    required String moonZodiac,
  }) async {
    try {
      final now = DateTime.now().toUtc();

      String widgetIcon = '✅'; // Default: No VOC today
      String widgetStartTimeText = 'N/A';
      String widgetEndTimeText = 'N/A';

      // 1. Get current timezone
      final prefs = await SharedPreferences.getInstance();
      final selectedTimezoneId =
          prefs.getString('selected_timezone') ?? 'Asia/Seoul';
      final location = tz.getLocation(selectedTimezoneId);
      final tzNow = tz.TZDateTime.from(now, location);

      bool isVocNow = false;
      if (vocStart != null && vocEnd != null) {
        isVocNow = now.isAfter(vocStart) && now.isBefore(vocEnd);
      }

      bool doesSelectedDateHaveVoc = false;
      if (vocStart != null && vocEnd != null) {
        final selectedDayStart = tz.TZDateTime(
          location,
          tzNow.year,
          tzNow.month,
          tzNow.day,
        );
        final selectedDayEnd = selectedDayStart.add(const Duration(days: 1));

        if (vocStart.isBefore(selectedDayEnd) &&
            vocEnd.isAfter(selectedDayStart)) {
          doesSelectedDateHaveVoc = true;
        }
      }

      // Format based on locale (simple MM/dd HH:mm)
      final localeStr = prefs.getString('cached_language_code') ?? 'en';
      final dateFormat = DateFormat('MM/dd HH:mm', localeStr);

      if (isVocNow) {
        widgetIcon = '🚫';
        if (nextVocStart != null && nextVocEnd != null) {
          widgetStartTimeText = dateFormat.format(
            tz.TZDateTime.from(nextVocStart, location),
          );
          widgetEndTimeText = dateFormat.format(
            tz.TZDateTime.from(nextVocEnd, location),
          );
        } else {
          widgetStartTimeText = 'Calculating...';
          widgetEndTimeText = 'Calculating...';
        }
      } else if (doesSelectedDateHaveVoc &&
          vocStart != null &&
          vocStart.isAfter(now)) {
        // Today has VOC and it hasn't started yet
        widgetIcon = '🔔';
        widgetStartTimeText = dateFormat.format(
          tz.TZDateTime.from(vocStart, location),
        );
        if (vocEnd != null) {
          widgetEndTimeText = dateFormat.format(
            tz.TZDateTime.from(vocEnd, location),
          );
        }
      } else if (vocStart != null && vocStart.isAfter(now)) {
        // Next VOC is in the future but not today
        widgetIcon = '✅';
        widgetStartTimeText = dateFormat.format(
          tz.TZDateTime.from(vocStart, location),
        );
        if (vocEnd != null) {
          widgetEndTimeText = dateFormat.format(
            tz.TZDateTime.from(vocEnd, location),
          );
        }
      } else if (nextVocStart != null && nextVocEnd != null) {
        // current vocStart has passed, use nextVocStart
        widgetIcon = '✅';
        widgetStartTimeText = dateFormat.format(
          tz.TZDateTime.from(nextVocStart, location),
        );
        widgetEndTimeText = dateFormat.format(
          tz.TZDateTime.from(nextVocEnd, location),
        );
      }

      await HomeWidget.saveWidgetData<String>('widget_icon', widgetIcon);
      await HomeWidget.saveWidgetData<String>(
        'widget_title_text',
        '🌙 Void of course $moonZodiac',
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
}
