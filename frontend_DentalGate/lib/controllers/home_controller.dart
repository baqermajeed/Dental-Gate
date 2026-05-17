import 'dart:async';

import 'package:get/get.dart';

import 'package:dental_gate/core/app_routes.dart';
import 'package:dental_gate/models/doctor_profile_full.dart';
import 'package:dental_gate/models/home_slider_item.dart';
import 'package:dental_gate/models/job_posting.dart';
import 'package:dental_gate/models/user_profile.dart';
import 'package:dental_gate/services/api_service.dart';
import 'package:dental_gate/services/fcm_registration_service.dart';

class HomeController extends GetxController {
  final profile = Rxn<UserProfile>();
  final profileSpecialty = RxnString();
  final profileError = Rxn<String>();
  final isProfileLoading = true.obs;

  final jobs = <JobPosting>[].obs;
  final jobsError = Rxn<String>();
  final isJobsLoading = true.obs;
  final sliders = <HomeSliderItem>[].obs;
  final sliderIndex = 0.obs;

  /// نص البحث النشط في قائمة الوظائف (يُضبط من شاشة البحث).
  final jobSearchQuery = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadProfile();
    loadJobs();
    loadSliders();
  }

  Future<void> loadProfile() async {
    isProfileLoading.value = true;
    profileError.value = null;
    profileSpecialty.value = null;
    try {
      final p = await ApiService.instance.fetchMe();
      profile.value = p;
      DoctorProfileFull? doctorProfile;
      try {
        doctorProfile = await ApiService.instance.fetchDoctorProfileFull();
      } catch (_) {
        doctorProfile = null;
      }
      profileSpecialty.value = _resolveProfileSpecialty(
        fromMe: p,
        fromDoctorProfile: doctorProfile,
      );
      unawaited(FcmRegistrationService.instance.syncToBackend());
    } on ApiException catch (e) {
      profileError.value = e.message;
    } catch (_) {
      profileError.value = 'تعذر تحميل الملف الشخصي';
    } finally {
      isProfileLoading.value = false;
    }
  }

  String? _resolveProfileSpecialty({
    required UserProfile fromMe,
    required DoctorProfileFull? fromDoctorProfile,
  }) {
    String? clean(String? v) {
      final t = v?.trim();
      return (t == null || t.isEmpty) ? null : t;
    }

    final degreeType = fromDoctorProfile?.education
        .map((e) => clean(e.degreeType))
        .firstWhere((v) => v != null, orElse: () => null);

    return clean(fromDoctorProfile?.professionalTitle) ??
        clean(fromMe.professionalTitle) ??
        degreeType;
  }

  Future<void> loadJobs() async {
    isJobsLoading.value = true;
    jobsError.value = null;
    try {
      final list = await ApiService.instance.fetchJobPostings();
      jobs.assignAll(list);
    } on ApiException catch (e) {
      jobsError.value = e.message;
      jobs.clear();
    } catch (_) {
      jobsError.value = 'تعذر تحميل الوظائف';
      jobs.clear();
    } finally {
      isJobsLoading.value = false;
    }
  }

  Future<void> loadSliders() async {
    try {
      final list = await ApiService.instance.fetchHomeSliders();
      sliders.assignAll(list);
      sliderIndex.value = 0;
    } catch (_) {
      sliders.clear();
      sliderIndex.value = 0;
    }
  }

  void setSliderIndex(int index) {
    sliderIndex.value = index;
  }

  Future<JobPosting?> resolveSliderJob(String jobId) async {
    for (final j in jobs) {
      if (j.id == jobId) return j;
    }
    try {
      return await ApiService.instance.fetchJobById(jobId);
    } catch (_) {
      return null;
    }
  }

  Future<void> refreshAll() async {
    await Future.wait<void>([loadProfile(), loadJobs(), loadSliders()]);
  }

  void setJobSearchQuery(String q) {
    jobSearchQuery.value = q.trim();
  }

  void clearJobSearchQuery() {
    jobSearchQuery.value = '';
  }

  bool _jobMatchesSearch(JobPosting j, String q) {
    if (q.isEmpty) return true;
    final t = q.toLowerCase();
    bool has(String s) => s.toLowerCase().contains(t);
    if (has(j.workplaceName)) return true;
    if (has(j.requiredSpecialty)) return true;
    if (has(j.workplaceAddress)) return true;
    if (has(j.description ?? '')) return true;
    return j.coreSkills.any(has);
  }

  /// فلترة بالنص الممرَّر (لا تلمس [jobSearchQuery]) — لشاشة النتائج حتى لا يُعاد بناء الرئيسية خلفها.
  List<JobPosting> jobsMatchingQuery(String query) {
    final q = query.trim();
    if (q.isEmpty) return jobs.toList();
    return jobs.where((j) => _jobMatchesSearch(j, q)).toList();
  }

  static bool _experienceBandMatches(int years, int experienceIndex) {
    switch (experienceIndex) {
      case 0:
        return years >= 1 && years <= 3;
      case 1:
        return years >= 3 && years <= 5;
      case 2:
      default:
        return years > 5;
    }
  }

  /// نص + خبرة (فهرس الشيت) + محافظة (مطابقة جزئية في العنوان/اسم مكان العمل).
  List<JobPosting> jobsMatchingJobSearchFilters(
    String textQuery, {
    int? experienceIndex,
    String? province,
  }) {
    final q = textQuery.trim();
    final prov = province?.trim();
    final expIdx = experienceIndex;
    return jobs.where((j) {
      if (q.isNotEmpty && !_jobMatchesSearch(j, q)) return false;
      if (expIdx != null &&
          !_experienceBandMatches(j.yearsExperience, expIdx)) {
        return false;
      }
      if (prov != null && prov.isNotEmpty) {
        final hay =
            '${j.workplaceAddress} ${j.workplaceName}'.toLowerCase();
        if (!hay.contains(prov.toLowerCase())) return false;
      }
      return true;
    }).toList();
  }

  /// وظائف مطابقة لـ [jobSearchQuery] (فارغ = الكل).
  List<JobPosting> jobsMatchingSearch() {
    return jobsMatchingQuery(jobSearchQuery.value);
  }

  Future<void> logout() async {
    await ApiService.instance.logout();
    Get.offAllNamed(Routes.signIn);
  }

  void clearSessionStateAfterLogout() {
    profile.value = null;
    profileSpecialty.value = null;
    profileError.value = null;
    isProfileLoading.value = false;
    jobs.clear();
    jobsError.value = null;
    isJobsLoading.value = false;
    sliders.clear();
    sliderIndex.value = 0;
    jobSearchQuery.value = '';
  }
}
