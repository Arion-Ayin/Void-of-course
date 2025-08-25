import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    tz.initializeTimeZones();

    await _notificationsPlugin.initialize(initializationSettings);
  }

  Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      final bool? androidResult = await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      return androidResult ?? false;
    }
    return false;
  }

  Future<bool> checkExactAlarmPermission() async {
    if (Platform.isAndroid) {
      final bool? canSchedule = await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.canScheduleExactNotifications();
      return canSchedule ?? false;
    }
    return true;
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    required bool canScheduleExact,
  }) async {
    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'void_channel_id',
          'Void Notifications',
          channelDescription: 'Notifications for Void of Course periods',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: canScheduleExact
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexact,
    );
  }

  // 화면에 계속 떠 있는 알람을 보여주는 함수예요. (진동 없음)
  Future<void> showOngoingNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    // 진동과 소리가 없는 채널을 사용합니다.
    const NotificationDetails notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'ongoing_void_channel_id',
        'Ongoing Void Notifications',
        channelDescription: 'Persistent notification during Void of Course',
        importance: Importance.low, // 진동 없이 조용히
        priority: Priority.low,
        ongoing: true, // 지워지지 않게 고정
        autoCancel: false,
        enableVibration: false,
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

  // 즉시 알람을 보여주는 함수예요. (스케줄링 없이)
  Future<void> showImmediateNotification({
    required int id,
    required String title,
    required String body,
    bool isVibrate = false,
  }) async {
    // isVibrate 값에 따라 채널을 다르게 사용
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