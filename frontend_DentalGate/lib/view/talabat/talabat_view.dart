import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'package:dental_gate/core/app_routes.dart';
import 'package:dental_gate/controllers/talabat_controller.dart';
import 'package:dental_gate/models/my_job_application_item.dart';
import 'package:dental_gate/models/job_posting.dart';
import 'package:dental_gate/widgets/posted_job_owner_card.dart';
import 'package:dental_gate/widgets/job_application_card.dart';
import 'package:dental_gate/widgets/pill_bottom_nav_bar.dart';
import 'package:dental_gate/widgets/unified_search_bar.dart';

class TalabatView extends GetView<TalabatController> {
  const TalabatView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final postedTab =
          controller.activeSection.value == TalabatSection.postedJobs;
      return Scaffold(
        backgroundColor: postedTab
            ? PostedJobsDesign.pageBg
            : const Color(0xFFFDFEFF),
        body: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 57.h),
              Center(
                child: Text(
                  'الطلبات',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Lama Sans',
                    fontWeight: FontWeight.w900,
                    fontSize: 20.sp,
                    height: 1.5,
                    color: const Color(0xFF040814),
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: const _TalabatSectionSwitcher(),
              ),
              SizedBox(height: 14.h),
              Center(
                child: SizedBox(
                  width: 353.w,
                  child: _TalabatSearchBar(controller: controller),
                ),
              ),
              Obx(() {
                if (!controller.hasActiveFilters) {
                  return const SizedBox.shrink();
                }
                final status = controller.selectedStatus.value;
                final statusText =
                    controller.activeSection.value == TalabatSection.postedJobs
                    ? null
                    : status == null
                    ? null
                    : _TalabatSearchBar.statusLabelFromApi(status);
                final govText = controller.selectedGovernorate.value;
                return Padding(
                  padding: EdgeInsets.fromLTRB(22.w, 12.h, 22.w, 4.h),
                  child: Row(
                    textDirection: TextDirection.rtl,
                    children: [
                      Text(
                        'تصفية حسب :',
                        style: TextStyle(
                          fontFamily: 'Lama Sans',
                          fontWeight: FontWeight.w700,
                          fontSize: 16.sp,
                          color: const Color(0xFF040814),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      if (statusText != null)
                        _ActiveFilterChip(
                          text: statusText,
                          onRemove: () => controller.applyFilters(
                            status: null,
                            governorate: controller.selectedGovernorate.value,
                          ),
                        ),
                      if (statusText != null && govText != null)
                        SizedBox(width: 6.w),
                      if (govText != null)
                        _ActiveFilterChip(
                          text: govText,
                          onRemove: () => controller.applyFilters(
                            status: controller.selectedStatus.value,
                            governorate: null,
                          ),
                        ),
                    ],
                  ),
                );
              }),
              SizedBox(height: 16.h),
              Expanded(
                child: Obx(() {
                  if (controller.isLoading.value) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (controller.errorMessage.value != null) {
                    return Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24.w),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              controller.errorMessage.value!,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Lama Sans',
                                fontSize: 15.sp,
                                color: Colors.red.shade700,
                              ),
                            ),
                            SizedBox(height: 16.h),
                            TextButton(
                              onPressed: controller.load,
                              child: Text(
                                'إعادة المحاولة',
                                style: TextStyle(
                                  fontFamily: 'Lama Sans',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14.sp,
                                  color: PillNavDesign.activeBlue,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  final isApplicationsTab =
                      controller.activeSection.value ==
                      TalabatSection.applications;
                  final appList = controller.filteredItems;
                  final postedList = controller.filteredPostedJobs;
                  final visibleList = isApplicationsTab ? appList : postedList;
                  if (visibleList.isEmpty) {
                    final isSearchMode = controller.searchQuery.value
                        .trim()
                        .isNotEmpty;
                    if (isSearchMode) {
                      return Center(
                        child: Text(
                          'لا نتائج للبحث',
                          style: TextStyle(
                            fontFamily: 'Lama Sans',
                            fontWeight: FontWeight.w600,
                            fontSize: 15.sp,
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                      );
                    }
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            'assets/icons/لم يتقدم الى الي طلب بعد.png',
                            width: 250.w,
                            height: 250.h,
                            fit: BoxFit.contain,
                          ),
                          SizedBox(height: 10.h),
                          Text(
                            isApplicationsTab
                                ? 'لم تقدم على أي وظيفة بعد'
                                : 'لا توجد وظائف منشورة بعد',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Lama Sans',
                              fontWeight: FontWeight.w800,
                              fontSize: 22.sp,
                              height: 1.0,
                              color: const Color(0xFF505558),
                            ),
                          ),
                          SizedBox(height: 10.h),
                          Text(
                            isApplicationsTab
                                ? 'ابدأ باختيار وظيفة والتقديم عليها'
                                : 'قم بنشر وظيفة لتظهر هنا',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Lama Sans',
                              fontWeight: FontWeight.w600,
                              fontSize: 16.sp,
                              height: 26 / 16,
                              color: const Color(0xFF505558),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return RefreshIndicator(
                    color: PillNavDesign.activeBlue,
                    onRefresh: controller.load,
                    child: isApplicationsTab
                        ? ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(
                              parent: BouncingScrollPhysics(),
                            ),
                            padding: EdgeInsets.fromLTRB(18.w, 0, 18.w, 100.h),
                            itemCount: appList.length,
                            separatorBuilder: (context, _) =>
                                SizedBox(height: 12.h),
                            itemBuilder: (context, index) {
                              return JobApplicationTalabatCard(
                                item: appList[index],
                              );
                            },
                          )
                        : _PostedJobsOwnerList(posted: postedList),
                  );
                }),
              ),
            ],
          ),
        ),
      );
    });
  }
}

class _PostedJobsOwnerList extends StatelessWidget {
  const _PostedJobsOwnerList({required this.posted});

  final List<JobPosting> posted;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<TalabatController>();
    final sorted = List<JobPosting>.from(posted)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final latest = sorted.take(4).toList();
    return Obx(() {
      final counts = controller.applicantCountByJobId;
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 100.h),
        children: [
          Text(
            'أحدث الوظائف',
            style: TextStyle(
              fontFamily: 'Lama Sans',
              fontWeight: FontWeight.w800,
              fontSize: 18.sp,
              height: 1.2,
              color: const Color(0xFF000000),
            ),
          ),
          SizedBox(height: 14.h),
          ...latest.asMap().entries.map((e) {
            return Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: PostedJobOwnerCard(
                job: e.value,
                applicantCount: counts[e.value.id] ?? 0,
              ),
            );
          }),
          SizedBox(height: 28.h),
          Text(
            'جميع الوظائف',
            style: TextStyle(
              fontFamily: 'Lama Sans',
              fontWeight: FontWeight.w800,
              fontSize: 18.sp,
              height: 1.2,
              color: const Color(0xFF000000),
            ),
          ),
          SizedBox(height: 14.h),
          ...sorted.asMap().entries.map((e) {
            return Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: PostedJobOwnerCard(
                job: e.value,
                applicantCount: counts[e.value.id] ?? 0,
              ),
            );
          }),
        ],
      );
    });
  }
}

class _PostedJobsSearchRow extends StatelessWidget {
  const _PostedJobsSearchRow({required this.controller});

  final TalabatController controller;

  @override
  Widget build(BuildContext context) {
    return Row(
      textDirection: TextDirection.rtl,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Container(
            height: 52.h,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26.r),
              border: Border.all(color: const Color(0xFFE5E7EB)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 6,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            padding: EdgeInsets.symmetric(horizontal: 14.w),
            child: Row(
              textDirection: TextDirection.rtl,
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
                    controller: controller.searchController,
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      fontFamily: 'Lama Sans',
                      fontWeight: FontWeight.w600,
                      fontSize: 14.sp,
                      color: const Color(0xFF040814),
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      hintText: 'أبحث عن وظيفة نشرتها ..',
                      hintStyle: TextStyle(
                        fontFamily: 'Lama Sans',
                        fontWeight: FontWeight.w500,
                        fontSize: 14.sp,
                        color: const Color(0xFF9CA3AF),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(width: 12.w),
        Material(
          color: PostedJobsDesign.primaryBlue,
          borderRadius: BorderRadius.circular(12.r),
          child: InkWell(
            onTap: () => Get.toNamed(Routes.createJob),
            borderRadius: BorderRadius.circular(12.r),
            child: SizedBox(
              width: 52.w,
              height: 52.h,
              child: Icon(Icons.add_rounded, color: Colors.white, size: 28.sp),
            ),
          ),
        ),
      ],
    );
  }
}

class _ActiveFilterChip extends StatelessWidget {
  const _ActiveFilterChip({required this.text, required this.onRemove});

  final String text;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFE5E7EB),
      borderRadius: BorderRadius.circular(12.r),
      child: InkWell(
        onTap: onRemove,
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.fromLTRB(10.w, 6.h, 10.w, 6.h),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            textDirection: TextDirection.rtl,
            children: [
              Text(
                text,
                style: TextStyle(
                  fontFamily: 'Lama Sans',
                  fontWeight: FontWeight.w800,
                  fontSize: 14.sp,
                  color: const Color(0xFF040814),
                ),
              ),
              SizedBox(width: 6.w),
              Text(
                '×',
                style: TextStyle(
                  fontFamily: 'Lama Sans',
                  fontWeight: FontWeight.w900,
                  fontSize: 16.sp,
                  color: const Color(0xFF111827),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TalabatSectionSwitcher extends GetView<TalabatController> {
  const _TalabatSectionSwitcher();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return Container(
        height: 50.h,
        padding: EdgeInsets.all(4.r),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF3FA),
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Row(
          children: [
            Expanded(
              child: _SectionItem(
                label: 'طلبات التوظيف',
                selected:
                    controller.activeSection.value ==
                    TalabatSection.applications,
                onTap: () => controller.setSection(TalabatSection.applications),
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: _SectionItem(
                label: 'الوظائف المنشورة',
                selected:
                    controller.activeSection.value == TalabatSection.postedJobs,
                onTap: () => controller.setSection(TalabatSection.postedJobs),
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _SectionItem extends StatelessWidget {
  const _SectionItem({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? Colors.white : Colors.transparent,
      borderRadius: BorderRadius.circular(12.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Center(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Lama Sans',
              fontWeight: FontWeight.w800,
              fontSize: 13.sp,
              color: selected
                  ? const Color(0xFF040814)
                  : const Color(0xFF64748B),
            ),
          ),
        ),
      ),
    );
  }
}

/// شريط بحث — حدود رمادية خفيفة، أيقونة بحث، placeholder، زر تصفية يسار الشاشة.
class _TalabatSearchBar extends StatelessWidget {
  const _TalabatSearchBar({required this.controller});

  final TalabatController controller;

  static const List<String> _governorates = [
    'بابل',
    'بغداد',
    'النجف',
    'كربلاء',
    'البصرة',
  ];

  static String statusLabelFromApi(JobApplicationStatusApi status) {
    switch (status) {
      case JobApplicationStatusApi.accepted:
        return 'مقبول';
      case JobApplicationStatusApi.pending:
        return 'قيد المراجعة';
      case JobApplicationStatusApi.rejected:
        return 'لم يقبل';
    }
  }

  static JobApplicationStatusApi? statusApiFromLabel(String? label) {
    switch (label) {
      case 'مقبول':
        return JobApplicationStatusApi.accepted;
      case 'قيد المراجعة':
        return JobApplicationStatusApi.pending;
      case 'لم يقبل':
        return JobApplicationStatusApi.rejected;
      default:
        return null;
    }
  }

  void _onLeadingActionTap(BuildContext context, bool isPostedTab) {
    if (isPostedTab) return;
    _showFilterSheet(context);
  }

  Future<String?> _showGovernoratePicker(
    BuildContext context,
    String? selected,
  ) async {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: SafeArea(
            top: false,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFFDFEFF),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1A040814),
                    blurRadius: 16,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              padding: EdgeInsets.fromLTRB(18.w, 10.h, 18.w, 16.h),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 52.w,
                    height: 5.h,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD1D5DB),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    'اختيار المحافظة',
                    style: TextStyle(
                      fontFamily: 'Lama Sans',
                      fontWeight: FontWeight.w800,
                      fontSize: 18.sp,
                      color: const Color(0xFF040814),
                    ),
                  ),
                  SizedBox(height: 10.h),
                  ..._governorates.map((g) {
                    final isSelected = selected == g;
                    return Padding(
                      padding: EdgeInsets.only(bottom: 8.h),
                      child: Material(
                        color: isSelected
                            ? const Color(0x1A5993FF)
                            : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14.r),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14.r),
                          onTap: () => Navigator.of(context).pop(g),
                          child: Container(
                            height: 50.h,
                            padding: EdgeInsets.symmetric(horizontal: 14.w),
                            child: Row(
                              children: [
                                if (isSelected)
                                  Icon(
                                    Icons.check_circle_rounded,
                                    color: const Color(0xFF5993FF),
                                    size: 20.sp,
                                  )
                                else
                                  Icon(
                                    Icons.location_on_outlined,
                                    color: const Color(0xFF9CA3AF),
                                    size: 20.sp,
                                  ),
                                SizedBox(width: 8.w),
                                Expanded(
                                  child: Text(
                                    g,
                                    style: TextStyle(
                                      fontFamily: 'Lama Sans',
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15.sp,
                                      color: const Color(0xFF040814),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showFilterSheet(BuildContext context) async {
    final isPostedTab =
        controller.activeSection.value == TalabatSection.postedJobs;
    String? selectedStatus = controller.selectedStatus.value == null
        ? null
        : statusLabelFromApi(controller.selectedStatus.value!);
    if (isPostedTab) {
      selectedStatus = null;
    }
    String? selectedGovernorate = controller.selectedGovernorate.value;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: SafeArea(
                top: false,
                bottom: false,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: SizedBox(
                    width: 393.w,
                    height: 409.h,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDFDFD),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(32.r),
                          topRight: Radius.circular(32.r),
                          bottomLeft: Radius.circular(0),
                          bottomRight: Radius.circular(0),
                        ),
                      ),
                      padding: EdgeInsets.fromLTRB(22.w, 10.h, 22.w, 28.h),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(
                            child: Container(
                              width: 56.w,
                              height: 6.h,
                              decoration: BoxDecoration(
                                color: const Color(0xFFD1D5DB),
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                            ),
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            'فلترة الطلبات',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Lama Sans',
                              fontWeight: FontWeight.w800,
                              fontSize: 20.sp,
                              height: 1.0,
                              color: const Color(0xFF040814),
                            ),
                          ),
                          SizedBox(height: 40.h),
                          if (!isPostedTab) ...[
                            Row(
                              textDirection: TextDirection.rtl,
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Container(
                                  width: 6.w,
                                  height: 6.w,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFEF4444),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                SizedBox(width: 6.w),
                                Text(
                                  'حسب حالة الطلب',
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                    fontFamily: 'Lama Sans',
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16.sp,
                                    height: 1.5,
                                    color: const Color(0xFF040814),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 14.h),
                            Row(
                              textDirection: TextDirection.rtl,
                              children: [
                                Expanded(
                                  child: _statusFilterButton(
                                    label: 'مقبول',
                                    selected: selectedStatus == 'مقبول',
                                    onTap: () => setModalState(
                                      () => selectedStatus = 'مقبول',
                                    ),
                                  ),
                                ),
                                SizedBox(width: 10.w),
                                Expanded(
                                  child: _statusFilterButton(
                                    label: 'قيد المراجعة',
                                    selected: selectedStatus == 'قيد المراجعة',
                                    onTap: () => setModalState(
                                      () => selectedStatus = 'قيد المراجعة',
                                    ),
                                  ),
                                ),
                                SizedBox(width: 10.w),
                                Expanded(
                                  child: _statusFilterButton(
                                    label: 'لم يقبل',
                                    selected: selectedStatus == 'لم يقبل',
                                    onTap: () => setModalState(
                                      () => selectedStatus = 'لم يقبل',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 29.h),
                          ] else
                            SizedBox(height: 4.h),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              'حسب المحافظة',
                              style: TextStyle(
                                fontFamily: 'Lama Sans',
                                fontWeight: FontWeight.w700,
                                fontSize: 16.sp,
                                height: 1.5,
                                color: const Color(0xFF040814),
                              ),
                            ),
                          ),
                          SizedBox(height: 12.h),
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16.r),
                              onTap: () async {
                                final value = await _showGovernoratePicker(
                                  context,
                                  selectedGovernorate,
                                );
                                if (value != null) {
                                  setModalState(
                                    () => selectedGovernorate = value,
                                  );
                                }
                              },
                              child: Container(
                                width: 309.w,
                                height: 50.h,
                                padding: EdgeInsets.fromLTRB(
                                  22.w,
                                  10.h,
                                  21.w,
                                  11.h,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0x70D9D9D9),
                                  borderRadius: BorderRadius.circular(16.r),
                                  border: Border.all(
                                    color: const Color(0x335993FF),
                                    width: 1.1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 30.w,
                                      height: 30.w,
                                      decoration: BoxDecoration(
                                        color: const Color(0x225993FF),
                                        borderRadius: BorderRadius.circular(
                                          9.r,
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.keyboard_arrow_down_rounded,
                                        size: 22.sp,
                                        color: const Color(0xFF1F2937),
                                      ),
                                    ),
                                    SizedBox(width: 10.w),
                                    Expanded(
                                      child: Text(
                                        selectedGovernorate ?? 'اختر المحافظة',
                                        textAlign: TextAlign.right,
                                        style: TextStyle(
                                          fontFamily: 'Lama Sans',
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16.sp,
                                          color: selectedGovernorate == null
                                              ? const Color(0xFF6B7280)
                                              : const Color(0xFF040814),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 44.h),
                          SizedBox(
                            width: 309.w,
                            height: 48.h,
                            child: ElevatedButton(
                              onPressed: () {
                                controller.applyFilters(
                                  status: isPostedTab
                                      ? null
                                      : statusApiFromLabel(selectedStatus),
                                  governorate: selectedGovernorate,
                                );
                                Navigator.of(context).pop();
                              },
                              style: ElevatedButton.styleFrom(
                                elevation: 0,
                                backgroundColor: const Color(0xFF5993FF),
                                foregroundColor: const Color(0xFFFDFEFF),
                                padding: EdgeInsets.fromLTRB(
                                  45.w,
                                  13.h,
                                  45.w,
                                  13.h,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                              ),
                              child: Text(
                                'فلترة',
                                style: TextStyle(
                                  fontFamily: 'Lama Sans',
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16.sp,
                                  height: 1.5,
                                  color: const Color(0xFFFDFEFF),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _statusFilterButton({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(10.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10.r),
        child: Container(
          width: 98.w,
          height: 42.h,
          alignment: Alignment.center,
          padding: EdgeInsets.fromLTRB(8.w, 5.h, 8.w, 5.h),
          decoration: BoxDecoration(
            color: selected ? const Color(0x4DB3B3B3) : Colors.white,
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(
              color: selected ? Colors.transparent : const Color(0xFF9CA3AF),
              width: 1.2,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Lama Sans',
              fontWeight: FontWeight.w800,
              fontSize: 12.sp,
              height: 1.5,
              color: const Color(0xFF040814),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isPostedTab =
          controller.activeSection.value == TalabatSection.postedJobs;
      if (isPostedTab) {
        return _PostedJobsSearchRow(controller: controller);
      }
      return UnifiedSearchBar(
        hintText: 'ابحث عن طلبك ..',
        controller: controller.searchController,
        onFilterTap: () => _onLeadingActionTap(context, isPostedTab),
        actionIconAsset: 'assets/icons/filtter.png',
        actionIconWidth: 26,
        actionIconHeight: 29,
        actionButtonColor: const Color(0xFFFDFEFF),
        actionTooltip: 'فلترة',
      );
    });
  }
}
