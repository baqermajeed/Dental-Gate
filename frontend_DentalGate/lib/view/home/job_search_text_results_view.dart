import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'package:dental_gate/controllers/home_controller.dart';
import 'package:dental_gate/core/app_routes.dart';
import 'package:dental_gate/models/job_search_filter_criteria.dart';
import 'package:dental_gate/services/job_search_history_service.dart';
import 'package:dental_gate/widgets/job_posting_card.dart';
import 'package:dental_gate/widgets/job_search_app_bar_row.dart';
import 'package:dental_gate/widgets/job_search_filter_sheet.dart';

class JobSearchTextResultsView extends StatefulWidget {
  const JobSearchTextResultsView({super.key, required this.initialQuery});

  final String initialQuery;

  @override
  State<JobSearchTextResultsView> createState() => _JobSearchTextResultsViewState();
}

class _JobSearchTextResultsViewState extends State<JobSearchTextResultsView> {
  static const _bg = Color(0xFFF5F6F8);

  final HomeController _home = Get.find<HomeController>();
  late final TextEditingController _controller;
  late final FocusNode _focus;
  bool _openingResults = false;
  late String _activeQuery;

  @override
  void initState() {
    super.initState();
    _activeQuery = widget.initialQuery.trim();
    _controller = TextEditingController(text: _activeQuery);
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
    if (q.isEmpty || _openingResults) return;
    _openingResults = true;
    unawaited(JobSearchHistoryService.addQuery(q));
    setState(() => _activeQuery = q);
    _openingResults = false;
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
              SizedBox(height: 14.h),
              JobSearchAppBarRow(
                controller: _controller,
                focusNode: _focus,
                cancelTextColor: const Color(0xFF040814),
                onCancel: () => Get.back(),
                onFilterTap: _showFilterSheet,
                onSubmitted: _submit,
              ),
              Expanded(
                child: Obx(() {
                  final jobs = _home.jobsMatchingQuery(_activeQuery);
                  if (jobs.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24.w),
                        child: Text(
                          'لا نتائج للبحث «$_activeQuery»',
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
                    padding: EdgeInsets.fromLTRB(14.w, 16.h, 14.w, 24.h),
                    physics: const BouncingScrollPhysics(),
                    itemCount: jobs.length,
                    separatorBuilder: (_, _) => SizedBox(height: 14.h),
                    itemBuilder: (context, index) {
                      return JobPostingCard(
                        job: jobs[index],
                        outlinedBookmarkStyle: true,
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
