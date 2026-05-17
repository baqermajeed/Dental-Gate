import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dental_gate/widgets/app_back_button.dart';

/// روابط التواصل الرسمية — حدّثها قبل النشر إلى حساباتكم الفعلية.
abstract final class DentalGateSocialUrls {
  static const String instagram = 'https://www.instagram.com/dentalgate_app/';
  static const String facebook = 'https://www.facebook.com/dentalgateapp';
  /// رقم واتساب بصيغة دولية بدون + أو صفر أول (مثال: 9665xxxxxxxx)
  static const String whatsapp = 'https://wa.me/966500000000';
}

/// صفحة تواصل معنا — قنوات التواصل الاجتماعي بتصميم عصري.
class ContactUsView extends StatelessWidget {
  const ContactUsView({super.key});

  static const Color _ink = Color(0xFF0B1220);
  static const Color _muted = Color(0xFF64748B);
  static const Color _accent = Color(0xFF5993FF);
  static const Color _accentDeep = Color(0xFF3B5B9A);

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      Get.snackbar(
        'رابط غير صالح',
        'تعذّر قراءة الرابط.',
        snackPosition: SnackPosition.BOTTOM,
        margin: EdgeInsets.all(16.w),
      );
      return;
    }
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        Get.snackbar(
          'تعذّر الفتح',
          'جرّب من المتصفح أو حدّث التطبيق.',
          snackPosition: SnackPosition.BOTTOM,
          margin: EdgeInsets.all(16.w),
        );
      }
    } catch (_) {
      Get.snackbar(
        'تعذّر الفتح',
        'تحقق من الاتصال بالإنترنت.',
        snackPosition: SnackPosition.BOTTOM,
        margin: EdgeInsets.all(16.w),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F8FF),
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          foregroundColor: _ink,
          automaticallyImplyLeading: false,
          // في RTL الـ leading يمين؛ نضع الرجوع في actions فيظهر يسار الشاشة
          leadingWidth: 56.w,
          leading: SizedBox(width: 56.w),
          actions: [
            Padding(
              padding: EdgeInsets.only(left: 8.w),
              child: AppBackButton(
                size: 38.w,
                iconSize: 22.sp,
                onTap: () => Get.back<void>(),
              ),
            ),
          ],
          title: Text(
            'تواصل معنا',
            style: TextStyle(
              fontFamily: 'Lama Sans',
              fontWeight: FontWeight.w900,
              fontSize: 17.sp,
              color: _ink,
              height: 1.3,
            ),
          ),
          centerTitle: true,
        ),
        body: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: -80.h,
              left: -60.w,
              child: _GlowBlob(
                diameter: 220.w,
                color: _accent.withValues(alpha: 0.18),
              ),
            ),
            Positioned(
              top: 120.h,
              right: -40.w,
              child: _GlowBlob(
                diameter: 160.w,
                color: const Color(0xFF7FB2E4).withValues(alpha: 0.22),
              ),
            ),
            Positioned(
              bottom: 40.h,
              left: -20.w,
              child: _GlowBlob(
                diameter: 120.w,
                color: _accentDeep.withValues(alpha: 0.12),
              ),
            ),
            SafeArea(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(child: SizedBox(height: 8.h)),
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(20.w, 56.h, 20.w, 32.h),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _HeroIntro(),
                          SizedBox(height: 28.h),
                          Text(
                            'اختر القناة التي تُفضّلها',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Lama Sans',
                              fontWeight: FontWeight.w800,
                              fontSize: 14.sp,
                              color: _muted,
                              letterSpacing: 0.3,
                            ),
                          ),
                          SizedBox(height: 16.h),
                          _SocialTile(
                            title: 'إنستغرام',
                            subtitle: 'لحظات، أخبار، ولمحات من مجتمعنا',
                            onTap: () => _openUrl(DentalGateSocialUrls.instagram),
                            leading: const _InstagramOrb(),
                            accent: const Color(0xFFE1306C),
                          ),
                          SizedBox(height: 12.h),
                          _SocialTile(
                            title: 'فيسبوك',
                            subtitle: 'صفحتنا الرسمية للتحديثات والنقاش',
                            onTap: () => _openUrl(DentalGateSocialUrls.facebook),
                            leading: const _FacebookOrb(),
                            accent: const Color(0xFF1877F2),
                          ),
                          SizedBox(height: 12.h),
                          _SocialTile(
                            title: 'واتساب',
                            subtitle: 'رسالة مباشرة — نرد بأسرع وقت ممكن',
                            onTap: () => _openUrl(DentalGateSocialUrls.whatsapp),
                            leading: const _WhatsAppOrb(),
                            accent: const Color(0xFF25D366),
                          ),
                          SizedBox(height: 32.h),
                          Text(
                            'شكراً لأنّك جزء من رحلتنا',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Lama Sans',
                              fontWeight: FontWeight.w700,
                              fontSize: 13.sp,
                              color: _muted.withValues(alpha: 0.85),
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
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
}

class _GlowBlob extends StatelessWidget {
  const _GlowBlob({
    required this.diameter,
    required this.color,
  });

  final double diameter;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: diameter,
        height: diameter,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ),
      ),
    );
  }
}

class _HeroIntro extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28.r),
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            Colors.white,
            Colors.white.withValues(alpha: 0.92),
            const Color(0xFFEEF4FF),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5993FF).withValues(alpha: 0.12),
            blurRadius: 32,
            offset: Offset(0, 14.h),
          ),
          BoxShadow(
            color: const Color(0xFF040814).withValues(alpha: 0.06),
            blurRadius: 18,
            offset: Offset(0, 6.h),
          ),
        ],
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.9),
          width: 1.2,
        ),
      ),
      padding: EdgeInsets.fromLTRB(22.w, 26.h, 22.w, 26.h),
      child: Column(
        children: [
          ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: (bounds) => LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                const Color(0xFF5993FF),
                const Color(0xFF7FB2E4),
                ContactUsView._accentDeep,
              ],
            ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
            child: Text(
              'Dental Gate',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Lama Sans',
                fontWeight: FontWeight.w900,
                fontSize: 32.sp,
                color: Colors.white,
                height: 1.05,
                letterSpacing: 0.5,
              ),
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            'بوابتك المهنية',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Lama Sans',
              fontWeight: FontWeight.w800,
              fontSize: 14.sp,
              color: ContactUsView._accent.withValues(alpha: 0.9),
              letterSpacing: 1.2,
            ),
          ),
          SizedBox(height: 18.h),
          Text(
            'نستقبل تواصلك بكل ترحيب — نجمع المهتمين بطبّ الأسنان في فضاءٍ واحد، '
            'وننمو مع آرائك واقتراحاتك لتجربةٍ أرقى في كل خطوة.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Lama Sans',
              fontWeight: FontWeight.w700,
              fontSize: 14.5.sp,
              height: 1.65,
              color: ContactUsView._ink.withValues(alpha: 0.88),
            ),
          ),
        ],
      ),
    );
  }
}

class _InstagramOrb extends StatelessWidget {
  const _InstagramOrb();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52.w,
      height: 52.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            Color(0xFFF58529),
            Color(0xFFDD2A7B),
            Color(0xFF8134AF),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFDD2A7B).withValues(alpha: 0.35),
            blurRadius: 12,
            offset: Offset(0, 6.h),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.camera_alt_rounded,
        color: Colors.white,
        size: 24.sp,
      ),
    );
  }
}

class _FacebookOrb extends StatelessWidget {
  const _FacebookOrb();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52.w,
      height: 52.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF1877F2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1877F2).withValues(alpha: 0.4),
            blurRadius: 12,
            offset: Offset(0, 6.h),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        'f',
        style: TextStyle(
          color: Colors.white,
          fontSize: 28.sp,
          fontWeight: FontWeight.w900,
          height: 1,
          fontFamily: 'Lama Sans',
        ),
      ),
    );
  }
}

class _WhatsAppOrb extends StatelessWidget {
  const _WhatsAppOrb();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52.w,
      height: 52.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF25D366),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF25D366).withValues(alpha: 0.4),
            blurRadius: 12,
            offset: Offset(0, 6.h),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.chat_rounded,
        color: Colors.white,
        size: 26.sp,
      ),
    );
  }
}

class _SocialTile extends StatelessWidget {
  const _SocialTile({
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.leading,
    required this.accent,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Widget leading;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22.r),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22.r),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22.r),
            border: Border.all(
              color: accent.withValues(alpha: 0.12),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF040814).withValues(alpha: 0.05),
                blurRadius: 16,
                offset: Offset(0, 8.h),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            child: Row(
              textDirection: TextDirection.rtl,
              children: [
                leading,
                SizedBox(width: 14.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontFamily: 'Lama Sans',
                          fontWeight: FontWeight.w900,
                          fontSize: 16.sp,
                          color: ContactUsView._ink,
                          height: 1.2,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontFamily: 'Lama Sans',
                          fontWeight: FontWeight.w600,
                          fontSize: 12.sp,
                          height: 1.4,
                          color: ContactUsView._muted,
                        ),
                      ),
                    ],
                  ),
                ),
                Transform.rotate(
                  angle: math.pi,
                  child: Icon(
                    Icons.chevron_left_rounded,
                    size: 26.sp,
                    color: accent.withValues(alpha: 0.65),
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
