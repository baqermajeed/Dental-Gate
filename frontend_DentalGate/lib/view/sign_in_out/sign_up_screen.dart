import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'package:dental_gate/core/app_routes.dart';
import 'package:dental_gate/models/otp_models.dart';
import 'package:dental_gate/services/api_service.dart';
import 'package:dental_gate/widgets/modern_options_bottom_sheet.dart';
import 'package:dental_gate/widgets/modern_picker_field.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  static const Color _primary = Color(0xFF5993FF);
  static const Color _bg = Color(0xFFF3F4F6);
  static const Color _textDark = Color(0xFF0E1525);
  static const Color _textBody = Color(0xFF333640);
  static const Color _fieldBg = Color(0xFFEAEAEC);
  static const Color _hint = Color(0xFFADADAD);

  /// أزرق أخف للتدرجات والتظليل (يتماشى مع البروفايل).
  static const Color _primarySoft = Color(0xFF7FB2E4);
  static const Color _surfaceElevated = Color(0xFFFDFEFF);

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
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
  static const List<String> _specialties = [
    'طبيب اسنان',
    'مساعد طبيب',
    'تقني اسنان',
  ];

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  /// يُحسب منه العمر المرسل للخادم (1–120).
  DateTime? _birthDate;

  String _gender = 'أنثى';
  String? _selectedGovernorate;
  String? _selectedSpecialty;
  bool _loading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  static int _ageYearsFromBirth(DateTime birth) {
    final t = DateTime.now();
    var y = t.year - birth.year;
    if (t.month < birth.month ||
        (t.month == birth.month && t.day < birth.day)) {
      y--;
    }
    return y;
  }

  String _formatBirthDisplay(DateTime d) =>
      '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';

  Future<void> _pickBirthDate() async {
    if (_loading) return;
    final now = DateTime.now();
    final minDate = DateTime(now.year - 120, 1, 1);
    final maxDate = DateTime(now.year, now.month, now.day);
    var initial = _birthDate ?? DateTime(now.year - 25, now.month, now.day);
    if (initial.isBefore(minDate)) initial = minDate;
    if (initial.isAfter(maxDate)) initial = maxDate;

    final picked = await showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) => _ModernBirthDateSheet(
        initial: initial,
        minDate: minDate,
        maxDate: maxDate,
      ),
    );
    if (picked != null && mounted) {
      setState(() => _birthDate = picked);
    }
  }

  Future<String?> _pickFromModernSheet({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<String> options,
    String? selected,
  }) async {
    if (_loading) return null;
    return showModernOptionsSheet(
      context: context,
      title: title,
      subtitle: subtitle,
      icon: icon,
      options: options,
      selected: selected,
    );
  }

  String? _validateName(String? value) {
    final v = (value ?? '').trim();
    final parts = v.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (v.isEmpty) return 'اكتب الاسم';
    if (parts.length < 3) return 'اكتب الاسم الثلاثي فما فوق';
    final letterParts = parts.every(
      (p) => RegExp(r'^[A-Za-z\u0600-\u06FF]+$').hasMatch(p),
    );
    if (!letterParts) return 'يرجى كتابة الاسم بشكل صحيح';
    return null;
  }

  String? _validatePhone(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'اكتب رقم الهاتف';
    if (!RegExp(r'^07\d{9}$').hasMatch(v)) {
      return 'رقم عراقي 11 رقماً يبدأ بـ 07';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'اكتب الإيميل';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v)) {
      return 'صيغة الإيميل غير صحيحة';
    }
    return null;
  }

  void _showMessage(String text, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text, textAlign: TextAlign.right),
        backgroundColor: error ? Colors.red.shade800 : null,
      ),
    );
  }

  /// إرسال رمز التحقق والانتقال إلى صفحة إدخال الرمز لإكمال إنشاء الحساب.
  Future<void> _continueToOtp() async {
    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) return;

    if (_birthDate == null) {
      _showMessage('اختر تاريخ الميلاد (يوم / شهر / سنة)', error: true);
      return;
    }
    final age = _ageYearsFromBirth(_birthDate!);
    if (age < 1 || age > 120) {
      _showMessage('العمر المحسوب يجب أن يكون بين 1 و 120 سنة', error: true);
      return;
    }
    if (_selectedGovernorate == null) {
      _showMessage('اختر المحافظة', error: true);
      return;
    }
    if (_selectedSpecialty == null) {
      _showMessage('اختر التخصص', error: true);
      return;
    }

    setState(() => _loading = true);
    try {
      final phone = _phoneController.text.trim();
      await ApiService.instance.requestOtp(phone);
      if (!mounted) return;

      final args = SignUpOtpArgs(
        name: _nameController.text.trim(),
        phone: phone,
        email: _emailController.text.trim(),
        age: age,
        genderApi: _gender == 'ذكر' ? 'male' : 'female',
        governorate: _selectedGovernorate!,
        professionalTitle: _selectedSpecialty!,
      );

      await Get.toNamed<void>(
        Routes.phoneOtp,
        arguments: PhoneOtpRouteArgs(
          phone: phone,
          flow: OtpFlow.signUp,
          signUpData: args,
        ),
      );
    } on ApiException catch (e) {
      _showMessage(e.message, error: true);
    } catch (_) {
      _showMessage('تعذر الاتصال بالخادم', error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SignUpScreen._bg,
      body: SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.only(bottom: 24.h),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                  SizedBox(height: 10.h),
                  SizedBox(
                    width: 100.w,
                    height: 100.h,
                    child: Image.asset(
                      'assets/logo/inside.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    'أنشاء الحساب',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Lama Sans',
                      fontSize: 23.sp,
                      fontWeight: FontWeight.w700,
                      color: SignUpScreen._textDark,
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'أدخل معلوماتك، ثم أدخل رمز التحقق في الخطوة التالية',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Lama Sans',
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: SignUpScreen._textBody,
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  _Field(
                    hint: 'اكتب اسمك',
                    width: double.infinity,
                    controller: _nameController,
                    keyboardType: TextInputType.name,
                    validator: _validateName,
                  ),
                  SizedBox(height: 12.h),
                  _Field(
                    hint: 'اكتب رقم هاتفك',
                    width: double.infinity,
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(11),
                    ],
                    validator: _validatePhone,
                  ),
                  SizedBox(height: 12.h),
                  SizedBox(
                    width: double.infinity,
                    child: Row(
                      children: [
                        Expanded(
                          child: _GenderBox(
                            selected: _gender == 'ذكر',
                            text: 'ذكر',
                            onTap: _loading
                                ? null
                                : () => setState(() => _gender = 'ذكر'),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: _GenderBox(
                            selected: _gender == 'أنثى',
                            text: 'أنثى',
                            onTap: _loading
                                ? null
                                : () => setState(() => _gender = 'أنثى'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 12.h),
                  ModernPickerField(
                    width: double.infinity,
                    hint: 'اختر المحافظة',
                    value: _selectedGovernorate,
                    icon: Icons.location_on_rounded,
                    enabled: !_loading,
                    onTap: () async {
                      final value = await _pickFromModernSheet(
                        title: 'اختيار المحافظة',
                        subtitle: 'اختر المحافظة الأقرب لمكان عملك',
                        icon: Icons.location_city_rounded,
                        options: _governorates,
                        selected: _selectedGovernorate,
                      );
                      if (value != null && mounted) {
                        setState(() => _selectedGovernorate = value);
                      }
                    },
                  ),
                  SizedBox(height: 12.h),
                  ModernPickerField(
                    width: double.infinity,
                    hint: 'اختر التخصص',
                    value: _selectedSpecialty,
                    icon: Icons.medical_services_rounded,
                    enabled: !_loading,
                    onTap: () async {
                      final value = await _pickFromModernSheet(
                        title: 'اختيار التخصص',
                        subtitle: 'اختر تخصصك بدقة لنتائج أفضل',
                        icon: Icons.workspace_premium_rounded,
                        options: _specialties,
                        selected: _selectedSpecialty,
                      );
                      if (value != null && mounted) {
                        setState(() => _selectedSpecialty = value);
                      }
                    },
                  ),
                  SizedBox(height: 12.h),
                  _BirthDateTile(
                    width: double.infinity,
                    birthDate: _birthDate,
                    format: _formatBirthDisplay,
                    ageYears: _birthDate == null
                        ? null
                        : _ageYearsFromBirth(_birthDate!),
                    enabled: !_loading,
                    onTap: _pickBirthDate,
                  ),
                  SizedBox(height: 12.h),
                  _Field(
                    hint: 'اكتب ايميلك',
                    width: double.infinity,
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    validator: _validateEmail,
                  ),
                  SizedBox(height: 12.h),
                  SizedBox(
                    width: double.infinity,
                    height: 56.h,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: SignUpScreen._primary,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 0,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      onPressed: _loading ? null : _continueToOtp,
                      child: _loading
                          ? SizedBox(
                              width: 24.w,
                              height: 24.h,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'أنشاء الحساب',
                              style: TextStyle(
                                fontFamily: 'Lama Sans',
                                fontSize: 24.sp,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                height: 1.5,
                              ),
                            ),
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Wrap(
                    alignment: WrapAlignment.end,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 2.w,
                    children: [
                      Text(
                        'لديك حساب ؟ ',
                        style: TextStyle(
                          fontFamily: 'Lama Sans',
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: SignUpScreen._textDark,
                          height: 1.5,
                        ),
                      ),
                      TextButton(
                        onPressed: _loading ? null : Get.back,
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'سجل الدخول',
                          style: TextStyle(
                            fontFamily: 'Lama Sans',
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: SignUpScreen._primary,
                            decoration: TextDecoration.underline,
                            decorationThickness: 1.2.sp,
                            decorationStyle: TextDecorationStyle.solid,
                            height: 1.5,
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
        ),
      ),
    );
  }
}

/// بوتوم شيت حديث لاختيار تاريخ الميلاد (عجلات + ألوان التطبيق).
class _ModernBirthDateSheet extends StatefulWidget {
  const _ModernBirthDateSheet({
    required this.initial,
    required this.minDate,
    required this.maxDate,
  });

  final DateTime initial;
  final DateTime minDate;
  final DateTime maxDate;

  @override
  State<_ModernBirthDateSheet> createState() => _ModernBirthDateSheetState();
}

class _ModernBirthDateSheetState extends State<_ModernBirthDateSheet> {
  late DateTime _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initial;
  }

  int get _agePreview {
    final t = DateTime.now();
    var y = t.year - _selected.year;
    if (t.month < _selected.month ||
        (t.month == _selected.month && t.day < _selected.day)) {
      y--;
    }
    return y;
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final pickerHeight = 216.h.clamp(180.0, 260.0);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: EdgeInsets.only(top: 12.h),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            width: double.infinity,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.88,
            ),
            decoration: BoxDecoration(
              color: SignUpScreen._surfaceElevated,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
              boxShadow: [
                BoxShadow(
                  color: SignUpScreen._primary.withValues(alpha: 0.18),
                  blurRadius: 40,
                  offset: const Offset(0, -8),
                ),
                const BoxShadow(
                  color: Color(0x14040814),
                  blurRadius: 24,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 16.h + bottom),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: Container(
                        width: 44.w,
                        height: 5.h,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD1D5DB),
                          borderRadius: BorderRadius.circular(100.r),
                        ),
                      ),
                    ),
                    SizedBox(height: 20.h),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.fromLTRB(18.w, 16.h, 18.w, 16.h),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20.r),
                        gradient: LinearGradient(
                          begin: Alignment.topRight,
                          end: Alignment.bottomLeft,
                          colors: [
                            SignUpScreen._primary.withValues(alpha: 0.14),
                            SignUpScreen._primarySoft.withValues(alpha: 0.08),
                            SignUpScreen._surfaceElevated,
                          ],
                        ),
                        border: Border.all(
                          color: SignUpScreen._primary.withValues(alpha: 0.12),
                        ),
                      ),
                      child: Row(
                        textDirection: TextDirection.rtl,
                        children: [
                          Container(
                            width: 48.w,
                            height: 48.w,
                            decoration: BoxDecoration(
                              color: SignUpScreen._primary.withValues(
                                alpha: 0.12,
                              ),
                              borderRadius: BorderRadius.circular(14.r),
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.event_rounded,
                              color: SignUpScreen._primary,
                              size: 26.sp,
                            ),
                          ),
                          SizedBox(width: 14.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'تاريخ الميلاد',
                                  style: TextStyle(
                                    fontFamily: 'Lama Sans',
                                    fontWeight: FontWeight.w800,
                                    fontSize: 20.sp,
                                    height: 1.2,
                                    color: SignUpScreen._textDark,
                                  ),
                                ),
                                SizedBox(height: 4.h),
                                Text(
                                  'مرّر لاختيار اليوم والشهر والسنة بدقة',
                                  style: TextStyle(
                                    fontFamily: 'Lama Sans',
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13.sp,
                                    height: 1.4,
                                    color: SignUpScreen._textBody.withValues(
                                      alpha: 0.88,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 18.h),
                    Container(
                      width: double.infinity,
                      height: pickerHeight,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F7FA),
                        borderRadius: BorderRadius.circular(18.r),
                        border: Border.all(color: const Color(0xFFE8ECF2)),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18.r),
                        child: CupertinoTheme(
                          data: CupertinoThemeData(
                            primaryColor: SignUpScreen._primary,
                            textTheme: CupertinoTextThemeData(
                              dateTimePickerTextStyle: TextStyle(
                                fontFamily: 'Lama Sans',
                                fontSize: 20.sp,
                                fontWeight: FontWeight.w700,
                                color: SignUpScreen._textDark,
                              ),
                            ),
                          ),
                          child: CupertinoDatePicker(
                            mode: CupertinoDatePickerMode.date,
                            initialDateTime: _selected,
                            minimumDate: widget.minDate,
                            maximumDate: widget.maxDate,
                            use24hFormat: true,
                            onDateTimeChanged: (d) {
                              setState(() => _selected = d);
                            },
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 14.h),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 12.h,
                      ),
                      decoration: BoxDecoration(
                        color: SignUpScreen._primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14.r),
                        border: Border.all(
                          color: SignUpScreen._primary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.auto_awesome_rounded,
                            size: 18.sp,
                            color: SignUpScreen._primary,
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            'العمر المحسوب: $_agePreview سنة',
                            style: TextStyle(
                              fontFamily: 'Lama Sans',
                              fontWeight: FontWeight.w800,
                              fontSize: 15.sp,
                              color: SignUpScreen._primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 22.h),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: SignUpScreen._textBody,
                              side: BorderSide(
                                color: SignUpScreen._textBody.withValues(
                                  alpha: 0.25,
                                ),
                              ),
                              padding: EdgeInsets.symmetric(vertical: 14.h),
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
                        SizedBox(width: 12.w),
                        Expanded(
                          flex: 2,
                          child: FilledButton(
                            onPressed: () =>
                                Navigator.of(context).pop<DateTime>(_selected),
                            style: FilledButton.styleFrom(
                              backgroundColor: SignUpScreen._primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: EdgeInsets.symmetric(vertical: 14.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14.r),
                              ),
                              shadowColor: SignUpScreen._primary.withValues(
                                alpha: 0.45,
                              ),
                            ),
                            child: Text(
                              'تأكيد التاريخ',
                              style: TextStyle(
                                fontFamily: 'Lama Sans',
                                fontWeight: FontWeight.w900,
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
        ),
      ),
    );
  }
}

/// صف يشبه حقول النموذج؛ يفتح ورقة اختيار تاريخ الميلاد المخصصة.
class _BirthDateTile extends StatelessWidget {
  const _BirthDateTile({
    required this.width,
    required this.birthDate,
    required this.format,
    required this.ageYears,
    required this.enabled,
    required this.onTap,
  });

  final double width;
  final DateTime? birthDate;
  final String Function(DateTime d) format;
  final int? ageYears;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasDate = birthDate != null;
    return SizedBox(
      width: width,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12.r),
          onTap: enabled ? onTap : null,
          child: Container(
            padding: EdgeInsets.fromLTRB(14.w, 10.h, 14.w, 10.h),
            decoration: BoxDecoration(
              color: SignUpScreen._fieldBg,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: hasDate
                    ? SignUpScreen._primary.withValues(alpha: 0.22)
                    : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Row(
              textDirection: TextDirection.rtl,
              children: [
                Icon(
                  Icons.calendar_month_rounded,
                  color: hasDate ? SignUpScreen._primary : SignUpScreen._hint,
                  size: 22.sp,
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        hasDate
                            ? format(birthDate!)
                            : 'تاريخ الميلاد (يوم / شهر / سنة)',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontFamily: 'Lama Sans',
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: hasDate
                              ? SignUpScreen._textDark
                              : SignUpScreen._hint,
                          height: 1.35,
                        ),
                      ),
                      if (hasDate && ageYears != null) ...[
                        SizedBox(height: 2.h),
                        Text(
                          'العمر المحسوب: $ageYears سنة',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontFamily: 'Lama Sans',
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w600,
                            color: SignUpScreen._textBody.withValues(
                              alpha: 0.85,
                            ),
                            height: 1.3,
                          ),
                        ),
                      ],
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

class _GenderBox extends StatelessWidget {
  const _GenderBox({
    required this.selected,
    required this.text,
    required this.onTap,
  });

  final bool selected;
  final String text;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 58.h,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? Colors.transparent : SignUpScreen._fieldBg,
          borderRadius: BorderRadius.circular(12.r),
          border: selected
              ? Border.all(color: SignUpScreen._primary, width: 2)
              : Border.all(color: Colors.transparent, width: 2),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontFamily: 'Lama Sans',
            fontSize: 16.sp,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
            color: selected ? SignUpScreen._primary : SignUpScreen._hint,
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.hint,
    required this.width,
    required this.controller,
    required this.keyboardType,
    required this.validator,
    this.inputFormatters,
  });

  final String hint;
  final double width;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final FormFieldValidator<String> validator;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 58.h,
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        textAlign: TextAlign.right,
        validator: validator,
        style: TextStyle(
          fontFamily: 'Lama Sans',
          fontSize: 16.sp,
          fontWeight: FontWeight.w600,
          color: SignUpScreen._textDark,
        ),
        decoration: InputDecoration(
          filled: true,
          fillColor: SignUpScreen._fieldBg,
          hintText: hint,
          hintStyle: TextStyle(
            fontFamily: 'Lama Sans',
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: SignUpScreen._hint,
          ),
          contentPadding: EdgeInsets.fromLTRB(19.w, 17.h, 19.w, 17.h),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide.none,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
