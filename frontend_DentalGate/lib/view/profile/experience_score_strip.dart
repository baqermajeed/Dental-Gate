import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:dental_gate/view/profile/experience_score_breakdown.dart';

/// ألوان وتسميات الشارة — داكن للشريط الكامل، فاتح للشارة المضغوطة.
abstract final class _XpTierStyle {
  static Color accent(ExperienceTier t) => switch (t) {
        ExperienceTier.silver => const Color(0xFF94A3B8),
        ExperienceTier.gold => const Color(0xFFF59E0B),
        ExperienceTier.platinum => const Color(0xFF22D3EE),
        ExperienceTier.diamond => const Color(0xFFA78BFA),
      };

  static Color accentDeep(ExperienceTier t) => switch (t) {
        ExperienceTier.silver => const Color(0xFF475569),
        ExperienceTier.gold => const Color(0xFFD97706),
        ExperienceTier.platinum => const Color(0xFF0891B2),
        ExperienceTier.diamond => const Color(0xFF7C3AED),
      };

  static Color surfaceTint(ExperienceTier t) => switch (t) {
        ExperienceTier.silver => const Color(0xFFF1F5F9),
        ExperienceTier.gold => const Color(0xFFFFF7ED),
        ExperienceTier.platinum => const Color(0xFFECFEFF),
        ExperienceTier.diamond => const Color(0xFFF5F3FF),
      };

  static IconData icon(ExperienceTier t) => switch (t) {
        ExperienceTier.silver => Icons.shield_moon_rounded,
        ExperienceTier.gold => Icons.military_tech_rounded,
        ExperienceTier.platinum => Icons.auto_awesome_rounded,
        ExperienceTier.diamond => Icons.diamond_rounded,
      };
}

/// شريط علوي يعرض نقاط الخبرة وفئة الطبيب — فوق بطاقة الهوية.
class ExperienceScoreStrip extends StatelessWidget {
  const ExperienceScoreStrip({
    super.key,
    required this.breakdown,
    required this.onTap,
  });

  final ExperienceScoreBreakdown breakdown;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tier = breakdown.tier;
    final accent = _XpTierStyle.accent(tier);
    final frac = breakdown.fraction.clamp(0.0, 1.0);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22.r),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22.r),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0B1220),
                Color(0xFF111827),
                Color(0xFF172554),
              ],
              stops: [0.0, 0.45, 1.0],
            ),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.28),
                blurRadius: 24,
                offset: const Offset(0, 12),
                spreadRadius: -4,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22.r),
            child: Stack(
              children: [
                Positioned(
                  right: -40.w,
                  top: -30.h,
                  child: Transform.rotate(
                    angle: -0.35,
                    child: Container(
                      width: 160.w,
                      height: 160.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            accent.withValues(alpha: 0.35),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withValues(alpha: 0.07),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.12),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 12.h),
                  child: Row(
                    textDirection: TextDirection.rtl,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _TierOrb(
                        tier: tier,
                        accent: accent,
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              textDirection: TextDirection.rtl,
                              children: [
                                Flexible(
                                  child: Text(
                                    'نقاط الخبرة',
                                    style: TextStyle(
                                      fontFamily: 'Lama Sans',
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15.sp,
                                      height: 1.2,
                                      color: Colors.white.withValues(alpha: 0.92),
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 8.w),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8.w,
                                    vertical: 3.h,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(999),
                                    gradient: LinearGradient(
                                      colors: [
                                        accent.withValues(alpha: 0.35),
                                        accent.withValues(alpha: 0.12),
                                      ],
                                    ),
                                    border: Border.all(
                                      color: accent.withValues(alpha: 0.55),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        _XpTierStyle.icon(tier),
                                        size: 13.sp,
                                        color: accent,
                                      ),
                                      SizedBox(width: 4.w),
                                      Text(
                                        experienceTierLabelAr(tier),
                                        style: TextStyle(
                                          fontFamily: 'Lama Sans',
                                          fontWeight: FontWeight.w900,
                                          fontSize: 11.sp,
                                          color: Colors.white.withValues(alpha: 0.95),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 6.h),
                            Row(
                              textDirection: TextDirection.rtl,
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                ShaderMask(
                                  blendMode: BlendMode.srcIn,
                                  shaderCallback: (bounds) => LinearGradient(
                                    colors: [
                                      Colors.white,
                                      accent.withValues(alpha: 0.88),
                                    ],
                                  ).createShader(bounds),
                                  child: Text(
                                    '${breakdown.totalEarned}',
                                    style: TextStyle(
                                      fontFamily: 'Lama Sans',
                                      fontWeight: FontWeight.w900,
                                      fontSize: 26.sp,
                                      height: 1,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                Text(
                                  '/${breakdown.totalMax}',
                                  style: TextStyle(
                                    fontFamily: 'Lama Sans',
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14.sp,
                                    color: Colors.white.withValues(alpha: 0.45),
                                  ),
                                ),
                                const Spacer(),
                                Icon(
                                  Icons.arrow_back_ios_new_rounded,
                                  size: 14.sp,
                                  color: Colors.white.withValues(alpha: 0.35),
                                ),
                              ],
                            ),
                            SizedBox(height: 10.h),
                            _XpProgressBar(
                              fraction: frac,
                              accent: accent,
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
        ),
      ),
    );
  }
}

class _TierOrb extends StatelessWidget {
  const _TierOrb({
    required this.tier,
    required this.accent,
  });

  final ExperienceTier tier;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 52.w,
      height: 52.w,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 52.w,
            height: 52.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: SweepGradient(
                colors: [
                  accent,
                  accent.withValues(alpha: 0.25),
                  accent.withValues(alpha: 0.65),
                  accent,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.45),
                  blurRadius: 16,
                  spreadRadius: -2,
                ),
              ],
            ),
          ),
          ClipOval(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 0.5, sigmaY: 0.5),
              child: Container(
                width: 46.w,
                height: 46.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF1E293B),
                      const Color(0xFF0F172A),
                    ],
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                ),
                child: Icon(
                  _XpTierStyle.icon(tier),
                  color: accent,
                  size: 26.sp,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _XpProgressBar extends StatelessWidget {
  const _XpProgressBar({
    required this.fraction,
    required this.accent,
  });

  final double fraction;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: 5.h,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              color: Colors.white.withValues(alpha: 0.08),
            ),
            FractionallySizedBox(
              alignment: Alignment.centerRight,
              widthFactor: fraction,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  gradient: LinearGradient(
                    colors: [
                      accent.withValues(alpha: 0.35),
                      accent,
                      Colors.white.withValues(alpha: 0.85),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.6),
                      blurRadius: 8,
                      spreadRadius: -1,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// شارة مضغوطة لنقاط طبيب آخر — في صف العنوان (يمين)، غير قابلة للضغط.
class ExperienceScoreCompactChip extends StatelessWidget {
  const ExperienceScoreCompactChip({
    super.key,
    required this.breakdown,
  });

  final ExperienceScoreBreakdown breakdown;

  @override
  Widget build(BuildContext context) {
    final tier = breakdown.tier;
    final accent = _XpTierStyle.accentDeep(tier);
    final tint = _XpTierStyle.surfaceTint(tier);
    final frac = breakdown.fraction.clamp(0.0, 1.0);

    return Container(
      height: 36.h,
      padding: EdgeInsets.fromLTRB(5.w, 4.h, 8.w, 4.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18.r),
        color: Colors.white,
        border: Border.all(
          color: const Color(0xFFE2EEF8),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.14),
            blurRadius: 14,
            offset: const Offset(0, 4),
            spreadRadius: -2,
          ),
          BoxShadow(
            color: const Color(0xFF5993FF).withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        textDirection: TextDirection.rtl,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _CompactXpRing(
            fraction: frac,
            accent: accent,
            tint: tint,
            tier: tier,
          ),
          SizedBox(width: 7.w),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'نقاط الخبرة',
                style: TextStyle(
                  fontFamily: 'Lama Sans',
                  fontWeight: FontWeight.w600,
                  fontSize: 8.sp,
                  height: 1,
                  color: const Color(0xFF94A3B8),
                ),
              ),
              SizedBox(height: 2.h),
              Row(
                textDirection: TextDirection.rtl,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '${breakdown.totalEarned}',
                    style: TextStyle(
                      fontFamily: 'Lama Sans',
                      fontWeight: FontWeight.w900,
                      fontSize: 14.sp,
                      height: 1,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    '/$kExperienceScoreTotalCap',
                    style: TextStyle(
                      fontFamily: 'Lama Sans',
                      fontWeight: FontWeight.w600,
                      fontSize: 9.sp,
                      height: 1,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(width: 6.w),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 4.h),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: tint,
              border: Border.all(
                color: accent.withValues(alpha: 0.28),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _XpTierStyle.icon(tier),
                  size: 11.sp,
                  color: accent,
                ),
                SizedBox(width: 3.w),
                Text(
                  experienceTierLabelAr(tier),
                  style: TextStyle(
                    fontFamily: 'Lama Sans',
                    fontWeight: FontWeight.w800,
                    fontSize: 9.sp,
                    height: 1,
                    color: accent,
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

/// حلقة تقدّم صغيرة حول أيقونة التصنيف — للشارة المضغوطة.
class _CompactXpRing extends StatelessWidget {
  const _CompactXpRing({
    required this.fraction,
    required this.accent,
    required this.tint,
    required this.tier,
  });

  final double fraction;
  final Color accent;
  final Color tint;
  final ExperienceTier tier;

  @override
  Widget build(BuildContext context) {
    final size = 28.w;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _CompactRingPainter(
              fraction: fraction,
              trackColor: const Color(0xFFE8F0F8),
              progressColor: accent,
              strokeWidth: 2.5,
            ),
          ),
          Container(
            width: 22.w,
            height: 22.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: tint,
            ),
            child: Icon(
              _XpTierStyle.icon(tier),
              size: 12.sp,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactRingPainter extends CustomPainter {
  const _CompactRingPainter({
    required this.fraction,
    required this.trackColor,
    required this.progressColor,
    required this.strokeWidth,
  });

  final double fraction;
  final Color trackColor;
  final Color progressColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final track = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final progress = Paint()
      ..shader = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: 3 * math.pi / 2,
        colors: [
          progressColor.withValues(alpha: 0.35),
          progressColor,
        ],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, track);

    if (fraction > 0) {
      canvas.drawArc(
        rect,
        -math.pi / 2,
        2 * math.pi * fraction,
        false,
        progress,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CompactRingPainter oldDelegate) =>
      oldDelegate.fraction != fraction ||
      oldDelegate.progressColor != progressColor;
}
