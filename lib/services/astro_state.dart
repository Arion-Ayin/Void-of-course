// astro_state.dart

// 비동기(async) 작업을 도와주는 도구들을 가져옵니다.
import 'dart:async';
// Flutter 앱이 웹에서 실행되는지 등을 확인하는 도구들을 가져옵니다.
import 'package:flutter/foundation.dart';
// Flutter의 기본 위젯 관련 도구들을 가져옵니다.
import 'package:flutter/widgets.dart';
// 우리가 만든 '별자리 계산' 파일을 가져옵니다.
import 'astro_calculator.dart';
// 별자리 계산을 위한 특별한 도구(Sweph)를 가져옵니다.
import 'package:sweph/sweph.dart';

// AstroCalculator 인스턴스를 AstroState 클래스 밖으로 이동시킵니다.
// 이렇게 해야 백그라운드 작업(Isolate)에서 이 도구를 사용할 수 있어요.
final AstroCalculator _calculator = AstroCalculator();

// AstroState는 앱의 중요한 데이터(상태)를 관리하고, 변화를 알려주는 역할을 합니다.
// 'with ChangeNotifier'는 데이터가 바뀌었을 때 화면을 새로고침하게 해주는 도구입니다.
class AstroState with ChangeNotifier {
  // 현재 선택된 날짜를 저장하는 변수입니다.
  DateTime _selectedDate = DateTime.now();
  // 달의 위상(모양) 이름을 저장하는 변수입니다.
  String _moonPhase = '';
  // 달이 있는 별자리의 이모티콘을 저장하는 변수입니다.
  String _moonZodiac = '';
  // 달이 있는 별자리의 영어 이름을 저장하는 변수입니다.
  String _moonInSign = '';
  // 보이드 오브 코스 기간의 시작 시간을 저장하는 변수입니다.
  DateTime? _vocStart;
  // 보이드 오브 코스 기간의 종료 시간을 저장하는 변수입니다.
  DateTime? _vocEnd;
  // 다음 별자리로 넘어가는 시간을 저장하는 변수입니다.
  DateTime? _nextSignTime;
  // 계산 중 생긴 오류 메시지를 저장하는 변수입니다.
  String? _lastError;
  // 앱이 처음 준비되었는지 확인하는 변수입니다.
  bool _isInitialized = false;
  // 계산 중인지 확인하는 변수입니다.
  bool _isLoading = false;
  // 현재 어두운 모드인지 확인하는 변수입니다.
  bool _isDarkMode = false;

  // 이전에 계산한 결과를 저장해두는 공간(캐시)입니다.
  final Map<String, Map<String, dynamic>> _cache = {};

  // 'get'은 변수 안의 값을 꺼내 쓰는 역할을 합니다.
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

  // 화면의 색깔(테마)을 어두운 모드와 밝은 모드로 바꿔주는 함수입니다.
  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    // 데이터가 바뀌었다고 화면에게 알려줍니다.
    notifyListeners();
  }

  // 앱의 테마를 특정 값으로 설정하는 함수입니다.
  void setTheme(bool isDark) {
    _isDarkMode = isDark;
    // 데이터가 바뀌었다고 화면에게 알려줍니다.
    notifyListeners();
  }

  // 앱이 처음 시작될 때 필요한 데이터를 준비하는 함수입니다.
  Future<void> initialize() async {
    // 만약 이미 준비되었다면 함수를 끝냅니다.
    if (_isInitialized) return;
    // 데이터를 업데이트합니다.
    await _updateData();
    // 준비가 완료되었다고 표시합니다.
    _isInitialized = true;
    // 데이터가 바뀌었다고 화면에게 알려줍니다.
    notifyListeners();
  }

  // 날짜가 바뀌었을 때 데이터를 새로 가져오는 함수입니다.
  Future<void> updateDate(DateTime newDate) async {
    // 새로운 날짜를 저장합니다.
    _selectedDate = newDate;
    // 데이터를 업데이트합니다.
    await _updateData();
  }

  // 앱의 모든 별자리 데이터를 업데이트하는 핵심 함수입니다.
  Future<void> _updateData() async {
    // 계산 중이라고 표시합니다.
    _isLoading = true;
    // 화면에게 로딩 중이라고 알려줍니다.
    notifyListeners();

    // 현재 날짜를 '2025-08-15' 형식의 이름으로 만듭니다.
    final dateKey = _selectedDate.toIso8601String().substring(0, 10);
    // 만약 캐시에 같은 날짜의 데이터가 있다면,
    if (_cache.containsKey(dateKey)) {
      // 캐시에서 데이터를 가져와서,
      final result = _cache[dateKey]!;
      // 화면을 업데이트합니다.
      _updateStateFromResult(result);
      // 로딩이 끝났다고 표시합니다.
      _isLoading = false;
      // 화면에게 업데이트를 알려주고,
      notifyListeners();
      // 함수를 끝냅니다.
      return;
    }

    // 혹시 오류가 생길 수도 있으니, 일단 시도해봅니다.
    try {
      // 별자리 계산 함수들을 하나씩 호출하여 데이터를 가져옵니다.
      final moonPhase = _calculator.getMoonPhase(_selectedDate);
      final moonZodiac = _calculator.getMoonZodiacEmoji(_selectedDate);
      final moonInSign = _calculator.getMoonZodiacName(_selectedDate);
      final vocTimes = _calculator.findVoidOfCoursePeriod(_selectedDate);
      final moonSignTimes = _calculator.getMoonSignTimes(_selectedDate);

      // 가져온 모든 데이터를 하나의 지도(Map) 형태로 묶습니다.
      final Map<String, dynamic> result = {
        'moonPhase': moonPhase,
        'moonZodiac': moonZodiac,
        'moonInSign': moonInSign,
        'vocStart': vocTimes['start'],
        'vocEnd': vocTimes['end'],
        'nextSignTime': moonSignTimes['end'],
      };

      // 계산된 데이터를 캐시에 저장합니다.
      _cache[dateKey] = result;
      // 화면을 업데이트합니다.
      _updateStateFromResult(result);
      // 오류가 없었으니 오류 변수를 비워둡니다.
      _lastError = null;
    } catch (e, stack) {
      // 계산 중 오류가 생기면,
      // 콘솔에 오류 내용과 위치를 출력합니다.
      print('계산 중 오류 발생: $e\n$stack');
      // 오류 변수에 메시지를 저장합니다.
      _lastError = '계산 중 오류 발생: $e';
    } finally {
      // 계산이 끝났다고 표시합니다.
      _isLoading = false;
      // 마지막으로 화면에게 업데이트를 알려줍니다.
      notifyListeners();
    }
  }

  // 계산된 결과를 화면에 보여주기 위해 변수들을 업데이트하는 함수입니다.
  void _updateStateFromResult(Map<String, dynamic> result) {
    // 계산된 위상 이름을 변수에 저장합니다.
    _moonPhase = result['moonPhase'] as String;
    // 계산된 별자리 이모티콘을 변수에 저장합니다.
    _moonZodiac = result['moonZodiac'] as String;
    // 계산된 별자리 이름을 변수에 저장합니다.
    _moonInSign = result['moonInSign'] as String;
    // 계산된 보이드 시작 시간을 변수에 저장합니다.
    _vocStart = result['vocStart'] as DateTime?;
    // 계산된 보이드 종료 시간을 변수에 저장합니다.
    _vocEnd = result['vocEnd'] as DateTime?;
    // 계산된 다음 별자리 시간을 변수에 저장합니다.
    _nextSignTime = result['nextSignTime'] as DateTime?;
  }
}