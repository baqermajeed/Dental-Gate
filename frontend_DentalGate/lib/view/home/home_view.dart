import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'package:dental_gate/core/app_routes.dart';
import 'package:dental_gate/core/media_url.dart';
import 'package:dental_gate/controllers/home_controller.dart';
import 'package:dental_gate/models/job_posting.dart';
import 'package:dental_gate/controllers/notifications_controller.dart';
import 'package:dental_gate/view/jobs/job_detail_view.dart';
import 'package:dental_gate/view/home/latest_jobs_view.dart';
import 'package:dental_gate/view/notifications/notifications_view.dart';
import 'package:dental_gate/widgets/job_posting_card.dart';
import 'package:dental_gate/widgets/unified_search_bar.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFFDFEFF),
        body: SafeArea(
          child: Obx(() {
            if (controller.isJobsLoading.value && controller.jobs.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            final profileImageUrl =
                resolveMediaUrl(controller.profile.value?.imageUrl);
            final profileSpecialty = controller.profileSpecialty.value?.trim();
            final filteredJobs = controller.jobs.toList();
            final latestJobs = List<JobPosting>.from(filteredJobs)
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

            return RefreshIndicator(
              color: JobListingDesign.primaryBlue,
              onRefresh: controller.refreshAll,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 0),
                      child: Row(
                        textDirection: TextDirection.rtl,
                        children: [
                          SizedBox(width: 10.w),
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => Get.toNamed(Routes.professionalProfile),
                              customBorder: const CircleBorder(),
                              child: Container(
                                width: 41.w,
                                height: 41.h,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x29000000),
                                      offset: Offset(0, 0),
                                      blurRadius: 6,
                                      spreadRadius: 0,
                                    ),
                                  ],
                                  image: profileImageUrl.isNotEmpty
                                      ? DecorationImage(
                                          image: NetworkImage(profileImageUrl),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                  color: Colors.white,
                                ),
                                child: profileImageUrl.isEmpty
                                    ? Icon(
                                        Icons.person_rounded,
                                        size: 22.sp,
                                        color: const Color(0xFF9CA3AF),
                                      )
                                    : null,
                              ),
                            ),
                          ),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: Directionality(
                              textDirection: TextDirection.rtl,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    controller.profile.value?.name ?? 'مرحبًا',
                                    textAlign: TextAlign.right,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontFamily: 'Lama Sans',
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16.sp,
                                      height: 1.5,
                                      color: const Color(0xFF040814),
                                    ),
                                  ),
                                  if (profileSpecialty != null &&
                                      profileSpecialty.isNotEmpty)
                                    Text(
                                      profileSpecialty,
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
                                ],
                              ),
                            ),
                          ),
                          SizedBox(width: 10.w),
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                final id = controller.profile.value?.id;
                                if (id == null || id.isEmpty) {
                                  Get.snackbar(
                                    'تنبيه',
                                    'سجّل الدخول لعرض الإشعارات',
                                    snackPosition: SnackPosition.BOTTOM,
                                  );
                                  return;
                                }
                                Get.to(
                                  () => const NotificationsView(),
                                  binding: BindingsBuilder(() {
                                    Get.put(
                                      NotificationsController(userId: id),
                                    );
                                  }),
                                );
                              },
                              customBorder: const CircleBorder(),
                              child: Container(
                                width: 54.w,
                                height: 54.h,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFDFEFF),
                                  borderRadius: BorderRadius.circular(27.r),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.16,
                                      ),
                                      blurRadius: 7.9,
                                      spreadRadius: 0,
                                      offset: Offset.zero,
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: EdgeInsets.all(13.17.r),
                                  child: Center(
                                    child: Image.asset(
                                      'assets/icons/ايقونة الاشعارات.png',
                                      width: 26.w,
                                      height: 26.h,
                                      fit: BoxFit.contain,
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
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 0),
                      child: UnifiedSearchBar(
                        hintText: 'أبحث عن وظيفة ..',
                        readOnly: true,
                        onBarTap: () async {
                          // لا تستخدم Get.toNamed<String?> — يُسبب cast خاطئ لـ Route<String?> مع GetPageRoute<dynamic>.
                          await Get.toNamed(Routes.jobSearch);
                        },
                        onFilterTap: () async {
                          await Get.toNamed(
                            Routes.jobSearch,
                            arguments: {'openFilter': true},
                          );
                        },
                      ),
                    ),
                  ),
                  if (controller.sliders.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(14.w, 10.h, 14.w, 0),
                        child: SizedBox(
                          height: 148.h,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20.r),
                            child: PageView.builder(
                              itemCount: controller.sliders.length,
                              onPageChanged: controller.setSliderIndex,
                              itemBuilder: (context, index) {
                                final item = controller.sliders[index];
                                return Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () async {
                                      final job = await controller.resolveSliderJob(
                                        item.jobId,
                                      );
                                      if (job == null || !context.mounted) return;
                                      Navigator.of(context).push(
                                        MaterialPageRoute<void>(
                                          builder: (_) => JobDetailView(job: job),
                                        ),
                                      );
                                    },
                                    child: Image.network(
                                      resolveMediaUrl(item.imageUrl),
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        color: const Color(0xFFEAF2FF),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Builder(
                        builder: (_) {
                          final count = controller.sliders.length;
                          final active = controller.sliderIndex.value.clamp(
                            0,
                            count - 1,
                          );
                          return Padding(
                            padding: EdgeInsets.only(top: 8.h),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                count,
                                (i) => Container(
                                  width: 8.w,
                                  height: 8.w,
                                  margin: EdgeInsets.symmetric(horizontal: 3.w),
                                  decoration: BoxDecoration(
                                    color: i == active
                                        ? const Color(0xFF5B8EF7)
                                        : const Color(0xFFCAD5E8),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(14.w, 10.h, 14.w, 16.h),
                      child: Row(
                        children: [
                          Text(
                            'أحدث الوظائف',
                            style: TextStyle(
                              fontFamily: 'Lama Sans',
                              fontWeight: FontWeight.w900,
                              fontSize: 16.sp,
                              height: 1.5,
                              color: const Color(0xFF040814),
                            ),
                          ),
                          const Spacer(),
                          InkWell(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => LatestJobsView(jobs: latestJobs),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(10.r),
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 4.w,
                                vertical: 2.h,
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    'عرض الكل',
                                    style: TextStyle(
                                      fontFamily: 'Lama Sans',
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12.sp,
                                      height: 1.5,
                                      color: const Color(0xFF040814),
                                    ),
                                  ),
                                  SizedBox(width: 6.w),
                                  Transform.rotate(
                                    angle: 3.141592653589793,
                                    child: Icon(
                                      Icons.chevron_left_rounded,
                                      size: 18.sp,
                                      color: const Color(0xFF040814),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 214.h,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(14.w, 6.h, 14.w, 8.h),
                        itemCount: latestJobs.length > 3
                            ? 3
                            : latestJobs.length,
                        separatorBuilder: (_, __) => SizedBox(width: 12.w),
                        itemBuilder: (context, index) => SizedBox(
                          width: 320.w,
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: JobPostingCard(
                              job: latestJobs[index],
                              compactLatestStyle: true,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (controller.jobsError.value != null)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        child: Text(
                          controller.jobsError.value!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Lama Sans',
                            fontSize: 14.sp,
                            color: Colors.red.shade700,
                          ),
                        ),
                      ),
                    ),
                  if (!controller.isProfileLoading.value &&
                      controller.profile.value == null &&
                      controller.profileError.value != null)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 8.h),
                        child: Text(
                          'وضع الضيف — ${controller.profileError.value}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Lama Sans',
                            fontSize: 12.sp,
                            color: JobListingDesign.mutedGray,
                          ),
                        ),
                      ),
                    ),
                  if (controller.jobs.isEmpty &&
                      !controller.isJobsLoading.value &&
                      controller.jobsError.value == null)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Text(
                          'لا توجد وظائف منشورة حالياً',
                          style: TextStyle(
                            fontFamily: 'Lama Sans',
                            fontWeight: FontWeight.w600,
                            fontSize: 15.sp,
                            color: JobListingDesign.mutedGray,
                          ),
                        ),
                      ),
                    )
                  else
                    ...[
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(14.w, 14.h, 14.w, 16.h),
                          child: Text(
                            'جميع الوظائف',
                            style: TextStyle(
                              fontFamily: 'Lama Sans',
                              fontWeight: FontWeight.w900,
                              fontSize: 16.sp,
                              height: 1.5,
                              color: const Color(0xFF040814),
                            ),
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(14.w, 0, 14.w, 100.h),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final job = filteredJobs[index];
                              return JobPostingCard(job: job);
                            },
                            childCount: filteredJobs.length,
                          ),
                        ),
                      ),
                    ],
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}
