import 'package:flutter/material.dart';
import '../themes.dart';

class DateSelector extends StatefulWidget {
  final TextEditingController dateController;
  final VoidCallback showCalendar;
  final VoidCallback onNextDay;
  final VoidCallback onPreviousDay;
  final DateTime selectedDate;

  const DateSelector({
    super.key,
    required this.dateController,
    required this.showCalendar,
    required this.onNextDay,
    required this.onPreviousDay,
    required this.selectedDate,
  });

  @override
  State<DateSelector> createState() => _DateSelectorState();
}

class _DateSelectorState extends State<DateSelector> {
  bool _isPrevPressed = false;
  bool _isNextPressed = false;

  bool get _isToday {
    final now = DateTime.now();
    return widget.selectedDate.year == now.year &&
        widget.selectedDate.month == now.month &&
        widget.selectedDate.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: Themes.cardGradient(isDark),
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [Themes.cardShadow(isDark)],
      ),
      child: Row(
        children: [
          // 이전 날짜 버튼
          _buildNavButton(
            context,
            Icons.chevron_left_rounded,
            widget.onPreviousDay,
            isDark,
            isPrev: true,
          ),
          // 날짜 표시 영역
          Expanded(
            child: GestureDetector(
              onTap: widget.showCalendar,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 1),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 18,
                      color: _isToday
                          ? Themes.gold
                          : (isDark ? Themes.gold : Themes.midnightBlue),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      widget.dateController.text,
                      style: TextStyle(
                        color: _isToday
                            ? Themes.gold
                            : Theme.of(context).textTheme.bodyLarge?.color,
                        fontSize: 17,
                        fontWeight: _isToday ? FontWeight.w700 : FontWeight.w600,
                        letterSpacing: 1,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // 다음 날짜 버튼
          _buildNavButton(
            context,
            Icons.chevron_right_rounded,
            widget.onNextDay,
            isDark,
            isPrev: false,
          ),
        ],
      ),
    );
  }

  Widget _buildNavButton(
    BuildContext context,
    IconData icon,
    VoidCallback onPressed,
    bool isDark, {
    required bool isPrev,
  }) {
    final isPressed = isPrev ? _isPrevPressed : _isNextPressed;

    return GestureDetector(
      onTapDown: (_) => setState(() {
        if (isPrev) {
          _isPrevPressed = true;
        } else {
          _isNextPressed = true;
        }
      }),
      onTapUp: (_) => setState(() {
        if (isPrev) {
          _isPrevPressed = false;
        } else {
          _isNextPressed = false;
        }
      }),
      onTapCancel: () => setState(() {
        if (isPrev) {
          _isPrevPressed = false;
        } else {
          _isNextPressed = false;
        }
      }),
      child: AnimatedScale(
        scale: isPressed ? 0.9 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(12),
            splashColor: (isDark ? Themes.gold : Themes.midnightBlue).withValues(alpha: 0.3),
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 50,
                color: isDark ? Themes.gold : Themes.midnightBlue,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
