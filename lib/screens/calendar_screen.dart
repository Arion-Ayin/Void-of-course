import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:void_of_course/l10n/app_localizations.dart';
import '../services/astro_calculator.dart';
import '../services/astro_state.dart';
import '../services/timezone_provider.dart';
import '../themes.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final AstroCalculator _calculator = AstroCalculator();
  late final ValueNotifier<List<Map<String, dynamic>>> _selectedEvents;
  Map<DateTime, List<Map<String, dynamic>>> _vocEvents = {};
  Map<DateTime, Map<String, dynamic>> _vocSpans = {}; // 다중 날짜 VOC 스팬 추적

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // 추가: 로딩 상태와 오류 상태를 관리할 변수
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _selectedEvents = ValueNotifier([]);
    // 위젯이 빌드된 후 첫 데이터 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchMonthVocEvents(_focusedDay);
    });
  }

  @override
  void dispose() {
    _selectedEvents.dispose();
    super.dispose();
  }

  // 다중 날짜 VOC 스팬을 식별하고 정보를 저장하는 함수
  void _identifyVocSpans() {
    _vocSpans.clear();
    final List<DateTime> sortedDates = _vocEvents.keys.toList()..sort();
    
    for (int i = 0; i < sortedDates.length; i++) {
      final currentDate = sortedDates[i];
      if (_vocSpans.containsKey(currentDate)) {
        continue; // 이미 처리된 날짜 건너뛰기
      }

      final currentVoc = _vocEvents[currentDate]?.first;
      if (currentVoc == null) continue;

      final startDate = currentVoc['start'] as DateTime?;
      final endDate = currentVoc['end'] as DateTime?;

      if (startDate == null || endDate == null) continue;

      // VOC 기간의 시작과 끝을 날짜만으로 추출
      final vocStartDay = DateTime.utc(startDate.year, startDate.month, startDate.day);
      final vocEndDay = DateTime.utc(endDate.year, endDate.month, endDate.day);
      
      // 시작일과 종료일이 다른 경우 (2일 이상)
      final dayDifference = vocEndDay.difference(vocStartDay).inDays;
      final isMultiDay = dayDifference > 0;

      // 모든 날짜에 스팬 정보 저장
      var checkDate = vocStartDay;
      while (checkDate.isBefore(vocEndDay) || checkDate.isAtSameMomentAs(vocEndDay)) {
        _vocSpans[checkDate] = {
          'isMultiDay': isMultiDay,
          'spanStart': vocStartDay,
          'spanEnd': vocEndDay,
          'dayDifference': dayDifference,
          'isFirstDay': checkDate.isAtSameMomentAs(vocStartDay),
          'isLastDay': checkDate.isAtSameMomentAs(vocEndDay),
        };
        checkDate = checkDate.add(const Duration(days: 1));
      }
    }
  }

  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    // 날짜의 시간 부분을 무시하고 비교하기 위해 UTC 자정으로 변환
    final dayUtc = DateTime.utc(day.year, day.month, day.day);
    return _vocEvents[dayUtc] ?? [];
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
      });
      _selectedEvents.value = _getEventsForDay(selectedDay);
    }
  }

  Future<void> _fetchMonthVocEvents(DateTime month) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      // 백그라운드에서 계산을 수행하는 것처럼 처리 (실제로는 동기적)
      final events =
          await Future.microtask(() => _calculator.getVocEventsForMonth(
                month.year,
                month.month,
              ));
      if (mounted) {
        setState(() {
          _vocEvents = events;
          _identifyVocSpans(); // VOC 스팬 식별
          _isLoading = false;
        });
        // 현재 선택된 날의 이벤트도 갱신
        if (_selectedDay != null) {
          _selectedEvents.value = _getEventsForDay(_selectedDay!);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load VOC data.';
          _isLoading = false;
        });
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final tzProvider = Provider.of<TimezoneProvider>(context);
    final appLocalizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(
              Icons.calendar_month,
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(appLocalizations.voidCalendar),
          ],
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        elevation: Theme.of(context).appBarTheme.elevation,
      ),
      body: Column(
        children: [
          // VOC 바 오버레이를 포함한 커스텀 캘린더
          Stack(
            children: [
              TableCalendar<Map<String, dynamic>>(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2050, 12, 31),
                focusedDay: _focusedDay,
                locale: appLocalizations.localeName,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                eventLoader: _getEventsForDay,
                onDaySelected: _onDaySelected,
                onPageChanged: (focusedDay) {
                  _focusedDay = focusedDay;
                  _fetchMonthVocEvents(focusedDay);
                },
                calendarStyle: CalendarStyle(
                  // 오늘 날짜 스타일
                  todayDecoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Themes.gold.withOpacity(0.3)
                        : Themes.midnightBlue.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  // 선택된 날짜 스타일
                  selectedDecoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark ? Themes.gold : Themes.midnightBlue,
                    shape: BoxShape.circle,
                  ),
                  // 마커 스타일 - 1일 VOC 용 점
                  markerDecoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.redAccent : Colors.red,
                    shape: BoxShape.circle,
                  ),
                  markerSize: 6.0,
                ),
                headerStyle: HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  titleTextStyle: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                    fontSize: 18,
                  ),
                  leftChevronIcon: Icon(
                    Icons.chevron_left,
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                  ),
                  rightChevronIcon: Icon(
                    Icons.chevron_right,
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                  ),
                ),
                calendarBuilders: CalendarBuilders(
                  // 2일 이상 VOC를 굵은 선으로 표시
                  defaultBuilder: (context, day, focusedDay) {
                    final vocSpan = _vocSpans[day];
                    if (vocSpan == null || !vocSpan['isMultiDay']) {
                      return null; // 기본 렌더링 사용 (1일 VOC는 점으로 표시)
                    }

                    final isFirstDay = vocSpan['isFirstDay'] as bool;
                    final isLastDay = vocSpan['isLastDay'] as bool;
                    final markerColor = Theme.of(context).brightness == Brightness.dark ? Colors.redAccent : Colors.red;

                    return Stack(
                      children: [
                        // 굵은 선 (아래쪽)
                        Align(
                          alignment: Alignment(0, 0.8), // 날짜 텍스트 아래쪽에 위치
                          child: Container(
                            height: 6,
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            decoration: BoxDecoration(
                              color: markerColor,
                              borderRadius: BorderRadius.horizontal(
                                left: isFirstDay ? const Radius.circular(3) : Radius.zero,
                                right: isLastDay ? const Radius.circular(3) : Radius.zero,
                              ),
                            ),
                          ),
                        ),
                        // 날짜 텍스트 (위쪽, 위에 표시됨)
                        Align(
                          alignment: Alignment.center,
                          child: Text(
                            day.day.toString(),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8.0),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text(_error!))
                    : ValueListenableBuilder<List<Map<String, dynamic>>>(
                        valueListenable: _selectedEvents,
                        builder: (context, events, _) {
                          if (events.isEmpty) {
                            return Center(
                              child: Text(appLocalizations.noVocFound),
                            );
                          }
                          return ListView.builder(
                            itemCount: events.length,
                            itemBuilder: (context, index) {
                              final event = events[index];
                              final vocStart = event['start'] as DateTime?;
                              final vocEnd = event['end'] as DateTime?;

                              if (vocStart == null || vocEnd == null) {
                                return ListTile(
                                  title: Text(appLocalizations.invalidVocData),
                                );
                              }

                              // 타임존 변환
                              final tzStart = tzProvider.convert(vocStart);
                              final tzEnd = tzProvider.convert(vocEnd);

                              final timeFormat = DateFormat('HH:mm');

                              return Card(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 12.0,
                                  vertical: 4.0,
                                ),
                                child: ListTile(
                                  leading: const Icon(Icons.timer_off_outlined,
                                      color: Colors.red),
                                  title: const Text('Void of Course'),
                                  subtitle: Text(
                                    '${timeFormat.format(tzStart)} - ${timeFormat.format(tzEnd)}',
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
