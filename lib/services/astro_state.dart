import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'astro_calculator.dart';
import 'package:sweph/sweph.dart';

final AstroCalculator _calculator = AstroCalculator();

class AstroState with ChangeNotifier {
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
  
  // 다음 위상 정보를 위한 새로운 변수들
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

  // 다음 위상 정보를 가져오는 getter
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
      // Sweph 라이브러리 초기화
      await Sweph.init();

      // UI에 표시될 초기 데이터를 로드
      await _updateData();
      _isInitialized = true;
      _lastError = null;

    } catch (e, stack) {
      print('Initialization error: $e\n$stack');
      _lastError = '초기화 오류: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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

    final dateKey = _selectedDate.toIso8601String();
    if (_cache.containsKey(dateKey)) {
      final result = _cache[dateKey]!;
      if (kDebugMode) {
        print('Using cached data for $dateKey: $result');
      }
      _updateStateFromResult(result);
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      // 이제 `_calculator.findNextPrimaryPhase()`는 매개변수가 필요 없습니다.
      final nextPhaseInfo = _calculator.findNextPrimaryPhase();
      _nextMoonPhaseName = nextPhaseInfo['name'] ?? 'N/A';
      _nextMoonPhaseTime = nextPhaseInfo['time'];

      final moonPhaseInfo = _calculator.getMoonPhaseInfo(_selectedDate);
      final moonPhase = moonPhaseInfo['phaseName'];
      final moonZodiac = _calculator.getMoonZodiacEmoji(_selectedDate);
      final moonInSign = _calculator.getMoonZodiacName(_selectedDate);
      final vocTimes = _calculator.findVoidOfCoursePeriod(_selectedDate);
      final moonSignTimes = _calculator.getMoonSignTimes(_selectedDate);

      final Map<String, dynamic> result = {
        'moonPhase': moonPhase,
        'moonZodiac': moonZodiac,
        'moonInSign': moonInSign,
        'vocStart': vocTimes['start'],
        'vocEnd': vocTimes['end'],
        'nextSignTime': moonSignTimes['end'],
      };

      if (kDebugMode) {
        print('Calculated data for $dateKey: $result');
      }
      _cache[dateKey] = result;
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
  }
}