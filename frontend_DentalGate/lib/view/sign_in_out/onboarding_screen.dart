import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import 'package:dental_gate/core/app_routes.dart';
import 'package:dental_gate/widgets/blue_circle_arrow_button.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  static const Color _bg = Color(0xFFF3F4F6);
  static const Color _blue = Color(0xFF5B8DEF);
  static const Color _blueLight = Color(0xFFBFD3FF);

  static const List<_SlideData> _slides = [
    _SlideData(
      imagePath: 'assets/icons/page 1.png',
      title: 'وظيفتك أقرب مما تتخيل',
      description:
          'أكتشف فرص عمل مناسبة\nلتخصصك و خبرتك في مكان\nواحد، بدون تشتت أو بحث طويل .',
    ),
    _SlideData(
      imagePath: 'assets/icons/page 2.png',
      title: 'أنشئ هويتك المهنية',
      description: 'أعــرض خبراتك و شـهـاداتك فـي ملف أحترافي يساعدك على جذب أفــضــل الـفـــرص بـسـهــولـة .',
    ),
    _SlideData(
      imagePath: 'assets/icons/Frame 427321685.png',
      title: 'قدّم بضغطة واحدة',
      description: 'بياناتك جـاهـزة دائـمًا ، قـدّم على الوظائف بسرعة و تابع حالة طلبك لحـظــة بلـحـظــة .',
    ),
  ];

  void _finish() {
    Get.offNamed(Routes.signIn);
  }

  void _goNext() {
    if (_currentIndex == _slides.length - 1) {
      _finish();
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goBack() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            children: [
              SizedBox(height: 8.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 18.w),
                child: Row(
                  children: [
                    TextButton(
                      onPressed: _finish,
                      child: Text(
                        'تخطي',
                        style: TextStyle(
                          fontFamily: 'expoArabic',
                          color: Colors.black.withValues(alpha: 0.7),
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _slides.length,
                  onPageChanged: (index) => setState(() => _currentIndex = index),
                  itemBuilder: (context, index) {
                    final slide = _slides[index];
                    return _OnboardingSlide(
                      index: index,
                      imagePath: slide.imagePath,
                      title: slide.title,
                      description: slide.description,
                    );
                  },
                ),
              ),
              SizedBox(height: 6.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 50.w),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (_currentIndex > 0)
                      BlueCircleArrowButton(
                        onTap: _goBack,
                        backgroundColor: _bg,
                        borderColor: _blue,
                        borderWidth: 1,
                        arrowColor: _blue,
                        arrowPointsLeft: false,
                      )
                    else
                      const SizedBox(width: 50),
                    Expanded(
                      child: Center(
                        child: Directionality(
                          textDirection: TextDirection.ltr,
                          child: SmoothPageIndicator(
                            controller: _pageController,
                            count: _slides.length,
                            effect: WormEffect(
                              dotHeight: 8.h,
                              dotWidth: 8.w,
                              spacing: 7.w,
                              activeDotColor: _blue,
                              dotColor: _blueLight,
                            ),
                          ),
                        ),
                      ),
                    ),
                    BlueCircleArrowButton(
                      onTap: _goNext,
                      color: _blue,
                      arrowPointsLeft: true,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 4.h),
            ],
          ),
        ),
      ),
    );
  }
}

class _SlideData {
  final String imagePath;
  final String title;
  final String description;

  const _SlideData({
    required this.imagePath,
    required this.title,
    required this.description,
  });
}

class _OnboardingSlide extends StatelessWidget {
  final int index;
  final String imagePath;
  final String title;
  final String description;

  const _OnboardingSlide({
    required this.index,
    required this.imagePath,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 18.w),
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          children: [
            SizedBox(height: 100.h),
            Image.asset(
              imagePath,
              width: 284.w,
              height: 284.h,
              fit: BoxFit.contain,
            ),
            SizedBox(height: 40.h),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Lama Sans',
                fontSize: 26.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0E1525),
                height: 1.5,
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Lama Sans',
                fontSize: 20.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF333640),
                height: 1.5,
              ),
            ),
            SizedBox(height: 4.h),
          ],
        ),
      ),
    );
  }
}
