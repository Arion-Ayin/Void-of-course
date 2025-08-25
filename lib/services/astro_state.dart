import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'astro_calculator.dart';
import 'notification_service.dart';
import 'package:sweph/sweph.dart';

final AstroCalculator _calculator = AstroCalculator();

class AstroState with ChangeNotifier {
  Timer? _timer;
  final NotificationService _notificationService = NotificationService();
  bool _voidAlarmEnabled = false;
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

  Future<bool> toggleVoidAlarm(bool enable) async {
    print('toggleVoidAlarm called with enable: $enable'); // Debug print
    if (enable) {
      final bool hasPermission = await _notificationService.requestPermissions();
      print('Notification permission granted: $hasPermission'); // Debug print
      if (hasPermission) {
        _voidAlarmEnabled = true;
        _schedulePreVoidAlarm();
      } else {
        _voidAlarmEnabled = false;
      }
    } else {
      _voidAlarmEnabled = false;
      _notificationService.cancelAllNotifications();
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('voidAlarmEnabled', _voidAlarmEnabled);
    notifyListeners();
    print('Returning _voidAlarmEnabled: $_voidAlarmEnabled'); // Debug print
    return _voidAlarmEnabled;
  }

  void _schedulePreVoidAlarm() {
    _notificationService.cancelAllNotifications();
    if (!_voidAlarmEnabled) return;

    if (_vocStart != null && _vocStart!.isAfter(DateTime.now())) {
      final now = DateTime.now();
      final timeUntilVocStart = _vocStart!.difference(now);

      // If VOC starts within the next hour (60 minutes)
      if (timeUntilVocStart.inMinutes <= 60) {
        final minutesRemaining = timeUntilVocStart.inMinutes;
        String notificationBody;
        if (minutesRemaining > 0) {
          notificationBody = '$minutesRemaining분 후에 보이드가 시작됩니다.';
        } else {
          // If it's very close or already started (within a minute or so)
          notificationBody = '보이드가 곧 시작됩니다.';
        }

        _notificationService.scheduleNotification(
          id: 0,
          title: 'Void of Course 알림',
          body: notificationBody,
          scheduledTime: now, // Schedule immediately
        );
      } else {
        // If VOC starts more than an hour later, schedule for 1 hour before
        final oneHourBefore = _vocStart!.subtract(const Duration(hours: 10));
        _notificationService.scheduleNotification(
          id: 0,
          title: 'Void of Course 알림',
          body: '1시간 후에 보이드가 시작됩니다.',
          scheduledTime: oneHourBefore,
        );
      }
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _checkTime();
    });
  }

  void _checkTime() {
    final now = DateTime.now();

    // 1. 데이터 새로고침 조건 확인 (오늘 날짜일 경우)
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
      // 보이드 종료 시간이 지났는지 확인
      else if (_vocEnd != null && now.isAfter(_vocEnd!) && _isOngoingNotificationVisible) {
        shouldRefresh = true;
        refreshReason = "VOC end time has passed.";
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


    // 2. 보이드 알람 및 지속적인 알림 처리
    if (_voidAlarmEnabled) {
      final start = _vocStart;
      final end = _vocEnd;
      if (start != null && end != null) {
        final isCurrentlyInVoc = now.isAfter(start) && now.isBefore(end);

        if (isCurrentlyInVoc && !_isOngoingNotificationVisible) {
          // 보이드 기간 시작 -> 지속적인 알림 표시
          _notificationService.showOngoingNotification(
            id: 1,
            title: '보이드 중',
            body: '현재 보이드 오브 코스 기간입니다.',
          );
          _isOngoingNotificationVisible = true;
          if (kDebugMode) print("Showing ongoing VOC notification.");
        } else if (!isCurrentlyInVoc && _isOngoingNotificationVisible) {
          // 보이드 기간 종료 -> 지속적인 알림 취소
          _notificationService.cancelNotification(1);
          _isOngoingNotificationVisible = false;
          if (kDebugMode) print("Cancelling ongoing VOC notification as VOC period has ended.");
          // 데이터 새로고침은 위의 로직에서 처리하므로 여기서는 알림만 제거합니다.
        }
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
      
      _updateStateFromResult(result);
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

  void _updateStateFromResult(Map<String, dynamic> result) {
    _moonPhase = result['moonPhase'] as String;
    _moonZodiac = result['moonZodiac'] as String;
    _moonInSign = result['moonInSign'] as String;
    _vocStart = result['vocStart'] as DateTime?;
    _vocEnd = result['vocEnd'] as DateTime?;
    _nextSignTime = result['nextSignTime'] as DateTime?;
    _nextMoonPhaseName = result['nextMoonPhaseName'] as String;
    _nextMoonPhaseTime = result['nextMoonPhaseTime'] as DateTime?;
    _schedulePreVoidAlarm();
  }
}