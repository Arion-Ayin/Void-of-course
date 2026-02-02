import 'package:flutter/material.dart';
import 'package:void_of_course/services/ad_service.dart';
import '../themes.dart';

class ResetDateButton extends StatefulWidget {
  final VoidCallback onPressed;

  const ResetDateButton({super.key, required this.onPressed});

  @override
  State<ResetDateButton> createState() => _ResetDateButtonState();
}

class _ResetDateButtonState extends State<ResetDateButton> {
  final AdService _adService = AdService();
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _adService.initialize();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedScale(
          scale: _isPressed ? 0.9 : 1.0,
          duration: const Duration(milliseconds: 100),
          child: Container(
            width: 65,
            height: 65,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [Themes.gold, const Color(0xFFB8960C)]
                    : [Themes.midnightBlue, const Color(0xFF1A252F)],
              ),
              boxShadow: [
                BoxShadow(
                  color: (isDark ? Themes.gold : Themes.midnightBlue)
                      .withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  widget.onPressed();
                  _adService.showAdIfNeeded(() {});
                },
                borderRadius: BorderRadius.circular(30),
                splashColor: Colors.white.withValues(alpha: 0.3),
                highlightColor: Colors.white.withValues(alpha: 0.1),
                child: const Center(
                  child: Icon(
                    Icons.refresh_rounded,
                    size: 45,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
