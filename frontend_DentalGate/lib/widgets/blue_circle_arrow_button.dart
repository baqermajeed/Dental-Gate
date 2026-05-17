import 'package:flutter/material.dart';

/// زر دائري مع سهم بحواف دائرية — نمط ممتلئ (التالي) أو محدد (الرجوع).
class BlueCircleArrowButton extends StatelessWidget {
  const BlueCircleArrowButton({
    super.key,
    required this.onTap,
    this.size = 50,
    this.arrowPointsLeft = true,
    this.color = const Color(0xFF5993FF),
    this.backgroundColor,
    this.borderColor,
    this.borderWidth = 0,
    this.arrowColor,
  });

  final VoidCallback onTap;
  final double size;
  /// `true` = سهم لليسار (زر التالي في RTL).
  final bool arrowPointsLeft;
  /// لون تعبئة الدائرة (زر التالي).
  final Color color;
  /// خلفية الدائرة — إن وُجدت تُستخدم بدل [color].
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderWidth;
  /// لون السهم — الافتراضي أبيض على الخلفية الزرقاء.
  final Color? arrowColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _BlueCircleArrowPainter(
              fillColor: backgroundColor ?? color,
              borderColor: borderColor,
              borderWidth: borderWidth,
              arrowColor: arrowColor ?? Colors.white,
              arrowPointsLeft: arrowPointsLeft,
            ),
          ),
        ),
      ),
    );
  }
}

class _BlueCircleArrowPainter extends CustomPainter {
  _BlueCircleArrowPainter({
    required this.fillColor,
    required this.borderColor,
    required this.borderWidth,
    required this.arrowColor,
    required this.arrowPointsLeft,
  });

  final Color fillColor;
  final Color? borderColor;
  final double borderWidth;
  final Color arrowColor;
  final bool arrowPointsLeft;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    canvas.drawCircle(
      center,
      radius,
      Paint()..color = fillColor,
    );

    if (borderColor != null && borderWidth > 0) {
      canvas.drawCircle(
        center,
        radius - borderWidth / 2,
        Paint()
          ..color = borderColor!
          ..style = PaintingStyle.stroke
          ..strokeWidth = borderWidth,
      );
    }

    final stroke = Paint()
      ..color = arrowColor
      ..strokeWidth = size.width * 0.078
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;
    final cx = center.dx;
    final cy = center.dy;

    if (arrowPointsLeft) {
      canvas.drawLine(
        Offset(cx + w * 0.11, cy),
        Offset(cx - w * 0.06, cy),
        stroke,
      );
      final head = Path()
        ..moveTo(cx - w * 0.03, cy - h * 0.12)
        ..lineTo(cx - w * 0.17, cy)
        ..lineTo(cx - w * 0.03, cy + h * 0.12);
      canvas.drawPath(head, stroke);
    } else {
      canvas.drawLine(
        Offset(cx - w * 0.11, cy),
        Offset(cx + w * 0.06, cy),
        stroke,
      );
      final head = Path()
        ..moveTo(cx + w * 0.03, cy - h * 0.12)
        ..lineTo(cx + w * 0.17, cy)
        ..lineTo(cx + w * 0.03, cy + h * 0.12);
      canvas.drawPath(head, stroke);
    }
  }

  @override
  bool shouldRepaint(covariant _BlueCircleArrowPainter oldDelegate) =>
      oldDelegate.fillColor != fillColor ||
      oldDelegate.borderColor != borderColor ||
      oldDelegate.borderWidth != borderWidth ||
      oldDelegate.arrowColor != arrowColor ||
      oldDelegate.arrowPointsLeft != arrowPointsLeft;
}
