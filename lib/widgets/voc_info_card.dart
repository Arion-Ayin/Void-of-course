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
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
    Color vocBgColor;

    if (isVocNow) {
      vocStatusText = "Void Now";
      vocColor = const Color(0xFFE53935);
      vocBgColor = isDark ? const Color(0xFF3D1F1F) : const Color(0xFFFFF0F0);
      vocIcon = '🚫';
    } else if (doesSelectedDateHaveVoc) {
      vocStatusText = "Void Today";
      vocIcon = '⚠️';
      vocColor = const Color(0xFFFF9800);
      vocBgColor = isDark ? const Color(0xFF3D2E1F) : const Color(0xFFFFF8E1);
    } else {
      vocStatusText = "Clear";
      vocIcon = '✅';
      vocColor = const Color(0xFF4CAF50);
      vocBgColor = isDark ? const Color(0xFF1F3D2A) : const Color(0xFFF0FFF4);
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  vocBgColor,
                  const Color(0xFF16213E),
                ]
              : [
                  vocBgColor,
                  Colors.white,
                ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : vocColor.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // 상태 색상 악센트
            Positioned(
              right: -40,
              top: -40,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      vocColor.withOpacity(0.2),
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
                  // 상태 아이콘 영역
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          vocColor.withOpacity(isDark ? 0.3 : 0.2),
                          vocColor.withOpacity(isDark ? 0.1 : 0.05),
                        ],
                      ),
                    ),
                    child: Center(
                      child: Text(
                        vocIcon,
                        style: const TextStyle(fontSize: 42),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
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
                                color: isDark
                                    ? const Color(0xFFD4AF37)
                                    : const Color(0xFF2C3E50),
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                            if (provider.vocAspect != null && provider.vocPlanet != null) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white.withOpacity(0.1)
                                      : Colors.black.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '${provider.vocAspect}',
                                      style: TextStyle(
                                        color: _getAspectColor(provider.vocAspect!),
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      ' ${provider.vocPlanet}',
                                      style: TextStyle(
                                        color: _getPlanetColor(provider.vocPlanet!),
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 1),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: vocColor.withOpacity(isDark ? 0.25 : 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            vocStatusText,
                            style: TextStyle(
                              color: vocColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 1),
                        _buildTimeRow(
                          context,
                          'Start',
                          _formatDateTime(provider.vocStart),
                          isDark,
                        ),
                        const SizedBox(height: 1),
                        _buildTimeRow(
                          context,
                          'End',
                          _formatDateTime(provider.vocEnd),
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

  Color _getAspectColor(String aspect) {
    if (['☌', '□', '☍'].contains(aspect)) {
      return const Color(0xFFE53935); // Hard aspects - Red
    }
    if (['✶', '△'].contains(aspect)) {
      return const Color(0xFF2196F3); // Soft aspects - Blue
    }
    return const Color(0xFF9E9E9E);
  }

  Color _getPlanetColor(String planet) {
    switch (planet) {
      case '☉':
        return const Color(0xFFFF9800); // Sun - Orange
      case '☾':
        return const Color(0xFF9E9E9E); // Moon - Silver
      case '☿':
        return const Color(0xFF9C27B0); // Mercury - Purple
      case '♀':
        return const Color(0xFF4CAF50); // Venus - Green
      case '♂':
        return const Color(0xFFE53935); // Mars - Red
      case '♃':
        return const Color(0xFF3F51B5); // Jupiter - Indigo
      case '♄':
        return const Color(0xFF795548); // Saturn - Brown
      case '♅':
        return const Color(0xFF00BCD4); // Uranus - Cyan
      case '♆':
        return const Color(0xFF2196F3); // Neptune - Blue
      case '⯓':
        return const Color(0xFF673AB7); // Pluto - Deep Purple
      default:
        return const Color(0xFF9E9E9E);
    }
  }
}
