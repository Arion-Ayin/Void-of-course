import 'package:flutter/material.dart';
import 'package:void_of_course/services/ad_service.dart';

class ResetDateButton extends StatefulWidget {
  final VoidCallback onPressed;

  const ResetDateButton({super.key, required this.onPressed});

  @override
  State<ResetDateButton> createState() => _ResetDateButtonState();
}

class _ResetDateButtonState extends State<ResetDateButton> {
  final AdService _adService = AdService();

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
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    const Color(0xFFD4AF37),
                    const Color(0xFFB8960C),
                  ]
                : [
                    const Color(0xFF2C3E50),
                    const Color(0xFF1A252F),
                  ],
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? const Color(0xFFD4AF37).withOpacity(0.3)
                  : const Color(0xFF2C3E50).withOpacity(0.3),
              blurRadius: 5,
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
            borderRadius: BorderRadius.circular(24),
            child: const Center(
              child: Icon(
                Icons.refresh_rounded,
                size: 35,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
