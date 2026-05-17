import 'package:flutter/material.dart';

/// زر رجوع موحّد بنفس نمط صفحة الإشعارات.
class AppBackButton extends StatelessWidget {
  const AppBackButton({
    super.key,
    this.onTap,
    this.size = 40,
    this.iconSize = 24,
    this.backgroundColor = const Color(0xFFEFF4FF),
    this.iconColor = const Color(0xFF215CD6),
  });

  final VoidCallback? onTap;
  final double size;
  final double iconSize;
  final Color backgroundColor;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap ?? () => Navigator.of(context).maybePop(),
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(
            Icons.chevron_right_rounded,
            size: iconSize,
            color: iconColor,
          ),
        ),
      ),
    );
  }
}
