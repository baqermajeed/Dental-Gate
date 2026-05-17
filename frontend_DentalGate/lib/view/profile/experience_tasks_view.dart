import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'package:dental_gate/models/doctor_profile_full.dart';
import 'package:dental_gate/services/api_service.dart' show ApiService;
import 'package:dental_gate/view/profile/experience_score_breakdown.dart';
import 'package:dental_gate/view/profile/accredited_course_submit_dialog.dart';
import 'package:dental_gate/view/profile/practice_license_submit_dialog.dart';
import 'package:dental_gate/widgets/app_back_button.dart';

/// نتيجة إغلاق صفحة المهام — فتح تبويب معيّن في البروفايل.
enum ExperienceTasksPopResult {
  openRatingsTab,
}

/// صفحة تفاصيل مهام نقاط الخبرة والتوزيع.
class ExperienceTasksView extends StatefulWidget {
  const ExperienceTasksView({
    super.key,
    required this.profile,
    this.initialPeerReceived = 0,
    this.initialPeerGiven = 0,
  });

  final DoctorProfileFull profile;
  final int initialPeerReceived;
  final int initialPeerGiven;

  @override
  State<ExperienceTasksView> createState() => _ExperienceTasksViewState();
}

class _ExperienceTasksViewState extends State<ExperienceTasksView> {
  late DoctorProfileFull _profile;
  bool _profileUpdated = false;
  late int _peerReceived;
  late int _peerGiven;

  @override
  void initState() {
    super.initState();
    _profile = widget.profile;
    _peerReceived = widget.initialPeerReceived;
    _peerGiven = widget.initialPeerGiven;
    _refreshPeerStats();
  }

  void _pop([Object? result]) =>
      Navigator.of(context).pop(result ?? _profileUpdated);

  ExperienceScoreBreakdown get _breakdown => resolveExperienceScoreBreakdown(
        _profile,
        peerRatingsReceived: _peerReceived,
        peerRatingsGiven: _peerGiven,
      );

  Future<void> _refreshPeerStats() async {
    try {
      final page = await ApiService.instance.fetchMyPeerRatings();
      if (!mounted) return;
      setState(() {
        _peerReceived = page.totalCount;
        _peerGiven = page.ratingsGivenCount;
      });
    } catch (_) {}
  }

  bool _taskIsTappable(ExperienceScoreTask t) {
    if (t.comingSoon) return false;
    if (t.id == 'peer_in' || t.id == 'peer_out') return true;
    if (t.id == 'practice_license' || t.id == 'courses') {
      return t.opensSubmitDialog || t.isPendingReview;
    }
    return false;
  }

  Future<void> _reloadProfile() async {
    final p = await ApiService.instance.fetchDoctorProfileFull();
    if (!mounted) return;
    setState(() {
      _profile = p;
      _profileUpdated = true;
    });
    await _refreshPeerStats();
  }

  Future<void> _onTaskTap(ExperienceScoreTask task) async {
    if (task.id == 'peer_in') {
      _pop(ExperienceTasksPopResult.openRatingsTab);
      return;
    }
    if (task.id == 'peer_out') {
      await _showPeerOutInfo();
      return;
    }
    if (task.id == 'practice_license') {
      await _handlePracticeLicenseTap(task);
      return;
    }
    if (task.id == 'courses') {
      await _handleCoursesTap(task);
    }
  }

  Future<void> _showPeerOutInfo() async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r),
          ),
          title: Text(
            'تقييم الزملاء (صادر)',
            style: TextStyle(
              fontFamily: 'Lama Sans',
              fontWeight: FontWeight.w900,
              fontSize: 17.sp,
            ),
          ),
          content: Text(
            'لتقييم زميل، افتح بروفايله من البحث عن الأطباء واضغط «قيّم الطبيب». '
            'تحصل على ${kPeerRatingsOutgoingMax} نقاط عند تقييم '
            '$kPeerRatingsOutgoingRequired أطباء (مرة واحدة لكل طبيب).',
            style: TextStyle(
              fontFamily: 'Lama Sans',
              fontWeight: FontWeight.w600,
              fontSize: 14.sp,
              height: 1.45,
              color: const Color(0xFF64748B),
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF5993FF),
              ),
              child: Text(
                'حسناً',
                style: TextStyle(
                  fontFamily: 'Lama Sans',
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handlePracticeLicenseTap(ExperienceScoreTask task) async {
    if (task.isPendingReview) {
      await _showPendingInfo(
        title: 'قيد المراجعة',
        body:
            'تم استلام شهادة الممارسة. فريق التحقق يراجعها وسنُعلمك عند الاعتماد.',
      );
      return;
    }
    if (!task.opensSubmitDialog) return;
    final sent = await showPracticeLicenseSubmitDialog(
      context,
      existing: _profile.practiceLicense,
    );
    if (sent == true) {
      await _reloadProfile();
      if (!mounted) return;
      Get.snackbar(
        'تم الإرسال',
        'طلبك قيد المراجعة. ستُضاف النقاط بعد موافقة الإدارة.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 4),
      );
    }
  }

  Future<void> _handleCoursesTap(ExperienceScoreTask task) async {
    if (task.isPendingReview) {
      final pending =
          _profile.accreditedCourses.where((c) => c.isPending).length;
      await _showPendingInfo(
        title: 'دورات قيد المراجعة',
        body:
            'لديك $pending دورة بانتظار التحقق. ستُضاف النقاط (نقطتان لكل دورة معتمدة) بعد الموافقة.',
      );
      return;
    }
    if (!task.opensSubmitDialog) return;
    final sent = await showAccreditedCourseSubmitDialog(context);
    if (sent == true) {
      await _reloadProfile();
      if (!mounted) return;
      Get.snackbar(
        'تم الإرسال',
        'الدورة قيد المراجعة. ستُضاف النقاط بعد موافقة الإدارة.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 4),
      );
    }
  }

  Future<void> _showPendingInfo({
    required String title,
    required String body,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontFamily: 'Lama Sans',
              fontWeight: FontWeight.w900,
              fontSize: 17.sp,
            ),
          ),
          content: Text(
            body,
            style: TextStyle(
              fontFamily: 'Lama Sans',
              fontWeight: FontWeight.w600,
              fontSize: 14.sp,
              height: 1.45,
              color: const Color(0xFF64748B),
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFF59E0B),
              ),
              child: Text(
                'حسناً',
                style: TextStyle(
                  fontFamily: 'Lama Sans',
                  fontWeight: FontWeight.w800,
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
    final breakdown = _breakdown;
    final tier = breakdown.tier;
    final accent = _tierAccentFromPublicApi(tier);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _pop();
      },
      child: Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              pinned: true,
              elevation: 0,
              scrolledUnderElevation: 0.5,
              backgroundColor: const Color(0xFFF8FAFC),
              surfaceTintColor: Colors.transparent,
              automaticallyImplyLeading: false,
              title: Text(
                'مهام نقاط الخبرة',
                style: TextStyle(
                  fontFamily: 'Lama Sans',
                  fontWeight: FontWeight.w900,
                  fontSize: 18.sp,
                  color: const Color(0xFF0F172A),
                ),
              ),
              centerTitle: true,
              actions: [
                Padding(
                  padding: EdgeInsets.only(left: 8.w),
                  child: AppBackButton(
                    size: 38.w,
                    iconSize: 22.sp,
                    iconColor: const Color(0xFF0F172A),
                    onTap: _pop,
                  ),
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 12.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _HeroScoreCard(
                      breakdown: breakdown,
                      accent: accent,
                    ),
                    SizedBox(height: 18.h),
                    Text(
                      'التقدم حسب المهام',
                      style: TextStyle(
                        fontFamily: 'Lama Sans',
                        fontWeight: FontWeight.w900,
                        fontSize: 16.sp,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'أكمل المهام لرفع تصنيفك وبناء سمعتك المهنية الرقمية.',
                      style: TextStyle(
                        fontFamily: 'Lama Sans',
                        fontWeight: FontWeight.w600,
                        fontSize: 12.5.sp,
                        height: 1.45,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    SizedBox(height: 14.h),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 100.h),
              sliver: SliverList.separated(
                itemCount: breakdown.tasks.length,
                separatorBuilder: (_, _) => SizedBox(height: 10.h),
                itemBuilder: (context, i) {
                  final t = breakdown.tasks[i];
                  return _TaskProgressTile(
                    task: t,
                    accent: accent,
                    onTap: _taskIsTappable(t) ? () => _onTaskTap(t) : null,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }
}

Color _tierAccentFromPublicApi(ExperienceTier t) {
  return switch (t) {
    ExperienceTier.silver => const Color(0xFF94A3B8),
    ExperienceTier.gold => const Color(0xFFF59E0B),
    ExperienceTier.platinum => const Color(0xFF22D3EE),
    ExperienceTier.diamond => const Color(0xFFA78BFA),
  };
}

class _HeroScoreCard extends StatelessWidget {
  const _HeroScoreCard({
    required this.breakdown,
    required this.accent,
  });

  final ExperienceScoreBreakdown breakdown;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final frac = breakdown.fraction.clamp(0.0, 1.0);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26.r),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0B1220),
            Color(0xFF111827),
            Color(0xFF1E3A5F),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.22),
            blurRadius: 28,
            offset: const Offset(0, 16),
            spreadRadius: -6,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26.r),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: -30.w,
              bottom: -40.h,
              child: Opacity(
                opacity: 0.35,
                child: Icon(
                  Icons.hexagon_rounded,
                  size: 140.sp,
                  color: accent,
                ),
              ),
            ),
            Positioned(
              left: 10.w,
              top: 10.h,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => showExperienceTiersInfoDialog(context),
                  customBorder: const CircleBorder(),
                  child: Padding(
                    padding: EdgeInsets.all(10.w),
                    child: SizedBox(
                      width: 12.w,
                      height: 12.w,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.38),
                          ),
                        ),
                        child: Center(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Icon(
                              Icons.question_mark_rounded,
                              size: 10.sp,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(20.w),
              child: Row(
                textDirection: TextDirection.rtl,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _CircularXpGauge(
                    fraction: frac,
                    accent: accent,
                    centerText: '${breakdown.totalEarned}',
                    subText: '/ ${breakdown.totalMax}',
                  ),
                  SizedBox(width: 18.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'مجموع نقاط الخبرة',
                          style: TextStyle(
                            fontFamily: 'Lama Sans',
                            fontWeight: FontWeight.w800,
                            fontSize: 14.sp,
                            color: Colors.white.withValues(alpha: 0.75),
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Wrap(
                          spacing: 8.w,
                          runSpacing: 8.h,
                          children: [
                            _GlassChip(
                              icon: Icons.workspace_premium_rounded,
                              label: experienceTierLabelAr(breakdown.tier),
                              accent: accent,
                            ),
                            _GlassChip(
                              icon: Icons.auto_graph_rounded,
                              label: '${(frac * 100).round()}٪ مكتمل',
                              accent: Colors.white.withValues(alpha: 0.85),
                            ),
                          ],
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
}

/// شرح نطاق نقاط كل تصنيف (متطابق مع منطق الحساب في الخلفية).
Future<void> showExperienceTiersInfoDialog(BuildContext context) async {
  await showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22.r),
        ),
        backgroundColor: Colors.white,
        titlePadding: EdgeInsets.fromLTRB(22.w, 20.h, 22.w, 8.h),
        contentPadding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 8.h),
        actionsAlignment: MainAxisAlignment.center,
        actionsPadding: EdgeInsets.fromLTRB(20.w, 4.h, 20.w, 18.h),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(
                Icons.workspace_premium_rounded,
                color: const Color(0xFF5993FF),
                size: 22.sp,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                'تصنيفات نقاط الخبرة',
                style: TextStyle(
                  fontFamily: 'Lama Sans',
                  fontWeight: FontWeight.w900,
                  fontSize: 17.sp,
                  height: 1.25,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'يختلف تصنيفك حسب مجموع نقاطك ضمن نظام الخبرة (حتى $kExperienceScoreTotalCap نقطة).',
                style: TextStyle(
                  fontFamily: 'Lama Sans',
                  fontWeight: FontWeight.w600,
                  fontSize: 13.sp,
                  height: 1.45,
                  color: const Color(0xFF64748B),
                ),
              ),
              SizedBox(height: 16.h),
              for (final tier in ExperienceTier.values) ...[
                _TierRangeDialogRow(tier: tier),
                if (tier != ExperienceTier.diamond)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.h),
                    child: Divider(
                      height: 1,
                      color: const Color(0xFFE2E8F0),
                    ),
                  ),
              ],
            ],
          ),
        ),
        actions: [
          SizedBox(
            width: 100.w,
            child: FilledButton(
              onPressed: () => Navigator.of(ctx).pop(),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFF59E0B),
                foregroundColor: Colors.white,
                elevation: 0,
                shadowColor: const Color(0xFFF59E0B).withValues(alpha: 0.45),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                padding: EdgeInsets.symmetric(vertical: 10.h),
                minimumSize: Size(80.w, 40.h),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'حسناً',
                style: TextStyle(
                  fontFamily: 'Lama Sans',
                  fontWeight: FontWeight.w900,
                  fontSize: 13.sp,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _TierRangeDialogRow extends StatelessWidget {
  const _TierRangeDialogRow({required this.tier});

  final ExperienceTier tier;

  @override
  Widget build(BuildContext context) {
    final accent = _tierAccentFromPublicApi(tier);
    final min = experienceTierMinInclusive(tier);
    final max = experienceTierMaxInclusive(tier);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      textDirection: TextDirection.rtl,
      children: [
        Container(
          width: 4.w,
          height: 44.h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4.r),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                accent,
                accent.withValues(alpha: 0.55),
              ],
            ),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                experienceTierLabelAr(tier),
                style: TextStyle(
                  fontFamily: 'Lama Sans',
                  fontWeight: FontWeight.w900,
                  fontSize: 15.sp,
                  color: const Color(0xFF0F172A),
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                'من $min إلى $max نقطة',
                style: TextStyle(
                  fontFamily: 'Lama Sans',
                  fontWeight: FontWeight.w700,
                  fontSize: 13.sp,
                  height: 1.35,
                  color: const Color(0xFF475569),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GlassChip extends StatelessWidget {
  const _GlassChip({
    required this.icon,
    required this.label,
    required this.accent,
  });

  final IconData icon;
  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.white.withValues(alpha: 0.08),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15.sp, color: accent),
          SizedBox(width: 6.w),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Lama Sans',
              fontWeight: FontWeight.w800,
              fontSize: 11.5.sp,
              color: Colors.white.withValues(alpha: 0.92),
            ),
          ),
        ],
      ),
    );
  }
}

class _CircularXpGauge extends StatelessWidget {
  const _CircularXpGauge({
    required this.fraction,
    required this.accent,
    required this.centerText,
    required this.subText,
  });

  final double fraction;
  final Color accent;
  final String centerText;
  final String subText;

  @override
  Widget build(BuildContext context) {
    final size = 108.w;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _GaugePainter(
          fraction: fraction,
          accent: accent,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                centerText,
                style: TextStyle(
                  fontFamily: 'Lama Sans',
                  fontWeight: FontWeight.w900,
                  fontSize: 28.sp,
                  height: 1,
                  color: Colors.white,
                ),
              ),
              Text(
                subText,
                style: TextStyle(
                  fontFamily: 'Lama Sans',
                  fontWeight: FontWeight.w600,
                  fontSize: 11.sp,
                  color: Colors.white.withValues(alpha: 0.45),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  _GaugePainter({
    required this.fraction,
    required this.accent,
  });

  final double fraction;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 8;
    final bg = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(c, r, bg);

    final sweep = 2 * math.pi * fraction.clamp(0.0, 1.0);
    final fg = Paint()
      ..color = accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      -math.pi / 2,
      sweep,
      false,
      fg,
    );

    if (sweep > 0.05) {
      final gloss = Paint()
        ..color = Colors.white.withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r - 3),
        -math.pi / 2,
        sweep * 0.92,
        false,
        gloss,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) =>
      oldDelegate.fraction != fraction || oldDelegate.accent != accent;
}

class _TaskProgressTile extends StatelessWidget {
  const _TaskProgressTile({
    required this.task,
    required this.accent,
    this.onTap,
  });

  final ExperienceScoreTask task;
  final Color accent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final done = task.isComplete;
    final pending = task.isPendingReview;
    final rejected = task.isRejected;
    final track = task.comingSoon
        ? Colors.white.withValues(alpha: 0.06)
        : const Color(0xFFE2E8F0);

    final content = Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(
          color: done
              ? accent.withValues(alpha: 0.35)
              : pending
                  ? const Color(0xFFF59E0B).withValues(alpha: 0.45)
                  : rejected
                      ? const Color(0xFFE53935).withValues(alpha: 0.35)
                      : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(14.w, 14.h, 14.w, 14.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            textDirection: TextDirection.rtl,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      textDirection: TextDirection.rtl,
                      children: [
                        Flexible(
                          child: Text(
                            task.title,
                            style: TextStyle(
                              fontFamily: 'Lama Sans',
                              fontWeight: FontWeight.w900,
                              fontSize: 14.5.sp,
                              height: 1.25,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        if (task.comingSoon) ...[
                          SizedBox(width: 8.w),
                          _TaskBadge(
                            label: 'قريباً',
                            bg: const Color(0xFFEEF2FF),
                            fg: const Color(0xFF4F46E5),
                          ),
                        ] else if (pending) ...[
                          SizedBox(width: 8.w),
                          _TaskBadge(
                            label: 'قيد المراجعة',
                            bg: const Color(0xFFFFFBEB),
                            fg: const Color(0xFFD97706),
                          ),
                        ] else if (rejected) ...[
                          SizedBox(width: 8.w),
                          _TaskBadge(
                            label: 'مرفوض',
                            bg: const Color(0xFFFEE2E2),
                            fg: const Color(0xFFDC2626),
                          ),
                        ] else if (task.opensSubmitDialog || onTap != null) ...[
                          SizedBox(width: 8.w),
                          Icon(
                            Icons.touch_app_rounded,
                            size: 16.sp,
                            color: const Color(0xFF94A3B8),
                          ),
                        ],
                      ],
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      task.subtitle,
                      style: TextStyle(
                        fontFamily: 'Lama Sans',
                        fontWeight: FontWeight.w600,
                        fontSize: 12.sp,
                        height: 1.45,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 10.w),
              _StatusOrb(
                done: done,
                comingSoon: task.comingSoon,
                pending: pending,
                rejected: rejected,
                accent: accent,
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            textDirection: TextDirection.rtl,
            children: [
              Text(
                '${task.earned}/${task.max}',
                style: TextStyle(
                  fontFamily: 'Lama Sans',
                  fontWeight: FontWeight.w900,
                  fontSize: 12.5.sp,
                  color: const Color(0xFF475569),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: SizedBox(
                    height: 8.h,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Container(color: track),
                        if (!task.comingSoon)
                          FractionallySizedBox(
                            alignment: Alignment.centerRight,
                            widthFactor: task.progress.clamp(0.0, 1.0),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    accent.withValues(alpha: 0.55),
                                    accent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18.r),
        child: content,
      ),
    );
  }
}

class _TaskBadge extends StatelessWidget {
  const _TaskBadge({
    required this.label,
    required this.bg,
    required this.fg,
  });

  final String label;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Lama Sans',
          fontWeight: FontWeight.w800,
          fontSize: 10.sp,
          color: fg,
        ),
      ),
    );
  }
}

class _StatusOrb extends StatelessWidget {
  const _StatusOrb({
    required this.done,
    required this.comingSoon,
    required this.pending,
    required this.rejected,
    required this.accent,
  });

  final bool done;
  final bool comingSoon;
  final bool pending;
  final bool rejected;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    if (comingSoon) {
      return Container(
        width: 40.w,
        height: 40.w,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFFF1F5F9),
          border: Border.all(color: const Color(0xFFCBD5E1)),
        ),
        child: Icon(
          Icons.hourglass_empty_rounded,
          color: const Color(0xFF64748B),
          size: 20.sp,
        ),
      );
    }
    if (pending) {
      return Container(
        width: 40.w,
        height: 40.w,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFFFFFBEB),
          border: Border.all(color: const Color(0xFFF59E0B), width: 2),
        ),
        child: Icon(
          Icons.hourglass_top_rounded,
          color: const Color(0xFFF59E0B),
          size: 20.sp,
        ),
      );
    }
    if (rejected) {
      return Container(
        width: 40.w,
        height: 40.w,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFFFEE2E2),
          border: Border.all(color: const Color(0xFFE53935), width: 2),
        ),
        child: Icon(
          Icons.refresh_rounded,
          color: const Color(0xFFE53935),
          size: 20.sp,
        ),
      );
    }
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: 40.w,
      height: 40.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: done
            ? LinearGradient(
                colors: [
                  accent.withValues(alpha: 0.85),
                  accent,
                ],
              )
            : null,
        color: done ? null : const Color(0xFFF8FAFC),
        border: Border.all(
          color: done ? accent : const Color(0xFFE2E8F0),
          width: 2,
        ),
        boxShadow: done
            ? [
                BoxShadow(
                  color: accent.withValues(alpha: 0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Icon(
        done ? Icons.check_rounded : Icons.radio_button_unchecked_rounded,
        color: done ? Colors.white : const Color(0xFFCBD5E1),
        size: done ? 22.sp : 18.sp,
      ),
    );
  }
}
