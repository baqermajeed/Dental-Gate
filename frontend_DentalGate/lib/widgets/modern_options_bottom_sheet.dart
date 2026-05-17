import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// ألوان وتنسيق مطابق لشيت الخيارات في إنشاء الحساب.
abstract final class _ModernSheetTokens {
  static const Color primary = Color(0xFF5993FF);
  static const Color primarySoft = Color(0xFF7FB2E4);
  static const Color textDark = Color(0xFF0E1525);
  static const Color textBody = Color(0xFF333640);
  static const Color hint = Color(0xFFADADAD);
  static const Color surfaceElevated = Color(0xFFFDFEFF);
}

/// شيت قيعان لاختيار عنصر من قائمة (محافظة، تخصص، …) بنفس تصميم التسجيل.
class ModernOptionsBottomSheet extends StatelessWidget {
  const ModernOptionsBottomSheet({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.options,
    required this.selected,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<String> options;
  final String? selected;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: EdgeInsets.only(top: 12.h),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            width: double.infinity,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.86,
            ),
            decoration: BoxDecoration(
              color: _ModernSheetTokens.surfaceElevated,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
              boxShadow: [
                BoxShadow(
                  color: _ModernSheetTokens.primary.withValues(alpha: 0.18),
                  blurRadius: 40,
                  offset: const Offset(0, -8),
                ),
                const BoxShadow(
                  color: Color(0x14040814),
                  blurRadius: 24,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 16.h + bottom),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 44.w,
                    height: 5.h,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD1D5DB),
                      borderRadius: BorderRadius.circular(100.r),
                    ),
                  ),
                  SizedBox(height: 18.h),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.fromLTRB(18.w, 16.h, 18.w, 16.h),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20.r),
                      gradient: LinearGradient(
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                        colors: [
                          _ModernSheetTokens.primary.withValues(alpha: 0.14),
                          _ModernSheetTokens.primarySoft.withValues(alpha: 0.08),
                          _ModernSheetTokens.surfaceElevated,
                        ],
                      ),
                      border: Border.all(
                        color: _ModernSheetTokens.primary.withValues(alpha: 0.12),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48.w,
                          height: 48.w,
                          decoration: BoxDecoration(
                            color: _ModernSheetTokens.primary.withValues(
                              alpha: 0.12,
                            ),
                            borderRadius: BorderRadius.circular(14.r),
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            icon,
                            color: _ModernSheetTokens.primary,
                            size: 26.sp,
                          ),
                        ),
                        SizedBox(width: 14.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: TextStyle(
                                  fontFamily: 'Lama Sans',
                                  fontWeight: FontWeight.w800,
                                  fontSize: 20.sp,
                                  height: 1.2,
                                  color: _ModernSheetTokens.textDark,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                subtitle,
                                style: TextStyle(
                                  fontFamily: 'Lama Sans',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13.sp,
                                  height: 1.4,
                                  color: _ModernSheetTokens.textBody.withValues(
                                    alpha: 0.88,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 14.h),
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: options.length,
                      separatorBuilder: (_, index) => SizedBox(height: 8.h),
                      itemBuilder: (context, index) {
                        final option = options[index];
                        final active = option == selected;
                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14.r),
                            onTap: () => Navigator.of(context).pop(option),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 14.w,
                                vertical: 12.h,
                              ),
                              decoration: BoxDecoration(
                                color: active
                                    ? _ModernSheetTokens.primary.withValues(
                                        alpha: 0.12,
                                      )
                                    : const Color(0xFFF5F7FA),
                                borderRadius: BorderRadius.circular(14.r),
                                border: Border.all(
                                  color: active
                                      ? _ModernSheetTokens.primary.withValues(
                                          alpha: 0.45,
                                        )
                                      : const Color(0xFFE8ECF2),
                                ),
                              ),
                              child: Row(
                                children: [
                                  if (active)
                                    Icon(
                                      Icons.check_circle_rounded,
                                      color: _ModernSheetTokens.primary,
                                      size: 20.sp,
                                    )
                                  else
                                    Icon(
                                      Icons.radio_button_unchecked_rounded,
                                      color: _ModernSheetTokens.hint,
                                      size: 20.sp,
                                    ),
                                  SizedBox(width: 10.w),
                                  Expanded(
                                    child: Text(
                                      option,
                                      textAlign: TextAlign.right,
                                      style: TextStyle(
                                        fontFamily: 'Lama Sans',
                                        fontSize: 15.sp,
                                        fontWeight: active
                                            ? FontWeight.w800
                                            : FontWeight.w600,
                                        color: active
                                            ? _ModernSheetTokens.primary
                                            : _ModernSheetTokens.textDark,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(height: 14.h),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _ModernSheetTokens.textBody,
                        side: BorderSide(
                          color: _ModernSheetTokens.textBody.withValues(alpha: 0.25),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14.r),
                        ),
                      ),
                      child: Text(
                        'إلغاء',
                        style: TextStyle(
                          fontFamily: 'Lama Sans',
                          fontWeight: FontWeight.w800,
                          fontSize: 16.sp,
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
    );
  }
}

Future<String?> showModernOptionsSheet({
  required BuildContext context,
  required String title,
  required String subtitle,
  required IconData icon,
  required List<String> options,
  String? selected,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (_) => ModernOptionsBottomSheet(
      title: title,
      subtitle: subtitle,
      icon: icon,
      options: options,
      selected: selected,
    ),
  );
}
