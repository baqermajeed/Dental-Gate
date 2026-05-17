import 'package:cached_network_image/cached_network_image.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import 'package:dental_gate/core/media_url.dart';
import 'package:dental_gate/services/api_service.dart' show ApiException, ApiService;
import 'package:dental_gate/view/profile/experience_score_breakdown.dart';

/// يُرجع `true` عند إرسال الدورة بنجاح.
Future<bool?> showAccreditedCourseSubmitDialog(BuildContext context) async {
  return showDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withValues(alpha: 0.42),
    builder: (ctx) => const _AccreditedCourseSubmitDialog(),
  );
}

class _AccreditedCourseSubmitDialog extends StatefulWidget {
  const _AccreditedCourseSubmitDialog();

  @override
  State<_AccreditedCourseSubmitDialog> createState() =>
      _AccreditedCourseSubmitDialogState();
}

class _AccreditedCourseSubmitDialogState
    extends State<_AccreditedCourseSubmitDialog> {
  final _title = TextEditingController();
  final _explanation = TextEditingController();
  String? _imageUrl;
  bool _uploading = false;
  bool _submitting = false;

  static const Color _ink = Color(0xFF0F172A);
  static const Color _muted = Color(0xFF64748B);
  static const Color _gold = Color(0xFFF59E0B);

  @override
  void dispose() {
    _title.dispose();
    _explanation.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (_uploading || _submitting) return;
    setState(() => _uploading = true);
    try {
      await Future<void>.delayed(const Duration(milliseconds: 150));
      if (!mounted) return;
      final x = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        requestFullMetadata: false,
      );
      if (x == null) return;
      if (!mounted) return;
      final url = await ApiService.instance.uploadProfileImage(
        filePath: x.path,
        purpose: 'accredited_course',
      );
      if (!mounted) return;
      setState(() => _imageUrl = url);
    } on MissingPluginException catch (_, st) {
      debugPrint('image_picker: $st');
      if (mounted) {
        Get.snackbar(
          'أعد بناء التطبيق',
          'شغّل التطبيق من جديد (flutter run).',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        Get.snackbar('تعذر الرفع', e.message, snackPosition: SnackPosition.BOTTOM);
      }
    } catch (e) {
      if (mounted) {
        Get.snackbar(
          'تعذر اختيار الصورة',
          e.toString(),
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _submit() async {
    final title = _title.text.trim();
    final explanation = _explanation.text.trim();
    final url = (_imageUrl ?? '').trim();
    if (title.isEmpty) {
      Get.snackbar('اسم الدورة', 'أدخل اسم الدورة المعتمدة',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    if (url.isEmpty) {
      Get.snackbar('صورة مطلوبة', 'ارفع شهادة أو إثبات إتمام الدورة',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    if (explanation.isEmpty) {
      Get.snackbar('الشرح مطلوب',
          'أضف شرحاً (الجهة المنظمة، التاريخ، مدة الدورة…)',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    setState(() => _submitting = true);
    try {
      await ApiService.instance.submitAccreditedCourse(
        title: title,
        imageUrl: url,
        explanation: explanation,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted) {
        Get.snackbar('تعذر الإرسال', e.message, snackPosition: SnackPosition.BOTTOM);
      }
    } catch (e) {
      if (mounted) {
        Get.snackbar('تعذر الإرسال', e.toString(),
            snackPosition: SnackPosition.BOTTOM);
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = _uploading || _submitting;
    final preview = (_imageUrl ?? '').trim();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 400.w, maxHeight: 620.h),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26.r),
            child: Material(
              color: Colors.white,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHeader(),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(18.w, 14.h, 18.w, 10.h),
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'ارفع شهادة الدورة مع اسمها وشرح مختصر. بعد موافقة الإدارة تُضاف '
                            '$kAccreditedCoursePointsEach نقاط لكل دورة (حد أقصى $kAccreditedCoursePointsMax).',
                            style: TextStyle(
                              fontFamily: 'Lama Sans',
                              fontWeight: FontWeight.w600,
                              fontSize: 12.5.sp,
                              height: 1.5,
                              color: _muted,
                            ),
                          ),
                          SizedBox(height: 14.h),
                          Text(
                            'اسم الدورة',
                            style: TextStyle(
                              fontFamily: 'Lama Sans',
                              fontWeight: FontWeight.w800,
                              fontSize: 14.sp,
                              color: _ink,
                            ),
                          ),
                          SizedBox(height: 6.h),
                          TextField(
                            controller: _title,
                            enabled: !busy,
                            textDirection: TextDirection.rtl,
                            decoration: InputDecoration(
                              hintText: 'مثال: زراعة الأسنان المتقدمة',
                              filled: true,
                              fillColor: const Color(0xFFF1F5F9),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14.r),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            style: TextStyle(
                              fontFamily: 'Lama Sans',
                              fontWeight: FontWeight.w700,
                              fontSize: 14.sp,
                              color: _ink,
                            ),
                          ),
                          SizedBox(height: 14.h),
                          Text(
                            'صورة الشهادة',
                            style: TextStyle(
                              fontFamily: 'Lama Sans',
                              fontWeight: FontWeight.w800,
                              fontSize: 14.sp,
                              color: _ink,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          GestureDetector(
                            onTap: busy ? null : _pickImage,
                            child: DottedBorder(
                              borderType: BorderType.RRect,
                              radius: Radius.circular(18.r),
                              color: const Color(0xFFCBD5E1),
                              dashPattern: const [6, 4],
                              child: Container(
                                height: 140.h,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(18.r),
                                  color: const Color(0xFFF8FAFC),
                                ),
                                child: preview.isEmpty
                                    ? Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          if (_uploading)
                                            const CircularProgressIndicator(
                                              color: _gold,
                                              strokeWidth: 2.5,
                                            )
                                          else ...[
                                            Icon(
                                              Icons.school_rounded,
                                              size: 34.sp,
                                              color: _gold,
                                            ),
                                            SizedBox(height: 6.h),
                                            Text(
                                              'اضغط لاختيار صورة',
                                              style: TextStyle(
                                                fontFamily: 'Lama Sans',
                                                fontWeight: FontWeight.w700,
                                                fontSize: 13.sp,
                                                color: _muted,
                                              ),
                                            ),
                                          ],
                                        ],
                                      )
                                    : ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(18.r),
                                        child: CachedNetworkImage(
                                          imageUrl: resolveMediaUrl(preview),
                                          fit: BoxFit.cover,
                                          height: 140.h,
                                          width: double.infinity,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                          SizedBox(height: 14.h),
                          Text(
                            'شرح للمراجعة',
                            style: TextStyle(
                              fontFamily: 'Lama Sans',
                              fontWeight: FontWeight.w800,
                              fontSize: 14.sp,
                              color: _ink,
                            ),
                          ),
                          SizedBox(height: 6.h),
                          TextField(
                            controller: _explanation,
                            enabled: !busy,
                            maxLines: 3,
                            maxLength: 2000,
                            textDirection: TextDirection.rtl,
                            decoration: InputDecoration(
                              hintText:
                                  'الجهة المنظمة، تاريخ الإنجاز، عدد الساعات…',
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
                  ),
                  _buildActions(busy),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(18.w, 14.h, 12.w, 12.h),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E3A5F)],
        ),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: Icon(Icons.school_rounded, color: _gold, size: 26.sp),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              'إضافة دورة معتمدة',
              style: TextStyle(
                fontFamily: 'Lama Sans',
                fontWeight: FontWeight.w900,
                fontSize: 17.sp,
                color: Colors.white,
              ),
            ),
          ),
          IconButton(
            onPressed: _submitting ? null : () => Navigator.of(context).pop(),
            icon: Icon(Icons.close_rounded,
                color: Colors.white.withValues(alpha: 0.85)),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(bool busy) {
    return Padding(
      padding: EdgeInsets.fromLTRB(18.w, 6.h, 18.w, 14.h),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: busy ? null : () => Navigator.of(context).pop(),
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
              onPressed: busy ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: _gold,
                padding: EdgeInsets.symmetric(vertical: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.r),
                ),
              ),
              child: _submitting
                  ? SizedBox(
                      width: 22.w,
                      height: 22.w,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'إرسال للتحقق',
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
    );
  }
}
