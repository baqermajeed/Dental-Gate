import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:dental_gate/models/job_posting.dart';
import 'package:dental_gate/widgets/app_back_button.dart';
import 'package:dental_gate/widgets/job_posting_card.dart';

class LatestJobsView extends StatelessWidget {
  const LatestJobsView({super.key, required this.jobs});

  final List<JobPosting> jobs;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFFDFEFF),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 16.h),
              SizedBox(
                height: 40.h,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Center(
                      child: Text(
                        'أحدث الوظائف',
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
                    Positioned(
                      left: 8.w,
                      child: AppBackButton(
                        size: 40.w,
                        iconSize: 24.sp,
                        iconColor: const Color(0xFF040814),
                        onTap: () => Navigator.of(context).maybePop(),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16.h),
              Expanded(
                child: ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 100.h),
                  itemCount: jobs.length,
                  separatorBuilder: (_, index) => SizedBox(height: 12.h),
                  itemBuilder: (context, index) => JobPostingCard(job: jobs[index]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
