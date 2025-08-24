// dart:async 라이브러리를 가져와서 사용해요. 이 라이브러리는 비동기 프로그래밍(시간이 걸리는 작업을 처리할 때)에 도움을 줘요.
import 'dart:async';
// 플러터 프레임워크의 foundation 라이브러리를 가져와요. 앱의 기본적인 기능을 만드는 데 필요해요.
import 'package:flutter/foundation.dart';
// 플러터 프레임워크의 widgets 라이브러리를 가져와요. 화면에 보이는 버튼이나 글자 같은 것들을 만들 때 필요해요.
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
// 우리가 만든 astro_calculator.dart 파일을 가져와서 사용해요. 여기에는 천문학 계산 기능이 들어있어요.
import 'astro_calculator.dart';
import 'notification_service.dart';
// sweph라는 외부 라이브러리를 가져와요. 천문 현상을 계산할 때 사용하는 전문적인 도구예요.
import 'package:sweph/sweph.dart';

// AstroCalculator라는 계산기를 하나 만들어서 _calculator라는 이름의 상자에 넣어둬요. final은 한 번 넣으면 바꿀 수 없다는 뜻이에요.
final AstroCalculator _calculator = AstroCalculator();

// AstroState 클래스는 앱의 중요한 정보들을 가지고 있고, 정보가 바뀔 때 화면에 알려주는 역할을 해요.
// with ChangeNotifier는 이 클래스가 변화를 알려줄 수 있는 능력을 가졌다는 뜻이에요.
class AstroState with ChangeNotifier {
  // 실시간 업데이트를 위한 타이머 변수예요.
  Timer? _timer;

  // 알람 서비스를 사용하기 위한 변수예요.
  final NotificationService _notificationService = NotificationService();
  // 보이드 알람이 켜져 있는지 상태를 저장하는 변수예요.
  bool _voidAlarmEnabled = false;
  // 현재 지속 알람이 화면에 보이는지 상태를 저장하는 변수예요.
  bool _isOngoingNotificationVisible = false;

  // 사용자가 선택한 날짜를 저장하는 상자예요. 처음에는 지금 현재 날짜와 시간으로 정해져요.
  DateTime _selectedDate = DateTime.now();
  // 달의 모양(예: 보름달)을 글자로 저장하는 상자예요. 처음에는 비어있어요.
  String _moonPhase = '';
  // 달이 위치한 별자리를 글자로 저장하는 상자예요. 처음에는 비어있어요.
  String _moonZodiac = '';
  // 달이 어떤 별자리에 들어가는지를 글자로 저장하는 상자예요. 처음에는 비어있어요.
  String _moonInSign = '';
  // 보이드 오브 코스(달이 다음 별자리로 넘어가기 전 잠시 쉬는 시간)가 시작되는 시간을 저장하는 상자예요. 시간이 없을 수도 있어서 물음표(?)가 붙어있어요.
  DateTime? _vocStart;
  // 보이드 오브 코스가 끝나는 시간을 저장하는 상자예요. 시간이 없을 수도 있어서 물음표(?)가 붙어있어요.
  DateTime? _vocEnd;
  // 달이 다음 별자리로 들어가는 시간을 저장하는 상자예요. 시간이 없을 수도 있어서 물음표(?)가 붙어있어요.
  DateTime? _nextSignTime;
  // 만약에 앱에 문제가 생기면, 어떤 문제인지 알려주는 글자를 저장하는 상자예요. 문제가 없을 수도 있어서 물음표(?)가 붙어있어요.
  String? _lastError;
  // 앱이 처음 시작할 때 필요한 준비를 마쳤는지 알려주는 상자예요. 처음에는 '아니요(false)'로 되어 있어요.
  bool _isInitialized = false;
  // 지금 무언가 데이터를 불러오는 중인지 알려주는 상자예요. 처음에는 '아니요(false)'로 되어 있어요.
  bool _isLoading = false;
  // 앱의 화면이 어두운 모드인지 알려주는 상자예요. 처음에는 '아니요(false)'로 되어 있어요.
  bool _isDarkMode = false;
  
  // 다음 달의 위상(모양) 정보를 위한 새로운 변수들이에요.
  // 다음에 올 달의 모양 이름을 저장하는 상자예요. 처음에는 '계산 중...'이라고 보여줘요.
  String _nextMoonPhaseName = 'Calculating...';
  // 다음에 올 달의 모양이 나타나는 시간을 저장하는 상자예요. 시간이 없을 수도 있어서 물음표(?)가 붙어있어요.
  DateTime? _nextMoonPhaseTime;

  // 한 번 계산한 결과를 저장해두는 상자(지도)예요. 이렇게 하면 똑같은 계산을 또 하지 않아서 앱이 빨라져요.
  final Map<String, Map<String, dynamic>> _cache = {};

  // 다른 파일에서 _selectedDate 값을 읽을 수 있게 해주는 문이에요.
  DateTime get selectedDate => _selectedDate;
  // 다른 파일에서 _moonPhase 값을 읽을 수 있게 해주는 문이에요.
  String get moonPhase => _moonPhase;
  // 다른 파일에서 _moonZodiac 값을 읽을 수 있게 해주는 문이에요.
  String get moonZodiac => _moonZodiac;
  // 다른 파일에서 _moonInSign 값을 읽을 수 있게 해주는 문이에요.
  String get moonInSign => _moonInSign;
  // 다른 파일에서 _vocStart 값을 읽을 수 있게 해주는 문이에요.
  DateTime? get vocStart => _vocStart;
  // 다른 파일에서 _vocEnd 값을 읽을 수 있게 해주는 문이에요.
  DateTime? get vocEnd => _vocEnd;
  // 다른 파일에서 _nextSignTime 값을 읽을 수 있게 해주는 문이에요.
  DateTime? get nextSignTime => _nextSignTime;
  // 다른 파일에서 _lastError 값을 읽을 수 있게 해주는 문이에요.
  String? get lastError => _lastError;
  // 다른 파일에서 _isInitialized 값을 읽을 수 있게 해주는 문이에요.
  bool get isInitialized => _isInitialized;
  // 다른 파일에서 _isLoading 값을 읽을 수 있게 해주는 문이에요.
  bool get isLoading => _isLoading;
  // 다른 파일에서 _isDarkMode 값을 읽을 수 있게 해주는 문이에요.
  bool get isDarkMode => _isDarkMode;
  // 다른 파일에서 보이드 알람 설정 상태를 읽을 수 있게 해주는 문이에요.
  bool get voidAlarmEnabled => _voidAlarmEnabled;

  // 다음 달의 위상 정보를 다른 파일에서 읽을 수 있게 해주는 문들이에요.
  String get nextMoonPhaseName => _nextMoonPhaseName;
  DateTime? get nextMoonPhaseTime => _nextMoonPhaseTime;

  // 화면 테마를 바꾸는 일을 하는 함수(기능)예요.
  void toggleTheme() {
    // _isDarkMode 값을 반대로 바꿔요. (참 -> 거짓, 거짓 -> 참)
    _isDarkMode = !_isDarkMode;
    // 화면에 "나 바뀌었어!"라고 알려줘서 화면을 새로 그리게 해요.
    notifyListeners();
  }

  // 화면 테마를 정해주는 일을 하는 함수예요. isDark가 참이면 어두운 모드, 거짓이면 밝은 모드로 설정돼요.
  void setTheme(bool isDark) {
    // _isDarkMode 값을 isDark 값으로 정해요.
    _isDarkMode = isDark;
    // 화면에 "나 바뀌었어!"라고 알려줘서 화면을 새로 그리게 해요.
    notifyListeners();
  }

  // 앱을 처음 시작할 때 한 번만 실행되는 준비 작업을 하는 함수예요. Future는 시간이 좀 걸리는 작업이라는 뜻이에요.
  Future<void> initialize() async {
    // 만약에(_isInitialized가 참이라면) 이미 준비가 끝났으면,
    if (_isInitialized) return; // 여기서 함수를 끝내고 더 이상 진행하지 않아요.
    
    // 지금 로딩 중이라고 상태를 바꿔요.
    _isLoading = true;
    // 화면에 "나 바뀌었어!"라고 알려줘서 로딩 중인 화면을 보여주게 해요.
    notifyListeners();

    // try는 "일단 시도해봐"라는 뜻이에요. 혹시 문제가 생길 수도 있는 코드를 여기에 넣어요.
    try {
      // Sweph 라이브러리를 준비시키는 과정이에요.
      await Sweph.init();
      // 알람 서비스를 준비시켜요.
      await _notificationService.init();
      // 저장된 알람 설정을 불러와요.
      final prefs = await SharedPreferences.getInstance();
      _voidAlarmEnabled = prefs.getBool('voidAlarmEnabled') ?? false;

      // 화면에 보여줄 데이터를 처음으로 불러오는 작업을 해요.
      await _updateData();
      // 이제 준비가 끝났다고 상태를 바꿔요.
      _isInitialized = true;
      // 실시간 업데이트 타이머를 시작해요.
      _startTimer();
      // 혹시 이전에 오류가 있었다면, 이제 없애줘요.
      _lastError = null;

    // catch는 "만약에 문제가 생기면 이렇게 해"라는 뜻이에요. e는 어떤 문제가 생겼는지 알려주는 정보예요.
    } catch (e, stack) {
      // 컴퓨터 개발자만 볼 수 있는 창에 어떤 오류가 났는지 자세히 보여줘요.
      print('Initialization error: $e\n$stack');
      // 화면에 보여줄 오류 메시지를 만들어서 저장해요.
      _lastError = '초기화 오류: $e';
    // finally는 "위에 모든 작업이 끝나면(성공하든 실패하든) 반드시 실행해"라는 뜻이에요.
    } finally {
      // 로딩이 끝났다고 상태를 바꿔요.
      _isLoading = false;
      // 화면에 "나 바뀌었어!"라고 알려줘서 로딩 화면을 없애고 원래 화면을 보여주게 해요.
      notifyListeners();
    }
  }

  // 보이드 알람 설정을 켜고 끄는 함수예요.
  Future<void> toggleVoidAlarm(bool enable) async {
    if (enable) {
      // 알람을 켜는 경우, 사용자에게 권한을 요청해요.
      final bool hasPermission = await _notificationService.requestPermissions();
      if (hasPermission) {
        _voidAlarmEnabled = true;
        // 알람 예약을 시작해요.
        _scheduleVoidNotifications();
      } else {
        // 사용자가 권한을 거부하면 스위치를 꺼진 상태로 둬요.
        _voidAlarmEnabled = false;
      }
    } else {
      // 알람을 끄는 경우, 모든 알람 예약을 취소해요.
      _voidAlarmEnabled = false;
      _notificationService.cancelAllNotifications();
    }
    // 설정을 기기에 저장해요.
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('voidAlarmEnabled', _voidAlarmEnabled);
    // 화면에 변경사항을 알려요.
    notifyListeners();
  }

  // 보이드 알람을 예약하는 함수예요.
  void _scheduleVoidNotifications() {
    // 이전에 예약된 알람을 모두 취소해요.
    _notificationService.cancelAllNotifications();
    // 알람 설정이 꺼져있으면 아무것도 하지 않아요.
    if (!_voidAlarmEnabled) return;

    // 보이드 시작 시간이 있고, 아직 지나지 않았다면 알람을 예약해요.
    if (_vocStart != null && _vocStart!.isAfter(DateTime.now())) {
      // 보이드 시작 1시간 전 알람
      final oneHourBefore = _vocStart!.subtract(const Duration(hours: 1));
      _notificationService.scheduleNotification(
        id: 0,
        title: '보이드 알람',
        body: '1시간 후에 보이드를 시작합니다.',
        scheduledTime: oneHourBefore,
      );
    }
  }

  // 1초마다 실행되는 타이머를 설정하는 함수예요.
  void _startTimer() {
    // 이미 타이머가 실행 중이면 또 만들지 않아요.
    _timer?.cancel();
    // 1초마다 _checkTime 함수를 실행하는 타이머를 만들어요.
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _checkTime();
    });
  }

  // 시간이 지났는지 확인하고 필요하면 데이터를 업데이트하거나 알람을 관리하는 함수예요.
  void _checkTime() {
    final now = DateTime.now();
    // 사용자가 오늘 날짜를 보고 있는지 확인해요.
    final isToday = now.year == _selectedDate.year &&
        now.month == _selectedDate.month &&
        now.day == _selectedDate.day;

    // 데이터 자동 새로고침 로직
    if (isToday && _vocEnd != null && now.isAfter(_vocEnd!)) {
      if (kDebugMode) {
        print("Void of course ended. Refreshing data...");
      }
      // 현재 시간으로 데이터를 새로고침해요.
      updateDate(now);
    }

    // 보이드 알람 로직
    if (_voidAlarmEnabled) {
      final start = _vocStart;
      final end = _vocEnd;

      if (start != null && end != null) {
        // 현재 시간이 보이드 기간 안이고, 지속 알람이 아직 보이지 않는다면
        if (now.isAfter(start) && now.isBefore(end) && !_isOngoingNotificationVisible) {
          _notificationService.showOngoingNotification(
            id: 1,
            title: '보이드 중',
            body: '현재 보이드 오브 코스 기간입니다.',
          );
          _isOngoingNotificationVisible = true;
          if (kDebugMode) print("Showing ongoing notification.");
        } 
        // 현재 시간이 보이드 기간을 지났고, 지속 알람이 보이고 있다면
        else if (now.isAfter(end) && _isOngoingNotificationVisible) {
          _notificationService.cancelNotification(1);
          _isOngoingNotificationVisible = false;
          if (kDebugMode) print("Cancelling ongoing notification.");
        }
      }
    }
  }

  // 이 클래스가 화면에서 사라질 때 타이머를 멈추게 하는 함수예요.
    void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // 사용자가 날짜를 바꾸면, 그 날짜에 맞는 정보로 업데이트하는 함수예요.
  Future<void> updateDate(DateTime newDate) async {
    // 사용자가 선택한 날짜를 새로 받은 날짜(newDate)로 바꿔요.
    _selectedDate = newDate;
    // 바뀐 날짜에 맞는 새로운 데이터를 불러와요.
    await _updateData();
  }

  // 데이터를 새로고침하고 싶을 때 사용하는 함수예요.
  Future<void> refreshData() async {
    // 저장해뒀던 계산 결과(캐시)를 모두 지워요.
    _cache.clear();
    // 데이터를 처음부터 다시 불러와요.
    await _updateData();
  }

  // 실제로 데이터를 계산하고 업데이트하는 중요한 일을 하는 함수예요.
  Future<void> _updateData() async {
    // 지금 로딩 중이라고 상태를 바꿔요.
    _isLoading = true;
    // 화면에 "나 바뀌었어!"라고 알려줘서 로딩 중인 화면을 보여주게 해요.
    notifyListeners();

    // 선택된 날짜의 자정(0시 0분)을 기준으로 고유 키를 만들어요.
    // 이렇게 하면 시간과 관계없이 같은 날짜는 같은 캐시를 사용해요.
    final dayStart = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    final dateKey = dayStart.toIso8601String();

    // 만약에(_cache에 dateKey와 똑같은 이름표가 있다면) 이미 계산한 적이 있다면,
    if (_cache.containsKey(dateKey)) {
      // 저장해뒀던 계산 결과를 result 상자에 꺼내와요.
      final result = _cache[dateKey]!;
      // 만약에(kDebugMode가 참이라면) 지금이 개발 중인 상태라면,
      if (kDebugMode) {
        // 컴퓨터 개발자만 볼 수 있는 창에 캐시 데이터를 사용한다고 알려줘요.
        print('Using cached data for $dateKey: $result');
      }
      // 저장된 결과로 화면에 보여줄 정보들을 바꿔요.
      _updateStateFromResult(result);
      // 로딩이 끝났다고 상태를 바꿔요.
      _isLoading = false;
      // 화면에 "나 바뀌었어!"라고 알려줘요.
      notifyListeners();
      // 여기서 함수를 끝내고 더 이상 진행하지 않아요.
      return;
    }

    // try는 "일단 시도해봐"라는 뜻이에요. 계산하다가 문제가 생길 수도 있으니까요.
    try {
      // _calculator에게 다음 주요 달의 위상(모양) 정보를 찾아달라고 부탁해요.
      final nextPhaseInfo = _calculator.findNextPrimaryPhase();
      // 결과로 받은 정보에서 'name'이라는 이름표가 붙은 값을 _nextMoonPhaseName에 저장해요. 만약 값이 없으면 'N/A'라고 저장해요.
      _nextMoonPhaseName = nextPhaseInfo['name'] ?? 'N/A';
      // 결과로 받은 정보에서 'time'이라는 이름표가 붙은 값을 _nextMoonPhaseTime에 저장해요.
      _nextMoonPhaseTime = nextPhaseInfo['time'];

      // 모든 계산은 시간 정보를 제외한 'dayStart'를 기준으로 수행해요.
      // 이렇게 하면 하루 동안 표시되는 정보가 일관성 있게 유지돼요.
      final moonPhaseInfo = _calculator.getMoonPhaseInfo(dayStart);
      // 계산 결과에서 'phaseName'이라는 이름표가 붙은 값을 moonPhase 상자에 저장해요.
      final moonPhase = moonPhaseInfo['phaseName'];
      // _calculator에게 선택된 날짜의 달 별자리 이모티콘(그림글자)을 계산해달라고 부탁해요.
      final moonZodiac = _calculator.getMoonZodiacEmoji(dayStart);
      // _calculator에게 선택된 날짜의 달 별자리 이름을 계산해달라고 부탁해요.
      final moonInSign = _calculator.getMoonZodiacName(dayStart);
      // _calculator에게 선택된 날짜의 보이드 오브 코스 시간을 찾아달라고 부탁해요.
      final vocTimes = _calculator.findVoidOfCoursePeriod(dayStart);
      // _calculator에게 선택된 날짜의 달이 별자리에 머무는 시간을 계산해달라고 부탁해요.
      final moonSignTimes = _calculator.getMoonSignTimes(dayStart);

      // 위에서 계산한 모든 결과들을 'result'라는 이름의 지도(Map)에 정리해서 담아둬요.
      final Map<String, dynamic> result = {
        'moonPhase': moonPhase,
        'moonZodiac': moonZodiac,
        'moonInSign': moonInSign,
        'vocStart': vocTimes['start'],
        'vocEnd': vocTimes['end'],
        'nextSignTime': moonSignTimes['end'],
      };

      // 만약에(kDebugMode가 참이라면) 지금이 개발 중인 상태라면,
      if (kDebugMode) {
        // 컴퓨터 개발자만 볼 수 있는 창에 새로 계산한 데이터를 보여줘요.
        print('Calculated data for $dateKey: $result');
      }
      // 새로 계산한 결과를 나중에 또 쓸 수 있도록 _cache에 저장해요.
      _cache[dateKey] = result;
      // 계산된 결과로 화면에 보여줄 정보들을 바꿔요.
      _updateStateFromResult(result);
      // 혹시 이전에 오류가 있었다면, 이제 없애줘요.
      _lastError = null;
    // catch는 "만약에 계산하다가 문제가 생기면 이렇게 해"라는 뜻이에요.
    } catch (e, stack) {
      // 만약에(kDebugMode가 참이라면) 지금이 개발 중인 상태라면,
      if (kDebugMode) {
        // 컴퓨터 개발자만 볼 수 있는 창에 어떤 오류가 났는지 자세히 보여줘요.
        print('계산 중 오류 발생: $e\n$stack');
      }
      // 화면에 보여줄 오류 메시지를 만들어서 저장해요.
      _lastError = '계산 중 오류 발생: $e';
    // finally는 "위에 모든 작업이 끝나면(성공하든 실패하든) 반드시 실행해"라는 뜻이에요.
    } finally {
      // 로딩이 끝났다고 상태를 바꿔요.
      _isLoading = false;
      // 화면에 "나 바뀌었어!"라고 알려줘요.
      notifyListeners();
    }
  }

  // 계산 결과를 받아서 앱의 상태(정보)를 업데이트하는 함수예요.
  void _updateStateFromResult(Map<String, dynamic> result) {
    // 결과 지도(result)에서 'moonPhase' 이름표를 가진 값을 꺼내 _moonPhase 상자에 저장해요.
    _moonPhase = result['moonPhase'] as String;
    // 결과 지도(result)에서 'moonZodiac' 이름표를 가진 값을 꺼내 _moonZodiac 상자에 저장해요.
    _moonZodiac = result['moonZodiac'] as String;
    // 결과 지도(result)에서 'moonInSign' 이름표를 가진 값을 꺼내 _moonInSign 상자에 저장해요.
    _moonInSign = result['moonInSign'] as String;
    // 결과 지도(result)에서 'vocStart' 이름표를 가진 값을 꺼내 _vocStart 상자에 저장해요.
    _vocStart = result['vocStart'] as DateTime?;
    // 결과 지도(result)에서 'vocEnd' 이름표를 가진 값을 꺼내 _vocEnd 상자에 저장해요.
    _vocEnd = result['vocEnd'] as DateTime?;
    // 결과 지도(result)에서 'nextSignTime' 이름표를 가진 값을 꺼내 _nextSignTime 상자에 저장해요.
    _nextSignTime = result['nextSignTime'] as DateTime?;

    // 데이터가 업데이트될 때마다 알람 예약을 다시 설정해요.
    _scheduleVoidNotifications();
  }
}