/// أسماء مسارات GetX (بدون شرطة مزدوجة في القيم لتفادي أخطاء التحليل).
abstract class Routes {
  /// نقطة الدخول: تتحقق من وجود جلسة محفوظة ثم تنتقل إلى الرئيسية أو الإعداد الأولي.
  static const splash = '/splash';
  static const onboarding = '/onboarding';
  static const signIn = '/sign-in';
  static const signUp = '/sign-up';
  static const phoneOtp = '/phone-otp';
  static const main = '/main';
  static const professionalProfile = '/professional-profile';
  static const professionalProfileEdit = '/professional-profile/edit';
  static const jobSearch = '/job-search';
  static const jobSearchTextResults = '/job-search-text-results';
  static const jobSearchResults = '/job-search-results';
  static const createJob = '/create-job';
  static const contactUs = '/contact-us';
  static const privacyPolicy = '/privacy-policy';
  static const aboutApp = '/about-app';
}
