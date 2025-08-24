// astro_state.dart
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

  Future<void> toggleVoidAlarm(bool enable) async {
    if (enable) {
      final bool hasPermission = await _notificationService.requestPermissions();
      if (hasPermission) {
        _voidAlarmEnabled = true;
        _scheduleVoidNotifications();
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
  }

  void _scheduleVoidNotifications() {
    _notificationService.cancelAllNotifications();
    if (!_voidAlarmEnabled) return;

    if (_vocStart != null && _vocStart!.isAfter(DateTime.now())) {
      final oneHourBefore = _vocStart!.subtract(const Duration(hours: 5));
      _notificationService.scheduleNotification(
        id: 0,
        title: '보이드 알람',
        body: '1시간 후에 보이드가 시작됩니다.',
        scheduledTime: oneHourBefore,
      );
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

    // 실시간 데이터 갱신은 사용자가 현재 날짜를 보고 있을 때만 실행합니다.
    if (_selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day) {
      final shouldRefreshForSign = _nextSignTime != null && now.isAfter(_nextSignTime!);

      if (shouldRefreshForSign) {
        if (kDebugMode) {
          print("Moon sign ended. Refreshing data...");
        }
        _selectedDate = now;
        refreshData();
      }
    }
    
    // 이전에 논의한 VOC 알람 로직은 그대로 유지합니다.
    if (_voidAlarmEnabled) {
      final start = _vocStart;
      final end = _vocEnd;
      if (start != null && end != null) {
        if (now.isAfter(start) && now.isBefore(end) && !_isOngoingNotificationVisible) {
          _notificationService.showOngoingNotification(
            id: 1,
            title: '보이드 중',
            body: '현재 보이드 오브 코스 기간입니다.',
          );
          _isOngoingNotificationVisible = true;
          if (kDebugMode) print("Showing ongoing notification.");
        } else if (now.isAfter(end) && _isOngoingNotificationVisible) {
          _notificationService.cancelNotification(1);
          _isOngoingNotificationVisible = false;
          if (kDebugMode) print("Cancelling ongoing notification.");
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

    // 모든 계산은 선택된 날짜의 시작(자정)을 기준으로 수행합니다.
    final dateForCalc = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    // final dateKey = '${dateForCalc.year}-${dateForCalc.month}-${dateForCalc.day}';

    // Caching disabled
    // if (_cache.containsKey(dateKey)) {
    //   final result = _cache[dateKey]!;
    //   if (kDebugMode) {
    //     print('Using cached data for $dateKey: $result');
    //   }
    //   _updateStateFromResult(result);
    //   _isLoading = false;
    //   notifyListeners();
    //   return;
    // }

    try {
      // 모든 계산은 dateForCalc를 기준으로 수행합니다.
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

      // if (kDebugMode) {
      //   print('Calculated data for $dateKey: $result');
      // }
      // _cache[dateKey] = result;
      _updateStateFromResult(result);
      _lastError = null;
    } catch (e, stack) {
      if (kDebugMode) {
        print('계산 중 오류 발생: $e\n$stack');
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
    _scheduleVoidNotifications();
  }
}