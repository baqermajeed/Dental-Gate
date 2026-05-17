import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// حقل اختيار من قائمة بنفس شكل إنشاء الحساب.
class ModernPickerField extends StatelessWidget {
  const ModernPickerField({
    super.key,
    required this.hint,
    required this.width,
    required this.value,
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final String hint;
  final double width;
  final String? value;
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  static const Color _primary = Color(0xFF5993FF);
  static const Color _textDark = Color(0xFF0E1525);
  static const Color _fieldBg = Color(0xFFEAEAEC);
  static const Color _hint = Color(0xFFADADAD);

  @override
  Widget build(BuildContext context) {
    final hasValue = (value ?? '').trim().isNotEmpty;
    return SizedBox(
      width: width,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12.r),
          onTap: enabled ? onTap : null,
          child: Container(
            constraints: BoxConstraints(minHeight: 58.h),
            padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 12.h),
            decoration: BoxDecoration(
              color: _fieldBg,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: hasValue
                    ? _primary.withValues(alpha: 0.22)
                    : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Row(
              textDirection: TextDirection.rtl,
              children: [
                Icon(
                  icon,
                  color: hasValue ? _primary : _hint,
                  size: 22.sp,
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Text(
                    hasValue ? value! : hint,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontFamily: 'Lama Sans',
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: hasValue ? _textDark : _hint,
                      height: 1.35,
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: hasValue ? _primary : _hint,
                  size: 22.sp,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
