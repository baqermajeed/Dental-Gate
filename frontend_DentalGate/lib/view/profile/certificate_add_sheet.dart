import 'package:cached_network_image/cached_network_image.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import 'package:dental_gate/core/media_url.dart';
import 'package:dental_gate/services/api_service.dart';

void _closeCertificateSheet(BuildContext ctx, {Object? result}) {
  FocusManager.instance.primaryFocus?.unfocus();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    Future<void>.delayed(const Duration(milliseconds: 120), () {
      if (!ctx.mounted) return;
      Navigator.of(ctx).pop(result);
    });
  });
}

/// نتيجة إضافة شهادة (صورة واحدة + عنوان + مصدر).
class CertificateFormResult {
  const CertificateFormResult({
    required this.title,
    required this.issuer,
    required this.imageUrl,
  });

  final String title;
  final String issuer;
  final String imageUrl;
}

Future<String?> _pickAndUploadCertificateImage(BuildContext context) async {
  try {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    if (!context.mounted) return null;
    final x = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      requestFullMetadata: false,
    );
    if (x == null) return null;
    if (!context.mounted) return null;
    return await ApiService.instance.uploadProfileImage(
      filePath: x.path,
      purpose: 'certificate',
    );
  } on MissingPluginException catch (_, st) {
    debugPrint('image_picker plugin not linked: $st');
    if (context.mounted) {
      Get.snackbar(
        'أعد بناء التطبيق',
        'أوقف التشغيل ثم شغّل من جديد (flutter run). الإضافات الأصلية لا تعمل مع Hot Reload فقط.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 6),
      );
    }
    return null;
  } on PlatformException catch (e, st) {
    debugPrint('image_picker platform: ${e.code} ${e.message}\n$st');
    if (context.mounted) {
      final detail = e.code == 'channel-error'
          ? 'أوقف التطبيق ثم شغّله من جديد (لا Hot Reload). تم ضبط النشاط الأصلي لفتح المعرض.'
          : (e.message ?? e.toString());
      Get.snackbar(
        'تعذر فتح المعرض',
        detail,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 5),
      );
    }
    return null;
  } on ApiException catch (e) {
    if (context.mounted) {
      Get.snackbar(
        'تعذر رفع الصورة',
        e.message,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
    return null;
  } catch (e, st) {
    debugPrint('pick/upload certificate image: $e\n$st');
    if (context.mounted) {
      Get.snackbar(
        'تعذر اختيار الصورة',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
    }
    return null;
  }
}

class _CertSheetRequiredLabel extends StatelessWidget {
  const _CertSheetRequiredLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        textDirection: TextDirection.rtl,
        children: [
          Text(
            text,
            style: TextStyle(
              fontFamily: 'Lama Sans',
              fontWeight: FontWeight.w700,
              fontSize: 16.sp,
              height: 1.5,
              color: const Color(0xFF040814),
            ),
          ),
          SizedBox(width: 4.w),
          Container(
            width: 5.r,
            height: 5.r,
            decoration: const BoxDecoration(
              color: Color(0xFFE53935),
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}

class _CertSheetTitleField extends StatelessWidget {
  const _CertSheetTitleField({required this.controller, this.hintText});

  final TextEditingController controller;
  final String? hintText;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 47.h,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: TextField(
          controller: controller,
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.start,
          textAlignVertical: TextAlignVertical.center,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0x4DD9D9D9),
            hintText: hintText,
            hintStyle: TextStyle(
              fontFamily: 'Lama Sans',
              fontWeight: FontWeight.w700,
              fontSize: 14.sp,
              height: 1.5,
              color: const Color(0xFF6B7280),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide.none,
            ),
            counterText: '',
            contentPadding: EdgeInsets.fromLTRB(19.w, 17.h, 19.w, 17.h),
          ),
          style: TextStyle(
            fontFamily: 'Lama Sans',
            fontWeight: FontWeight.w800,
            fontSize: 14.sp,
            height: 1.5,
            color: const Color(0xFF000000),
          ),
        ),
      ),
    );
  }
}

class _CertSheetImageThumb extends StatelessWidget {
  const _CertSheetImageThumb({required this.src, required this.height});

  final String src;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22.r),
        color: const Color(0xFFE7E7EA),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: src.isEmpty
                ? Icon(
                    Icons.image_outlined,
                    color: const Color(0xFF9CA3AF),
                    size: 28.sp,
                  )
                : CachedNetworkImage(
                    imageUrl: resolveMediaUrl(src),
                    fit: BoxFit.cover,
                    memCacheWidth: 420,
                    memCacheHeight: 280,
                    fadeInDuration: Duration.zero,
                    fadeOutDuration: Duration.zero,
                    placeholder: (context, url) => Container(
                      color: const Color(0xFFE7E7EA),
                      alignment: Alignment.center,
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: const Color(0xFF9CA3AF).withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Icon(
                      Icons.broken_image_outlined,
                      color: const Color(0xFF9CA3AF),
                      size: 28.sp,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet لإضافة شهادة جديدة (نفس منطق صفحة التعديل السابقة).
Future<CertificateFormResult?> showCertificateAddSheet(BuildContext context) async {
  final title = TextEditingController();
  final issuer = TextEditingController();
  String? imageUrl;
  try {
    final result = await showModalBottomSheet<CertificateFormResult>(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final sheetHeight = (MediaQuery.of(ctx).size.height * 0.82).clamp(420.0, 640.0);
        return StatefulBuilder(
          builder: (ctx, setModal) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: Container(
                width: 393.w,
                height: sheetHeight,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F6F8),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(36.r)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1A515459),
                      offset: Offset(0, -2),
                      blurRadius: 29.1,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                padding: EdgeInsets.fromLTRB(28.w, 16.h, 28.w, 44.h),
                child: ListView(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  children: [
                    Center(
                      child: Container(
                        width: 51.w,
                        height: 5.h,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD9D8D8),
                          borderRadius: BorderRadius.circular(2.r),
                        ),
                      ),
                    ),
                    SizedBox(height: 20.h),
                    Text(
                      'أضافة شهادة جديدة',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Lama Sans',
                        fontWeight: FontWeight.w800,
                        fontSize: 20.sp,
                        height: 1,
                        color: const Color(0xFF040814),
                      ),
                    ),
                    SizedBox(height: 18.h),
                    const _CertSheetRequiredLabel('أسم الشهادة'),
                    SizedBox(height: 8.h),
                    _CertSheetTitleField(
                      controller: title,
                      hintText: 'اكتب اسم الشهادة',
                    ),
                    SizedBox(height: 12.h),
                    const _CertSheetRequiredLabel('مصدر الشهادة'),
                    SizedBox(height: 8.h),
                    _CertSheetTitleField(
                      controller: issuer,
                      hintText: 'اكتب مصدر الشهادة',
                    ),
                    SizedBox(height: 12.h),
                    const _CertSheetRequiredLabel('صورة الشهادة'),
                    SizedBox(height: 8.h),
                    LayoutBuilder(
                      builder: (ctx2, c) {
                        final cellW = ((c.maxWidth - 10.w) / 2).clamp(120.0, 200.0);
                        final cellH = cellW * 0.82;
                        Widget addTile() {
                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () async {
                                final imgUrl = await _pickAndUploadCertificateImage(ctx);
                                if (imgUrl == null || imgUrl.trim().isEmpty) return;
                                setModal(() => imageUrl = imgUrl.trim());
                              },
                              borderRadius: BorderRadius.circular(16.r),
                              child: DottedBorder(
                                color: const Color(0xFF9CA3AF),
                                strokeWidth: 1.2,
                                radius: Radius.circular(16.r),
                                borderType: BorderType.RRect,
                                dashPattern: const [6, 4],
                                child: SizedBox(
                                  width: cellW,
                                  height: cellH,
                                  child: Center(
                                    child: Text(
                                      '+ أضف صورة جديدة',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontFamily: 'Lama Sans',
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13.sp,
                                        color: const Color(0xFF757A80),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }

                        if (imageUrl == null || imageUrl!.isEmpty) {
                          return addTile();
                        }
                        return SizedBox(
                          width: cellW,
                          height: cellH,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Positioned.fill(
                                child: _CertSheetImageThumb(
                                  src: imageUrl!,
                                  height: cellH,
                                ),
                              ),
                              PositionedDirectional(
                                top: 6.h,
                                end: 6.w,
                                child: Material(
                                  color: Colors.white,
                                  elevation: 2,
                                  shadowColor: Colors.black26,
                                  shape: const CircleBorder(),
                                  child: InkWell(
                                    customBorder: const CircleBorder(),
                                    onTap: () => setModal(() => imageUrl = null),
                                    child: Padding(
                                      padding: EdgeInsets.all(6.r),
                                      child: Icon(
                                        Icons.close_rounded,
                                        size: 18.sp,
                                        color: const Color(0xFF3F3F46),
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
                    SizedBox(height: 18.h),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _closeCertificateSheet(ctx),
                            style: OutlinedButton.styleFrom(
                              minimumSize: Size.fromHeight(48.h),
                              side: const BorderSide(color: Color(0xFFFF724C)),
                              foregroundColor: const Color(0xFFFF724C),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                            ),
                            child: Text(
                              'الغاء',
                              style: TextStyle(
                                fontFamily: 'Lama Sans',
                                fontWeight: FontWeight.w800,
                                fontSize: 16.sp,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 16.w),
                        Expanded(
                          child: FilledButton(
                            onPressed: () {
                              final t = title.text.trim();
                              final iss = issuer.text.trim();
                              final img = imageUrl?.trim() ?? '';
                              if (t.isEmpty || iss.isEmpty || img.isEmpty) {
                                Get.snackbar(
                                  'بيانات ناقصة',
                                  'يرجى إدخال اسم الشهادة ومصدرها وإضافة صورة',
                                  snackPosition: SnackPosition.BOTTOM,
                                );
                                return;
                              }
                              _closeCertificateSheet(
                                ctx,
                                result: CertificateFormResult(
                                  title: t,
                                  issuer: iss,
                                  imageUrl: img,
                                ),
                              );
                            },
                            style: FilledButton.styleFrom(
                              minimumSize: Size.fromHeight(48.h),
                              backgroundColor: const Color(0xFFFF724C),
                              foregroundColor: const Color(0xFFFDFEFF),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                            ),
                            child: Text(
                              'حفظ',
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
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    return result;
  } finally {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      title.dispose();
      issuer.dispose();
    });
  }
}
