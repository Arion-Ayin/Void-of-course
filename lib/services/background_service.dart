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

// 알림 ID 상수
const int foregroundNotificationId = 888; // 포그라운드 서비스 알림 (카운트다운, 삭제 불가)
const int alertNotificationId = 777;      // 상태 변경 알림 (소리/진동 1회)
const int vocEndNotificationId = 999;     // 종료 알림 (삭제 가능)

Future<void> initializeBackgroundService() async {
  final service = FlutterBackgroundService();

  // 포그라운드 서비스 채널 - 카운트다운용 (소리/진동 없음)
  const AndroidNotificationChannel serviceChannel = AndroidNotificationChannel(
    'void_service_channel',
    'Void Countdown',
    description: 'Shows countdown timer for Void of Course',
    importance: Importance.low, // 소리/진동 없음
    playSound: false,
    enableVibration: false,
    showBadge: false,
  );

  // 상태 변경 알림 채널 (소리/진동 1회용)
  const AndroidNotificationChannel alertChannel = AndroidNotificationChannel(
    'void_alert_channel',
    'Void Alerts',
    description: 'Alert when Void of Course starts',
    importance: Importance.high,
    playSound: true,
    enableVibration: true,
  );

  // 종료 알림 채널
  const AndroidNotificationChannel endChannel = AndroidNotificationChannel(
    'void_end_channel',
    'Void End Notifications',
    description: 'Notification when Void of Course ends',
    importance: Importance.high,
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(serviceChannel);

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(alertChannel);

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(endChannel);

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: false,
      isForegroundMode: true,
      notificationChannelId: 'void_service_channel',
      initialNotificationTitle: '',
      initialNotificationContent: '',
      foregroundServiceNotificationId: foregroundNotificationId,
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
  DartPluginRegistrant.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();

  final FlutterLocalNotificationsPlugin notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@drawable/ic_notification');
  const InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);
  await notificationsPlugin.initialize(initializationSettings);

  // 알림 채널 생성 (서비스 재시작 시)
  const AndroidNotificationChannel serviceChannel = AndroidNotificationChannel(
    'void_service_channel',
    'Void Countdown',
    description: 'Shows countdown timer for Void of Course',
    importance: Importance.low,
    playSound: false,
    enableVibration: false,
    showBadge: false,
  );

  const AndroidNotificationChannel alertChannel = AndroidNotificationChannel(
    'void_alert_channel',
    'Void Alerts',
    description: 'Alert when Void of Course starts',
    importance: Importance.high,
    playSound: true,
    enableVibration: true,
  );

  const AndroidNotificationChannel endChannel = AndroidNotificationChannel(
    'void_end_channel',
    'Void End Notifications',
    description: 'Notification when Void of Course ends',
    importance: Importance.high,
  );

  await notificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(serviceChannel);

  await notificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(alertChannel);

  await notificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(endChannel);

  int previousState = stateNone;
  bool isProcessing = false;

  Timer.periodic(const Duration(seconds: 1), (timer) async {
    if (isProcessing) return;
    isProcessing = true;

    try {
      if (service is AndroidServiceInstance) {
        await prefs.reload();

        final String? startStr = prefs.getString('cached_voc_start');
        final String? endStr = prefs.getString('cached_voc_end');
        final int preHours = prefs.getInt('cached_pre_void_hours') ?? 6;
        final bool isEnabled = prefs.getBool('voidAlarmEnabled') ?? false;
        final String languageCode = prefs.getString('cached_language_code') ?? 'en';
        final bool isKorean = languageCode.startsWith('ko');

        if (!isEnabled) {
          await notificationsPlugin.cancel(alertNotificationId);
          await notificationsPlugin.cancel(vocEndNotificationId);
          previousState = stateNone;
          timer.cancel();
          service.stopSelf();
          return;
        }

        if (startStr != null && endStr != null) {
          final DateTime now = DateTime.now();
          final DateTime vocStart = DateTime.parse(startStr);
          final DateTime vocEnd = DateTime.parse(endStr);
          final DateTime preVoidStart = vocStart.subtract(Duration(hours: preHours));

          int currentState = stateNone;
          String title = '';
          String content = '';

          if (now.isBefore(preVoidStart)) {
            // 대기 중 - 알림 표시 안함
            currentState = stateNone;
          } else if (now.isBefore(vocStart)) {
            // Pre-Void
            currentState = statePreVoid;
            final Duration timeLeft = vocStart.difference(now);
            final String timeLeftStr = _formatDuration(timeLeft);
            title = isKorean ? '⏰ 보이드 시작 알림' : '⏰ Void Starting Soon';
            content = isKorean ? '보이드 시작까지: $timeLeftStr' : 'Starts in: $timeLeftStr';
          } else if (now.isBefore(vocEnd)) {
            // Void Active
            currentState = stateVocActive;
            final Duration timeLeft = vocEnd.difference(now);
            final String timeLeftStr = _formatDuration(timeLeft);
            title = isKorean ? '🌑 지금은 보이드입니다!' : '🌑 Void of Course Active!';
            content = isKorean ? '보이드 종료까지: $timeLeftStr' : 'Ends in: $timeLeftStr';
          } else {
            // Void 종료
            currentState = stateVocEnded;
          }

          // 상태 전환 처리
          if (currentState != previousState) {
            // 이전 alert 알림 제거
            await notificationsPlugin.cancel(alertNotificationId);

            if (currentState == statePreVoid) {
              // Pre-Void 시작 - 알림음 1회
              await notificationsPlugin.cancel(vocEndNotificationId);
              await _showAlertNotification(
                notificationsPlugin,
                isKorean ? '⏰ 보이드가 곧 시작됩니다' : '⏰ Void of Course Starting',
                isKorean ? '보이드 시간이 다가오고 있습니다.' : 'Void period is approaching.',
              );
            } else if (currentState == stateVocActive) {
              // Void Active 시작 - 알림음 1회
              await _showAlertNotification(
                notificationsPlugin,
                isKorean ? '🌑 보이드가 시작되었습니다!' : '🌑 Void of Course Started!',
                isKorean ? '중요한 결정을 피하세요.' : 'Avoid important decisions.',
              );
            } else if (currentState == stateVocEnded) {
              // Void 종료 - 종료 알림 표시 후 서비스 종료
              await notificationsPlugin.show(
                vocEndNotificationId,
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
                    autoCancel: true,
                    icon: '@drawable/ic_notification',
                  ),
                ),
              );

              previousState = currentState;
              timer.cancel();
              service.stopSelf();
              return;
            }

            previousState = currentState;
          }

          // 카운트다운 알림 업데이트 (소리/진동 없이, 삭제 불가)
          if (currentState == statePreVoid || currentState == stateVocActive) {
            await notificationsPlugin.show(
              foregroundNotificationId,
              title,
              content,
              const NotificationDetails(
                android: AndroidNotificationDetails(
                  'void_service_channel',
                  'Void Countdown',
                  channelDescription: 'Shows countdown timer for Void of Course',
                  importance: Importance.low,
                  priority: Priority.low,
                  ongoing: true,
                  autoCancel: false,
                  playSound: false,
                  enableVibration: false,
                  onlyAlertOnce: true,
                  icon: '@drawable/ic_notification',
                ),
              ),
            );
          } else {
            // 대기 중 - 알림 내용 최소화 (빈 내용)
            await notificationsPlugin.show(
              foregroundNotificationId,
              '',
              '',
              const NotificationDetails(
                android: AndroidNotificationDetails(
                  'void_service_channel',
                  'Void Countdown',
                  channelDescription: 'Shows countdown timer for Void of Course',
                  importance: Importance.low,
                  priority: Priority.low,
                  ongoing: true,
                  autoCancel: false,
                  playSound: false,
                  enableVibration: false,
                  onlyAlertOnce: true,
                  icon: '@drawable/ic_notification',
                ),
              ),
            );
          }
        } else {
          // 데이터 없음 - 알림 숨김
          await notificationsPlugin.show(
            foregroundNotificationId,
            '',
            '',
            const NotificationDetails(
              android: AndroidNotificationDetails(
                'void_service_channel',
                'Void Countdown',
                channelDescription: 'Shows countdown timer for Void of Course',
                importance: Importance.low,
                priority: Priority.low,
                ongoing: true,
                autoCancel: false,
                playSound: false,
                enableVibration: false,
                onlyAlertOnce: true,
                icon: '@drawable/ic_notification',
              ),
            ),
          );
        }
      }
    } finally {
      isProcessing = false;
    }
  });
}

// 상태 변경 시 알림음 1회 (자동 삭제)
Future<void> _showAlertNotification(
  FlutterLocalNotificationsPlugin plugin,
  String title,
  String body,
) async {
  await plugin.show(
    alertNotificationId,
    title,
    body,
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
}

String _formatDuration(Duration duration) {
  final hours = duration.inHours;
  final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
  final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
  return '$hours:$minutes:$seconds';
}
