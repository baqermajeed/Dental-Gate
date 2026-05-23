import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:dental_gate/services/api_service.dart';

/// fallback محلي عند تعذر جلب التخصصات من الباكند.
const List<String> kFallbackJobSearchSpecialties = [
  'طب و جراحة الأسنان',
  'زراعة الأسنان',
  'طبيب مساعد',
  'جراحة الفم و الفكين',
  'أمراض اللثة',
  'طب الأسنان التجميلي',
];

/// اسم قديم مستخدم في شاشات البحث — نبقيه للتوافق.
const List<String> kPopularJobSearchChips = kFallbackJobSearchSpecialties;

/// محافظات العراق — مطابقة لقائمة التسجيل وإنشاء الوظيفة.
const List<String> kJobFilterGovernorates = [
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

Future<void> showJobSearchFilterBottomSheet(
  BuildContext context, {
  required String initialSpecialty,
  int initialExperienceIndex = 0,
  String? initialProvince,
  required void Function(String specialty, int experienceIndex, String? province)
      onApply,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(ctx).bottom,
        ),
        child: JobSearchFilterBottomSheet(
          initialSpecialty: initialSpecialty,
          initialExperienceIndex: initialExperienceIndex,
          initialProvince: initialProvince,
          onApply: onApply,
        ),
      );
    },
  );
}

/// شيت فلترة نتائج البحث.
class JobSearchFilterBottomSheet extends StatefulWidget {
  const JobSearchFilterBottomSheet({
    super.key,
    required this.initialSpecialty,
    this.initialExperienceIndex = 0,
    this.initialProvince,
    required this.onApply,
  });

  final String initialSpecialty;
  final int initialExperienceIndex;
  final String? initialProvince;
  final void Function(String specialty, int experienceIndex, String? province)
      onApply;

  @override
  State<JobSearchFilterBottomSheet> createState() =>
      JobSearchFilterBottomSheetState();
}

class JobSearchFilterBottomSheetState extends State<JobSearchFilterBottomSheet> {
  static const _fieldGrey = Color(0xFFF3F4F6);
  static const _borderGrey = Color(0xFFE5E7EB);
  static const _muted = Color(0xFF6B7280);
  static const _blue = Color(0xFF5993FF);

  static const _expChoices = [
    '1 - 3 سنوات',
    '3 - 5 سنوات',
    'أكثر من 5 سنوات',
  ];

  late String _specialty;
  int _expIndex = 0;
  String? _province;
  List<String> _specialtyOptions = kFallbackJobSearchSpecialties;

  @override
  void initState() {
    super.initState();
    _specialty = widget.initialSpecialty;
    _expIndex = widget.initialExperienceIndex.clamp(0, _expChoices.length - 1);
    _province = widget.initialProvince;
    _loadSpecialties();
  }

  Future<void> _loadSpecialties() async {
    try {
      final items = await ApiService.instance.fetchDentalSpecialties();
      if (!mounted) return;
      final clean = items.map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      if (clean.isEmpty) return;
      setState(() {
        _specialtyOptions = clean;
        if (_specialty.trim().isEmpty) {
          _specialty = clean.first;
        }
      });
    } catch (_) {}
  }

  Widget _requiredFieldLabel(String text) {
    return Align(
      alignment: Alignment.centerRight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        textDirection: TextDirection.rtl,
        children: [
          Container(
            width: 6.r,
            height: 6.r,
            decoration: const BoxDecoration(
              color: Color(0xFFE53935),
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 6.w),
          Text(
            text,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontFamily: 'Lama Sans',
              fontWeight: FontWeight.w700,
              fontSize: 16.sp,
              height: 1.5,
              color: const Color(0xFF040814),
            ),
          ),
        ],
      ),
    );
  }

  Future<String?> _showTalabatStyleListPicker({
    required String title,
    required List<String> items,
    String? selected,
    required IconData leadingIconUnselected,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final mq = MediaQuery.sizeOf(ctx);
        final sheetH = math.min(500.h, mq.height * 0.92);
        return Directionality(
          textDirection: TextDirection.rtl,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.viewInsetsOf(ctx).bottom,
              ),
              child: SizedBox(
                height: sheetH,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDFEFF),
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(24.r)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1A040814),
                        blurRadius: 16,
                        offset: Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: EdgeInsets.fromLTRB(18.w, 10.h, 18.w, 0),
                        child: Column(
                          children: [
                            Center(
                              child: Container(
                                width: 52.w,
                                height: 5.h,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFD1D5DB),
                                  borderRadius: BorderRadius.circular(12.r),
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
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView.separated(
                          padding: EdgeInsets.fromLTRB(18.w, 0, 18.w, 16.h),
                          physics: const BouncingScrollPhysics(),
                          itemCount: items.length,
                          separatorBuilder: (context, _) =>
                              SizedBox(height: 8.h),
                          itemBuilder: (context, index) {
                            final g = items[index];
                            return Material(
                              color: selected == g
                                  ? const Color(0x1A5993FF)
                                  : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(14.r),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(14.r),
                                onTap: () => Navigator.of(ctx).pop(g),
                                child: Container(
                                  height: 50.h,
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 14.w),
                                  child: Row(
                                    children: [
                                      if (selected == g)
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
                                          g,
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
            ),
          ),
        );
      },
    );
  }

  Widget _talabatStyleFilterField({
    required String displayText,
    required bool isPlaceholder,
    required VoidCallback onTap,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = math.min(309.w, constraints.maxWidth);
        return Align(
          alignment: AlignmentDirectional.centerStart,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16.r),
              onTap: onTap,
              child: SizedBox(
                width: w,
                height: 50.h,
                child: Container(
                  padding: EdgeInsets.fromLTRB(22.w, 10.h, 21.w, 11.h),
                  decoration: BoxDecoration(
                    color: const Color(0x70D9D9D9),
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      color: const Color(0x335993FF),
                      width: 1.1,
                    ),
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
                          displayText,
                          textAlign: TextAlign.right,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Lama Sans',
                            fontWeight: FontWeight.w700,
                            fontSize: 16.sp,
                            height: 1.25,
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
            ),
          ),
        );
      },
    );
  }

  Widget _specialtyField() {
    return _talabatStyleFilterField(
      displayText: _specialty,
      isPlaceholder: false,
      onTap: () async {
        final v = await _showTalabatStyleListPicker(
          title: 'اختيار التخصص',
          items: _specialtyOptions,
          selected: _specialty,
          leadingIconUnselected: Icons.work_outline_rounded,
        );
        if (v != null) setState(() => _specialty = v);
      },
    );
  }

  Widget _provinceField() {
    return _talabatStyleFilterField(
      displayText: _province ?? 'اختر المحافظة',
      isPlaceholder: _province == null,
      onTap: () async {
        final v = await _showTalabatStyleListPicker(
          title: 'اختيار المحافظة',
          items: kJobFilterGovernorates,
          selected: _province,
          leadingIconUnselected: Icons.location_on_outlined,
        );
        if (v != null) setState(() => _province = v);
      },
    );
  }

  Widget _experienceChips() {
    return Row(
      textDirection: TextDirection.rtl,
      children: [
        for (int i = 0; i < 3; i++) ...[
          if (i > 0) SizedBox(width: 8.w),
          Expanded(child: _experienceChip(i)),
        ],
      ],
    );
  }

  Widget _experienceChip(int index) {
    final selected = _expIndex == index;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _expIndex = index),
        borderRadius: BorderRadius.circular(12.r),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          alignment: Alignment.center,
          padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 4.w),
          decoration: BoxDecoration(
            color: selected ? _fieldGrey : Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            border: selected ? null : Border.all(color: _borderGrey, width: 1),
          ),
          child: Text(
            _expChoices[index],
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Lama Sans',
              fontWeight: FontWeight.w600,
              fontSize: 12.sp,
              height: 1.25,
              color: selected ? const Color(0xFF040814) : _muted,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: ClipRRect(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        child: ColoredBox(
          color: Colors.white,
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(22.w, 0, 22.w, 12.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: 8.h),
                  Center(
                    child: Container(
                      width: 40.w,
                      height: 4.h,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5E7EB),
                        borderRadius: BorderRadius.circular(2.r),
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h + 20.h),
                  Text(
                    'فلترة نتائج البحث',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Lama Sans',
                      fontWeight: FontWeight.w800,
                      fontSize: 20.sp,
                      height: 1.0,
                      color: const Color(0xFF040814),
                    ),
                  ),
                  SizedBox(height: 24.h),
                  _requiredFieldLabel('حسب الاختصاص'),
                  SizedBox(height: 16.h),
                  _specialtyField(),
                  SizedBox(height: 22.h),
                  _requiredFieldLabel('حسب سنوات الخبرة'),
                  SizedBox(height: 16.h),
                  _experienceChips(),
                  SizedBox(height: 22.h),
                  _requiredFieldLabel('حسب المحافظة'),
                  SizedBox(height: 16.h),
                  _provinceField(),
                  SizedBox(height: 28.h),
                  SizedBox(
                    height: 52.h,
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        widget.onApply(_specialty, _expIndex, _province);
                      },
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: _blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14.r),
                        ),
                        textStyle: TextStyle(
                          fontFamily: 'Lama Sans',
                          fontWeight: FontWeight.w800,
                          fontSize: 16.sp,
                        ),
                      ),
                      child: const Text('فلترة'),
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
