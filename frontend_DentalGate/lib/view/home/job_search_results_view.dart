import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'package:dental_gate/controllers/home_controller.dart';
import 'package:dental_gate/core/app_routes.dart';
import 'package:dental_gate/services/job_search_history_service.dart';
import 'package:dental_gate/widgets/job_posting_card.dart';
import 'package:dental_gate/widgets/job_search_app_bar_row.dart';
import 'package:dental_gate/widgets/job_search_filter_sheet.dart';

/// شاشة نتائج البحث والفلترة (تخصص + خبرة + محافظة عند فتحها من الشيت).
class JobSearchResultsView extends StatefulWidget {
  const JobSearchResultsView({
    super.key,
    this.initialQuery = '',
    this.initialExperienceIndex,
    this.initialProvince,
  });

  final String initialQuery;

  /// عند `null` لا يُقيَّد بسنوات الخبرة (فتح من بحث نصي فقط).
  final int? initialExperienceIndex;
  final String? initialProvince;

  @override
  State<JobSearchResultsView> createState() => _JobSearchResultsViewState();
}

class _JobSearchResultsViewState extends State<JobSearchResultsView> {
  static const _bg = Color(0xFFF5F6F8);
  static const _labelMuted = Color(0xFF6B7280);
  static const _chipBg = Color(0x4DC4CBD3);

  static const _expChipLabels = [
    '1–3 سنوات',
    '3–5 سنوات',
    'أكثر من 5 سنوات',
  ];

  late final TextEditingController _controller;
  late final FocusNode _focus;
  final HomeController _home = Get.find<HomeController>();

  late String _activeQuery;
  int? _experienceIndex;
  String? _province;

  bool get _hasActiveFilters =>
      _activeQuery.isNotEmpty ||
      _experienceIndex != null ||
      (_province != null && _province!.trim().isNotEmpty);

  String? get _specialtyLabel {
    final q = _activeQuery.trim();
    return q.isEmpty ? null : q;
  }

  String? get _experienceLabel {
    final i = _experienceIndex;
    if (i == null || i < 0 || i >= _expChipLabels.length) return null;
    return _expChipLabels[i];
  }

  String? get _provinceLabel {
    final p = _province?.trim();
    if (p == null || p.isEmpty) return null;
    return p;
  }

  @override
  void initState() {
    super.initState();
    _activeQuery = widget.initialQuery.trim();
    _experienceIndex = widget.initialExperienceIndex;
    _province = widget.initialProvince;
    _controller = TextEditingController(text: widget.initialQuery);
    _focus = FocusNode(skipTraversal: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _submit(String raw) {
    final q = raw.trim();
    if (q.isEmpty) return;
    unawaited(JobSearchHistoryService.addQuery(q));
    setState(() {
      _activeQuery = q;
      _experienceIndex = null;
      _province = null;
    });
  }

  bool _hasFiltersAfter({
    String? query,
    int? experienceIndex,
    bool clearExperience = false,
    String? province,
    bool clearProvince = false,
  }) {
    final q = query ?? _activeQuery;
    final exp = clearExperience ? null : (experienceIndex ?? _experienceIndex);
    final prov = clearProvince ? null : (province ?? _province);
    return q.trim().isNotEmpty ||
        exp != null ||
        (prov != null && prov.trim().isNotEmpty);
  }

  void _removeSpecialtyFilter() {
    final shouldExit = !_hasFiltersAfter(query: '');
    if (shouldExit) {
      _activeQuery = '';
      _controller.clear();
      unawaited(Get.offNamed(Routes.jobSearch));
      return;
    }
    setState(() {
      _activeQuery = '';
      _controller.clear();
    });
  }

  void _removeExperienceFilter() {
    final shouldExit = !_hasFiltersAfter(clearExperience: true);
    if (shouldExit) {
      _experienceIndex = null;
      unawaited(Get.offNamed(Routes.jobSearch));
      return;
    }
    setState(() => _experienceIndex = null);
  }

  void _removeProvinceFilter() {
    final shouldExit = !_hasFiltersAfter(clearProvince: true);
    if (shouldExit) {
      _province = null;
      unawaited(Get.offNamed(Routes.jobSearch));
      return;
    }
    setState(() => _province = null);
  }

  Widget _specialtyFilterStrip() {
    final chips = <MapEntry<String, VoidCallback>>[
      if (_specialtyLabel != null)
        MapEntry(
          _specialtyLabel!,
          _removeSpecialtyFilter,
        ),
      if (_experienceLabel != null)
        MapEntry(
          _experienceLabel!,
          _removeExperienceFilter,
        ),
      if (_provinceLabel != null)
        MapEntry(
          _provinceLabel!,
          _removeProvinceFilter,
        ),
    ];
    return Padding(
      padding: EdgeInsets.fromLTRB(14.w, 16.h, 14.w, 4.h),
      child: Row(
        textDirection: TextDirection.rtl,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 42.h,
            child: Center(
              child: Text(
                'تصفية حسب : ',
                style: TextStyle(
                  fontFamily: 'Lama Sans',
                  fontWeight: FontWeight.w600,
                  fontSize: 14.sp,
                  height: 1.35,
                  color: const Color(0xFF040814),
                ),
              ),
            ),
          ),
          if (_hasActiveFilters) ...[
            SizedBox(width: 8.w),
            Expanded(
              child: Wrap(
                spacing: 6.w,
                runSpacing: 6.h,
                children: chips
                    .map(
                      (chip) => Container(
                        height: 42.h,
                        padding: EdgeInsets.fromLTRB(
                          8.96.w,
                          8.14.h,
                          8.96.w,
                          8.14.h,
                        ),
                        decoration: BoxDecoration(
                          color: _chipBg,
                          borderRadius: BorderRadius.circular(13.03.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              chip.key,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Lama Sans',
                                fontWeight: FontWeight.w800,
                                fontSize: 12.sp,
                                height: 1.5,
                                color: const Color(0xFF3D3E46),
                              ),
                            ),
                            SizedBox(width: 8.14.w),
                            InkWell(
                              onTap: chip.value,
                              borderRadius: BorderRadius.circular(10.r),
                              child: Icon(
                                Icons.close_rounded,
                                size: 18.sp,
                                color: const Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showFilterSheet() {
    final initial = _controller.text.trim();
    final spec = kPopularJobSearchChips.contains(initial)
        ? initial
        : kPopularJobSearchChips.first;
    showJobSearchFilterBottomSheet(
      context,
      initialSpecialty: spec,
      initialExperienceIndex: _experienceIndex ?? 0,
      initialProvince: _province,
      onApply: (specialty, expIndex, province) {
        setState(() {
          _controller.text = specialty;
          _activeQuery = specialty.trim();
          _experienceIndex = expIndex;
          _province = province;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _bg,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 6.h),
              JobSearchAppBarRow(
                controller: _controller,
                focusNode: _focus,
                readOnly: false,
                showFilterActiveDot: _hasActiveFilters,
                cancelTextColor: _labelMuted,
                onCancel: () => Get.back(),
                onFilterTap: _showFilterSheet,
                onSubmitted: _submit,
              ),
              _specialtyFilterStrip(),
              SizedBox(height: 8.h),
              Expanded(
                child: Obx(() {
                  final jobs = _home.jobsMatchingJobSearchFilters(
                    _activeQuery,
                    experienceIndex: _experienceIndex,
                    province: _province,
                  );
                  if (jobs.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24.w),
                        child: Text(
                          _hasActiveFilters
                              ? 'لا نتائج مطابقة للفلترة الحالية'
                              : 'لا توجد وظائف لعرضها حالياً',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Lama Sans',
                            fontWeight: FontWeight.w600,
                            fontSize: 15.sp,
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: EdgeInsets.fromLTRB(14.w, 0, 14.w, 24.h),
                    physics: const BouncingScrollPhysics(),
                    itemCount: jobs.length,
                    separatorBuilder: (_, _) => SizedBox(height: 14.h),
                    itemBuilder: (context, index) {
                      return Align(
                        alignment: Alignment.center,
                        child: JobPostingCard(
                          job: jobs[index],
                          outlinedBookmarkStyle: true,
                        ),
                      );
                    },
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
