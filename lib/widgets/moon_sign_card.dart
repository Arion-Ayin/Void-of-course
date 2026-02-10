import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/astro_state.dart';
import '../services/timezone_provider.dart';
import '../themes.dart';

class MoonSignCard extends StatelessWidget {
  final AstroState provider;

  const MoonSignCard({
    super.key,
    required this.provider,
  });

  static final _dateFormat = DateFormat('MM/dd HH:mm');

  String getZodiacEmoji(String sign) {
    switch (sign) {
      case 'Aries':
        return '♈︎';
      case 'Taurus':
        return '♉︎';
      case 'Gemini':
        return '♊︎';
      case 'Cancer':
        return '♋︎';
      case 'Leo':
        return '♌︎';
      case 'Virgo':
        return '♍︎';
      case 'Libra':
        return '♎︎';
      case 'Scorpio':
        return '♏︎';
      case 'Sagittarius':
        return '♐︎';
      case 'Capricorn':
        return '♑︎';
      case 'Aquarius':
        return '♒︎';
      case 'Pisces':
        return '♓︎';
      default:
        return '❔';
    }
  }

  Color _getSignColor(String sign, bool isDark) {
    // 원소별 색상 (불, 흙, 공기, 물)
    switch (sign) {
      case 'Aries':
      case 'Leo':
      case 'Sagittarius':
        return isDark ? const Color(0xFFE57373) : const Color(0xFFD32F2F); // 불
      case 'Taurus':
      case 'Virgo':
      case 'Capricorn':
        return isDark ? const Color(0xFFA1887F) : const Color(0xFF5D4037); // 흙
      case 'Gemini':
      case 'Libra':
      case 'Aquarius':
        return isDark ? const Color(0xFF90CAF9) : const Color(0xFF1976D2); // 공기
      case 'Cancer':
      case 'Scorpio':
      case 'Pisces':
        return isDark ? const Color(0xFF80DEEA) : const Color(0xFF00838F); // 물
      default:
        return isDark ? const Color(0xFFB8B5AD) : const Color(0xFF6B7280);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tzProvider = Provider.of<TimezoneProvider>(context);
    final nextSignTime = provider.nextSignTime != null
        ? tzProvider.convert(provider.nextSignTime!)
        : null;
    final formattedNextSignTime =
        nextSignTime != null
            ? _dateFormat.format(nextSignTime)
            : 'N/A';
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bodyColor = theme.textTheme.bodyLarge?.color;
    final signColor = _getSignColor(provider.moonInSign, isDark);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: Themes.cardGradient(isDark),
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [Themes.cardShadow(isDark)],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // 별자리 원소 색상 악센트
            Positioned(
              left: -30,
              bottom: -30,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      signColor.withValues(alpha: 0.15),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 별자리 심볼 영역
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: isDark
                            ? [
                                signColor.withValues(alpha: 0.3),
                                const Color(0xFF1E3A5F),
                              ]
                            : [
                                signColor.withValues(alpha: 0.15),
                                const Color(0xFFF0EDE5),
                              ],
                      ),
                    ),
                    child: Center(
                      child: Text(
                        getZodiacEmoji(provider.moonInSign),
                        style: TextStyle(
                          fontSize: 50,
                          color: signColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Moon in ${provider.moonInSign}',
                          style: TextStyle(
                            color: isDark ? Themes.gold : Themes.midnightBlue,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 1),
                        _buildTimeRow(
                          'Start',
                          provider.currentSignStartTime != null
                              ? _dateFormat.format(tzProvider.convert(provider.currentSignStartTime!))
                              : 'N/A',
                          isDark,
                          bodyColor,
                        ),
                        const SizedBox(height: 1),
                        _buildTimeRow(
                          'End',
                          formattedNextSignTime,
                          isDark,
                          bodyColor,
                        ),
                      ],
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

  Widget _buildTimeRow(String label, String time, bool isDark, Color? bodyColor) {
    final textStyle = TextStyle(
      color: bodyColor,
      fontSize: 16,
      fontWeight: FontWeight.w700,
    );
    return Row(
      children: [
        SizedBox(
          width: 38,
          child: Text(label, style: textStyle),
        ),
        Text(' : ', style: textStyle),
        Text(
          time,
          style: textStyle.copyWith(
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
