import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:dental_gate/widgets/app_back_button.dart';

/// صفحة سياسة الخصوصية — تصميم متوافق مع صفحة «تواصل معنا».
class PrivacyPolicyView extends StatelessWidget {
  const PrivacyPolicyView({super.key});

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
            'سياسة الخصوصية',
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
                          const _PrivacyHero(),
                          SizedBox(height: 24.h),
                          Text(
                            'التفاصيل',
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
                          const _PolicyBlock(
                            title: 'مقدمة',
                            body:
                                'نحن في Dental Gate نلتزم بحماية خصوصيتك. توضح هذه السياسة كيفية جمع '
                                'البيانات واستخدامها عند استخدامك للتطبيق والخدمات المرتبطة به. '
                                'باستمرارك في الاستخدام، فإنك توافق على ما ورد هنا ضمن حدود القانون المعمول به.',
                          ),
                          SizedBox(height: 12.h),
                          const _PolicyBlock(
                            title: 'البيانات التي قد نجمعها',
                            body:
                                'قد تشمل: معلومات الحساب (الاسم، البريد، رقم الهاتف عند التسجيل)، '
                                'البيانات المهنية التي تختار إضافتها للملف الشخصي، بيانات الاستخدام '
                                'والجهاز لتحسين الأداء والأمان، ومحتوى ترفعه طوعاً (مثل الصور أو المستندات '
                                'ضمن الميزات المتاحة). لا نطلب بياناتاً غير لازمة لتشغيل الخدمة.',
                          ),
                          SizedBox(height: 12.h),
                          const _PolicyBlock(
                            title: 'استخدام البيانات',
                            body:
                                'نستخدم البيانات لتشغيل التطبيق، وتخصيص التجربة، والتواصل معك بخصوص الحساب، '
                                'وتحسين الخدمات، والامتثال للالتزامات القانونية. لا نبيع بياناتك الشخصية '
                                'لأطرافٍ تسويقية خارج نطاق ما يُسمح به قانوناً.',
                          ),
                          SizedBox(height: 12.h),
                          const _PolicyBlock(
                            title: 'مشاركة البيانات',
                            body:
                                'قد نشارك بياناتاً محدودة مع مزودي بنية تحتية (استضافة، إشعارات، تحليلات '
                                'مجمّعة) بموجب عقود تلزمهم بالسرية والأمان. قد نكشف عن معلومات إذا طُلب '
                                'ذلك قضائياً أو لحماية حقوقنا ومستخدمينا.',
                          ),
                          SizedBox(height: 12.h),
                          const _PolicyBlock(
                            title: 'الأمان والاحتفاظ',
                            body:
                                'نطبّق إجراءات تقنية وتنظيمية معقولة لحماية بياناتك. نحتفظ بالبيانات '
                                'لمدةٍ تتوافق مع الغرض من جمعها أو كما يقتضيه القانون، ثم نعالجها أو '
                                'نحذفها وفق سياسات الاحتفاظ لدينا.',
                          ),
                          SizedBox(height: 12.h),
                          const _PolicyBlock(
                            title: 'حقوقك',
                            body:
                                'حسب القوانين المعمول بها، قد يشمل ذلك: طلب الاطلاع على بياناتك، '
                                'تصحيحها، حذفها، تقييد المعالجة، أو الاعتراض على معالجةٍ معيّنة. '
                                'للمطالبة بحقوقك يمكنك التواصل معنا عبر القنوات الرسمية في التطبيق.',
                          ),
                          SizedBox(height: 12.h),
                          const _PolicyBlock(
                            title: 'تحديث السياسة',
                            body:
                                'قد نُحدّث هذه السياسة من وقتٍ لآخر. سنُشير إلى تاريخ آخر تحديث في '
                                'أسفل الصفحة، ويُستحسن مراجعتها دورياً. استمرارك بالاستخدام بعد التحديث '
                                'يُعد قبولاً للتعديلات الجوهرية ضمن الإطار القانوني.',
                          ),
                          SizedBox(height: 28.h),
                          Text(
                            'آخر تحديث: مايو 2026',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Lama Sans',
                              fontWeight: FontWeight.w700,
                              fontSize: 12.sp,
                              color: _muted.withValues(alpha: 0.9),
                            ),
                          ),
                          SizedBox(height: 12.h),
                          Text(
                            'Dental Gate — نقدّر ثقتك',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Lama Sans',
                              fontWeight: FontWeight.w800,
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

class _PrivacyHero extends StatelessWidget {
  const _PrivacyHero();

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
                PrivacyPolicyView._accentDeep,
              ],
            ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
            child: Text(
              'Dental Gate',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Lama Sans',
                fontWeight: FontWeight.w900,
                fontSize: 30.sp,
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
                Icons.verified_user_rounded,
                size: 20.sp,
                color: PrivacyPolicyView._accent.withValues(alpha: 0.9),
              ),
              SizedBox(width: 8.w),
              Text(
                'سياسة الخصوصية',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Lama Sans',
                  fontWeight: FontWeight.w900,
                  fontSize: 16.sp,
                  color: PrivacyPolicyView._accent.withValues(alpha: 0.95),
                  height: 1.2,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Text(
            'شفافية وحماية — نشرح لك باختصار كيف نتعامل مع معلوماتك، '
            'ونلتزم بالحد الأدنى من الجمع والاستخدام لما يخدم تجربتك المهنية بأمان.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Lama Sans',
              fontWeight: FontWeight.w700,
              fontSize: 14.sp,
              height: 1.65,
              color: PrivacyPolicyView._ink.withValues(alpha: 0.88),
            ),
          ),
        ],
      ),
    );
  }
}

class _PolicyBlock extends StatelessWidget {
  const _PolicyBlock({
    required this.title,
    required this.body,
  });

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(
          color: PrivacyPolicyView._accent.withValues(alpha: 0.12),
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
        padding: EdgeInsets.fromLTRB(18.w, 18.h, 18.w, 18.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontFamily: 'Lama Sans',
                fontWeight: FontWeight.w900,
                fontSize: 15.sp,
                color: PrivacyPolicyView._ink,
                height: 1.25,
              ),
            ),
            SizedBox(height: 10.h),
            Text(
              body,
              style: TextStyle(
                fontFamily: 'Lama Sans',
                fontWeight: FontWeight.w600,
                fontSize: 13.sp,
                height: 1.55,
                color: PrivacyPolicyView._muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
