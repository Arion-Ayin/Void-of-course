import 'dart:ui';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

const int preVoidAlarmId = 100; // pre-void 시작 → 서비스 시작
const int vocStartAlarmId = 101; // void 시작 → "시작합니다!" 직접 전송 + 서비스 재시작
const int vocMidAlarmId = 102;   // void 중간 → 서비스 재시작 (죽었을 경우 복구)
const int vocEndAlarmId = 103;   // void 종료 → "종료됩니다." 직접 전송

class AlarmService {
  static final AlarmService _instance = AlarmService._internal();
  factory AlarmService() => _instance;
  AlarmService._internal();

  Future<void> init() async {
    await AndroidAlarmManager.initialize();
  }

  /// 1) pre-void 시작 시점에 백그라운드 서비스를 시작하는 알람 예약
  Future<void> schedulePreVoidAlarm(DateTime preVoidStart) async {
    final now = DateTime.now();
    if (preVoidStart.isBefore(now)) return;

    await AndroidAlarmManager.cancel(preVoidAlarmId);
    await AndroidAlarmManager.oneShotAt(
      preVoidStart,
      preVoidAlarmId,
      _preVoidAlarmCallback,
      exact: true,
      wakeup: true,
      allowWhileIdle: true,
      rescheduleOnReboot: true,
    );
  }

  /// 2) void 시작 시점: "시작합니다!" 직접 전송 + 서비스 재시작
  Future<void> scheduleVocStartAlarm(DateTime vocStart) async {
    final now = DateTime.now();
    if (vocStart.isBefore(now)) return;

    await AndroidAlarmManager.cancel(vocStartAlarmId);
    await AndroidAlarmManager.oneShotAt(
      vocStart,
      vocStartAlarmId,
      _vocStartAlarmCallback,
      exact: true,
      wakeup: true,
      allowWhileIdle: true,
      rescheduleOnReboot: true,
    );
  }

  /// 3) void 중간 시점: 서비스가 죽어있으면 재시작 (카운트다운 복구)
  Future<void> scheduleVocMidAlarm(DateTime vocMid) async {
    final now = DateTime.now();
    if (vocMid.isBefore(now)) return;

    await AndroidAlarmManager.cancel(vocMidAlarmId);
    await AndroidAlarmManager.oneShotAt(
      vocMid,
      vocMidAlarmId,
      _vocMidAlarmCallback,
      exact: true,
      wakeup: true,
      allowWhileIdle: true,
      rescheduleOnReboot: true,
    );
  }

  /// 4) void 종료 시점: 직접 종료 알림 전송 (서비스 없이도 보장)
  Future<void> scheduleVocEndAlarm(DateTime vocEnd) async {
    final now = DateTime.now();
    if (vocEnd.isBefore(now)) return;

    await AndroidAlarmManager.cancel(vocEndAlarmId);
    await AndroidAlarmManager.oneShotAt(
      vocEnd,
      vocEndAlarmId,
      _vocEndAlarmCallback,
      exact: true,
      wakeup: true,
      allowWhileIdle: true,
      rescheduleOnReboot: true,
    );
  }

  /// 모든 알람 취소
  Future<void> cancelAlarm() async {
    await Future.wait([
      AndroidAlarmManager.cancel(preVoidAlarmId),
      AndroidAlarmManager.cancel(vocStartAlarmId),
      AndroidAlarmManager.cancel(vocMidAlarmId),
      AndroidAlarmManager.cancel(vocEndAlarmId),
    ]);
  }
}

// ─────────────────────────────────────────────
// AlarmManager 콜백 (top-level 함수여야 함)
// ─────────────────────────────────────────────

/// 1) pre-void 시작: 서비스 시작 → pre-void 카운트다운 시작
@pragma('vm:entry-point')
Future<void> _preVoidAlarmCallback() async {
  DartPluginRegistrant.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  await prefs.reload();

  final bool isEnabled = prefs.getBool('voidAlarmEnabled') ?? false;
  if (!isEnabled) return;

  final service = FlutterBackgroundService();
  final isRunning = await service.isRunning();
  if (!isRunning) {
    await service.startService();
  }
}

/// 2) void 시작: "시작합니다!" 직접 전송 + 서비스 재시작 → void 카운트다운 시작
@pragma('vm:entry-point')
Future<void> _vocStartAlarmCallback() async {
  DartPluginRegistrant.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  await prefs.reload();

  final bool isEnabled = prefs.getBool('voidAlarmEnabled') ?? false;
  if (!isEnabled) return;

  final String languageCode = prefs.getString('cached_language_code') ?? 'en';
  final bool isKorean = languageCode.startsWith('ko');

  // "시작합니다!" 알림 직접 전송 (서비스 생사와 무관하게 보장)
  final FlutterLocalNotificationsPlugin notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  const AndroidInitializationSettings initSettings =
      AndroidInitializationSettings('@drawable/ic_notification');
  await notificationsPlugin.initialize(
    const InitializationSettings(android: initSettings),
  );

  await notificationsPlugin.show(
    777, // vocStartNotificationId
    isKorean ? '보이드가 시작되었습니다!' : 'Void of Course Started!',
    isKorean ? '중요한 결정을 피하세요.' : 'Avoid important decisions.',
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'void_alert_channel',
        'Void Alerts',
        channelDescription: 'Alert when Void of Course starts',
        importance: Importance.high,
        priority: Priority.high,
        ongoing: false,
        autoCancel: true,
        timeoutAfter: 10000, // 10초 후 자동 삭제
        icon: '@drawable/ic_notification',
      ),
    ),
  );

  // 서비스가 죽어있으면 재시작 → void 카운트다운 복구
  final service = FlutterBackgroundService();
  final isRunning = await service.isRunning();
  if (!isRunning) {
    await service.startService();
  } else {
    service.invoke("refreshData");
  }
}

/// 3) void 중간: 서비스가 죽어있으면 재시작 → 카운트다운 복구
@pragma('vm:entry-point')
Future<void> _vocMidAlarmCallback() async {
  DartPluginRegistrant.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  await prefs.reload();

  final bool isEnabled = prefs.getBool('voidAlarmEnabled') ?? false;
  if (!isEnabled) return;

  final service = FlutterBackgroundService();
  final isRunning = await service.isRunning();
  if (!isRunning) {
    await service.startService();
  } else {
    service.invoke("refreshData");
  }
}

/// 4) void 종료: "종료됩니다." 직접 전송 (서비스 없이도 보장)
@pragma('vm:entry-point')
Future<void> _vocEndAlarmCallback() async {
  DartPluginRegistrant.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  await prefs.reload();

  final bool isEnabled = prefs.getBool('voidAlarmEnabled') ?? false;
  if (!isEnabled) return;

  final String languageCode = prefs.getString('cached_language_code') ?? 'en';
  final bool isKorean = languageCode.startsWith('ko');

  final FlutterLocalNotificationsPlugin notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  const AndroidInitializationSettings initSettings =
      AndroidInitializationSettings('@drawable/ic_notification');
  await notificationsPlugin.initialize(
    const InitializationSettings(android: initSettings),
  );

  await notificationsPlugin.show(
    999, // vocEndNotificationId
    isKorean ? '✅ 보이드 종료!' : '✅ Void of Course Ended!',
    isKorean ? '보이드가 종료되었습니다.' : 'The Void period has ended.',
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'void_end_channel',
        'Void End Notifications',
        channelDescription: 'Notification when Void of Course ends',
        importance: Importance.high,
        priority: Priority.high,
        ongoing: false,
        autoCancel: false, // 유저가 직접 지우기 전까지 유지
        icon: '@drawable/ic_notification',
      ),
    ),
  );

  // 혹시 살아있는 서비스가 있으면 정상 종료
  final service = FlutterBackgroundService();
  final isRunning = await service.isRunning();
  if (isRunning) {
    service.invoke("stopService");
  }
}
