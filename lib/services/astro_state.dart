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
  int _preVoidAlarmHours = 4;
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
  int get preVoidAlarmHours => _preVoidAlarmHours;
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
      _preVoidAlarmHours = prefs.getInt('preVoidAlarmHours') ?? 3;
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
    _voidAlarmEnabled = enable;
    await prefs.setBool('voidAlarmEnabled', _voidAlarmEnabled);

    if (enable) {
      final bool hasNotificationPermission =
          await _notificationService.requestPermissions();
      if (!hasNotificationPermission) {
        notifyListeners();
        return AlarmPermissionStatus.notificationDenied;
      }

      final bool hasExactAlarmPermission =
          await _notificationService.checkExactAlarmPermission();
      await _schedulePreVoidAlarm(isToggleOn: true);
      if (!hasExactAlarmPermission) {
        notifyListeners();
        return AlarmPermissionStatus.exactAlarmDenied;
      }
      notifyListeners();
      return AlarmPermissionStatus.granted;
    } else {
      await _notificationService.cancelAllNotifications();
      notifyListeners();
      return AlarmPermissionStatus.granted;
    }
  }

  Future<void> setPreVoidAlarmHours(int hours) async {
    _preVoidAlarmHours = hours;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('preVoidAlarmHours', hours);
    await _schedulePreVoidAlarm(isToggleOn: false);
    notifyListeners();
  }

  Future<void> _schedulePreVoidAlarm({bool isToggleOn = false}) async {
    await _notificationService.cancelNotification(0);
    if (!_voidAlarmEnabled) {
      if (kDebugMode) print('[VOC ALARM] Alarm is disabled.');
      return;
    }
    if (_vocStart == null || _vocStart!.isBefore(DateTime.now())) {
      if (kDebugMode) print('[VOC ALARM] No upcoming VOC found or it has passed.');
      _lastError = '선택된 날짜에 예정된 보이드 기간이 없거나 이미 지났습니다. 알람이 예약되지 않았습니다.';
      notifyListeners();
      return;
    }

    _lastError = null;
    final now = DateTime.now();
    final scheduledNotificationTime =
        _vocStart!.subtract(Duration(hours: _preVoidAlarmHours));
    final bool canScheduleExact =
        await _notificationService.checkExactAlarmPermission();
    String notificationBody = '$_preVoidAlarmHours시간 후에 보이드가 시작됩니다.';

    if (scheduledNotificationTime.isAfter(now)) {
      if (kDebugMode) print('[VOC ALARM] SCENARIO 1: Scheduled for the future.');
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
    } else if (isToggleOn) {
      await _updatePreVoidAlarmNotification();
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

    if (_voidAlarmEnabled) {
      final start = _vocStart;
      final end = _vocEnd;
      if (start != null && end != null) {
        final isCurrentlyInVoc = now.isAfter(start) && now.isBefore(end);
        final isVocStartingSoon =
            now.isAfter(start.subtract(Duration(hours: preVoidAlarmHours))) &&
                now.isBefore(start);

        // 보이드 시작 전 알림 업데이트
        if (isVocStartingSoon) {
          _updatePreVoidAlarmNotification();
        }

        // 보이드 진행 중 알림 업데이트
        if (isCurrentlyInVoc) {
          if (!_isOngoingNotificationVisible) {
            // 보이드 시작 시, 진동이 있는 알림을 한 번만 보냄
            _notificationService.showImmediateNotification(
              id: 1,
              title: '보이드 시작',
              body: '지금부터 보이드 시간입니다.',
              isVibrate: true,
            );
            
            // 동시에, 진동이 없는 고정 알림을 시작하여 시간 업데이트에 사용
            _notificationService.showOngoingNotification(
              id: 2,
              title: '보이드 중',
              body: '지금은 보이드 시간입니다.',
            );
            _isOngoingNotificationVisible = true;
            if (kDebugMode) print("Showing ongoing VOC notification.");
          } else {
            _updateOngoingNotification();
          }
        } else if (!isCurrentlyInVoc && now.isAfter(end) && _isOngoingNotificationVisible) {
          _notificationService.cancelNotification(1);
          _notificationService.cancelNotification(2);
          _isOngoingNotificationVisible = false;
          if (kDebugMode) print("Cancelling ongoing VOC notification.");

          _notificationService.showImmediateNotification(
            id: 3,
            title: '보이드 종료',
            body: '보이드가 종료되었습니다.',
          );
          if (kDebugMode) print("Showing VOC ended notification.");
          _selectedDate = now;
          refreshData();
          return;
        }
      }
    }

    if (_selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day) {
      bool shouldRefresh = false;
      String refreshReason = "";

      if (_nextMoonPhaseTime != null && now.isAfter(_nextMoonPhaseTime!)) {
        shouldRefresh = true;
        refreshReason = "Next Moon Phase time has passed.";
      } else if (_nextSignTime != null && now.isAfter(_nextSignTime!)) {
        shouldRefresh = true;
        refreshReason = "Moon Sign end time has passed.";
      }

      if (shouldRefresh) {
        if (kDebugMode) {
          print("Time to refresh data: $refreshReason. Refreshing...");
        }
        _selectedDate = now;
        refreshData();
        return;
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
    await _updateData();
  }

  Future<void> _updateData() async {
    _isLoading = true;
    notifyListeners();

    if (kDebugMode) {
      print("--- ");
      print("[AstroState] Starting data update for: $_selectedDate");
    }

    final dateForCalc =
        DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);

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
          print(" - $key: $value");
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
    await _schedulePreVoidAlarm(isToggleOn: false);
  }

  Future<void> _updateOngoingNotification() async {
    if (_vocStart == null || _vocEnd == null) return;

    final now = DateTime.now();
    final remainingDuration = _vocEnd!.difference(now);

    final hours = remainingDuration.inHours;
    final minutes = remainingDuration.inMinutes.remainder(60);
    final seconds = remainingDuration.inSeconds.remainder(60);

    String remainingTimeText;
    if (hours > 0) {
      remainingTimeText = '남은 시간: ${hours}시간 ${minutes}분';
    } else {
      remainingTimeText = '남은 시간: ${minutes}분 ${seconds}초';
    }

    await _notificationService.showOngoingNotification(
      id: 2,
      title: '보이드 중',
      body: '지금은 보이드 시간입니다. $remainingTimeText',
    );

    _isOngoingNotificationVisible = true;
    if (kDebugMode) print("Updating ongoing VOC notification.");
  }

  Future<void> _updatePreVoidAlarmNotification() async {
    if (_vocStart == null) return;

    final now = DateTime.now();
    final remainingDuration = _vocStart!.difference(now);

    final hours = remainingDuration.inHours;
    final minutes = remainingDuration.inMinutes.remainder(60);
    final seconds = remainingDuration.inSeconds.remainder(60);

    String notificationBody;
    if (hours > 0) {
      notificationBody = '보이드 시작까지 ${hours}시간 ${minutes}분 남았습니다.';
    } else if (minutes > 0) {
      notificationBody = '보이드 시작까지 ${minutes}분 남았습니다.';
    } else {
      notificationBody = '보이드가 곧 시작됩니다.';
    }

    await _notificationService.showOngoingNotification(
      id: 0,
      title: 'Void of Course 알림',
      body: notificationBody,
    );
  }
}