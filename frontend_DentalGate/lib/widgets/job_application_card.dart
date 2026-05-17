import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:dental_gate/models/my_job_application_item.dart';
import 'package:dental_gate/view/jobs/job_detail_view.dart';

/// ألوان شارات حالة الطلب (مطابقة للوحة).
abstract final class JobApplicationCardDesign {
  static const Color titleDark = Color(0xFF040814);
  static const Color subtitleGray = Color(0xFF6B7280);
  static const Color chevronGray = Color(0xFF9CA3AF);
  static const Color logoBg = Color(0xFFF3F4F6);
  static const Color logoOrange = Color(0xFFFF9F6A);
  static const Color cardBg = Color(0xFFF6F6F6);
  static const Color acceptedGreen = Color(0xFF0BDB0F);
  static const Color pendingOrange = Color(0xFFFF9914);
  static const Color rejectedRed = Color(0xFFED3737);
  static const Color statusText = Color(0xFFFDFEFF);
}

class JobApplicationTalabatCard extends StatelessWidget {
  const JobApplicationTalabatCard({
    super.key,
    required this.item,
  });

  final MyJobApplicationItem item;

  Color get _statusColor {
    switch (item.status) {
      case JobApplicationStatusApi.pending:
        return JobApplicationCardDesign.pendingOrange;
      case JobApplicationStatusApi.accepted:
        return JobApplicationCardDesign.acceptedGreen;
      case JobApplicationStatusApi.rejected:
        return JobApplicationCardDesign.rejectedRed;
    }
  }

  void _openDetail(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => JobDetailView(
          job: item.job,
          applicationStatus: item.status,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final job = item.job;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openDetail(context),
        borderRadius: BorderRadius.circular(20.r),
        child: Container(
          constraints: BoxConstraints(minHeight: 72.4603271484375.h),
          padding: EdgeInsets.fromLTRB(13.w, 14.h, 13.w, 14.h),
          decoration: BoxDecoration(
            color: JobApplicationCardDesign.cardBg,
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Row(
            textDirection: TextDirection.rtl,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _LogoCircle(),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      textDirection: TextDirection.rtl,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            job.requiredSpecialty,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Lama Sans',
                              fontWeight: FontWeight.w800,
                              fontSize: 15.sp,
                              height: 1.25,
                              color: JobApplicationCardDesign.titleDark,
                            ),
                          ),
                        ),
                        SizedBox(width: 4.w),
                        Transform.rotate(
                          angle: math.pi,
                          child: Icon(
                            Icons.chevron_left_rounded,
                            size: 22.sp,
                            color: JobApplicationCardDesign.chevronGray,
                          ),
                        ),
                      ],
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
                        color: JobApplicationCardDesign.subtitleGray,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 10.w),
              Container(
                width: 74.w,
                height: 40.h,
                padding: EdgeInsets.fromLTRB(9.w, 11.h, 9.w, 11.h),
                decoration: BoxDecoration(
                  color: _statusColor,
                  borderRadius: BorderRadius.circular(12.31.r),
                ),
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      item.statusLabel,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      style: TextStyle(
                        fontFamily: 'Lama Sans',
                        fontWeight: FontWeight.w900,
                        fontSize: 12.sp,
                        color: JobApplicationCardDesign.statusText,
                        height: 1.5,
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
}

class _LogoCircle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 50.w,
      height: 50.h,
      child: Image.asset(
        'assets/icons/talab icon.png',
        fit: BoxFit.contain,
      ),
    );
  }
}
