import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'astro_calculator.dart';
import 'notification_service.dart';
import 'package:sweph/sweph.dart';

final AstroCalculator _calculator = AstroCalculator();

enum AlarmPermissionStatus { granted, notificationDenied, exactAlarmDenied }

class AstroState with ChangeNotifier {
  Timer? _timer;
  final NotificationService _notificationService = NotificationService();
  bool _voidAlarmEnabled = false;
  int _preVoidAlarmHours = 6;

  DateTime _selectedDate = DateTime.now();
  bool _isFollowingTime = true;
  String _moonPhase = '';
  String _moonZodiac = '';
  String _moonInSign = '';

  // VOC for the selected date
  DateTime? _vocStart;
  DateTime? _vocEnd;

  // VOC Aspect Info
  String? _vocPlanet;
  String? _vocAspect;

  DateTime? _nextSignTime;
  String? _lastError;
  bool _isInitialized = false;
  bool _isLoading = false;
  bool _isDarkMode = false;
  String _nextMoonPhaseName = 'calculating';
  DateTime? _nextMoonPhaseTime;
  late String _currentLocale;

  DateTime get selectedDate => _selectedDate;
  String get moonPhase => _moonPhase;
  String get moonZodiac => _moonZodiac;
  String get moonInSign => _moonInSign;
  DateTime? get vocStart => _vocStart;
  DateTime? get vocEnd => _vocEnd;
  String? get vocPlanet => _vocPlanet;
  String? get vocAspect => _vocAspect;
  DateTime? get nextSignTime => _nextSignTime;
  String? get lastError => _lastError;
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  bool get isDarkMode => _isDarkMode;
  bool get voidAlarmEnabled => _voidAlarmEnabled;
  int get preVoidAlarmHours => _preVoidAlarmHours;
  String get nextMoonPhaseName => _nextMoonPhaseName;
  DateTime? get nextMoonPhaseTime => _nextMoonPhaseTime;
  bool get isFollowingTime => _isFollowingTime;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  void setTheme(bool isDark) {
    _isDarkMode = isDark;
    notifyListeners();
  }

  Future<void> followTime() async {
    if (_isFollowingTime) return;
    _isFollowingTime = true;
    _selectedDate = DateTime.now();
    await refreshData();
  }

  Future<void> initialize() async {
    if (_isInitialized) return;
    _isLoading = true;

    try {
      await Sweph.init();
      _currentLocale = Intl.getCurrentLocale();
      await _notificationService.init();
      final prefs = await SharedPreferences.getInstance();
      _voidAlarmEnabled = prefs.getBool('voidAlarmEnabled') ?? false;
      _preVoidAlarmHours = prefs.getInt('preVoidAlarmHours') ?? 6;

      await _updateData();

      _isInitialized = true;
      _startTimer();
      _lastError = null;
    } catch (e, stack) {
      print('Initialization error: $e\n$stack');
      _lastError = 'initializationError';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateLocale(String newLocale) async {
    _currentLocale = newLocale;
    if (_voidAlarmEnabled) {
      await _schedulePreVoidAlarm();
      _checkTime();
    }
  }

  Future<AlarmPermissionStatus> toggleVoidAlarm(bool enable) async {
    final prefs = await SharedPreferences.getInstance();

    if (enable) {
      final bool hasNotificationPermission =
          await _notificationService.requestPermissions();
      if (!hasNotificationPermission) {
        _voidAlarmEnabled = false;
        notifyListeners();
        return AlarmPermissionStatus.notificationDenied;
      }

      bool hasExactAlarmPermission =
          await _notificationService.checkExactAlarmPermission();
      if (!hasExactAlarmPermission) {
        await _notificationService.requestExactAlarmPermission();
        hasExactAlarmPermission =
            await _notificationService.checkExactAlarmPermission();
      }

      if (hasExactAlarmPermission) {
        _voidAlarmEnabled = true;
        await prefs.setBool('voidAlarmEnabled', true);
        await _schedulePreVoidAlarm(isToggleOn: true);
        notifyListeners();
        return AlarmPermissionStatus.granted;
      } else {
        _voidAlarmEnabled = false;
        await prefs.setBool('voidAlarmEnabled', false);
        notifyListeners();
        return AlarmPermissionStatus.exactAlarmDenied;
      }
    } else {
      _voidAlarmEnabled = false;
      await prefs.setBool('voidAlarmEnabled', false);
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
    await _notificationService.cancelAllNotifications();

    if (!_voidAlarmEnabled) {
      notifyListeners();
      return;
    }

    bool hasExactAlarmPermission =
        await _notificationService.checkExactAlarmPermission();
    if (!hasExactAlarmPermission) {
      await _notificationService.requestExactAlarmPermission();
      hasExactAlarmPermission =
          await _notificationService.checkExactAlarmPermission();
      if (!hasExactAlarmPermission) {
        if (kDebugMode)
          print(
            "Exact alarm permission denied, cannot schedule notifications.",
          );
        return;
      }
    }

    final now = DateTime.now();
    DateTime searchDate = now;
    int notificationId =
        1000; // Start IDs from 1000 to avoid conflict with ongoing (0, 2)

    // Schedule next 10 events
    for (int i = 0; i < 10; i++) {
      final vocTimes = _calculator.findVoidOfCoursePeriod(searchDate);
      final vocStart = vocTimes['start'];
      final vocEnd = vocTimes['end'];

      if (vocStart == null || vocEnd == null) {
        // If we can't find a VOC, try searching from next day to avoid infinite loop if logic fails
        searchDate = searchDate.add(const Duration(days: 1));
        continue;
      }

      // If this VOC is already passed, move to next
      if (vocEnd.isBefore(now)) {
        searchDate = vocEnd.add(const Duration(minutes: 1));
        continue;
      }

      final locale = _currentLocale;
      final preAlarmTime = vocStart.subtract(
        Duration(hours: _preVoidAlarmHours),
      );

      // 1. Pre-VOC Alarm (Counts down to Start)
      if (preAlarmTime.isAfter(now)) {
        String preTitle =
            locale.startsWith('ko') ? '보이드 시작 알림' : 'Void of Course Upcoming';
        String preBody =
            locale.startsWith('ko')
                ? '보이드 시작까지 남은 시간:'
                : 'Time until Void of Course begins:';
        await _notificationService.scheduleNotification(
          id: notificationId++,
          title: preTitle,
          body: preBody,
          scheduledTime: preAlarmTime,
          canScheduleExact: hasExactAlarmPermission,
          usesChronometer: true,
          chronometerCountDown: true,
          when: vocStart.millisecondsSinceEpoch,
        );
      } else if (vocStart.isAfter(now)) {
        // 현재 보이드 시작 전 6시간 이내인 경우 - 즉시 알림 스케줄링 (크로노미터 사용을 위해)
        String preTitle =
            locale.startsWith('ko') ? '보이드 시작 알림' : 'Void of Course Upcoming';
        String preBody =
            locale.startsWith('ko')
                ? '보이드 시작까지 남은 시간:'
                : 'Time until Void of Course begins:';
        await _notificationService.scheduleNotification(
          id: notificationId++,
          title: preTitle,
          body: preBody,
          scheduledTime: now.add(const Duration(seconds: 2)),
          canScheduleExact: hasExactAlarmPermission,
          usesChronometer: true,
          chronometerCountDown: true,
          when: vocStart.millisecondsSinceEpoch,
        );
      }

      // 2. VOC Start Alarm (Counts down to End)
      if (vocStart.isAfter(now)) {
        String startTitle =
            locale.startsWith('ko') ? '보이드 시작' : 'Void of Course Started';
        String startBody =
            locale.startsWith('ko')
                ? '보이드 종료까지 남은 시간:'
                : 'Time until Void of Course ends:';
        await _notificationService.scheduleNotification(
          id: notificationId++,
          title: startTitle,
          body: startBody,
          scheduledTime: vocStart,
          canScheduleExact: hasExactAlarmPermission,
          usesChronometer: true,
          chronometerCountDown: true,
          when: vocEnd.millisecondsSinceEpoch,
        );
      } else if (vocEnd.isAfter(now)) {
        // 현재 보이드 중인 경우 - 즉시 알림 스케줄링
        String startTitle =
            locale.startsWith('ko') ? '보이드 시작' : 'Void of Course Started';
        String startBody =
            locale.startsWith('ko')
                ? '보이드 종료까지 남은 시간:'
                : 'Time until Void of Course ends:';
        await _notificationService.scheduleNotification(
          id: notificationId++,
          title: startTitle,
          body: startBody,
          scheduledTime: now.add(const Duration(seconds: 2)),
          canScheduleExact: hasExactAlarmPermission,
          usesChronometer: true,
          chronometerCountDown: true,
          when: vocEnd.millisecondsSinceEpoch,
        );
      }

      // 3. VOC End Alarm (No countdown)
      if (vocEnd.isAfter(now)) {
        String endTitle =
            locale.startsWith('ko') ? '보이드 종료' : 'Void of Course Ended';
        String endBody =
            locale.startsWith('ko')
                ? '보이드 시간이 종료되었습니다.'
                : 'The Void of Course period has ended.';
        await _notificationService.scheduleNotification(
          id: notificationId++,
          title: endTitle,
          body: endBody,
          scheduledTime: vocEnd,
          canScheduleExact: hasExactAlarmPermission,
        );
      }

      // Prepare for next iteration
      searchDate = vocEnd.add(const Duration(minutes: 1));
    }

    if (kDebugMode) {
      print("Scheduled notifications for next 10 VOC periods.");
    }

    _checkTime();
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

    // 1. (기존 로직) 현재 시간을 따르는 중일 때 데이터 자동 새로고침
    if (_isFollowingTime) {
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
        // 데이터를 새로고칠 때, 알람 스케줄도 다시 잡아야 합니다.
        if (_voidAlarmEnabled) {
          _schedulePreVoidAlarm();
        }
      }
    }
  }

  Future<void> updateDate(DateTime newDate) async {
    _selectedDate = newDate;

    final now = DateTime.now();
    final bool isNowFollowingTime =
        newDate.year == now.year &&
        newDate.month == now.month &&
        newDate.day == now.day;

    _isFollowingTime = isNowFollowingTime;

    if (_isFollowingTime) {
      _selectedDate = now;
    }
    await refreshData();
  }

  Future<void> refreshData() async {
    await _updateData();
  }

  Future<void> _updateData() async {
    _isLoading = true;
    notifyListeners();

    final dateForCalc = _selectedDate;

    try {
      final nextPhaseInfo = _calculator.findNextPhase(dateForCalc);
      final moonPhaseInfo = _calculator.getMoonPhaseInfo(dateForCalc);
      final moonPhase = moonPhaseInfo['phaseName'];
      final moonZodiac = _calculator.getMoonZodiacEmoji(dateForCalc);
      var vocTimes = _calculator.findVoidOfCoursePeriod(dateForCalc);

      // If we are following time and the found VOC has already passed, find the next one
      if (_isFollowingTime && vocTimes['end'] != null) {
        final now = DateTime.now();
        final vocEnd = vocTimes['end'] as DateTime;
        if (vocEnd.isBefore(now)) {
          // Search from the next day to ensure we find the next VOC event
          // (findVoidOfCoursePeriod resets search to start of the day)
          vocTimes = _calculator.findVoidOfCoursePeriod(
            vocEnd.add(const Duration(days: 1)),
          );
        }
      }

      final moonSignTimes = _calculator.getMoonSignTimes(dateForCalc);

      final moonSignName = _calculator.getMoonSignName(dateForCalc);

      if (kDebugMode) {
        print('[DEBUG] moonPhaseInfo: $moonPhaseInfo');
        print('[DEBUG] moonZodiac: $moonZodiac');
        print('[DEBUG] moonInSign (Name): $moonSignName');
        print('[DEBUG] vocTimes: $vocTimes');
        print('[DEBUG] moonSignTimes: $moonSignTimes');
        print('[DEBUG] nextPhaseInfo: $nextPhaseInfo');
      }

      final Map<String, dynamic> result = {
        'moonPhase': moonPhase,
        'moonZodiac': moonZodiac,
        'moonInSign': moonSignName,
        'vocStart': vocTimes['start'],
        'vocEnd': vocTimes['end'],
        'vocPlanet': vocTimes['planet'],
        'vocAspect': vocTimes['aspect'],
        'nextSignTime': moonSignTimes['end'],
        'nextMoonPhaseName': nextPhaseInfo['name'] ?? 'N/A',
        'nextMoonPhaseTime': nextPhaseInfo['time'],
      };

      await _updateStateFromResult(result);
      _lastError = null;
    } catch (e, stack) {
      if (kDebugMode) {
        print('[AstroState] Error during calculation: $e\n$stack');
      }
      _lastError = 'calculationError';
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
    _vocPlanet = result['vocPlanet'] as String?;
    _vocAspect = result['vocAspect'] as String?;
    _nextSignTime = result['nextSignTime'] as DateTime?;
    _nextMoonPhaseName = result['nextMoonPhaseName'] as String;
    _nextMoonPhaseTime = result['nextMoonPhaseTime'] as DateTime?;
  }
}
