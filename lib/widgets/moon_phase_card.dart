import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/astro_state.dart';
import '../services/astro_calculator.dart';

class MoonPhaseCard extends StatelessWidget {
  final AstroState provider;

  const MoonPhaseCard({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
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
        contentPadding: const EdgeInsets.all(8),
        leading: SizedBox(
          width: 60,
          height: 60,
          child: Center(
            child: Text(
              AstroCalculator().getMoonPhaseEmoji(provider.moonPhase),
              style: const TextStyle(fontSize: 40),
            ),
          ),
        ),
        title: Column(
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
              // nextSignTime 대신 nextMoonPhaseTime을 사용하도록 수정
              '다음 상태 : ${provider.nextMoonPhaseTime != null ? DateFormat('MM월 dd일 HH:mm').format(provider.nextMoonPhaseTime!) : 'N/A'}',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color,
                fontSize: 17,
              ),
            ),
          ],
        ),
      ),
    );
  }
}