import 'dart:async';

import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'package:dental_gate/controllers/home_controller.dart';
import 'package:dental_gate/controllers/talabat_controller.dart';
import 'package:dental_gate/models/job_posting.dart';
import 'package:dental_gate/services/api_service.dart';
import 'package:dental_gate/utils/iqd_format.dart';
import 'package:dental_gate/widgets/app_back_button.dart';
import 'package:dental_gate/widgets/modern_options_bottom_sheet.dart';

class CreateJobView extends StatefulWidget {
  const CreateJobView({super.key, this.existingJob});

  /// عند التمرير: نفس النموذج في وضع التعديل مع تعبئة الحقول.
  final JobPosting? existingJob;

  @override
  State<CreateJobView> createState() => _CreateJobViewState();
}

class _CreateJobViewState extends State<CreateJobView> {
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
  final List<String> _dentalSpecialties = [];
  final List<String> _educationOptions = [];
  final List<String> _dentalSkillsCatalog = [];

  final TextEditingController _workplaceName = TextEditingController();
  final TextEditingController _specialty = TextEditingController(
    text: 'طبيب اسنان متدرب',
  );
  final TextEditingController _description = TextEditingController(text: '');

  int _yearsExperience = 10;
  int _shiftHours = 10;
  final TextEditingController _salaryController = TextEditingController();
  String _selectedGovernorate = 'بابل';
  String _selectedCurrency = 'د.ع';
  String _selectedEducation = 'بكالوريوس';
  bool _isArabicSelected = true;
  bool _isEnglishSelected = true;
  final List<String> _skills = [
    'طب أسنان الأطفال',
    'تبييض الأسنان',
    'جراحة الفم',
    'أجهزة التقويم',
    'علاج قناة الجذر المتقدم',
    'حشوات تجميلية',
  ];

  bool _basicOpen = false;
  bool _aboutOpen = false;
  bool _educationOpen = false;
  bool _languagesOpen = false;
  bool _skillsOpen = false;
  bool _deadlineOpen = false;
  bool _publishing = false;
  DateTime? _applicationDeadline;

  bool get _isEditMode => widget.existingJob != null;

  int _hoursFromWorkingHours(String s) {
    final m = RegExp(r'(\d+)').firstMatch(s);
    if (m == null) return 10;
    return int.tryParse(m.group(1)!) ?? 10;
  }

  @override
  void initState() {
    super.initState();
    _loadDynamicProfileOptions();
    final j = widget.existingJob;
    if (j == null) return;
    _workplaceName.text = j.workplaceName;
    _specialty.text = j.requiredSpecialty;
    _description.text = (j.description ?? '').trim();
    _yearsExperience = j.yearsExperience;
    _shiftHours = j.shiftHours ?? _hoursFromWorkingHours(j.workingHours);
    final sal = j.monthlySalaryIqd;
    if (sal != null) {
      _salaryController.text = formatIqdWithCommas(sal);
    } else {
      _salaryController.clear();
    }
    final addr = j.workplaceAddress.trim();
    if (_governorates.contains(addr)) {
      _selectedGovernorate = addr;
    } else {
      String? found;
      for (final g in _governorates) {
        if (addr.contains(g)) {
          found = g;
          break;
        }
      }
      _selectedGovernorate = found ?? _governorates.first;
    }
    _selectedEducation = jobEducationLabelAr(j.education);
    _isArabicSelected = j.languages.contains(JobLanguageApi.arabic);
    _isEnglishSelected = j.languages.contains(JobLanguageApi.english);
    _skills
      ..clear()
      ..addAll(j.coreSkills.isNotEmpty ? j.coreSkills : <String>[]);
    _applicationDeadline = j.applicationDeadline?.toLocal();
  }

  Future<void> _loadDynamicProfileOptions() async {
    try {
      final results = await Future.wait<List<String>>([
        ApiService.instance.fetchDentalSpecialties(),
        ApiService.instance.fetchEducationOptions(),
        ApiService.instance.fetchSkillOptions(),
      ]);
      if (!mounted) return;
      setState(() {
        _dentalSpecialties
          ..clear()
          ..addAll(results[0]);
        _educationOptions
          ..clear()
          ..addAll(results[1]);
        _dentalSkillsCatalog
          ..clear()
          ..addAll(results[2]);
        if (_selectedEducation.trim().isEmpty && _educationOptions.isNotEmpty) {
          _selectedEducation = _educationOptions.first;
        }
        if (_skills.isEmpty && _dentalSkillsCatalog.isNotEmpty) {
          _skills.addAll(_dentalSkillsCatalog.take(2));
        }
      });
    } catch (_) {
      // يبقى السلوك الحالي بدون كسر الشاشة عند فشل جلب القوائم.
    }
  }

  @override
  void dispose() {
    _workplaceName.dispose();
    _specialty.dispose();
    _description.dispose();
    _salaryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFFDFEFF),
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(14.w, 10.h, 14.w, 8.h),
                child: Row(
                  textDirection: TextDirection.ltr,
                  children: [
                    AppBackButton(
                      size: 40.w,
                      iconSize: 24.sp,
                      iconColor: const Color(0xFF111827),
                      onTap: () => Get.back(),
                    ),
                    Expanded(
                      child: Text(
                        _isEditMode ? 'تعديل الوظيفة' : 'أنشاء وظيفة جديدة',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Lama Sans',
                          fontWeight: FontWeight.w800,
                          fontSize: 16.sp,
                          height: 1.5,
                          color: const Color(0xFF040814),
                        ),
                      ),
                    ),
                    SizedBox(width: 24.w),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  width: double.infinity,
                  margin: EdgeInsets.only(top: 8.h),
                  color: const Color(0xFFFDFEFF),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(14.w, 14.h, 14.w, 24.h),
                    child: Column(
                      children: [
                        _sectionCard(
                          title: 'معلومات الوظيفة الأساسية',
                          open: _basicOpen,
                          onToggle: () =>
                              setState(() => _basicOpen = !_basicOpen),
                          cardRadius: 22,
                          bodyPadding: EdgeInsets.all(16.r),
                          child: _basicSectionBody(),
                        ),
                        SizedBox(height: 16.h),
                        _sectionCard(
                          title: 'حول الوظيفة',
                          open: _aboutOpen,
                          onToggle: () =>
                              setState(() => _aboutOpen = !_aboutOpen),
                          child: _aboutSectionBody(),
                        ),
                        SizedBox(height: 16.h),
                        _sectionCard(
                          title: 'التعليم',
                          open: _educationOpen,
                          onToggle: () =>
                              setState(() => _educationOpen = !_educationOpen),
                          child: _educationSectionBody(),
                        ),
                        SizedBox(height: 16.h),
                        _sectionCard(
                          title: 'اللغات',
                          open: _languagesOpen,
                          onToggle: () =>
                              setState(() => _languagesOpen = !_languagesOpen),
                          child: _languagesSectionBody(),
                        ),
                        SizedBox(height: 16.h),
                        _sectionCard(
                          title: 'المهارات الأساسية',
                          open: _skillsOpen,
                          onToggle: () =>
                              setState(() => _skillsOpen = !_skillsOpen),
                          child: _skillsSectionBody(),
                        ),
                        SizedBox(height: 16.h),
                        _sectionCard(
                          title: 'اخر موعد للتقديم',
                          open: _deadlineOpen,
                          onToggle: () =>
                              setState(() => _deadlineOpen = !_deadlineOpen),
                          child: _deadlineSectionBody(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              _bottomBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required bool open,
    required VoidCallback onToggle,
    required Widget child,
    double cardRadius = 16,
    EdgeInsetsGeometry? bodyPadding,
  }) {
    final card = Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFFDFEFF),
        borderRadius: BorderRadius.circular(cardRadius.r),
        boxShadow: const [
          BoxShadow(
            color: Color(0x29040814),
            blurRadius: 6,
            spreadRadius: 0,
            offset: Offset(0, 0),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(cardRadius.r),
            child: Padding(
              padding: EdgeInsets.fromLTRB(14.w, 0, 14.w, 0),
              child: SizedBox(
                height: 48.h,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
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
                    ),
                    SizedBox(width: 6.w),
                    Icon(
                      open
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      size: 24.sp,
                      color: const Color(0xFF040814),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (open)
            Padding(
              padding: bodyPadding ?? EdgeInsets.fromLTRB(14.w, 0, 14.w, 14.h),
              child: child,
            ),
        ],
      ),
    );
    return card;
  }

  Widget _basicSectionBody() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: 0.h),
        Container(
          width: 67.w,
          height: 67.h,
          decoration: BoxDecoration(
            color: const Color(0xFFFFFFFF),
            shape: BoxShape.circle,
            boxShadow: const [
              BoxShadow(
                color: Color(0x1F000000),
                offset: Offset(0, 0),
                blurRadius: 9.8,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Center(
            child: Image.asset(
              'assets/icons/Frame 427321681.png',
              width: 35.704246520996094.w,
              height: 30.69352912902832.h,
              fit: BoxFit.contain,
            ),
          ),
        ),
        SizedBox(height: 16.h),
        _fieldLabel('أسم مكان العمل'),
        _textField(_workplaceName, hintText: 'ادخل اسم مكان العمل...'),
        _fieldLabel('عنوان العمل'),
        _governorateFieldLikeFilter(
          _selectedGovernorate,
          onTap: () async {
            final value = await _showGovernoratePicker(
              context,
              _selectedGovernorate,
            );
            if (value != null) {
              setState(() => _selectedGovernorate = value);
            }
          },
        ),
        _fieldLabel('أسم الأختصاص'),
        _governorateFieldLikeFilter(
          _specialty.text,
          onTap: () async {
            final value = await _showSpecialtyPicker(context, _specialty.text);
            if (value != null) {
              setState(() => _specialty.text = value);
            }
          },
        ),
        _fieldLabel('سنوات الخبرة'),
        _counterRow(
          value: _yearsExperience.toString(),
          onMinus: () => setState(
            () => _yearsExperience = (_yearsExperience - 1).clamp(0, 80),
          ),
          onPlus: () => setState(
            () => _yearsExperience = (_yearsExperience + 1).clamp(0, 80),
          ),
        ),
        _fieldLabel('ساعات الدوام'),
        _counterRow(
          value: _shiftHours.toString(),
          onMinus: () =>
              setState(() => _shiftHours = (_shiftHours - 1).clamp(1, 24)),
          onPlus: () =>
              setState(() => _shiftHours = (_shiftHours + 1).clamp(1, 24)),
        ),
        _fieldLabel('الراتب'),
        Row(
          children: [
            Expanded(
              child: Container(
                height: 47.h,
                decoration: BoxDecoration(
                  color: const Color(0x4DD9D9D9),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                padding: EdgeInsets.fromLTRB(19.w, 12.h, 19.w, 12.h),
                alignment: Alignment.centerRight,
                child: TextField(
                  controller: _salaryController,
                  keyboardType: TextInputType.number,
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.right,
                  textAlignVertical: TextAlignVertical.center,
                  inputFormatters: [ThousandsSeparatorInputFormatter()],
                  style: TextStyle(
                    fontFamily: 'Lama Sans',
                    fontWeight: FontWeight.w700,
                    fontSize: 14.sp,
                    height: 1.5,
                    color: const Color(0xE6000000),
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    hintText: 'ادخل الراتب',
                    hintStyle: TextStyle(
                      fontFamily: 'Lama Sans',
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      height: 1.5,
                      color: Color(0x80000000),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: 8.w),
            SizedBox(
              width: 68.w,
              child: Container(
                height: 47.h,
                decoration: BoxDecoration(
                  color: const Color(0x4DD9D9D9),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                padding: EdgeInsets.fromLTRB(19.w, 6.h, 19.w, 6.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _selectedCurrency,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontFamily: 'Lama Sans',
                        fontWeight: FontWeight.w800,
                        fontSize: 14.sp,
                        height: 1.5,
                        color: const Color(0xFF2471FF),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _counterRow({
    required String value,
    required VoidCallback onMinus,
    required VoidCallback onPlus,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 79.w,
          height: 47.h,
          child: _counterButton('-', onMinus),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: Container(
            height: 47.h,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0x4DD9D9D9),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontFamily: 'Lama Sans',
                fontWeight: FontWeight.w700,
                fontSize: 15.33.sp,
                height: 1.5,
                color: const Color(0xFF111827),
              ),
            ),
          ),
        ),
        SizedBox(width: 8.w),
        SizedBox(width: 79.w, height: 47.h, child: _counterButton('+', onPlus)),
      ],
    );
  }

  Widget _aboutSectionBody() {
    return SizedBox(
      width: 323.w,
      height: 122.h,
      child: Container(
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: const Color(0x4DD9D9D9),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: TextField(
          controller: _description,
          expands: true,
          minLines: null,
          maxLines: null,
          scrollPhysics: const BouncingScrollPhysics(),
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.justify,
          style: TextStyle(
            fontFamily: 'Lama Sans',
            fontWeight: FontWeight.w600,
            fontSize: 14.sp,
            color: const Color(0xFF676B72),
            height: 2.0,
          ),
          decoration: InputDecoration(
            border: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.zero,
            hintText: 'ادخل وصف عن الوظيفة ...',
            hintStyle: TextStyle(
              fontFamily: 'Lama Sans',
              fontWeight: FontWeight.w600,
              fontSize: 14.sp,
              height: 2.0,
              color: const Color(0x80676B72),
            ),
          ),
        ),
      ),
    );
  }

  Widget _educationSectionBody() {
    return _governorateFieldLikeFilter(
      _selectedEducation,
      onTap: () async {
        final value = await _showEducationPicker(context, _selectedEducation);
        if (value != null) {
          setState(() => _selectedEducation = value);
        }
      },
    );
  }

  Widget _languagesSectionBody() {
    return Column(
      children: [
        _languageCheckboxTile(
          label: 'العربية',
          value: _isArabicSelected,
          onChanged: (v) => setState(() => _isArabicSelected = v ?? false),
        ),
        SizedBox(height: 8.h),
        _languageCheckboxTile(
          label: 'الانجليزية',
          value: _isEnglishSelected,
          onChanged: (v) => setState(() => _isEnglishSelected = v ?? false),
        ),
      ],
    );
  }

  Widget _languageCheckboxTile({
    required String label,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return Container(
      width: double.infinity,
      height: 50.h,
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      decoration: BoxDecoration(
        color: const Color(0x4DD9D9D9),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Expanded(
            child: Text(
              label,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontFamily: 'Lama Sans',
                fontWeight: FontWeight.w700,
                fontSize: 14.sp,
                color: const Color(0xFF040814),
              ),
            ),
          ),
          Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF5993FF),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4.r),
            ),
          ),
        ],
      ),
    );
  }

  Widget _skillsSectionBody() {
    return Column(
      children: [
        Wrap(
          spacing: 8.14.w,
          runSpacing: 8.14.h,
          children: _skills.map((e) => _pillChip(e, outlined: true)).toList(),
        ),
        SizedBox(height: 10.h),
        DottedBorderButton(
          text: '+ اضف مهارة جديدة',
          onTap: () async {
            final result = await _showSkillsPickerDialog(context);
            if (result == null) return;
            setState(() {
              _skills
                ..clear()
                ..addAll(result);
            });
          },
        ),
      ],
    );
  }

  Widget _deadlineSectionBody() {
    final text = _applicationDeadline == null
        ? 'اختر التاريخ'
        : _deadlineLabel(_applicationDeadline!);
    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            'آخر موعد للتقديم',
            style: TextStyle(
              fontFamily: 'Lama Sans',
              fontWeight: FontWeight.w700,
              fontSize: 14.sp,
              color: const Color(0xFF040814),
            ),
          ),
        ),
        SizedBox(height: 10.h),
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14.r),
            onTap: _pickApplicationDeadline,
            child: Container(
              width: double.infinity,
              height: 50.h,
              padding: EdgeInsets.symmetric(horizontal: 14.w),
              decoration: BoxDecoration(
                color: const Color(0x70D9D9D9),
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(color: const Color(0x335993FF), width: 1.1),
              ),
              child: Row(
                textDirection: TextDirection.rtl,
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    size: 20.sp,
                    color: const Color(0xFF2563EB),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      text,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontFamily: 'Lama Sans',
                        fontWeight: FontWeight.w700,
                        fontSize: 14.sp,
                        color: _applicationDeadline == null
                            ? const Color(0xFF6B7280)
                            : const Color(0xFF040814),
                      ),
                    ),
                  ),
                  if (_applicationDeadline != null)
                    InkWell(
                      onTap: () => setState(() => _applicationDeadline = null),
                      borderRadius: BorderRadius.circular(12.r),
                      child: Padding(
                        padding: EdgeInsets.all(4.r),
                        child: Icon(
                          Icons.close_rounded,
                          size: 18.sp,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<List<String>?> _showSkillsPickerDialog(BuildContext context) async {
    final selected = _skills.toSet();
    const Color primaryBlue = Color(0xFF5B92FF);
    const Color tagIdleBg = Color(0xFFF2F2F2);
    const Color tagIdleText = Color(0xFF6B6B6B);
    const Color sheetHandle = Color(0xFFD9D9D9);

    return showDialog<List<String>>(
      context: context,
      barrierColor: const Color(0x660B1F3D),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: Dialog(
                backgroundColor: Colors.transparent,
                insetPadding: EdgeInsets.symmetric(
                  horizontal: 20.w,
                  vertical: 24.h,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(46.r),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0x140B1F3D),
                        blurRadius: 28,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  padding: EdgeInsets.fromLTRB(18.w, 14.h, 18.w, 22.h),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.sizeOf(context).height * 0.78,
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Center(
                                  child: Container(
                                    width: 44.w,
                                    height: 5.h,
                                    decoration: BoxDecoration(
                                      color: sheetHandle,
                                      borderRadius: BorderRadius.circular(100),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 18.h),
                                Text(
                                  'أضافة مهارة جديدة',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'Lama Sans',
                                    fontWeight: FontWeight.w700,
                                    fontSize: 18.sp,
                                    height: 1.3,
                                    color: const Color(0xFF000000),
                                  ),
                                ),
                                SizedBox(height: 22.h),
                                GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _dentalSkillsCatalog.length,
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 2,
                                        mainAxisSpacing: 12.h,
                                        crossAxisSpacing: 12.w,
                                        childAspectRatio: 2.35,
                                      ),
                                  itemBuilder: (context, index) {
                                    final skill = _dentalSkillsCatalog[index];
                                    final isOn = selected.contains(skill);
                                    return Material(
                                      color: isOn ? primaryBlue : tagIdleBg,
                                      borderRadius: BorderRadius.circular(22.r),
                                      child: InkWell(
                                        onTap: () {
                                          setModalState(() {
                                            if (isOn) {
                                              selected.remove(skill);
                                            } else {
                                              selected.add(skill);
                                            }
                                          });
                                        },
                                        borderRadius: BorderRadius.circular(
                                          22.r,
                                        ),
                                        splashColor: primaryBlue.withValues(
                                          alpha: 0.2,
                                        ),
                                        highlightColor: primaryBlue.withValues(
                                          alpha: 0.08,
                                        ),
                                        child: Center(
                                          child: Padding(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 8.w,
                                            ),
                                            child: Text(
                                              skill,
                                              textAlign: TextAlign.center,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontFamily: 'Lama Sans',
                                                fontWeight: FontWeight.w600,
                                                fontSize: 12.5.sp,
                                                height: 1.35,
                                                color: isOn
                                                    ? Colors.white
                                                    : tagIdleText,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                SizedBox(height: 12.h),
                                SizedBox(
                                  width: double.infinity,
                                  child: Material(
                                    color: tagIdleBg,
                                    borderRadius: BorderRadius.circular(22.r),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(22.r),
                                      onTap: () async {
                                        final customSkill =
                                            await _askForCustomSkill(
                                              this.context,
                                            );
                                        if (customSkill == null) return;
                                        setModalState(() {
                                          selected.add(customSkill);
                                        });
                                      },
                                      child: Container(
                                        height: 52.h,
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 12.w,
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          'أخرى',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontFamily: 'Lama Sans',
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14.sp,
                                            color: tagIdleText,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 22.h),
                        Row(
                          textDirection: TextDirection.rtl,
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 50.h,
                                child: ElevatedButton(
                                  onPressed: () => Navigator.of(
                                    context,
                                  ).pop(selected.toList(growable: false)),
                                  style: ElevatedButton.styleFrom(
                                    elevation: 0,
                                    backgroundColor: primaryBlue,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18.r),
                                    ),
                                  ),
                                  child: Text(
                                    'حفظ',
                                    style: TextStyle(
                                      fontFamily: 'Lama Sans',
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15.sp,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: SizedBox(
                                height: 50.h,
                                child: OutlinedButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  style: OutlinedButton.styleFrom(
                                    elevation: 0,
                                    backgroundColor: Colors.white,
                                    foregroundColor: primaryBlue,
                                    side: const BorderSide(
                                      color: primaryBlue,
                                      width: 1.2,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18.r),
                                    ),
                                  ),
                                  child: Text(
                                    'الغاء',
                                    style: TextStyle(
                                      fontFamily: 'Lama Sans',
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15.sp,
                                      color: primaryBlue,
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
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<String?> _askForCustomSkill(BuildContext context) async {
    final c = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: true,
      builder: (dialogContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Dialog(
            insetPadding: EdgeInsets.symmetric(
              horizontal: 22.w,
              vertical: 28.h,
            ),
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
                            colors: [Color(0xFF7FB2E4), Color(0xFF5993FF)],
                          ),
                          borderRadius: BorderRadius.circular(14.r),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF5993FF,
                              ).withValues(alpha: 0.25),
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
                          'إضافة مهارة أخرى',
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
                    textInputAction: TextInputAction.done,
                    style: TextStyle(
                      fontFamily: 'Lama Sans',
                      fontWeight: FontWeight.w700,
                      fontSize: 15.sp,
                      color: const Color(0xFF040814),
                    ),
                    decoration: InputDecoration(
                      hintText: 'اكتب المهارة',
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
                          color: const Color(
                            0xFF7FB2E4,
                          ).withValues(alpha: 0.55),
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
                    onSubmitted: (_) {
                      final value = c.text.trim();
                      if (value.isEmpty) return;
                      Navigator.of(dialogContext).pop(value);
                    },
                  ),
                  SizedBox(height: 22.h),
                  Row(
                    textDirection: TextDirection.rtl,
                    children: [
                      Expanded(
                        child: FilledButton(
                          onPressed: () {
                            final value = c.text.trim();
                            if (value.isEmpty) {
                              Get.snackbar(
                                'حقل فارغ',
                                'يرجى تعبئة الحقل قبل الإضافة',
                                snackPosition: SnackPosition.BOTTOM,
                              );
                              return;
                            }
                            Navigator.of(dialogContext).pop(value);
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
                          onPressed: () => Navigator.of(dialogContext).pop(),
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
        );
      },
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      c.dispose();
    });
    return result?.trim().isNotEmpty == true ? result!.trim() : null;
  }

  Widget _fieldLabel(String text) {
    return Padding(
      padding: EdgeInsets.only(top: 16.h, bottom: 6.h),
      child: Align(
        alignment: Alignment.centerRight,
        child: Text(
          text,
          style: TextStyle(
            fontFamily: 'Lama Sans',
            fontWeight: FontWeight.w600,
            fontSize: 14.sp,
            height: 1.5,
            color: const Color(0xFF000000),
          ),
        ),
      ),
    );
  }

  Widget _textField(TextEditingController controller, {String? hintText}) {
    return Container(
      height: 47.h,
      decoration: BoxDecoration(
        color: const Color(0x4DD9D9D9),
        borderRadius: BorderRadius.circular(12.r),
      ),
      padding: EdgeInsets.fromLTRB(19.w, 12.h, 19.w, 12.h),
      child: TextField(
        controller: controller,
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.right,
        style: TextStyle(
          fontFamily: 'Lama Sans',
          fontWeight: FontWeight.w700,
          fontSize: 14.sp,
          height: 1.5,
          color: const Color(0xFF000000),
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
          hintText: hintText,
          hintStyle: TextStyle(
            fontFamily: 'Lama Sans',
            fontWeight: FontWeight.w600,
            fontSize: 14.sp,
            height: 1.5,
            color: const Color(0x80000000),
          ),
        ),
      ),
    );
  }

  Widget _governorateFieldLikeFilter(
    String text, {
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16.r),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          height: 50.h,
          padding: EdgeInsets.fromLTRB(22.w, 10.h, 21.w, 11.h),
          decoration: BoxDecoration(
            color: const Color(0x70D9D9D9),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: const Color(0x335993FF), width: 1.1),
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
                  text,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontFamily: 'Lama Sans',
                    fontWeight: FontWeight.w700,
                    fontSize: 16.sp,
                    color: const Color(0xFF040814),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<String?> _showGovernoratePicker(
    BuildContext context,
    String? selected,
  ) {
    final opts = List<String>.from(_governorates);
    final cur = selected?.trim();
    if (cur != null && cur.isNotEmpty && !opts.contains(cur)) {
      opts.insert(0, cur);
    }
    return showModernOptionsSheet(
      context: context,
      title: 'اختيار المحافظة',
      subtitle: 'اختر المحافظة الأقرب لمكان عملك',
      icon: Icons.location_city_rounded,
      options: opts,
      selected: cur == null || cur.isEmpty ? null : cur,
    );
  }

  Future<String?> _showSpecialtyPicker(
    BuildContext context,
    String? selected,
  ) async {
    final entries = <String>[
      ..._dentalSpecialties.map((e) => e.trim()).where((e) => e.isNotEmpty),
      'أخرى',
    ];
    final cur = (selected ?? '').trim();
    if (cur.isNotEmpty && cur != 'أخرى' && !entries.contains(cur)) {
      entries.insert(0, cur);
    }

    final picked = await showModernOptionsSheet(
      context: context,
      title: 'اختيار التخصص',
      subtitle: 'اختر تخصصك بدقة لنتائج أفضل',
      icon: Icons.workspace_premium_rounded,
      options: entries,
      selected: cur.isEmpty ? null : cur,
    );
    if (picked == null) return null;
    if (picked == 'أخرى') {
      final custom = await _askForCustomSpecialty();
      if (custom == null) return null;
      if (!_dentalSpecialties.contains(custom)) {
        setState(() => _dentalSpecialties.insert(0, custom));
      }
      return custom;
    }
    return picked;
  }

  Future<String?> _askForCustomSpecialty() async {
    final c = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      useRootNavigator: true,
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
                          colors: [Color(0xFF7FB2E4), Color(0xFF5993FF)],
                        ),
                        borderRadius: BorderRadius.circular(14.r),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF5993FF,
                            ).withValues(alpha: 0.25),
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
                        'إضافة اختصاص آخر',
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
                  decoration: InputDecoration(
                    hintText: 'اكتب الاختصاص',
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
                          final v = c.text.trim();
                          if (v.isEmpty) {
                            Get.snackbar(
                              'حقل فارغ',
                              'يرجى تعبئة الحقل قبل الإضافة',
                              snackPosition: SnackPosition.BOTTOM,
                            );
                            return;
                          }
                          Navigator.of(ctx).pop(v);
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      c.dispose();
    });
    return result?.trim().isNotEmpty == true ? result!.trim() : null;
  }

  Future<String?> _showEducationPicker(
    BuildContext context,
    String? selected,
  ) async {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: SafeArea(
            top: false,
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
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 52.w,
                    height: 5.h,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD1D5DB),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    'اختيار التعليم',
                    style: TextStyle(
                      fontFamily: 'Lama Sans',
                      fontWeight: FontWeight.w800,
                      fontSize: 18.sp,
                      color: const Color(0xFF040814),
                    ),
                  ),
                  SizedBox(height: 10.h),
                  ..._educationOptions.map((e) {
                    final isSelected = selected == e;
                    return Padding(
                      padding: EdgeInsets.only(bottom: 8.h),
                      child: Material(
                        color: isSelected
                            ? const Color(0x1A5993FF)
                            : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14.r),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14.r),
                          onTap: () => Navigator.of(context).pop(e),
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
                                    Icons.school_outlined,
                                    color: const Color(0xFF9CA3AF),
                                    size: 20.sp,
                                  ),
                                SizedBox(width: 8.w),
                                Expanded(
                                  child: Text(
                                    e,
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
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _counterButton(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        width: 79.w,
        height: 47.h,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFFDFEFF),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: const Color(0xFFD9D9D9), width: 1),
        ),
        child: _counterGlyph(label),
      ),
    );
  }

  Widget _counterGlyph(String label) {
    if (label == '+') {
      return Opacity(
        opacity: 0.9,
        child: SizedBox(
          width: 10.554380416870117.w,
          height: 11.000009536743164.h,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 10.554380416870117.w,
                height: 2.h,
                decoration: BoxDecoration(
                  color: const Color(0xFF111827),
                  borderRadius: BorderRadius.circular(0.6.r),
                ),
              ),
              Container(
                width: 2.w,
                height: 11.000009536743164.h,
                decoration: BoxDecoration(
                  color: const Color(0xFF111827),
                  borderRadius: BorderRadius.circular(0.6.r),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return Opacity(
      opacity: 0.9,
      child: Container(
        width: 14.w,
        height: 3.h,
        decoration: BoxDecoration(
          color: const Color(0xFF111827),
          borderRadius: BorderRadius.circular(20.67.r),
        ),
      ),
    );
  }

  Widget _pillChip(String text, {bool outlined = false}) {
    return Container(
      constraints: BoxConstraints(minHeight: 35.h),
      padding: EdgeInsets.fromLTRB(8.96.w, 8.14.h, 8.96.w, 8.14.h),
      decoration: BoxDecoration(
        color: outlined ? const Color(0x1A5993FF) : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(13.03.r),
        border: outlined
            ? Border.all(color: const Color(0x995993FF), width: 0.67)
            : null,
      ),
      child: Text(
        text,
        textAlign: TextAlign.right,
        style: TextStyle(
          fontFamily: 'Lama Sans',
          fontWeight: FontWeight.w700,
          fontSize: 12.sp,
          height: 1.5,
          color: outlined ? const Color(0xFF2471FF) : const Color(0xFF111827),
        ),
      ),
    );
  }

  String _educationApiValue() {
    switch (_selectedEducation) {
      case 'دبلوم':
        return 'diploma';
      case 'بكالوريوس':
        return 'bachelor';
      case 'ماجستير':
        return 'master';
      case 'دكتوراه':
        return 'doctorate';
      default:
        return 'bachelor';
    }
  }

  int? _parsedSalaryIqd() {
    final digits = ThousandsSeparatorInputFormatter.stripToDigits(
      _salaryController.text,
    );
    if (digits.isEmpty) return null;
    return int.tryParse(digits);
  }

  String _deadlineLabel(DateTime dt) {
    return '${dt.year}/${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')}';
  }

  Future<void> _pickApplicationDeadline() async {
    final now = DateTime.now();
    final initial = _applicationDeadline ?? now.add(const Duration(days: 7));
    final picked = await showDialog<DateTime>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        var selected = initial.isBefore(now) ? now : initial;
        final firstDate = DateTime(now.year, now.month, now.day);
        final lastDate = now.add(const Duration(days: 365 * 3));
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: Dialog(
                backgroundColor: Colors.transparent,
                insetPadding: EdgeInsets.symmetric(
                  horizontal: 18.w,
                  vertical: 24.h,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDFEFF),
                    borderRadius: BorderRadius.circular(28.r),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0F172A).withValues(alpha: 0.12),
                        blurRadius: 26,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.fromLTRB(18.w, 16.h, 18.w, 16.h),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topRight,
                            end: Alignment.bottomLeft,
                            colors: [Color(0xFF6FA8FF), Color(0xFF3F7DFF)],
                          ),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(28.r),
                            topRight: Radius.circular(28.r),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 42.w,
                              height: 42.w,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(14.r),
                              ),
                              alignment: Alignment.center,
                              child: Icon(
                                Icons.event_available_rounded,
                                color: Colors.white,
                                size: 22.sp,
                              ),
                            ),
                            SizedBox(width: 10.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'آخر موعد للتقديم',
                                    style: TextStyle(
                                      fontFamily: 'Lama Sans',
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16.sp,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(height: 3.h),
                                  Text(
                                    _deadlineLabel(selected),
                                    style: TextStyle(
                                      fontFamily: 'Lama Sans',
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13.sp,
                                      color: Colors.white.withValues(
                                        alpha: 0.95,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(10.w, 10.h, 10.w, 2.h),
                        child: CalendarDatePicker(
                          initialDate: selected,
                          firstDate: firstDate,
                          lastDate: lastDate,
                          onDateChanged: (value) =>
                              setModalState(() => selected = value),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h),
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () =>
                                    Navigator.of(dialogContext).pop(),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(
                                    color: Color(0xFF3F7DFF),
                                  ),
                                  foregroundColor: const Color(0xFF3F7DFF),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12.r),
                                  ),
                                  minimumSize: Size.fromHeight(48.h),
                                ),
                                child: Text(
                                  'إلغاء',
                                  style: TextStyle(
                                    fontFamily: 'Lama Sans',
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15.sp,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 10.w),
                            Expanded(
                              child: FilledButton(
                                onPressed: () =>
                                    Navigator.of(dialogContext).pop(selected),
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFF3F7DFF),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12.r),
                                  ),
                                  minimumSize: Size.fromHeight(48.h),
                                ),
                                child: Text(
                                  'تأكيد',
                                  style: TextStyle(
                                    fontFamily: 'Lama Sans',
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15.sp,
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
            );
          },
        );
      },
    );
    if (picked == null || !mounted) return;
    setState(() {
      _applicationDeadline = DateTime(
        picked.year,
        picked.month,
        picked.day,
        23,
        59,
        59,
      );
    });
  }

  Future<void> _publishJob() async {
    final messenger = ScaffoldMessenger.of(context);
    if (_workplaceName.text.trim().isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('أدخل اسم مكان العمل')),
      );
      return;
    }
    if (_specialty.text.trim().isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('اختر اسم الاختصاص')),
      );
      return;
    }
    if (_applicationDeadline == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('حدد آخر موعد للتقديم')),
      );
      return;
    }

    setState(() => _publishing = true);
    try {
      final body = <String, dynamic>{
        'workplace_name': _workplaceName.text.trim(),
        'workplace_address': _selectedGovernorate.trim(),
        'required_specialty': _specialty.text.trim(),
        'years_experience': _yearsExperience,
        'monthly_salary_iqd': _parsedSalaryIqd(),
        'shift_hours': _shiftHours,
        'working_hours': '$_shiftHours ساعات',
        'description': _description.text.trim().isEmpty
            ? null
            : _description.text.trim(),
        'education': _educationApiValue(),
        'languages': [
          if (_isArabicSelected) 'arabic',
          if (_isEnglishSelected) 'english',
        ],
        'core_skills': List<String>.from(_skills),
        'application_deadline': _applicationDeadline!.toUtc().toIso8601String(),
      };

      if (_isEditMode) {
        final updated = await ApiService.instance.updateJobPosting(
          widget.existingJob!.id,
          body,
        );
        if (Get.isRegistered<TalabatController>()) {
          unawaited(Get.find<TalabatController>().load());
        }
        if (Get.isRegistered<HomeController>()) {
          unawaited(Get.find<HomeController>().loadJobs());
        }
        if (!mounted) return;
        setState(() => _publishing = false);
        Get.snackbar(
          'تم الحفظ',
          'تم حفظ التعديلات بنجاح',
          snackPosition: SnackPosition.BOTTOM,
          margin: EdgeInsets.all(16.w),
        );
        Navigator.of(context).pop(updated);
      } else {
        await ApiService.instance.createJobPosting(body);

        if (Get.isRegistered<TalabatController>()) {
          unawaited(Get.find<TalabatController>().load());
        }
        if (Get.isRegistered<HomeController>()) {
          unawaited(Get.find<HomeController>().loadJobs());
        }

        if (!mounted) return;
        setState(() => _publishing = false);
        Get.back<void>();
        Get.snackbar(
          'تم النشر',
          'تم نشر الوظيفة بنجاح',
          snackPosition: SnackPosition.BOTTOM,
          margin: EdgeInsets.all(16.w),
        );
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _publishing = false);
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      setState(() => _publishing = false);
      messenger.showSnackBar(const SnackBar(content: Text('تعذر نشر الوظيفة')));
    }
  }

  Widget _bottomBar() {
    return SafeArea(
      top: false,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 16.h),
        decoration: BoxDecoration(
          color: const Color(0xFFFDFEFF),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(44.r),
            topRight: Radius.circular(44.r),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A000000),
              offset: Offset(0, -1),
              blurRadius: 16.1,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              constraints: BoxConstraints(minHeight: 48.h),
              decoration: BoxDecoration(
                color: const Color(0x1AFF9914),
                borderRadius: BorderRadius.circular(10.r),
              ),
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
              child: Row(
                textDirection: TextDirection.rtl,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Image.asset(
                    'assets/onboarding_cosmetics/الملاحضة.png',
                    width: 18.w,
                    height: 18.h,
                    fit: BoxFit.contain,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      'أي حقل يُترك فارغ لن يظهر ضمن المتطلبات.',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontFamily: 'Lama Sans',
                        fontWeight: FontWeight.w700,
                        fontSize: 14.sp,
                        height: 1.5,
                        color: const Color(0xFFDC810A),
                      ),
                    ),
                  ),
                ],
              ),
            ),
              SizedBox(height: 16.h),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 52.h,
                      child: ElevatedButton(
                        onPressed: _publishing
                            ? null
                            : () => unawaited(_publishJob()),
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: const Color(0xFFFF9914),
                          disabledBackgroundColor: const Color(0xFFFF9914),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          padding: EdgeInsets.fromLTRB(0, 14.h, 0, 14.h),
                        ),
                        child: _publishing
                            ? SizedBox(
                                width: 22.w,
                                height: 22.h,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                _isEditMode ? 'حفظ التعديلات' : 'نشر الآن',
                                style: TextStyle(
                                  fontFamily: 'Lama Sans',
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16.sp,
                                  height: 1.5,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: SizedBox(
                      width: 167.w,
                      height: 52.h,
                      child: OutlinedButton(
                        onPressed: _publishing ? null : () => Get.back(),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                            color: Color(0xFFFF9914),
                            width: 1,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          padding: EdgeInsets.fromLTRB(0, 14.h, 0, 14.h),
                        ),
                        child: Text(
                          'إلغاء',
                          style: TextStyle(
                            fontFamily: 'Lama Sans',
                            fontWeight: FontWeight.w700,
                            fontSize: 16.sp,
                            height: 1.5,
                            color: const Color(0xFFFF9914),
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

class DottedBorderButton extends StatelessWidget {
  const DottedBorderButton({
    super.key,
    required this.text,
    required this.onTap,
  });

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: DottedBorder(
        color: const Color(0xFF9CA3AF),
        dashPattern: const [6, 4],
        strokeWidth: 1.1,
        borderType: BorderType.RRect,
        radius: Radius.circular(12.r),
        child: Container(
          width: double.infinity,
          height: 46.h,
          alignment: Alignment.center,
          child: Text(
            text,
            style: TextStyle(
              fontFamily: 'Lama Sans',
              fontWeight: FontWeight.w700,
              fontSize: 18.sp,
              color: const Color(0xFF6B7280),
            ),
          ),
        ),
      ),
    );
  }
}

class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  static const String _arabicIndic = '٠١٢٣٤٥٦٧٨٩';
  static const String _latinDigits = '0123456789';

  /// تحويل الأرقام العربية إلى لاتينية ثم إبقاء الأرقام فقط.
  static String stripToDigits(String raw) {
    final b = StringBuffer();
    for (final c in raw.split('')) {
      final i = _arabicIndic.indexOf(c);
      if (i >= 0) {
        b.write(_latinDigits[i]);
      } else if (RegExp(r'[0-9]').hasMatch(c)) {
        b.write(c);
      }
    }
    return b.toString();
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = stripToDigits(newValue.text);
    if (digits.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }
    final number = int.tryParse(digits);
    if (number == null) return oldValue;
    final formatted = formatIqdWithCommas(number);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
