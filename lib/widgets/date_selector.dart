import 'package:flutter/material.dart';

class DateSelector extends StatelessWidget {
  final TextEditingController dateController;
  final VoidCallback showCalendar;
  final VoidCallback onNextDay;
  final VoidCallback onPreviousDay;

  const DateSelector({
    super.key,
    required this.dateController,
    required this.showCalendar,
    required this.onNextDay,
    required this.onPreviousDay,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal : 10 ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF1E3A5F),
                  const Color(0xFF16213E),
                ]
              : [
                  Colors.white,
                  const Color(0xFFF8F6F0),
                ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          // 이전 날짜 버튼
          _buildNavButton(
            context,
            Icons.chevron_left_rounded,
            onPreviousDay,
            isDark,
          ),
          // 날짜 표시 영역
          Expanded(
            child: GestureDetector(
              onTap: showCalendar,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 1),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.05)
                      : Colors.black.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 18,
                      color: isDark
                          ? const Color(0xFFD4AF37)
                          : const Color(0xFF2C3E50),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      dateController.text,
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
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
            onNextDay,
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildNavButton(
    BuildContext context,
    IconData icon,
    VoidCallback onPressed,
    bool isDark,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.08)
                : Colors.black.withOpacity(0.04),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            size: 50,
            color: isDark
                ? const Color(0xFFD4AF37)
                : const Color(0xFF2C3E50),
          ),
        ),
      ),
    );
  }
}
