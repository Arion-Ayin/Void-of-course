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
    await _updateData();
    _isInitialized = true;
    notifyListeners();
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

    // 캐시 키를 마이크로초까지 포함
    final dateKey = _selectedDate.toIso8601String();
    if (_cache.containsKey(dateKey)) {
      final result = _cache[dateKey]!;
      print('Using cached data for $dateKey: $result');
      _updateStateFromResult(result);
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
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

      print('Calculated data for $dateKey: $result');
      _cache[dateKey] = result;
      _updateStateFromResult(result);
      _lastError = null;
    } catch (e, stack) {
      print('계산 중 오류 발생: $e\n$stack');
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