import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:timezone/timezone.dart' as tz;
import '../services/astro_state.dart';
import '../services/timezone_provider.dart';
import '../themes.dart';

class VocInfoCard extends StatefulWidget {
  final AstroState provider;

  const VocInfoCard({super.key, required this.provider});

  @override
  State<VocInfoCard> createState() => _VocInfoCardState();
}

class _VocInfoCardState extends State<VocInfoCard> {
  static final _dateFormat = DateFormat('MM/dd HH:mm');

  String _formatDateTime(DateTime? dateTime, TimezoneProvider tzProvider) {
    if (dateTime == null) return 'N/A';
    return _dateFormat.format(tzProvider.convert(dateTime));
  }

  @override
  Widget build(BuildContext context) {
    final tzProvider = Provider.of<TimezoneProvider>(context);
    final vocStart = widget.provider.vocStart;
    final vocEnd = widget.provider.vocEnd;
    final now = DateTime.now().toUtc();
    final selectedDate = widget.provider.selectedDate;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bodyColor = theme.textTheme.bodyLarge?.color;

    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 380;
    final iconSize = isCompact ? 66.0 : 82.0;
    final emojiSize = isCompact ? 42.0 : 52.0;
    final cardPadding = isCompact ? 10.0 : 12.0;
    final iconGap = isCompact ? 12.0 : 16.0;
    final titleSize = isCompact ? 15.0 : 17.0;
    final statusSize = isCompact ? 14.0 : 16.0;
    final badgeSize = isCompact ? 13.0 : 15.0;

    bool isVocNow = false;
    if (vocStart != null && vocEnd != null) {
      isVocNow = now.isAfter(vocStart) && now.isBefore(vocEnd);
    }

    bool doesSelectedDateHaveVoc = false;
    if (vocStart != null && vocEnd != null) {
      // 선택된 타임존 기준으로 날짜 경계를 결정 (기기 타임존이 아닌)
      final location = tz.getLocation(tzProvider.selectedTimezoneId);
      late final tz.TZDateTime selectedDayStart;
      if (widget.provider.isFollowingTime) {
        // 실시간 모드: UTC를 선택된 타임존으로 변환하여 정확한 날짜 결정
        final tzNow = tz.TZDateTime.from(now, location);
        selectedDayStart = tz.TZDateTime(location, tzNow.year, tzNow.month, tzNow.day);
      } else {
        // 날짜 선택 모드: 사용자가 선택한 날짜를 그대로 사용
        selectedDayStart = tz.TZDateTime(location, selectedDate.year, selectedDate.month, selectedDate.day);
      }
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
      vocIcon = '🔔';
      vocColor = const Color.fromARGB(255, 235, 88, 4);
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
              ? [vocBgColor, const Color(0xFF16213E)]
              : [vocBgColor, Colors.white],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : vocColor.withValues(alpha: 0.15),
            blurRadius: 15,
            offset: const Offset(0, 5),
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
                      vocColor.withValues(alpha: 0.2),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(cardPadding),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 상태 아이콘 영역
                  Container(
                    width: iconSize,
                    height: iconSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        center: Alignment(0.0, -0.3),
                        colors: [
                          vocColor.withValues(alpha: isDark ? 0.3 : 0.2),
                          vocColor.withValues(alpha: isDark ? 0.1 : 0.05),
                        ],
                      ),
                      boxShadow: isVocNow
                          ? [
                              BoxShadow(
                                color: vocColor.withValues(alpha: 0.4),
                                blurRadius: 15,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        vocIcon,
                        style: TextStyle(fontSize: emojiSize),
                      ),
                    ),
                  ),
                  SizedBox(width: iconGap),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              'Void of Course',
                              style: TextStyle(
                                color: isDark ? Themes.gold : Themes.midnightBlue,
                                fontSize: titleSize,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                            if (widget.provider.vocAspect != null &&
                                widget.provider.vocPlanet != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.1)
                                      : Colors.black.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '${widget.provider.vocAspect}',
                                      style: TextStyle(
                                        color: _getAspectColor(
                                            widget.provider.vocAspect!),
                                        fontSize: badgeSize,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      ' ${widget.provider.vocPlanet}',
                                      style: TextStyle(
                                        color: _getPlanetColor(
                                            widget.provider.vocPlanet!),
                                        fontSize: badgeSize,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 1),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: vocColor.withValues(alpha: isDark ? 0.25 : 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            vocStatusText,
                            style: TextStyle(
                              color: vocColor,
                              fontSize: statusSize,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 1),
                        _buildTimeRow(
                          'Start',
                          _formatDateTime(widget.provider.vocStart, tzProvider),
                          isDark,
                          bodyColor,
                          isCompact,
                        ),
                        const SizedBox(height: 1),
                        _buildTimeRow(
                          'End',
                          _formatDateTime(widget.provider.vocEnd, tzProvider),
                          isDark,
                          bodyColor,
                          isCompact,
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

  Widget _buildTimeRow(
      String label, String time, bool isDark, Color? bodyColor, bool isCompact) {
    final textStyle = TextStyle(
      color: bodyColor,
      fontSize: isCompact ? 14.0 : 16.0,
      fontWeight: FontWeight.w700,
    );
    return Row(
      children: [
        SizedBox(
          width: isCompact ? 40.0 : 55.0,
          child: Text(label, style: textStyle),
        ),
        Text(' : ', style: textStyle),
        Expanded(
          child: Text(
            time,
            style: textStyle.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }

  Color _getAspectColor(String aspect) {
    if (['☌', '□', '☍'].contains(aspect)) {
      return const Color.fromARGB(255, 255, 4, 0); // Hard aspects - Red
    }
    if (['✶', '△'].contains(aspect)) {
      return const Color.fromARGB(255, 4, 0, 250); // Soft aspects - Blue
    }
    return const Color(0xFF9E9E9E);
  }

  Color _getPlanetColor(String planet) {
    switch (planet) {
      case '☉':
        return const Color.fromARGB(255, 209, 98, 46);
      case '☾':
        return const Color.fromARGB(232, 158, 158, 158);
      case '☿':
        return const Color(0xFF9C27B0);
      case '♀':
        return const Color.fromARGB(255, 2, 245, 245);
      case '♂':
        return const Color.fromARGB(255, 255, 4, 0);
      case '♃':
        return const Color.fromARGB(255, 73, 73, 73);
      case '♄':
        return const Color.fromARGB(255, 99, 0, 0);
      case '♅':
        return const Color.fromARGB(255, 35, 67, 250);
      case '♆':
        return const Color.fromARGB(255, 0, 141, 177);
      case '⯓':
        return const Color.fromARGB(255, 63, 0, 0);
      default:
        return const Color(0xFF9E9E9E);
    }
  }
}
