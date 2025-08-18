
import 'package:flutter/material.dart'; // 플러터의 디자인 라이브러리를 가져와요.
import 'package:provider/provider.dart'; // 앱의 상태(데이터)를 쉽게 관리하게 도와주는 라이브러리를 가져와요.
import 'package:table_calendar/table_calendar.dart'; // 표 형태로 된 달력을 보여주는 라이브러리를 가져와요.
import '../services/astro_state.dart'; // 별자리 계산과 관련된 우리 앱의 기능을 가져와요.

// 화면에 달력을 보여주는 함수예요.
void showCalendarDialog(BuildContext context) {
  // 앱의 전체적인 상태(데이터)를 가져와요. 여기서는 날짜 정보가 필요해요.
  final provider = Provider.of<AstroState>(context, listen: false);

  // 화면에 대화상자(팝업창)를 보여줘요.
  showDialog(
    context: context, // 이 대화상자를 어디에 보여줄지 알려줘요.
    builder: (context) => Dialog( // 대화상자의 내용을 만들어요.
      // 대화상자 안에 들어갈 내용물을 담는 상자예요.
      child: SizedBox(
        width: 1000, // 상자의 너비는 1000
        height: 450, // 상자의 높이는 450
        // 상자 안쪽에 여백을 줘요.
        child: Padding(
          padding: const EdgeInsets.all(16), // 모든 방향으로 16만큼 여백을 줘요.
          // 달력을 만들어요.
          child: TableCalendar(
            focusedDay: provider.selectedDate, // 달력에서 처음 보여줄 날짜를 정해요. (현재 선택된 날짜)
            firstDay: DateTime(1900), // 달력에서 선택할 수 있는 가장 빠른 날짜예요.
            lastDay: DateTime(2100), // 달력에서 선택할 수 있는 가장 늦은 날짜예요.
            calendarFormat: CalendarFormat.month, // 달력을 '월' 단위로 보여줘요.
            // 사용 가능한 달력 형식을 정해요. 여기서는 '월' 단위만 가능하게 해요.
            availableCalendarFormats: const {
              CalendarFormat.month: 'Month',
            },
            // 달력의 윗부분(헤더) 스타일을 정해요.
            headerStyle: const HeaderStyle(
              titleCentered: true, // '2025년 8월' 같은 제목을 가운데 정렬해요.
            ),
            // 어떤 날짜가 선택되었는지 알려주는 함수예요.
            selectedDayPredicate: (day) => isSameDay(provider.selectedDate, day),
            // 사용자가 날짜를 선택했을 때 실행될 함수예요.
            onDaySelected: (selectedDay, focusedDay) {
              // 선택된 날짜로 앱의 날짜 정보를 업데이트해요.
              provider.updateDate(selectedDay);
              // 날짜를 선택했으니, 달력 창을 닫아요.
              Navigator.of(context).pop();
            },
          ),
        ),
      ),
    ),
  );
}
