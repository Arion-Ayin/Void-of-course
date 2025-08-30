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
  int _preVoidAlarmHours = 5;
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

    if (enable) {
      // 1. Request standard notification permission
      final bool hasNotificationPermission =
          await _notificationService.requestPermissions();
      if (!hasNotificationPermission) {
        notifyListeners();
        return AlarmPermissionStatus.notificationDenied;
      }

      // 2. Check and request exact alarm permission
      bool hasExactAlarmPermission =
          await _notificationService.checkExactAlarmPermission();
      if (!hasExactAlarmPermission) {
        await _notificationService.requestExactAlarmPermission();
        // Check again after user returns from settings
        hasExactAlarmPermission =
            await _notificationService.checkExactAlarmPermission();
      }

      // 3. Update state and schedule alarm only if permission is granted
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
      // Disabling alarm
      _voidAlarmEnabled = false;
      await prefs.setBool('voidAlarmEnabled', false);
      await _notificationService.cancelAllNotifications();
      _isOngoingNotificationVisible = false;
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
    // 1. Always cancel previous alarms to avoid conflicts
    await _notificationService.cancelNotification(0);
    if (!_voidAlarmEnabled) {
      return;
    }

    // 2. Find the next upcoming VOC period.
    final vocTimes = _calculator.findVoidOfCoursePeriod(DateTime.now());
    _realtimeVocStart = vocTimes['start'];
    _realtimeVocEnd = vocTimes['end'];

    // 3. Trigger an immediate check.
    // _checkTime() will now handle showing the pre-void or in-void notification based on the latest times.
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
        return; // Return after refresh to avoid conflicting UI updates
      }
    }

    // --- Real-time VOC Notification Management ---

    // If alarms are disabled, ensure no notifications are showing and stop.
    if (!_voidAlarmEnabled) {
      if (_isOngoingNotificationVisible) {
        _notificationService.cancelNotification(1);
        _notificationService.cancelNotification(2);
        _isOngoingNotificationVisible = false;
      }
      _notificationService.cancelNotification(0); // Also cancel pre-void
      return;
    }

    // If the VOC we were tracking is long over, find the next one to be prepared.
    if (_realtimeVocEnd != null &&
        now.isAfter(_realtimeVocEnd!.add(const Duration(minutes: 1)))) {
      final vocTimes = _calculator.findVoidOfCoursePeriod(now);
      _realtimeVocStart = vocTimes['start'];
      _realtimeVocEnd = vocTimes['end'];
    }

    // Proceed only if we have a valid upcoming VOC
    if (_realtimeVocStart == null || _realtimeVocEnd == null) {
      return;
    }

    final vocStart = _realtimeVocStart!;
    final vocEnd = _realtimeVocEnd!;
    final preAlarmTime = vocStart.subtract(Duration(hours: _preVoidAlarmHours));

    final isCurrentlyInVoc = now.isAfter(vocStart) && now.isBefore(vocEnd);
    final isCurrentlyInPreVoc = now.isAfter(preAlarmTime) && now.isBefore(vocStart);

    // --- State Machine for Notifications ---

    if (isCurrentlyInPreVoc) {
      // STATE 1: Pre-VOC Countdown
      // We are in the countdown window. Show/update the countdown notification.
      if (_isOngoingNotificationVisible) {
        // This can happen if date/time changes abruptly.
        // Ensure main VOC notification is cancelled.
        _notificationService.cancelNotification(1);
        _notificationService.cancelNotification(2);
        _isOngoingNotificationVisible = false;
      }
      _updatePreVoidAlarmNotification(vocStart);
    } else if (isCurrentlyInVoc) {
      // STATE 2: In-VOC Period
      if (!_isOngoingNotificationVisible) {
        // VOC just started
        _notificationService.cancelNotification(0); // Clear pre-void notification
        _isOngoingNotificationVisible = true;

        // Show "VOC Started" alert
        final locale = _currentLocale;
        String title, body;
        if (locale.startsWith('ko')) {
          title = '보이드 시작';
          body = '지금은 보이드 시간입니다.';
        } else {
          title = 'Void of Course Started';
          body = 'The Void of Course period has now begun.';
        }
        _notificationService.showImmediateNotification(
            id: 1, title: title, body: body, isVibrate: true);
        if (kDebugMode) print("Showing VOC started notification.");

        // REFRESH UI
        if (_isFollowingTime) {
          refreshData();
        }
      }
      // Whether it just started or is in progress, update the ongoing notification
      _updateOngoingNotification();
    } else {
      // STATE 3: Outside of Pre-VOC or In-VOC windows
      if (_isOngoingNotificationVisible) {
        // VOC just ended
        _isOngoingNotificationVisible = false;
        _notificationService.cancelNotification(1); // In case it's still there
        _notificationService.cancelNotification(2); // The ongoing one
        if (kDebugMode) print("Cancelling ongoing VOC notification.");

        // Show "VOC Ended" alert
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

        // Find the next VOC period immediately
        final vocTimes = _calculator.findVoidOfCoursePeriod(now);
        _realtimeVocStart = vocTimes['start'];
        _realtimeVocEnd = vocTimes['end'];

        if (_isFollowingTime) {
          refreshData();
        }
      }
      // Also make sure the pre-void notification is cancelled
      _notificationService.cancelNotification(0);
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
      body = '지금은 보이드 시간입니다.\n$remainingTimeText';
    } else {
      title = 'Void of Course in Progress';
      body = 'Currently in Void of Course period.\n$remainingTimeText';
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
