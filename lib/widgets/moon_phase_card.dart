import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/astro_state.dart';
import '../services/astro_calculator.dart';

class MoonPhaseCard extends StatelessWidget {
  final AstroState provider;

  const MoonPhaseCard({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    final phaseStartTime = provider.moonPhaseStartTime?.toLocal();
    final phaseEndTime = provider.moonPhaseEndTime?.toLocal();
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
            // 미세한 장식 원 (달빛 효과)
            if (isDark)
              Positioned(
                right: -20,
                top: -20,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFFD4AF37).withOpacity(0.1),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // 달 이모지 영역
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: isDark
                            ? [
                                const Color(0xFF2A4A6E),
                                const Color(0xFF1E3A5F),
                              ]
                            : [
                                const Color(0xFFF0EDE5),
                                const Color.fromARGB(255, 243, 242, 241),
                              ],
                      ),
                    ),
                    child: Center(
                      child: Text(
                        AstroCalculator().getMoonPhaseEmoji(provider.moonPhase),
                        style: const TextStyle(fontSize: 50),
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
                          'Moon Phase',
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
                          AstroCalculator().getMoonPhaseNameOnly(provider.moonPhase),
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
                          phaseStartTime != null
                              ? DateFormat('MM/dd HH:mm').format(phaseStartTime)
                              : 'N/A',
                          isDark,
                        ),
                        const SizedBox(height: 1),
                        _buildTimeRow(
                          context,
                          'End',
                          phaseEndTime != null
                              ? DateFormat('MM/dd HH:mm').format(phaseEndTime)
                              : 'N/A',
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
