import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'package:dental_gate/controllers/bookmarks_controller.dart';
import 'package:dental_gate/controllers/home_controller.dart';
import 'package:dental_gate/controllers/talabat_controller.dart';
import 'package:dental_gate/models/job_posting.dart';
import 'package:dental_gate/models/my_job_application_item.dart';
import 'package:dental_gate/services/api_service.dart';
import 'package:dental_gate/utils/relative_time_ar.dart';
import 'package:dental_gate/view/jobs/create_job_view.dart';
import 'package:dental_gate/view/jobs/delete_job_confirm_dialog.dart';
import 'package:dental_gate/view/jobs/job_applicants_view.dart';
import 'package:dental_gate/widgets/app_back_button.dart';
import 'package:dental_gate/widgets/job_posting_card.dart';

/// شريط سفلي لصاحب الإعلان: تبديل «إدارة الوظيفة» / «المتقدمين» (تصميم مرجعي).
abstract final class _OwnerJobDetailBarDesign {
  /// لون زر «إدارة الوظيفة» النشط (Figma).
  static const Color activeOrange = Color(0xFFFF724C);
  static const Color activeLabel = Color(0xFFFDFEFF);

  /// خلفية الحاوية الأفقية (#FF724C شفافية ~10%).
  static const Color trackTintBg = Color(0x1AFF724C);
  static const Color badgeRed = Color(0xFFE53935);
}

enum _OwnerJobDetailTab { applicants, jobManagement }

/// شاشة تفاصيل الوظيفة — نفس ألوان وطبقات بطاقة القائمة مع عرض كامل للحقول.
class JobDetailView extends StatefulWidget {
  const JobDetailView({super.key, required this.job, this.applicationStatus});

  final JobPosting job;
  final JobApplicationStatusApi? applicationStatus;

  @override
  State<JobDetailView> createState() => _JobDetailViewState();
}

class _JobDetailViewState extends State<JobDetailView> {
  bool _applyLoading = false;
  bool _statusLoading = false;
  JobApplicationStatusApi? _currentApplicationStatus;
  final BookmarksController _bookmarks = Get.find<BookmarksController>();
  String? _myUserId;
  _OwnerJobDetailTab _ownerTab = _OwnerJobDetailTab.jobManagement;
  int _applicantCount = 0;
  bool _loadingApplicantCount = false;
  Worker? _homeProfileEver;
  late JobPosting _displayJob;
  bool _deletingJob = false;

  bool get _isMyPostedJob =>
      _myUserId != null && _myUserId == widget.job.postedBy;

  @override
  void initState() {
    super.initState();
    _displayJob = widget.job;
    _currentApplicationStatus = widget.applicationStatus;
    if (_currentApplicationStatus == null) {
      _loadApplicationStatusFromBackend();
    }
    if (Get.isRegistered<HomeController>()) {
      _homeProfileEver = ever(
        Get.find<HomeController>().profile,
        (_) => unawaited(_onHomeProfileForApplicants()),
      );
    }
    unawaited(_loadMyUserId());
  }

  @override
  void dispose() {
    _homeProfileEver?.dispose();
    super.dispose();
  }

  Future<void> _onHomeProfileForApplicants() async {
    final id = Get.find<HomeController>().profile.value?.id;
    if (!mounted) return;
    if (id != null) setState(() => _myUserId = id);
    if (id != null && id == widget.job.postedBy) {
      await _loadApplicantCount();
    }
  }

  Future<void> _loadApplicantCount() async {
    if (_loadingApplicantCount) return;
    _loadingApplicantCount = true;
    try {
      final n = await ApiService.instance.fetchMyJobApplicationCount(
        widget.job.id,
      );
      if (mounted) setState(() => _applicantCount = n);
    } catch (_) {
      if (mounted) setState(() => _applicantCount = 0);
    } finally {
      _loadingApplicantCount = false;
    }
  }

  Future<void> _loadMyUserId() async {
    try {
      if (Get.isRegistered<HomeController>()) {
        final id = Get.find<HomeController>().profile.value?.id;
        if (id != null) {
          if (mounted) setState(() => _myUserId = id);
          if (id == widget.job.postedBy) await _loadApplicantCount();
          return;
        }
      }
      final me = await ApiService.instance.fetchMe();
      if (mounted) setState(() => _myUserId = me.id);
      if (me.id == widget.job.postedBy) await _loadApplicantCount();
    } catch (_) {}
  }

  bool get _isFromApplicationCard => _currentApplicationStatus != null;

  Color get _applicationStatusColor {
    switch (_currentApplicationStatus) {
      case JobApplicationStatusApi.pending:
        return const Color(0xFFFF9914);
      case JobApplicationStatusApi.accepted:
        return const Color(0xFF0BDB0F);
      case JobApplicationStatusApi.rejected:
        return const Color(0xFFED3737);
      case null:
        return JobListingDesign.primaryBlue;
    }
  }

  String get _applicationStatusLabel {
    switch (_currentApplicationStatus) {
      case JobApplicationStatusApi.pending:
        return 'قيد المراجعة';
      case JobApplicationStatusApi.accepted:
        return 'تم قبول الطلب';
      case JobApplicationStatusApi.rejected:
        return 'لم يتم القبول';
      case null:
        return 'تقديم على الوظيفة';
    }
  }

  Future<void> _loadApplicationStatusFromBackend() async {
    if (_statusLoading) return;
    setState(() => _statusLoading = true);
    try {
      final applications = await ApiService.instance.fetchMyJobApplications();
      if (!mounted) return;
      JobApplicationStatusApi? status;
      for (final item in applications) {
        if (item.job.id == widget.job.id) {
          status = item.status;
          break;
        }
      }
      setState(() {
        _currentApplicationStatus = status;
      });
    } catch (_) {
      // Keep default CTA when status cannot be fetched.
    } finally {
      if (mounted) setState(() => _statusLoading = false);
    }
  }

  Future<void> _apply() async {
    if (_applyLoading) return;
    setState(() => _applyLoading = true);
    try {
      await ApiService.instance.applyToJob(widget.job.id);
      if (!mounted) return;
      setState(() {
        _currentApplicationStatus = JobApplicationStatusApi.pending;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إرسال طلب التقديم بنجاح')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.statusCode == 409) {
        setState(() {
          _currentApplicationStatus = JobApplicationStatusApi.pending;
        });
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تعذر إكمال التقديم')));
    } finally {
      if (mounted) setState(() => _applyLoading = false);
    }
  }

  Future<void> _deleteJob() async {
    if (_deletingJob) return;
    final ok = await DeleteJobConfirmDialog.show();
    if (ok != true || !mounted) return;
    setState(() => _deletingJob = true);
    try {
      await ApiService.instance.deleteJobPosting(_displayJob.id);
      if (Get.isRegistered<HomeController>()) {
        unawaited(Get.find<HomeController>().loadJobs());
      }
      if (Get.isRegistered<TalabatController>()) {
        unawaited(Get.find<TalabatController>().load());
      }
      if (!mounted) return;
      Get.back<void>();
      Get.snackbar(
        'تم الحذف',
        'تم حذف الوظيفة بنجاح',
        snackPosition: SnackPosition.BOTTOM,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تعذر حذف الوظيفة')));
    } finally {
      if (mounted) setState(() => _deletingJob = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final job = _displayJob;
    final desc = (job.description ?? '').trim();
    final skills = job.coreSkills.isEmpty
        ? <String>['لم يتم تحديد مهارات']
        : job.coreSkills;
    final deadline =
        job.applicationDeadline?.toLocal() ?? job.createdAt.toLocal();
    final appliedDate =
        '${deadline.day} / ${deadline.month} / ${deadline.year}';

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
                      iconColor: JobListingDesign.titleDark,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                    Expanded(
                      child: Text(
                        'تفاصيل الوظيفة',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Lama Sans',
                          fontWeight: FontWeight.w800,
                          fontSize: 20.sp,
                          height: 1.5,
                          color: JobListingDesign.titleDark,
                        ),
                      ),
                    ),
                    if (_isMyPostedJob)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            padding: EdgeInsets.all(4.r),
                            constraints: BoxConstraints(
                              minWidth: 40.w,
                              minHeight: 40.h,
                            ),
                            icon: _deletingJob
                                ? SizedBox(
                                    width: 20.w,
                                    height: 20.w,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: JobListingDesign.titleDark,
                                    ),
                                  )
                                : Image.asset(
                                    'assets/icons/deletphoto.png',
                                    width: 22.w,
                                    height: 22.h,
                                    fit: BoxFit.contain,
                                  ),
                            onPressed: _deletingJob ? null : _deleteJob,
                          ),
                          SizedBox(width: 4.w),
                          IconButton(
                            padding: EdgeInsets.all(4.r),
                            constraints: BoxConstraints(
                              minWidth: 40.w,
                              minHeight: 40.h,
                            ),
                            icon: Icon(
                              Icons.edit_rounded,
                              color: JobListingDesign.titleDark,
                              size: 22.sp,
                            ),
                            onPressed: () async {
                              final updated = await Navigator.of(context)
                                  .push<JobPosting?>(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          CreateJobView(existingJob: job),
                                    ),
                                  );
                              if (!mounted || updated == null) return;
                              setState(() => _displayJob = updated);
                            },
                          ),
                        ],
                      )
                    else
                      Text(
                        relativeTimeAr(job.createdAt),
                        style: TextStyle(
                          fontFamily: 'Lama Sans',
                          fontWeight: FontWeight.w800,
                          fontSize: 12.sp,
                          height: 1.5,
                          color: JobListingDesign.timeGray,
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 12.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: SizedBox(
                          width: 353.w,
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFFDFEFF),
                              borderRadius: BorderRadius.circular(22.r),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x29040814),
                                  offset: Offset(0, 0),
                                  blurRadius: 6,
                                  spreadRadius: 0,
                                ),
                              ],
                            ),
                            padding: EdgeInsets.all(16.r),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Image.asset(
                                  'assets/icons/icon 3.png',
                                  width: 61.883705139160156.w,
                                  height: 61.883705139160156.h,
                                  fit: BoxFit.contain,
                                ),
                                SizedBox(height: 10.h),
                                Text(
                                  job.requiredSpecialty,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'Lama Sans',
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16.sp,
                                    color: JobListingDesign.titleDark,
                                  ),
                                ),
                                SizedBox(height: 2.h),
                                Text(
                                  job.locationSubtitle,
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: 'Lama Sans',
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12.sp,
                                    color: const Color(0xFF646B79),
                                  ),
                                ),
                                SizedBox(height: 16.h),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    SizedBox(
                                      width: 157.31.w,
                                      height: 45.62.h,
                                      child: _metaTile(
                                        '${job.yearsExperience} سنوات خبرة',
                                        'assets/icons/سنوات الخبرة.png',
                                      ),
                                    ),
                                    SizedBox(
                                      width: 157.31.w,
                                      height: 45.62.h,
                                      child: _metaTile(
                                        '${job.shiftHours ?? 10} ساعات دوام',
                                        'assets/icons/ساعات الدوام.png',
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8.h),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    SizedBox(
                                      width: 157.31.w,
                                      height: 45.62.h,
                                      child: _metaTile(
                                        job.salaryChipText,
                                        'assets/icons/الراتب.png',
                                      ),
                                    ),
                                    SizedBox(
                                      width: 157.31.w,
                                      height: 45.62.h,
                                      child: _metaTile(
                                        job.workingHours,
                                        'assets/icons/اوقات الدوام.png',
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 12.h),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 8.h),
                      SizedBox(
                        width: 353.w,
                        height: 54.h,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFFDFEFF),
                            borderRadius: BorderRadius.circular(22.r),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x29040814),
                                offset: Offset(0, 0),
                                blurRadius: 6,
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          padding: EdgeInsets.all(16.r),
                          child: Row(
                            textDirection: TextDirection.rtl,
                            children: [
                              Image.asset(
                                'assets/icons/العنوان.png',
                                width: 23.w,
                                height: 23.h,
                                fit: BoxFit.contain,
                              ),
                              SizedBox(width: 8.w),
                              Expanded(
                                child: Text(
                                  job.locationSubtitle,
                                  textAlign: TextAlign.right,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: 'Lama Sans',
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14.sp,
                                    height: 1.5,
                                    color: const Color(0xFF2471FF),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 20.h),
                      _sectionLabel('حول الوظيفة', fontWeight: FontWeight.w900),
                      SizedBox(height: 8.h),
                      Text(
                        desc.isEmpty
                            ? 'تفاصيل الوظيفة أو نبذة مختصرة عنها الوظيفة او نبذة مختصرة عنها تفاصيل الوظيفة او نبذة مختصرة عنها.'
                            : desc,
                        textAlign: TextAlign.justify,
                        style: TextStyle(
                          fontFamily: 'Lama Sans',
                          fontWeight: FontWeight.w700,
                          fontSize: 14.sp,
                          height: 2.0,
                          color: const Color(0xFF040814),
                        ),
                      ),
                      SizedBox(height: 12.h),
                      Divider(
                        color: const Color(0x1A000000),
                        thickness: 1,
                        height: 1.h,
                      ),
                      SizedBox(height: 12.h),
                      _sectionLabel(
                        'التعليم المطلوب',
                        fontWeight: FontWeight.w900,
                      ),
                      SizedBox(height: 8.h),
                      _bullet(jobEducationLabelAr(job.education)),
                      SizedBox(height: 12.h),
                      Divider(color: const Color(0xFFE5E7EB), height: 1.h),
                      SizedBox(height: 12.h),
                      _sectionLabel(
                        'اللغات المطلوبة',
                        fontWeight: FontWeight.w900,
                      ),
                      SizedBox(height: 8.h),
                      ...job.languages.isEmpty
                          ? <Widget>[_bullet('لم يتم تحديد اللغات')]
                          : job.languages
                                .map((l) => _bullet(jobLanguageLabelAr(l)))
                                .toList(),
                      SizedBox(height: 12.h),
                      Divider(color: const Color(0xFFE5E7EB), height: 1.h),
                      SizedBox(height: 12.h),
                      _sectionLabel(
                        'المهارات المطلوبة',
                        fontWeight: FontWeight.w900,
                      ),
                      SizedBox(height: 8.h),
                      ...skills.map(_bullet),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.zero,
                child: _adaptiveJobBottomBar(context, job, appliedDate),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _adaptiveJobBottomBar(
    BuildContext context,
    JobPosting job,
    String appliedDate,
  ) {
    if (Get.isRegistered<HomeController>()) {
      return Obx(() {
        final uid = Get.find<HomeController>().profile.value?.id ?? _myUserId;
        final isOwner = uid != null && uid == job.postedBy;
        return isOwner
            ? _ownerJobBottomBar(context)
            : _visitorJobBottomBar(context, job, appliedDate);
      });
    }
    return _isMyPostedJob
        ? _ownerJobBottomBar(context)
        : _visitorJobBottomBar(context, job, appliedDate);
  }

  Widget _ownerJobBottomBar(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    /// عرض كامل، ملاصق للأسفل، زوايا علوية فقط؛ الارتفاع 92 + safe area.
    const barH = 92.0;

    return SizedBox(
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
          padding: EdgeInsets.fromLTRB(21.w, 19.h, 19.w, 23.h + bottomInset),
          child: Center(
            child: SizedBox(
              width: 353.w,
              height: 50.h,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: _OwnerJobDetailBarDesign.trackTintBg,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Row(
                  textDirection: TextDirection.rtl,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: _ownerBarSegment(
                        label: 'المتقدمين',
                        selected: _ownerTab == _OwnerJobDetailTab.applicants,
                        showNotificationDot: _applicantCount > 0,
                        onTap: () {
                          setState(
                            () => _ownerTab = _OwnerJobDetailTab.applicants,
                          );
                          unawaited(
                            Navigator.of(context)
                                .push<void>(
                                  MaterialPageRoute<void>(
                                    builder: (_) => JobApplicantsView(
                                      job: _displayJob,
                                      applicantCountForBadge: _applicantCount,
                                    ),
                                  ),
                                )
                                .then((_) {
                                  if (!mounted) return;
                                  setState(
                                    () => _ownerTab =
                                        _OwnerJobDetailTab.jobManagement,
                                  );
                                  unawaited(_loadApplicantCount());
                                }),
                          );
                        },
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: _ownerBarSegment(
                        label: 'إدارة الوظيفة',
                        selected: _ownerTab == _OwnerJobDetailTab.jobManagement,
                        showNotificationDot: false,
                        onTap: () => setState(
                          () => _ownerTab = _OwnerJobDetailTab.jobManagement,
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
    );
  }

  Widget _ownerBarSegment({
    required String label,
    required bool selected,
    required bool showNotificationDot,
    required VoidCallback onTap,
  }) {
    const orange = _OwnerJobDetailBarDesign.activeOrange;
    const labelOn = _OwnerJobDetailBarDesign.activeLabel;
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
                              color: _OwnerJobDetailBarDesign.badgeRed,
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

  Widget _visitorJobBottomBar(
    BuildContext context,
    JobPosting job,
    String appliedDate,
  ) {
    return Center(
      child: SizedBox(
        width: 393.w,
        child: Container(
          constraints: BoxConstraints(minHeight: 123.h),
          decoration: BoxDecoration(
            color: const Color(0xFFFDFEFF),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(44.r),
              topRight: Radius.circular(44.r),
              bottomLeft: Radius.circular(0),
              bottomRight: Radius.circular(0),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1A000000),
                offset: Offset(0, -1),
                blurRadius: 16.1,
                spreadRadius: 0,
              ),
            ],
          ),
          padding: EdgeInsets.fromLTRB(20.w, 13.h, 20.w, 22.h),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  textDirection: TextDirection.rtl,
                  children: [
                    Image.asset(
                      'assets/icons/اخر موعد.png',
                      width: 22.w,
                      height: 22.h,
                      fit: BoxFit.contain,
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      'آخر موعد للتقديم $appliedDate',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Lama Sans',
                        fontWeight: FontWeight.w700,
                        fontSize: 14.sp,
                        height: 1.5,
                        color: const Color(0xFFED3737),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16.h),
              Row(
                textDirection: TextDirection.rtl,
                children: [
                  Expanded(
                    child: Center(
                      child: SizedBox(
                        width: 292.w,
                        height: 52.h,
                        child: ElevatedButton(
                          onPressed: _isFromApplicationCard
                              ? null
                              : (_applyLoading ? null : _apply),
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: _isFromApplicationCard
                                ? _applicationStatusColor
                                : JobListingDesign.primaryBlue,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor:
                                (_isFromApplicationCard
                                        ? _applicationStatusColor
                                        : JobListingDesign.primaryBlue)
                                    .withValues(alpha: 0.95),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                          ),
                          child:
                              (!_isFromApplicationCard &&
                                  (_applyLoading || _statusLoading))
                              ? SizedBox(
                                  width: 22.w,
                                  height: 22.w,
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  _applicationStatusLabel,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'Lama Sans',
                                    fontWeight: FontWeight.w800,
                                    fontSize: 20.sp,
                                    height: 1.5,
                                    color: const Color(0xFFFDFEFF),
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Material(
                    color: JobListingDesign.saveButtonBg,
                    borderRadius: BorderRadius.circular(12.r),
                    child: Obx(
                      () => InkWell(
                        onTap: () => _bookmarks.toggle(job),
                        borderRadius: BorderRadius.circular(12.r),
                        child: Container(
                          width: 48.w,
                          height: 48.w,
                          alignment: Alignment.center,
                          child: Icon(
                            _bookmarks.isSaved(job.id)
                                ? Icons.bookmark_rounded
                                : Icons.bookmark_border_rounded,
                            color: JobListingDesign.primaryBlue,
                            size: 24.sp,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text, {FontWeight fontWeight = FontWeight.w700}) {
    return Align(
      alignment: Alignment.centerRight,
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Lama Sans',
          fontWeight: fontWeight,
          fontSize: 16.sp,
          height: 1.5,
          color: JobListingDesign.titleDark,
        ),
      ),
    );
  }

  Widget _bullet(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Text(
            '•',
            style: TextStyle(
              fontFamily: 'Lama Sans',
              fontWeight: FontWeight.w900,
              fontSize: 18.sp,
              color: Colors.black,
            ),
          ),
          SizedBox(width: 6.w),
          Expanded(
            child: Text(
              text,
              textAlign: TextAlign.justify,
              style: TextStyle(
                fontFamily: 'Lama Sans',
                fontWeight: FontWeight.w700,
                fontSize: 14.sp,
                height: 2.0,
                color: const Color(0xFF272B33),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metaTile(String value, String iconAsset) {
    return Container(
      padding: EdgeInsets.fromLTRB(8.w, 11.h, 8.w, 11.h),
      decoration: BoxDecoration(
        color: const Color(0x4DD9D9D9),
        borderRadius: BorderRadius.circular(7.28.r),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Image.asset(
            iconAsset,
            width: 21.w,
            height: 21.h,
            fit: BoxFit.contain,
          ),
          SizedBox(width: 6.w),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Lama Sans',
                fontWeight: FontWeight.w800,
                fontSize: 13.sp,
                height: 1.5,
                color: JobListingDesign.titleDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
