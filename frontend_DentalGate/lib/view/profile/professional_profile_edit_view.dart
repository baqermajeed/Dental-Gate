import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dental_gate/controllers/home_controller.dart';
import 'package:dental_gate/core/media_url.dart';
import 'package:dental_gate/models/doctor_profile_full.dart';
import 'package:dental_gate/services/api_service.dart';
import 'package:dental_gate/widgets/app_back_button.dart';
import 'package:dental_gate/widgets/modern_options_bottom_sheet.dart';
import 'package:dental_gate/widgets/modern_picker_field.dart';
import 'package:dental_gate/view/settings/profile_save_success_dialog.dart';
import 'package:dental_gate/view/profile/clinical_case_add_sheet.dart'
    show kMaxClinicalCaseImages;

/// أيقونة ختم التعليم؛ ثابت على مستوى الملف لـ [precacheImage] وتقليل تكرار فك الترميز.
const String _kEduSealAssetPath = 'assets/icons/IMG_0635.PNG';

/// عدد الأحرف مع استبعاد كل المسافات (Unicode whitespace بما فيها المسافة والسطر).
int _bioNonWhitespaceCount(String text) =>
    text.replaceAll(RegExp(r'\s'), '').length;

const int _kBioMinSignificantChars = 20;

/// بعد `Navigator.pop` للـ sheet قد يُعاد بناء المحتوى لإطار واحد؛ لا تُعد `dispose` للمتحكمات في نفس اللحظة.
void _disposeControllersAfterModal(List<TextEditingController> controllers) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    for (final c in controllers) {
      c.dispose();
    }
  });
}

class ProfessionalProfileEditView extends StatefulWidget {
  const ProfessionalProfileEditView({super.key, this.initialProfile});

  final DoctorProfileFull? initialProfile;

  @override
  State<ProfessionalProfileEditView> createState() =>
      _ProfessionalProfileEditViewState();
}

class _ProfessionalProfileEditViewState extends State<ProfessionalProfileEditView> {
  static const String _otherOption = 'أخرى';
  /// مطابقة لقائمة المحافظات في إنشاء الحساب.
  static const List<String> _governorates = [
    'بغداد',
    'نينوى',
    'البصرة',
    'أربيل',
    'النجف',
    'كربلاء',
    'السليمانية',
    'دهوك',
    'كركوك',
    'الأنبار',
    'ديالى',
    'صلاح الدين',
    'بابل',
    'واسط',
    'ذي قار',
    'ميسان',
    'المثنى',
    'القادسية',
  ];
  /// مطابقة لخيارات التخصص في شاشة إنشاء الحساب.
  static const List<String> _professionalSpecialties = [
    'طبيب اسنان',
    'مساعد طبيب',
    'تقني اسنان',
  ];
  late final TextEditingController _name;
  late final TextEditingController _city;
  late final TextEditingController _phone;
  late final TextEditingController _email;
  late final TextEditingController _age;
  late final TextEditingController _bio;

  late final ValueNotifier<int> _yearsExperience;
  late final ValueNotifier<List<_EducationFormEntry>> _educationEntries;
  late final ValueNotifier<List<_ClinicalCaseFormEntry>> _clinicalCaseEntries;
  late final ValueNotifier<List<_CertificateFormEntry>> _certificateEntries;
  late final ValueNotifier<List<TextEditingController>> _languageControllers;
  late final ValueNotifier<List<TextEditingController>> _skillControllers;
  late final ValueNotifier<List<_ExperienceFormEntry>> _experienceEntries;
  late final ValueNotifier<String?> _selectedSpecialtyNv;
  late final ValueNotifier<String?> _selectedGovernorateNv;
  /// خيارات «الاختصاص المهني» في البيانات الأساسية (مثل إنشاء الحساب).
  final List<String> _specialties = [];
  /// تخصص الشهادة في قسم التعليم — من الخادم كما سابقاً.
  final List<String> _educationSpecialtyOptions = [];
  final List<String> _educationOptions = [];
  final List<String> _languageOptions = [];
  final List<String> _skillOptions = [];
  final List<String> _universityOptions = [];
  bool _isSaving = false;
  /// يُعرض مؤشر تحميل حتى يكتمل إطار التنقّل ثم يُبنى النموذج؛ يقلّل ANR مع الشاشات الثقيلة.
  bool _formReady = false;
  /// يمنع إكمال التعبئة غير المتزامنة بعد [dispose] (تسرّب متحكمات أو كتابة على notifiers مُتلفة).
  bool _hydrationCancelled = false;
  /// رابط الصورة بعد الرفع المحلي (يُدمج في الحفظ كـ [imageUrl]).
  late final ValueNotifier<String?> _avatarPickedUrlNv;
  late final ValueNotifier<bool> _avatarBusyNv;

  @override
  void initState() {
    super.initState();
    final p = widget.initialProfile;
    _name = TextEditingController(text: p?.name ?? '');
    _city = TextEditingController(text: p?.governorate ?? '');
    _phone = TextEditingController(text: p?.phone ?? '');
    _email = TextEditingController(text: p?.email ?? '');
    _age = TextEditingController(
      text: p?.age != null ? '${p!.age}' : '',
    );
    _bio = TextEditingController(text: p?.bio ?? '');
    _yearsExperience = ValueNotifier<int>(p?.yearsExperience ?? 0);
    _selectedSpecialtyNv = ValueNotifier<String?>(_resolveSpecialty(p));
    _selectedGovernorateNv = ValueNotifier<String?>(_resolveGovernorate(p?.governorate));
    _avatarPickedUrlNv = ValueNotifier<String?>(null);
    _avatarBusyNv = ValueNotifier<bool>(false);

    _educationEntries = ValueNotifier<List<_EducationFormEntry>>([]);
    _languageControllers = ValueNotifier<List<TextEditingController>>([]);
    _skillControllers = ValueNotifier<List<TextEditingController>>([]);
    _experienceEntries = ValueNotifier<List<_ExperienceFormEntry>>([]);
    _clinicalCaseEntries = ValueNotifier<List<_ClinicalCaseFormEntry>>([]);
    _certificateEntries = ValueNotifier<List<_CertificateFormEntry>>([]);
    _scheduleRevealFormAndLoadLists();
  }

  /// تعبئة القوائم من الـ API على دفعات مع [Future.delayed(Duration.zero)] لتفادي حجب الخيط الرئيسي لآلاف الملّي ثانية.
  Future<void> _populateFromProfileAsync() async {
    final p = widget.initialProfile;
    if (_hydrationCancelled || !mounted) return;

    final edu = p?.education ?? const <EducationEntryDto>[];
    final eduList = <_EducationFormEntry>[];
    for (final item in edu) {
      eduList.add(
        _EducationFormEntry(
          degreeLabel: _educationLabelFromApi(item.degreeType.trim()),
          specialty: item.specialty.trim(),
          university: item.university.trim(),
          startYear: item.startYear?.toString() ?? '',
          graduationYear: item.graduationYear?.toString() ?? '',
        ),
      );
    }
    _educationEntries.value = eduList;
    await Future<void>.delayed(Duration.zero);
    if (_hydrationCancelled || !mounted) return;

    final langs = p?.languages.map((e) => e.trim()).where((e) => e.isNotEmpty) ?? const Iterable<String>.empty();
    final langCtrls = <TextEditingController>[];
    for (final item in langs) {
      langCtrls.add(TextEditingController(text: item));
    }
    if (_hydrationCancelled || !mounted) {
      for (final c in langCtrls) {
        c.dispose();
      }
      return;
    }
    _languageControllers.value = langCtrls;
    await Future<void>.delayed(Duration.zero);
    if (_hydrationCancelled || !mounted) return;

    final skills = p?.skillIds.map((e) => e.trim()).where((e) => e.isNotEmpty) ?? const Iterable<String>.empty();
    final skillCtrls = <TextEditingController>[];
    for (final item in skills) {
      skillCtrls.add(TextEditingController(text: item));
    }
    if (_hydrationCancelled || !mounted) {
      for (final c in skillCtrls) {
        c.dispose();
      }
      return;
    }
    _skillControllers.value = skillCtrls;
    await Future<void>.delayed(Duration.zero);
    if (_hydrationCancelled || !mounted) return;

    final exps = p?.experiences ?? const <WorkExperienceDto>[];
    final expList = <_ExperienceFormEntry>[];
    for (final item in exps) {
      if (item.workplace.trim().isEmpty) continue;
      expList.add(
        _ExperienceFormEntry(
          workplace: item.workplace.trim(),
          role: item.experienceType.trim().isEmpty ? 'غير محدد' : item.experienceType.trim(),
          startYear: _yearFromIso(item.periodStart) ?? '',
          endYear: _yearFromIso(item.periodEnd) ?? '',
          isCurrent: item.periodEnd == null || item.periodEnd!.trim().isEmpty,
        ),
      );
    }
    _experienceEntries.value = expList;
    await Future<void>.delayed(Duration.zero);
    if (_hydrationCancelled || !mounted) return;

    final cases = p?.gallery ?? const <GalleryItemDto>[];
    final caseList = <_ClinicalCaseFormEntry>[];
    var galleryIndex = 0;
    for (final item in cases) {
      final parts = item.caption.split('\n\n');
      final rawTitle = parts.isNotEmpty ? parts.first.trim() : '';
      final rawDesc = parts.length > 1 ? parts.sublist(1).join('\n\n').trim() : '';
      final imgs = item.images
          .take(kMaxClinicalCaseImages)
          .map((e) => resolveMediaUrl(e))
          .where((e) => e.trim().isNotEmpty)
          .toList();
      caseList.add(
        _ClinicalCaseFormEntry(
          title: rawTitle.isEmpty ? 'حالة بدون عنوان' : rawTitle,
          description: rawDesc,
          imageUrls: imgs,
        ),
      );
      galleryIndex++;
      if (galleryIndex % 12 == 0) {
        await Future<void>.delayed(Duration.zero);
        if (_hydrationCancelled || !mounted) return;
      }
    }
    _clinicalCaseEntries.value = caseList;
    await Future<void>.delayed(Duration.zero);
    if (_hydrationCancelled || !mounted) return;

    final certList = <_CertificateFormEntry>[];
    final certificateImages = p?.certificateImages ?? const <CertificateImageDto>[];
    for (final item in certificateImages) {
      final resolved = resolveMediaUrl(item.url).trim();
      if (resolved.isEmpty) continue;
      final rawTitle = (item.title ?? '').trim();
      certList.add(
        _CertificateFormEntry(
          title: rawTitle.isEmpty ? 'شهادة بدون عنوان' : rawTitle,
          issuer: (item.issuer ?? '').trim(),
          imageUrls: [resolved],
        ),
      );
    }
    _certificateEntries.value = certList;
  }

  void _scheduleRevealFormAndLoadLists() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future<void>.delayed(Duration.zero);
      if (!mounted || _hydrationCancelled) return;
      try {
        await precacheImage(
          const AssetImage(_kEduSealAssetPath),
          context,
        );
      } catch (_) {
        /* أصل الأصول أو السياق غير جاهزين */
      }
      if (!mounted || _hydrationCancelled) return;
      await _populateFromProfileAsync();
      if (!mounted || _hydrationCancelled) return;
      setState(() => _formReady = true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_loadPickLists());
      });
    });
  }

  String _educationLabelFromApi(String apiValue) {
    switch (apiValue) {
      case 'diploma':
        return 'دبلوم';
      case 'bachelor':
        return 'بكالوريوس';
      case 'master':
        return 'ماجستير';
      case 'doctorate':
        return 'دكتوراه';
      default:
        return apiValue;
    }
  }

  String? _educationApiFromLabel(String label) {
    switch (label.trim()) {
      case 'دبلوم':
        return 'diploma';
      case 'بكالوريوس':
        return 'bachelor';
      case 'ماجستير':
        return 'master';
      case 'دكتوراه':
        return 'doctorate';
      default:
        return null;
    }
  }

  String _resolveSpecialty(DoctorProfileFull? p) {
    if (p == null) return '';
    final explicit = p.professionalTitle?.trim();
    if (explicit != null && explicit.isNotEmpty) return explicit;
    return '';
  }

  String? _resolveGovernorate(String? value) {
    final current = (value ?? '').trim();
    if (current.isEmpty) return null;
    if (_governorates.contains(current)) return current;
    return current;
  }

  Future<void> _loadPickLists() async {
    try {
      final results = await Future.wait<List<String>>([
        ApiService.instance.fetchDentalSpecialties(),
        ApiService.instance.fetchEducationOptions(),
        ApiService.instance.fetchLanguageOptions(),
        ApiService.instance.fetchSkillOptions(),
        ApiService.instance.fetchUniversityOptions(),
      ]);
      if (!mounted) return;
      await Future<void>.delayed(Duration.zero);
      if (!mounted) return;
      final clean = List<String>.from(_professionalSpecialties);
      final dentalRaw = results[0]
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      final dentalForEducation = dentalRaw.isNotEmpty
          ? dentalRaw
          : List<String>.from(_professionalSpecialties);
      final edu = results[1]
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      final langs = results[2]
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      final skills = results[3]
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      final universities = results[4]
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      final current = _resolveSpecialty(widget.initialProfile).trim();
      setState(() {
        _specialties
          ..clear()
          ..addAll(clean);
        _educationSpecialtyOptions
          ..clear()
          ..addAll(dentalForEducation);
        _educationOptions
          ..clear()
          ..addAll(edu);
        _languageOptions
          ..clear()
          ..addAll(langs);
        _skillOptions
          ..clear()
          ..addAll(skills);
        _universityOptions
          ..clear()
          ..addAll(universities);
        if (current.isEmpty) {
          _selectedSpecialtyNv.value = clean.isNotEmpty ? clean.first : null;
          return;
        }
        if (!clean.contains(current)) {
          _specialties.add(current);
        }
        _selectedSpecialtyNv.value = current;
      });
    } catch (_) {
      if (!mounted) return;
      final currentFallback = _resolveSpecialty(widget.initialProfile).trim();
      setState(() {
        _specialties
          ..clear()
          ..addAll(_professionalSpecialties);
        if (currentFallback.isNotEmpty &&
            !_specialties.contains(currentFallback)) {
          _specialties.add(currentFallback);
        }
        _educationSpecialtyOptions
          ..clear()
          ..addAll(_professionalSpecialties);
        _educationOptions.clear();
        _languageOptions.clear();
        _skillOptions.clear();
        _universityOptions.clear();
        _selectedSpecialtyNv.value =
            currentFallback.isEmpty ? null : currentFallback;
      });
    }
  }

  Future<void> _addFromOptions({
    required List<String> options,
    required ValueNotifier<List<TextEditingController>> controllersNotifier,
    required bool allowOther,
    required String title,
    required String otherPrompt,
    String pickerTitle = 'اختر اللغة',
  }) async {
    if (options.isEmpty && !allowOther) return;
    final picked = await showModalBottomSheet<String>(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final entries = <String>[
          ...options,
          if (allowOther) _otherOption,
        ];
        final media = MediaQuery.of(ctx);
        final sheetH = (media.size.height * 0.52).clamp(360.0, 540.0);
        final existing = controllersNotifier.value
            .map((c) => c.text.trim())
            .where((s) => s.isNotEmpty)
            .toSet();

        IconData iconFor(String label) {
          final t = label.trim();
          if (t == _otherOption) return Icons.edit_note_rounded;
          if (t.contains('عرب')) return Icons.menu_book_outlined;
          if (t.contains('نجليز')) return Icons.translate_rounded;
          return Icons.language_rounded;
        }

        return Directionality(
          textDirection: TextDirection.rtl,
          child: SafeArea(
            child: Container(
              height: sheetH,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F6F8),
                borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1A040814),
                    blurRadius: 24,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: 10.h),
                  Center(
                    child: Container(
                      width: 48.w,
                      height: 5.h,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD1D5DB),
                        borderRadius: BorderRadius.circular(3.r),
                      ),
                    ),
                  ),
                  SizedBox(height: 18.h),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 22.w),
                    child: Text(
                      pickerTitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Lama Sans',
                        fontWeight: FontWeight.w800,
                        fontSize: 20.sp,
                        height: 1.2,
                        color: const Color(0xFF040814),
                      ),
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 22.w),
                    child: Text(
                      'اختر لغة لإضافتها إلى بروفايلك',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Lama Sans',
                        fontWeight: FontWeight.w600,
                        fontSize: 13.sp,
                        height: 1.45,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ),
                  SizedBox(height: 18.h),
                  Expanded(
                    child: ListView.separated(
                      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 20.h),
                      physics: const BouncingScrollPhysics(),
                      itemCount: entries.length,
                      separatorBuilder: (_, __) => SizedBox(height: 10.h),
                      itemBuilder: (_, i) {
                        final item = entries[i];
                        final taken = existing.contains(item);
                        return Opacity(
                          opacity: taken ? 0.45 : 1,
                          child: Material(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18.r),
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              onTap: taken
                                  ? () {
                                      Get.snackbar(
                                        'مضافة مسبقاً',
                                        'هذه اللغة موجودة بالفعل في قائمتك',
                                        snackPosition: SnackPosition.BOTTOM,
                                      );
                                    }
                                  : () => Navigator.of(ctx).pop(item),
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(18.r),
                                  border: Border.all(
                                    color: taken
                                        ? const Color(0xFFE5E7EB)
                                        : const Color(0xFF7FB2E4).withValues(alpha: 0.55),
                                    width: 1.2,
                                  ),
                                  boxShadow: [
                                    if (!taken)
                                      BoxShadow(
                                        color: const Color(0xFF5993FF).withValues(alpha: 0.1),
                                        blurRadius: 14,
                                        offset: const Offset(0, 6),
                                      ),
                                  ],
                                ),
                                child: Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
                                  child: Row(
                                    textDirection: TextDirection.rtl,
                                    children: [
                                      Container(
                                        width: 48.w,
                                        height: 48.w,
                                        decoration: BoxDecoration(
                                          gradient: taken
                                              ? null
                                              : const LinearGradient(
                                                  begin: Alignment.topRight,
                                                  end: Alignment.bottomLeft,
                                                  colors: [
                                                    Color(0xFF7FB2E4),
                                                    Color(0xFF5993FF),
                                                  ],
                                                ),
                                          color: taken ? const Color(0xFFF3F4F6) : null,
                                          borderRadius: BorderRadius.circular(14.r),
                                        ),
                                        alignment: Alignment.center,
                                        child: Icon(
                                          iconFor(item),
                                          color: taken ? const Color(0xFF9CA3AF) : Colors.white,
                                          size: 24.sp,
                                        ),
                                      ),
                                      SizedBox(width: 14.w),
                                      Expanded(
                                        child: Text(
                                          item,
                                          textAlign: TextAlign.right,
                                          style: TextStyle(
                                            fontFamily: 'Lama Sans',
                                            fontWeight: FontWeight.w800,
                                            fontSize: 16.sp,
                                            color: taken
                                                ? const Color(0xFF9CA3AF)
                                                : const Color(0xFF040814),
                                          ),
                                        ),
                                      ),
                                      Icon(
                                        Icons.chevron_left_rounded,
                                        color: const Color(0xFF94A3B8),
                                        size: 26.sp,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    if (picked == null || !mounted) return;
    String value = picked.trim();
    if (allowOther && value == _otherOption) {
      final custom = await _askCustomValue(title: title, prompt: otherPrompt);
      if (custom == null || custom.trim().isEmpty) return;
      value = custom.trim();
    }
    if (value.isEmpty) return;
    final list = controllersNotifier.value;
    if (list.any((c) => c.text.trim() == value)) return;
    controllersNotifier.value = [
      ...list,
      TextEditingController(text: value),
    ];
  }

  Future<void> _showAddSkillDialog() async {
    if (!mounted) return;
    if (_skillOptions.isEmpty) {
      Get.snackbar(
        'لا توجد مهارات',
        'تعذر تحميل قائمة المهارات من الخادم',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    final entries = _skillOptions
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    final initiallySelected = _skillControllers.value
        .map((c) => c.text.trim())
        .where((e) => e.isNotEmpty)
        .toSet();
    final picked = await showModalBottomSheet<List<String>>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final sheetHeight = MediaQuery.of(ctx).size.height * 0.82;
        final selected = <String>{...initiallySelected};
        return StatefulBuilder(
          builder: (ctx, setModal) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: Container(
                height: sheetHeight,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F6F8),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(36.r)),
                ),
                padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 16.h),
                child: SafeArea(
                  top: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
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
                        'أضافة مهارة جديدة',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Lama Sans',
                          fontWeight: FontWeight.w800,
                          fontSize: 20.sp,
                          height: 1.0,
                          letterSpacing: 0,
                          color: const Color(0xFF040814),
                        ),
                      ),
                      SizedBox(height: 18.h),
                      Expanded(
                        child: RepaintBoundary(
                          child: GridView.builder(
                            physics: const BouncingScrollPhysics(),
                            itemCount: entries.length,
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 12.h,
                              crossAxisSpacing: 12.w,
                              childAspectRatio: 148 / 44,
                            ),
                            itemBuilder: (_, i) {
                              final item = entries[i];
                              final isSelected = selected.contains(item);
                              return Material(
                                color: isSelected
                                    ? const Color(0xFFFF7345)
                                    : const Color(0xFFE7E7EA),
                                borderRadius: BorderRadius.circular(14.41.r),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(14.41.r),
                                  onTap: () {
                                    setModal(() {
                                      if (selected.contains(item)) {
                                        selected.remove(item);
                                      } else {
                                        selected.add(item);
                                      }
                                    });
                                  },
                                  child: SizedBox(
                                    width: 148.w,
                                    height: 44.h,
                                    child: Padding(
                                      padding: EdgeInsets.fromLTRB(
                                        9.91.w,
                                        9.01.h,
                                        9.91.w,
                                        9.01.h,
                                      ),
                                      child: Align(
                                        alignment: Alignment.center,
                                        child: Text(
                                          item,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontFamily: 'Lama Sans',
                                            fontWeight: FontWeight.w800,
                                            fontSize: 13.27.sp,
                                            height: 1.5,
                                            color: isSelected
                                                ? const Color(0xFFFDFEFF)
                                                : const Color(0xFF757A80),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      SizedBox(height: 18.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 148.w,
                            child: FilledButton(
                              onPressed: () => Navigator.of(ctx).pop(
                                selected.toList(),
                              ),
                              style: FilledButton.styleFrom(
                                minimumSize: Size(148.w, 48.h),
                                padding: EdgeInsets.fromLTRB(45.w, 13.h, 45.w, 13.h),
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
                                  height: 1.5,
                                  letterSpacing: 0,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 16.w),
                          SizedBox(
                            width: 148.w,
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(ctx).pop(),
                              style: OutlinedButton.styleFrom(
                                minimumSize: Size(148.w, 48.h),
                                side: const BorderSide(color: Color(0xFFFF7345)),
                                foregroundColor: const Color(0xFFFF7345),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                              ),
                              child: Text(
                                'إلغاء',
                                style: TextStyle(
                                  fontFamily: 'Lama Sans',
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16.sp,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
    if (picked == null || !mounted) return;
    final cleaned = picked.map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    for (final c in _skillControllers.value) {
      c.dispose();
    }
    _skillControllers.value =
        cleaned.map((e) => TextEditingController(text: e)).toList();
  }

  Future<String?> _askCustomValue({
    required String title,
    required String prompt,
  }) async {
    final c = TextEditingController();
    try {
      return await showDialog<String>(
        context: context,
        barrierDismissible: true,
        builder: (ctx) => Directionality(
          textDirection: TextDirection.rtl,
          child: Dialog(
            insetPadding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 28.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24.r),
            ),
            backgroundColor: const Color(0xFFF8FAFC),
            child: Padding(
              padding: EdgeInsets.fromLTRB(18.w, 20.h, 18.w, 18.h),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    textDirection: TextDirection.rtl,
                    children: [
                      Container(
                        padding: EdgeInsets.all(10.r),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topRight,
                            end: Alignment.bottomLeft,
                            colors: [
                              Color(0xFF7FB2E4),
                              Color(0xFF5993FF),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(14.r),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF5993FF).withValues(alpha: 0.25),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.edit_note_rounded,
                          color: Colors.white,
                          size: 22.sp,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Text(
                          title,
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontFamily: 'Lama Sans',
                            fontWeight: FontWeight.w800,
                            fontSize: 18.sp,
                            height: 1.25,
                            color: const Color(0xFF040814),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 18.h),
                  TextField(
                    controller: c,
                    autofocus: true,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontFamily: 'Lama Sans',
                      fontWeight: FontWeight.w700,
                      fontSize: 15.sp,
                      color: const Color(0xFF040814),
                    ),
                    decoration: InputDecoration(
                      hintText: prompt,
                      filled: true,
                      fillColor: Colors.white,
                      hintStyle: TextStyle(
                        fontFamily: 'Lama Sans',
                        fontWeight: FontWeight.w600,
                        fontSize: 14.sp,
                        color: const Color(0xFF9CA3AF),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14.r),
                        borderSide: BorderSide(
                          color: const Color(0xFF7FB2E4).withValues(alpha: 0.55),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14.r),
                        borderSide: BorderSide(
                          color: const Color(0xFF7FB2E4).withValues(alpha: 0.5),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14.r),
                        borderSide: const BorderSide(
                          color: Color(0xFF5993FF),
                          width: 2,
                        ),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 14.h,
                      ),
                    ),
                  ),
                  SizedBox(height: 22.h),
                  Row(
                    textDirection: TextDirection.rtl,
                    children: [
                      Expanded(
                        child: FilledButton(
                          onPressed: () {
                            final t = c.text.trim();
                            if (t.isEmpty) {
                              Get.snackbar(
                                'حقل فارغ',
                                'يرجى تعبئة الحقل قبل الإضافة',
                                snackPosition: SnackPosition.BOTTOM,
                              );
                              return;
                            }
                            Navigator.of(ctx).pop(t);
                          },
                          style: FilledButton.styleFrom(
                            minimumSize: Size.fromHeight(48.h),
                            backgroundColor: const Color(0xFF5993FF),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                          ),
                          child: Text(
                            'إضافة',
                            style: TextStyle(
                              fontFamily: 'Lama Sans',
                              fontWeight: FontWeight.w800,
                              fontSize: 16.sp,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          style: OutlinedButton.styleFrom(
                            minimumSize: Size.fromHeight(48.h),
                            side: const BorderSide(color: Color(0xFF5993FF)),
                            foregroundColor: const Color(0xFF5993FF),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
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
                ],
              ),
            ),
          ),
        ),
      );
    } finally {
      _disposeControllersAfterModal([c]);
    }
  }

  Future<void> _addEducationEntry() => _openEducationSheet();

  Future<void> _openEducationSheet({int? editIndex}) async {
    if (_educationOptions.isEmpty) {
      Get.snackbar(
        'لا توجد خيارات تعليم',
        'تعذر تحميل أنواع الشهادات من الخادم. تحقق من الاتصال وحاول لاحقاً.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    if (!mounted) return;

    _EducationFormEntry? existing;
    if (editIndex != null) {
      final e = _educationEntries.value;
      if (editIndex >= 0 && editIndex < e.length) {
        existing = e[editIndex];
      }
    }

    final years = List<String>.generate(61, (i) => '${1990 + i}');
    String degree = _educationOptions.first;
    if (existing != null && _educationOptions.contains(existing.degreeLabel)) {
      degree = existing.degreeLabel;
    }
    String specialty = existing?.specialty.trim() ?? '';
    final uniList = List<String>.from(
      _universityOptions.isNotEmpty
          ? _universityOptions
          : const <String>['جامعة بغداد'],
    );
    if (existing != null) {
      final u = existing.university.trim();
      if (u.isNotEmpty && !uniList.contains(u)) {
        uniList.insert(0, u);
      }
    }
    String university = uniList.first;
    if (existing != null && existing.university.trim().isNotEmpty) {
      university = existing.university.trim();
    }
    String startYear = existing?.startYear.trim() ?? '';
    String graduationYear = existing?.graduationYear.trim() ?? '';

    final specialtyItems = List<String>.from(_educationSpecialtyOptions);
    if (existing != null) {
      final sp = existing.specialty.trim();
      if (sp.isNotEmpty && !specialtyItems.contains(sp)) {
        specialtyItems.insert(0, sp);
      }
    }

    final sheetTitle = existing == null ? 'أضافة تعليم جديد' : 'تعديل التعليم';

    final result = await showModalBottomSheet<_EducationFormEntry>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModal) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: Container(
                width: double.infinity,
                constraints: BoxConstraints(maxHeight: 598.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDFDFD),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(32.r),
                    topRight: Radius.circular(32.r),
                  ),
                ),
                padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 20.h),
                child: ListView(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  children: [
                        Center(
                          child: Container(
                            width: 56.w,
                            height: 5.h,
                            decoration: BoxDecoration(
                              color: const Color(0xFFD9D9D9),
                              borderRadius: BorderRadius.circular(100.r),
                            ),
                          ),
                        ),
                        SizedBox(height: 20.h),
                        Text(
                          sheetTitle,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Lama Sans',
                            fontWeight: FontWeight.w800,
                            fontSize: 20.sp,
                            height: 1.0,
                            color: const Color(0xFF040814),
                          ),
                        ),
                        SizedBox(height: 22.h),
                        _requiredLabel('نوع الشهادة'),
                        SizedBox(height: 8.h),
                        _sheetSelectField(
                          value: degree,
                          onTap: () async {
                            final picked = await _addFromBottomSheet(
                              title: 'اختيار نوع الشهادة',
                              items: _educationOptions,
                              selected: degree,
                              leadingIconUnselected: Icons.school_outlined,
                            );
                            if (picked != null) {
                              setModal(() => degree = picked);
                            }
                          },
                        ),
                        SizedBox(height: 14.h),
                        _requiredLabel('الجامعة'),
                        SizedBox(height: 8.h),
                        _sheetSelectField(
                          value: university,
                          onTap: () async {
                            final picked = await _addFromBottomSheet(
                              title: 'اختيار الجامعة',
                              items: uniList,
                              selected: university,
                              leadingIconUnselected: Icons.school_outlined,
                            );
                            if (picked != null) {
                              setModal(() => university = picked);
                            }
                          },
                        ),
                        SizedBox(height: 14.h),
                        _requiredLabel('التخصص'),
                        SizedBox(height: 8.h),
                        _sheetSelectField(
                          value: specialty.isEmpty ? 'اختر التخصص' : specialty,
                          isPlaceholder: specialty.isEmpty,
                          onTap: () async {
                            final picked = await _addFromBottomSheet(
                              title: 'اختيار التخصص',
                              items: specialtyItems,
                              selected: specialty.isEmpty ? null : specialty,
                              leadingIconUnselected: Icons.medical_services_outlined,
                            );
                            if (picked != null) {
                              setModal(() => specialty = picked);
                            }
                          },
                        ),
                        SizedBox(height: 14.h),
                        _requiredLabel('سنوات الدراسة'),
                        SizedBox(height: 8.h),
                        Row(
                          children: [
                            Expanded(
                              child: _sheetSelectField(
                                value: graduationYear.isEmpty
                                    ? 'سنة التخرج'
                                    : graduationYear,
                                isPlaceholder: graduationYear.isEmpty,
                                onTap: () async {
                                  final picked = await _addFromBottomSheet(
                                    title: 'سنة التخرج',
                                    items: years,
                                    selected: graduationYear.isEmpty
                                        ? null
                                        : graduationYear,
                                    leadingIconUnselected:
                                        Icons.calendar_today_outlined,
                                  );
                                  if (picked != null) {
                                    setModal(() => graduationYear = picked);
                                  }
                                },
                              ),
                            ),
                            SizedBox(width: 10.w),
                            Expanded(
                              child: _sheetSelectField(
                                value: startYear.isEmpty ? 'سنة البداية' : startYear,
                                isPlaceholder: startYear.isEmpty,
                                onTap: () async {
                                  final picked = await _addFromBottomSheet(
                                    title: 'سنة البداية',
                                    items: years,
                                    selected:
                                        startYear.isEmpty ? null : startYear,
                                    leadingIconUnselected:
                                        Icons.calendar_today_outlined,
                                  );
                                  if (picked != null) {
                                    setModal(() => startYear = picked);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 22.h),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.of(ctx).pop(),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(
                                    color: Color(0xFFFF7345),
                                  ),
                                  foregroundColor: const Color(0xFFFF7345),
                                  minimumSize: Size.fromHeight(52.h),
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
                            SizedBox(width: 10.w),
                            Expanded(
                              child: FilledButton(
                                onPressed: () {
                                  if (specialty.trim().isEmpty) {
                                    Get.snackbar(
                                      'تخصص مطلوب',
                                      'اختر التخصص قبل الحفظ',
                                      snackPosition: SnackPosition.BOTTOM,
                                    );
                                    return;
                                  }
                                  Navigator.of(ctx).pop(
                                    _EducationFormEntry(
                                      degreeLabel: degree,
                                      specialty: specialty.trim(),
                                      university: university.trim(),
                                      startYear: startYear.trim(),
                                      graduationYear: graduationYear.trim(),
                                    ),
                                  );
                                },
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFFFF7345),
                                  foregroundColor: Colors.white,
                                  minimumSize: Size.fromHeight(52.h),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14.r),
                                  ),
                                ),
                                child: Text(
                                  'حفظ',
                                  style: TextStyle(
                                    fontFamily: 'Lama Sans',
                                    fontWeight: FontWeight.w900,
                                    fontSize: 18.sp,
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
    if (result != null && mounted) {
      final cur = List<_EducationFormEntry>.from(_educationEntries.value);
      if (editIndex != null && editIndex >= 0 && editIndex < cur.length) {
        cur[editIndex] = result;
      } else {
        cur.add(result);
      }
      _educationEntries.value = cur;
    }
  }

  void _removeLanguageAt(int index) {
    final list = List<TextEditingController>.from(_languageControllers.value);
    if (index < 0 || index >= list.length) return;
    final removed = list.removeAt(index);
    removed.dispose();
    _languageControllers.value = list;
  }

  String? _yearFromIso(String? iso) {
    if (iso == null || iso.trim().length < 4) return null;
    final y = iso.trim().substring(0, 4);
    return RegExp(r'^\d{4}$').hasMatch(y) ? y : null;
  }

  String? _yearToIsoDateStart(String y) {
    final n = int.tryParse(y.trim());
    if (n == null || n < 1900 || n > 2100) return null;
    return '${n.toString().padLeft(4, '0')}-01-01';
  }

  String? _yearToIsoDateEnd(String y) {
    final n = int.tryParse(y.trim());
    if (n == null || n < 1900 || n > 2100) return null;
    return '${n.toString().padLeft(4, '0')}-12-31';
  }

  Future<void> _showAddExperienceDialog() async => _openExperienceSheet();

  Future<void> _openExperienceSheet({int? editIndex}) async {
    if (!mounted) return;
    final years = List<String>.generate(71, (i) => '${1960 + i}');
    const roleOptions = <String>[
      'مساعد طبيب',
      'متدرب',
      'طبيب أسنان',
      'أخصائي',
    ];
    _ExperienceFormEntry? existing;
    if (editIndex != null) {
      final e = _experienceEntries.value;
      if (editIndex >= 0 && editIndex < e.length) {
        existing = e[editIndex];
      }
    }
    final roleChoices = List<String>.from(roleOptions);
    if (existing != null) {
      final r = existing.role.trim();
      if (r.isNotEmpty && !roleChoices.contains(r)) {
        roleChoices.insert(0, r);
      }
    }
    final workplace = TextEditingController(text: existing?.workplace ?? '');
    String role = roleChoices.first;
    if (existing != null && existing.role.trim().isNotEmpty) {
      role = existing.role.trim();
    }
    String startYear = existing?.startYear.trim() ?? '';
    String endYear = existing?.endYear.trim() ?? '';
    bool isCurrent = existing?.isCurrent ?? true;
    if (isCurrent) {
      endYear = '';
    }
    final sheetTitle = existing == null ? 'أضافة خبرة جديدة' : 'تعديل الخبرة';
    try {
      final result = await showModalBottomSheet<_ExperienceFormEntry>(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (ctx) {
          return StatefulBuilder(
            builder: (ctx, setModal) {
              return Directionality(
                textDirection: TextDirection.rtl,
                child: Container(
                  width: 393.w,
                  constraints: BoxConstraints(maxHeight: 587.h),
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
                  padding: EdgeInsets.fromLTRB(28.w, 10.h, 28.w, 44.h),
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
                        SizedBox(height: 28.h),
                        Text(
                          sheetTitle,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Lama Sans',
                            fontWeight: FontWeight.w800,
                            fontSize: 20.sp,
                            height: 1.0,
                            letterSpacing: 0,
                            color: const Color(0xFF040814),
                          ),
                        ),
                        SizedBox(height: 26.h),
                        _requiredLabel('أسم مكان العمل'),
                        SizedBox(height: 8.h),
                        _Field(
                          controller: workplace,
                          topInfoStyle: true,
                        ),
                        SizedBox(height: 14.h),
                        _requiredLabel('التخصص'),
                        SizedBox(height: 8.h),
                        _sheetSelectField(
                          value: role,
                          onTap: () async {
                            final picked = await _addFromBottomSheet(
                              title: 'اختيار التخصص',
                              items: roleChoices,
                              selected: role,
                              leadingIconUnselected: Icons.work_outline,
                            );
                            if (picked != null) {
                              setModal(() => role = picked);
                            }
                          },
                        ),
                        SizedBox(height: 14.h),
                        _requiredLabel('سنوات العمل'),
                        SizedBox(height: 8.h),
                        Row(
                          children: [
                            Expanded(
                              child: _sheetSelectField(
                                value: startYear.isEmpty ? 'سنة بدء العمل' : startYear,
                                onTap: () async {
                                  final picked = await _addFromBottomSheet(
                                    title: 'سنة بدء العمل',
                                    items: years,
                                    selected: startYear.isEmpty ? null : startYear,
                                    leadingIconUnselected: Icons.calendar_today_outlined,
                                  );
                                  if (picked != null) {
                                    setModal(() => startYear = picked);
                                  }
                                },
                              ),
                            ),
                            SizedBox(width: 10.w),
                            Expanded(
                              child: _sheetSelectField(
                                value: isCurrent
                                    ? 'سنة ترك العمل'
                                    : (endYear.isEmpty ? 'سنة ترك العمل' : endYear),
                                onTap: () async {
                                  final picked = await _addFromBottomSheet(
                                    title: 'سنة ترك العمل',
                                    items: years,
                                    selected: endYear.isEmpty ? null : endYear,
                                    leadingIconUnselected:
                                        Icons.calendar_today_outlined,
                                  );
                                  if (picked != null) {
                                    setModal(() {
                                      endYear = picked;
                                      isCurrent = false;
                                    });
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 14.h),
                        Row(
                          children: [
                            Checkbox(
                              value: isCurrent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6.r),
                              ),
                              onChanged: (v) {
                                setModal(() {
                                  isCurrent = v ?? false;
                                  if (isCurrent) endYear = '';
                                });
                              },
                            ),
                            Expanded(
                              child: Text(
                                'تعيين ك مكان العمل الحالي',
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  fontFamily: 'Lama Sans',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15.sp,
                                  color: const Color(0xFF757A80),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 18.h),
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton(
                                onPressed: () {
                                  final wp = workplace.text.trim();
                                  if (wp.isEmpty) {
                                    Get.snackbar(
                                      'مكان العمل',
                                      'أدخل اسم مكان العمل',
                                      snackPosition: SnackPosition.BOTTOM,
                                    );
                                    return;
                                  }
                                  if (role.trim().isEmpty) {
                                    Get.snackbar(
                                      'التخصص',
                                      'اختر نوع الخبرة',
                                      snackPosition: SnackPosition.BOTTOM,
                                    );
                                    return;
                                  }
                                  if (startYear.trim().isEmpty) {
                                    Get.snackbar(
                                      'سنوات العمل',
                                      'اختر سنة بدء العمل',
                                      snackPosition: SnackPosition.BOTTOM,
                                    );
                                    return;
                                  }
                                  if (!isCurrent && endYear.trim().isEmpty) {
                                    Get.snackbar(
                                      'سنوات العمل',
                                      'اختر سنة ترك العمل أو فعّل «مكان العمل الحالي»',
                                      snackPosition: SnackPosition.BOTTOM,
                                    );
                                    return;
                                  }
                                  Navigator.of(ctx).pop(
                                    _ExperienceFormEntry(
                                      workplace: wp,
                                      role: role.trim(),
                                      startYear: startYear.trim(),
                                      endYear: isCurrent ? '' : endYear.trim(),
                                      isCurrent: isCurrent,
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
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 16.w),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.of(ctx).pop(),
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
                                    height: 1.5,
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
      if (result != null && mounted) {
        final cur = List<_ExperienceFormEntry>.from(_experienceEntries.value);
        if (editIndex != null && editIndex >= 0 && editIndex < cur.length) {
          cur[editIndex] = result;
        } else {
          cur.add(result);
        }
        _experienceEntries.value = cur;
      }
    } finally {
      _disposeControllersAfterModal([workplace]);
    }
  }

  Widget _requiredLabel(String text) {
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

  Widget _sheetSelectField({
    required String value,
    bool isPlaceholder = false,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          height: 50.h,
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(2.w, 10.h, 8.w, 10.h),
          decoration: BoxDecoration(
            color: const Color(0x70D9D9D9),
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Row(
            children: [
              Container(
                width: 30.w,
                height: 30.w,
                decoration: BoxDecoration(
                  color: const Color(0x225993FF),
                  borderRadius: BorderRadius.circular(9.r),
                ),
                child: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 22.sp,
                  color: const Color(0xFF1F2937),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                  style: TextStyle(
                    fontFamily: 'Lama Sans',
                    fontWeight: FontWeight.w700,
                    fontSize: 14.sp,
                    color: isPlaceholder
                        ? const Color(0xFF6B7280)
                        : const Color(0xFF040814),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<String?> _addFromBottomSheet({
    required String title,
    required List<String> items,
    required String? selected,
    required IconData leadingIconUnselected,
  }) {
    FocusScope.of(context).unfocus();
    return showModalBottomSheet<String>(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final maxScreenHeight = MediaQuery.of(ctx).size.height;
        final sheetH = (maxScreenHeight * 0.62).clamp(320.0, 560.0);
        return Directionality(
          textDirection: TextDirection.rtl,
          child: SizedBox(
            height: sheetH,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFFDFEFF),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1A040814),
                    blurRadius: 16,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              padding: EdgeInsets.fromLTRB(18.w, 10.h, 18.w, 16.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 51.w,
                      height: 5.h,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD1D5DB),
                        borderRadius: BorderRadius.circular(2.r),
                      ),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Lama Sans',
                      fontWeight: FontWeight.w800,
                      fontSize: 18.sp,
                      color: const Color(0xFF040814),
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Expanded(
                    child: ListView.separated(
                      physics: const BouncingScrollPhysics(),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => SizedBox(height: 8.h),
                      itemBuilder: (_, i) {
                        final entry = items[i];
                        final isSelected = selected == entry;
                        return Material(
                          color: isSelected
                              ? const Color(0x1A5993FF)
                              : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14.r),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14.r),
                            onTap: () => Navigator.of(ctx).pop(entry),
                            child: Container(
                              height: 50.h,
                              padding: EdgeInsets.symmetric(horizontal: 14.w),
                              child: Row(
                                children: [
                                  if (isSelected)
                                    Icon(
                                      Icons.check_circle_rounded,
                                      color: const Color(0xFF5993FF),
                                      size: 20.sp,
                                    )
                                  else
                                    Icon(
                                      leadingIconUnselected,
                                      color: const Color(0xFF9CA3AF),
                                      size: 20.sp,
                                    ),
                                  SizedBox(width: 8.w),
                                  Expanded(
                                    child: Text(
                                      entry,
                                      style: TextStyle(
                                        fontFamily: 'Lama Sans',
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15.sp,
                                        color: const Color(0xFF040814),
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
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickAvatarAndPreview() async {
    if (_avatarBusyNv.value || !mounted) return;
    if (kIsWeb) {
      Get.snackbar(
        'غير مدعوم على المتصفح',
        'استخدم تطبيق الهاتف لتعديل الصورة والاقتصاص.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    FocusScope.of(context).unfocus();
    try {
      await Future<void>.delayed(const Duration(milliseconds: 200));
      if (!mounted) return;
      final x = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 92,
        requestFullMetadata: false,
      );
      if (x == null || !mounted) return;

      final cropped = await ImageCropper().cropImage(
        sourcePath: x.path,
        maxWidth: 2048,
        maxHeight: 2048,
        compressQuality: 88,
        compressFormat: ImageCompressFormat.jpg,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'اقتصاص الصورة',
            toolbarColor: const Color(0xFF5993FF),
            toolbarWidgetColor: Colors.white,
            activeControlsWidgetColor: const Color(0xFFFF9914),
            lockAspectRatio: false,
            initAspectRatio: CropAspectRatioPreset.original,
            aspectRatioPresets: const [
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPreset.ratio16x9,
            ],
          ),
          IOSUiSettings(
            title: 'اقتصاص الصورة',
            aspectRatioLockEnabled: false,
            doneButtonTitle: 'تم',
            cancelButtonTitle: 'إلغاء',
            aspectRatioPresets: const [
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio4x3,
            ],
          ),
        ],
      );
      if (cropped == null || !mounted) return;

      _avatarBusyNv.value = true;
      final uploaded = await ApiService.instance.uploadProfileImage(
        filePath: cropped.path,
        purpose: 'avatar',
      );
      if (!mounted) return;
      final u = uploaded.trim();
      if (u.isEmpty) return;
      _avatarPickedUrlNv.value = u;
    } on MissingPluginException catch (_, st) {
      debugPrint('image_picker plugin: $st');
      if (mounted) {
        Get.snackbar(
          'أعد بناء التطبيق',
          'أوقف التشغيل ثم شغّل من جديد (flutter run).',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 5),
        );
      }
    } on PlatformException catch (e, st) {
      debugPrint('image_picker: ${e.code} ${e.message}\n$st');
      if (mounted) {
        Get.snackbar(
          'تعذر فتح المعرض',
          e.message ?? e.toString(),
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        Get.snackbar(
          'تعذر رفع الصورة',
          e.message,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e, st) {
      debugPrint('pick/upload avatar: $e\n$st');
      if (mounted) {
        Get.snackbar(
          'تعذر رفع الصورة',
          e.toString(),
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } finally {
      if (mounted) _avatarBusyNv.value = false;
    }
  }

  Future<void> _saveProfile() async {
    if (_isSaving) return;
    final specialty = (_selectedSpecialtyNv.value ?? '').trim();
    final governorate = (_selectedGovernorateNv.value ?? _city.text).trim();
    final phone = _phone.text.trim();
    if (!RegExp(r'^07\d{9}$').hasMatch(phone)) {
      Get.snackbar(
        'رقم هاتف غير صالح',
        'أدخل رقم هاتف من 11 رقم يبدأ بـ 07 (بدون كود دولة)',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    final ageVal = int.tryParse(_age.text.trim());
    if (ageVal == null || ageVal < 1 || ageVal > 120) {
      Get.snackbar(
        'العمر',
        'أدخل عمراً صحيحاً بين 1 و 120',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    final bioRaw = _bio.text;
    final bioSignificant = _bioNonWhitespaceCount(bioRaw);
    if (bioSignificant == 0) {
      if (bioRaw.isEmpty) {
        Get.snackbar(
          'النبذة التعريفية',
          'يرجى كتابة نبذة من $_kBioMinSignificantChars أحرف على الأقل (المسافات لا تُحتسب).',
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        Get.snackbar(
          'النبذة التعريفية',
          'لا يمكن حفظ نص يحتوي على مسافات فقط. أدخل أحرفاً فعلية (المسافات لا تُحتسب ضمن العدد).',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
      return;
    }
    if (bioSignificant < _kBioMinSignificantChars) {
      Get.snackbar(
        'النبذة التعريفية',
        'يجب أن تحتوي النبذة على $_kBioMinSignificantChars حرفاً على الأقل دون احتساب المسافات (لديك الآن $bioSignificant).',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    final languages = _languageControllers.value
        .map((c) => c.text.trim())
        .where((v) => v.isNotEmpty)
        .toSet()
        .toList();
    final skillIds = _skillControllers.value
        .map((c) => c.text.trim())
        .where((v) => v.isNotEmpty)
        .toSet()
        .toList();
    final education = _educationEntries.value
        .map((e) {
          final degree = _educationApiFromLabel(e.degreeLabel);
          if (degree == null) return null;
          final uni = e.university.trim();
          final start = int.tryParse(e.startYear.trim());
          final grad = int.tryParse(e.graduationYear.trim());
          return <String, dynamic>{
            'degree_type': degree,
            'specialty': e.specialty.trim(),
            'university': uni.isEmpty ? 'غير محدد' : uni,
            'start_year': start,
            'graduation_year': grad,
          };
        })
        .whereType<Map<String, dynamic>>()
        .toList();

    final experiences = _experienceEntries.value
        .where((e) => e.workplace.trim().isNotEmpty)
        .map((e) {
          final start = _yearToIsoDateStart(e.startYear);
          final end = e.isCurrent ? null : _yearToIsoDateEnd(e.endYear);
          return <String, dynamic>{
            'experience_type': e.role.trim(),
            'workplace': e.workplace.trim(),
            if (start != null) 'period_start': start,
            'period_end': end,
          };
        })
        .toList();

    final gallery = <Map<String, dynamic>>[];
    for (final c in _clinicalCaseEntries.value) {
      final imgs = c.imageUrls
          .map(stripMediaToApiPath)
          .where((s) => s.isNotEmpty)
          .take(kMaxClinicalCaseImages)
          .toList();
      if (imgs.isEmpty) continue;
      final t = c.title.trim();
      final d = c.description.trim();
      final caption = d.isEmpty ? t : '$t\n\n$d';
      gallery.add({
        'caption': caption,
        'images': imgs,
      });
    }

    final certificateImages = <Map<String, dynamic>>[];
    for (final c in _certificateEntries.value) {
      final t = c.title.trim();
      final iss = c.issuer.trim();
      for (final u in c.imageUrls) {
        final path = stripMediaToApiPath(u);
        if (path.isEmpty) continue;
        certificateImages.add({
          'url': path,
          if (t.isNotEmpty) 'title': t,
          if (iss.isNotEmpty) 'issuer': iss,
        });
      }
    }

    setState(() => _isSaving = true);
    try {
      final body = <String, dynamic>{
        'name': _name.text.trim(),
        'professional_title': specialty,
        'governorate': governorate,
        'phone': phone,
        'email': _email.text.trim(),
        'age': ageVal,
        'years_experience': _yearsExperience.value,
        'bio': _bio.text.trim(),
        'languages': languages,
        'skill_ids': skillIds,
        'education': education,
        'experiences': experiences,
        'gallery': gallery,
        'certificate_images': certificateImages,
      };
      final pickedAvatar = (_avatarPickedUrlNv.value ?? '').trim();
      if (pickedAvatar.isNotEmpty) {
        final imgPath = stripMediaToApiPath(pickedAvatar);
        if (imgPath.isNotEmpty) {
          body['imageUrl'] = imgPath;
        }
      }
      await ApiService.instance.patchDoctorProfile(body: body);
      if (!mounted) return;
      if (Get.isRegistered<HomeController>()) {
        unawaited(Get.find<HomeController>().loadProfile());
      }
      if (mounted) setState(() => _isSaving = false);
      if (!mounted) return;
      await ProfileSaveSuccessDialog.show(
        onConfirm: () => Get.back(result: true),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      Get.snackbar(
        'تعذر الحفظ',
        e.message,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      if (!mounted) return;
      Get.snackbar(
        'تعذر الحفظ',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _hydrationCancelled = true;
    _yearsExperience.dispose();
    _educationEntries.dispose();
    _clinicalCaseEntries.dispose();
    _certificateEntries.dispose();
    _experienceEntries.dispose();
    _selectedSpecialtyNv.dispose();
    _selectedGovernorateNv.dispose();
    _avatarPickedUrlNv.dispose();
    _avatarBusyNv.dispose();
    for (final c in _languageControllers.value) {
      c.dispose();
    }
    _languageControllers.dispose();
    for (final c in _skillControllers.value) {
      c.dispose();
    }
    _skillControllers.dispose();
    _name.dispose();
    _city.dispose();
    _phone.dispose();
    _email.dispose();
    _age.dispose();
    _bio.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F6F8),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF5F6F8),
          elevation: 0,
          scrolledUnderElevation: 0,
          automaticallyImplyLeading: false,
          centerTitle: true,
          title: Text(
            'تعديل البروفايل المهني',
            style: TextStyle(
              fontFamily: 'Lama Sans',
              fontWeight: FontWeight.w800,
              fontSize: 20.sp,
              height: 1.5,
              color: const Color(0xFF040814),
            ),
          ),
          actions: [
            Padding(
              padding: EdgeInsets.only(left: 8.w),
              child: AppBackButton(
                size: 38.w,
                iconSize: 22.sp,
                iconColor: const Color(0xFF040814),
                onTap: () => Get.back(),
              ),
            ),
          ],
        ),
        body: SafeArea(
          top: false,
          child: !_formReady
              ? Center(
                  child: SizedBox(
                    width: 36.w,
                    height: 36.w,
                    child: const CircularProgressIndicator(
                      strokeWidth: 3,
                      color: Color(0xFF5993FF),
                    ),
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: ListView.separated(
                        cacheExtent: 0,
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(14.w, 8.h, 14.w, 20.h),
                        itemCount: 6,
                        separatorBuilder: (context, index) =>
                            SizedBox(height: 14.h),
                        itemBuilder: (context, index) {
                          switch (index) {
                            case 0:
                              return RepaintBoundary(
                                child: AnimatedBuilder(
                                  animation: Listenable.merge(<Listenable>[
                                    _selectedSpecialtyNv,
                                    _selectedGovernorateNv,
                                    _avatarPickedUrlNv,
                                    _avatarBusyNv,
                                  ]),
                                  builder: (context, _) {
                                    final avatarUrl = resolveMediaUrl(
                                      _avatarPickedUrlNv.value ??
                                          widget.initialProfile?.imageUrl,
                                    );
                                    return _ProfileEditBasicInfoSection(
                                      avatarUrl: avatarUrl,
                                      avatarBusyListenable: _avatarBusyNv,
                                      onAvatarEdit: _pickAvatarAndPreview,
                                      nameController: _name,
                                      phoneController: _phone,
                                      emailController: _email,
                                      ageController: _age,
                                      specialtyValue: _selectedSpecialtyNv.value,
                                      specialtyOptions: _specialties,
                                      onSpecialtyChanged: (v) {
                                        _selectedSpecialtyNv.value = v;
                                      },
                                      governorateValue: _selectedGovernorateNv.value,
                                      governorateOptions: _governorates,
                                      onGovernorateChanged: (v) {
                                        _selectedGovernorateNv.value = v;
                                        _city.text = v ?? '';
                                      },
                                      yearsNotifier: _yearsExperience,
                                    );
                                  },
                                ),
                              );
                            case 1:
                              return RepaintBoundary(
                                child: SizedBox(
                                  width: 353.w,
                                  child: _MultiTextSection(
                                    title: 'نبذة تعريفية',
                                    controllers: [_bio],
                                    sectionGap: 12,
                                    useBioFieldStyle: true,
                                  ),
                                ),
                              );
                            case 2:
                              return RepaintBoundary(
                                child: ValueListenableBuilder<List<_EducationFormEntry>>(
                                  valueListenable: _educationEntries,
                                  builder: (context, entries, _) {
                                    return _EducationSection(
                                      entries: entries,
                                      onAdd: _addEducationEntry,
                                      onTapEntry: (i) => _openEducationSheet(editIndex: i),
                                    );
                                  },
                                ),
                              );
                            case 3:
                              return RepaintBoundary(
                                child: ValueListenableBuilder<List<TextEditingController>>(
                                  valueListenable: _languageControllers,
                                  builder: (context, ctrls, _) {
                                    return _LanguagesSection(
                                      title: 'اللغات',
                                      controllers: ctrls,
                                      onRemoveAt: _removeLanguageAt,
                                      onAdd: () => _addFromOptions(
                                        options: _languageOptions,
                                        controllersNotifier: _languageControllers,
                                        allowOther: true,
                                        title: 'لغة أخرى',
                                        otherPrompt: 'اكتب اللغة',
                                      ),
                                    );
                                  },
                                ),
                              );
                            case 4:
                              return RepaintBoundary(
                                child: ValueListenableBuilder<List<TextEditingController>>(
                                  valueListenable: _skillControllers,
                                  builder: (context, ctrls, _) {
                                    return _SkillsSection(
                                      title: 'المهارات الأساسية',
                                      controllers: ctrls,
                                      addLabel: 'أضف مهارة جديدة +',
                                      onAdd: _showAddSkillDialog,
                                    );
                                  },
                                ),
                              );
                            case 5:
                              return RepaintBoundary(
                                child: ValueListenableBuilder<List<_ExperienceFormEntry>>(
                                  valueListenable: _experienceEntries,
                                  builder: (context, entries, _) {
                                    return _ExperiencesSection(
                                      title: 'الخبرات',
                                      entries: entries,
                                      onAdd: _showAddExperienceDialog,
                                      onTapEntry: (i) => _openExperienceSheet(editIndex: i),
                                    );
                                  },
                                ),
                              );
                            default:
                              return const SizedBox.shrink();
                          }
                        },
                      ),
                    ),
                    _BottomActions(
                      onSave: _saveProfile,
                      onCancel: Get.back,
                      isSaving: _isSaving,
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// قسم البيانات الأساسية معزول ليعيد التخطيط/الرسم دون بقية الصفحة؛ سنوات الخبرة عبر [ValueNotifier] دون setState.
class _ProfileEditBasicInfoSection extends StatelessWidget {
  const _ProfileEditBasicInfoSection({
    required this.avatarUrl,
    required this.avatarBusyListenable,
    required this.onAvatarEdit,
    required this.nameController,
    required this.phoneController,
    required this.emailController,
    required this.ageController,
    required this.specialtyValue,
    required this.specialtyOptions,
    required this.onSpecialtyChanged,
    required this.governorateValue,
    required this.governorateOptions,
    required this.onGovernorateChanged,
    required this.yearsNotifier,
  });

  final String avatarUrl;
  final ValueNotifier<bool> avatarBusyListenable;
  final VoidCallback onAvatarEdit;
  final TextEditingController nameController;
  final TextEditingController phoneController;
  final TextEditingController emailController;
  final TextEditingController ageController;
  final String? specialtyValue;
  final List<String> specialtyOptions;
  final ValueChanged<String?> onSpecialtyChanged;
  final String? governorateValue;
  final List<String> governorateOptions;
  final ValueChanged<String?> onGovernorateChanged;
  final ValueNotifier<int> yearsNotifier;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 7.h),
          _RepaintedProfileAvatar(
            avatarUrl: avatarUrl,
            busyListenable: avatarBusyListenable,
            onEdit: onAvatarEdit,
          ),
          SizedBox(height: 14.h),
          _Field(controller: nameController, topInfoStyle: true),
          SizedBox(height: 6.h),
          _SpecialtyField(
            value: specialtyValue,
            options: specialtyOptions,
            onChanged: onSpecialtyChanged,
          ),
          SizedBox(height: 6.h),
          _GovernorateField(
            value: governorateValue,
            options: governorateOptions,
            onChanged: onGovernorateChanged,
          ),
          SizedBox(height: 6.h),
          _Field(
            controller: phoneController,
            keyboardType: TextInputType.phone,
            topInfoStyle: true,
            maxLength: 11,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(11),
            ],
          ),
          SizedBox(height: 6.h),
          _Field(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            topInfoStyle: true,
          ),
          SizedBox(height: 6.h),
          _Field(
            controller: ageController,
            keyboardType: TextInputType.number,
            topInfoStyle: true,
            maxLength: 3,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(3),
            ],
            hintText: 'العمر',
          ),
          SizedBox(height: 16.h),
          ValueListenableBuilder<int>(
            valueListenable: yearsNotifier,
            builder: (context, years, _) {
              return _YearsEditor(
                years: years,
                onMinus: () {
                  yearsNotifier.value = (yearsNotifier.value - 1).clamp(0, 80);
                },
                onPlus: () {
                  yearsNotifier.value = (yearsNotifier.value + 1).clamp(0, 80);
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

/// يعزل رسم الصورة الشخصية عن حقول النموذج لتقليل إعادة الرسم عند التحديث.
class _RepaintedProfileAvatar extends StatelessWidget {
  const _RepaintedProfileAvatar({
    required this.avatarUrl,
    required this.busyListenable,
    required this.onEdit,
  });

  final String avatarUrl;
  final ValueNotifier<bool> busyListenable;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: _AvatarEditor(
        avatarUrl: avatarUrl,
        busyListenable: busyListenable,
        onEdit: onEdit,
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: const Color(0xFFFDFEFF),
        borderRadius: BorderRadius.circular(22.r),
        boxShadow: const [
          BoxShadow(
            color: Color(0x29040814),
            offset: Offset(0, 0),
            blurRadius: 6,
            spreadRadius: 0,
          ),
        ],
      ),
      child: child,
    );
  }
}

class _AvatarEditor extends StatelessWidget {
  const _AvatarEditor({
    required this.avatarUrl,
    required this.busyListenable,
    required this.onEdit,
  });

  final String avatarUrl;
  final ValueNotifier<bool> busyListenable;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final size = 67.w;
    final cachePx = (size * MediaQuery.of(context).devicePixelRatio).round().clamp(48, 2048);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x29000000),
                    offset: Offset(0, 0),
                    blurRadius: 9.8,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: ClipOval(
                child: avatarUrl.isEmpty
                    ? Container(
                        color: Colors.white,
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.person_rounded,
                          size: 30.sp,
                          color: const Color(0xFF9CA3AF),
                        ),
                      )
                    : CachedNetworkImage(
                        imageUrl: avatarUrl,
                        width: size,
                        height: size,
                        fit: BoxFit.cover,
                        alignment: Alignment.center,
                        memCacheWidth: cachePx,
                        fadeInDuration: Duration.zero,
                        fadeOutDuration: Duration.zero,
                        placeholder: (context, url) => Container(
                          color: Colors.white,
                          alignment: Alignment.center,
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: const Color(0xFF9CA3AF).withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) {
                          return Container(
                            color: Colors.white,
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.person_rounded,
                              size: 30.sp,
                              color: const Color(0xFF9CA3AF),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ),
          ValueListenableBuilder<bool>(
            valueListenable: busyListenable,
            builder: (context, busy, _) {
              if (!busy) return const SizedBox.shrink();
              return Positioned.fill(
                child: ClipOval(
                  child: ColoredBox(
                    color: Colors.black.withValues(alpha: 0.35),
                    child: Center(
                      child: SizedBox(
                        width: 24.w,
                        height: 24.w,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          Positioned(
            left: 0,
            bottom: 0,
            child: ValueListenableBuilder<bool>(
              valueListenable: busyListenable,
              builder: (context, busy, _) {
                return Material(
                  color: const Color(0xFF5993FF),
                  shape: const CircleBorder(),
                  elevation: 2,
                  shadowColor: const Color(0x405993FF),
                  child: InkWell(
                    onTap: busy ? null : onEdit,
                    customBorder: const CircleBorder(),
                    child: SizedBox(
                      width: 24.w,
                      height: 24.w,
                      child: Icon(
                        Icons.edit_rounded,
                        color: Colors.white,
                        size: 13.sp,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    this.keyboardType,
    this.topInfoStyle = false,
    this.readOnly = false,
    this.hintText,
    this.maxLength,
    this.inputFormatters,
  });
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final bool topInfoStyle;
  final bool readOnly;
  final String? hintText;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: topInfoStyle ? 47.h : null,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: TextField(
          controller: controller,
          keyboardType: keyboardType,
          readOnly: readOnly,
          maxLength: maxLength,
          inputFormatters: inputFormatters,
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.start,
          textAlignVertical: TextAlignVertical.center,
          decoration: InputDecoration(
            filled: true,
            fillColor: topInfoStyle
                ? const Color(0x4DD9D9D9)
                : const Color(0xFFE7E7EA),
            hintText: hintText,
            hintStyle: TextStyle(
              fontFamily: 'Lama Sans',
              fontWeight: FontWeight.w700,
              fontSize: 14.sp,
              height: 1.5,
              color: const Color(0xFF6B7280),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(topInfoStyle ? 12.r : 14.r),
              borderSide: BorderSide.none,
            ),
            counterText: '',
            contentPadding: topInfoStyle
                ? EdgeInsets.fromLTRB(19.w, 17.h, 19.w, 17.h)
                : EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
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

class _SpecialtyField extends StatelessWidget {
  const _SpecialtyField({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String? value;
  final List<String> options;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final entries = <String>[
      ...options,
      if (value != null && value!.trim().isNotEmpty && !options.contains(value))
        value!,
    ];
    final selected = entries.contains(value) ? value : null;
    return ModernPickerField(
      hint: 'اختر التخصص',
      width: double.infinity,
      value: selected,
      icon: Icons.medical_services_rounded,
      enabled: true,
      onTap: () async {
        final picked = await showModernOptionsSheet(
          context: context,
          title: 'اختيار التخصص',
          subtitle: 'اختر تخصصك بدقة لنتائج أفضل',
          icon: Icons.workspace_premium_rounded,
          options: entries,
          selected: selected,
        );
        if (picked != null) onChanged(picked);
      },
    );
  }
}

class _GovernorateField extends StatelessWidget {
  const _GovernorateField({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String? value;
  final List<String> options;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final entries = <String>[
      ...options,
      if (value != null && value!.trim().isNotEmpty && !options.contains(value))
        value!,
    ];
    final selected = entries.contains(value) ? value : null;
    return ModernPickerField(
      hint: 'اختر المحافظة',
      width: double.infinity,
      value: selected,
      icon: Icons.location_on_rounded,
      enabled: true,
      onTap: () async {
        final picked = await showModernOptionsSheet(
          context: context,
          title: 'اختيار المحافظة',
          subtitle: 'اختر المحافظة الأقرب لمكان عملك',
          icon: Icons.location_city_rounded,
          options: entries,
          selected: selected,
        );
        if (picked != null) onChanged(picked);
      },
    );
  }
}

class _YearsEditor extends StatelessWidget {
  const _YearsEditor({
    required this.years,
    required this.onMinus,
    required this.onPlus,
  });
  final int years;
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: EdgeInsets.only(right: 16.w),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                'سنوات الخبرة',
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontFamily: 'Lama Sans',
                  fontWeight: FontWeight.w900,
                  fontSize: 18.sp,
                  color: const Color(0xFF111827),
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: 8.h),
        Row(
          children: [
            _StepButton(isPlus: true, onTap: onPlus),
            SizedBox(width: 8.w),
            Expanded(
              child: Container(
                height: 46.h,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFE7E7EA),
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Text(
                  '$years',
                  style: TextStyle(
                    fontFamily: 'Lama Sans',
                    fontWeight: FontWeight.w700,
                    fontSize: 15.33.sp,
                    height: 1.5,
                    color: const Color(0xFF000000),
                  ),
                ),
              ),
            ),
            SizedBox(width: 8.w),
            _StepButton(isPlus: false, onTap: onMinus),
          ],
        ),
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.isPlus, required this.onTap});
  final bool isPlus;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 86.w,
      height: 46.h,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFC9CDD6)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
          foregroundColor: const Color(0xFF111827),
        ),
        child: _StepGlyph(isPlus: isPlus),
      ),
    );
  }
}

class _StepGlyph extends StatelessWidget {
  const _StepGlyph({required this.isPlus});

  final bool isPlus;

  @override
  Widget build(BuildContext context) {
    final line = DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xE6000000),
        borderRadius: BorderRadius.circular(0.6.r),
      ),
      child: SizedBox(width: 10.55.w, height: 1.h),
    );
    if (!isPlus) return line;
    return SizedBox(
      width: 10.55.w,
      height: 10.55.w,
      child: Stack(
        alignment: Alignment.center,
        children: [
          line,
          Transform.rotate(
            angle: 1.5707963267948966,
            child: line,
          ),
        ],
      ),
    );
  }
}

class _MultiTextSection extends StatelessWidget {
  const _MultiTextSection({
    required this.title,
    required this.controllers,
    this.sectionGap = 10,
    this.useBioFieldStyle = false,
  });
  final String title;
  final List<TextEditingController> controllers;
  final double sectionGap;
  final bool useBioFieldStyle;
  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontFamily: 'Lama Sans',
              fontWeight: FontWeight.w900,
              fontSize: 18.sp,
              color: const Color(0xFF111827),
            ),
          ),
          SizedBox(height: sectionGap.h),
          if (controllers.isEmpty)
            Text(
              'لا توجد عناصر',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontFamily: 'Lama Sans',
                fontSize: 13.sp,
                color: const Color(0xFF6B7280),
              ),
            ),
          ...controllers.map(
            (c) => Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: useBioFieldStyle
                  ? _BioTextField(controller: c, readOnly: false)
                  : _Field(controller: c, readOnly: false),
            ),
          ),
        ],
      ),
    );
  }
}

class _EducationSection extends StatelessWidget {
  const _EducationSection({
    required this.entries,
    required this.onAdd,
    required this.onTapEntry,
  });

  final List<_EducationFormEntry> entries;
  final VoidCallback onAdd;
  final ValueChanged<int> onTapEntry;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.keyboard_arrow_up_rounded,
                size: 24.sp,
                color: const Color(0xFF111827),
              ),
              const Spacer(),
              Text(
                'التعليم',
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontFamily: 'Lama Sans',
                  fontWeight: FontWeight.w900,
                  fontSize: 18.sp,
                  color: const Color(0xFF111827),
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          if (entries.isEmpty)
            Text(
              'لا يوجد تعليم مضاف',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontFamily: 'Lama Sans',
                fontWeight: FontWeight.w600,
                fontSize: 14.sp,
                color: const Color(0xFF6B7280),
              ),
            ),
          ...List.generate(entries.length, (i) {
            final value = entries[i];
            final years = _formatYears(value.startYear, value.graduationYear);
            final degree = value.degreeLabel.trim();
            final specialty = value.specialty.trim();
            final subtitle = [
              if (degree.isNotEmpty) degree,
              if (specialty.isNotEmpty) specialty,
            ].join(' - ');
            final dpr = MediaQuery.devicePixelRatioOf(context);
            final sealPx = (41.3.w * dpr).round().clamp(1, 2048);
            return Padding(
              padding: EdgeInsets.only(bottom: i == entries.length - 1 ? 0 : 8.h),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12.r),
                  onTap: () => onTapEntry(i),
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, 10.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFDFEFF),
                      border: Border(
                        bottom: BorderSide(
                          color: i == entries.length - 1
                              ? Colors.transparent
                              : const Color(0xFFE5E7EB),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          textDirection: TextDirection.rtl,
                          children: [
                            Container(
                              width: 41.3.w,
                              height: 41.3.h,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0x29000000),
                                    blurRadius: 6.05,
                                    spreadRadius: 0,
                                    offset: Offset(0, 0),
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: Image.asset(
                                  _kEduSealAssetPath,
                                  width: 41.3.w,
                                  height: 41.3.h,
                                  fit: BoxFit.cover,
                                  filterQuality: FilterQuality.low,
                                  cacheWidth: sealPx,
                                  cacheHeight: sealPx,
                                ),
                              ),
                            ),
                            SizedBox(width: 10.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    textDirection: TextDirection.rtl,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          value.university.trim().isEmpty
                                              ? 'جامعة غير محددة'
                                              : value.university.trim(),
                                          textAlign: TextAlign.right,
                                          style: TextStyle(
                                            fontFamily: 'Lama Sans',
                                            fontWeight: FontWeight.w700,
                                            fontSize: 15.sp,
                                            color: const Color(0xFF111827),
                                          ),
                                        ),
                                      ),
                                      Text(
                                        years,
                                        style: TextStyle(
                                          fontFamily: 'Lama Sans',
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12.sp,
                                          color: const Color(0xFF6B7280),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 2.h),
                                  Text(
                                    subtitle,
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                      fontFamily: 'Lama Sans',
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14.sp,
                                      color: const Color(0xFF6B7280),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
          SizedBox(height: 12.h),
          DottedBorder(
            color: const Color(0xFFB7BDC8),
            strokeWidth: 1.2,
            radius: Radius.circular(12.r),
            borderType: BorderType.RRect,
            dashPattern: const [6, 4],
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12.r),
                onTap: onAdd,
                child: SizedBox(
                  height: 50.h,
                  child: Center(
                    child: Text(
                      '+ أضف تعليم جديد',
                      style: TextStyle(
                        fontFamily: 'Lama Sans',
                        fontWeight: FontWeight.w700,
                        fontSize: 16.sp,
                        color: const Color(0xFF6B7280),
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
  }

  String _formatYears(String start, String end) {
    final s = start.trim();
    final e = end.trim();
    if (s.isEmpty && e.isEmpty) return '—';
    if (s.isEmpty) return '$e - —';
    if (e.isEmpty) return '— - $s';
    return '$e - $s';
  }
}

class _LanguagesSection extends StatelessWidget {
  const _LanguagesSection({
    required this.title,
    required this.controllers,
    required this.onAdd,
    required this.onRemoveAt,
  });

  final String title;
  final List<TextEditingController> controllers;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemoveAt;

  @override
  Widget build(BuildContext context) {
    final chipWidgets = <Widget>[];
    for (var i = 0; i < controllers.length; i++) {
      final v = controllers[i].text.trim();
      if (v.isEmpty) continue;
      chipWidgets.add(
        SizedBox(
          height: 37.h,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0x4DD9D9D9),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Padding(
              padding: EdgeInsetsDirectional.fromSTEB(4.w, 0, 8.w, 0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                textDirection: TextDirection.rtl,
                children: [
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => onRemoveAt(i),
                      customBorder: const CircleBorder(),
                      child: Padding(
                        padding: EdgeInsets.all(4.r),
                        child: Icon(
                          Icons.close_rounded,
                          size: 18.sp,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ),
                  ),
                  Flexible(
                    child: Text(
                      v,
                      textAlign: TextAlign.right,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: TextStyle(
                        fontFamily: 'Lama Sans',
                        fontWeight: FontWeight.w700,
                        fontSize: 12.sp,
                        height: 1.8,
                        color: const Color(0xFF040814),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(minHeight: 161.h),
        padding: EdgeInsets.all(10.r),
        decoration: BoxDecoration(
          color: const Color(0xFFFDFEFF),
          borderRadius: BorderRadius.circular(22.r),
          boxShadow: const [
            BoxShadow(
              color: Color(0x29040814),
              offset: Offset(0, 0),
              blurRadius: 6,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  Icons.keyboard_arrow_up_rounded,
                  size: 24.sp,
                  color: const Color(0xFF2F2A60),
                ),
                const Spacer(),
                Text(
                  title,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontFamily: 'Lama Sans',
                    fontWeight: FontWeight.w700,
                    fontSize: 16.6.sp,
                    height: 1.5,
                    color: const Color(0xFF040814),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            if (chipWidgets.isNotEmpty)
              Wrap(
                textDirection: TextDirection.rtl,
                spacing: 12.w,
                runSpacing: 12.h,
                alignment: WrapAlignment.start,
                runAlignment: WrapAlignment.start,
                children: chipWidgets,
              ),
            if (chipWidgets.isNotEmpty) SizedBox(height: 12.h),
            DottedBorder(
              color: const Color(0xFFB7BDC8),
              strokeWidth: 1.2,
              radius: Radius.circular(12.r),
              borderType: BorderType.RRect,
              dashPattern: const [6, 4],
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12.r),
                  onTap: onAdd,
                  child: SizedBox(
                    height: 50.h,
                    child: Center(
                      child: Text(
                        '+ أضف لغة جديدة',
                        style: TextStyle(
                          fontFamily: 'Lama Sans',
                          fontWeight: FontWeight.w700,
                          fontSize: 16.sp,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SkillsSection extends StatelessWidget {
  const _SkillsSection({
    required this.title,
    required this.controllers,
    required this.addLabel,
    required this.onAdd,
  });

  final String title;
  final List<TextEditingController> controllers;
  final String addLabel;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final values = controllers
        .map((c) => c.text.trim())
        .where((v) => v.isNotEmpty)
        .toList();
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontFamily: 'Lama Sans',
              fontWeight: FontWeight.w900,
              fontSize: 16.6.sp,
              height: 1.5,
              color: const Color(0xFF040814),
            ),
          ),
          SizedBox(height: 10.h),
          if (values.isEmpty)
            Text(
              'لا توجد عناصر',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontFamily: 'Lama Sans',
                fontSize: 13.sp,
                color: const Color(0xFF6B7280),
              ),
            )
          else
            Wrap(
              spacing: 8.14.w,
              runSpacing: 8.14.h,
              alignment: WrapAlignment.start,
              textDirection: TextDirection.rtl,
              children: values.map((s) => _EditSkillChip(label: s)).toList(),
            ),
          SizedBox(height: 12.h),
          DottedBorder(
            color: const Color(0xFFB7BDC8),
            strokeWidth: 1.2,
            radius: Radius.circular(12.r),
            borderType: BorderType.RRect,
            dashPattern: const [6, 4],
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12.r),
                onTap: onAdd,
                child: SizedBox(
                  height: 50.h,
                  child: Center(
                    child: Text(
                      addLabel,
                      style: TextStyle(
                        fontFamily: 'Lama Sans',
                        fontWeight: FontWeight.w700,
                        fontSize: 16.sp,
                        color: const Color(0xFF6B7280),
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
  }
}

class _ExperiencesSection extends StatelessWidget {
  const _ExperiencesSection({
    required this.title,
    required this.entries,
    required this.onAdd,
    required this.onTapEntry,
  });

  final String title;
  final List<_ExperienceFormEntry> entries;
  final VoidCallback onAdd;
  final ValueChanged<int> onTapEntry;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.keyboard_arrow_up_rounded,
                size: 24.sp,
                color: const Color(0xFF2F2A60),
              ),
              const Spacer(),
              Text(
                title,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontFamily: 'Lama Sans',
                  fontWeight: FontWeight.w900,
                  fontSize: 16.6.sp,
                  height: 1.5,
                  color: const Color(0xFF040814),
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          if (entries.isEmpty)
            Text(
              'لا توجد عناصر',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontFamily: 'Lama Sans',
                fontSize: 13.sp,
                color: const Color(0xFF6B7280),
              ),
            ),
          ...List.generate(entries.length, (i) {
            final item = entries[i];
            return Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20.r),
                  onTap: () => onTapEntry(i),
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 15.h),
                    decoration: BoxDecoration(
                      color: const Color(0x4DD9D9D9),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          textDirection: TextDirection.rtl,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Text(
                                item.workplace,
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  fontFamily: 'Lama Sans',
                                  fontWeight: FontWeight.w900,
                                  fontSize: 14.sp,
                                  height: 1.5,
                                  color: const Color(0xFF040814),
                                ),
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Text(
                              _range(item),
                              textAlign: TextAlign.left,
                              style: TextStyle(
                                fontFamily: 'Lama Sans',
                                fontWeight: FontWeight.w500,
                                fontSize: 12.sp,
                                height: 1.5,
                                color: const Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          item.role.trim().isEmpty ? 'غير محدد' : item.role.trim(),
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontFamily: 'Lama Sans',
                            fontWeight: FontWeight.w500,
                            fontSize: 12.sp,
                            height: 1.5,
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
          DottedBorder(
            color: const Color(0xFFB7BDC8),
            strokeWidth: 1.2,
            radius: Radius.circular(12.r),
            borderType: BorderType.RRect,
            dashPattern: const [6, 4],
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12.r),
                onTap: onAdd,
                child: SizedBox(
                  height: 50.h,
                  child: Center(
                    child: Text(
                      '+ أضف خبرة جديدة',
                      style: TextStyle(
                        fontFamily: 'Lama Sans',
                        fontWeight: FontWeight.w700,
                        fontSize: 16.sp,
                        color: const Color(0xFF6B7280),
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
  }

  String _range(_ExperienceFormEntry e) {
    final s = e.startYear.trim();
    if (e.isCurrent) return 'الآن - $s';
    final end = e.endYear.trim();
    if (s.isEmpty && end.isEmpty) return '—';
    if (s.isEmpty) return end;
    if (end.isEmpty) return s;
    return '$end - $s';
  }
}

class _ClinicalCaseFormEntry {
  const _ClinicalCaseFormEntry({
    required this.title,
    required this.description,
    required this.imageUrls,
  });

  final String title;
  final String description;
  final List<String> imageUrls;
}

class _CertificateFormEntry {
  const _CertificateFormEntry({
    required this.title,
    required this.issuer,
    required this.imageUrls,
  });

  final String title;
  final String issuer;
  final List<String> imageUrls;
}

class _ExperienceFormEntry {
  _ExperienceFormEntry({
    required this.workplace,
    required this.role,
    required this.startYear,
    required this.endYear,
    required this.isCurrent,
  });

  final String workplace;
  final String role;
  final String startYear;
  final String endYear;
  final bool isCurrent;
}

class _EditSkillChip extends StatelessWidget {
  const _EditSkillChip({required this.label});

  final String label;

  static const Color _fill = Color(0x1A5993FF);
  static const Color _border = Color(0x995993FF);
  static const Color _text = Color(0xFF5993FF);

  @override
  Widget build(BuildContext context) {
    return IntrinsicWidth(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _fill,
          borderRadius: BorderRadius.circular(13.03.r),
          border: Border.all(
            width: 0.67.r,
            color: _border,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(8.96.w, 8.14.h, 8.96.w, 8.14.h),
          child: Text(
            label,
            textAlign: TextAlign.right,
            softWrap: true,
            style: TextStyle(
              fontFamily: 'Lama Sans',
              fontWeight: FontWeight.w900,
              fontSize: 12.sp,
              height: 1.5,
              letterSpacing: 0,
              color: _text,
            ),
          ),
        ),
      ),
    );
  }
}

class _EducationFormEntry {
  _EducationFormEntry({
    required this.degreeLabel,
    required this.specialty,
    required this.university,
    required this.startYear,
    required this.graduationYear,
  });

  final String degreeLabel;
  final String specialty;
  final String university;
  final String startYear;
  final String graduationYear;
}

class _BioTextField extends StatefulWidget {
  const _BioTextField({required this.controller, required this.readOnly});

  final TextEditingController controller;
  final bool readOnly;

  @override
  State<_BioTextField> createState() => _BioTextFieldState();
}

class _BioTextFieldState extends State<_BioTextField> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
  }

  @override
  void didUpdateWidget(covariant _BioTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onChanged);
      widget.controller.addListener(_onChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final raw = widget.controller.text;
    final significant = _bioNonWhitespaceCount(raw);
    final hasOnlyWhitespace = raw.isNotEmpty && significant == 0;

    Color hintColor;
    String hintLine;
    if (hasOnlyWhitespace) {
      hintColor = const Color(0xFFE53935);
      hintLine = 'لا يُقبل نص من مسافات فقط. اكتب أحرفاً فعلية (المسافات لا تُحتسب).';
    } else if (significant < _kBioMinSignificantChars) {
      hintColor = const Color(0xFF92400E);
      hintLine =
          'الحد الأدنى $_kBioMinSignificantChars حرفاً دون المسافات — لديك الآن $significant / $_kBioMinSignificantChars';
    } else {
      hintColor = const Color(0xFF059669);
      hintLine = 'تم استيفاء الحد الأدنى للأحرف (دون احتساب المسافات).';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 323.w,
          height: 122.h,
          child: Container(
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              color: const Color(0x4DD9D9D9),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: TextField(
              controller: widget.controller,
              readOnly: widget.readOnly,
              expands: true,
              minLines: null,
              maxLines: null,
              maxLength: 200,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.justify,
              textAlignVertical: TextAlignVertical.top,
              style: TextStyle(
                fontFamily: 'Lama Sans',
                fontWeight: FontWeight.w600,
                fontSize: 14.sp,
                height: 2.0,
                color: const Color(0xFF040814),
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                counterText: '',
                hintText: 'اكتب نبذة تعريفية',
                hintStyle: TextStyle(
                  fontFamily: 'Lama Sans',
                  fontWeight: FontWeight.w400,
                  fontSize: 14.sp,
                  height: 2.0,
                  color: const Color(0x80040814),
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: 6.h),
        Text(
          hintLine,
          textAlign: TextAlign.right,
          style: TextStyle(
            fontFamily: 'Lama Sans',
            fontWeight: FontWeight.w600,
            fontSize: 11.sp,
            height: 1.35,
            color: hintColor,
          ),
        ),
      ],
    );
  }
}

class _BottomActions extends StatelessWidget {
  const _BottomActions({
    required this.onSave,
    required this.onCancel,
    required this.isSaving,
  });
  final VoidCallback onSave;
  final VoidCallback onCancel;
  final bool isSaving;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        color: const Color(0xFFF5F6F8),
        padding: EdgeInsets.fromLTRB(14.w, 8.h, 14.w, 10.h),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: onCancel,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFFF7345)),
                  foregroundColor: const Color(0xFFFF7345),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  minimumSize: Size.fromHeight(50.h),
                ),
                child: Text(
                  'إلغاء',
                  style: TextStyle(
                    fontFamily: 'Lama Sans',
                    fontWeight: FontWeight.w800,
                    fontSize: 18.sp,
                  ),
                ),
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: FilledButton(
                onPressed: isSaving ? null : onSave,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFFF7345),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  minimumSize: Size.fromHeight(50.h),
                ),
                child: Text(
                  isSaving ? 'جاري الحفظ...' : 'حفظ',
                  style: TextStyle(
                    fontFamily: 'Lama Sans',
                    fontWeight: FontWeight.w900,
                    fontSize: 20.sp,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
