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

      await _updateData();
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
      await _schedulePreVoidAlarm();
      _checkTime();
    }
  }

  Future<AlarmPermissionStatus> toggleVoidAlarm(bool enable) async {
    final prefs = await SharedPreferences.getInstance();

    if (enable) {
      final bool hasNotificationPermission = await _notificationService.requestPermissions();
      if (!hasNotificationPermission) {
        notifyListeners();
        return AlarmPermissionStatus.notificationDenied;
      }

      bool hasExactAlarmPermission = await _notificationService.checkExactAlarmPermission();
      if (!hasExactAlarmPermission) {
        await _notificationService.requestExactAlarmPermission();
        hasExactAlarmPermission = await _notificationService.checkExactAlarmPermission();
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
    await _notificationService.cancelAllNotifications();

    if (!_voidAlarmEnabled) {
      _isOngoingNotificationVisible = false;
      notifyListeners();
      return;
    }

    final now = DateTime.now();
    final vocTimes = _calculator.findVoidOfCoursePeriod(now);
    _realtimeVocStart = vocTimes['start'];
    _realtimeVocEnd = vocTimes['end'];

    if (_realtimeVocStart == null || _realtimeVocEnd == null) {
      if (kDebugMode) print("No upcoming VOC period found.");
      return;
    }

    final locale = _currentLocale;
    final preAlarmTime = _realtimeVocStart!.subtract(Duration(hours: _preVoidAlarmHours));

    bool hasExactAlarmPermission = await _notificationService.checkExactAlarmPermission();
    if (!hasExactAlarmPermission) {
      await _notificationService.requestExactAlarmPermission();
      hasExactAlarmPermission = await _notificationService.checkExactAlarmPermission();
      if (!hasExactAlarmPermission) {
        if (kDebugMode) print("Exact alarm permission denied, cannot schedule notifications.");
        return;
      }
    }

    // Pre-VOC 알림
    String preTitle = locale.startsWith('ko') ? '보이드 시작 알림' : 'Void of Course Upcoming';
    String preBody = locale.startsWith('ko')
        ? '보이드가 $_preVoidAlarmHours시간 후 시작됩니다.'
        : 'Void of Course begins in $_preVoidAlarmHours hours.';
    await _notificationService.scheduleNotification(
      id: 0,
      title: preTitle,
      body: preBody,
      scheduledTime: preAlarmTime,
      canScheduleExact: hasExactAlarmPermission,
    );

    // VOC 시작 알림
    String startTitle = locale.startsWith('ko') ? '보이드 시작' : 'Void of Course Started';
    String startBody = locale.startsWith('ko')
        ? '지금 보이드 시간이 시작되었습니다.'
        : 'The Void of Course period has now begun.';
    await _notificationService.scheduleNotification(
      id: 1,
      title: startTitle,
      body: startBody,
      scheduledTime: _realtimeVocStart!,
      canScheduleExact: hasExactAlarmPermission,
    );

    // VOC 종료 알림
    String endTitle = locale.startsWith('ko') ? '보이드 종료' : 'Void of Course Ended';
    String endBody = locale.startsWith('ko')
        ? '보이드 시간이 종료되었습니다.'
        : 'The Void of Course period has ended.';
    await _notificationService.scheduleNotification(
      id: 2,
      title: endTitle,
      body: endBody,
      scheduledTime: _realtimeVocEnd!,
      canScheduleExact: hasExactAlarmPermission,
    );

    if (kDebugMode) {
      print("Scheduled notifications: Pre-VOC at $preAlarmTime, Start at $_realtimeVocStart, End at $_realtimeVocEnd");
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
      }
    }

    if (_realtimeVocStart != null && _realtimeVocEnd != null) {
      final isCurrentlyInVoc = now.isAfter(_realtimeVocStart!) && now.isBefore(_realtimeVocEnd!);
      _isOngoingNotificationVisible = isCurrentlyInVoc;
      notifyListeners();
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

    _isFollowingTime = isNowFollowingTime;

    if (_isFollowingTime) {
      _selectedDate = now;
    }
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
      } else if (seconds >= 1) {
        notificationBody = '보이드 시작까지 ${seconds}초 남았습니다.';
      } else {
        notificationBody = '보이드가 곧 시작됩니다.';
      }
    } else {
      if (hours > 0) {
        notificationBody = '$hours h $minutes m until Void of Course begins.';
      } else if (minutes > 0) {
        notificationBody = '$minutes minutes until Void of Course begins.';
      } else if (seconds >= 1) {
        notificationBody = '$seconds seconds until Void of Course begins.';
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