import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/astro_state.dart';

class VocInfoCard extends StatelessWidget {
  final AstroState provider;

  const VocInfoCard({super.key, required this.provider});

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'N/A';
    return DateFormat('MM/dd HH:mm').format(dateTime.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final vocStart = provider.vocStart;
    final vocEnd = provider.vocEnd;
    final now = DateTime.now().toUtc();
    final selectedDate = provider.selectedDate;

    bool isVocNow = false;
    if (vocStart != null && vocEnd != null) {
      isVocNow = now.isAfter(vocStart) && now.isBefore(vocEnd);
    }

    bool doesSelectedDateHaveVoc = false;
    if (vocStart != null && vocEnd != null) {
      final selectedDayStart =
          selectedDate.isUtc
              ? DateTime.utc(
                selectedDate.year,
                selectedDate.month,
                selectedDate.day,
              )
              : DateTime(
                selectedDate.year,
                selectedDate.month,
                selectedDate.day,
              );
      final selectedDayEnd = selectedDayStart.add(const Duration(days: 1));

      if (vocStart.isBefore(selectedDayEnd) &&
          vocEnd.isAfter(selectedDayStart)) {
        doesSelectedDateHaveVoc = true;
      }
    }

    String vocStatusText;
    String vocIcon;
    Color vocColor;

    if (isVocNow) {
      vocStatusText = "There's a void Now";
      vocColor = const Color.fromRGBO(252, 17, 0, 1);
      vocIcon = '🚫';
    } else if (doesSelectedDateHaveVoc) {
      vocStatusText = "There's a void today";
      vocIcon = '🔔';
      vocColor = Colors.orange;
    } else {
      vocStatusText = "It's not a void";
      vocIcon = '✅';
      vocColor = const Color.fromARGB(255, 72, 189, 76);
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
      padding: const EdgeInsets.all(5), // ⭐️ 전체 컨테이너에 충분한 패딩을 줍니다.
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.center, // ⭐️ Row의 자식들을 수직 중앙 정렬합니다.
        children: [
          // ⭐️ 아이콘 부분을 담당하는 SizedBox와 Text 위젯
          SizedBox(
            width: 90, // 아이콘의 컨테이너 너비를 충분히 확보합니다.
            height: 100, // 아이콘의 컨테이너 높이를 충분히 확보합니다.
            child: Center(
              child: Text(
                vocIcon,
                style: TextStyle(
                  fontSize: 55, // ⭐️ 아이콘의 크기를 더 크게 설정합니다.
                  color: vocColor, // ⭐️ 상태에 따라 아이콘 색상을 적용합니다.
                ),
              ),
            ),
          ),
          const SizedBox(width: 16), // ⭐️ 아이콘과 텍스트 사이의 간격을 줍니다.
          // ⭐️ 텍스트 부분을 담당하는 Expanded와 Column 위젯
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      'Void of Course',
                      style: TextStyle(
                        color: Theme.of(context).textTheme.titleLarge?.color,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (provider.vocAspect != null &&
                        provider.vocPlanet != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        '${provider.vocAspect}',
                        style: TextStyle(
                          color: _getAspectColor(provider.vocAspect!),
                          fontSize: 16,
                          fontWeight: _getAspectFontWeight(provider.vocAspect!),
                        ),
                      ),
                      Text(
                        ', ',
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.color?.withOpacity(0.7),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${provider.vocPlanet}',
                        style: TextStyle(
                          color: _getPlanetColor(provider.vocPlanet!),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 1),
                Text(
                  'Start : ${_formatDateTime(provider.vocStart)}\n'
                  'End  : ${_formatDateTime(provider.vocEnd)}',
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
        ],
      ),
    );
  }

  Color _getAspectColor(String aspect) {
    // Hard aspects: Conjunction (☌), Square (▢), Opposition (☍) -> Red
    if (['☌', '□', '☍'].contains(aspect)) {
      return const Color.fromARGB(255, 255, 0, 0);
    }
    // Soft aspects: Sextile (✶), Trine (▵) -> Blue
    if (['✶', '△'].contains(aspect)) {
      return const Color.fromARGB(255, 0, 0, 255);
    }
    return Colors.grey;
  }

  Color _getPlanetColor(String planet) {
    switch (planet) {
      case '☉': // Sun
        return Colors.brown;
      case '☾': // Moon
        return Colors.brown;
      case '☿': // Mercury
        return Colors.purple;
      case '♀': // Venus
        return const Color(0xFF00C4B4); // Mint (Teal-ish)
      case '♂': // Mars
        return Colors.red;
      case '♃': // Jupiter
        return Colors.grey[800]!; // Dark Grey
      case '♄': // Saturn
        return const Color(0xFFA52A2A); // Reddish Brown
      case '♅': // Uranus
        return const Color.fromARGB(223, 12, 26, 223); // Mint
      case '♆': // Neptune
        return const Color(0xFF00C4B4); // Mint
      case '⯓': // Pluto
        return const Color(0xFFA52A2A); // Reddish Brown
      default:
        return Colors.grey;
    }
  }
}

FontWeight _getAspectFontWeight(String aspect) {
  return FontWeight.w900;
}
