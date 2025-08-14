// home_screen.dart

// Flutter의 기본 재료들을 가져옵니다. 화면을 만드는 데 꼭 필요해요.
import 'package:flutter/material.dart';
// 화면 아래에 알림 메시지를 보여주는 도구(플러시바)를 가져옵니다.
import 'package:lioluna/utils/flushbar_helper.dart';
// 앱의 중요한 데이터(상태)를 여러 곳에서 같이 쓰게 해주는 도구(프로바이더)를 가져옵니다.
import 'package:provider/provider.dart';
// 우리가 만든 '별자리 정보' 데이터 관리 파일을 가져옵니다.
import '../services/astro_state.dart';
// 앱의 전체적인 색깔과 디자인을 정해둔 파일을 가져옵니다.
import '../themes.dart';
// 날짜를 '2025-08-13'처럼 예쁘게 꾸며주는 도구(포매터)를 가져옵니다.
import 'package:intl/intl.dart';
// 화면의 색깔이 부드럽게 바뀌는 애니메이션을 도와주는 도구(테마 스위처)를 가져옵니다.
import 'package:animated_theme_switcher/animated_theme_switcher.dart';

// HomeScreen은 우리 앱의 첫 화면(위젯)입니다.
class HomeScreen extends StatefulWidget {
  // HomeScreen 위젯을 만듭니다.
  const HomeScreen({super.key});

  // 이 화면의 상태(데이터)를 관리하는 곳을 만듭니다.
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

// _HomeScreenState는 HomeScreen의 상태를 실제로 관리하는 곳입니다.
// 'with TickerProviderStateMixin'은 애니메이션을 만들 때 필요한 도구입니다.
class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  // 날짜를 입력하는 칸에 들어갈 글자를 관리하는 도구입니다.
  final TextEditingController _dateController = TextEditingController();
  // 키보드를 띄우거나 숨기는 것을 관리하는 도구입니다.
  final FocusNode _focusNode = FocusNode();

  // 데이터가 바뀌었을 때 알려주는 역할을 하는 함수를 준비합니다.
  late VoidCallback _listener;
  // 아이콘의 회전 애니메이션을 조절하는 도구입니다.
  late AnimationController _iconRotationController;
  // 아이콘의 회전 각도를 계산하는 도구입니다.
  late Animation<double> _iconRotationAnimation;

  // 테마(화면의 색깔)가 바뀔 때 실행되는 함수입니다.
  void _onThemeChanged() {
    // 아이콘 회전 애니메이션을 처음부터 다시 시작합니다.
    _iconRotationController.forward(from: 0.0);
  }

  // 달력(날짜 선택기)을 보여주는 함수입니다.
  void _showDatePicker() async {
    // 사용자가 날짜를 선택할 때까지 기다립니다.
    final DateTime? picked = await showDatePicker(
      // 현재 화면을 기준으로 달력을 보여줍니다.
      context: context,
      // 달력을 처음 열었을 때 오늘 날짜를 보여줍니다.
      initialDate: DateTime.now(),
      // 선택할 수 있는 가장 빠른 날짜입니다.
      firstDate: DateTime(1900),
      // 선택할 수 있는 가장 늦은 날짜입니다.
      lastDate: DateTime(2100),
      // 달력의 디자인을 정해주는 함수입니다.
      builder: (context, child) {
        // 현재 화면이 어두운 모드인지 밝은 모드인지에 따라 달력 색깔을 바꿉니다.
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).brightness == Brightness.dark
                // 어두운 모드일 때의 색깔입니다.
                ? ColorScheme.dark(primary: Colors.blue[300]!, onPrimary: Colors.white)
                // 밝은 모드일 때의 색깔입니다.
                : ColorScheme.light(primary: Colors.blue[600]!, onPrimary: Colors.white),
          ),
          // 달력 위젯을 여기에 넣습니다.
          child: child!,
        );
      },
    );
    // 만약 사용자가 날짜를 선택했다면,
    if (picked != null) {
      // 선택된 날짜를 'yyyy-MM-dd' 형식으로 바꿔서 입력 칸에 넣습니다.
      _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      // 날짜가 입력되었을 때 실행되는 함수를 호출합니다.
      _handleDateInput(_dateController.text);
    }
  }

  // 날짜 입력 칸의 글자를 현재 선택된 날짜로 바꿔주는 함수입니다.
  void _updateDateController() {
    // 화면이 아직 살아 있는지 확인합니다.
    if (mounted) {
      // AstroState에서 현재 선택된 날짜를 가져옵니다.
      final provider = Provider.of<AstroState>(context, listen: false);
      // 날짜를 예쁘게 바꿔서 입력 칸에 넣어줍니다.
      _dateController.text = DateFormat('yyyy-MM-dd').format(provider.selectedDate);
    }
  }

  // 날짜를 하루씩 바꾸는 함수입니다.
  void _changeDate(int days) {
    // 화면이 아직 살아 있는지 확인합니다.
    if (mounted) {
      // AstroState에서 날짜를 가져와서,
      final provider = Provider.of<AstroState>(context, listen: false);
      // 원하는 만큼의 날짜를 더하거나 뺌니다.
      final newDate = provider.selectedDate.add(Duration(days: days));
      // 바뀐 날짜를 AstroState에 알려줍니다.
      provider.updateDate(newDate);
    }
  }

  // 사용자가 직접 날짜를 입력했을 때 실행되는 함수입니다.
  void _handleDateInput(String input) {
    // 화면이 아직 살아 있는지 확인합니다.
    if (mounted) {
      // 혹시 오류가 생길 수도 있으니, 일단 시도해봅니다.
      try {
        // 입력된 날짜에서 하이픈(-)을 모두 없앱니다.
        input = input.trim().replaceAll('-', '');
        // 입력된 글자 수가 너무 짧거나 길면 오류를 보여줍니다.
        if (input.length < 6 || input.length > 8) {
          showErrorSnackBar();
          return;
        }

        // 입력된 글자에서 연도를 가져옵니다.
        String year = input.substring(0, 4);
        // 월과 일 변수를 미리 만들어둡니다.
        String month = '';
        String day = '';

        // 입력된 글자 수에 따라 월과 일을 가져오는 방식이 다릅니다.
        if (input.length == 8) {
          // '20250815' 형식
          month = input.substring(4, 6);
          day = input.substring(6, 8);
        } else if (input.length == 7) {
          // '2025815' 형식
          month = input.substring(4, 5);
          day = input.substring(5, 7);
        } else if (input.length == 6) {
          // '202581' 형식
          month = input.substring(4, 5);
          day = input.substring(5, 6).padLeft(2, '0');
        }

        // 가져온 연, 월, 일을 숫자로 바꿉니다.
        int y = int.parse(year);
        int m = int.parse(month);
        int d = int.parse(day);

        // 새로운 날짜를 만듭니다.
        final newDate = DateTime(y, m, d);

        // 만약 만든 날짜가 유효한 날짜라면,
        if (newDate.year == y && newDate.month == m && newDate.day == d) {
          // AstroState에 새로운 날짜를 알려줍니다.
          final provider = Provider.of<AstroState>(context, listen: false);
          provider.updateDate(newDate);
        } else {
          // 유효하지 않으면 오류 메시지를 보여줍니다.
          showErrorSnackBar();
        }
      } catch (e) {
        // 날짜를 숫자로 바꾸는 중에 오류가 생기면 메시지를 보여줍니다.
        showErrorSnackBar();
      }
    }
  }

  // 화면 아래에 오류 메시지를 보여주는 함수입니다.
  void showErrorSnackBar() {
    // 화면이 아직 살아 있는지 확인합니다.
    if (mounted) {
      // '올바른 날짜를 입력해주세요.'라는 메시지를 보여줍니다.
      FlushbarHelper.showError(context, "올바른 날짜를 입력해주세요.");
    }
  }

  // 이 화면이 사라질 때 실행되는 함수입니다.
  @override
  void dispose() {
    // 화면이 아직 살아 있는지 확인합니다.
    if (mounted) {
      // 오류가 생겨도 앱이 멈추지 않게 보호합니다.
      try {
        // AstroState에서 리스너(데이터 변화를 알려주는)를 제거합니다.
        final provider = Provider.of<AstroState>(context, listen: false);
        provider.removeListener(_listener);
      } catch (e) {
        // 프로바이더가 이미 사라진 경우, 그냥 넘어갑니다.
      }
    }
    // 사용했던 도구들을 모두 정리합니다.
    _dateController.dispose();
    _focusNode.dispose();
    _iconRotationController.dispose();
    // 부모 위젯의 dispose 함수도 꼭 불러줍니다.
    super.dispose();
  }

  // 화면에 무엇을 보여줄지 결정하는 중요한 함수입니다.
  @override
  Widget build(BuildContext context) {
    // AstroState의 데이터를 가져옵니다.
    final provider = Provider.of<AstroState>(context);

    // 만약 데이터가 아직 준비 중이거나 불러오는 중이라면,
    if (!provider.isInitialized || provider.isLoading) {
      // 로딩 표시를 보여줍니다.
      return const Center(child: CircularProgressIndicator());
    }
    // 만약 오류가 발생했다면,
    if (provider.lastError != null) {
      // 오류 메시지를 보여줍니다.
      return Center(child: Text('Error: ${provider.lastError}'));
    }

    // 날짜와 시간을 'yyyy-MM-dd HH:mm' 형식으로 예쁘게 만들어주는 함수입니다.
    String _formatDateTime(DateTime? dateTime) {
      // 만약 날짜가 없으면 'N/A'를 반환합니다.
      if (dateTime == null) return 'N/A';
      // 날짜가 있으면 원하는 형식으로 바꿔줍니다.
      return DateFormat('yyyy-MM-dd HH:mm').format(dateTime);
    }

    // 다음 싸인이 바뀌는 시간을 보여줄 글자를 만듭니다.
    final nextSignTimeText = provider.nextSignTime != null
        // 시간이 있으면 형식을 맞춰서 보여주고,
        ? '종료 : ${DateFormat('yyyy-MM-dd HH:mm').format(provider.nextSignTime!)}'
        // 시간이 없으면 '종료 : N/A'라고 보여줍니다.
        : '종료 : N/A';

    // ⭐ 여기부터가 실제 화면의 시작입니다. build 함수는 항상 위젯을 반환해야 합니다.
    // 'Scaffold'는 앱 화면의 기본 틀(바탕)입니다.
    return Scaffold(
      // AppBar는 화면의 맨 위에 있는 막대입니다.
      appBar: AppBar(
        // title은 AppBar의 제목 부분입니다.
        title: Row(
          // 아이콘과 텍스트를 나란히 놓습니다.
          children: [
            // 별 아이콘을 보여줍니다.
            Icon(
                // 별 모양 아이콘
                Icons.star,
                // 어두운 모드일 때 노란색, 밝은 모드일 때 주황색으로 색을 정합니다.
                color: Theme.of(context).brightness == Brightness.dark ? Colors.yellow : Colors.orange,
                // 아이콘 크기
                size: 24
            ),
            // 아이콘과 텍스트 사이에 작은 공간을 둡니다.
            const SizedBox(width: 8),
            // 앱 이름을 보여주는 텍스트입니다.
            Text(
              'Lioluna',
              // 텍스트의 디자인을 정합니다.
              style: TextStyle(
                // 어두운 모드일 때 흰색, 밝은 모드일 때 검은색으로 글자 색을 정합니다.
                color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
        // AppBar의 배경색을 테마에 맞춰 정합니다.
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        // AppBar의 글자색을 테마에 맞춰 정합니다.
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        // AppBar 아래에 그림자를 살짝 넣어줍니다.
        elevation: Theme.of(context).appBarTheme.elevation,
        // actions는 AppBar의 오른쪽 부분에 들어가는 위젯들입니다.
        actions: [
          // ThemeSwitcher는 테마를 바꾸는 기능을 제공하는 위젯입니다.
          ThemeSwitcher(
            // ThemeSwitcher의 내용을 만들어주는 함수입니다.
            builder: (context) {
              // 버튼의 크기를 정해주는 컨테이너입니다.
              return Container(
                constraints: const BoxConstraints(
                  // 버튼의 최소 가로 크기
                  minWidth: 48,
                  // 버튼의 최소 세로 크기
                  minHeight: 48,
                ),
                // 애니메이션을 부드럽게 만들어주는 위젯입니다.
                child: AnimatedBuilder(
                  // 어떤 애니메이션을 사용할지 정합니다.
                  animation: _iconRotationAnimation,
                  // 애니메이션이 바뀔 때마다 실행되는 함수입니다.
                  builder: (context, child) {
                    // 아이콘을 회전시키는 효과를 줍니다.
                    return Transform.rotate(
                      // 회전하는 각도를 계산합니다.
                      angle: _iconRotationAnimation.value * 2 * 3.14159,
                      // 아이콘 버튼입니다.
                      child: IconButton(
                        // 아이콘 모양을 정합니다.
                        icon: Icon(
                          // 어두운 모드일 때 해 아이콘, 밝은 모드일 때 달 아이콘을 보여줍니다.
                          Theme.of(context).brightness == Brightness.dark ? Icons.wb_sunny : Icons.nightlight_round,
                          // 아이콘의 색깔을 정합니다.
                          color: Theme.of(context).brightness == Brightness.dark ? Colors.orange : Colors.indigo,
                        ),
                        // 버튼을 눌렀을 때 실행되는 함수입니다.
                        onPressed: () {
                          // 테마 변경 애니메이션을 시작합니다.
                          _onThemeChanged();
                          // 테마를 바꾸는 도구를 가져옵니다.
                          final switcher = ThemeSwitcher.of(context);
                          // 현재 테마가 무엇인지 확인합니다.
                          final currentTheme = Theme.of(context);
                          // 현재 테마가 어두운 모드라면,
                          if (currentTheme.brightness == Brightness.dark) {
                            // 밝은 모드로 바꿔줍니다.
                            switcher.changeTheme(theme: Themes.lightTheme);
                          } else {
                            // 밝은 모드라면, 어두운 모드로 바꿔줍니다.
                            switcher.changeTheme(theme: Themes.darkTheme);
                          }
                        },
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
      // body는 화면의 주요 내용을 담는 부분입니다.
      body: Container(
        // 컨테이너의 가로 길이를 화면 전체로 설정합니다.
        width: double.infinity,
        // 컨테이너의 세로 길이를 화면 전체로 설정합니다.
        height: double.infinity,
        // 컨테이너가 화면 전체를 채우도록 합니다.
        constraints: const BoxConstraints.expand(),
        // 컨테이너의 배경을 그라데이션으로 만듭니다.
        decoration: BoxDecoration(
          gradient: LinearGradient(
            // 그라데이션이 시작되는 위치
            begin: Alignment.topCenter,
            // 그라데이션이 끝나는 위치
            end: Alignment.bottomCenter,
            // 현재 테마에 따라 그라데이션 색깔을 다르게 정합니다.
            colors: Theme.of(context).brightness == Brightness.dark
                ? [Colors.grey[900]!, Colors.grey[800]!]
                : [Colors.blue[50]!, Colors.white],
          ),
        ),
        // SafeArea는 화면의 상단 노치(notch)나 하단 바를 피해서 내용을 보여주는 위젯입니다.
        child: SafeArea(
          // 화면의 내용이 많아도 스크롤할 수 있게 해주는 위젯입니다.
          child: SingleChildScrollView(
            // 스크롤이 끝에 도달했을 때 튕기는 효과를 없앱니다.
            physics: const ClampingScrollPhysics(),
            // 모든 방향에 16.0만큼의 여백을 줍니다.
            padding: const EdgeInsets.all(16.0),
            // 컨테이너의 크기에 제약을 줍니다.
            child: ConstrainedBox(
              // 최소 높이를 600으로 설정합니다.
              constraints: const BoxConstraints(
                minHeight: 600,
              ),
              // 자식 위젯들을 세로로 나열하는 위젯입니다.
              child: Column(
                // 세로 길이를 자식 위젯의 크기만큼만 사용합니다.
                mainAxisSize: MainAxisSize.min,
                // 자식 위젯들을 여기에 넣어줍니다.
                children: [
                  // 달의 위상 정보를 보여주는 카드 위젯입니다.
                  _buildMoonPhaseCard(provider),
                  // 카드 아래에 16만큼의 공간을 줍니다.
                  const SizedBox(height: 16),
                  // 달의 사인 정보를 보여주는 카드 위젯입니다.
                  _buildInfoCard(
                    // 카드 왼쪽에 들어갈 아이콘
                    icon: Icons.star,
                    // 카드 제목
                    title: 'Moon in ${provider.moonInSign} ${provider.moonZodiac}',
                    // 카드 부제목
                    subtitle: nextSignTimeText,
                    // 아이콘의 색깔
                    iconColor: Colors.blue,
                  ),
                  // 카드 아래에 16만큼의 공간을 줍니다.
                  const SizedBox(height: 16),
                  // 보이드 오브 코스 정보를 보여주는 카드 위젯입니다.
                  _buildInfoCard(
                    // 카드 왼쪽에 들어갈 아이콘
                    icon: Icons.timelapse,
                    // 카드 제목
                    title: 'Void of Course',
                    // 카드 부제목
                    subtitle: '시작: ${_formatDateTime(provider.vocStart)}\n'
                        '종료: ${_formatDateTime(provider.vocEnd)}',
                    // 아이콘의 색깔
                    iconColor: Colors.teal,
                  ),
                  // 카드 아래에 20만큼의 공간을 줍니다.
                  const SizedBox(height: 20),
                  // 날짜를 바꾸는 버튼과 입력 칸이 들어있는 컨테이너입니다.
                  Container(
                    // 위아래로 12, 양옆으로 16만큼의 여백을 줍니다.
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    // 컨테이너의 디자인을 정합니다.
                    decoration: BoxDecoration(
                      // 테마에 맞는 카드 색깔을 배경으로 사용합니다.
                      color: Theme.of(context).cardColor,
                      // 모서리를 둥글게 만듭니다.
                      borderRadius: BorderRadius.circular(16),
                      // 그림자 효과를 줍니다.
                      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                    ),
                    // 위젯들을 가로로 나열하는 위젯입니다.
                    child: Row(
                      // 자식 위젯들을 여기에 넣어줍니다.
                      children: [
                        // 이전 날짜로 가는 화살표 버튼입니다.
                        IconButton(
                          // 뒤로 가는 아이콘
                          icon: const Icon(Icons.arrow_back_ios),
                          // 버튼을 눌렀을 때 날짜를 하루 줄이는 함수를 실행합니다.
                          onPressed: () => _changeDate(-1),
                          // 아이콘 색깔을 테마에 맞춥니다.
                          color: Theme.of(context).iconTheme.color,
                        ),
                        // 남은 공간을 모두 차지하는 위젯입니다.
                        Expanded(
                          // 텍스트를 입력받는 칸입니다.
                          child: TextField(
                            // 텍스트 칸의 내용을 관리하는 도구
                            controller: _dateController,
                            // 키보드를 관리하는 도구
                            focusNode: _focusNode,
                            // 입력 칸의 디자인
                            decoration: InputDecoration(
                              // 테두리를 없앱니다.
                              border: InputBorder.none,
                              // 글자가 없을 때 보여줄 힌트 메시지
                              hintText: 'YYYY-MM-DD',
                              // 힌트 메시지의 디자인
                              hintStyle: TextStyle(
                                // 글자 색깔을 테마에 맞게 흐리게 만듭니다.
                                color: Theme.of(context).textTheme.bodyMedium!.color!.withOpacity(0.5),
                              ),
                            ),
                            // 입력될 글자의 디자인
                            style: TextStyle(
                              // 글자 색깔을 테마에 맞춥니다.
                              color: Theme.of(context).textTheme.bodyMedium!.color,
                            ),
                            // 입력받을 키보드 타입을 숫자로 정합니다.
                            keyboardType: TextInputType.number,
                            // 글자를 가운데에 맞춥니다.
                            textAlign: TextAlign.center,
                            // 입력 칸을 누르면 실행되는 함수입니다.
                            onTap: () {
                              // 입력 칸의 모든 글자를 선택되게 합니다.
                              _dateController.selection = TextSelection(
                                baseOffset: 0,
                                extentOffset: _dateController.text.length,
                              );
                            },
                            // 글자 입력을 끝내고 제출할 때 실행되는 함수입니다.
                            onSubmitted: _handleDateInput,
                          ),
                        ),
                        // 다음 날짜로 가는 화살표 버튼입니다.
                        IconButton(
                          // 앞으로 가는 아이콘
                          icon: const Icon(Icons.arrow_forward_ios),
                          // 버튼을 눌렀을 때 날짜를 하루 늘리는 함수를 실행합니다.
                          onPressed: () => _changeDate(1),
                          // 아이콘 색깔을 테마에 맞춥니다.
                          color: Theme.of(context).iconTheme.color,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 달의 위상 카드를 만드는 함수입니다.
  Widget _buildMoonPhaseCard(AstroState provider) {
    // 카드의 배경이 될 컨테이너입니다.
    return Container(
      // 컨테이너의 디자인을 정합니다.
      decoration: BoxDecoration(
        // 그라데이션 배경을 사용합니다.
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.purple.withOpacity(0.8),
            Colors.indigo.withOpacity(0.6),
          ],
        ),
        // 모서리를 둥글게 만듭니다.
        borderRadius: BorderRadius.circular(24),
        // 그림자 효과를 줍니다.
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      // 컨테이너 안쪽에 여백을 줍니다.
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        // 위젯들을 세로로 나열하는 위젯입니다.
        child: Column(
          // 자식 위젯들을 여기에 넣어줍니다.
          children: [
            // 위젯들을 가로로 나열하는 위젯입니다.
            Row(
              // 자식 위젯들을 가운데로 정렬합니다.
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 달 아이콘입니다.
                Icon(
                  Icons.brightness_3,
                  color: Colors.white,
                  size: 32,
                ),
                // 아이콘과 텍스트 사이에 공간을 둡니다.
                const SizedBox(width: 12),
                // 'Moon Phase' 텍스트입니다.
                Text(
                  'Moon Phase',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            // 위젯 아래에 16만큼의 공간을 줍니다.
            const SizedBox(height: 16),
            // 달의 위상 정보를 보여주는 텍스트입니다.
            Text(
              provider.moonPhase,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // 일반적인 정보 카드를 만드는 함수입니다.
  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
  }) {
    // 카드의 배경이 될 컨테이너입니다.
    return Container(
      // 컨테이너의 디자인을 정합니다.
      decoration: BoxDecoration(
        // 그라데이션 배경을 사용합니다.
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).cardColor,
            Theme.of(context).cardColor.withOpacity(0.8),
          ],
        ),
        // 모서리를 둥글게 만듭니다.
        borderRadius: BorderRadius.circular(20),
        // 그림자 효과를 줍니다.
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      // ListTile은 정보를 리스트 형태로 보여주는 편리한 위젯입니다.
      child: ListTile(
        // 리스트의 여백을 정합니다.
        contentPadding: const EdgeInsets.all(20),
        // 리스트 왼쪽에 들어갈 위젯입니다.
        leading: CircleAvatar(
          // 원의 반지름을 25로 정합니다.
          radius: 25,
          // 배경색은 아이콘 색깔을 흐리게 만듭니다.
          backgroundColor: iconColor.withOpacity(0.1),
          // 아이콘을 원 안에 넣어줍니다.
          child: Icon(icon, color: iconColor, size: 28),
        ),
        // 리스트의 제목 텍스트입니다.
        title: Text(
          title,
          // 제목의 디자인을 정합니다.
          style: TextStyle(
            // 글자 색깔은 테마에 맞춥니다.
            color: Theme.of(context).textTheme.titleLarge?.color,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        // 리스트의 부제목 텍스트입니다.
        subtitle: Text(
          subtitle,
          // 부제목의 디자인을 정합니다.
          style: TextStyle(
            // 글자 색깔은 테마에 맞춥니다.
            color: Theme.of(context).textTheme.bodyMedium?.color,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}