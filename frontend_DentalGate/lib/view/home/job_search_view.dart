import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'package:dental_gate/controllers/bookmarks_controller.dart';
import 'package:dental_gate/controllers/professional_profile_controller.dart';
import 'package:dental_gate/core/app_routes.dart';
import 'package:dental_gate/widgets/doctor_search_grid_card.dart';
import 'package:dental_gate/models/doctor_search_item.dart';
import 'package:dental_gate/models/job_search_filter_criteria.dart';
import 'package:dental_gate/services/api_service.dart';
import 'package:dental_gate/services/job_search_history_service.dart';
import 'package:dental_gate/view/profile/professional_profile_view.dart';
import 'package:dental_gate/widgets/job_search_app_bar_row.dart';
import 'package:dental_gate/widgets/job_search_filter_sheet.dart';

/// شاشة البحث الكاملة عند الضغط على شريط البحث في الرئيسية.
class JobSearchView extends StatefulWidget {
  const JobSearchView({
    super.key,
    this.initialQuery,
    this.openFilterOnStart = false,
  });

  final String? initialQuery;
  final bool openFilterOnStart;

  @override
  State<JobSearchView> createState() => _JobSearchViewState();
}

class _JobSearchViewState extends State<JobSearchView> {
  static const _bg = Color(0xFFFDFEFF);
  static const _switcherBg = Color(0xFFEFF3FA);

  late final TextEditingController _controller;
  late final FocusNode _focus;
  final BookmarksController _bookmarks = Get.find<BookmarksController>();
  List<String> _history = [];
  bool _openingResults = false;
  bool _doctorLoading = false;
  String? _doctorError;
  List<DoctorSearchItem> _doctorResults = const [];
  Timer? _doctorSearchDebounce;
  _SearchMode _mode = _SearchMode.jobs;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery ?? '');
    _focus = FocusNode();
    _loadHistory();
    unawaited(_loadDoctors(query: _controller.text.trim()));
    _controller.addListener(() {
      if (_mode != _SearchMode.doctors) return;
      _doctorSearchDebounce?.cancel();
      _doctorSearchDebounce = Timer(const Duration(milliseconds: 350), () {
        unawaited(_loadDoctors(query: _controller.text.trim()));
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.openFilterOnStart) {
        _showFilterSheet();
        return;
      }
      _focus.requestFocus();
    });
  }

  Future<void> _loadHistory() async {
    final h = await JobSearchHistoryService.load();
    if (mounted) setState(() => _history = h);
  }

  @override
  void dispose() {
    _doctorSearchDebounce?.cancel();
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _loadDoctors({String? query}) async {
    if (!mounted) return;
    setState(() {
      _doctorLoading = true;
      _doctorError = null;
    });
    try {
      final list = await ApiService.instance.fetchDoctorsForSearch(query: query);
      if (!mounted) return;
      setState(() {
        _doctorResults = list;
        _doctorLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _doctorError = e.message;
        _doctorLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _doctorError = 'تعذر تحميل الأطباء';
        _doctorLoading = false;
      });
    }
  }

  Future<void> _openDoctorProfile(DoctorSearchItem doctor) async {
    final tag = 'search_doctor_profile_${doctor.id}';
    Get.put(ProfessionalProfileController(viewUserId: doctor.id), tag: tag);
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

  /// تنقّل عبر GetX ([Get.offNamed]) بدل Navigator لتفادي تعارض مراقب المسارات
  /// مع [GetMaterialApp] (كان يظهر REPLACE ROUTE null ثم ANR).
  void _submit(String raw) {
    final q = raw.trim();
    if (q.isEmpty || _openingResults) return;
    if (_mode == _SearchMode.doctors) {
      unawaited(_loadDoctors(query: q));
      return;
    }
    _openingResults = true;
    FocusScope.of(context).unfocus();
    unawaited(JobSearchHistoryService.addQuery(q));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        _openingResults = false;
        return;
      }
      try {
        Get.offNamed(Routes.jobSearchTextResults, arguments: q);
      } finally {
        _openingResults = false;
      }
    });
  }

  Future<void> _removeHistoryItem(int index) async {
    final next = await JobSearchHistoryService.removeAt(index);
    if (mounted) setState(() => _history = next);
  }

  Future<void> _clearHistory() async {
    final next = await JobSearchHistoryService.clearAll();
    if (mounted) setState(() => _history = next);
  }

  void _showFilterSheet() {
    final initial = _controller.text.trim();
    final spec = kPopularJobSearchChips.contains(initial)
        ? initial
        : kPopularJobSearchChips.first;
    showJobSearchFilterBottomSheet(
      context,
      initialSpecialty: spec,
      onApply: (specialty, expIndex, province) {
        FocusScope.of(context).unfocus();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          Get.offNamed(
            Routes.jobSearchResults,
            arguments: JobSearchFilterCriteria(
              specialtyText: specialty,
              experienceIndex: expIndex,
              province: province,
            ),
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final doctors = _doctorResults;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _bg,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 8.h),
              Text(
                'البحث',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Lama Sans',
                  fontWeight: FontWeight.w900,
                  fontSize: 18.sp,
                  height: 1.4,
                  color: const Color(0xFF040814),
                ),
              ),
              SizedBox(height: 12.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 14.w),
                child: Container(
                  height: 50.h,
                  padding: EdgeInsets.all(4.r),
                  decoration: BoxDecoration(
                    color: _switcherBg,
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _ModeTab(
                          label: 'بحث عن وظيفة',
                          selected: _mode == _SearchMode.jobs,
                          onTap: () => setState(() => _mode = _SearchMode.jobs),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: _ModeTab(
                          label: 'بحث عن أطباء',
                          selected: _mode == _SearchMode.doctors,
                          onTap: () {
                            setState(() => _mode = _SearchMode.doctors);
                            unawaited(_loadDoctors(query: _controller.text.trim()));
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 14.h),
              JobSearchAppBarRow(
                controller: _controller,
                focusNode: _focus,
                onCancel: () => Get.back(),
                onFilterTap: _showFilterSheet,
                onSubmitted: _submit,
                hintText: _mode == _SearchMode.jobs
                    ? 'أبحث عن وظيفة ..'
                    : 'أبحث عن طبيب ..',
              ),
              if (_mode == _SearchMode.doctors)
                Expanded(
                  child: _doctorLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _doctorError != null
                          ? Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 24.w),
                                child: Text(
                                  _doctorError!,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'Lama Sans',
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14.sp,
                                    color: const Color(0xFF6B7280),
                                  ),
                                ),
                              ),
                            )
                          : doctors.isEmpty
                      ? Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 24.w),
                            child: Text(
                              'لا يوجد أطباء مطابقين للبحث',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Lama Sans',
                                fontWeight: FontWeight.w600,
                                fontSize: 15.sp,
                                color: const Color(0xFF6B7280),
                              ),
                            ),
                          ),
                        )
                      : DoctorSearchTwoColumnList(
                          padding: EdgeInsets.fromLTRB(14.w, 20.h, 14.w, 24.h),
                          crossAxisSpacing: 12.w,
                          mainAxisSpacing: 12.h,
                          itemCount: doctors.length,
                          itemBuilder: (context, index) {
                            final doctor = doctors[index];
                            return Obx(() {
                              final saved = _bookmarks.isDoctorSaved(doctor.id);
                              return DoctorSearchGridCard(
                                doctor: doctor,
                                isSaved: saved,
                                onViewProfile: () => unawaited(
                                  _openDoctorProfile(doctor),
                                ),
                                onToggleSaved: () {
                                  unawaited(_bookmarks.toggleDoctor(doctor));
                                },
                              );
                            });
                          },
                        ),
                )
              else ...[
                SizedBox(height: 22.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14.w),
                  child: Row(
                    children: [
                      Text(
                        'سجل البحث',
                        style: TextStyle(
                          fontFamily: 'Lama Sans',
                          fontWeight: FontWeight.w900,
                          fontSize: 16.sp,
                          color: const Color(0xFF040814),
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed:
                            _history.isEmpty ? null : () => _clearHistory(),
                        icon: _history.isEmpty
                            ? ColorFiltered(
                                colorFilter: const ColorFilter.mode(
                                  Color(0xFFCBD5E1),
                                  BlendMode.srcIn,
                                ),
                                child: Image.asset(
                                  'assets/icons/حذف سحل البحث.png',
                                  width: 16.77.w,
                                  height: 19.89.h,
                                  fit: BoxFit.contain,
                                ),
                              )
                            : Image.asset(
                                'assets/icons/حذف سحل البحث.png',
                                width: 16.77.w,
                                height: 19.89.h,
                                fit: BoxFit.contain,
                              ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 6.h),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.only(bottom: 24.h),
                    children: [
                      if (_history.isEmpty)
                        Padding(
                          padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 20.h),
                          child: Text(
                            'لا يوجد سجل بحث بعد',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontFamily: 'Lama Sans',
                              fontWeight: FontWeight.w600,
                              fontSize: 14.sp,
                              color: const Color(0xFF9CA3AF),
                            ),
                          ),
                        )
                      else
                        ...List.generate(_history.length, (index) {
                          final item = _history[index];
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (index > 0)
                                Divider(
                                  height: 1,
                                  indent: 14.w,
                                  endIndent: 14.w,
                                  color: const Color(0xFFE5E7EB),
                                ),
                              SizedBox(
                                height: 48.h,
                                child: Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 14.w),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () => _submit(item),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              item,
                                              textAlign: TextAlign.right,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontFamily: 'Lama Sans',
                                                fontWeight: FontWeight.w600,
                                                fontSize: 15.sp,
                                                color: const Color(0xFF040814),
                                              ),
                                            ),
                                          ),
                                          IconButton(
                                            onPressed: () =>
                                                _removeHistoryItem(index),
                                            icon: Icon(
                                              Icons.close_rounded,
                                              size: 20.sp,
                                              color: const Color(0xFF9CA3AF),
                                            ),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(
                                              minWidth: 40,
                                              minHeight: 40,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 14.w).copyWith(
                          top: 20.h,
                          bottom: 12.h,
                        ),
                        child: Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: Text(
                            'الأكثر شهرة',
                            textAlign: TextAlign.start,
                            style: TextStyle(
                              fontFamily: 'Lama Sans',
                              fontWeight: FontWeight.w900,
                              fontSize: 16.sp,
                              color: const Color(0xFF040814),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(14.w, 0, 14.w, 16.h),
                        child: Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: Wrap(
                            spacing: 8.14.w,
                            runSpacing: 8.14.h,
                            textDirection: TextDirection.rtl,
                            alignment: WrapAlignment.start,
                            children: kPopularJobSearchChips.map((label) {
                              final chipRadius = 13.03.r;
                              final chipBg = const Color(0xFFC4CBD3)
                                  .withValues(alpha: 0.3);
                              return Material(
                                color: chipBg,
                                borderRadius:
                                    BorderRadius.circular(chipRadius),
                                clipBehavior: Clip.antiAlias,
                                child: InkWell(
                                  onTap: () {
                                    _controller.text = label;
                                    _submit(label);
                                  },
                                  borderRadius:
                                      BorderRadius.circular(chipRadius),
                                  child: SizedBox(
                                    height: 42.h,
                                    child: Padding(
                                      padding: EdgeInsets.fromLTRB(
                                        4.w,
                                        8.14.h,
                                        4.w,
                                        8.14.h,
                                      ),
                                      child: Align(
                                        alignment: Alignment.center,
                                        widthFactor: 1,
                                        heightFactor: 1,
                                        child: Text(
                                          label,
                                          textDirection: TextDirection.rtl,
                                          textAlign: TextAlign.start,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontFamily: 'Lama Sans',
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13.sp,
                                            height: 1.2,
                                            color: const Color(0xFF040814),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

enum _SearchMode { jobs, doctors }

class _ModeTab extends StatelessWidget {
  const _ModeTab({
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
