import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'astro_calculator.dart';
import 'notification_service.dart';
import 'package:sweph/sweph.dart';

final AstroCalculator _calculator = AstroCalculator();

// 알람 권한의 상태를 나타내는 열거형이에요.
enum AlarmPermissionStatus {
  granted, // 모든 권한이 허용됨
  notificationDenied, // 기본 알림 권한이 거부됨
  exactAlarmDenied, // 기본 알림은 허용됐지만, 정확한 알람 권한이 거부됨
}

class AstroState with ChangeNotifier {
  Timer? _timer;
  final NotificationService _notificationService = NotificationService();
  bool _voidAlarmEnabled = false;
  int _preVoidAlarmHours = 5; // Default to 5 hours
  bool _isOngoingNotificationVisible = false;
  DateTime _selectedDate = DateTime.now();
  String _moonPhase = '';
  String _moonZodiac = '';
  String _moonInSign = '';
  DateTime? _vocStart;
  DateTime? _vocEnd;
  DateTime? _nextSignTime;
  String? _lastError;
  bool _isInitialized = false;
  bool _isLoading = false;
  bool _isDarkMode = false;
  String _nextMoonPhaseName = 'Calculating...';
  DateTime? _nextMoonPhaseTime;
  final Map<String, Map<String, dynamic>> _cache = {};

  DateTime get selectedDate => _selectedDate;
  String get moonPhase => _moonPhase;
  String get moonZodiac => _moonZodiac;
  String get moonInSign => _moonInSign;
  DateTime? get vocStart => _vocStart;
  DateTime? get vocEnd => _vocEnd;
  DateTime? get nextSignTime => _nextSignTime;
  String? get lastError => _lastError;
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  bool get isDarkMode => _isDarkMode;
  bool get voidAlarmEnabled => _voidAlarmEnabled;
  int get preVoidAlarmHours => _preVoidAlarmHours; // Getter for the new setting
  String get nextMoonPhaseName => _nextMoonPhaseName;
  DateTime? get nextMoonPhaseTime => _nextMoonPhaseTime;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  void setTheme(bool isDark) {
    _isDarkMode = isDark;
    notifyListeners();
  }

  Future<void> initialize() async {
    if (_isInitialized) return;
    _isLoading = true;
    notifyListeners();

    try {
      await Sweph.init();
      await _notificationService.init();
      final prefs = await SharedPreferences.getInstance();
      _voidAlarmEnabled = prefs.getBool('voidAlarmEnabled') ?? false;
      _preVoidAlarmHours = prefs.getInt('preVoidAlarmHours') ?? 5; // Load setting

      await _updateData();
      _isInitialized = true;
      _startTimer();
      _lastError = null;
    } catch (e, stack) {
      print('Initialization error: $e\n$stack');
      _lastError = '초기화 오류: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<AlarmPermissionStatus> toggleVoidAlarm(bool enable) async {
    final prefs = await SharedPreferences.getInstance();
    if (enable) {
      final bool hasNotificationPermission = await _notificationService.requestPermissions();
      if (!hasNotificationPermission) {
        _voidAlarmEnabled = false;
        await prefs.setBool('voidAlarmEnabled', _voidAlarmEnabled);
        notifyListeners();
        return AlarmPermissionStatus.notificationDenied;
      }

      final bool hasExactAlarmPermission = await _notificationService.checkExactAlarmPermission();
      
      _voidAlarmEnabled = true;
      await _schedulePreVoidAlarm();
      await prefs.setBool('voidAlarmEnabled', _voidAlarmEnabled);
      notifyListeners();

      if (!hasExactAlarmPermission) {
        return AlarmPermissionStatus.exactAlarmDenied;
      }

      return AlarmPermissionStatus.granted;

    } else {
      _voidAlarmEnabled = false;
      await _notificationService.cancelAllNotifications();
      await prefs.setBool('voidAlarmEnabled', _voidAlarmEnabled);
      notifyListeners();
      return AlarmPermissionStatus.granted; // Or a more specific status if needed
    }
  }

  // Method to update the pre-alarm hours setting
  Future<void> setPreVoidAlarmHours(int hours) async {
    _preVoidAlarmHours = hours;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('preVoidAlarmHours', hours);
    // Reschedule notifications with the new setting
    await _schedulePreVoidAlarm();
    notifyListeners();
  }

  Future<void> _schedulePreVoidAlarm() async {
    // Cancel only the notifications that this scheduling logic manages.
    await _notificationService.cancelNotification(0); // Pre-VOC notification
    await _notificationService.cancelNotification(1); // Ongoing VOC notification

    if (!_voidAlarmEnabled) {
      if (kDebugMode) print('[VOC ALARM] Alarm is disabled. Cancelling notifications.');
      return;
    }
    if (_vocStart == null || _vocStart!.isBefore(DateTime.now())) {
      if (kDebugMode) print('[VOC ALARM] No upcoming VOC found. No alarm scheduled.');
      _lastError = '선택된 날짜에 예정된 보이드 기간이 없거나 이미 지났습니다. 알람이 예약되지 않았습니다.';
      notifyListeners();
      return;
    }

    // 이전 오류 메시지 제거
    _lastError = null;

    // Check for exact alarm permission before scheduling
    final bool canScheduleExact = await _notificationService.checkExactAlarmPermission();

    final now = DateTime.now();
    final timeUntilVocStart = _vocStart!.difference(now);
    final scheduledNotificationTime = _vocStart!.subtract(Duration(hours: _preVoidAlarmHours));

    if (kDebugMode) {
      print('[VOC ALARM] Scheduling check initiated at $now');
      print('[VOC ALARM] Upcoming VOC starts at: $_vocStart');
      print('[VOC ALARM] Pre-alarm setting: $_preVoidAlarmHours hours before');
      print('[VOC ALARM] Calculated notification time: $scheduledNotificationTime');
      print('[VOC ALARM] Can schedule exact alarm: $canScheduleExact');
    }

    String notificationBody;

    // Scenario 1: The scheduled notification time is in the future.
    if (scheduledNotificationTime.isAfter(now)) {
      notificationBody = '$_preVoidAlarmHours시간 후에 보이드가 시작됩니다.';
      
      try {
        await _notificationService.scheduleNotification(
          id: 0,
          title: 'Void of Course 알림',
          body: notificationBody,
          scheduledTime: scheduledNotificationTime,
          canScheduleExact: canScheduleExact,
        );
      } catch (e, stack) {
        print('[VOC ALARM] ERROR scheduling notification: $e\n$stack');
        _lastError = '알람 예약 중 오류 발생: $e';
      }

      if (kDebugMode) {
        print('[VOC ALARM] SCENARIO 1: Scheduled for the future.');
        print('[VOC ALARM] Notification will be sent at: $scheduledNotificationTime');
        print('[VOC ALARM] Notification body: "$notificationBody"');
      }
    }
    // Scenario 2: The pre-alarm time has already passed, but the VOC hasn't started yet.
    else {
      final hoursRemaining = timeUntilVocStart.inHours;
      final minutesRemaining = timeUntilVocStart.inMinutes % 60;

      if (hoursRemaining > 0) {
        notificationBody = '$hoursRemaining시간 $minutesRemaining분 후에 보이드가 시작됩니다.';
      } else if (minutesRemaining > 0) {
        notificationBody = '$minutesRemaining분 후에 보이드가 시작됩니다.';
      } else {
        notificationBody = '보이드가 곧 시작됩니다.';
      }
      
      // Send notification immediately
      try {
        // --- DEBUGGING START ---
        // Let's try to show a notification directly to test if notifications can be shown at all.
        print('[VOC ALARM] DEBUG: Attempting to show a direct ongoing notification with ID 99.');
        await _notificationService.showOngoingNotification(
            id: 99,
            title: '보이드 알림',
            body: notificationBody,
        );
        // --- DEBUGGING END ---

        /* Original code commented out for debugging
        await _notificationService.scheduleNotification(
        id: 0,
        title: 'Void of Course 알림',
        body: notificationBody,
        scheduledTime: now.add(const Duration(seconds: 2)), // Schedule for 2 seconds from now
        canScheduleExact: canScheduleExact,
        );
        */
      } catch (e, stack) {
        print('[VOC ALARM] ERROR scheduling notification: $e\n$stack');
        _lastError = '알람 예약 중 오류 발생: $e';
      }

      if (kDebugMode) {
        print('[VOC ALARM] SCENARIO 2: VOC is starting soon (within $_preVoidAlarmHours hours).');
        print('[VOC ALARM] Sending immediate notification.');
        print('[VOC ALARM] Notification body: "$notificationBody"');
      }
    }
    notifyListeners();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _checkTime();
    });
  }

  void _checkTime() {
    final now = DateTime.now();

    // 1. 보이드 알람 및 상태 변경 처리
    if (_voidAlarmEnabled) {
      final start = _vocStart;
      final end = _vocEnd;
      if (start != null && end != null) {
        final isCurrentlyInVoc = now.isAfter(start) && now.isBefore(end);

        // Case 1: VOC is active and ongoing notification is not visible
        if (isCurrentlyInVoc && !_isOngoingNotificationVisible) {
          // 보이드 기간 시작 -> 지속적인 알림 표시
          _notificationService.showOngoingNotification(
            id: 1,
            title: '보이드 중',
            body: '지금은 보이드 시간입니다.',
          );
          _isOngoingNotificationVisible = true;
          if (kDebugMode) print("Showing ongoing VOC notification.");

        // Case 2: VOC has ended and ongoing notification was visible
        } else if (!isCurrentlyInVoc && now.isAfter(end) && _isOngoingNotificationVisible) {
          // 보이드 기간 종료 -> 지속적인 알림 취소 및 종료 알림 표시
          _notificationService.cancelNotification(1); // 지속적인 알림 취소
          _isOngoingNotificationVisible = false;
          if (kDebugMode) print("Cancelling ongoing VOC notification.");

          // 보이드 종료 알림 표시
          _notificationService.scheduleNotification(
            id: 2, // 새 ID로 종료 알림
            title: '보이드 종료',
            body: '보이드가 종료되었습니다.',
            scheduledTime: now.add(const Duration(seconds: 1)), // 즉시 표시
            canScheduleExact: true,
          );
          if (kDebugMode) print("Showing VOC ended notification.");

          // 데이터 새로고침을 트리거하여 다음 VOC를 찾습니다.
          if (kDebugMode) print("VOC ended, triggering data refresh.");
          _selectedDate = now;
          refreshData();
          return; // 새로고침 후 종료
        }
      }
    }

    // 2. 데이터 새로고침 조건 확인 (VOC 외)
    if (_selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day) {
      
      bool shouldRefresh = false;
      String refreshReason = "";

      // 다음 문 페이즈 시간이 지났는지 확인
      if (_nextMoonPhaseTime != null && now.isAfter(_nextMoonPhaseTime!)) {
        shouldRefresh = true;
        refreshReason = "Next Moon Phase time has passed.";
      }
      // 다음 문 사인이 끝나는 시간이 지났는지 확인
      else if (_nextSignTime != null && now.isAfter(_nextSignTime!)) {
        shouldRefresh = true;
        refreshReason = "Moon Sign end time has passed.";
      }

      if (shouldRefresh) {
        if (kDebugMode) {
          print("Time to refresh data: $refreshReason. Refreshing...");
        }
        _selectedDate = now; // 날짜를 현재로 업데이트
        refreshData(); // 데이터 새로고침
        return; // 새로고침 후 함수 종료
      }
    }
  }

  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> updateDate(DateTime newDate) async {
    _selectedDate = newDate;
    await _updateData();
  }

  Future<void> refreshData() async {
    _cache.clear();
    await _updateData();
  }

  Future<void> _updateData() async {
    _isLoading = true;
    notifyListeners();

    if (kDebugMode) {
      print("--- ");
      print("[AstroState] Starting data update for: $_selectedDate");
    }

    final dateForCalc = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);

    try {
      if (kDebugMode) print("[AstroState] Calculating Moon Phase, Sign, and VOC...");
      
      final nextPhaseInfo = _calculator.findNextPhase(dateForCalc);
      final moonPhaseInfo = _calculator.getMoonPhaseInfo(dateForCalc);
      final moonPhase = moonPhaseInfo['phaseName'];
      final moonZodiac = _calculator.getMoonZodiacEmoji(dateForCalc);
      final moonInSign = _calculator.getMoonZodiacName(dateForCalc);
      final vocTimes = _calculator.findVoidOfCoursePeriod(dateForCalc);
      final moonSignTimes = _calculator.getMoonSignTimes(dateForCalc);

      final Map<String, dynamic> result = {
        'moonPhase': moonPhase,
        'moonZodiac': moonZodiac,
        'moonInSign': moonInSign,
        'vocStart': vocTimes['start'],
        'vocEnd': vocTimes['end'],
        'nextSignTime': moonSignTimes['end'],
        'nextMoonPhaseName': nextPhaseInfo['name'] ?? 'N/A',
        'nextMoonPhaseTime': nextPhaseInfo['time'],
      };

      if (kDebugMode) {
        print("[AstroState] Calculation complete. New data:");
        result.forEach((key, value) {
          print("  - $key: $value");
        });
        print("--- ");
      }
      
      await _updateStateFromResult(result);
      _lastError = null;
    } catch (e, stack) {
      if (kDebugMode) {
        print('[AstroState] Error during calculation: $e\n$stack');
        print("--- ");
      }
      _lastError = '계산 중 오류 발생: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _updateStateFromResult(Map<String, dynamic> result) async {
    _moonPhase = result['moonPhase'] as String;
    _moonZodiac = result['moonZodiac'] as String;
    _moonInSign = result['moonInSign'] as String;
    _vocStart = result['vocStart'] as DateTime?;
    _vocEnd = result['vocEnd'] as DateTime?;
    _nextSignTime = result['nextSignTime'] as DateTime?;
    _nextMoonPhaseName = result['nextMoonPhaseName'] as String;
    _nextMoonPhaseTime = result['nextMoonPhaseTime'] as DateTime?;
    await _schedulePreVoidAlarm();
  }
}
