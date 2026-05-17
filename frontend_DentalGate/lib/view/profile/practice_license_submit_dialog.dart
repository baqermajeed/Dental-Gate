import 'package:cached_network_image/cached_network_image.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import 'package:dental_gate/core/media_url.dart';
import 'package:dental_gate/models/doctor_profile_full.dart';
import 'package:dental_gate/services/api_service.dart' show ApiException, ApiService;

/// يُرجع `true` عند إرسال الطلب بنجاح.
Future<bool?> showPracticeLicenseSubmitDialog(
  BuildContext context, {
  PracticeLicenseDto? existing,
}) async {
  return showDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withValues(alpha: 0.42),
    builder: (ctx) => _PracticeLicenseSubmitDialog(existing: existing),
  );
}

class _PracticeLicenseSubmitDialog extends StatefulWidget {
  const _PracticeLicenseSubmitDialog({this.existing});

  final PracticeLicenseDto? existing;

  @override
  State<_PracticeLicenseSubmitDialog> createState() =>
      _PracticeLicenseSubmitDialogState();
}

class _PracticeLicenseSubmitDialogState
    extends State<_PracticeLicenseSubmitDialog> {
  final _explanation = TextEditingController();
  String? _imageUrl;
  bool _uploading = false;
  bool _submitting = false;

  static const Color _ink = Color(0xFF0F172A);
  static const Color _muted = Color(0xFF64748B);
  static const Color _gold = Color(0xFFF59E0B);

  @override
  void initState() {
    super.initState();
    final ex = widget.existing;
    if (ex != null && ex.isRejected) {
      _explanation.text = ex.explanation;
    }
  }

  @override
  void dispose() {
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
        purpose: 'practice_license',
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
    final url = (_imageUrl ?? '').trim();
    final explanation = _explanation.text.trim();
    if (url.isEmpty) {
      Get.snackbar(
        'صورة مطلوبة',
        'ارفع صورة واضحة لشهادة ممارسة المهنة',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    if (explanation.isEmpty) {
      Get.snackbar(
        'الشرح مطلوب',
        'أضف شرحاً يساعد فريق المراجعة (رقم الترخيص، الجهة، تاريخ الإصدار…)',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      await ApiService.instance.submitPracticeLicense(
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
        Get.snackbar(
          'تعذر الإرسال',
          e.toString(),
          snackPosition: SnackPosition.BOTTOM,
        );
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
        insetPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 400.w, maxHeight: 560.h),
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
                      padding: EdgeInsets.fromLTRB(18.w, 16.h, 18.w, 12.h),
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'ارفع صورة شهادة ممارسة المهنة مع شرح مختصر. سيتحقق فريق Dental Gate من الطلب ثم تُضاف النقاط بعد الموافقة.',
                            style: TextStyle(
                              fontFamily: 'Lama Sans',
                              fontWeight: FontWeight.w600,
                              fontSize: 12.8.sp,
                              height: 1.5,
                              color: _muted,
                            ),
                          ),
                          SizedBox(height: 16.h),
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
                                height: 160.h,
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
                                              Icons.add_photo_alternate_rounded,
                                              size: 36.sp,
                                              color: _gold,
                                            ),
                                            SizedBox(height: 8.h),
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
                                    : Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(18.r),
                                            child: CachedNetworkImage(
                                              imageUrl: resolveMediaUrl(preview),
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                          if (_uploading)
                                            Container(
                                              color: Colors.black45,
                                              alignment: Alignment.center,
                                              child: const CircularProgressIndicator(
                                                color: Colors.white,
                                              ),
                                            ),
                                          Positioned(
                                            left: 8.w,
                                            bottom: 8.h,
                                            child: Material(
                                              color: Colors.black54,
                                              borderRadius:
                                                  BorderRadius.circular(8.r),
                                              child: Padding(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: 10.w,
                                                  vertical: 6.h,
                                                ),
                                                child: Text(
                                                  'تغيير الصورة',
                                                  style: TextStyle(
                                                    fontFamily: 'Lama Sans',
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 11.sp,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            'شرح للمراجعة',
                            style: TextStyle(
                              fontFamily: 'Lama Sans',
                              fontWeight: FontWeight.w800,
                              fontSize: 14.sp,
                              color: _ink,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          TextField(
                            controller: _explanation,
                            enabled: !busy,
                            maxLines: 4,
                            maxLength: 2000,
                            textDirection: TextDirection.rtl,
                            decoration: InputDecoration(
                              hintText:
                                  'مثال: رقم الترخيص، جهة الإصدار، تاريخ الصلاحية…',
                              hintStyle: TextStyle(
                                fontFamily: 'Lama Sans',
                                fontWeight: FontWeight.w600,
                                fontSize: 13.sp,
                                color: const Color(0xFF94A3B8),
                              ),
                              filled: true,
                              fillColor: const Color(0xFFF1F5F9),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14.r),
                                borderSide: BorderSide.none,
                              ),
                              counterStyle: TextStyle(
                                fontFamily: 'Lama Sans',
                                fontSize: 11.sp,
                                color: _muted,
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
      padding: EdgeInsets.fromLTRB(18.w, 16.h, 12.w, 14.h),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            Color(0xFF0F172A),
            Color(0xFF1E3A5F),
          ],
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
            child: Icon(
              Icons.verified_user_rounded,
              color: _gold,
              size: 26.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              'توثيق شهادة الممارسة',
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
            icon: Icon(
              Icons.close_rounded,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(bool busy) {
    return Padding(
      padding: EdgeInsets.fromLTRB(18.w, 8.h, 18.w, 16.h),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: busy ? null : () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                foregroundColor: _muted,
                side: const BorderSide(color: Color(0xFFE2E8F0)),
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
                foregroundColor: Colors.white,
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
