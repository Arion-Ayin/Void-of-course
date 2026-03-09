import 'dart:ui';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
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

/// 2) void 시작: 서비스 재시작 → void 카운트다운 시작
@pragma('vm:entry-point')
Future<void> _vocStartAlarmCallback() async {
  DartPluginRegistrant.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  await prefs.reload();

  final bool isEnabled = prefs.getBool('voidAlarmEnabled') ?? false;
  if (!isEnabled) return;

  // 서비스가 죽어있으면 재시작 → void 카운트다운 복구
  final service = FlutterBackgroundService();
  final isRunning = await service.isRunning();
  if (!isRunning) {
    await service.startService();
  } else {
    service.invoke("refreshData");
  }
}

/// 3) void 중간: 서비스가 죽어있으면 재시작 → 카운트다운 복구 + 다음 알람 예약
@pragma('vm:entry-point')
Future<void> _vocMidAlarmCallback() async {
  DartPluginRegistrant.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  await prefs.reload();

  final bool isEnabled = prefs.getBool('voidAlarmEnabled') ?? false;
  if (!isEnabled) return;

  // 1. 서비스 생존 확인 및 재시작
  final service = FlutterBackgroundService();
  final isRunning = await service.isRunning();
  if (!isRunning) {
    await service.startService();
  } else {
    service.invoke("refreshData");
  }

  // 2. 다음 중간 알람 예약 (체인 생성)
  final vocEndString = prefs.getString('cached_voc_end');
  if (vocEndString == null) return;

  final vocEnd = DateTime.parse(vocEndString);
  final now = DateTime.now().toUtc();
  const maxInterval = Duration(hours: 12);
  final nextMidVoc = now.add(maxInterval);

  if (nextMidVoc.isBefore(vocEnd)) {
    // 다음 중간 알람을 예약합니다.
    await AndroidAlarmManager.oneShotAt(
      nextMidVoc,
      vocMidAlarmId, // 동일한 ID를 사용하여 기존 알람을 덮어씁니다.
      _vocMidAlarmCallback,
      exact: true,
      wakeup: true,
      allowWhileIdle: true,
      rescheduleOnReboot: true,
    );
  }
}

/// 4) void 종료: 서비스 재시작 → 종료 알림 전송 및 서비스 종료
@pragma('vm:entry-point')
Future<void> _vocEndAlarmCallback() async {
  DartPluginRegistrant.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  await prefs.reload();

  final bool isEnabled = prefs.getBool('voidAlarmEnabled') ?? false;
  if (!isEnabled) return;

  // 서비스가 죽어있더라도 시작하여 종료 알림을 표시하고 스스로 멈추도록 함
  final service = FlutterBackgroundService();
  final isRunning = await service.isRunning();
  if (!isRunning) {
    await service.startService();
  } else {
    // 이미 실행중이면 refresh 이벤트를 보내 즉시 종료 로직을 타도록 함
    service.invoke("refreshData");
  }
}
