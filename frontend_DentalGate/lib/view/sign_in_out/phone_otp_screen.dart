import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'package:dental_gate/core/app_routes.dart';
import 'package:dental_gate/models/otp_models.dart';
import 'package:dental_gate/services/api_service.dart';

/// إدخال رمز التحقق المرسل إلى الهاتف بعد تسجيل الدخول أو إنشاء الحساب.
class PhoneOtpScreen extends StatefulWidget {
  const PhoneOtpScreen({
    super.key,
    required this.phone,
    required this.flow,
    this.signUpData,
  }) : assert(
         flow != OtpFlow.signUp || signUpData != null,
         'signUpData مطلوب عند إنشاء الحساب',
       );

  final String phone;
  final OtpFlow flow;
  final SignUpOtpArgs? signUpData;

  @override
  State<PhoneOtpScreen> createState() => _PhoneOtpScreenState();
}

class _PhoneOtpScreenState extends State<PhoneOtpScreen> {
  static const Color _primary = Color(0xFF5993FF);
  static const Color _bg = Color(0xFFF3F4F6);
  static const Color _textDark = Color(0xFF0E1525);
  static const Color _textBody = Color(0xFF333640);
  static const Color _fieldBg = Color(0xFFEAEAEC);
  static const Color _hint = Color(0xFFADADAD);

  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();

  bool _loading = false;
  bool _resendLoading = false;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  String get _phoneDisplay => widget.phone.trim();

  String? _validateOtp(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'اكتب رمز التحقق';
    if (v.length != 6) return 'الرمز مكوّن من 6 أرقام';
    if (!RegExp(r'^\d{6}$').hasMatch(v)) return 'الرمز أرقام فقط';
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

  Future<void> _resendOtp() async {
    setState(() => _resendLoading = true);
    try {
      await ApiService.instance.requestOtp(_phoneDisplay);
      if (!mounted) return;
      _showMessage('تم إعادة إرسال الرمز');
    } on ApiException catch (e) {
      _showMessage(e.message, error: true);
    } catch (_) {
      _showMessage('تعذر الاتصال بالخادم', error: true);
    } finally {
      if (mounted) setState(() => _resendLoading = false);
    }
  }

  Future<void> _confirm() async {
    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) return;

    setState(() => _loading = true);
    try {
      final code = _otpController.text.trim();

      if (widget.flow == OtpFlow.signIn) {
        final result = await ApiService.instance.verifyOtp(
          phone: _phoneDisplay,
          code: code,
        );
        if (!mounted) return;
        if (!result.accountExists) {
          _showMessage(
            'لا يوجد حساب بهذا الرقم. أنشئ حساباً من شاشة التسجيل.',
            error: true,
          );
          return;
        }
        Get.offAllNamed(Routes.main);
        return;
      }

      final verify = await ApiService.instance.verifyOtp(
        phone: _phoneDisplay,
        code: code,
      );
      if (!mounted) return;

      final data = widget.signUpData!;

      if (verify.accountExists) {
        _showMessage('يوجد حساب بهذا الرقم. تم تسجيل دخولك.');
        Get.offAllNamed(Routes.main);
        return;
      }

      await ApiService.instance.register(
        name: data.name,
        phone: data.phone,
        email: data.email,
        age: data.age,
        genderApi: data.genderApi,
      );
      await ApiService.instance.patchDoctorProfile(
        body: {
          'governorate': data.governorate,
          'professional_title': data.professionalTitle,
        },
      );
      if (!mounted) return;
      Get.offAllNamed(Routes.main);
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
    final title = widget.flow == OtpFlow.signIn
        ? 'تسجيل الدخول'
        : 'إنشاء الحساب';
    final actionLabel = widget.flow == OtpFlow.signIn
        ? 'تسجيل الدخول'
        : 'إنشاء الحساب';

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        foregroundColor: _textDark,
        centerTitle: true,
        title: Text(
          'رمز التحقق',
          style: TextStyle(
            fontFamily: 'Lama Sans',
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: _textDark,
          ),
        ),
      ),
      body: SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: 24.h),
                  Container(
                    width: 88.w,
                    height: 88.h,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE8E8EA),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.sms_outlined,
                      size: 40.sp,
                      color: _primary,
                    ),
                  ),
                  SizedBox(height: 28.h),
                  Text(
                    title,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontFamily: 'Lama Sans',
                      fontSize: 24.sp,
                      fontWeight: FontWeight.w700,
                      color: _textDark,
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    'أدخل الرمز المكوّن من 6 أرقام المرسل إلى\n$_phoneDisplay',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontFamily: 'Lama Sans',
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: _textBody,
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: 36.h),
                  SizedBox(
                    width: 353.w,
                    height: 58.h,
                    child: TextFormField(
                      controller: _otpController,
                      autofocus: true,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 6,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: TextStyle(
                        fontFamily: 'Lama Sans',
                        fontSize: 22.sp,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 8,
                        color: _textDark,
                      ),
                      validator: _validateOtp,
                      decoration: InputDecoration(
                        counterText: '',
                        filled: true,
                        fillColor: _fieldBg,
                        hintText: '• • • • • •',
                        hintStyle: TextStyle(
                          fontFamily: 'Lama Sans',
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w600,
                          color: _hint,
                          letterSpacing: 6,
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 16.h,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide(color: _primary, width: 1.5),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: (_loading || _resendLoading)
                          ? null
                          : _resendOtp,
                      child: _resendLoading
                          ? SizedBox(
                              width: 18.w,
                              height: 18.h,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: _primary,
                              ),
                            )
                          : Text(
                              'إعادة إرسال الرمز',
                              style: TextStyle(
                                fontFamily: 'Lama Sans',
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w700,
                                color: _primary,
                              ),
                            ),
                    ),
                  ),
                  SizedBox(height: 24.h),
                  SizedBox(
                    width: double.infinity,
                    height: 58.h,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      onPressed: _loading ? null : _confirm,
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
                              actionLabel,
                              style: TextStyle(
                                fontFamily: 'Lama Sans',
                                fontSize: 26.sp,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                height: 1.5,
                              ),
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
  }
}
