import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'package:dental_gate/controllers/bookmarks_controller.dart';
import 'package:dental_gate/controllers/professional_profile_controller.dart';
import 'package:dental_gate/models/doctor_search_item.dart';
import 'package:dental_gate/view/profile/professional_profile_view.dart';
import 'package:dental_gate/view/settings/settings_view.dart';
import 'package:dental_gate/view/talabat/talabat_view.dart';
import 'package:dental_gate/widgets/doctor_search_grid_card.dart';
import 'package:dental_gate/widgets/job_posting_card.dart';

class OrdersTabPage extends StatelessWidget {
  const OrdersTabPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const TalabatView();
  }
}

class BookmarksTabPage extends StatefulWidget {
  const BookmarksTabPage({super.key});

  @override
  State<BookmarksTabPage> createState() => _BookmarksTabPageState();
}

enum _BookmarksMode { jobs, doctors }

class _BookmarksTabPageState extends State<BookmarksTabPage> {
  _BookmarksMode _mode = _BookmarksMode.jobs;
  final TextEditingController _doctorSearch = TextEditingController();

  @override
  void dispose() {
    _doctorSearch.dispose();
    super.dispose();
  }

  Future<void> _openDoctorProfile(DoctorSearchItem doctor) async {
    final tag = 'saved_doctor_profile_${doctor.id}';
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
    if (mounted) {
      unawaited(Get.find<BookmarksController>().syncSavedDoctorsFromServer());
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookmarks = Get.find<BookmarksController>();
    return Scaffold(
      backgroundColor: const Color(0xFFFDFEFF),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 16.h),
            Center(
              child: Text(
                'المحفوظات',
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
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Container(
                height: 50.h,
                padding: EdgeInsets.all(4.r),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF3FA),
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _BookmarksModeTab(
                        label: 'الوظائف المحفوظة',
                        selected: _mode == _BookmarksMode.jobs,
                        onTap: () => setState(() => _mode = _BookmarksMode.jobs),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: _BookmarksModeTab(
                        label: 'الأطباء المحفوظين',
                        selected: _mode == _BookmarksMode.doctors,
                        onTap: () {
                          setState(() => _mode = _BookmarksMode.doctors);
                          unawaited(bookmarks.syncSavedDoctorsFromServer());
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16.h),
            Expanded(
              child: _mode == _BookmarksMode.doctors
                  ? Obx(() {
                      final q = _doctorSearch.text.trim().toLowerCase();
                      final all = bookmarks.savedDoctors;
                      final doctors = q.isEmpty
                          ? all
                          : all.where((d) {
                              return d.displayName.toLowerCase().contains(q) ||
                                  d.specialtyLabel.toLowerCase().contains(q) ||
                                  d.phone.toLowerCase().contains(q);
                            }).toList();
                      return Column(
                        children: [
                          Padding(
                            padding: EdgeInsets.fromLTRB(14.w, 0, 14.w, 10.h),
                            child: Container(
                              height: 44.h,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14.r),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x1A000000),
                                    blurRadius: 6,
                                    offset: Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: TextField(
                                controller: _doctorSearch,
                                textAlign: TextAlign.right,
                                textDirection: TextDirection.rtl,
                                onChanged: (_) => setState(() {}),
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  hintText: 'ابحث عن طبيب محفوظ ..',
                                  hintStyle: TextStyle(
                                    fontFamily: 'Lama Sans',
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13.sp,
                                    color: const Color(0xFF6B7280),
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12.w,
                                    vertical: 10.h,
                                  ),
                                  suffixIcon: const Icon(Icons.search_rounded),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: RefreshIndicator(
                              color: const Color(0xFF5B8EF7),
                              onRefresh: bookmarks.syncSavedDoctorsFromServer,
                              child: doctors.isEmpty
                                  ? ListView(
                                      physics:
                                          const AlwaysScrollableScrollPhysics(),
                                      children: [
                                        SizedBox(height: 80.h),
                                        Center(
                                          child: Padding(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 24.w,
                                            ),
                                            child: Text(
                                              all.isEmpty
                                                  ? 'لا يوجد أطباء محفوظين حالياً'
                                                  : 'لا يوجد نتائج مطابقة',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontFamily: 'Lama Sans',
                                                fontWeight: FontWeight.w600,
                                                fontSize: 15.sp,
                                                color: const Color(0xFF6B7280),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    )
                                  : DoctorSearchTwoColumnList(
                                      padding: EdgeInsets.fromLTRB(
                                        14.w,
                                        4.h,
                                        14.w,
                                        100.h,
                                      ),
                                      crossAxisSpacing: 12.w,
                                      mainAxisSpacing: 12.h,
                                      itemCount: doctors.length,
                                      itemBuilder: (context, index) {
                                        final d = doctors[index];
                                        return Obx(() {
                                          final saved =
                                              bookmarks.isDoctorSaved(d.id);
                                          return DoctorSearchGridCard(
                                            doctor: d,
                                            isSaved: saved,
                                            onViewProfile: () =>
                                                _openDoctorProfile(d),
                                            onToggleSaved: () =>
                                                bookmarks.toggleDoctor(d),
                                          );
                                        });
                                      },
                                    ),
                            ),
                          ),
                        ],
                      );
                    })
                  : Obx(() {
                      if (bookmarks.savedJobs.isEmpty) {
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
                                'لم تحفظ أي وظيفة بعد',
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
                                'ابدأ بأختيار وظيفة و حفظها',
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

                      return ListView.separated(
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 100.h),
                        itemCount: bookmarks.savedJobs.length,
                        separatorBuilder: (context, index) =>
                            SizedBox(height: 12.h),
                        itemBuilder: (context, index) =>
                            JobPostingCard(job: bookmarks.savedJobs[index]),
                      );
                    }),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookmarksModeTab extends StatelessWidget {
  const _BookmarksModeTab({
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

class SettingsTabPage extends StatelessWidget {
  const SettingsTabPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const SettingsView();
  }
}
