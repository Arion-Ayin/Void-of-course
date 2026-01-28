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
      padding: const EdgeInsets.all(5),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            height: 100,
            child: Center(
              child: Text(
                AstroCalculator().getMoonPhaseEmoji(provider.moonPhase),
                style: const TextStyle(
                  fontSize: 55,
                  color: Colors.white, // ⭐️ 이모지 색상을 흰색으로 지정
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
                  'Moon Phase',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.titleLarge?.color,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  AstroCalculator().getMoonPhaseNameOnly(provider.moonPhase),
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Start : ${phaseStartTime != null ? DateFormat('MM/dd HH:mm').format(phaseStartTime) : 'N/A'}\n'
                  'End  : ${phaseEndTime != null ? DateFormat('MM/dd HH:mm').format(phaseEndTime) : 'N/A'}',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
