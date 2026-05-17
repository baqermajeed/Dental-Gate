import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class UnifiedSearchBar extends StatelessWidget {
  const UnifiedSearchBar({
    super.key,
    required this.hintText,
    this.controller,
    this.onFilterTap,
    this.actionIconAsset = 'assets/icons/filtter.png',
    this.actionIconWidth = 26,
    this.actionIconHeight = 29,
    this.actionButtonColor = const Color(0xFFFDFEFF),
    this.actionTooltip,
    this.readOnly = false,
    /// عند [readOnly]، الضغط على الشريط (مثل فتح شاشة البحث).
    this.onBarTap,
  });

  final String hintText;
  final TextEditingController? controller;
  final VoidCallback? onFilterTap;
  final String actionIconAsset;
  final double actionIconWidth;
  final double actionIconHeight;
  final Color actionButtonColor;
  final String? actionTooltip;
  final bool readOnly;
  final VoidCallback? onBarTap;

  @override
  Widget build(BuildContext context) {
    final actionButton = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onFilterTap,
        borderRadius: BorderRadius.circular(22.r),
        child: Container(
          width: 54.w,
          height: 54.h,
          decoration: BoxDecoration(
            color: actionButtonColor,
            borderRadius: BorderRadius.circular(22.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.16),
                blurRadius: 7.9,
                spreadRadius: 0,
                offset: Offset.zero,
              ),
            ],
          ),
          padding: const EdgeInsets.all(13.17),
          child: Image.asset(
            actionIconAsset,
            width: actionIconWidth.w,
            height: actionIconHeight.h,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
    Widget bar = Container(
      width: 353.w,
      height: 54.h,
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(44.r),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x29040814),
            blurRadius: 6,
            spreadRadius: 0,
            offset: Offset(0, 0),
          ),
        ],
      ),
      padding: EdgeInsets.only(right: 16.w),
      alignment: Alignment.center,
      child: Row(
        textDirection: TextDirection.ltr,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (actionTooltip == null) actionButton else Tooltip(message: actionTooltip!, child: actionButton),
          SizedBox(width: 13.17.w),
          Expanded(
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Builder(
                builder: (context) {
                  final field = Row(
                    children: [
                      Image.asset(
                        'assets/icons/search.png',
                        width: 22.w,
                        height: 22.w,
                        fit: BoxFit.contain,
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: readOnly && onBarTap != null
                            ? Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  hintText,
                                  textAlign: TextAlign.right,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: 'Lama Sans',
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14.sp,
                                    color: const Color(0xFF6B7280),
                                    height: 1.5,
                                  ),
                                ),
                              )
                            : TextField(
                            controller: controller,
                            readOnly: readOnly,
                            textAlign: TextAlign.right,
                            textDirection: TextDirection.rtl,
                            style: TextStyle(
                              fontFamily: 'Lama Sans',
                              fontWeight: FontWeight.w500,
                              fontSize: 14.sp,
                              color: const Color(0xFF040814),
                              height: 1.2,
                            ),
                            decoration: InputDecoration(
                              isDense: true,
                              hintText: hintText,
                              hintStyle: TextStyle(
                                fontFamily: 'Lama Sans',
                                fontWeight: FontWeight.w700,
                                fontSize: 14.sp,
                                color: const Color(0xFF6B7280),
                                height: 1.5,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                      ),
                    ],
                  );
                  if (readOnly && onBarTap != null) {
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: onBarTap,
                      child: field,
                    );
                  }
                  return field;
                },
              ),
            ),
          ),
        ],
      ),
    );
    return bar;
  }
}
