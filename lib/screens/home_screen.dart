import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/astro_state.dart';
import '../widgets/calendar_dialog.dart';
import '../widgets/date_selector.dart';
import '../widgets/moon_phase_card.dart';
import '../widgets/moon_sign_card.dart';
import '../widgets/reset_date_button.dart';
import '../widgets/voc_info_card.dart';

// 홈 화면을 보여주는 위젯이에요.
class HomeScreen extends StatefulWidget {
  // const는 이 위젯이 변하지 않는다는 뜻이에요.
  const HomeScreen({super.key});

  @override
  // 홈 화면의 상태를 관리하는 클래스를 만들어요.
  _HomeScreenState createState() => _HomeScreenState();
}

// 홈 화면의 상태를 관리하는 클래스예요.
class _HomeScreenState extends State<HomeScreen> {
  // 날짜를 보여주는 입력창을 다루는 컨트롤러예요.
  final TextEditingController _dateController = TextEditingController();

  @override
  // 이 위젯이 처음 만들어질 때 한 번만 실행되는 함수예요.
  void initState() {
    super.initState(); // 부모 클래스의 initState 함수를 먼저 실행해요.
    // 앱의 전체적인 상태(데이터)를 가져와요. 화면을 다시 그릴 필요는 없어요.
    final provider = Provider.of<AstroState>(context, listen: false);

    // 만약 아직 별자리 정보가 준비되지 않았다면,
    if (!provider.isInitialized) {
      // 아주 잠깐 뒤에 별자리 정보를 준비하는 함수를 실행해요.
      Future.microtask(() => provider.initialize());
    }
  }

  @override
  // 이 위젯이 화면에서 사라질 때 실행되는 함수예요.
  void dispose() {
    _dateController.dispose(); // 날짜 컨트롤러를 정리해서 메모리를 아껴요.
    super.dispose(); // 부모 클래스의 dispose 함수를 실행해요.
  }

  // 날짜를 바꾸는 함수예요. days 만큼 날짜를 더하거나 빼요.
  void _changeDate(int days) {
    // 이 위젯이 화면에 잘 붙어있을 때만 실행해요.
    if (mounted) {
      // 앱의 전체적인 상태(데이터)를 가져와요.
      final provider = Provider.of<AstroState>(context, listen: false);
      // 현재 선택된 날짜에 days 만큼 더하거나 뺀 새로운 날짜를 만들어요.
      final newDate = provider.selectedDate.add(Duration(days: days));
      // 앱의 날짜 정보를 새로운 날짜로 업데이트해요.
      provider.updateDate(newDate);
    }
  }

  // 날짜를 오늘로 되돌리는 함수를 추가합니다.
  void _resetDateToToday() {
    if (mounted) {
      final provider = Provider.of<AstroState>(context, listen: false);
      provider.updateDate(DateTime.now());
    }
  }

  @override
  // 이 위젯이 화면에 어떻게 보일지 정하는 가장 중요한 부분이에요.
  Widget build(BuildContext context) {
    // 앱의 전체적인 상태(데이터)를 가져와요. 데이터가 바뀌면 화면을 다시 그려요.
    final provider = Provider.of<AstroState>(context);
    // 날짜 컨트롤러에 현재 선택된 날짜를 '년-월-일' 형식으로 보여줘요.
    _dateController.text = DateFormat('yyyy-MM-dd').format(provider.selectedDate);

    // 만약 데이터가 아직 준비 중이라면,
    if (!provider.isInitialized || provider.isLoading) {
      // 화면 가운데에 동그란 로딩 아이콘을 보여줘요.
      return const Center(child: CircularProgressIndicator());
    }
    // 만약 에러가 발생했다면,
    if (provider.lastError != null) {
      // 화면 가운데에 에러 메시지를 보여줘요.
      return Center(child: Text('Error: ${provider.lastError}'));
    }

    // 다음 별자리로 바뀌는 시간에 대한 글자를 만들어요.
    final nextSignTimeText = provider.nextSignTime != null
        // 만약 다음 별자리로 바뀌는 시간이 있다면, 그 시간을 예쁘게 만들어서 보여줘요.
        ? '다음 싸인 : ${DateFormat('MM월 dd일 HH:mm').format(provider.nextSignTime!)}'
        : '다음 싸인 : N/A';

    // 화면의 전체적인 구조를 짜요.
    return Scaffold(
      // 화면 상단의 앱 바(제목 바)예요.
      appBar: AppBar(
        // 제목 부분에 아이콘과 글자를 가로로 나란히 놓아요.
        title: Row(
          children: [
            // 별 모양 아이콘이에요.
            Icon(
              Icons.star,
              color: Theme.of(context).colorScheme.secondary, // 앱 테마에 맞는 두 번째 색깔을 사용해요.
              size: 24, // 아이콘 크기는 24
            ),
            const SizedBox(width: 8), // 아이콘과 글자 사이에 작은 공간을 만들어요.
            // 앱 제목을 써요.
            Text(
              'Void of Course',
              style: Theme.of(context).appBarTheme.titleTextStyle, // 테마에 정의된 앱 바 제목 스타일을 사용해요.
            ),
          ],
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor, // 앱 바의 배경색을 테마에 맞게 설정해요.
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor, // 앱 바의 글자/아이콘 색을 테마에 맞게 설정해요.
        elevation: Theme.of(context).appBarTheme.elevation, // 앱 바의 그림자 높이를 테마에 맞게 설정해요.
      ),
      // 화면의 주요 내용이 들어가는 부분이에요.
      body: Container(
        width: double.infinity, // 너비를 화면 끝까지 채워요.
        height: double.infinity, // 높이를 화면 끝까지 채워요.
        // 화면 배경을 예쁘게 꾸며줘요.
        decoration: BoxDecoration(
          // 배경색을 위에서 아래로 변하게 만들어요.
          gradient: LinearGradient(
            begin: Alignment.topCenter, // 위쪽 가운데에서 시작해서
            end: Alignment.bottomCenter, // 아래쪽 가운데로 색이 변해요.
            colors: [
              Theme.of(context).colorScheme.background, // 앱 테마의 배경색
              Theme.of(context).colorScheme.surface, // 앱 테마의 표면색
            ],
          ),
        ),
        // 휴대폰의 상태표시줄 같은 시스템 UI를 피해서 내용을 보여줘요.
        child: SafeArea(
          // 내용이 길어지면 스크롤 할 수 있게 만들어요.
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0), // 모든 방향으로 16만큼 여백을 줘요.
            // 화면에 보이는 위젯들을 세로로 차곡차곡 쌓아요.
            child: Column(
              children: [
                // 1. 달의 위상 정보를 보여주는 카드를 넣어요.
                MoonPhaseCard(provider: provider),
                const SizedBox(height: 8), // 카드와 카드 사이에 작은 공간을 만들어요.

                // 2. 달의 별자리 정보를 보여주는 카드를 넣어요.
                MoonSignCard(provider: provider, nextSignTimeText: nextSignTimeText),
                const SizedBox(height: 8), // 카드와 카드 사이에 작은 공간을 만들어요.

                // 3. VOC(Void of Course) 정보를 보여주는 카드를 넣어요.
                VocInfoCard(provider: provider), // provider만 넘겨주면 카드 안에서 모든 것을 처리해요.
                const SizedBox(height: 8), // 카드와 날짜 선택기 사이에 작은 공간을 만들어요.

                // 4. 날짜를 선택하는 위젯을 넣어요.
                DateSelector(
                  dateController: _dateController, // 날짜를 보여줄 컨트롤러를 줘요.
                  onPreviousDay: () => _changeDate(-1), // 왼쪽 화살표를 누르면 어제로 가요.
                  onNextDay: () => _changeDate(1), // 오른쪽 화살표를 누르면 내일로 가요.
                  showCalendar: () => showCalendarDialog(context), // 날짜 부분을 누르면 달력을 보여줘요.
                ),
                const SizedBox(height: 15), // 날짜 선택기와 초기화 버튼 사이에 공간을 만들어요.

                // 5. 날짜를 오늘로 되돌리는 버튼을 넣어요.
                ResetDateButton(onPressed: _resetDateToToday),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
