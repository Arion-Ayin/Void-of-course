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
// 포그라운드 서비스 알림 ID와 카운트다운 알림 ID를 동일하게 사용해야 빈 알림 문제가 해결됨
const int countdownNotificationId = 888;  // 카운트다운 알림 (pre-void, void active 모두 사용)
const int vocStartNotificationId = 777;   // Void 시작 알림 (10초 후 자동 삭제, 진동)
const int vocEndNotificationId = 999;     // Void 종료 알림 (삭제 가능, 진동)

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
      foregroundServiceNotificationId: countdownNotificationId,
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

  // stopService 이벤트 핸들러 등록
  // vocEndNotificationId는 취소하지 않음 (사용자가 직접 지울 때까지 유지)
  service.on("stopService").listen((event) async {
    await notificationsPlugin.cancel(countdownNotificationId);
    await notificationsPlugin.cancel(vocStartNotificationId);
    await service.stopSelf();
  });

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
  int tickCount = 0;

  // 캐시된 설정값 (매초 reload 대신 30초마다 갱신)
  String? cachedStartStr = prefs.getString('cached_voc_start');
  String? cachedEndStr = prefs.getString('cached_voc_end');
  int cachedPreHours = prefs.getInt('cached_pre_void_hours') ?? 6;
  bool cachedIsEnabled = prefs.getBool('voidAlarmEnabled') ?? false;
  String cachedLanguageCode = prefs.getString('cached_language_code') ?? 'en';

  // 서비스 시작 직후 즉시 알림 업데이트 (빈 알림 방지)
  // Timer.periodic 전에 먼저 실행하여 빈 포그라운드 알림을 덮어씀
  if (cachedIsEnabled && cachedStartStr != null && cachedEndStr != null) {
    // UTC 기준으로 비교 (기기 타임존과 무관하게 정확한 epoch 비교)
    final DateTime utcNow = DateTime.now().toUtc();

    final DateTime vocStart = DateTime.parse(cachedStartStr);
    final DateTime vocEnd = DateTime.parse(cachedEndStr);
    final DateTime preVoidStart = vocStart.subtract(Duration(hours: cachedPreHours));
    final bool isKorean = cachedLanguageCode.startsWith('ko');

    String? title;
    String? content;

    if (utcNow.isAfter(preVoidStart) && utcNow.isBefore(vocStart)) {
      // Pre-Void 상태
      final Duration timeLeft = vocStart.difference(utcNow);
      title = isKorean ? '⏰ 보이드 시작 알림' : '⏰ Void Starting Soon';
      content = isKorean ? '보이드 시작까지: ${_formatDuration(timeLeft)}' : 'Starts in: ${_formatDuration(timeLeft)}';
      previousState = statePreVoid;
    } else if (utcNow.isAfter(vocStart) && utcNow.isBefore(vocEnd)) {
      // Void Active 상태
      final Duration timeLeft = vocEnd.difference(utcNow);
      title = isKorean ? '🌑 지금은 보이드입니다!' : '🌑 Void of Course Active!';
      content = isKorean ? '보이드 종료까지: ${_formatDuration(timeLeft)}' : 'Ends in: ${_formatDuration(timeLeft)}';
      previousState = stateVocActive;
    }

    // 즉시 알림 표시 (빈 알림 덮어쓰기)
    if (title != null && content != null) {
      await notificationsPlugin.show(
        countdownNotificationId,
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
    }
  }

  Timer.periodic(const Duration(seconds: 1), (timer) async {
    if (isProcessing) return;
    isProcessing = true;

    try {
      if (service is AndroidServiceInstance) {
        // 30초마다 한 번씩만 SharedPreferences 갱신 (I/O 최소화)
        tickCount++;
        if (tickCount >= 30) {
          tickCount = 0;
          await prefs.reload();
          cachedStartStr = prefs.getString('cached_voc_start');
          cachedEndStr = prefs.getString('cached_voc_end');
          cachedPreHours = prefs.getInt('cached_pre_void_hours') ?? 6;
          cachedIsEnabled = prefs.getBool('voidAlarmEnabled') ?? false;
          cachedLanguageCode = prefs.getString('cached_language_code') ?? 'en';
        }

        // 캐시된 값 사용 (30초마다 갱신됨)
        final String? startStr = cachedStartStr;
        final String? endStr = cachedEndStr;
        final int preHours = cachedPreHours;
        final bool isEnabled = cachedIsEnabled;
        final bool isKorean = cachedLanguageCode.startsWith('ko');

        if (!isEnabled) {
          // 알림 비활성화 - 모든 알림 삭제 후 서비스 종료
          await notificationsPlugin.cancel(countdownNotificationId);
          await notificationsPlugin.cancel(vocStartNotificationId);
          await notificationsPlugin.cancel(vocEndNotificationId); // 사용자가 알람 끄면 종료 알림도 삭제
          previousState = stateNone;
          timer.cancel();
          service.stopSelf();
          return;
        }

        if (startStr != null && endStr != null) {
          // UTC 기준으로 비교 (기기 타임존과 무관하게 정확한 epoch 비교)
          final DateTime utcNow = DateTime.now().toUtc();

          final DateTime vocStart = DateTime.parse(startStr);
          final DateTime vocEnd = DateTime.parse(endStr);
          final DateTime preVoidStart = vocStart.subtract(Duration(hours: preHours));

          int currentState = stateNone;
          String title = '';
          String content = '';

          if (utcNow.isBefore(preVoidStart)) {
            // 대기 중 (pre-void 시작 전) - 서비스 필요 없음, 종료
            // vocEndNotificationId는 취소하지 않음 (이전 보이드 종료 알림 유지)
            await notificationsPlugin.cancel(countdownNotificationId);
            await notificationsPlugin.cancel(vocStartNotificationId);
            timer.cancel();
            service.stopSelf();
            return;
          } else if (utcNow.isBefore(vocStart)) {
            // Pre-Void
            currentState = statePreVoid;
            final Duration timeLeft = vocStart.difference(utcNow);
            final String timeLeftStr = _formatDuration(timeLeft);
            title = isKorean ? '⏰ 보이드 시작 알림' : '⏰ Void Starting Soon';
            content = isKorean ? '보이드 시작까지: $timeLeftStr' : 'Starts in: $timeLeftStr';
          } else if (utcNow.isBefore(vocEnd)) {
            // Void Active
            currentState = stateVocActive;
            final Duration timeLeft = vocEnd.difference(utcNow);
            final String timeLeftStr = _formatDuration(timeLeft);
            title = isKorean ? '🌑 지금은 보이드입니다!' : '🌑 Void of Course Active!';
            content = isKorean ? '보이드 종료까지: $timeLeftStr' : 'Ends in: $timeLeftStr';
          } else {
            // Void 종료
            currentState = stateVocEnded;
          }

          // 상태 전환 처리
          if (currentState != previousState) {
            if (currentState == statePreVoid) {
              // 1. Pre-Void 시작 - 이전 알림들 정리
              await notificationsPlugin.cancel(vocStartNotificationId);
              await notificationsPlugin.cancel(vocEndNotificationId);
            } else if (currentState == stateVocActive) {
              // 2. Void 시작 - Void 시작 알림 표시 (카운트다운 알림은 같은 ID로 덮어씀)
              await _showVocStartNotification(
                notificationsPlugin,
                isKorean ? '🌑 보이드가 시작되었습니다!' : '🌑 Void of Course Started!',
                isKorean ? '중요한 결정을 피하세요.' : 'Avoid important decisions.',
              );
            } else if (currentState == stateVocEnded) {
              // 4. Void 종료 - 카운트다운 알림 삭제, Void 종료 알림 표시
              await notificationsPlugin.cancel(countdownNotificationId);
              await notificationsPlugin.cancel(vocStartNotificationId);

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
                    autoCancel: false, // 탭해도 삭제 안 됨 - 사용자가 스와이프로 직접 삭제
                    icon: '@drawable/ic_notification',
                  ),
                ),
              );

              // 알림이 시스템에 완전히 등록될 때까지 대기 후 서비스 종료
              // (즉시 종료하면 삼성 등 일부 기기에서 프로세스와 함께 알림도 정리됨)
              previousState = currentState;
              timer.cancel();
              await Future.delayed(const Duration(seconds: 5));
              service.stopSelf();
              return;
            }

            previousState = currentState;
          }

          // 카운트다운 알림 업데이트 (소리/진동 없이, 삭제 불가)
          // pre-void와 void active 모두 같은 ID를 사용하여 포그라운드 서비스 알림을 덮어씀
          if (currentState == statePreVoid || currentState == stateVocActive) {
            await notificationsPlugin.show(
              countdownNotificationId,
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
          }
        } else {
          // 데이터 없음 - 카운트다운/시작 알림만 삭제 후 서비스 종료
          // vocEndNotificationId는 유지 (사용자가 직접 삭제)
          await notificationsPlugin.cancel(countdownNotificationId);
          await notificationsPlugin.cancel(vocStartNotificationId);
          timer.cancel();
          service.stopSelf();
          return;
        }
      }
    } finally {
      isProcessing = false;
    }
  });
}

// 2. Void 시작 알림 (10초 후 자동 삭제, 진동)
Future<void> _showVocStartNotification(
  FlutterLocalNotificationsPlugin plugin,
  String title,
  String body,
) async {
  await plugin.show(
    vocStartNotificationId,
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


