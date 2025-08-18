import 'package:flutter/material.dart';
import 'package:lioluna/utils/flushbar_helper.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../services/astro_state.dart';
import '../themes.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _dateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<AstroState>(context, listen: false);

    if (!provider.isInitialized) {
      Future.microtask(() => provider.initialize());
    }
  }

  void _showCalendar() {
    final provider = Provider.of<AstroState>(context, listen: false);
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            child: SizedBox(
              width: 1000,
              height: 450,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TableCalendar(
                  focusedDay: provider.selectedDate,
                  firstDay: DateTime(1900),
                  lastDay: DateTime(2100),
                  calendarFormat: CalendarFormat.month,
                  availableCalendarFormats: const {
                    CalendarFormat.month: 'Month',
                  },
                  headerStyle: const HeaderStyle(
                    titleCentered: true, // 헤더 제목을 가운데 정렬
                  ),
                  selectedDayPredicate:
                      (day) => isSameDay(provider.selectedDate, day),
                  onDaySelected: (selectedDay, focusedDay) {
                    provider.updateDate(selectedDay);
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ),
          ),
    );
  }

  void _changeDate(int days) {
    if (mounted) {
      final provider = Provider.of<AstroState>(context, listen: false);
      final newDate = provider.selectedDate.add(Duration(days: days));
      provider.updateDate(newDate);
    }
  }

  @override
  void dispose() {
    _dateController.dispose();
    super.dispose();
  }

  void _resetDateToToday() {
    if (mounted) {
      final provider = Provider.of<AstroState>(context, listen: false);
      provider.updateDate(DateTime.now());
    }
  }

  String getZodiacEmoji(String sign) {
    switch (sign) {
      case 'Aries':
        return '♈';
      case 'Taurus':
        return '♉';
      case 'Gemini':
        return '♊';
      case 'Cancer':
        return '♋';
      case 'Leo':
        return '♌';
      case 'Virgo':
        return '♍';
      case 'Libra':
        return '♎';
      case 'Scorpio':
        return '♏';
      case 'Sagittarius':
        return '♐';
      case 'Capricorn':
        return '♑';
      case 'Aquarius':
        return '♒';
      case 'Pisces':
        return '♓';
      default:
        return '❔';
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AstroState>(context);
    _dateController.text = DateFormat(
      'yyyy-MM-dd',
    ).format(provider.selectedDate);

    if (!provider.isInitialized || provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.lastError != null) {
      return Center(child: Text('Error: ${provider.lastError}'));
    }

    String _formatDateTime(DateTime? dateTime) {
      if (dateTime == null) return 'N/A';
      return DateFormat('yyyy-MM-dd HH:mm').format(dateTime);
    }

    final nextSignTimeText =
        provider.nextSignTime != null
            ? 'Next Sign : ${DateFormat('yyyy-MM-dd HH:mm').format(provider.nextSignTime!)}'
            : 'Next Sign : N/A';

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(
              Icons.star,
              color: Theme.of(context).colorScheme.secondary,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              'Void of Course',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        elevation: Theme.of(context).appBarTheme.elevation,
        actions: [],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        constraints: const BoxConstraints.expand(),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.background,
              Theme.of(context).colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 600),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildMoonPhaseCard(provider),
                  const SizedBox(height: 16),
                  _buildMoonSignCard(provider, nextSignTimeText),
                  const SizedBox(height: 16),
                  _buildInfoCard(
                    icon: Icons.timelapse,
                    title: 'Void of Course',
                    subtitle:
                        '시작: ${_formatDateTime(provider.vocStart)}\n'
                        '종료: ${_formatDateTime(provider.vocEnd)}',
                    iconColor: Colors.teal,
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 10),
                      ],
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios),
                          onPressed: () => _changeDate(-1),
                          color: Theme.of(context).iconTheme.color,
                        ),
                        Expanded(
                          child: TextField(
                            controller: _dateController,
                            readOnly: true,
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: 'YYYY-MM-DD',
                              hintStyle: TextStyle(
                                color: Theme.of(
                                  context,
                                ).textTheme.bodyMedium!.color!.withOpacity(0.5),
                              ),
                            ),
                            style: TextStyle(
                              color:
                                  Theme.of(context).textTheme.bodyMedium!.color,
                            ),
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            onTap: _showCalendar,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.arrow_forward_ios),
                          onPressed: () => _changeDate(1),
                          color: Theme.of(context).iconTheme.color,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.center,
                    child: SizedBox(
                      width: 70, // 너비를 50으로 설정
                      height: 70, // 높이를 50으로 설정
                      child: ElevatedButton(
                        onPressed: _resetDateToToday,
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.zero, // 내부 여백을 없앰
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              25,
                            ), // 높이의 절반(50/2)으로 설정해 원형으로 만듦
                          ),
                        ),
                        child: const Icon(Icons.refresh, size: 30), // 아이콘만 남김
                      ),
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

  Widget _buildMoonPhaseCard(AstroState provider) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.purple.withOpacity(0.8),
            Colors.indigo.withOpacity(0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.brightness_3, color: Colors.white, size: 32),
                const SizedBox(width: 12),
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
            const SizedBox(height: 16),
            Text(
              provider.moonPhase,
              style: const TextStyle(color: Colors.white, fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Next Phase : ${provider.nextSignTime != null ? DateFormat('MM-dd HH:mm').format(provider.nextSignTime!) : 'N/A'}',
              style: const TextStyle(color: Colors.white, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoonSignCard(AstroState provider, String nextSignTimeText) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).cardColor,
            Theme.of(context).cardColor.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Text(
              getZodiacEmoji(provider.moonInSign),
              style: const TextStyle(fontSize: 30),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Moon in ${provider.moonInSign}',
                    style: TextStyle(
                      color: Theme.of(context).textTheme.titleLarge?.color,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    nextSignTimeText,
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).cardColor,
            Theme.of(context).cardColor.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(20),
        leading: CircleAvatar(
          radius: 25,
          backgroundColor: iconColor.withOpacity(0.1),
          child: Icon(icon, color: iconColor, size: 28),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start, // 텍스트를 왼쪽으로 정렬
          children: [
            Text(
              title,
              style: TextStyle(
                color: Theme.of(context).textTheme.titleLarge?.color,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4), // 제목과 추가 텍스트 사이 간격
            Text(
              '새롭게 추가할 텍스트입니다.', // 여기에 원하는 텍스트를 넣으세요.
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            // subtitle은 Column 아래에 자동으로 위치하므로 별도 조정이 필요 없습니다.
          ],
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyMedium?.color,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
