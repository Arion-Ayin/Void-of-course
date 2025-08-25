
import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  // 이 클래스가 앱 전체에서 하나만 있도록 하는 싱글톤 패턴이에요.
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // 알람 서비스를 초기화하는 함수예요.
  Future<void> init() async {
    // 안드로이드에서 사용할 알람 설정을 만들어요.
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // 안드로이드 설정으로만 알람 플러그인을 초기화해요.
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    // 타임존 데이터를 초기화해요.
    tz.initializeTimeZones();

    await _notificationsPlugin.initialize(initializationSettings);
  }

  // 사용자에게 알람 권한을 요청하는 함수예요. (안드로이드 13 이상)
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

  // 정확한 알람 권한이 있는지 확인하는 함수예요.
  Future<bool> checkExactAlarmPermission() async {
    if (Platform.isAndroid) {
      final bool? canSchedule = await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.canScheduleExactNotifications();
      return canSchedule ?? false;
    }
    return true; // 안드로이드가 아니면 항상 true를 반환해요.
  }

  // 특정 시간에 알람을 예약하는 함수예요.
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    required bool canScheduleExact,
  }) async {
    // 예약 시간이 현재 시간보다 이전이면 알람을 보내지 않아요. (실험을 위해 주석 처리)
    // if (scheduledTime.isBefore(DateTime.now())) {
    //   return;
    // }

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

  // 화면에 계속 떠 있는 알람을 보여주는 함수예요.
  Future<void> showOngoingNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const NotificationDetails notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'ongoing_void_channel_id',
        'Ongoing Void Notifications',
        channelDescription: 'Persistent notification during Void of Course',
        importance: Importance.max,
        priority: Priority.high,
        ongoing: true,
        autoCancel: false,
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
  }) async {
    const NotificationDetails notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'void_channel_id', // Use the same channel as scheduled notifications
        'Void Notifications',
        channelDescription: 'Notifications for Void of Course periods',
        importance: Importance.max,
        priority: Priority.high,
        ongoing: false,
        autoCancel: true,
      ),
    );
    await _notificationsPlugin.show(id, title, body, notificationDetails);
  }
}