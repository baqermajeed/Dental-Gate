import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'package:dental_gate/controllers/bookmarks_controller.dart';
import 'package:dental_gate/models/job_posting.dart';
import 'package:dental_gate/utils/relative_time_ar.dart';
import 'package:dental_gate/view/jobs/job_detail_view.dart';

/// ثوابت تصميم بطاقة الوظيفة (مطابقة للوحة Figma).
abstract final class JobListingDesign {
  static const Color primaryBlue = Color(0xFF4A89FF);
  static const Color titleDark = Color(0xFF040814);
  static const Color mutedGray = Color(0xFF757575);
  static const Color timeGray = Color(0xFF9E9E9E);
  static const Color tagBg = Color(0xFFF2F2F2);
  static const Color logoOrange = Color(0xFFFF9F6A);
  static const Color logoBorder = Color(0xFFE8E8E8);
  static const Color saveButtonBg = Color(0xFFEAF2FF);
}

class JobListingTagChip extends StatelessWidget {
  const JobListingTagChip({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: JobListingDesign.tagBg,
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Lama Sans',
          fontWeight: FontWeight.w700,
          fontSize: 12.sp,
          height: 1.2,
          color: JobListingDesign.titleDark,
        ),
      ),
    );
  }
}

class JobListingLogoAvatar extends StatelessWidget {
  const JobListingLogoAvatar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40.w,
      height: 40.h,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Color(0x1F000000),
            offset: Offset(0, 0),
            blurRadius: 6,
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/icons/Frame 427321672.png',
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

/// بطاقة وظيفة في الرئيسية — تخطيط RTL.
class JobPostingCard extends StatefulWidget {
  const JobPostingCard({
    super.key,
    required this.job,
    this.compactLatestStyle = false,
    this.outlinedBookmarkStyle = false,
  });

  final JobPosting job;
  final bool compactLatestStyle;

  /// زر الحفظ أبيض بحدود زرقاء (تصميم صفحة نتائج البحث).
  final bool outlinedBookmarkStyle;

  @override
  State<JobPostingCard> createState() => _JobPostingCardState();
}

class _JobPostingCardState extends State<JobPostingCard> {
  final BookmarksController _bookmarks = Get.find<BookmarksController>();

  @override
  Widget build(BuildContext context) {
    final job = widget.job;
    return Container(
      margin: EdgeInsets.only(bottom: widget.compactLatestStyle ? 0 : 14.h),
      width: 353.w,
      decoration: BoxDecoration(
        color: const Color(0xFFFDFEFF),
        borderRadius: BorderRadius.circular(22.r),
        boxShadow: const [
          BoxShadow(
            color: Color(0x29040814),
            blurRadius: 6,
            spreadRadius: 0,
            offset: Offset(0, 0),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(16.w, 17.h, 16.w, 12.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            textDirection: TextDirection.rtl,
            children: [
              Expanded(
                child: Row(
                  textDirection: TextDirection.rtl,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const JobListingLogoAvatar(),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            job.requiredSpecialty,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Lama Sans',
                              fontWeight: FontWeight.w800,
                              fontSize: 17.sp,
                              height: 1.25,
                              color: JobListingDesign.titleDark,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            job.locationSubtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Lama Sans',
                              fontWeight: FontWeight.w500,
                              fontSize: 13.sp,
                              height: 1.35,
                              color: JobListingDesign.mutedGray,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              Text(
                relativeTimeAr(job.createdAt),
                style: TextStyle(
                  fontFamily: 'Lama Sans',
                  fontWeight: FontWeight.w500,
                  fontSize: 11.sp,
                  color: JobListingDesign.timeGray,
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            textDirection: TextDirection.rtl,
            children: [
              Expanded(
                child: _CompactMetaChip(label: '${job.yearsExperience} سنوات خبرة'),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _CompactMetaChip(label: job.salaryChipText),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _CompactMetaChip(label: job.hoursChipText),
              ),
            ],
          ),
          if (!widget.compactLatestStyle) ...[
            SizedBox(height: 12.h),
            Text(
              job.descriptionPreview(maxChars: 160),
              textAlign: TextAlign.justify,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Lama Sans',
                fontWeight: FontWeight.w700,
                fontSize: 12.sp,
                height: 1.8,
                color: const Color(0xFF040814),
              ),
            ),
            SizedBox(height: 16.h),
          ] else
            SizedBox(height: 14.h),
          Row(
            textDirection: TextDirection.rtl,
            children: [
              Expanded(
                child: Center(
                  child: SizedBox(
                    width: (widget.compactLatestStyle ? 319.w : 270.w),
                    height: 44.h,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => JobDetailView(job: job),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: const Color(0xFF5993FF),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: Text(
                        'عرض التفاصيل',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Lama Sans',
                          fontWeight: FontWeight.w900,
                          fontSize: 16.sp,
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
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(12.r),
                child: Obx(
                  () => InkWell(
                    onTap: () => _bookmarks.toggle(job),
                    borderRadius: BorderRadius.circular(12.r),
                    child: Container(
                      width: 48.w,
                      height: 48.w,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: widget.outlinedBookmarkStyle
                            ? Colors.white
                            : JobListingDesign.saveButtonBg,
                        borderRadius: BorderRadius.circular(12.r),
                        border: widget.outlinedBookmarkStyle
                            ? Border.all(
                                color: JobListingDesign.primaryBlue,
                                width: 1.5,
                              )
                            : null,
                      ),
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
          SizedBox(height: 12.h),
        ],
      ),
    );
  }
}

class _CompactMetaChip extends StatelessWidget {
  const _CompactMetaChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 37.h,
      padding: EdgeInsets.symmetric(horizontal: 10.w),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0x4DD9D9D9),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontFamily: 'Lama Sans',
          fontWeight: FontWeight.w800,
          fontSize: 12.sp,
          height: 1.8,
          color: JobListingDesign.titleDark,
        ),
      ),
    );
  }
}
