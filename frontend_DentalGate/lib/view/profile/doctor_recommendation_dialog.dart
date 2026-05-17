import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

/// نتيجة حوار كتابة توصية لطبيب.
class DoctorRecommendationResult {
  const DoctorRecommendationResult({required this.text});

  final String text;
}

const int kDoctorRecommendationMaxLength = 200;

/// حوار كتابة توصية مهنية (حتى 200 حرف).
Future<DoctorRecommendationResult?> showDoctorRecommendationDialog(
  BuildContext context, {
  String? doctorName,
}) {
  return showDialog<DoctorRecommendationResult>(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withValues(alpha: 0.42),
    builder: (ctx) => _DoctorRecommendationDialog(doctorName: doctorName),
  );
}

class _DoctorRecommendationDialog extends StatefulWidget {
  const _DoctorRecommendationDialog({this.doctorName});

  final String? doctorName;

  @override
  State<_DoctorRecommendationDialog> createState() =>
      _DoctorRecommendationDialogState();
}

class _DoctorRecommendationDialogState extends State<_DoctorRecommendationDialog> {
  final _text = TextEditingController();

  static const Color _ink = Color(0xFF0F172A);
  static const Color _blue = Color(0xFF5993FF);

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _submit() {
    final body = _text.text.trim();
    if (body.isEmpty) {
      Get.snackbar(
        'التوصية',
        'اكتب نص التوصية',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    Navigator.of(context).pop(DoctorRecommendationResult(text: body));
  }

  @override
  Widget build(BuildContext context) {
    final name = (widget.doctorName ?? '').trim();
    final len = _text.text.characters.length;

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
                      Icon(Icons.recommend_rounded, color: _blue, size: 28.sp),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Text(
                          name.isNotEmpty ? 'توصية لـ $name' : 'إضافة توصية',
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
                  child: TextField(
                    controller: _text,
                    maxLength: kDoctorRecommendationMaxLength,
                    maxLines: 5,
                    onChanged: (_) => setState(() {}),
                    textDirection: TextDirection.rtl,
                    decoration: InputDecoration(
                      hintText: 'اكتب توصيتك المهنية…',
                      counterText: '$len / $kDoctorRecommendationMaxLength',
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
                            backgroundColor: _blue,
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14.r),
                            ),
                          ),
                          child: Text(
                            'إرسال التوصية',
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
