import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'package:dental_gate/controllers/professional_profile_controller.dart';
import 'package:dental_gate/core/media_url.dart';
import 'package:dental_gate/models/job_applicant_item.dart';
import 'package:dental_gate/models/job_posting.dart';
import 'package:dental_gate/models/my_job_application_item.dart';
import 'package:dental_gate/services/api_service.dart';
import 'package:dental_gate/view/profile/professional_profile_view.dart';
import 'package:dental_gate/widgets/app_back_button.dart';

/// ألوان شاشة المتقدمين (مطابقة لشريط تفاصيل الوظيفة + Figma).
abstract final class _ApplicantsDesign {
  static const Color titleDark = Color(0xFF040814);
  static const Color subtext = Color(0xFF757575);
  static const Color activeOrange = Color(0xFFFF724C);
  static const Color activeLabel = Color(0xFFFDFEFF);
  static const Color trackTintBg = Color(0x1AFF724C);
  static const Color badgeRed = Color(0xFFE53935);
  static const Color infoBoxBg = Color(0xFFF5F5F5);
  static const Color cardShadow = Color(0x29040814);
}

/// قائمة المتقدمين على وظيفة (صاحب الإعلان) — مطابقة لتصميم الشاشة المرجعية.
class JobApplicantsView extends StatefulWidget {
  const JobApplicantsView({
    super.key,
    required this.job,
    required this.applicantCountForBadge,
  });

  final JobPosting job;
  final int applicantCountForBadge;

  @override
  State<JobApplicantsView> createState() => _JobApplicantsViewState();
}

class _JobApplicantsViewState extends State<JobApplicantsView> {
  List<JobApplicantItem> _items = [];
  bool _loading = true;
  String? _error;
  final TextEditingController _search = TextEditingController();
  final Set<String> _bookmarked = {};

  @override
  void initState() {
    super.initState();
    _search.addListener(() => setState(() {}));
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await ApiService.instance.fetchJobApplicantsForOwner(
        widget.job.id,
      );
      if (!mounted) return;
      setState(() {
        _items = list;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'تعذر تحميل المتقدمين';
        _loading = false;
      });
    }
  }

  List<JobApplicantItem> get _filtered {
    final q = _search.text.trim().toLowerCase();
    if (q.isEmpty) return _items;
    bool hit(JobApplicantItem a) {
      final parts = <String?>[
        a.name,
        a.phone,
        a.email,
        a.governorate,
        a.professionalTitle,
      ];
      return parts.any((s) => (s ?? '').toLowerCase().contains(q));
    }

    return _items.where(hit).toList();
  }

  Future<void> _openApplicantProfessionalProfile(JobApplicantItem a) async {
    final tag = 'job_applicant_prof_${widget.job.id}_${a.applicationId}';
    Get.put(
      ProfessionalProfileController(
        viewJobId: widget.job.id,
        viewApplicationId: a.applicationId,
      ),
      tag: tag,
    );
    try {
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => ProfessionalProfileView(tag: tag),
        ),
      );
    } finally {
      if (Get.isRegistered<ProfessionalProfileController>(tag: tag)) {
        Get.delete<ProfessionalProfileController>(tag: tag);
      }
    }
  }

  void _showApplicationStatusSheet(JobApplicantItem applicant) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
        ),
        child: SafeArea(
          top: false,
          child: _ApplicationStatusBottomSheet(
            jobId: widget.job.id,
            applicant: applicant,
            onStatusUpdated: (newStatus) {
              if (!mounted) return;
              setState(() {
                final i = _items.indexWhere(
                  (e) => e.applicationId == applicant.applicationId,
                );
                if (i >= 0) {
                  _items = List<JobApplicantItem>.from(_items);
                  _items[i] = applicant.copyWith(status: newStatus);
                }
              });
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    const barH = 92.0;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFFDFEFF),
        body: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(12.w, 6.h, 12.w, 8.h),
                child: Row(
                  textDirection: TextDirection.ltr,
                  children: [
                    AppBackButton(
                      size: 40.w,
                      iconSize: 24.sp,
                      iconColor: _ApplicantsDesign.titleDark,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                    Expanded(
                      child: Text(
                        'المتقدمين',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Lama Sans',
                          fontWeight: FontWeight.w800,
                          fontSize: 20.sp,
                          height: 1.5,
                          color: _ApplicantsDesign.titleDark,
                        ),
                      ),
                    ),
                    SizedBox(width: 32.w),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 10.h),
                child: SizedBox(
                  height: 54.h,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFFFF),
                      borderRadius: BorderRadius.circular(27.r),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x29040814),
                          blurRadius: 6,
                          spreadRadius: 0,
                          offset: Offset.zero,
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(16.w, 17.h, 16.w, 17.h),
                      child: Directionality(
                        textDirection: TextDirection.rtl,
                        child: Row(
                          children: [
                            Image.asset(
                              'assets/icons/search.png',
                              width: 22.w,
                              height: 22.w,
                              fit: BoxFit.contain,
                            ),
                            SizedBox(width: 10.w),
                            Expanded(
                              child: TextField(
                                controller: _search,
                                textAlign: TextAlign.right,
                                textDirection: TextDirection.rtl,
                                textInputAction: TextInputAction.search,
                                style: TextStyle(
                                  fontFamily: 'Lama Sans',
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14.sp,
                                  color: const Color(0xFF040814),
                                ),
                                decoration: InputDecoration(
                                  isDense: true,
                                  hintText: 'أبحث عن متقدم للوظيفة ..',
                                  hintStyle: TextStyle(
                                    fontFamily: 'Lama Sans',
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14.sp,
                                    color: const Color(0xFF6B7280),
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                    ? Center(
                        child: Padding(
                          padding: EdgeInsets.all(24.w),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _error!,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'Lama Sans',
                                  fontSize: 15.sp,
                                  color: _ApplicantsDesign.subtext,
                                ),
                              ),
                              SizedBox(height: 16.h),
                              FilledButton(
                                onPressed: _load,
                                style: FilledButton.styleFrom(
                                  backgroundColor:
                                      _ApplicantsDesign.activeOrange,
                                ),
                                child: const Text('إعادة المحاولة'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: _filtered.isEmpty
                            ? ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: EdgeInsets.fromLTRB(
                                  24.w,
                                  48.h,
                                  24.w,
                                  24.h,
                                ),
                                children: [
                                  Center(
                                    child: Text(
                                      _items.isEmpty
                                          ? 'لا يوجد متقدمون بعد'
                                          : 'لا نتائج مطابقة للبحث',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontFamily: 'Lama Sans',
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15.sp,
                                        color: _ApplicantsDesign.subtext,
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : ListView.builder(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: EdgeInsets.fromLTRB(
                                  16.w,
                                  4.h,
                                  16.w,
                                  12.h,
                                ),
                                itemCount: _filtered.length,
                                itemBuilder: (context, i) {
                                  final a = _filtered[i];
                                  return _ApplicantCard(
                                    applicant: a,
                                    bookmarked: _bookmarked.contains(a.userId),
                                    onBookmark: () => setState(() {
                                      if (_bookmarked.contains(a.userId)) {
                                        _bookmarked.remove(a.userId);
                                      } else {
                                        _bookmarked.add(a.userId);
                                      }
                                    }),
                                    onProfile: () => unawaited(
                                      _openApplicantProfessionalProfile(a),
                                    ),
                                    onStatusTap: () =>
                                        _showApplicationStatusSheet(a),
                                  );
                                },
                              ),
                      ),
              ),
              SizedBox(
                width: double.infinity,
                height: barH.h + bottomInset,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDFDFD),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(32.r),
                      topRight: Radius.circular(32.r),
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x29000000),
                        offset: Offset(0, -1),
                        blurRadius: 16.1,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      21.w,
                      19.h,
                      19.w,
                      23.h + bottomInset,
                    ),
                    child: Center(
                      child: SizedBox(
                        width: 353.w,
                        height: 50.h,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: _ApplicantsDesign.trackTintBg,
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          child: Row(
                            textDirection: TextDirection.rtl,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: _bottomSegment(
                                  label: 'المتقدمين',
                                  selected: true,
                                  showNotificationDot:
                                      widget.applicantCountForBadge > 0,
                                  onTap: () {},
                                ),
                              ),
                              SizedBox(width: 8.w),
                              Expanded(
                                child: _bottomSegment(
                                  label: 'إدارة الوظيفة',
                                  selected: false,
                                  showNotificationDot: false,
                                  onTap: () => Navigator.of(context).pop(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bottomSegment({
    required String label,
    required bool selected,
    required bool showNotificationDot,
    required VoidCallback onTap,
  }) {
    const orange = _ApplicantsDesign.activeOrange;
    const labelOn = _ApplicantsDesign.activeLabel;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10.r),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final targetW = 172.w;
            final w = constraints.maxWidth < targetW
                ? constraints.maxWidth
                : targetW;
            return Align(
              alignment: Alignment.center,
              child: SizedBox(
                width: w,
                height: 50.h,
                child: Container(
                  decoration: BoxDecoration(
                    color: selected ? orange : Colors.transparent,
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  padding: EdgeInsets.fromLTRB(8.w, 5.h, 8.w, 5.h),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Align(
                        alignment: Alignment.center,
                        child: Text(
                          label,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Lama Sans',
                            fontWeight: selected
                                ? FontWeight.w900
                                : FontWeight.w800,
                            fontSize: 14.sp,
                            height: 1.5,
                            color: selected ? labelOn : orange,
                          ),
                        ),
                      ),
                      if (showNotificationDot)
                        Positioned(
                          top: 2.h,
                          right: 2.w,
                          child: Container(
                            width: 8.w,
                            height: 8.w,
                            decoration: const BoxDecoration(
                              color: _ApplicantsDesign.badgeRed,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ApplicantCard extends StatelessWidget {
  const _ApplicantCard({
    required this.applicant,
    required this.bookmarked,
    required this.onBookmark,
    required this.onProfile,
    required this.onStatusTap,
  });

  final JobApplicantItem applicant;
  final bool bookmarked;
  final VoidCallback onBookmark;
  final VoidCallback onProfile;
  final VoidCallback onStatusTap;

  Color get _statusColor {
    switch (applicant.status) {
      case JobApplicationStatusApi.pending:
        return const Color(0xFFFF9914);
      case JobApplicationStatusApi.accepted:
        return const Color(0xFF0BDB0F);
      case JobApplicationStatusApi.rejected:
        return const Color(0xFFED3737);
    }
  }

  String _displayEmail(String email) {
    final i = email.indexOf('@');
    if (i <= 0 || i >= email.length - 1) return email;
    return '${email.substring(0, i)} @ ${email.substring(i + 1)}';
  }

  @override
  Widget build(BuildContext context) {
    final url = resolveMediaUrl(applicant.imageUrl);
    final subtitle = applicant.professionalTitle?.trim();
    final normalizedSubtitle = subtitle?.replaceAll(RegExp(r'\s+'), ' ').trim();
    final isDefaultSeedTitle =
        normalizedSubtitle == 'طبيب أسنان متدرب' ||
        normalizedSubtitle == 'طبيب اسنان متدرب';
    final hasSubtitle =
        normalizedSubtitle != null &&
        normalizedSubtitle.isNotEmpty &&
        !isDefaultSeedTitle;
    final subtitleToShow = hasSubtitle ? normalizedSubtitle : null;

    return Padding(
      padding: EdgeInsets.only(bottom: 14.h),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22.r),
          boxShadow: const [
            BoxShadow(
              color: _ApplicantsDesign.cardShadow,
              offset: Offset(0, 0),
              blurRadius: 6,
              spreadRadius: 0,
            ),
          ],
        ),
        padding: EdgeInsets.fromLTRB(14.w, 14.h, 14.w, 14.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              textDirection: TextDirection.rtl,
              crossAxisAlignment: subtitleToShow != null
                  ? CrossAxisAlignment.start
                  : CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 28.r,
                  backgroundColor: const Color(0xFFE8E8E8),
                  backgroundImage: url.isNotEmpty ? NetworkImage(url) : null,
                  child: url.isEmpty
                      ? Icon(
                          Icons.person_rounded,
                          size: 28.sp,
                          color: _ApplicantsDesign.subtext,
                        )
                      : null,
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        applicant.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Lama Sans',
                          fontWeight: FontWeight.w900,
                          fontSize: 16.sp,
                          color: _ApplicantsDesign.titleDark,
                        ),
                      ),
                      if (subtitleToShow != null) ...[
                        SizedBox(height: 2.h),
                        Text(
                          subtitleToShow,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.start,
                          style: TextStyle(
                            fontFamily: 'Lama Sans',
                            fontWeight: FontWeight.w600,
                            fontSize: 12.sp,
                            color: _ApplicantsDesign.subtext,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(width: 8.w),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onStatusTap,
                    borderRadius: BorderRadius.circular(20.r),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 5.h,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: _statusColor, width: 1),
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Text(
                        applicant.statusLabel,
                        style: TextStyle(
                          fontFamily: 'Lama Sans',
                          fontWeight: FontWeight.w800,
                          fontSize: 11.sp,
                          color: _statusColor,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: _ApplicantsDesign.infoBoxBg,
                borderRadius: BorderRadius.circular(14.r),
              ),
              child: Column(
                children: [
                  _infoRow(
                    Icons.workspace_premium_outlined,
                    applicant.experienceLine,
                  ),
                  SizedBox(height: 8.h),
                  _infoRow(Icons.location_on_outlined, applicant.locationLine),
                  SizedBox(height: 8.h),
                  _infoRow(Icons.phone_outlined, applicant.phone),
                  SizedBox(height: 8.h),
                  _infoRow(
                    Icons.email_outlined,
                    _displayEmail(applicant.email),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12.h),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onProfile,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _ApplicantsDesign.activeOrange,
                      side: const BorderSide(
                        color: _ApplicantsDesign.activeOrange,
                        width: 1.5,
                      ),
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                    ),
                    child: Text(
                      'عرض البروفايل المهني',
                      style: TextStyle(
                        fontFamily: 'Lama Sans',
                        fontWeight: FontWeight.w800,
                        fontSize: 14.sp,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10.w),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onBookmark,
                    borderRadius: BorderRadius.circular(12.r),
                    child: Container(
                      width: 48.w,
                      height: 48.w,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: _ApplicantsDesign.activeOrange,
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        bookmarked
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_border_rounded,
                        color: _ApplicantsDesign.activeOrange,
                        size: 24.sp,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 18.sp, color: _ApplicantsDesign.titleDark),
        SizedBox(width: 8.w),
        Expanded(
          child: Text(
            text,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontFamily: 'Lama Sans',
              fontWeight: FontWeight.w600,
              fontSize: 13.sp,
              color: _ApplicantsDesign.titleDark,
            ),
          ),
        ),
      ],
    );
  }
}

/// تغيير حالة طلب التقديم — مطابق لتصميم الـ bottom sheet.
class _ApplicationStatusBottomSheet extends StatefulWidget {
  const _ApplicationStatusBottomSheet({
    required this.jobId,
    required this.applicant,
    required this.onStatusUpdated,
  });

  final String jobId;
  final JobApplicantItem applicant;
  final void Function(JobApplicationStatusApi newStatus) onStatusUpdated;

  @override
  State<_ApplicationStatusBottomSheet> createState() =>
      _ApplicationStatusBottomSheetState();
}

class _ApplicationStatusBottomSheetState
    extends State<_ApplicationStatusBottomSheet> {
  static const Color _radioBlue = Color(0xFF4C84FF);
  static const Color _radioGrey = Color(0xFFCCCCCC);

  late JobApplicationStatusApi _selected;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selected = widget.applicant.status;
  }

  static String _optionLabel(JobApplicationStatusApi s) {
    switch (s) {
      case JobApplicationStatusApi.accepted:
        return 'مقبول';
      case JobApplicationStatusApi.pending:
        return 'قيد المراجعة';
      case JobApplicationStatusApi.rejected:
        return 'مرفوض';
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final newStatus = await ApiService.instance.patchJobApplicationStatus(
        jobId: widget.jobId,
        applicationId: widget.applicant.applicationId,
        status: _selected,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      widget.onStatusUpdated(newStatus);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تعذر حفظ الحالة')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _optionRow(JobApplicationStatusApi value) {
    return InkWell(
      onTap: _saving ? null : () => setState(() => _selected = value),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8.h),
        child: Row(
          textDirection: TextDirection.ltr,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                _optionLabel(value),
                textAlign: TextAlign.left,
                style: TextStyle(
                  fontFamily: 'Lama Sans',
                  fontWeight: FontWeight.w800,
                  fontSize: 16.sp,
                  color: _ApplicantsDesign.titleDark,
                ),
              ),
            ),
            _statusRadioDot(value),
          ],
        ),
      ),
    );
  }

  Widget _statusRadioDot(JobApplicationStatusApi value) {
    final selected = _selected == value;
    return Container(
      width: 22.w,
      height: 22.w,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: selected ? _radioBlue : _radioGrey, width: 2),
      ),
      child: selected
          ? Container(
              width: 10.w,
              height: 10.w,
              decoration: const BoxDecoration(
                color: _radioBlue,
                shape: BoxShape.circle,
              ),
            )
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 24.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E0E0),
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),
            SizedBox(height: 18.h),
            Text(
              'فلترة طلبات المتقدمين',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Lama Sans',
                fontWeight: FontWeight.w900,
                fontSize: 18.sp,
                color: _ApplicantsDesign.titleDark,
              ),
            ),
            SizedBox(height: 20.h),
            _optionRow(JobApplicationStatusApi.accepted),
            _optionRow(JobApplicationStatusApi.pending),
            _optionRow(JobApplicationStatusApi.rejected),
            SizedBox(height: 24.h),
            Row(
              textDirection: TextDirection.rtl,
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: _saving ? null : _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: _ApplicantsDesign.activeOrange,
                      foregroundColor: _ApplicantsDesign.activeLabel,
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    child: _saving
                        ? SizedBox(
                            height: 22.h,
                            width: 22.w,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'حفظ',
                            style: TextStyle(
                              fontFamily: 'Lama Sans',
                              fontWeight: FontWeight.w900,
                              fontSize: 16.sp,
                            ),
                          ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _saving
                        ? null
                        : () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _ApplicantsDesign.activeOrange,
                      side: const BorderSide(
                        color: _ApplicantsDesign.activeOrange,
                        width: 1.5,
                      ),
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    child: Text(
                      'الغاء',
                      style: TextStyle(
                        fontFamily: 'Lama Sans',
                        fontWeight: FontWeight.w800,
                        fontSize: 16.sp,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
