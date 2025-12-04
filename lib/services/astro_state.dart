import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'astro_calculator.dart';
import 'notification_service.dart';
import 'package:sweph/sweph.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

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
      _lastError = null;
    } catch (e, stack) {
      print('Initialization error: $e\n$stack');
      _lastError = 'initializationError';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateLocale(String languageCode) async {
    _currentLocale = languageCode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cached_language_code', languageCode);

    if (_voidAlarmEnabled) {
      await _schedulePreVoidAlarm();
    }

    // 언어가 변경되면 알림 메시지도 갱신되어야 하므로 데이터 갱신 (배경 서비스용)
    if (_vocStart != null) {
      // Trigger update to save new locale to prefs if not already done by _schedulePreVoidAlarm
      // But _schedulePreVoidAlarm doesn't save to prefs. _updateStateFromResult does.
      // So let's just save explicitly here or rely on _updateData if called.
      // Actually, _updateData calls _updateStateFromResult.
      // Let's call _updateData to be safe and consistent.
      // But _updateData might be expensive.
      // Let's just ensure prefs are saved.
      // We already saved 'cached_language_code' above.
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

      // 배터리 최적화 제외 요청 (알람이 죽지 않도록)
      await _notificationService.requestBatteryOptimizationPermission();

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

        // Start Background Service
        final service = FlutterBackgroundService();
        await service.startService();

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

      // Stop Background Service
      final service = FlutterBackgroundService();
      service.invoke("stopService");

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
    const int ongoingNotificationId =
        888; // Fixed ID for the active persistent notification

    // Schedule next 10 events
    bool isFirstVocFound = false;
    final prefs = await SharedPreferences.getInstance();

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

      // Found the first valid upcoming VOC! Cache it for the background service.
      if (!isFirstVocFound) {
        isFirstVocFound = true;
        await prefs.setString('cached_voc_start', vocStart.toIso8601String());
        await prefs.setString('cached_voc_end', vocEnd.toIso8601String());
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
          id: notificationId++, // Future alarm -> Unique ID
          title: preTitle,
          body: preBody,
          scheduledTime: preAlarmTime,
          canScheduleExact: hasExactAlarmPermission,
          usesChronometer: true,
          chronometerCountDown: true,
          when: vocStart.millisecondsSinceEpoch,
          isOngoing: true,
          onlyAlertOnce: true,
          isSilent: true,
          timeoutAfter: vocStart.millisecondsSinceEpoch,
        );
      } else if (vocStart.isAfter(now)) {
        // 현재 보이드 시작 전 6시간 이내인 경우 - 즉시 알림 스케줄링 (크로노미터 사용을 위해)
        String preTitle =
            locale.startsWith('ko') ? '보이드 시작 알림' : 'Void of Course Upcoming';
        String preBody =
            locale.startsWith('ko')
                ? '보이드 시작까지 남은 시간:'
                : 'Time until Void of Course begins:';
        await _notificationService.showInstantNotification(
          id: ongoingNotificationId, // Immediate alarm -> Fixed ID (888)
          title: preTitle,
          body: preBody,
          usesChronometer: true,
          chronometerCountDown: true,
          when: vocStart.millisecondsSinceEpoch,
          isOngoing: true,
          onlyAlertOnce: true,
          isSilent: true,
          timeoutAfter: vocStart.millisecondsSinceEpoch,
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
          id: notificationId++, // Future alarm -> Unique ID
          title: startTitle,
          body: startBody,
          scheduledTime: vocStart,
          canScheduleExact: hasExactAlarmPermission,
          usesChronometer: true,
          chronometerCountDown: true,
          when: vocEnd.millisecondsSinceEpoch,
          isOngoing: true,
          onlyAlertOnce: true,
          isSilent: true,
          timeoutAfter: vocEnd.millisecondsSinceEpoch,
        );
      } else if (vocEnd.isAfter(now)) {
        // 현재 보이드 중인 경우 - 즉시 알림 스케줄링
        String startTitle =
            locale.startsWith('ko') ? '보이드 시작' : 'Void of Course Started';
        String startBody =
            locale.startsWith('ko')
                ? '보이드 종료까지 남은 시간:'
                : 'Time until Void of Course ends:';
        await _notificationService.showInstantNotification(
          id: ongoingNotificationId, // Immediate alarm -> Fixed ID (888)
          title: startTitle,
          body: startBody,
          usesChronometer: true,
          chronometerCountDown: true,
          when: vocEnd.millisecondsSinceEpoch,
          isOngoing: true,
          onlyAlertOnce: true,
          isSilent: true,
          timeoutAfter: vocEnd.millisecondsSinceEpoch,
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
          isSilent: true,
        );
      }

      // Prepare for next iteration
      searchDate = vocEnd.add(const Duration(minutes: 1));
    }

    if (kDebugMode) {
      print("Scheduled notifications for next 10 VOC periods.");
    }

    notifyListeners();
  }

  void _scheduleNextUpdate() {
    _timer?.cancel();

    // We only schedule updates if the app is following the current time.
    if (!_isFollowingTime) {
      return;
    }

    // Determine the soonest event time that is in the future.
    final now = DateTime.now();
    DateTime? nextEvent;

    final signTime = _nextSignTime;
    final phaseTime = _nextMoonPhaseTime;
    final vocStart = _vocStart;
    final vocEnd = _vocEnd;

    if (signTime != null && signTime.isAfter(now)) {
      nextEvent = signTime;
    }
    if (phaseTime != null && phaseTime.isAfter(now)) {
      if (nextEvent == null || phaseTime.isBefore(nextEvent)) {
        nextEvent = phaseTime;
      }
    }
    if (vocStart != null && vocStart.isAfter(now)) {
      if (nextEvent == null || vocStart.isBefore(nextEvent)) {
        nextEvent = vocStart;
      }
    }
    if (vocEnd != null && vocEnd.isAfter(now)) {
      if (nextEvent == null || vocEnd.isBefore(nextEvent)) {
        nextEvent = vocEnd;
      }
    }

    if (nextEvent != null) {
      // We have a future event. Schedule a timer to fire just after it.
      final duration = nextEvent.difference(now) + const Duration(seconds: 1);

      if (kDebugMode) {
        print('Scheduling next UI update in $duration for event at $nextEvent');
      }

      _timer = Timer(duration, () {
        if (kDebugMode) {
          print('Timer fired for UI update. Refreshing data...');
        }

        // If we are still following time, refresh the data.
        if (_isFollowingTime) {
          _selectedDate = DateTime.now();
          refreshData(); // This will re-calculate event times and re-schedule the next update via _updateStateFromResult

          // Also reschedule alarms if they are enabled.
          if (_voidAlarmEnabled) {
            _schedulePreVoidAlarm();
          }
        }
      });
    } else {
      if (kDebugMode) {
        print('No future events found to schedule an update for.');
      }
    }
  }

  Future<void> updateDate(DateTime newDate) async {
    final now = DateTime.now();
    final bool isSameDay =
        newDate.year == now.year &&
        newDate.month == now.month &&
        newDate.day == now.day;

    if (isSameDay) {
      _selectedDate = now;
      _isFollowingTime = true;
    } else {
      _selectedDate = DateTime(newDate.year, newDate.month, newDate.day);
      _isFollowingTime = false;
    }
    await refreshData();
  }

  Future<void> refreshData() async {
    final now = DateTime.now();

    // On refresh, if we are in follow mode, snap back to the current time.
    if (_isFollowingTime) {
      _isFollowingTime = true;
      _selectedDate = now;
    }

    await _updateData();
  }

  Future<void> _updateData() async {
    _isLoading = true;
    notifyListeners();

    final dateForCalc = _selectedDate;

    try {
      final nextPhaseInfo = _calculator.findNextPhase(dateForCalc);
      final moonPhaseInfo = _calculator.getMoonPhaseInfo(dateForCalc);
      final moonPhase = moonPhaseInfo['phaseName'] ?? '';
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
    _moonPhase = result['moonPhase'] as String? ?? '';
    _moonZodiac = result['moonZodiac'] as String;
    _moonInSign = result['moonInSign'] as String;
    _vocStart = result['vocStart'] as DateTime?;
    _vocEnd = result['vocEnd'] as DateTime?;
    _vocPlanet = result['vocPlanet'] as String?;
    _vocAspect = result['vocAspect'] as String?;
    _nextSignTime = result['nextSignTime'] as DateTime?;
    _nextMoonPhaseName = result['nextMoonPhaseName'] as String;
    _nextMoonPhaseTime = result['nextMoonPhaseTime'] as DateTime?;

    // Cache VOC times and settings for background service
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('cached_pre_void_hours', _preVoidAlarmHours);
    await prefs.setString('cached_language_code', _currentLocale);

    // NOTE: We do NOT cache vocStart/vocEnd here anymore.
    // This method is called when UI updates (e.g. user changes date),
    // but we want the background service to ALWAYS track the *actual next* VOC,
    // which is calculated in _schedulePreVoidAlarm.
    _scheduleNextUpdate();
  }
}
