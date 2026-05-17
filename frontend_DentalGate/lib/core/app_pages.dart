import 'package:get/get.dart';

import 'package:dental_gate/core/app_routes.dart';
import 'package:dental_gate/core/main_shell_binding.dart';
import 'package:dental_gate/core/professional_profile_binding.dart';
import 'package:dental_gate/view/profile/professional_profile_view.dart';
import 'package:dental_gate/view/profile/professional_profile_edit_view.dart';
import 'package:dental_gate/models/job_posting.dart';
import 'package:dental_gate/models/job_search_filter_criteria.dart';
import 'package:dental_gate/models/doctor_profile_full.dart';
import 'package:dental_gate/models/otp_models.dart';
import 'package:dental_gate/view/home/job_search_results_view.dart';
import 'package:dental_gate/view/home/job_search_text_results_view.dart';
import 'package:dental_gate/view/home/job_search_view.dart';
import 'package:dental_gate/view/jobs/create_job_view.dart';
import 'package:dental_gate/view/shell/main_shell.dart';
import 'package:dental_gate/view/sign_in_out/onboarding_screen.dart';
import 'package:dental_gate/view/splash/splash_screen.dart';
import 'package:dental_gate/view/sign_in_out/phone_otp_screen.dart';
import 'package:dental_gate/view/sign_in_out/sign_in_screen.dart';
import 'package:dental_gate/view/sign_in_out/sign_up_screen.dart';
import 'package:dental_gate/view/settings/contact_us_view.dart';
import 'package:dental_gate/view/settings/privacy_policy_view.dart';
import 'package:dental_gate/view/settings/about_app_view.dart';

class AppPages {
  AppPages._();

  static final List<GetPage<dynamic>> pages = <GetPage<dynamic>>[
    GetPage(
      name: Routes.splash,
      page: () => const SplashScreen(),
    ),
    GetPage(
      name: Routes.onboarding,
      page: () => const OnboardingScreen(),
    ),
    GetPage(
      name: Routes.signIn,
      page: () => const SignInScreen(),
    ),
    GetPage(
      name: Routes.signUp,
      page: () => const SignUpScreen(),
    ),
    GetPage(
      name: Routes.phoneOtp,
      page: () {
        final args = Get.arguments as PhoneOtpRouteArgs;
        return PhoneOtpScreen(
          phone: args.phone,
          flow: args.flow,
          signUpData: args.signUpData,
        );
      },
    ),
    GetPage(
      name: Routes.main,
      page: () => const MainShell(),
      binding: MainShellBinding(),
    ),
    GetPage(
      name: Routes.professionalProfile,
      page: () => const ProfessionalProfileView(),
      binding: ProfessionalProfileBinding(),
    ),
    GetPage(
      name: Routes.professionalProfileEdit,
      page: () {
        final a = Get.arguments;
        return ProfessionalProfileEditView(
          initialProfile: a is DoctorProfileFull ? a : null,
        );
      },
    ),
    GetPage(
      name: Routes.jobSearch,
      page: () {
        final a = Get.arguments;
        final initial = a is String && a.trim().isNotEmpty
            ? a.trim()
            : (a is Map && a['initialQuery'] is String
                  ? (a['initialQuery'] as String).trim()
                  : null);
        final openFilter = a is Map && a['openFilter'] == true;
        return JobSearchView(
          initialQuery: initial,
          openFilterOnStart: openFilter,
        );
      },
    ),
    GetPage(
      name: Routes.jobSearchTextResults,
      page: () {
        final a = Get.arguments;
        final q = a is String ? a.trim() : '';
        return JobSearchTextResultsView(initialQuery: q);
      },
    ),
    GetPage(
      name: Routes.jobSearchResults,
      page: () {
        final a = Get.arguments;
        if (a is JobSearchFilterCriteria) {
          return JobSearchResultsView(
            initialQuery: a.specialtyText,
            initialExperienceIndex: a.experienceIndex,
            initialProvince: a.province,
          );
        }
        final q = a is String ? a.trim() : '';
        return JobSearchTextResultsView(initialQuery: q);
      },
    ),
    GetPage(
      name: Routes.createJob,
      page: () {
        final a = Get.arguments;
        return CreateJobView(
          existingJob: a is JobPosting ? a : null,
        );
      },
    ),
    GetPage(
      name: Routes.contactUs,
      page: () => const ContactUsView(),
    ),
    GetPage(
      name: Routes.privacyPolicy,
      page: () => const PrivacyPolicyView(),
    ),
    GetPage(
      name: Routes.aboutApp,
      page: () => const AboutAppView(),
    ),
  ];
}
