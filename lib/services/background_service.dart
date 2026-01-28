import 'dart:async';
import 'dart:ui';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 알림 상태 상수
const int stateNone = 0;
const int statePreVoid = 1;
const int stateVocActive = 2;
const int stateVocEnded = 3;

//백그라운드 서비스 세팅 대기함수
Future<void> initializeBackgroundService() async {
  final service = FlutterBackgroundService();

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'void_background_channel', // id
    'Void Monitor Service', // title
    description: 'Keeps the app running to monitor Void of Course',
    importance: Importance.low, // Silent
  );

  // 종료 알림용 채널 (소리 있음, 삭제 가능)
  const AndroidNotificationChannel endChannel = AndroidNotificationChannel(
    'void_end_channel',
    'Void End Notifications',
    description: 'Notification when Void of Course ends',
    importance: Importance.high,
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(channel);

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(endChannel);

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      // This will be executed when app is in foreground or background in separated isolate
      onStart: onStart,

      // auto start service
      autoStart: false,
      isForegroundMode: true,

      notificationChannelId: 'void_background_channel',
      initialNotificationTitle: 'Void Monitor',
      initialNotificationContent: 'Initializing...',
      foregroundServiceNotificationId: 888, // Same ID as we used before
    ),
    iosConfiguration: IosConfiguration(
      autoStart: false,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  return true;
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  // Only available for flutter 3.0.0 and later
  DartPluginRegistrant.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();

  // 알림 플러그인 초기화
  final FlutterLocalNotificationsPlugin notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);
  await notificationsPlugin.initialize(initializationSettings);

  // 이전 상태 추적 변수
  int previousState = stateNone;
  bool isProcessing = false; // 재진입 방지 플래그

  // 알림 ID 상수
  const int foregroundNotificationId = 888;
  const int vocEndNotificationId = 999;

  // Bring to foreground
  Timer.periodic(const Duration(seconds: 1), (timer) async {
    // 이전 콜백이 아직 실행 중이면 스킵 (async 재진입 방지)
    if (isProcessing) return;
    isProcessing = true;

    try {
    if (service is AndroidServiceInstance) {
      // Read cached VOC times
      // We need to reload prefs to get latest updates from main app
      await prefs.reload();

      final String? startStr = prefs.getString('cached_voc_start');
      final String? endStr = prefs.getString('cached_voc_end');
      final int preHours = prefs.getInt('cached_pre_void_hours') ?? 6;
      final bool isEnabled = prefs.getBool('voidAlarmEnabled') ?? false;
      final String languageCode =
          prefs.getString('cached_language_code') ?? 'en';
      final bool isKorean = languageCode.startsWith('ko');

      if (!isEnabled) {
        // 서비스 종료 전 알림 정리
        await notificationsPlugin.cancel(vocEndNotificationId);
        await notificationsPlugin.cancel(foregroundNotificationId);
        previousState = stateNone;
        timer.cancel();
        service.stopSelf();
        return;
      }

      if (startStr != null && endStr != null) {
        final DateTime now = DateTime.now();
        final DateTime vocStart = DateTime.parse(startStr);
        final DateTime vocEnd = DateTime.parse(endStr);

        final DateTime preVoidStart = vocStart.subtract(
          Duration(hours: preHours),
        );

        // 현재 상태 결정
        int currentState = stateNone;
        String title = '';
        String content = '';

        if (now.isBefore(preVoidStart)) {
          // 아직 Pre-Void 시간 전
          currentState = stateNone;
        } else if (!now.isBefore(preVoidStart) && now.isBefore(vocStart)) {
          // 1번: Pre-Void (6시간 전 ~ 보이드 시작) - preVoidStart 포함
          currentState = statePreVoid;
          final Duration timeLeft = vocStart.difference(now);
          final String timeLeftStr =
              '${timeLeft.inHours}:${(timeLeft.inMinutes % 60).toString().padLeft(2, '0')}:${(timeLeft.inSeconds % 60).toString().padLeft(2, '0')}';

          title = isKorean ? '보이드 시작 알림' : 'Void of Course Upcoming';
          content = isKorean ? '시작까지: $timeLeftStr' : 'Starts in: $timeLeftStr';
        } else if (!now.isBefore(vocStart) && now.isBefore(vocEnd)) {
          // 2번: VOC Active (보이드 중) - vocStart 포함
          currentState = stateVocActive;
          final Duration timeLeft = vocEnd.difference(now);
          final String timeLeftStr =
              '${timeLeft.inHours}:${(timeLeft.inMinutes % 60).toString().padLeft(2, '0')}:${(timeLeft.inSeconds % 60).toString().padLeft(2, '0')}';

          title = isKorean ? '지금은 보이드입니다' : 'Void of Course Active';
          content = isKorean ? '종료까지: $timeLeftStr' : 'Ends in: $timeLeftStr';
        } else if (!now.isBefore(vocEnd)) {
          // 3번: VOC 종료됨 - vocEnd 포함
          currentState = stateVocEnded;
        }

        // 상태 전환 감지 및 처리
        if (currentState != previousState) {
          // 상태가 변경됨 - 이전 알림 처리

          if (currentState == statePreVoid) {
            // None -> PreVoid: 이전 종료 알림 제거 후 포그라운드 서비스 시작
            await notificationsPlugin.cancel(vocEndNotificationId);
            if (!await service.isForegroundService()) {
              service.setAsForegroundService();
            }
          } else if (currentState == stateVocActive) {
            // PreVoid -> VocActive: 포그라운드 알림만 업데이트 (동일 ID 888이므로 자동 교체)
            if (!await service.isForegroundService()) {
              service.setAsForegroundService();
            }
          } else if (currentState == stateVocEnded) {
            // VocActive -> VocEnded: 포그라운드 알림 제거하고 종료 알림 표시
            previousState = currentState;

            // 타이머 먼저 취소 (추가 틱이 간섭하지 못하도록)
            timer.cancel();

            // 종료 알림 표시 (삭제 가능) - 서비스 종료 전에 먼저 표시
            await notificationsPlugin.show(
              vocEndNotificationId,
              isKorean ? '보이드 종료' : 'Void of Course Ended',
              isKorean ? '보이드가 종료되었습니다.' : 'The Void of Course period has ended.',
              const NotificationDetails(
                android: AndroidNotificationDetails(
                  'void_end_channel',
                  'Void End Notifications',
                  channelDescription: 'Notification when Void of Course ends',
                  importance: Importance.high,
                  priority: Priority.high,
                  ongoing: false, // 삭제 가능
                  autoCancel: true,
                ),
              ),
            );

            // 포그라운드 알림 명시적 제거 (잔류 방지)
            await notificationsPlugin.cancel(foregroundNotificationId);

            // 서비스 종료 (포그라운드 알림도 자동 제거됨)
            service.stopSelf();
            return;
          } else if (currentState == stateNone) {
            // 아직 알림 시간이 아님 - 이전 알림 정리 후 백그라운드로
            await notificationsPlugin.cancel(vocEndNotificationId);
            if (await service.isForegroundService()) {
              service.setAsBackgroundService();
            }
          }

          previousState = currentState;
        }

        // 현재 상태에 따른 알림 업데이트
        if (currentState == statePreVoid || currentState == stateVocActive) {
          // 포그라운드 알림 업데이트 (ongoing, 삭제 불가)
          if (!await service.isForegroundService()) {
            service.setAsForegroundService();
          }
          service.setForegroundNotificationInfo(title: title, content: content);
        }
      } else {
        // No data, go to background
        if (await service.isForegroundService()) {
          service.setAsBackgroundService();
        }
        previousState = stateNone;
      }
    }
    } finally {
      isProcessing = false;
    }
  });
}
