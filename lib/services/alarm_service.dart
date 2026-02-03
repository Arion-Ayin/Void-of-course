import 'dart:ui';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

const int preVoidAlarmId = 100;

class AlarmService {
  static final AlarmService _instance = AlarmService._internal();
  factory AlarmService() => _instance;
  AlarmService._internal();

  Future<void> init() async {
    await AndroidAlarmManager.initialize();
  }

  /// pre-void 시작 시점에 백그라운드 서비스를 시작하는 알람 예약
  Future<void> schedulePreVoidAlarm(DateTime preVoidStart) async {
    final now = DateTime.now();

    // 이미 지난 시간이면 무시
    if (preVoidStart.isBefore(now)) {
      return;
    }

    // 기존 알람 취소
    await AndroidAlarmManager.cancel(preVoidAlarmId);

    // 새 알람 예약
    await AndroidAlarmManager.oneShotAt(
      preVoidStart,
      preVoidAlarmId,
      _alarmCallback,
      exact: true,
      wakeup: true,
      allowWhileIdle: true,
      rescheduleOnReboot: true,
    );
  }

  /// 알람 취소
  Future<void> cancelAlarm() async {
    await AndroidAlarmManager.cancel(preVoidAlarmId);
  }
}

/// 알람이 트리거될 때 실행되는 콜백 (top-level 함수여야 함)
@pragma('vm:entry-point')
Future<void> _alarmCallback() async {
  DartPluginRegistrant.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  await prefs.reload();

  final bool isEnabled = prefs.getBool('voidAlarmEnabled') ?? false;

  if (isEnabled) {
    final service = FlutterBackgroundService();
    final isRunning = await service.isRunning();

    if (!isRunning) {
      await service.startService();
    }
  }
}
