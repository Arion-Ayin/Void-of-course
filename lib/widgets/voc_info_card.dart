// voc_info_card.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/astro_state.dart';

class VocInfoCard extends StatelessWidget {
  final AstroState provider;

  const VocInfoCard({
    super.key,
    required this.provider,
  });

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'N/A';
    return DateFormat('MM월 dd일 HH:mm').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    final vocStart = provider.vocStart;
    final vocEnd = provider.vocEnd;
    final now = DateTime.now();
    final selectedDate = provider.selectedDate;

    // 현재 시간이 보이드 구간에 있는지 확인
    bool isVocNow = false;
    if (vocStart != null && vocEnd != null) {
      isVocNow = now.isAfter(vocStart) && now.isBefore(vocEnd);
    }

    // 선택한 날짜에 보이드가 포함되어 있는지 확인 (과거, 현재, 미래 모두)
    bool doesSelectedDateHaveVoc = false;
    if (vocStart != null && vocEnd != null) {
      final selectedDayStart =
          DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
      final selectedDayEnd = selectedDayStart.add(const Duration(days: 1));

      // selectedDate 하루 전체(00:00 ~ 23:59)와 vocStart-vocEnd 기간이 겹치는지 확인
      if (vocStart.isBefore(selectedDayEnd) && vocEnd.isAfter(selectedDayStart)) {
        doesSelectedDateHaveVoc = true;
      }
    }

    String vocStatusText;
    String vocIcon;
    Color vocColor;

    if (isVocNow) {
      vocStatusText = '보이드 입니다';
      vocIcon = '🚫';
      vocColor = Colors.red;
    } else if (doesSelectedDateHaveVoc) {
      vocStatusText = '금일 보이드가 있습니다.';
      vocIcon = '🔔';
      vocColor = Colors.orange;
    } else {
      vocStatusText = '보이드가 아닙니다';
      vocIcon = '✅';
      vocColor = Colors.green;
    }

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
              vocIcon,
              style: const TextStyle(
                fontSize: 40,
              ),
            ),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Void of Course',
              style: TextStyle(
                color: Theme.of(context).textTheme.titleLarge?.color,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              '시작 : ${_formatDateTime(provider.vocStart)}\n'
              '종료 : ${_formatDateTime(provider.vocEnd)}',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              vocStatusText,
              style: TextStyle(
                color: vocColor,
                fontSize: 19,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
