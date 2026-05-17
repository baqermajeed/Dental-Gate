import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:dental_gate/models/job_posting.dart';
import 'package:dental_gate/utils/iqd_format.dart';
import 'package:dental_gate/utils/relative_time_ar.dart';
import 'package:dental_gate/view/jobs/job_detail_view.dart';
import 'package:dental_gate/widgets/job_posting_card.dart';

/// تصميم بطاقة «وظائفي المنشورة» (RTL) — ألوان قريبة من لوحة التصميم.
abstract final class PostedJobsDesign {
  static const Color primaryBlue = Color(0xFF3B82F6);
  static const Color pageBg = Color(0xFFF3F4F6);
  static const Color titleDark = Color(0xFF000000);
  static const Color metaGray = Color(0xFF6B7280);
  static const Color endedBlue = Color(0xFF3B82F6);
  static const Color closedRed = Color(0xFFDC2626);
  static const Color archivedGray = Color(0xFF9CA3AF);
  static const Color footerBorder = Color(0xFFE5E7EB);
}

class PostedJobOwnerCard extends StatelessWidget {
  const PostedJobOwnerCard({
    super.key,
    required this.job,
    this.applicantCount = 0,
  });

  final JobPosting job;
  final int applicantCount;

  @override
  Widget build(BuildContext context) {
    final status = _PostedJobStatusLine.resolve(job);
    final salary = job.monthlySalaryIqd;
    final salaryLine = salary == null
        ? '• غير محدد'
        : '• ${formatIqdWithCommas(salary)} د.ع شهرياً';

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20.r),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => JobDetailView(job: job)),
          );
        },
        borderRadius: BorderRadius.circular(20.r),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: const Color(0xFFE8E8E8), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: EdgeInsets.fromLTRB(14.w, 14.h, 14.w, 12.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                textDirection: TextDirection.rtl,
                children: [
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      textDirection: TextDirection.rtl,
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
                                  fontSize: 16.sp,
                                  height: 1.25,
                                  color: PostedJobsDesign.titleDark,
                                ),
                              ),
                              SizedBox(height: 6.h),
                              Text(
                                '• ${job.yearsExperience} سنوات خبرة',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: 'Lama Sans',
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13.sp,
                                  height: 1.35,
                                  color: PostedJobsDesign.metaGray,
                                ),
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                salaryLine,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: 'Lama Sans',
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13.sp,
                                  height: 1.35,
                                  color: PostedJobsDesign.metaGray,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 8.w),
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 110.w),
                    child: Text(
                      status.text,
                      textAlign: TextAlign.left,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Lama Sans',
                        fontWeight: status.bold
                            ? FontWeight.w800
                            : FontWeight.w600,
                        fontSize: 12.sp,
                        height: 1.25,
                        color: status.color,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 10.h),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: PostedJobsDesign.footerBorder,
                    width: 1,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  applicantCount == 0 ? '0 متقدم' : '+$applicantCount متقدم',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Lama Sans',
                    fontWeight: FontWeight.w700,
                    fontSize: 14.sp,
                    height: 1.3,
                    color: PostedJobsDesign.metaGray,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PostedJobStatusLine {
  _PostedJobStatusLine._(this.text, this.color, this.bold);

  final String text;
  final Color color;
  final bool bold;

  static _PostedJobStatusLine resolve(JobPosting job) {
    final now = DateTime.now();
    final deadline = job.applicationDeadline?.toLocal();
    if (deadline != null && now.isAfter(deadline)) {
      return _PostedJobStatusLine._(
        'أنتهت المدة',
        PostedJobsDesign.endedBlue,
        false,
      );
    }
    return _PostedJobStatusLine._(
      relativeTimeAr(job.createdAt),
      PostedJobsDesign.metaGray,
      false,
    );
  }
}
