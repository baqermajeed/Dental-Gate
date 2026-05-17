import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

/// نتيجة تقييم طبيب من زميل.
class DoctorPeerRatingResult {
  const DoctorPeerRatingResult({
    required this.stars,
    required this.comment,
  });

  final int stars;
  final String comment;
}

const int kPeerRatingMaxCommentLength = 200;

/// حوار تقييم طبيب: 1–5 نجوم + شرح (حتى 200 حرف).
Future<DoctorPeerRatingResult?> showDoctorPeerRatingDialog(
  BuildContext context, {
  String? doctorName,
}) async {
  return showDialog<DoctorPeerRatingResult>(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withValues(alpha: 0.42),
    builder: (ctx) => _DoctorPeerRatingDialog(doctorName: doctorName),
  );
}

class _DoctorPeerRatingDialog extends StatefulWidget {
  const _DoctorPeerRatingDialog({this.doctorName});

  final String? doctorName;

  @override
  State<_DoctorPeerRatingDialog> createState() => _DoctorPeerRatingDialogState();
}

class _DoctorPeerRatingDialogState extends State<_DoctorPeerRatingDialog> {
  int _stars = 0;
  final _comment = TextEditingController();

  static const Color _ink = Color(0xFF0F172A);
  static const Color _muted = Color(0xFF64748B);
  static const Color _gold = Color(0xFFF59E0B);

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  void _submit() {
    if (_stars < 1) {
      Get.snackbar(
        'التقييم',
        'اختر عدد النجوم من 1 إلى 5',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    Navigator.of(context).pop(
      DoctorPeerRatingResult(
        stars: _stars,
        comment: _comment.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = (widget.doctorName ?? '').trim();
    final len = _comment.text.characters.length;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 28.h),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24.r),
          child: Material(
            color: Colors.white,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.fromLTRB(18.w, 16.h, 12.w, 14.h),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF0F172A), Color(0xFF1E3A5F)],
                    ),
                  ),
                  child: Row(
                    textDirection: TextDirection.rtl,
                    children: [
                      Icon(Icons.star_rate_rounded, color: _gold, size: 28.sp),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Text(
                          name.isNotEmpty ? 'تقييم $name' : 'تقييم الطبيب',
                          style: TextStyle(
                            fontFamily: 'Lama Sans',
                            fontWeight: FontWeight.w900,
                            fontSize: 17.sp,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(
                          Icons.close_rounded,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(18.w, 18.h, 18.w, 8.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'كم تُقيّم خبرته وتعامله المهني؟',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Lama Sans',
                          fontWeight: FontWeight.w700,
                          fontSize: 14.sp,
                          color: _muted,
                        ),
                      ),
                      SizedBox(height: 16.h),
                      _StarRatingRow(
                        value: _stars,
                        onChanged: (v) => setState(() => _stars = v),
                      ),
                      SizedBox(height: 18.h),
                      Text(
                        'شرح (اختياري)',
                        style: TextStyle(
                          fontFamily: 'Lama Sans',
                          fontWeight: FontWeight.w800,
                          fontSize: 13.sp,
                          color: _ink,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      TextField(
                        controller: _comment,
                        maxLength: kPeerRatingMaxCommentLength,
                        maxLines: 4,
                        onChanged: (_) => setState(() {}),
                        textDirection: TextDirection.rtl,
                        decoration: InputDecoration(
                          hintText: 'ملاحظاتك المهنية…',
                          counterText: '$len / $kPeerRatingMaxCommentLength',
                          filled: true,
                          fillColor: const Color(0xFFF1F5F9),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14.r),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        style: TextStyle(
                          fontFamily: 'Lama Sans',
                          fontWeight: FontWeight.w600,
                          fontSize: 14.sp,
                          height: 1.45,
                          color: _ink,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(18.w, 4.h, 18.w, 16.h),
                  child: Row(
                    textDirection: TextDirection.rtl,
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14.r),
                            ),
                          ),
                          child: Text(
                            'إلغاء',
                            style: TextStyle(
                              fontFamily: 'Lama Sans',
                              fontWeight: FontWeight.w800,
                              fontSize: 14.sp,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        flex: 2,
                        child: FilledButton(
                          onPressed: _submit,
                          style: FilledButton.styleFrom(
                            backgroundColor: _gold,
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14.r),
                            ),
                          ),
                          child: Text(
                            'إرسال التقييم',
                            style: TextStyle(
                              fontFamily: 'Lama Sans',
                              fontWeight: FontWeight.w900,
                              fontSize: 14.sp,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StarRatingRow extends StatelessWidget {
  const _StarRatingRow({
    required this.value,
    required this.onChanged,
  });

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      textDirection: TextDirection.rtl,
      children: List.generate(5, (i) {
        final star = i + 1;
        final filled = star <= value;
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => onChanged(star),
              customBorder: const CircleBorder(),
              child: Padding(
                padding: EdgeInsets.all(4.w),
                child: Icon(
                  filled ? Icons.star_rounded : Icons.star_outline_rounded,
                  size: 40.sp,
                  color: filled
                      ? const Color(0xFFF59E0B)
                      : const Color(0xFFCBD5E1),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
