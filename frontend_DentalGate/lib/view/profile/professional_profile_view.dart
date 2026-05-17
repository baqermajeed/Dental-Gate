import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:dental_gate/controllers/professional_profile_controller.dart';
import 'package:dental_gate/core/app_routes.dart';
import 'package:dental_gate/core/media_url.dart';
import 'package:dental_gate/models/doctor_profile_full.dart';
import 'package:dental_gate/view/profile/certificate_add_sheet.dart';
import 'package:dental_gate/widgets/app_back_button.dart';
import 'package:dental_gate/view/profile/clinical_case_add_sheet.dart';
import 'package:dental_gate/models/doctor_peer_rating.dart';
import 'package:dental_gate/services/api_service.dart' show ApiException, ApiService;
import 'package:dental_gate/view/profile/doctor_peer_rating_dialog.dart';
import 'package:dental_gate/view/profile/doctor_recommendation_dialog.dart';
import 'package:dental_gate/view/profile/experience_score_breakdown.dart';
import 'package:dental_gate/view/profile/experience_score_strip.dart';
import 'package:dental_gate/view/profile/experience_tasks_view.dart';
import 'package:dental_gate/view/profile/id_card_english_text.dart';

/// ألوان مطابقة للتصميم (خلفية بيضاء، رمادي فاتح، أزرق أساسي).
abstract final class _Pv {
  static const Color white = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFF5F5F5);
  static const Color subtext = Color(0xFF757575);
  static const Color blue = Color(0xFF5993FF);
  /// لون نص صفوف المعلومات في بطاقة البروفايل (Figma)
  static const Color infoInk = Color(0xFF040814);
  static const Color experienceMuted = Color(0xFF6B7280);
  /// ظل البطاقة (Figma: #040814 @ 16%, blur 6, offset 0)
  static const Color cardShadow = Color(0x29040814);
  /// ظل شعار التعليم (Figma: #000000 @ 16%, blur 6.05, offset 0)
  static const Color eduSealShadow = Color(0x29000000);
}

/// ألوان وأسطح الواجهة أسفل بطاقة الهوية — موحّدة مع لوحة التطبيق (بدون بنفسجي).
abstract final class _Modern {
  /// ألوان التطبيق الرسمية
  static const Color appBlue = Color(0xFF5993FF);
  static const Color appBlueMid = Color(0xFF3A83BC);
  static const Color appBlueLight = Color(0xFF7FB2E4);

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      appBlueLight,
      appBlue,
      appBlueMid,
    ],
  );

  static const LinearGradient accentStroke = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [
      appBlueLight,
      appBlue,
    ],
  );

  static const Color shellInner = Color(0xFFFFFFFF);
  static const Color chipBg = Color(0xFFE8F4FC);
  static const Color chipBorder = Color(0xFFB8D9F2);
  static const Color chipText = Color(0xFF2A6B9E);
  static const Color mutedLine = Color(0xFFE2E8F0);
  static const Color titleInk = Color(0xFF0F172A);
  static const Color softShadow = Color(0x140F172A);

  static Color shadowPrimary([double alpha = 0.2]) =>
      appBlue.withValues(alpha: alpha);
}

const int _kBioMaxChars = 200;

String _clampBioDisplay(String s) {
  final t = s.trim();
  if (t.isEmpty) return '';
  if (t.length <= _kBioMaxChars) return t;
  return Characters(t).take(_kBioMaxChars).toString();
}

double _measurePlainTextHeight(String text, double maxWidth, TextStyle style) {
  final p = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.rtl,
    maxLines: null,
  )..layout(maxWidth: maxWidth);
  return p.height;
}

int _maxLinesFittingHeight({
  required String text,
  required double maxWidth,
  required double maxHeight,
  required TextStyle style,
}) {
  if (text.isEmpty) return 1;
  var lo = 1;
  var hi = 500;
  var best = 1;
  while (lo <= hi) {
    final mid = (lo + hi) ~/ 2;
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.rtl,
      maxLines: mid,
    )..layout(maxWidth: maxWidth);
    if (painter.height <= maxHeight) {
      best = mid;
      lo = mid + 1;
    } else {
      hi = mid - 1;
    }
  }
  return best;
}

Future<bool> _showDeleteGalleryCaseDialog(BuildContext context) async {
  final v = await showDialog<bool>(
    context: context,
    builder: (ctx) => Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: Text(
          'حذف الحالة',
          style: TextStyle(
            fontFamily: 'Lama Sans',
            fontWeight: FontWeight.w800,
            fontSize: 18.sp,
            color: _Modern.titleInk,
          ),
        ),
        content: Text(
          'هل أنت متأكد من حذف هذه الحالة؟',
          style: TextStyle(
            fontFamily: 'Lama Sans',
            fontWeight: FontWeight.w600,
            fontSize: 15.sp,
            height: 1.45,
            color: const Color(0xFF374151),
          ),
        ),
        actionsAlignment: MainAxisAlignment.start,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'إلغاء',
              style: TextStyle(
                fontFamily: 'Lama Sans',
                fontWeight: FontWeight.w700,
                fontSize: 15.sp,
                color: const Color(0xFF6B7280),
              ),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFE53935),
              foregroundColor: Colors.white,
            ),
            child: Text(
              'حذف',
              style: TextStyle(
                fontFamily: 'Lama Sans',
                fontWeight: FontWeight.w800,
                fontSize: 15.sp,
              ),
            ),
          ),
        ],
      ),
    ),
  );
  return v ?? false;
}

Future<bool> _showDeleteCertificateDialog(BuildContext context) async {
  final v = await showDialog<bool>(
    context: context,
    builder: (ctx) => Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: Text(
          'حذف الشهادة',
          style: TextStyle(
            fontFamily: 'Lama Sans',
            fontWeight: FontWeight.w800,
            fontSize: 18.sp,
            color: _Modern.titleInk,
          ),
        ),
        content: Text(
          'هل أنت متأكد من حذف هذه الشهادة؟',
          style: TextStyle(
            fontFamily: 'Lama Sans',
            fontWeight: FontWeight.w600,
            fontSize: 15.sp,
            height: 1.45,
            color: const Color(0xFF374151),
          ),
        ),
        actionsAlignment: MainAxisAlignment.start,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'إلغاء',
              style: TextStyle(
                fontFamily: 'Lama Sans',
                fontWeight: FontWeight.w700,
                fontSize: 15.sp,
                color: const Color(0xFF6B7280),
              ),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFE53935),
              foregroundColor: Colors.white,
            ),
            child: Text(
              'حذف',
              style: TextStyle(
                fontFamily: 'Lama Sans',
                fontWeight: FontWeight.w800,
                fontSize: 15.sp,
              ),
            ),
          ),
        ],
      ),
    ),
  );
  return v ?? false;
}

/// البروفايل المهني — مطابق لتصميم الشاشة (RTL).
///
/// [tag] اختياري: عند فتح بروفايل متقدّم يُسجَّل [ProfessionalProfileController] بنفس الوسم.
class ProfessionalProfileView extends StatefulWidget {
  const ProfessionalProfileView({super.key, this.tag});

  final String? tag;

  @override
  State<ProfessionalProfileView> createState() => _ProfessionalProfileViewState();
}

class _ProfessionalProfileViewState extends State<ProfessionalProfileView> {
  final _profileTabsKey = GlobalKey<_ProfileTabbedSectionState>();

  static String _mediaUrl(String? path) => resolveMediaUrl(path);

  @override
  Widget build(BuildContext context) {
    final controller =
        Get.find<ProfessionalProfileController>(tag: widget.tag);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        color: Colors.white,
        child: Scaffold(
          backgroundColor: Colors.white,
          extendBodyBehindAppBar: false,
          appBar: PreferredSize(
            preferredSize: Size.fromHeight(kToolbarHeight),
            child: Obx(() {
              const titleStyle = TextStyle(
                fontFamily: 'Lama Sans',
                fontWeight: FontWeight.w900,
                fontSize: 20,
                height: 1.35,
                letterSpacing: -0.2,
                color: _Modern.titleInk,
              );
              final p = controller.profile.value;
              final showXpChip = controller.isReadOnlyView &&
                  p != null &&
                  !controller.isLoading.value;

              return AppBar(
                backgroundColor: Colors.white,
                surfaceTintColor: Colors.transparent,
                elevation: 0,
                scrolledUnderElevation: 0.5,
                shadowColor: _Modern.softShadow,
                automaticallyImplyLeading: false,
                centerTitle: true,
                leadingWidth: showXpChip ? 172.w : 0,
                leading: showXpChip
                    ? Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: Padding(
                          padding: EdgeInsetsDirectional.only(end: 14.w),
                          child: ExperienceScoreCompactChip(
                            breakdown: resolveExperienceScoreBreakdown(
                              p,
                              peerRatingsReceived:
                                  controller.peerRatingsReceived.value,
                              peerRatingsGiven: 0,
                            ),
                          ),
                        ),
                      )
                    : null,
                title: Transform.translate(
                  offset: Offset(15 .w, 0),
                  child: Text(
                    'البروفايل',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: titleStyle.copyWith(fontSize: 20.sp),
                  ),
                ),
                actions: [
                  Padding(
                    padding: EdgeInsets.only(left: 8.w),
                    child: AppBackButton(
                      size: 38.w,
                      iconSize: 22.sp,
                      iconColor: _Modern.titleInk,
                      onTap: () => Get.back(),
                    ),
                  ),
                ],
              );
            }),
          ),
          body: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator(color: _Pv.blue));
          }
          if (controller.errorMessage.value != null) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(24.w),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      controller.errorMessage.value!,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontFamily: 'Cairo', fontSize: 15.sp),
                    ),
                    SizedBox(height: 16.h),
                    FilledButton(
                      onPressed: controller.reload,
                      child: const Text('إعادة المحاولة'),
                    ),
                  ],
                ),
              ),
            );
          }
          final p = controller.profile.value;
          if (p == null) {
            return const Center(child: Text('لا توجد بيانات'));
          }
          final hasBio = (p.bio ?? '').trim().isNotEmpty;
          final hasEducation = p.education.isNotEmpty;
          final hasLanguages = p.languages.isNotEmpty;
          final hasSkills = p.skillIds.isNotEmpty;
          final hasExperiences = p.experiences.isNotEmpty;
          final hasGallery = p.gallery.isNotEmpty;
          final hasCertificates = p.certificateImages.isNotEmpty;
          final completionSteps = <bool>[
            hasBio,
            hasEducation,
            hasLanguages,
            hasSkills,
            hasExperiences,
            hasGallery,
            hasCertificates,
          ];
          final completedCount = completionSteps.where((e) => e).length;
          final completion = completedCount / completionSteps.length;
          final xpBreakdown = resolveExperienceScoreBreakdown(
            p,
            peerRatingsReceived: controller.peerRatingsReceived.value,
            peerRatingsGiven: controller.isReadOnlyView
                ? 0
                : controller.peerRatingsGiven.value,
          );
          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(16.w, 6.h, 16.w, 6.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (!controller.isReadOnlyView &&
                          completedCount < completionSteps.length) ...[
                        _ProfileCompletionHero(
                          completion: completion,
                          completedCount: completedCount,
                          totalCount: completionSteps.length,
                        ),
                        SizedBox(height: 6.h),
                      ],
                      if (!controller.isReadOnlyView) ...[
                        ExperienceScoreStrip(
                          breakdown: xpBreakdown,
                          onTap: () async {
                            final result = await Get.to<Object?>(
                              () => ExperienceTasksView(
                                profile: p,
                                initialPeerReceived:
                                    controller.peerRatingsReceived.value,
                                initialPeerGiven:
                                    controller.peerRatingsGiven.value,
                              ),
                            );
                            if (result == ExperienceTasksPopResult.openRatingsTab) {
                              _profileTabsKey.currentState?.openRatingsTab();
                            }
                            if (result == true || result == ExperienceTasksPopResult.openRatingsTab) {
                              await controller.reload();
                            }
                          },
                        ),
                        SizedBox(height: 10.h),
                      ],
                      _HeaderCard(p: p, mediaUrl: _mediaUrl),
                      SizedBox(height: 6.h),
                      _ProfileTabbedSection(
                        key: _profileTabsKey,
                        p: p,
                        mediaUrl: _mediaUrl,
                        canSubmitPeerRating:
                            controller.canSubmitPeerRatingOnViewedProfile,
                        canSubmitRecommendation:
                            controller.canSubmitRecommendationOnViewedProfile,
                        sessionExperiencePoints:
                            controller.sessionExperiencePoints,
                        isOwnProfile: !controller.isReadOnlyView,
                        canManageGallery: !controller.isReadOnlyView,
                        onAddGalleryCase: () {
                          WidgetsBinding.instance.addPostFrameCallback((_) async {
                            if (!context.mounted) return;
                            final r = await showClinicalCaseAddSheet(context);
                            if (r == null || !context.mounted) return;
                            final c = widget.tag != null
                                ? Get.find<ProfessionalProfileController>(tag: widget.tag)
                                : Get.find<ProfessionalProfileController>();
                            await c.addGalleryCase(
                              title: r.title,
                              description: r.description,
                              imageUrls: r.imageUrls,
                            );
                          });
                        },
                        onRequestDeleteGalleryCase: (index) async {
                          final ok = await _showDeleteGalleryCaseDialog(context);
                          if (ok != true || !context.mounted) return;
                          final c = widget.tag != null
                              ? Get.find<ProfessionalProfileController>(tag: widget.tag)
                              : Get.find<ProfessionalProfileController>();
                          await c.removeGalleryCaseAt(index);
                        },
                        canManageCertificates: !controller.isReadOnlyView,
                        onAddCertificate: () {
                          WidgetsBinding.instance.addPostFrameCallback((_) async {
                            if (!context.mounted) return;
                            final r = await showCertificateAddSheet(context);
                            if (r == null || !context.mounted) return;
                            final c = widget.tag != null
                                ? Get.find<ProfessionalProfileController>(tag: widget.tag)
                                : Get.find<ProfessionalProfileController>();
                            await c.addCertificate(
                              title: r.title,
                              issuer: r.issuer,
                              imageUrl: r.imageUrl,
                            );
                          });
                        },
                        onRequestDeleteCertificate: (index) async {
                          final ok = await _showDeleteCertificateDialog(context);
                          if (ok != true || !context.mounted) return;
                          final c = widget.tag != null
                              ? Get.find<ProfessionalProfileController>(tag: widget.tag)
                              : Get.find<ProfessionalProfileController>();
                          await c.removeCertificateAt(index);
                        },
                      ),
                      SizedBox(height: 88.h),
                    ],
                  ),
                ),
              ),
              if (!controller.isReadOnlyView)
                _EditFooter(
                  onEdit: () {
                    // يفصل بدء التنقّل عن إطار ضغط الزر لتقليل التجمّد مع GetMaterialApp + مسار ثقيل.
                    WidgetsBinding.instance.addPostFrameCallback((_) async {
                      final result = await Get.toNamed<dynamic>(
                        Routes.professionalProfileEdit,
                        arguments: p,
                      );
                      if (result == true) {
                        await controller.reload();
                      }
                    });
                  },
                ),
            ],
          );
        }),
        ),
      ),
    );
  }
}

/// حد أدنى لنقاط الخبرة لكتابة توصية لطبيب آخر.
const int _kMinPointsToGiveRecommendation = 59;

/// أسفل بطاقة الهوية: أشرطة قابلة للتمرير — معلومات | صور | شهادات | تقييمات | توصيات.
class _ProfileTabbedSection extends StatefulWidget {
  const _ProfileTabbedSection({
    super.key,
    required this.p,
    required this.mediaUrl,
    this.canSubmitPeerRating = false,
    this.canSubmitRecommendation = false,
    this.sessionExperiencePoints = 0,
    this.isOwnProfile = false,
    this.canManageGallery = false,
    this.onAddGalleryCase,
    this.onRequestDeleteGalleryCase,
    this.canManageCertificates = false,
    this.onAddCertificate,
    this.onRequestDeleteCertificate,
  });

  final DoctorProfileFull p;
  final String Function(String?) mediaUrl;
  final bool canSubmitPeerRating;
  final bool canSubmitRecommendation;
  final int sessionExperiencePoints;
  final bool isOwnProfile;
  final bool canManageGallery;
  final VoidCallback? onAddGalleryCase;
  final Future<void> Function(int index)? onRequestDeleteGalleryCase;
  final bool canManageCertificates;
  final VoidCallback? onAddCertificate;
  final Future<void> Function(int index)? onRequestDeleteCertificate;

  @override
  State<_ProfileTabbedSection> createState() => _ProfileTabbedSectionState();
}

class _ProfileTabbedSectionState extends State<_ProfileTabbedSection> {
  int _tabIndex = 0;
  final _ratingsTabKey = GlobalKey<_ProfileRatingsTabState>();

  void openRatingsTab() => _selectTab(3);

  void _selectTab(int index) {
    setState(() => _tabIndex = index);
    if (index == 3) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _ratingsTabKey.currentState?.reload();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.p;
    final hasBio = (p.bio ?? '').trim().isNotEmpty;
    final hasEducation = p.education.isNotEmpty;
    final hasLanguages = p.languages.isNotEmpty;
    final hasSkills = p.skillIds.isNotEmpty;
    final hasExperiences = p.experiences.isNotEmpty;
    final hasGallery = p.gallery.isNotEmpty;
    final hasCertificates = p.certificateImages.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: EdgeInsets.all(4.r),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(color: _Modern.mutedLine.withValues(alpha: 0.85)),
            boxShadow: [
              BoxShadow(
                color: _Modern.softShadow,
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              textDirection: TextDirection.rtl,
              children: [
                _ProfileTabChip(
                  label: 'المعلومات',
                  icon: Icons.person_outline_rounded,
                  selected: _tabIndex == 0,
                  onTap: () => _selectTab(0),
                ),
                SizedBox(width: 6.w),
                _ProfileTabChip(
                  label: 'الصور',
                  icon: Icons.image_outlined,
                  selected: _tabIndex == 1,
                  onTap: () => _selectTab(1),
                ),
                SizedBox(width: 6.w),
                _ProfileTabChip(
                  label: 'الشهادات',
                  icon: Icons.verified_rounded,
                  selected: _tabIndex == 2,
                  onTap: () => _selectTab(2),
                ),
                SizedBox(width: 6.w),
                _ProfileTabChip(
                  label: 'التقييمات',
                  icon: Icons.star_rate_rounded,
                  selected: _tabIndex == 3,
                  onTap: () => _selectTab(3),
                ),
                SizedBox(width: 6.w),
                _ProfileTabChip(
                  label: 'التوصيات',
                  icon: Icons.recommend_rounded,
                  selected: _tabIndex == 4,
                  onTap: () => _selectTab(4),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 6.h),
        IndexedStack(
          index: _tabIndex,
          sizing: StackFit.loose,
          children: [
            _ProfileInfoTab(
              p: p,
              hasBio: hasBio,
              hasEducation: hasEducation,
              hasLanguages: hasLanguages,
              hasSkills: hasSkills,
              hasExperiences: hasExperiences,
            ),
            _ProfileGalleryTab(
              hasGallery: hasGallery,
              gallery: p.gallery,
              mediaUrl: widget.mediaUrl,
              canManage: widget.canManageGallery,
              onAddCase: widget.onAddGalleryCase,
              onRequestDeleteCase: widget.onRequestDeleteGalleryCase,
            ),
            _ProfileCertificatesTab(
              hasCertificates: hasCertificates,
              certs: p.certificateImages,
              mediaUrl: widget.mediaUrl,
              canManage: widget.canManageCertificates,
              onAddCertificate: widget.onAddCertificate,
              onRequestDeleteCertificate: widget.onRequestDeleteCertificate,
            ),
            _ProfileRatingsTab(
              key: _ratingsTabKey,
              targetDoctorId: p.id,
              canSubmitRating: widget.canSubmitPeerRating,
              isOwnProfile: widget.isOwnProfile,
              doctorName: p.name,
            ),
            _ProfileRecommendationsTab(
              canSubmitRecommendation: widget.canSubmitRecommendation,
              sessionExperiencePoints: widget.sessionExperiencePoints,
              doctorName: p.name,
              isOwnProfile: widget.isOwnProfile,
            ),
          ],
        ),
      ],
    );
  }
}

class _ProfileTabChip extends StatelessWidget {
  const _ProfileTabChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14.r),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(vertical: 11.h, horizontal: 14.w),
          decoration: BoxDecoration(
            gradient: selected ? _Modern.accentStroke : null,
            color: selected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(
              color: selected ? Colors.transparent : _Modern.mutedLine.withValues(alpha: 0.6),
              width: 1,
            ),
          ),
          child: Row(
            textDirection: TextDirection.rtl,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20.sp,
                color: selected ? Colors.white : _Modern.titleInk.withValues(alpha: 0.65),
              ),
              SizedBox(width: 8.w),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Lama Sans',
                  fontWeight: FontWeight.w800,
                  fontSize: 13.sp,
                  height: 1.2,
                  color: selected ? Colors.white : _Modern.titleInk,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileInfoTab extends StatelessWidget {
  const _ProfileInfoTab({
    required this.p,
    required this.hasBio,
    required this.hasEducation,
    required this.hasLanguages,
    required this.hasSkills,
    required this.hasExperiences,
  });

  final DoctorProfileFull p;
  final bool hasBio;
  final bool hasEducation;
  final bool hasLanguages;
  final bool hasSkills;
  final bool hasExperiences;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        hasBio
            ? _AboutSection(bio: p.bio ?? '')
            : const _MedicalEmptySectionCard(
                title: 'نبذة تعريفية',
                hint: 'أضف نبذة قصيرة عن خبرتك لتعزيز ثقة المرضى بك.',
                icon: Icons.description_outlined,
              ),
        SizedBox(height: 16.h),
        _EducationSectionTitle(),
        SizedBox(height: 10.h),
        hasEducation
            ? _EducationBlock(education: p.education)
            : const _MedicalEmptySectionCard(
                title: 'التعليم',
                hint: 'أدخل مؤهلاتك الأكاديمية لإبراز خلفيتك العلمية.',
                icon: Icons.school_outlined,
              ),
        SizedBox(height: 20.h),
        _LanguagesSectionTitle(),
        SizedBox(height: 10.h),
        hasLanguages
            ? _LanguagesBox(languages: p.languages)
            : const _MedicalEmptySectionCard(
                title: 'اللغات',
                hint: 'أضف اللغات التي تتقنها لتسهيل التواصل مع المرضى.',
                icon: Icons.translate_rounded,
              ),
        SizedBox(height: 20.h),
        _SkillsSectionTitle(),
        SizedBox(height: 10.h),
        hasSkills
            ? _SkillsWrap(skills: p.skillIds)
            : const _MedicalEmptySectionCard(
                title: 'المهارات الأساسية',
                hint: 'شارك أهم مهاراتك السريرية والتقنية.',
                icon: Icons.psychology_alt_outlined,
              ),
        SizedBox(height: 20.h),
        _ExperiencesSectionTitle(),
        SizedBox(height: 10.h),
        hasExperiences
            ? _ExperiencesList(experiences: p.experiences)
            : const _MedicalEmptySectionCard(
                title: 'الخبرات',
                hint: 'أضف خبراتك العملية لعرض مسيرتك المهنية.',
                icon: Icons.work_outline_rounded,
              ),
      ],
    );
  }
}

/// أيقونة إضافة حالة — نفس تدرج وحجم أيقونة عنوان [_ModernSectionTitle].
class _GalleryAddCaseIconButton extends StatelessWidget {
  const _GalleryAddCaseIconButton({
    required this.onPressed,
    this.tooltip = 'إضافة حالة جديدة',
  });

  final VoidCallback onPressed;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14.r),
          child: Ink(
            decoration: BoxDecoration(
              gradient: _Modern.accentStroke,
              borderRadius: BorderRadius.circular(14.r),
              boxShadow: [
                BoxShadow(
                  color: _Modern.shadowPrimary(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(10.r),
              child: Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: 20.sp,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileGalleryTab extends StatelessWidget {
  const _ProfileGalleryTab({
    required this.hasGallery,
    required this.gallery,
    required this.mediaUrl,
    this.canManage = false,
    this.onAddCase,
    this.onRequestDeleteCase,
  });

  final bool hasGallery;
  final List<GalleryItemDto> gallery;
  final String Function(String?) mediaUrl;
  final bool canManage;
  final VoidCallback? onAddCase;
  final Future<void> Function(int index)? onRequestDeleteCase;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (canManage && onAddCase != null)
          Row(
            textDirection: TextDirection.rtl,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: _ScientificLibrarySectionTitle()),
              _GalleryAddCaseIconButton(onPressed: onAddCase!),
            ],
          )
        else
          _ScientificLibrarySectionTitle(),
        SizedBox(height: 10.h),
        hasGallery
            ? _GallerySection(
                gallery: gallery,
                mediaUrl: mediaUrl,
                showDeleteActions: canManage && onRequestDeleteCase != null,
                onDeleteCase: onRequestDeleteCase,
              )
            : const _MedicalEmptySectionCard(
                title: 'الصور',
                hint: 'أضف حالاتك المميزة ودع نتائجك تتحدث عنك.',
                icon: Icons.photo_library_outlined,
              ),
      ],
    );
  }
}

class _ProfileRatingsTab extends StatefulWidget {
  const _ProfileRatingsTab({
    super.key,
    required this.targetDoctorId,
    required this.canSubmitRating,
    this.isOwnProfile = false,
    this.doctorName,
  });

  final String targetDoctorId;
  final bool canSubmitRating;
  final bool isOwnProfile;
  final String? doctorName;

  @override
  State<_ProfileRatingsTab> createState() => _ProfileRatingsTabState();
}

class _ProfileRatingsTabState extends State<_ProfileRatingsTab> {
  DoctorPeerRatingsPage? _page;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load(showSpinner: true);
  }

  @override
  void didUpdateWidget(covariant _ProfileRatingsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.targetDoctorId != widget.targetDoctorId ||
        oldWidget.isOwnProfile != widget.isOwnProfile) {
      _load(showSpinner: true);
    }
  }

  void reload() => _load(showSpinner: _page == null);

  Future<void> _load({bool showSpinner = false}) async {
    if (showSpinner || _page == null) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final page = widget.isOwnProfile
          ? await ApiService.instance.fetchMyPeerRatings()
          : await ApiService.instance.fetchDoctorPeerRatings(
              widget.targetDoctorId,
            );
      if (!mounted) return;
      setState(() {
        _page = page;
        _loading = false;
        _error = null;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _openRatingDialog() async {
    final result = await showDoctorPeerRatingDialog(
      context,
      doctorName: widget.doctorName,
    );
    if (result == null || !mounted) return;
    try {
      final submitted = await ApiService.instance.submitDoctorPeerRating(
        doctorUserId: widget.targetDoctorId,
        stars: result.stars,
        comment: result.comment,
      );
      if (!mounted) return;
      setState(() {
        final base = _page ??
            const DoctorPeerRatingsPage(
              ratings: [],
              totalCount: 0,
              currentUserHasRated: false,
            );
        _page = base.withAddedRating(submitted);
        _loading = false;
        _error = null;
      });
      await _load(showSpinner: false);
      if (!mounted) return;
      Get.snackbar(
        'تم التقييم',
        'ظهر تقييمك في القائمة مباشرة',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      Get.snackbar('تعذر الإرسال', e.message, snackPosition: SnackPosition.BOTTOM);
    }
  }

  @override
  Widget build(BuildContext context) {
    final page = _page;
    final canRate = widget.canSubmitRating &&
        page != null &&
        !page.currentUserHasRated;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'تقييمات الأطباء والزملاء عن الخبرة والتعامل المهني.',
          textAlign: TextAlign.right,
          style: TextStyle(
            fontFamily: 'Lama Sans',
            fontWeight: FontWeight.w600,
            fontSize: 12.5.sp,
            height: 1.45,
            color: const Color(0xFF64748B),
          ),
        ),
        if (canRate) ...[
          SizedBox(height: 14.h),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _openRatingDialog,
              icon: Icon(Icons.star_rounded, size: 20.sp),
              label: Text(
                'قيّم الطبيب',
                style: TextStyle(
                  fontFamily: 'Lama Sans',
                  fontWeight: FontWeight.w900,
                  fontSize: 15.sp,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: _Modern.appBlue,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 14.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.r),
                ),
              ),
            ),
          ),
        ] else if (!widget.canSubmitRating) ...[
          SizedBox(height: 6.h),
          Text(
            'التقييمات الواردة لملفك من الأطباء والزملاء.',
            style: TextStyle(
              fontFamily: 'Lama Sans',
              fontWeight: FontWeight.w600,
              fontSize: 12.sp,
              color: const Color(0xFF94A3B8),
            ),
          ),
        ],
        SizedBox(height: 14.h),
        if (_loading && page == null)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 24.h),
            child: const Center(
              child: CircularProgressIndicator(color: _Pv.blue),
            ),
          )
        else if (_error != null && page == null)
          Text(
            _error!,
            style: TextStyle(
              fontFamily: 'Lama Sans',
              fontSize: 13.sp,
              color: const Color(0xFFE53935),
            ),
          )
        else if (page == null || page.ratings.isEmpty)
          Text(
            'لا توجد تقييمات بعد.',
            style: TextStyle(
              fontFamily: 'Lama Sans',
              fontWeight: FontWeight.w600,
              fontSize: 13.sp,
              color: const Color(0xFF94A3B8),
            ),
          )
        else ...[
          if (page.averageStars != null) ...[
            Row(
              textDirection: TextDirection.rtl,
              children: [
                Icon(Icons.star_rounded, color: const Color(0xFFF59E0B), size: 22.sp),
                SizedBox(width: 6.w),
                Text(
                  '${page.averageStars}',
                  style: TextStyle(
                    fontFamily: 'Lama Sans',
                    fontWeight: FontWeight.w900,
                    fontSize: 18.sp,
                    color: _Modern.titleInk,
                  ),
                ),
                SizedBox(width: 6.w),
                Text(
                  '(${page.totalCount} تقييم)',
                  style: TextStyle(
                    fontFamily: 'Lama Sans',
                    fontWeight: FontWeight.w600,
                    fontSize: 12.5.sp,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
          ],
          ...page.ratings.map(
            (r) => Padding(
              padding: EdgeInsets.only(bottom: 10.h),
              child: _PeerRatingCard(rating: r),
            ),
          ),
        ],
      ],
    );
  }
}

class _PeerRatingCard extends StatelessWidget {
  const _PeerRatingCard({required this.rating});

  final DoctorPeerRatingItem rating;

  @override
  Widget build(BuildContext context) {
    final name = (rating.raterName ?? '').trim();
    final displayName = name.isNotEmpty ? name : 'طبيب';

    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: _Modern.softShadow,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            textDirection: TextDirection.rtl,
            children: [
              CircleAvatar(
                radius: 20.r,
                backgroundColor: const Color(0xFFEFF6FF),
                backgroundImage: (rating.raterImageUrl ?? '').isNotEmpty
                    ? NetworkImage(resolveMediaUrl(rating.raterImageUrl))
                    : null,
                child: (rating.raterImageUrl ?? '').isEmpty
                    ? Icon(Icons.person_rounded, color: _Modern.appBlue, size: 22.sp)
                    : null,
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: TextStyle(
                        fontFamily: 'Lama Sans',
                        fontWeight: FontWeight.w900,
                        fontSize: 14.sp,
                        color: _Modern.titleInk,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    _StarDisplayRow(stars: rating.stars),
                  ],
                ),
              ),
            ],
          ),
          if (rating.comment.trim().isNotEmpty) ...[
            SizedBox(height: 10.h),
            Text(
              rating.comment.trim(),
              textAlign: TextAlign.right,
              style: TextStyle(
                fontFamily: 'Lama Sans',
                fontWeight: FontWeight.w600,
                fontSize: 13.sp,
                height: 1.45,
                color: const Color(0xFF475569),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StarDisplayRow extends StatelessWidget {
  const _StarDisplayRow({required this.stars});

  final int stars;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      textDirection: TextDirection.rtl,
      children: List.generate(5, (i) {
        final filled = i < stars;
        return Icon(
          filled ? Icons.star_rounded : Icons.star_outline_rounded,
          size: 16.sp,
          color: filled ? const Color(0xFFF59E0B) : const Color(0xFFCBD5E1),
        );
      }),
    );
  }
}

class _ProfileRecommendationsTab extends StatelessWidget {
  const _ProfileRecommendationsTab({
    this.canSubmitRecommendation = false,
    this.sessionExperiencePoints = 0,
    this.doctorName,
    this.isOwnProfile = false,
  });

  final bool canSubmitRecommendation;
  final int sessionExperiencePoints;
  final String? doctorName;
  final bool isOwnProfile;

  Future<void> _onAddRecommendation(BuildContext context) async {
    if (sessionExperiencePoints < _kMinPointsToGiveRecommendation) {
      Get.snackbar(
        'غير متاح',
        'تحتاج $_kMinPointsToGiveRecommendation نقطة خبرة فأكثر لكتابة توصية لطبيب آخر.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 4),
      );
      return;
    }
    final result = await showDoctorRecommendationDialog(
      context,
      doctorName: doctorName,
    );
    if (result == null) return;
    Get.snackbar(
      'قريباً',
      'حفظ التوصيات على السيرفر سيُفعَّل قريباً',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 3),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          isOwnProfile
              ? 'توصيات واردة من أطباء ذوي خبرة عالية في المنصة.'
              : 'توصية مهنية من طبيب بخبرة $_kMinPointsToGiveRecommendation نقطة فأكثر.',
          textAlign: TextAlign.right,
          style: TextStyle(
            fontFamily: 'Lama Sans',
            fontWeight: FontWeight.w600,
            fontSize: 12.5.sp,
            height: 1.45,
            color: const Color(0xFF64748B),
          ),
        ),
        if (canSubmitRecommendation) ...[
          SizedBox(height: 14.h),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _onAddRecommendation(context),
              icon: Icon(Icons.recommend_rounded, size: 20.sp),
              label: Text(
                'إضافة توصية',
                style: TextStyle(
                  fontFamily: 'Lama Sans',
                  fontWeight: FontWeight.w900,
                  fontSize: 15.sp,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: _Modern.appBlue,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 14.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.r),
                ),
              ),
            ),
          ),
        ],
        SizedBox(height: 14.h),
        Text(
          'لا توجد توصيات بعد.',
          style: TextStyle(
            fontFamily: 'Lama Sans',
            fontWeight: FontWeight.w600,
            fontSize: 13.sp,
            color: const Color(0xFF94A3B8),
          ),
        ),
      ],
    );
  }
}

class _ProfileCertificatesTab extends StatelessWidget {
  const _ProfileCertificatesTab({
    required this.hasCertificates,
    required this.certs,
    required this.mediaUrl,
    this.canManage = false,
    this.onAddCertificate,
    this.onRequestDeleteCertificate,
  });

  final bool hasCertificates;
  final List<CertificateImageDto> certs;
  final String Function(String?) mediaUrl;
  final bool canManage;
  final VoidCallback? onAddCertificate;
  final Future<void> Function(int index)? onRequestDeleteCertificate;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (canManage && onAddCertificate != null)
          Row(
            textDirection: TextDirection.rtl,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: _CertificatesSectionTitle()),
              _GalleryAddCaseIconButton(
                onPressed: onAddCertificate!,
                tooltip: 'إضافة شهادة',
              ),
            ],
          )
        else
          _CertificatesSectionTitle(),
        SizedBox(height: 10.h),
        hasCertificates
            ? _CertificatesPostsSection(
                certs: certs,
                mediaUrl: mediaUrl,
                showDeleteActions: canManage && onRequestDeleteCertificate != null,
                onDeleteCertificate: onRequestDeleteCertificate,
              )
            : const _MedicalEmptySectionCard(
                title: 'الشهادات',
                hint: 'أضف شهاداتك المهنية لرفع مصداقيتك بشكل أقوى.',
                icon: Icons.verified_outlined,
              ),
      ],
    );
  }
}

class _EditFooter extends StatelessWidget {
  const _EditFooter({required this.onEdit});

  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 12.h),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.94),
          border: Border(top: BorderSide(color: _Modern.mutedLine.withValues(alpha: 0.8))),
          boxShadow: [
            BoxShadow(
              color: _Modern.softShadow,
              blurRadius: 20,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: SizedBox(
          width: double.infinity,
          height: 54.h,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: _Modern.heroGradient,
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: _Modern.shadowPrimary(0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onEdit,
                borderRadius: BorderRadius.circular(16.r),
                child: Center(
                  child: Text(
                    'تعديل البروفايل',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.w700,
                      fontSize: 16.sp,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
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

class _ProfileCompletionHero extends StatelessWidget {
  const _ProfileCompletionHero({
    required this.completion,
    required this.completedCount,
    required this.totalCount,
  });

  final double completion;
  final int completedCount;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    final percent = (completion * 100).round().clamp(0, 100);
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 353.w),
        child: Container(
          decoration: BoxDecoration(
            gradient: _Modern.heroGradient,
            borderRadius: BorderRadius.circular(26.r),
            boxShadow: [
              BoxShadow(
                color: _Modern.shadowPrimary(0.35),
                blurRadius: 28,
                offset: const Offset(0, 14),
                spreadRadius: -4,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26.r),
            child: Stack(
              children: [
                Positioned(
                  right: -20.w,
                  top: -24.h,
                  child: Icon(
                    Icons.blur_on_rounded,
                    size: 120.sp,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(14.w, 11.h, 14.w, 11.h),
                  child: Row(
                    children: [
                      Container(
                        width: 40.w,
                        height: 40.w,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(14.r),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.35),
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          Icons.auto_awesome_rounded,
                          color: Colors.white,
                          size: 22.sp,
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'اكتمال البروفايل',
                              style: TextStyle(
                                fontFamily: 'Lama Sans',
                                fontWeight: FontWeight.w800,
                                fontSize: 12.sp,
                                letterSpacing: 0.5,
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                            ),
                            SizedBox(height: 1.h),
                            Text(
                              '$percent%',
                              style: TextStyle(
                                fontFamily: 'Lama Sans',
                                fontWeight: FontWeight.w900,
                                fontSize: 22.sp,
                                height: 1.05,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 3.h),
                            Text(
                              'أكملت $completedCount من $totalCount أقسام — وسّع تأثيرك المهني',
                              style: TextStyle(
                                fontFamily: 'Lama Sans',
                                fontWeight: FontWeight.w600,
                                fontSize: 11.sp,
                                height: 1.35,
                                color: Colors.white.withValues(alpha: 0.92),
                              ),
                            ),
                            SizedBox(height: 8.h),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(99.r),
                              child: LinearProgressIndicator(
                                value: completion.clamp(0.0, 1.0),
                                minHeight: 5.h,
                                backgroundColor: Colors.white.withValues(alpha: 0.22),
                                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFBBF7D0)),
                              ),
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

/// عنوان قسم — شريط لوني + أيقونة + تدرج خفيف.
class _ModernSectionTitle extends StatelessWidget {
  const _ModernSectionTitle({
    required this.label,
    required this.icon,
  });

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 2.h),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Container(
            padding: EdgeInsets.all(10.r),
            decoration: BoxDecoration(
              gradient: _Modern.accentStroke,
              borderRadius: BorderRadius.circular(14.r),
              boxShadow: [
                BoxShadow(
                  color: _Modern.shadowPrimary(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 20.sp),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  label,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontFamily: 'Lama Sans',
                    fontWeight: FontWeight.w900,
                    fontSize: 17.sp,
                    height: 1.25,
                    letterSpacing: -0.3,
                    color: _Modern.titleInk,
                  ),
                ),
                SizedBox(height: 6.h),
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    height: 3.h,
                    width: 56.w,
                    decoration: BoxDecoration(
                      gradient: _Modern.accentStroke,
                      borderRadius: BorderRadius.circular(99.r),
                    ),
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

class _MedicalEmptySectionCard extends StatelessWidget {
  const _MedicalEmptySectionCard({
    required this.title,
    required this.hint,
    required this.icon,
  });

  final String title;
  final String hint;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 353.w),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 16.h),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(22.r),
            border: Border.all(
              color: const Color(0xFFCBD5E1).withValues(alpha: 0.7),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: _Modern.softShadow,
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            textDirection: TextDirection.rtl,
            children: [
              Container(
                width: 46.w,
                height: 46.w,
                decoration: BoxDecoration(
                  gradient: _Modern.accentStroke,
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Icon(icon, size: 22.sp, color: Colors.white),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      title,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontFamily: 'Lama Sans',
                        fontWeight: FontWeight.w800,
                        fontSize: 14.5.sp,
                        color: _Modern.titleInk,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      hint,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontFamily: 'Lama Sans',
                        fontWeight: FontWeight.w600,
                        fontSize: 12.sp,
                        height: 1.5,
                        color: _Pv.experienceMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EducationSectionTitle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const _ModernSectionTitle(
      label: 'التعليم',
      icon: Icons.school_rounded,
    );
  }
}

class _LanguagesSectionTitle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const _ModernSectionTitle(
      label: 'اللغات',
      icon: Icons.translate_rounded,
    );
  }
}

class _SkillsSectionTitle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const _ModernSectionTitle(
      label: 'المهارات الأساسية',
      icon: Icons.psychology_alt_rounded,
    );
  }
}

class _ExperiencesSectionTitle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const _ModernSectionTitle(
      label: 'الخبرات',
      icon: Icons.work_history_rounded,
    );
  }
}

class _ScientificLibrarySectionTitle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const _ModernSectionTitle(
      label: 'الصور',
      icon: Icons.image_outlined,
    );
  }
}

class _CertificatesSectionTitle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const _ModernSectionTitle(
      label: 'الشهادات',
      icon: Icons.verified_rounded,
    );
  }
}

/// ألوان بطاقة الهوية الرسمية (أبيض / أسود / رمادي).
abstract final class _OfficialIdCard {
  static const Color ink = Color(0xFF0F172A);
  static const Color muted = Color(0xFF64748B);
  static const Color line = Color(0xFFE2E8F0);
  static const Color wash = Color(0xFFF8FAFC);
}

String _officialCardNumber(String id) {
  final clean = id.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
  if (clean.length >= 8) return 'DG-${clean.substring(0, 8).toUpperCase()}';
  if (clean.isNotEmpty) return 'DG-${clean.toUpperCase()}';
  return 'DG-00000000';
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.p, required this.mediaUrl});

  final DoctorProfileFull p;
  final String Function(String?) mediaUrl;

  @override
  Widget build(BuildContext context) {
    final cardW = 398.w;
    final radius = 12.r;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: cardW),
        child: Container(
          width: cardW,
          decoration: BoxDecoration(
            color: _Pv.white,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: _OfficialIdCard.line, width: 1),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1A0F172A),
                blurRadius: 16,
                offset: Offset(0, 6),
                spreadRadius: -4,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: Stack(
              children: [
                Positioned(
                  left: cardW * 0.42,
                  top: 12.h,
                  child: Opacity(
                    opacity: 0.045,
                    child: Image.asset(
                      'assets/logo/logodental1.png',
                      width: 120.w,
                      height: 120.w,
                      fit: BoxFit.contain,
                      gaplessPlayback: true,
                    ),
                  ),
                ),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, 8.h),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _HeaderCardTopBar(
                              cardNumber: _officialCardNumber(p.id),
                            ),
                            SizedBox(height: 8.h),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _HeaderCardDoctorPhoto(
                                  url: mediaUrl(p.imageUrl),
                                ),
                                SizedBox(width: 10.w),
                                Expanded(child: _HeaderCardLeadText(p: p)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(height: 1, color: _OfficialIdCard.line),
                      Container(
                        color: _OfficialIdCard.wash,
                        padding: EdgeInsets.fromLTRB(12.w, 7.h, 12.w, 7.h),
                        child: _HeaderCardContactOverlay(p: p),
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

class _HeaderCardTopBar extends StatelessWidget {
  const _HeaderCardTopBar({required this.cardNumber});

  final String cardNumber;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Image.asset(
          'assets/logo/logodental1.png',
          width: 30.w,
          height: 30.w,
          fit: BoxFit.contain,
          gaplessPlayback: true,
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Professional Identity Card',
                style: TextStyle(
                  fontFamily: 'Lama Sans',
                  fontWeight: FontWeight.w900,
                  fontSize: 13.sp,
                  height: 1.2,
                  color: _OfficialIdCard.ink,
                  letterSpacing: -0.2,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                'Dental Gate Community Membership Card',
                style: TextStyle(
                  fontFamily: 'Lama Sans',
                  fontWeight: FontWeight.w600,
                  fontSize: 8.5.sp,
                  height: 1.2,
                  color: _OfficialIdCard.muted,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: 8.w),
        Text(
          cardNumber,
          style: TextStyle(
            fontFamily: 'Lama Sans',
            fontWeight: FontWeight.w700,
            fontSize: 9.sp,
            height: 1.2,
            color: _OfficialIdCard.muted,
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
  }
}

/// صفوف المعلومات في القسم السفلي — تسميات إنجليزية بدون أيقونات.
class _HeaderCardContactOverlay extends StatelessWidget {
  const _HeaderCardContactOverlay({required this.p});

  final DoctorProfileFull p;

  static Widget _labeledRow(String label, String value) {
    final style = TextStyle(
      fontFamily: 'Lama Sans',
      fontWeight: FontWeight.w600,
      fontSize: 11.5.sp,
      height: 1.3,
      color: _OfficialIdCard.ink,
    );

    return Text(
      '$label: $value',
      style: style,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  @override
  Widget build(BuildContext context) {
    final rows = <(String, String)>[
      ('  Phone number  ', IdCardEnglishText.phone(p.phone)),
      ('  City  ', IdCardEnglishText.city(p.governorate)),
      ('  Age  ', IdCardEnglishText.age(p.age)),
      ('  Gender  ', IdCardEnglishText.gender(p.gender)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) SizedBox(height: 4.h),
          _labeledRow(rows[i].$1, rows[i].$2),
        ],
      ],
    );
  }
}

/// اسم الطبيب والتخصص ورقم البطاقة — بجانب الصورة في القسم العلوي.
class _HeaderCardLeadText extends StatelessWidget {
  const _HeaderCardLeadText({required this.p});

  final DoctorProfileFull p;

  @override
  Widget build(BuildContext context) {
    final name = IdCardEnglishText.name(p.name);
    final specRaw = p.professionalTitle?.trim() ?? '';
    final spec = specRaw.isNotEmpty ? IdCardEnglishText.specialty(specRaw) : '';
    final cardNo = _officialCardNumber(p.id);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          name,
          style: TextStyle(
            fontFamily: 'Lama Sans',
            fontWeight: FontWeight.w800,
            fontSize: 15.sp,
            height: 1.3,
            color: _OfficialIdCard.ink,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (spec.isNotEmpty) ...[
          SizedBox(height: 3.h),
          Text(
            spec,
            style: TextStyle(
              fontFamily: 'Lama Sans',
              fontWeight: FontWeight.w600,
              fontSize: 11.5.sp,
              height: 1.35,
              color: _OfficialIdCard.muted,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ] else ...[
          SizedBox(height: 3.h),
          Text(
            'Add your specialty',
            style: TextStyle(
              fontFamily: 'Lama Sans',
              fontWeight: FontWeight.w600,
              fontSize: 11.sp,
              height: 1.35,
              color: _Modern.appBlue,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        SizedBox(height: 5.h),
        Text(
          cardNo,
          style: TextStyle(
            fontFamily: 'Lama Sans',
            fontWeight: FontWeight.w900,
            fontSize: 15.sp,
            height: 1.1,
            color: _OfficialIdCard.ink,
            letterSpacing: 0.6,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

/// صورة الطبيب — مربعة بزوايا حادة (أسلوب بطاقة هوية رسمية).
class _HeaderCardDoctorPhoto extends StatelessWidget {
  const _HeaderCardDoctorPhoto({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final side = 64.w;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final cachePx = (side * dpr).round().clamp(100, 1024);

    return Container(
      width: side,
      height: side,
      decoration: BoxDecoration(
        color: _OfficialIdCard.wash,
        border: Border.all(color: _OfficialIdCard.line, width: 1),
      ),
      child: url.isEmpty
          ? Icon(
              Icons.person_rounded,
              size: 36.sp,
              color: _OfficialIdCard.muted.withValues(alpha: 0.45),
            )
          : Image.network(
              url,
              width: side,
              height: side,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              cacheWidth: cachePx,
              errorBuilder: (context, error, stackTrace) => Icon(
                Icons.person_rounded,
                size: 36.sp,
                color: _OfficialIdCard.muted.withValues(alpha: 0.45),
              ),
            ),
    );
  }
}

/// إطار بطاقة بل مسار لوني رفيع — مظهر زجاجي عصري.
class _ModernGradientFrame extends StatelessWidget {
  const _ModernGradientFrame({
    required this.child,
    this.padding,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final outerR = 24.r;
    final innerR = 22.r;
    return Container(
      decoration: BoxDecoration(
        gradient: _Modern.accentStroke,
        borderRadius: BorderRadius.circular(outerR),
        boxShadow: [
          BoxShadow(
            color: _Modern.shadowPrimary(0.14),
            blurRadius: 22,
            offset: const Offset(0, 10),
            spreadRadius: -2,
          ),
        ],
      ),
      padding: EdgeInsets.all(1.35.r),
      child: Container(
        decoration: BoxDecoration(
          color: _Modern.shellInner,
          borderRadius: BorderRadius.circular(innerR),
        ),
        padding: padding ?? EdgeInsets.all(10.r),
        child: child,
      ),
    );
  }
}

class _AboutSection extends StatefulWidget {
  const _AboutSection({required this.bio});

  final String bio;

  @override
  State<_AboutSection> createState() => _AboutSectionState();
}

class _AboutSectionState extends State<_AboutSection> {
  bool _expanded = false;

  static double _linkHeight(TextStyle linkStyle, double maxWidth) {
    final p = TextPainter(
      text: TextSpan(text: 'عرض المزيد..', style: linkStyle),
      textDirection: TextDirection.rtl,
      maxLines: 1,
    )..layout(maxWidth: maxWidth);
    return p.height;
  }

  @override
  Widget build(BuildContext context) {
    final text = _clampBioDisplay(widget.bio);
    if (text.isEmpty) return const SizedBox.shrink();

    final titleStyle = TextStyle(
      fontFamily: 'Lama Sans',
      fontWeight: FontWeight.w900,
      fontSize: 16.6.sp,
      height: 1.5,
      letterSpacing: -0.2,
      color: _Modern.titleInk,
    );
    final bodyStyle = TextStyle(
      fontFamily: 'Lama Sans',
      fontWeight: FontWeight.w600,
      fontSize: 14.sp,
      height: 2.0,
      letterSpacing: 0,
      color: _Modern.titleInk,
    );
    final linkStyle = TextStyle(
      fontFamily: 'Lama Sans',
      fontWeight: FontWeight.w700,
      fontSize: 14.sp,
      height: 2.0,
      letterSpacing: 0,
      color: _Modern.appBlue,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardW = math.min(353.w, constraints.maxWidth);
        final hPad = 10.w * 2 + 8.w * 2;
        final contentW = (cardW - hPad).clamp(0.0, double.infinity);

        final cardVPad = 8.h + 10.h;
        final innerCollapsed = 143.h - cardVPad;

        final fullH = _measurePlainTextHeight(text, contentW, bodyStyle);
        final needsToggle = fullH > innerCollapsed + 0.5;

        final linkH = _linkHeight(linkStyle, contentW);
        final gap = 4.h;
        final textAreaCollapsedH =
            needsToggle ? (innerCollapsed - linkH - gap).clamp(0.0, double.infinity) : innerCollapsed;

        final collapsedLines = needsToggle && !_expanded
            ? _maxLinesFittingHeight(
                text: text,
                maxWidth: contentW,
                maxHeight: textAreaCollapsedH,
                style: bodyStyle,
              )
            : null;

        final cardMaxCollapsed = 143.h;

        Widget cardChild;
        if (_expanded) {
          cardChild = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                text,
                textAlign: TextAlign.justify,
                style: bodyStyle,
              ),
              SizedBox(height: 6.h),
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => _expanded = false),
                  child: Text('عرض أقل', style: linkStyle),
                ),
              ),
            ],
          );
        } else if (needsToggle) {
          cardChild = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Text(
                  text,
                  textAlign: TextAlign.justify,
                  style: bodyStyle,
                  maxLines: collapsedLines,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(height: gap),
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => _expanded = true),
                  child: Text('عرض المزيد..', style: linkStyle),
                ),
              ),
            ],
          );
        } else {
          cardChild = Text(
            text,
            textAlign: TextAlign.justify,
            style: bodyStyle,
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              textDirection: TextDirection.rtl,
              children: [
                Container(
                  padding: EdgeInsets.all(8.r),
                  decoration: BoxDecoration(
                    gradient: _Modern.accentStroke,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(
                    Icons.format_quote_rounded,
                    color: Colors.white,
                    size: 18.sp,
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Text(
                    'نبذة تعريفية',
                    textAlign: TextAlign.right,
                    style: titleStyle,
                  ),
                ),
              ],
            ),
            SizedBox(height: 10.h),
            Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 353.w),
                child: SizedBox(
                  width: double.infinity,
                  height: needsToggle && !_expanded ? cardMaxCollapsed : null,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: needsToggle && !_expanded ? cardMaxCollapsed : double.infinity,
                      minHeight: needsToggle && !_expanded ? cardMaxCollapsed : 0,
                    ),
                    child: _ModernGradientFrame(
                      padding: EdgeInsets.fromLTRB(10.w, 8.h, 10.w, 10.h),
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.w),
                        child: needsToggle && !_expanded
                            ? SizedBox.expand(child: cardChild)
                            : cardChild,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _EducationBlock extends StatelessWidget {
  const _EducationBlock({required this.education});

  final List<EducationEntryDto> education;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 353.w),
        child: SizedBox(
          width: double.infinity,
          child: _ModernGradientFrame(
            child: education.isEmpty
                ? Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '—',
                      style: TextStyle(fontFamily: 'Cairo', color: _Pv.subtext, fontSize: 14.sp),
                    ),
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var i = 0; i < education.length; i++)
                        _educationRow(
                          education[i],
                          isLast: i == education.length - 1,
                        ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  static const String _eduSealAsset = 'assets/icons/IMG_0635.PNG';

  Widget _educationRow(EducationEntryDto entry, {required bool isLast}) {
    final uniStyle = TextStyle(
      fontFamily: 'Lama Sans',
      fontWeight: FontWeight.w700,
      fontSize: 14.sp,
      height: 2.0,
      letterSpacing: 0,
      color: _Pv.infoInk,
    );
    final degreeStyle = TextStyle(
      fontFamily: 'Lama Sans',
      fontWeight: FontWeight.w500,
      fontSize: 14.sp,
      height: 2.0,
      letterSpacing: 0,
      color: _Pv.infoInk.withValues(alpha: 0.5),
    );
    final dateStyle = TextStyle(
      fontFamily: 'Lama Sans',
      fontWeight: FontWeight.w700,
      fontSize: 12.sp,
      height: 2.0,
      letterSpacing: 0,
      color: _Pv.infoInk.withValues(alpha: 0.5),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          textDirection: TextDirection.rtl,
          children: [
            Container(
              width: 41.3.w,
              height: 41.3.h,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _Pv.eduSealShadow,
                    blurRadius: 6.05,
                    spreadRadius: 0,
                    offset: Offset(0, 0),
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.asset(
                  _eduSealAsset,
                  width: 41.3.w,
                  height: 41.3.h,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    textDirection: TextDirection.rtl,
                    children: [
                      Expanded(
                        child: Text(
                          entry.university,
                          textAlign: TextAlign.right,
                          style: uniStyle,
                        ),
                      ),
                      Text(
                        _eduYears(entry),
                        textAlign: TextAlign.justify,
                        style: dateStyle,
                      ),
                    ],
                  ),
                  Text(
                    _educationSubtitle(entry),
                    textAlign: TextAlign.justify,
                    style: degreeStyle,
                  ),
                ],
              ),
            ),
          ],
        ),
        if (!isLast) ...[
          Center(
            child: SizedBox(
              width: 300.w,
              child: Divider(
                height: 1,
                thickness: 1,
                color: _Modern.mutedLine,
              ),
            ),
          ),
          SizedBox(height: 12.h),
        ],
      ],
    );
  }

  String _eduYears(EducationEntryDto e) {
    if (e.startYear != null && e.graduationYear != null) {
      return '${e.graduationYear} - ${e.startYear}';
    }
    if (e.graduationYear != null) {
      return '${e.graduationYear} - —';
    }
    final g = e.graduationDate;
    if (g == null || g.length < 4) return '—';
    try {
      final y = int.parse(g.substring(0, 4));
      return '${y - 5} - $y';
    } catch (_) {
      return g;
    }
  }

  String _educationSubtitle(EducationEntryDto e) {
    final degree = _degreeLabel(e.degreeType);
    final spec = e.specialty.trim();
    if (spec.isEmpty) return degree;
    return '$degree - $spec';
    }

  String _degreeLabel(String t) {
    switch (t) {
      case 'bachelor':
        return 'Bachelor of Dental Medicine and Surgery';
      case 'master':
        return 'Master';
      case 'doctorate':
        return 'Doctorate';
      case 'diploma':
        return 'Diploma';
      default:
        return t;
    }
  }
}

class _LanguagesBox extends StatelessWidget {
  const _LanguagesBox({required this.languages});

  final List<String> languages;

  @override
  Widget build(BuildContext context) {
    if (languages.isEmpty) return const SizedBox.shrink();

    final textStyle = TextStyle(
      fontFamily: 'Lama Sans',
      fontWeight: FontWeight.w900,
      fontSize: 14.sp,
      height: 2.0,
      letterSpacing: 0,
      color: _Pv.infoInk.withValues(alpha: 0.5),
    );

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 353.w, minHeight: 65.h),
        child: SizedBox(
          width: double.infinity,
          child: _ModernGradientFrame(
            padding: EdgeInsets.fromLTRB(10.r, 12.r, 10.r, 12.r),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 0.h),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < languages.length; i++) ...[
                    if (i > 0) SizedBox(height: 10.h),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      textDirection: TextDirection.rtl,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(top: 8.h),
                          child: Container(
                            width: 6.r,
                            height: 6.r,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: _Modern.accentStroke,
                            ),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            languages[i],
                            textAlign: TextAlign.justify,
                            style: textStyle,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SkillsWrap extends StatelessWidget {
  const _SkillsWrap({required this.skills});

  final List<String> skills;

  @override
  Widget build(BuildContext context) {
    if (skills.isEmpty) return const SizedBox.shrink();
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 353.w, minHeight: 117.h),
        child: SizedBox(
          width: double.infinity,
          child: _ModernGradientFrame(
            child: Wrap(
              spacing: 8.14.w,
              runSpacing: 8.14.h,
              // مع RTL: start = بداية السطر من اليمين (عربي صحيح).
              alignment: WrapAlignment.start,
              textDirection: TextDirection.rtl,
              children: skills.map((s) => _SkillChip(label: s)).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

class _SkillChip extends StatelessWidget {
  const _SkillChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return IntrinsicWidth(
      child: Container(
        decoration: BoxDecoration(
          color: _Modern.chipBg,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: _Modern.chipBorder, width: 1),
          boxShadow: [
            BoxShadow(
              color: _Modern.softShadow,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(10.w, 8.h, 10.w, 8.h),
          child: Text(
            label,
            textAlign: TextAlign.right,
            softWrap: true,
            style: TextStyle(
              fontFamily: 'Lama Sans',
              fontWeight: FontWeight.w800,
              fontSize: 12.sp,
              height: 1.45,
              letterSpacing: 0,
              color: _Modern.chipText,
            ),
          ),
        ),
      ),
    );
  }
}

class _ExperiencesList extends StatelessWidget {
  const _ExperiencesList({required this.experiences});

  final List<WorkExperienceDto> experiences;

  @override
  Widget build(BuildContext context) {
    if (experiences.isEmpty) return const SizedBox.shrink();
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 353.w),
        child: SizedBox(
          width: double.infinity,
          child: _ModernGradientFrame(
            padding: EdgeInsets.fromLTRB(10.w, 12.h, 10.w, 12.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < experiences.length; i++) ...[
                  if (i > 0) SizedBox(height: 8.h),
                  _ExperienceItemCard(
                    workplace: experiences[i].workplace,
                    role: experiences[i].experienceType,
                    rangeText: _expRange(experiences[i]),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _expRange(WorkExperienceDto e) {
    final a = _y(e.periodStart);
    final b = _y(e.periodEnd);
    if (a != null && b != null) return '$a - $b';
    if (a != null) return '$a';
    return '—';
  }

  int? _y(String? iso) {
    if (iso == null || iso.length < 4) return null;
    try {
      return int.parse(iso.substring(0, 4));
    } catch (_) {
      return null;
    }
  }
}

class _ExperienceItemCard extends StatelessWidget {
  const _ExperienceItemCard({
    required this.workplace,
    required this.role,
    required this.rangeText,
  });

  final String workplace;
  final String role;
  final String rangeText;

  @override
  Widget build(BuildContext context) {
    final titleStyle = TextStyle(
      fontFamily: 'Lama Sans',
      fontWeight: FontWeight.w900,
      fontSize: 14.sp,
      height: 1.5,
      letterSpacing: 0,
      color: _Pv.infoInk,
    );
    final roleStyle = TextStyle(
      fontFamily: 'Lama Sans',
      fontWeight: FontWeight.w500,
      fontSize: 12.sp,
      height: 1.5,
      letterSpacing: 0,
      color: _Pv.experienceMuted,
    );
    final dateStyle = TextStyle(
      fontFamily: 'Lama Sans',
      fontWeight: FontWeight.w500,
      fontSize: 12.sp,
      height: 1.5,
      letterSpacing: 0,
      color: _Pv.experienceMuted,
    );

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: _Modern.mutedLine),
        boxShadow: [
          BoxShadow(
            color: _Modern.softShadow,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            textDirection: TextDirection.rtl,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  workplace,
                  textAlign: TextAlign.right,
                  style: titleStyle,
                ),
              ),
              SizedBox(width: 12.w),
              Text(
                rangeText,
                textAlign: TextAlign.left,
                style: dateStyle,
              ),
            ],
          ),
          SizedBox(height: 4.h),
          Text(
            role,
            textAlign: TextAlign.right,
            style: roleStyle,
          ),
        ],
      ),
    );
  }
}

class _GallerySection extends StatelessWidget {
  const _GallerySection({
    required this.gallery,
    required this.mediaUrl,
    this.showDeleteActions = false,
    this.onDeleteCase,
  });

  final List<GalleryItemDto> gallery;
  final String Function(String?) mediaUrl;
  final bool showDeleteActions;
  final Future<void> Function(int index)? onDeleteCase;

  @override
  Widget build(BuildContext context) {
    if (gallery.isEmpty) return const SizedBox.shrink();
    final reversed = gallery.reversed.toList(growable: false);
    return Column(
      children: [
        for (var i = 0; i < reversed.length; i++) ...[
          if (i > 0) SizedBox(height: 14.h),
          _ScientificLibraryOuterCard(
            item: reversed[i],
            mediaUrl: mediaUrl,
            showDelete: showDeleteActions,
            onDelete: onDeleteCase == null
                ? null
                : () => onDeleteCase!(gallery.length - 1 - i),
          ),
        ],
      ],
    );
  }
}


/// عنصر معرض: عنوان ووصف يدخلهما الطبيب + صور (حتى 4) في نفس البطاقة.
class _ModernGalleryPostCard extends StatelessWidget {
  const _ModernGalleryPostCard({
    required this.title,
    required this.description,
    required this.imagePaths,
    required this.mediaUrl,
    this.showDelete = false,
    this.onDelete,
    this.deleteTooltip = 'حذف الحالة',
  });

  final String title;
  final String description;
  final List<String> imagePaths;
  final String Function(String?) mediaUrl;
  final bool showDelete;
  final VoidCallback? onDelete;
  final String deleteTooltip;

  static const int _kMaxImages = 4;
  static double get _maxCardW => 353.w;
  static const String _deleteCaseIconAsset = 'assets/icons/deletphoto.png';

  @override
  Widget build(BuildContext context) {
    final urls = imagePaths
        .map(mediaUrl)
        .where((u) => u.isNotEmpty)
        .take(_kMaxImages)
        .toList();
    final displayTitle = title.trim();
    final desc = description.trim();
    final hasTextHeader = displayTitle.isNotEmpty || desc.isNotEmpty;
    final showDeleteRow = showDelete && onDelete != null;
    final hasTopSection = hasTextHeader || showDeleteRow;
    final iconSide = 22.sp;

    Widget deleteChip() {
      return Tooltip(
        message: deleteTooltip,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onDelete,
            borderRadius: BorderRadius.circular(8.r),
            child: Padding(
              padding: EdgeInsets.all(4.r),
              child: Image.asset(
                _deleteCaseIconAsset,
                width: iconSide,
                height: iconSide,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: _maxCardW),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: _Modern.mutedLine.withValues(alpha: 0.55)),
            boxShadow: [
              BoxShadow(
                color: _Modern.softShadow,
                blurRadius: 22,
                offset: const Offset(0, 10),
                spreadRadius: -4,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(19.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (hasTopSection)
                  Padding(
                    padding: EdgeInsets.fromLTRB(14.w, 14.h, 14.w, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (displayTitle.isNotEmpty && showDeleteRow)
                          Row(
                            textDirection: TextDirection.rtl,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Text(
                                  displayTitle,
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                    fontFamily: 'Lama Sans',
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16.sp,
                                    height: 1.3,
                                    letterSpacing: -0.25,
                                    color: _Modern.titleInk,
                                  ),
                                ),
                              ),
                              SizedBox(width: 8.w),
                              deleteChip(),
                            ],
                          )
                        else if (displayTitle.isNotEmpty)
                          Text(
                            displayTitle,
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontFamily: 'Lama Sans',
                              fontWeight: FontWeight.w900,
                              fontSize: 16.sp,
                              height: 1.3,
                              letterSpacing: -0.25,
                              color: _Modern.titleInk,
                            ),
                          )
                        else if (showDeleteRow)
                          Row(
                            textDirection: TextDirection.rtl,
                            children: [
                              const Spacer(),
                              deleteChip(),
                            ],
                          ),
                        if (displayTitle.isNotEmpty && desc.isNotEmpty)
                          SizedBox(height: 8.h),
                        if (desc.isNotEmpty)
                          Text(
                            desc,
                            textAlign: TextAlign.justify,
                            style: TextStyle(
                              fontFamily: 'Lama Sans',
                              fontWeight: FontWeight.w600,
                              fontSize: 13.sp,
                              height: 1.55,
                              color: _Pv.subtext,
                            ),
                          ),
                      ],
                    ),
                  ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    12.w,
                    hasTopSection ? 14.h : 12.h,
                    12.w,
                    12.h,
                  ),
                  child: _GalleryMediaBlock(urls: urls),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

void _openFullScreenGallery(BuildContext context, List<String> urls, int initialIndex) {
  if (urls.isEmpty) return;
  final idx = initialIndex.clamp(0, urls.length - 1);
  Navigator.of(context, rootNavigator: true).push<void>(
    PageRouteBuilder<void>(
      opaque: true,
      pageBuilder: (context, animation, secondaryAnimation) {
        return _FullScreenImageGalleryPage(
          urls: urls,
          initialIndex: idx,
        );
      },
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 240),
    ),
  );
}

class _FullScreenImageGalleryPage extends StatefulWidget {
  const _FullScreenImageGalleryPage({
    required this.urls,
    required this.initialIndex,
  });

  final List<String> urls;
  final int initialIndex;

  @override
  State<_FullScreenImageGalleryPage> createState() => _FullScreenImageGalleryPageState();
}

class _FullScreenImageGalleryPageState extends State<_FullScreenImageGalleryPage> {
  late final PageController _pageController;
  late int _page;

  @override
  void initState() {
    super.initState();
    final i = widget.initialIndex.clamp(0, widget.urls.length - 1);
    _pageController = PageController(initialPage: i);
    _page = i;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final dpr = mq.devicePixelRatio;
    final w = mq.size.width;
    final cacheSide = (w * dpr).round().clamp(200, 4096);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: widget.urls.length,
              onPageChanged: (i) => setState(() => _page = i),
              itemBuilder: (context, index) {
                final url = widget.urls[index];
                return LayoutBuilder(
                  builder: (context, constraints) {
                    return InteractiveViewer(
                      minScale: 0.5,
                      maxScale: 5,
                      clipBehavior: Clip.none,
                      boundaryMargin: const EdgeInsets.all(120),
                      child: Center(
                        child: Image.network(
                          url,
                          fit: BoxFit.contain,
                          width: constraints.maxWidth,
                          height: constraints.maxHeight,
                          alignment: Alignment.center,
                          cacheWidth: cacheSide,
                          cacheHeight: cacheSide,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.broken_image_outlined,
                            color: Colors.white54,
                            size: 56,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                child: Row(
                  textDirection: TextDirection.rtl,
                  children: [
                    IconButton(
                      tooltip: 'إغلاق',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.close_rounded, color: Colors.white, size: 28.sp),
                      style: IconButton.styleFrom(backgroundColor: Colors.white12),
                    ),
                    if (widget.urls.length > 1) ...[
                      const Spacer(),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.white12,
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                          child: Text(
                            '${_page + 1}/${widget.urls.length}',
                            style: TextStyle(
                              fontFamily: 'Lama Sans',
                              color: Colors.white,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
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

class _GalleryMediaBlock extends StatelessWidget {
  const _GalleryMediaBlock({required this.urls});

  final List<String> urls;

  static double get _cellW => 150.w;
  static double get _cellH => 101.h;

  Widget _imageRaw(BuildContext context, String url) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final cw = (_cellW * dpr).round().clamp(100, 2048);
    return Image.network(
      url,
      fit: BoxFit.cover,
      width: _cellW,
      height: _cellH,
      cacheWidth: cw,
      errorBuilder: (context, error, stackTrace) =>
          ColoredBox(color: _Pv.surface),
    );
  }

  Widget _galleryExpandChip({required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          padding: EdgeInsets.all(8.r),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.38),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            Icons.zoom_out_map_rounded,
            size: 18.sp,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _thumbnailWithExpand(BuildContext context, List<String> allUrls, int index) {
    final url = allUrls[index];
    return ClipRRect(
      borderRadius: BorderRadius.circular(12.r),
      child: SizedBox(
        width: _cellW,
        height: _cellH,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(child: _imageRaw(context, url)),
            Align(
              alignment: AlignmentDirectional.bottomEnd,
              child: Padding(
                padding: EdgeInsets.all(8.r),
                child: _galleryExpandChip(
                  onTap: () => _openFullScreenGallery(context, allUrls, index),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (urls.isEmpty) {
      return Container(
        height: 128.h,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: _Modern.mutedLine.withValues(alpha: 0.6)),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: 32.sp,
              color: _Pv.subtext.withValues(alpha: 0.45),
            ),
            SizedBox(height: 6.h),
            Text(
              'لا صور في هذه الحالة',
              style: TextStyle(
                fontFamily: 'Lama Sans',
                fontWeight: FontWeight.w600,
                fontSize: 12.sp,
                color: _Pv.subtext,
              ),
            ),
          ],
        ),
      );
    }

    if (urls.length == 1) {
      // داخل عمود بـ stretch يفرض عرض البطاقة؛ Align يعيد قيوداً مرنة فيبقى العرض 150.w.
      return Align(
        alignment: AlignmentDirectional.centerStart,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14.r),
          child: SizedBox(
            width: _cellW,
            height: _cellH,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Positioned.fill(child: _imageRaw(context, urls.first)),
                Align(
                  alignment: AlignmentDirectional.bottomEnd,
                  child: Padding(
                    padding: EdgeInsets.all(8.r),
                    child: _galleryExpandChip(
                      onTap: () => _openFullScreenGallery(context, urls, 0),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (urls.length == 2) {
      return Row(
        textDirection: TextDirection.rtl,
        mainAxisSize: MainAxisSize.min,
        children: [
          _thumbnailWithExpand(context, urls, 0),
          SizedBox(width: 8.w),
          _thumbnailWithExpand(context, urls, 1),
        ],
      );
    }

    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      alignment: WrapAlignment.start,
      children: [
        for (var i = 0; i < urls.length; i++) _thumbnailWithExpand(context, urls, i),
      ],
    );
  }
}

/// قائمة شهادات عمودية — نفس أسلوب بطاقات المعرض [_ModernGalleryPostCard].
class _CertificatesPostsSection extends StatelessWidget {
  const _CertificatesPostsSection({
    required this.certs,
    required this.mediaUrl,
    this.showDeleteActions = false,
    this.onDeleteCertificate,
  });

  final List<CertificateImageDto> certs;
  final String Function(String?) mediaUrl;
  final bool showDeleteActions;
  final Future<void> Function(int index)? onDeleteCertificate;

  @override
  Widget build(BuildContext context) {
    if (certs.isEmpty) return const SizedBox.shrink();
    final reversed = certs.reversed.toList(growable: false);
    return Column(
      children: [
        for (var i = 0; i < reversed.length; i++) ...[
          if (i > 0) SizedBox(height: 14.h),
          _ModernGalleryPostCard(
            title: reversed[i].title?.trim().isNotEmpty == true
                ? reversed[i].title!.trim()
                : 'شهادة',
            description: reversed[i].issuer?.trim().isNotEmpty == true
                ? reversed[i].issuer!.trim()
                : '',
            imagePaths: [reversed[i].url],
            mediaUrl: mediaUrl,
            showDelete: showDeleteActions,
            onDelete: onDeleteCertificate == null
                ? null
                : () => onDeleteCertificate!(certs.length - 1 - i),
            deleteTooltip: 'حذف الشهادة',
          ),
        ],
      ],
    );
  }
}

class _ScientificLibraryOuterCard extends StatelessWidget {
  const _ScientificLibraryOuterCard({
    required this.item,
    required this.mediaUrl,
    this.showDelete = false,
    this.onDelete,
  });

  final GalleryItemDto item;
  final String Function(String?) mediaUrl;
  final bool showDelete;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final parts = item.caption.split('\n\n');
    final title = parts.isNotEmpty ? parts.first.trim() : '';
    final desc = parts.length > 1 ? parts.sublist(1).join('\n\n').trim() : '';
    return _ModernGalleryPostCard(
      title: title,
      description: desc,
      imagePaths: item.images,
      mediaUrl: mediaUrl,
      showDelete: showDelete,
      onDelete: onDelete,
    );
  }
}


