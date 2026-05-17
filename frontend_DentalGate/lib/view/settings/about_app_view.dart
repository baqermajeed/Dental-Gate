import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:dental_gate/widgets/app_back_button.dart';

/// يُفضّل مزامنته مع `pubspec.yaml` عند كل إصدار.
abstract final class AboutAppVersion {
  static const String version = '1.0.0';
  static const String build = '1';
}

/// صفحة «لمحة عن التطبيق» — تصميم متوافق مع «تواصل معنا».
class AboutAppView extends StatelessWidget {
  const AboutAppView({super.key});

  static const Color _ink = Color(0xFF0B1220);
  static const Color _muted = Color(0xFF64748B);
  static const Color _accent = Color(0xFF5993FF);
  static const Color _accentDeep = Color(0xFF3B5B9A);

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
            'لمحة عن التطبيق',
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
                          const _AboutHero(),
                          SizedBox(height: 28.h),
                          Text(
                            'لماذا Dental Gate؟',
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
                          const _HighlightTile(
                            title: 'مجتمع مهني',
                            subtitle:
                                'مساحة تجمع المهتمين والعاملين في مجال طبّ وجراحة الأسنان في مكان واحد.',
                            leading: _OrbIcon(
                              gradient: LinearGradient(
                                begin: Alignment.topRight,
                                end: Alignment.bottomLeft,
                                colors: [
                                  Color(0xFF5993FF),
                                  Color(0xFF7FB2E4),
                                ],
                              ),
                              icon: Icons.groups_rounded,
                            ),
                            accent: Color(0xFF5993FF),
                          ),
                          SizedBox(height: 12.h),
                          const _HighlightTile(
                            title: 'ملفك المهني',
                            subtitle:
                                'اعرض خبرتك ومسارك بشكلٍ منظم، وتواصل مع الفرص التي تناسب تخصصك.',
                            leading: _OrbIcon(
                              gradient: LinearGradient(
                                begin: Alignment.topRight,
                                end: Alignment.bottomLeft,
                                colors: [
                                  Color(0xFF6366F1),
                                  Color(0xFFA5B4FC),
                                ],
                              ),
                              icon: Icons.badge_rounded,
                            ),
                            accent: Color(0xFF6366F1),
                          ),
                          SizedBox(height: 12.h),
                          const _HighlightTile(
                            title: 'فرص وتفاعل',
                            subtitle:
                                'تابع الوظائف والمحتوى المهني، وابقَ على اطلاع بما يهم مسارك.',
                            leading: _OrbIcon(
                              gradient: LinearGradient(
                                begin: Alignment.topRight,
                                end: Alignment.bottomLeft,
                                colors: [
                                  Color(0xFF0EA5E9),
                                  Color(0xFF38BDF8),
                                ],
                              ),
                              icon: Icons.work_outline_rounded,
                            ),
                            accent: Color(0xFF0EA5E9),
                          ),
                          SizedBox(height: 12.h),
                          const _HighlightTile(
                            title: 'تجربة راقية',
                            subtitle:
                                'واجهة عصرية وسلسة، نطوّرها باستمرار لنمنحك راحةً أثناء الاستخدام.',
                            leading: _OrbIcon(
                              gradient: LinearGradient(
                                begin: Alignment.topRight,
                                end: Alignment.bottomLeft,
                                colors: [
                                  Color(0xFF14B8A6),
                                  Color(0xFF5EEAD4),
                                ],
                              ),
                              icon: Icons.auto_awesome_rounded,
                            ),
                            accent: Color(0xFF14B8A6),
                          ),
                          SizedBox(height: 24.h),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(22.r),
                              border: Border.all(
                                color: _accent.withValues(alpha: 0.14),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF040814)
                                      .withValues(alpha: 0.05),
                                  blurRadius: 16,
                                  offset: Offset(0, 8.h),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 20.w,
                                vertical: 18.h,
                              ),
                              child: Row(
                                textDirection: TextDirection.rtl,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.info_outline_rounded,
                                    size: 22.sp,
                                    color: _accent,
                                  ),
                                  SizedBox(width: 10.w),
                                  Text(
                                    'الإصدار ${AboutAppVersion.version} (${AboutAppVersion.build})',
                                    style: TextStyle(
                                      fontFamily: 'Lama Sans',
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14.sp,
                                      color: _ink,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: 28.h),
                          Text(
                            'شكراً لأنّك معنا في Dental Gate',
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

class _AboutHero extends StatelessWidget {
  const _AboutHero();

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
                AboutAppView._accentDeep,
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
          SizedBox(height: 8.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.layers_rounded,
                size: 20.sp,
                color: AboutAppView._accent.withValues(alpha: 0.9),
              ),
              SizedBox(width: 8.w),
              Text(
                'لمحة عن التطبيق',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Lama Sans',
                  fontWeight: FontWeight.w900,
                  fontSize: 16.sp,
                  color: AboutAppView._accent.withValues(alpha: 0.95),
                  height: 1.2,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Text(
            'تطبيقٌ يهدف إلى ربط المهتمين بمجال طبّ الأسنان بالفرص والمعرفة والتفاعل المهني، '
            'في بيئةٍ واضحة وحديثة تدعم مسارك المهني خطوةً بخطوة.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Lama Sans',
              fontWeight: FontWeight.w700,
              fontSize: 14.5.sp,
              height: 1.65,
              color: AboutAppView._ink.withValues(alpha: 0.88),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrbIcon extends StatelessWidget {
  const _OrbIcon({
    required this.gradient,
    required this.icon,
  });

  final Gradient gradient;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52.w,
      height: 52.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: gradient,
        boxShadow: [
          BoxShadow(
            color: AboutAppView._accent.withValues(alpha: 0.28),
            blurRadius: 12,
            offset: Offset(0, 6.h),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Icon(
        icon,
        color: Colors.white,
        size: 26.sp,
      ),
    );
  }
}

class _HighlightTile extends StatelessWidget {
  const _HighlightTile({
    required this.title,
    required this.subtitle,
    required this.leading,
    required this.accent,
  });

  final String title;
  final String subtitle;
  final Widget leading;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(
          color: accent.withValues(alpha: 0.14),
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
          crossAxisAlignment: CrossAxisAlignment.center,
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
                      color: AboutAppView._ink,
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
                      height: 1.45,
                      color: AboutAppView._muted,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.auto_awesome_outlined,
              size: 20.sp,
              color: accent.withValues(alpha: 0.45),
            ),
          ],
        ),
      ),
    );
  }
}
