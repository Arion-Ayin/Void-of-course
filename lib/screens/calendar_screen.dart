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
  Map<DateTime, List<Map<String, dynamic>>> _rawVocEvents = {};

  // 타임존이 반영된 이벤트와 스팬
  Map<DateTime, List<Map<String, dynamic>>> _tzAdjustedEvents = {};
  Map<DateTime, Map<String, dynamic>> _vocSpans = {};

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  bool _isLoading = true;
  String? _error;
  String _lastTzId = '';
  bool _lastIsDst = false;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _selectedEvents = ValueNotifier([]);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchMonthVocEvents(_focusedDay);
    });
  }

  @override
  void dispose() {
    _selectedEvents.dispose();
    super.dispose();
  }

  // 타임존을 고려하여 이벤트를 재구성하고 스팬을 식별하는 함수
  void _updateTzAdjustedData(TimezoneProvider tzProvider) {
    _tzAdjustedEvents.clear();
    _vocSpans.clear();

    // 1. 고유한 VOC 이벤트 추출
    Set<Map<String, dynamic>> uniqueEvents = {};
    for (var eventsList in _rawVocEvents.values) {
      uniqueEvents.addAll(eventsList);
    }

    // 2. 각 이벤트를 타임존에 맞게 날짜별로 매핑
    for (var voc in uniqueEvents) {
      final startUtc = voc['start'] as DateTime?;
      final endUtc = voc['end'] as DateTime?;
      if (startUtc == null || endUtc == null) continue;

      final tzStart = tzProvider.convert(startUtc);
      final tzEnd = tzProvider.convert(endUtc);

      final vocStartDay = DateTime.utc(
        tzStart.year,
        tzStart.month,
        tzStart.day,
      );
      final vocEndDay = DateTime.utc(tzEnd.year, tzEnd.month, tzEnd.day);

      var currentDay = vocStartDay;
      while (currentDay.isBefore(vocEndDay) ||
          currentDay.isAtSameMomentAs(vocEndDay)) {
        _tzAdjustedEvents.putIfAbsent(currentDay, () => []).add(voc);
        currentDay = currentDay.add(const Duration(days: 1));
      }
    }

    // 3. 다중 날짜 스팬 식별
    final List<DateTime> sortedDates = _tzAdjustedEvents.keys.toList()..sort();
    for (var currentDate in sortedDates) {
      if (_vocSpans.containsKey(currentDate)) continue;

      final currentVoc = _tzAdjustedEvents[currentDate]?.first;
      if (currentVoc == null) continue;

      final startUtc = currentVoc['start'] as DateTime?;
      final endUtc = currentVoc['end'] as DateTime?;
      if (startUtc == null || endUtc == null) continue;

      final tzStart = tzProvider.convert(startUtc);
      final tzEnd = tzProvider.convert(endUtc);

      final vocStartDay = DateTime.utc(
        tzStart.year,
        tzStart.month,
        tzStart.day,
      );
      final vocEndDay = DateTime.utc(tzEnd.year, tzEnd.month, tzEnd.day);

      final dayDifference = vocEndDay.difference(vocStartDay).inDays;
      final isMultiDay = dayDifference > 0;

      var checkDate = vocStartDay;
      while (checkDate.isBefore(vocEndDay) ||
          checkDate.isAtSameMomentAs(vocEndDay)) {
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
    final dayUtc = DateTime.utc(day.year, day.month, day.day);
    return _tzAdjustedEvents[dayUtc] ?? [];
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
      // 캘린더에서 보여지는 날짜 범위를 조금 더 넓게 가져와서 타임존 경계 문제 방지
      // 이전 달, 이번 달, 다음 달의 데이터를 가져옴 (선택적 최적화 가능)
      // 여기서는 이번 달만 가져오던 것을 앞뒤 달까지 확장하여 가져오는 것이 안전합니다.
      final prevMonth = DateTime.utc(month.year, month.month - 1, 1);
      final nextMonth = DateTime.utc(month.year, month.month + 1, 1);

      final prevEvents = await Future.microtask(
        () => _calculator.getVocEventsForMonth(prevMonth.year, prevMonth.month),
      );
      final currentEvents = await Future.microtask(
        () => _calculator.getVocEventsForMonth(month.year, month.month),
      );
      final nextEvents = await Future.microtask(
        () => _calculator.getVocEventsForMonth(nextMonth.year, nextMonth.month),
      );

      final Map<DateTime, List<Map<String, dynamic>>> allEvents = {};
      allEvents.addAll(prevEvents);
      allEvents.addAll(currentEvents);
      allEvents.addAll(nextEvents);

      if (mounted) {
        final tzProvider = Provider.of<TimezoneProvider>(context, listen: false);
        setState(() {
          _rawVocEvents = allEvents;
          _isLoading = false;
        });
        // 새 데이터 로드 후 타임존 반영된 데이터를 즉시 갱신
        _updateTzAdjustedData(tzProvider);
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

    // 타임존 설정이 변경되었을 때만 데이터 갱신
    if (_lastTzId != tzProvider.selectedTimezoneId ||
        _lastIsDst != tzProvider.isDstApplied) {
      _updateTzAdjustedData(tzProvider);
      _lastTzId = tzProvider.selectedTimezoneId;
      _lastIsDst = tzProvider.isDstApplied;

      // 선택된 이벤트 목록 갱신
      if (_selectedDay != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _selectedEvents.value = _getEventsForDay(_selectedDay!);
          }
        });
      }
    }

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
                    color:
                        Theme.of(context).brightness == Brightness.dark
                            ? Themes.gold.withOpacity(0.3)
                            : Themes.midnightBlue.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  // 선택된 날짜 스타일
                  selectedDecoration: BoxDecoration(
                    color:
                        Theme.of(context).brightness == Brightness.dark
                            ? Themes.gold
                            : Themes.midnightBlue,
                    shape: BoxShape.circle,
                  ),
                  // 마커 스타일 - 1일 VOC 용 점
                  markerDecoration: BoxDecoration(
                    color:
                        Theme.of(context).brightness == Brightness.dark
                            ? Colors.redAccent
                            : Colors.red,
                    shape: BoxShape.circle,
                  ),
                  markerSize: 6.0,
                ),
                headerStyle: HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  titleTextStyle: TextStyle(
                    color:
                        Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black,
                    fontSize: 18,
                  ),
                  leftChevronIcon: Icon(
                    Icons.chevron_left,
                    color:
                        Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black,
                  ),
                  rightChevronIcon: Icon(
                    Icons.chevron_right,
                    color:
                        Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black,
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
                    final markerColor =
                        Theme.of(context).brightness == Brightness.dark
                            ? Colors.redAccent
                            : Colors.red;

                    return Stack(
                      children: [
                        // 굵은 선 (아래쪽)
                        Align(
                          alignment: Alignment(0, 0.8), // 날짜 텍스트 아래쪽에 위치
                          child: Container(
                            height: 6,
                            margin: const EdgeInsets.symmetric(horizontal: 1),
                            decoration: BoxDecoration(
                              color: markerColor,
                              borderRadius: BorderRadius.horizontal(
                                left:
                                    isFirstDay
                                        ? const Radius.circular(10)
                                        : Radius.zero,
                                right:
                                    isLastDay
                                        ? const Radius.circular(10)
                                        : Radius.zero,
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
            child:
                _isLoading
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
                                leading: const Icon(
                                  Icons.timer_off_outlined,
                                  color: Colors.red,
                                ),
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
