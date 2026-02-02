import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/astro_state.dart';

class MoonSignCard extends StatelessWidget {
  final AstroState provider;

  const MoonSignCard({
    super.key,
    required this.provider,
  });

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
    final nextSignTime = provider.nextSignTime?.toLocal();
    final formattedNextSignTime =
        nextSignTime != null
            ? DateFormat('MM/dd HH:mm').format(nextSignTime)
            : 'N/A';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final signColor = _getSignColor(provider.moonInSign, isDark);

    return Container(
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
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
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
                      signColor.withOpacity(0.15),
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
                                signColor.withOpacity(0.3),
                                const Color(0xFF1E3A5F),
                              ]
                            : [
                                signColor.withOpacity(0.15),
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
                          'Moon in',
                          style: TextStyle(
                            color: isDark
                                ? const Color(0xFFD4AF37)
                                : const Color(0xFF2C3E50),
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          provider.moonInSign,
                          style: TextStyle(
                            color: Theme.of(context).textTheme.titleLarge?.color,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 1),
                        _buildTimeRow(
                          context,
                          'Start',
                          provider.currentSignStartTime != null
                              ? DateFormat('MM/dd HH:mm').format(provider.currentSignStartTime!.toLocal())
                              : 'N/A',
                          isDark,
                        ),
                        const SizedBox(height: 1),
                        _buildTimeRow(
                          context,
                          'End',
                          formattedNextSignTime,
                          isDark,
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

  Widget _buildTimeRow(BuildContext context, String label, String time, bool isDark) {
    return Row(
      children: [
        SizedBox(
          width: 40,
          child: Text(
            label,
            style: TextStyle(
              color: isDark
                  ? const Color(0xFFB8B5AD)
                  : const Color(0xFF6B7280),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          time,
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyLarge?.color,
            fontSize: 15,
            fontWeight: FontWeight.w700,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
