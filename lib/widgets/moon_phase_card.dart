import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/astro_state.dart';
import '../services/astro_calculator.dart';
import '../services/timezone_provider.dart';
import '../themes.dart';

class MoonPhaseCard extends StatelessWidget {
  final AstroState provider;

  const MoonPhaseCard({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    final tzProvider = Provider.of<TimezoneProvider>(context);
    final phaseStartTime = provider.moonPhaseStartTime != null
        ? tzProvider.convert(provider.moonPhaseStartTime!)
        : null;
    final phaseEndTime = provider.moonPhaseEndTime != null
        ? tzProvider.convert(provider.moonPhaseEndTime!)
        : null;
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                        Themes.gold.withValues(alpha: 0.1),
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
                            color: isDark ? Themes.gold : Themes.midnightBlue,
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
    final textStyle = TextStyle(
      color: Theme.of(context).textTheme.bodyLarge?.color,
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
