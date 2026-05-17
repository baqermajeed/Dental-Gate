/// تدفق شاشة رمز التحقق وبيانات التسجيل المرتبطة بـ GetX والتنقل المسمى.
enum OtpFlow { signIn, signUp }

/// بيانات التسجيل عند [OtpFlow.signUp] فقط.
class SignUpOtpArgs {
  const SignUpOtpArgs({
    required this.name,
    required this.phone,
    required this.email,
    required this.age,
    required this.genderApi,
    required this.governorate,
    required this.professionalTitle,
  });

  final String name;
  final String phone;
  final String email;
  final int age;
  final String genderApi;
  final String governorate;
  final String professionalTitle;
}

/// حجج التنقل إلى [PhoneOtpScreen] عبر `Get.toNamed`.
class PhoneOtpRouteArgs {
  const PhoneOtpRouteArgs({
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
}
