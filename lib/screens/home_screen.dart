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

  @override
  void dispose() {
    _dateController.dispose();
    super.dispose();
  }

  void _changeDate(int days) {
    if (mounted) {
      final provider = Provider.of<AstroState>(context, listen: false);
      final newDate = provider.selectedDate.add(Duration(days: days));
      provider.updateDate(newDate);
    }
  }

  void _resetDateToToday() {
    if (mounted) {
      final provider = Provider.of<AstroState>(context, listen: false);
      provider.updateDate(DateTime.now());

      final locale = Localizations.localeOf(context).languageCode;
      final message =
          locale == 'ko' ? '오늘 날짜로 재설정되었습니다.' : 'Date has been reset to today.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AstroState>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    _dateController.text = DateFormat('yyyy/MM/dd').format(provider.selectedDate.toLocal());

    if (!provider.isInitialized) {
      return Center(
        child: CircularProgressIndicator(
          color: isDark ? const Color(0xFFD4AF37) : const Color(0xFF2C3E50),
        ),
      );
    }
    if (provider.lastError != null) {
      return Center(child: Text('Error: ${provider.lastError}'));
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(
              Icons.auto_awesome,
              color: isDark ? const Color(0xFFD4AF37) : const Color(0xFF2C3E50),
              size: 22,
            ),
            const SizedBox(width: 10),
            Text(
              'Void of Course',
              style: Theme.of(context).appBarTheme.titleTextStyle,
            ),
          ],
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        elevation: 0,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [
                    const Color(0xFF0F0F1A),
                    const Color(0xFF1A1A2E),
                    const Color(0xFF16213E),
                  ]
                : [
                    const Color(0xFFF8F6F0),
                    const Color(0xFFFFFDF8),
                    const Color(0xFFF0EDE5),
                  ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                MoonPhaseCard(provider: provider),
                const SizedBox(height: 4),
                MoonSignCard(provider: provider),
                const SizedBox(height: 4),
                VocInfoCard(provider: provider),
                const SizedBox(height: 4),
                DateSelector(
                  dateController: _dateController,
                  onPreviousDay: () => _changeDate(-1),
                  onNextDay: () => _changeDate(1),
                  showCalendar: () => showCalendarDialog(context),
                ),
                const SizedBox(height: 7),
                ResetDateButton(onPressed: _resetDateToToday),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
