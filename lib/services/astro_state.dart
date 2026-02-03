import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'astro_calculator.dart';
import 'notification_service.dart';
import 'alarm_service.dart';
import 'package:sweph/sweph.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

final AstroCalculator _calculator = AstroCalculator();

enum AlarmPermissionStatus { granted, notificationDenied, exactAlarmDenied }

class AstroState with ChangeNotifier {
  Timer? _timer;
  final NotificationService _notificationService = NotificationService();
  final AlarmService _alarmService = AlarmService();
  SharedPreferences? _prefs; // 캐시된 SharedPreferences 인스턴스
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
  DateTime? _currentSignStartTime;
  String? _lastError;
  bool _isInitialized = false;
  bool _isLoading = false;
  bool _isDarkMode = false;
  String _nextMoonPhaseName = 'calculating';
  DateTime? _nextMoonPhaseTime;
  DateTime? _moonPhaseStartTime;
  DateTime? _moonPhaseEndTime;
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
  DateTime? get currentSignStartTime => _currentSignStartTime;
  String? get lastError => _lastError;
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  bool get isDarkMode => _isDarkMode;
  bool get voidAlarmEnabled => _voidAlarmEnabled;
  int get preVoidAlarmHours => _preVoidAlarmHours;
  String get nextMoonPhaseName => _nextMoonPhaseName;
  DateTime? get nextMoonPhaseTime => _nextMoonPhaseTime;
  DateTime? get moonPhaseStartTime => _moonPhaseStartTime;
  DateTime? get moonPhaseEndTime => _moonPhaseEndTime;
  bool get isFollowingTime => _isFollowingTime;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  void setTheme(bool isDark) {
    _isDarkMode = isDark;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timer = null;
    super.dispose();
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
      //스위프 초기화
      //천문학 라이브러리 초기화
      await Sweph.init();
      //현재 로케일 설정
      _currentLocale = Intl.getCurrentLocale();
      //알림 서비스 초기화
      await _notificationService.init();
      //알람 매니저 초기화 (앱 종료 후에도 백그라운드 서비스 시작 가능)
      await _alarmService.init();
      //shared preferences 초기화 (캐싱)
      _prefs = await SharedPreferences.getInstance();
      //void alarm enabled 상태 저장
      _voidAlarmEnabled = _prefs!.getBool('voidAlarmEnabled') ?? false;
      _preVoidAlarmHours = _prefs!.getInt('preVoidAlarmHours') ?? 6;

      await _updateData();

      // 알람이 활성화되어 있으면 예약 알림 설정 (앱 재시작 시에도 동작)
      // 단, 서비스가 이미 실행 중이면 다시 스케줄링하지 않음 (중복 알림 방지)
      if (_voidAlarmEnabled) {
        final service = FlutterBackgroundService();
        final isRunning = await service.isRunning();
        if (!isRunning) {
          await _schedulePreVoidAlarm();
        }
      }

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

  //
  Future<void> updateLocale(String languageCode) async {
    _currentLocale = languageCode;
    await _prefs?.setString('cached_language_code', languageCode);

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
        await _prefs?.setBool('voidAlarmEnabled', true);
        // _schedulePreVoidAlarm에서 pre-void 시작 여부에 따라 서비스 시작 결정
        await _schedulePreVoidAlarm(isToggleOn: true);

        notifyListeners();
        return AlarmPermissionStatus.granted;
      } else {
        _voidAlarmEnabled = false;
        await _prefs?.setBool('voidAlarmEnabled', false);
        notifyListeners();
        return AlarmPermissionStatus.exactAlarmDenied;
      }
    } else {
      _voidAlarmEnabled = false;
      await _prefs?.setBool('voidAlarmEnabled', false);
      await _notificationService.cancelAllNotifications();
      await _alarmService.cancelAlarm();

      // Stop Background Service
      final service = FlutterBackgroundService();
      service.invoke("stopService");

      notifyListeners();
      return AlarmPermissionStatus.granted;
    }
  }

  Future<void> setPreVoidAlarmHours(int hours) async {
    _preVoidAlarmHours = hours;
    await _prefs?.setInt('preVoidAlarmHours', hours);
    await _schedulePreVoidAlarm(isToggleOn: false);
    notifyListeners();
  }

  Future<void> _schedulePreVoidAlarm({bool isToggleOn = false}) async {
    // 기존 예약된 알림들 병렬로 취소 (1000~1100번)
    await Future.wait([
      for (int i = 0; i < 100; i++)
        _notificationService.cancelNotification(1000 + i),
      _alarmService.cancelAlarm(), // AlarmManager 알람도 함께 취소
    ]);

    if (!_voidAlarmEnabled) {
      notifyListeners();
      return;
    }

    final now = DateTime.now();
    DateTime searchDate = now;

    // 백그라운드 서비스용 pre-void 시간 동기화
    await _prefs?.setInt('cached_pre_void_hours', _preVoidAlarmHours);

    DateTime? foundVocStart;
    DateTime? foundVocEnd;

    for (int i = 0; i < 10; i++) {
      final vocTimes = _calculator.findVoidOfCoursePeriod(searchDate);
      final vocStart = vocTimes['start'];
      final vocEnd = vocTimes['end'];

      if (vocStart == null || vocEnd == null) {
        searchDate = searchDate.add(const Duration(days: 1));
        continue;
      }

      // 이미 지난 VOC는 스킵
      if (vocEnd.isBefore(now)) {
        searchDate = vocEnd.add(const Duration(minutes: 1));
        continue;
      }

      // 첫 번째 유효한 VOC를 백그라운드 서비스용으로 캐시
      await _prefs?.setString('cached_voc_start', vocStart.toIso8601String());
      await _prefs?.setString('cached_voc_end', vocEnd.toIso8601String());

      foundVocStart = vocStart;
      foundVocEnd = vocEnd;

      if (kDebugMode) {
        print("Cached VOC: start=$vocStart, end=$vocEnd");
      }

      break; // 첫 번째 유효한 VOC만 캐시하면 됨
    }

    // 백그라운드 서비스는 pre-void 시작 이후에만 필요
    // pre-void 시작 전이면 서비스를 시작하지 않음 (빈 알림 방지)
    final service = FlutterBackgroundService();
    final isRunning = await service.isRunning();

    if (foundVocStart != null && foundVocEnd != null) {
      final preVoidStart = foundVocStart.subtract(Duration(hours: _preVoidAlarmHours));
      final shouldServiceRun = now.isAfter(preVoidStart) || now.isAtSameMomentAs(preVoidStart);

      if (shouldServiceRun && !isRunning && _voidAlarmEnabled) {
        // pre-void 이상이면 서비스 시작
        await service.startService();
        if (kDebugMode) {
          print("Background service started for VOC monitoring (pre-void active)");
        }
      } else if (!shouldServiceRun && isRunning) {
        // pre-void 전인데 서비스가 실행 중이면 종료
        service.invoke("stopService");
        if (kDebugMode) {
          print("Background service stopped (pre-void not yet started)");
        }
      }

      // 앱이 꺼져있어도 백그라운드 서비스가 시작되도록 AlarmManager로 예약
      // pre-void 시작 시점에 알람 예약 (아직 시작 전일 때만)
      if (preVoidStart.isAfter(now)) {
        // AlarmManager로 백그라운드 서비스 자동 시작 예약
        await _alarmService.schedulePreVoidAlarm(preVoidStart);

        if (kDebugMode) {
          print("Scheduled AlarmManager for pre-void at: $preVoidStart");
        }
      } else {
        // 이미 pre-void가 시작되었으면 알람 취소
        await _alarmService.cancelAlarm();
      }
    } else if (isRunning) {
      // VOC 데이터가 없으면 서비스 종료
      service.invoke("stopService");
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

  //실제 계산 시작
  Future<void> _updateData() async {
    _isLoading = true;
    notifyListeners();

    final dateForCalc = _selectedDate;

    //카큘레이터에서 가져와서 계산 시작
    try {
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
      
      final moonPhaseTimes = _calculator.getMoonPhaseTimes(dateForCalc);
      
      // Extract next phase info from moonPhaseTimes to avoid duplicate calculation
      final nextMoonPhaseName = _calculator.findNextPhase(dateForCalc)['name'] ?? 'N/A';

      if (kDebugMode) {
        print('[DEBUG] moonPhaseInfo: $moonPhaseInfo');
        print('[DEBUG] moonZodiac: $moonZodiac');
        print('[DEBUG] moonInSign (Name): $moonSignName');
        print('[DEBUG] vocTimes: $vocTimes');
        print('[DEBUG] moonSignTimes: $moonSignTimes');
        print('[DEBUG] moonPhaseTimes: $moonPhaseTimes');
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
        'currentSignStartTime': moonSignTimes['start'],
        'nextMoonPhaseName': nextMoonPhaseName,
        'nextMoonPhaseTime': moonPhaseTimes['end'],
        'moonPhaseStartTime': moonPhaseTimes['start'],
        'moonPhaseEndTime': moonPhaseTimes['end'],
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

  // 계산된 결과를 -> 메모리에 저장하고
  Future<void> _updateStateFromResult(Map<String, dynamic> result) async {
    _moonPhase = result['moonPhase'] as String? ?? '';
    // 수정: null일 경우 빈 문자열로 처리하여 오류 방지
    _moonZodiac = result['moonZodiac'] as String? ?? '';
    _moonInSign = result['moonInSign'] as String? ?? '';
    _vocStart = result['vocStart'] as DateTime?;
    _vocEnd = result['vocEnd'] as DateTime?;
    _vocPlanet = result['vocPlanet'] as String?;
    _vocAspect = result['vocAspect'] as String?;
    _nextSignTime = result['nextSignTime'] as DateTime?;
    _currentSignStartTime = result['currentSignStartTime'] as DateTime?;
    _nextMoonPhaseName = result['nextMoonPhaseName'] as String? ?? '';
    _nextMoonPhaseTime = result['nextMoonPhaseTime'] as DateTime?;
    _moonPhaseStartTime = result['moonPhaseStartTime'] as DateTime?;
    _moonPhaseEndTime = result['moonPhaseEndTime'] as DateTime?;

    // Cache VOC times and settings for background service
    await _prefs?.setInt('cached_pre_void_hours', _preVoidAlarmHours);

    // 수정: _currentLocale이 초기화되지 않았을 경우를 대비해 예외 처리
    try {
      await _prefs?.setString('cached_language_code', _currentLocale);
    } catch (_) {
      // 초기화 전이라면 무시하거나 기본값 사용
    }

    // ... (나머지 코드는 동일)
    _scheduleNextUpdate();
  }
}
