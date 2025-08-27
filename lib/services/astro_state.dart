import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'astro_calculator.dart';
import 'notification_service.dart';
import 'package:sweph/sweph.dart';

final AstroCalculator _calculator = AstroCalculator();

enum AlarmPermissionStatus {
  granted,
  notificationDenied,
  exactAlarmDenied,
}

class AstroState with ChangeNotifier {
  Timer? _timer;
  final NotificationService _notificationService = NotificationService();
  bool _voidAlarmEnabled = false;
  int _preVoidAlarmHours = 3;
  bool _isOngoingNotificationVisible = false;
  DateTime _selectedDate = DateTime.now();
  bool _isFollowingTime = true;
  String _moonPhase = '';
  String _moonZodiac = '';
  String _moonInSign = '';

  // VOC for the selected date
  DateTime? _vocStart;
  DateTime? _vocEnd;

  // VOC for the current, real time
  DateTime? _realtimeVocStart;
  DateTime? _realtimeVocEnd;

  DateTime? _nextSignTime;
  String? _lastError;
  bool _isInitialized = false;
  bool _isLoading = false;
  bool _isDarkMode = false;
  String _nextMoonPhaseName = 'calculating';
  DateTime? _nextMoonPhaseTime;
  DateTime? _lastLogTime;
  late String _currentLocale;

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
  bool get isFollowingTime => _isFollowingTime;

  // Getter for the UI to know the real-time VOC status
  bool get isRealtimeVoc => _isOngoingNotificationVisible;

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
      _preVoidAlarmHours = prefs.getInt('preVoidAlarmHours') ?? 3;

      // This calculates for the initial date (today)
      await _updateData();

      // Also find the VOC period for the current time and store it separately
      final vocTimes = _calculator.findVoidOfCoursePeriod(DateTime.now());
      _realtimeVocStart = vocTimes['start'];
      _realtimeVocEnd = vocTimes['end'];

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
      // When locale changes, we need to reschedule the pre-void alarm
      // and update ongoing notifications if any.
      await _schedulePreVoidAlarm();
      _checkTime(); // Re-check to update ongoing notification text immediately
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
      _isOngoingNotificationVisible = false; // Make sure to update state
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

    // The pre-void alarm should always be for the *next actual* VOC.
    final vocTimes = _calculator.findVoidOfCoursePeriod(DateTime.now());
    final vocStartForAlarm = vocTimes['start'] as DateTime?;
    final vocEndForAlarm = vocTimes['end'] as DateTime?;

    if (vocStartForAlarm == null || vocStartForAlarm.isBefore(DateTime.now())) {
      // If we are currently in the found VOC period, it's not an error.
      // It just means the pre-alarm time has already passed.
      if (vocEndForAlarm != null && vocEndForAlarm.isAfter(DateTime.now())) {
        if (kDebugMode)
          print('[VOC ALARM] In VOC, pre-void alarm time has passed.');
        return;
      }

      if (kDebugMode) print('[VOC ALARM] No upcoming VOC found or it has passed.');
      _lastError = 'noUpcomingVocFound';
      notifyListeners();
      return;
    }

    _lastError = null;
    final now = DateTime.now();
    final scheduledNotificationTime =
        vocStartForAlarm.subtract(Duration(hours: _preVoidAlarmHours));
    final bool canScheduleExact =
        await _notificationService.checkExactAlarmPermission();

    String notificationBody;
    String title;
    final locale = _currentLocale;

    if (locale.startsWith('ko')) {
      title = 'Void of Course 알림';
      notificationBody = '$_preVoidAlarmHours시간 후에 보이드가 시작됩니다.';
    } else {
      title = 'Void of Course Notification';
      notificationBody = 'Void of Course begins in $_preVoidAlarmHours hours.';
    }

    if (scheduledNotificationTime.isAfter(now)) {
      if (kDebugMode) print('[VOC ALARM] SCENARIO 1: Scheduled for the future.');
      try {
        await _notificationService.scheduleNotification(
          id: 0,
          title: title,
          body: notificationBody,
          scheduledTime: scheduledNotificationTime,
          canScheduleExact: canScheduleExact,
        );
      } catch (e, stack) {
        print('[VOC ALARM] ERROR scheduling notification: $e\n$stack');
        _lastError = 'errorSchedulingAlarm';
      }
    } else if (isToggleOn) {
      await _updatePreVoidAlarmNotification(vocStartForAlarm);
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

    // --- Real-time VOC Management ---
    if (_realtimeVocEnd != null && now.isAfter(_realtimeVocEnd!)) {
      // The VOC we were tracking is over. Find the next one.
      final vocTimes = _calculator.findVoidOfCoursePeriod(now);
      _realtimeVocStart = vocTimes['start'];
      _realtimeVocEnd = vocTimes['end'];
    }

    if (_voidAlarmEnabled &&
        _realtimeVocStart != null &&
        _realtimeVocEnd != null) {
      final isCurrentlyInVoc =
          now.isAfter(_realtimeVocStart!) && now.isBefore(_realtimeVocEnd!);

      if (isCurrentlyInVoc && !_isOngoingNotificationVisible) {
        // VOC period has just started
        _isOngoingNotificationVisible = true;
        final locale = _currentLocale;
        String title, body;
        if (locale.startsWith('ko')) {
          title = '보이드 시작';
          body = '지금부터 보이드 시간입니다.';
        } else {
          title = 'Void of Course Started';
          body = 'The Void of Course period has now begun.';
        }
        _notificationService.showImmediateNotification(
            id: 1, title: title, body: body, isVibrate: true);
        _updateOngoingNotification(); // Show and update the ongoing notification
        if (kDebugMode) print("Showing ongoing VOC notification.");
      } else if (isCurrentlyInVoc && _isOngoingNotificationVisible) {
        // VOC is still in progress, update notification
        _updateOngoingNotification();
      } else if (!isCurrentlyInVoc && _isOngoingNotificationVisible) {
        // VOC period has just ended
        _isOngoingNotificationVisible = false;
        _notificationService.cancelNotification(1);
        _notificationService.cancelNotification(2);
        if (kDebugMode) print("Cancelling ongoing VOC notification.");

        final locale = _currentLocale;
        String title, body;
        if (locale.startsWith('ko')) {
          title = '보이드 종료';
          body = '보이드가 종료되었습니다.';
        } else {
          title = 'Void of Course Ended';
          body = 'The Void of Course period has ended.';
        }
        _notificationService.showImmediateNotification(
            id: 3, title: title, body: body);
        if (kDebugMode) print("Showing VOC ended notification.");

        // If user is viewing today, refresh the data to show the next VOC
        if (_isFollowingTime) {
          refreshData();
        }
      }
    }
    // --- End of Real-time VOC Management ---

    // This part is for auto-updating the screen when the user is following time
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
        return;
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> updateDate(DateTime newDate) async {
    _selectedDate = newDate;

    final now = DateTime.now();
    final bool isNowFollowingTime = newDate.year == now.year &&
        newDate.month == now.month &&
        newDate.day == now.day;

    // [FIX] No longer cancel ongoing notifications when changing date.
    // The real-time VOC status is now managed independently in _checkTime.

    _isFollowingTime = isNowFollowingTime;

    if (_isFollowingTime) {
      _selectedDate = now;
    }
    // Always update data for the selected date.
    await _updateData();
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
    _nextSignTime = result['nextSignTime'] as DateTime?;
    _nextMoonPhaseName = result['nextMoonPhaseName'] as String;
    _nextMoonPhaseTime = result['nextMoonPhaseTime'] as DateTime?;
    // Do not schedule pre-void alarm from here. It's managed separately.
  }

  Future<void> _updateOngoingNotification() async {
    if (_realtimeVocStart == null || _realtimeVocEnd == null) return;

    final now = DateTime.now();
    final remainingDuration = _realtimeVocEnd!.difference(now);

    final hours = remainingDuration.inHours;
    final minutes = remainingDuration.inMinutes.remainder(60);

    String remainingTimeText;
    final locale = _currentLocale;
    if (locale.startsWith('ko')) {
      if (hours > 0) {
        remainingTimeText = '남은 시간: ${hours}시간 ${minutes}분';
      } else {
        remainingTimeText = '남은 시간: ${minutes}분';
      }
    } else {
      if (hours > 0) {
        remainingTimeText = 'Time remaining: ${hours}h ${minutes}m';
      } else {
        remainingTimeText = 'Time remaining: $minutes minutes';
      }
    }

    String title, body;
    if (locale.startsWith('ko')) {
      title = '보이드 중';
      body = '지금은 보이드 시간입니다. $remainingTimeText';
    } else {
      title = 'Void of Course in Progress';
      body = 'Currently in Void of Course period. $remainingTimeText';
    }

    await _notificationService.showOngoingNotification(
      id: 2,
      title: title,
      body: body,
    );
  }

  Future<void> _updatePreVoidAlarmNotification(DateTime vocStart) async {

    final now = DateTime.now();
    final remainingDuration = vocStart.difference(now);

    final hours = remainingDuration.inHours;
    final minutes = remainingDuration.inMinutes.remainder(60);
    final seconds = remainingDuration.inSeconds.remainder(60);

    String notificationBody;
    final locale = _currentLocale;
    if (locale.startsWith('ko')) {
      if (hours > 0) {
        notificationBody = '보이드 시작까지 ${hours}시간 ${minutes}분 남았습니다.';
      } else if (minutes > 0) {
        notificationBody = '보이드 시작까지 ${minutes}분 남았습니다.';
      } else if (minutes >= 1) {
        notificationBody = '보이드 시작까지 ${seconds}초 남았습니다.';
      } else {
        notificationBody = '보이드가 곧 시작됩니다.';
      }
    } else {
      if (hours > 0) {
        notificationBody = '$hours h $minutes m until Void of Course begins.';
      } else if (minutes > 0) {
        notificationBody = '$minutes minutes until Void of Course begins.';
      } else if (minutes >= 1) {
        notificationBody = ' $seconds Seconds until Void of Course begins.';
      } else {
        notificationBody = 'Void of Course begins soon.';
      }
    }

    String title;
    if (locale.startsWith('ko')) {
      title = 'Void of Course 알림';
    } else {
      title = 'Void of Course Notification';
    }

    await _notificationService.showOngoingNotification(
      id: 0,
      title: title,
      body: notificationBody,
    );
  }
}