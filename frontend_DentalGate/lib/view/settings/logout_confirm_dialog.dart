import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

/// حوار تأكيد تسجيل الخروج — مطابق لمواصفات التصميم (Figma).
abstract final class LogoutConfirmDialog {
  static const Color _orange = Color(0xFFFF9914);
  static const Color _bodyGray = Color(0xFF515459);
  static const Color _cardBg = Color(0xFFFDFEFF);

  /// يعيد `true` عند تأكيد الخروج، و`false` عند الإلغاء، و`null` عند الإغلاق بالخلفية.
  static Future<bool?> show() {
    return Get.dialog<bool>(
      Directionality(
        textDirection: TextDirection.rtl,
        child: Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: EdgeInsets.symmetric(horizontal: 20.w),
          child: _LogoutCard(
            onConfirm: () => Get.back(result: true),
            onCancel: () => Get.back(result: false),
          ),
        ),
      ),
      barrierDismissible: true,
    );
  }
}

class _LogoutCard extends StatelessWidget {
  const _LogoutCard({
    required this.onConfirm,
    required this.onCancel,
  });

  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 328.w,
      height: 200.h,
      child: Container(
        decoration: BoxDecoration(
          color: LogoutConfirmDialog._cardBg,
          borderRadius: BorderRadius.circular(29.13.r),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF000000).withValues(alpha: 0.10),
              blurRadius: 10.49,
              spreadRadius: 0,
              offset: Offset.zero,
            ),
          ],
        ),
        padding: EdgeInsets.only(
          left: 25.64.w,
          right: 25.64.w,
          top: 12.h,
          bottom: 14.h,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 48.w,
                height: 48.h,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: LogoutConfirmDialog._orange.withValues(alpha: 0.16),
                ),
                alignment: Alignment.center,
                clipBehavior: Clip.antiAlias,
                child: Image.asset(
                  'assets/icons/sign out.png',
                  width: 48.w,
                  height: 48.h,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'تسجيل الخروج',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Lama Sans',
                fontWeight: FontWeight.w900,
                fontSize: 20.sp,
                height: 1.0,
                color: LogoutConfirmDialog._orange,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              'لن تفقد بياناتك ، هل أنت متأكد ؟',
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Lama Sans',
                fontWeight: FontWeight.w700,
                fontSize: 16.sp,
                height: 1.25,
                color: LogoutConfirmDialog._bodyGray,
              ),
            ),
            SizedBox(height: 10.h),
            const Spacer(),
            Row(
              textDirection: TextDirection.rtl,
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48.h,
                    child: ElevatedButton(
                      onPressed: onConfirm,
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: LogoutConfirmDialog._orange,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                      ),
                      child: Text(
                        'تسجيل الخروج',
                        style: TextStyle(
                          fontFamily: 'Lama Sans',
                          fontWeight: FontWeight.w800,
                          fontSize: 15.sp,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: SizedBox(
                    height: 48.h,
                    child: OutlinedButton(
                      onPressed: onCancel,
                      style: OutlinedButton.styleFrom(
                        elevation: 0,
                        foregroundColor: LogoutConfirmDialog._orange,
                        backgroundColor: Colors.white,
                        side: BorderSide(
                          color: LogoutConfirmDialog._orange,
                          width: 1.5,
                        ),
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                      ),
                      child: Text(
                        'إلغاء',
                        style: TextStyle(
                          fontFamily: 'Lama Sans',
                          fontWeight: FontWeight.w800,
                          fontSize: 15.sp,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
