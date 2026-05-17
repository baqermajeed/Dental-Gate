import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// صف «إلغاء + شريط بحث + زر فلترة» كما في شاشة البحث والنتائج.
class JobSearchAppBarRow extends StatelessWidget {
  const JobSearchAppBarRow({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onCancel,
    required this.onFilterTap,
    this.onSubmitted,
    this.readOnly = false,
    this.showFilterActiveDot = false,
    this.cancelTextColor,
    this.hintText = 'أبحث عن وظيفة ..',
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onCancel;
  final VoidCallback onFilterTap;
  final ValueChanged<String>? onSubmitted;
  final bool readOnly;

  /// نقطة حمراء فوق زر الفلترة (تصميم نتائج البحث عند وجود تصفية).
  final bool showFilterActiveDot;

  /// لون نص «إلغاء»؛ الافتراضي أسود.
  final Color? cancelTextColor;
  final String hintText;

  static const _filterBlue = Color(0xFF5993FF);

  @override
  Widget build(BuildContext context) {
    final searchBarH = 54.h;
    final searchBarMaxW = 286.25.w;
    final searchBarShadow = <BoxShadow>[
      const BoxShadow(
        color: Color(0x29040814),
        blurRadius: 6,
        spreadRadius: 0,
        offset: Offset.zero,
      ),
    ];
    final searchBarCapsuleR = searchBarH / 2;
    final filterW = 43.79.w;
    final filterRadius = 27.r;
    final filterShadow = const <BoxShadow>[
      BoxShadow(
        color: Color(0x29000000),
        blurRadius: 7.9,
        spreadRadius: 0,
        offset: Offset.zero,
      ),
    ];
    final filterShadowBleed = 12.w;
    final searchBarPaddingWithFilter = EdgeInsets.fromLTRB(
      filterW,
      17.h,
      16.w,
      17.h,
    );

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 14.w),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            TextButton(
              onPressed: onCancel,
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 8.w),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'إلغاء',
                style: TextStyle(
                  fontFamily: 'Lama Sans',
                  fontWeight: FontWeight.w700,
                  fontSize: 15.sp,
                  color: cancelTextColor ?? Colors.black,
                ),
              ),
            ),
            SizedBox(width: 6.w),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final barW = math.min(
                    math.max(0.0, constraints.maxWidth),
                    searchBarMaxW,
                  );
                  return SizedBox(
                    width: barW,
                    height: searchBarH,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFFFFF),
                              borderRadius: BorderRadius.circular(searchBarCapsuleR),
                              boxShadow: searchBarShadow,
                            ),
                            child: ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(searchBarCapsuleR),
                              clipBehavior: Clip.antiAlias,
                              child: Padding(
                                padding: searchBarPaddingWithFilter,
                                child: Directionality(
                                  textDirection: TextDirection.rtl,
                                  child: Row(
                                    children: [
                                      Image.asset(
                                        'assets/icons/search.png',
                                        width: 22.w,
                                        height: 22.w,
                                        fit: BoxFit.contain,
                                      ),
                                      SizedBox(width: 10.w),
                                      Expanded(
                                        child: TextField(
                                          controller: controller,
                                          focusNode: focusNode,
                                          readOnly: readOnly,
                                          textAlign: TextAlign.right,
                                          textDirection: TextDirection.rtl,
                                          textInputAction: TextInputAction.search,
                                          onSubmitted: onSubmitted,
                                          style: TextStyle(
                                            fontFamily: 'Lama Sans',
                                            fontWeight: FontWeight.w500,
                                            fontSize: 14.sp,
                                            color: const Color(0xFF040814),
                                          ),
                                          decoration: InputDecoration(
                                            isDense: true,
                                            hintText: hintText,
                                            hintStyle: TextStyle(
                                              fontFamily: 'Lama Sans',
                                              fontWeight: FontWeight.w700,
                                              fontSize: 14.sp,
                                              color: const Color(0xFF6B7280),
                                            ),
                                            border: InputBorder.none,
                                            contentPadding: EdgeInsets.zero,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: -filterShadowBleed,
                          top: -filterShadowBleed,
                          child: SizedBox(
                            width: filterW + 2 * filterShadowBleed,
                            height: searchBarH + 2 * filterShadowBleed,
                            child: Center(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: _filterBlue,
                                  borderRadius:
                                      BorderRadius.circular(filterRadius),
                                  boxShadow: filterShadow,
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  type: MaterialType.transparency,
                                  clipBehavior: Clip.none,
                                  child: InkWell(
                                    onTap: onFilterTap,
                                    borderRadius:
                                        BorderRadius.circular(filterRadius),
                                    splashColor:
                                        Colors.white.withValues(alpha: 0.2),
                                    highlightColor:
                                        Colors.white.withValues(alpha: 0.08),
                                    child: SizedBox(
                                      width: filterW,
                                      height: searchBarH,
                                      child: Stack(
                                        clipBehavior: Clip.none,
                                        alignment: Alignment.center,
                                        children: [
                                          Center(
                                            child: Image.asset(
                                              'assets/icons/فلترة بحث.png',
                                              width: 25.w,
                                              height: 25.w,
                                              fit: BoxFit.contain,
                                            ),
                                          ),
                                          if (showFilterActiveDot)
                                            Positioned(
                                              top: 5.h,
                                              right: 2.w,
                                              child: Container(
                                                width: 9.w,
                                                height: 9.w,
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFE53935),
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color: Colors.white,
                                                    width: 1.5,
                                                  ),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
