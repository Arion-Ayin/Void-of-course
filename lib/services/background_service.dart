import 'dart:async';
import 'dart:ui';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> initializeBackgroundService() async {
  final service = FlutterBackgroundService();

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'void_background_channel', // id
    'Void Monitor Service', // title
    description: 'Keeps the app running to monitor Void of Course',
    importance: Importance.low, // Silent
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(channel);

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

  // Bring to foreground
  Timer.periodic(const Duration(seconds: 1), (timer) async {
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
        service.stopSelf();
        return;
      }

      if (startStr != null && endStr != null) {
        final DateTime now = DateTime.now();
        final DateTime vocStart = DateTime.parse(startStr);
        final DateTime vocEnd = DateTime.parse(endStr);

        if (now.isAfter(vocEnd)) {
          service.stopSelf();
          return;
        }

        final DateTime preVoidStart = vocStart.subtract(
          Duration(hours: preHours),
        );

        // Check if we are in Critical Period (Pre-Void OR VOC)
        bool isCritical = false;
        String title = '';
        String content = '';

        if (now.isAfter(preVoidStart) && now.isBefore(vocStart)) {
          // Pre-Void
          isCritical = true;
          final Duration timeLeft = vocStart.difference(now);
          final String timeLeftStr =
              '${timeLeft.inHours}:${(timeLeft.inMinutes % 60).toString().padLeft(2, '0')}:${(timeLeft.inSeconds % 60).toString().padLeft(2, '0')}';

          title = isKorean ? '보이드 시작 알림' : 'Void of Course Upcoming';
          content = isKorean ? '시작까지: $timeLeftStr' : 'Starts in: $timeLeftStr';
        } else if (now.isAfter(vocStart) && now.isBefore(vocEnd)) {
          // VOC Active
          isCritical = true;
          final Duration timeLeft = vocEnd.difference(now);
          final String timeLeftStr =
              '${timeLeft.inHours}:${(timeLeft.inMinutes % 60).toString().padLeft(2, '0')}:${(timeLeft.inSeconds % 60).toString().padLeft(2, '0')}';

          title = isKorean ? '보이드 시작' : 'Void of Course Active';
          content = isKorean ? '종료까지: $timeLeftStr' : 'Ends in: $timeLeftStr';
        }

        if (isCritical) {
          // Ensure we are in Foreground (Undeletable)
          if (!await service.isForegroundService()) {
            service.setAsForegroundService();
          }
          service.setForegroundNotificationInfo(title: title, content: content);
        } else {
          // Idle (Deletable / Hidden)
          // Move to background to remove the persistent notification
          if (await service.isForegroundService()) {
            service.setAsBackgroundService();
          }
        }
      } else {
        // No data, go to background
        if (await service.isForegroundService()) {
          service.setAsBackgroundService();
        }
      }
    }
  });
}
