import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'package:dental_gate/core/app_routes.dart';
import 'package:dental_gate/models/otp_models.dart';
import 'package:dental_gate/services/api_service.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  static const Color _primary = Color(0xFF5993FF);
  static const Color _bg = Color(0xFFF3F4F6);
  static const Color _textDark = Color(0xFF0E1525);
  static const Color _textBody = Color(0xFF333640);
  static const Color _fieldBg = Color(0xFFEAEAEC);
  static const Color _hint = Color(0xFFADADAD);

  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();

  bool _loading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  String? _validatePhone(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'اكتب رقم الهاتف';
    if (!RegExp(r'^\d+$').hasMatch(v)) return 'رقم الهاتف أرقام فقط';
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

  /// إرسال رمز التحقق والانتقال إلى صفحة إدخال الرمز.
  Future<void> _continueToOtp() async {
    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) return;

    setState(() => _loading = true);
    try {
      final phone = _phoneController.text.trim();
      await ApiService.instance.requestOtp(phone);
      if (!mounted) return;
      await Get.toNamed<void>(
        Routes.phoneOtp,
        arguments: PhoneOtpRouteArgs(phone: phone, flow: OtpFlow.signIn),
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
      backgroundColor: _bg,
      body: SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Column(
              children: [
                SizedBox(height: 58.h),
                SizedBox(
                  width: 100.w,
                  height: 100.h,
                  child: Image.asset(
                    'assets/logo/inside.png',
                    fit: BoxFit.contain,
                  ),
                ),
                SizedBox(height: 34.h),
                Text(
                  'تسجيل الدخول',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Lama Sans',
                    fontSize: 26.sp,
                    fontWeight: FontWeight.w700,
                    color: _textDark,
                    height: 1.5,
                  ),
                ),
                SizedBox(height: 16.h),
                Text(
                  'أدخل رقم هاتفك، ثم رمز التحقق في الخطوة التالية',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Lama Sans',
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: _textBody,
                    height: 1.5,
                  ),
                ),
                SizedBox(height: 40.h),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _Field(
                        hint: 'اكتب رقم هاتفك',
                        width: 353.w,
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: _validatePhone,
                      ),
                      SizedBox(height: 20.h),
                      SizedBox(
                        width: 353.w,
                        height: 58.h,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primary,
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
                                  'تسجيل الدخول',
                                  textAlign: TextAlign.center,
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
                SizedBox(height: 26.h),
                Wrap(
                  alignment: WrapAlignment.end,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 2.w,
                  children: [
                    Text(
                      'ليس لديك حساب ؟ ',
                      style: TextStyle(
                        fontFamily: 'Lama Sans',
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: _textDark,
                        height: 1.5,
                      ),
                    ),
                    TextButton(
                      onPressed: _loading
                          ? null
                          : () {
                              Get.toNamed(Routes.signUp);
                            },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'أنشئ واحدًا',
                        style: TextStyle(
                          fontFamily: 'Lama Sans',
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: _primary,
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
          color: _SignInScreenState._textDark,
        ),
        decoration: InputDecoration(
          filled: true,
          fillColor: _SignInScreenState._fieldBg,
          hintText: hint,
          hintStyle: TextStyle(
            fontFamily: 'Lama Sans',
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: _SignInScreenState._hint,
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
