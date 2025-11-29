import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:android_intent_plus/android_intent.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'void_channel_id',
      'Void Notifications',
      description: 'Notifications for Void of Course periods',
      importance: Importance.max,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    tz.initializeTimeZones();

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    await _notificationsPlugin.initialize(initializationSettings);
  }

  Future<void> requestBatteryOptimizationPermission() async {
    if (Platform.isAndroid) {
      const intent = AndroidIntent(
        action: 'android.settings.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS',
        data: 'package:dev.lioluna.voidofcourse',
      );
      await intent.launch();
    }
  }

  Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      final bool? androidResult =
          await _notificationsPlugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >()
              ?.requestNotificationsPermission();
      return androidResult ?? false;
    }
    return false;
  }

  Future<bool> checkExactAlarmPermission() async {
    if (Platform.isAndroid) {
      final bool? canSchedule =
          await _notificationsPlugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >()
              ?.canScheduleExactNotifications();
      return canSchedule ?? false;
    }
    return true;
  }

  Future<void> requestExactAlarmPermission() async {
    if (Platform.isAndroid) {
      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestExactAlarmsPermission();
    }
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    required bool canScheduleExact,
    bool usesChronometer = false,
    bool chronometerCountDown = false,
    int? when,
    bool isOngoing = false,
  }) async {
    if (Platform.isAndroid && canScheduleExact) {
      final bool hasExactAlarmPermission = await checkExactAlarmPermission();
      if (!hasExactAlarmPermission) {
        await requestExactAlarmPermission();
        if (!await checkExactAlarmPermission()) {
          print('Exact alarm permission denied');
          return;
        }
      }
    }

    final tzScheduledTime = tz.TZDateTime.from(scheduledTime, tz.local);
    print(
      'Scheduling notification for: $tzScheduledTime (Local time: $scheduledTime)',
    );

    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tzScheduledTime,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'void_channel_id',
          'Void Notifications',
          channelDescription: 'Notifications for Void of Course periods',
          importance: Importance.max,
          priority: Priority.high,
          usesChronometer: usesChronometer,
          chronometerCountDown: chronometerCountDown,
          when: when,
          ongoing: isOngoing,
          autoCancel: !isOngoing,
        ),
      ),
      androidScheduleMode:
          canScheduleExact
              ? AndroidScheduleMode.exactAllowWhileIdle
              : AndroidScheduleMode.inexact,
    );
  }

  Future<void> showOngoingNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    final BigTextStyleInformation bigTextStyleInformation =
        BigTextStyleInformation(
          body,
          contentTitle: title,
          htmlFormatBigText: false,
          htmlFormatContentTitle: false,
        );

    final NotificationDetails notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'ongoing_void_channel_id',
        'Ongoing Void Notifications',
        channelDescription: 'Persistent notification during Void of Course',
        importance: Importance.low,
        priority: Priority.low,
        ongoing: true,
        autoCancel: false,
        enableVibration: false,
        styleInformation: bigTextStyleInformation,
      ),
    );
    await _notificationsPlugin.show(id, title, body, notificationDetails);
  }

  Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }

  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }

  Future<void> showImmediateNotification({
    required int id,
    required String title,
    required String body,
    bool isVibrate = false,
  }) async {
    final NotificationDetails notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        isVibrate ? 'alert_void_channel' : 'void_channel_id',
        isVibrate ? 'Alerts' : 'Void Notifications',
        channelDescription: 'Notifications for Void of Course periods',
        importance: isVibrate ? Importance.max : Importance.max,
        priority: isVibrate ? Priority.high : Priority.high,
        ongoing: false,
        autoCancel: true,
        enableVibration: isVibrate,
      ),
    );
    await _notificationsPlugin.show(id, title, body, notificationDetails);
  }
}
