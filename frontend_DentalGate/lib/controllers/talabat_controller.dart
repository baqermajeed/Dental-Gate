import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:dental_gate/models/job_posting.dart';
import 'package:dental_gate/models/my_job_application_item.dart';
import 'package:dental_gate/services/api_service.dart';

enum TalabatSection { applications, postedJobs }

class TalabatController extends GetxController {
  final items = <MyJobApplicationItem>[].obs;
  final postedJobs = <JobPosting>[].obs;

  /// عدد المتقدمين لكل وظيفة منشورة (`GET /jobs/{id}/applications/count`).
  final applicantCountByJobId = <String, int>{}.obs;
  final errorMessage = Rxn<String>();
  final isLoading = true.obs;
  final searchQuery = ''.obs;
  final selectedStatus = Rxn<JobApplicationStatusApi>();
  final selectedGovernorate = Rxn<String>();
  final activeSection = TalabatSection.applications.obs;

  late final TextEditingController searchController;

  List<MyJobApplicationItem> get filteredItems {
    final q = searchQuery.value.trim().toLowerCase();
    final gov = selectedGovernorate.value?.trim();
    return items.where((e) {
      final j = e.job;
      final haystack =
          '${j.requiredSpecialty} ${j.workplaceName} ${j.workplaceAddress} ${j.locationSubtitle}'
              .toLowerCase();
      final matchSearch = q.isEmpty || haystack.contains(q);
      final matchStatus =
          selectedStatus.value == null || e.status == selectedStatus.value;
      final matchGovernorate =
          gov == null ||
          gov.isEmpty ||
          j.workplaceAddress.contains(gov) ||
          j.locationSubtitle.contains(gov);
      return matchSearch && matchStatus && matchGovernorate;
    }).toList();
  }

  List<JobPosting> get filteredPostedJobs {
    final q = searchQuery.value.trim().toLowerCase();
    final gov = selectedGovernorate.value?.trim();
    return postedJobs.where((j) {
      final haystack =
          '${j.requiredSpecialty} ${j.workplaceName} ${j.workplaceAddress} ${j.locationSubtitle}'
              .toLowerCase();
      final matchSearch = q.isEmpty || haystack.contains(q);
      final matchGovernorate =
          gov == null ||
          gov.isEmpty ||
          j.workplaceAddress.contains(gov) ||
          j.locationSubtitle.contains(gov);
      return matchSearch && matchGovernorate;
    }).toList();
  }

  bool get hasActiveFilters =>
      selectedStatus.value != null ||
      (selectedGovernorate.value?.trim().isNotEmpty ?? false);

  void applyFilters({JobApplicationStatusApi? status, String? governorate}) {
    selectedStatus.value = status;
    selectedGovernorate.value =
        governorate == null || governorate.trim().isEmpty ? null : governorate;
  }

  void clearFilters() {
    selectedStatus.value = null;
    selectedGovernorate.value = null;
  }

  void setSection(TalabatSection section) {
    if (activeSection.value == section) return;
    activeSection.value = section;
    clearFilters();
  }

  @override
  void onInit() {
    super.onInit();
    searchController = TextEditingController();
    searchController.addListener(() {
      searchQuery.value = searchController.text;
    });
    load();
  }

  Future<void> _loadApplicantCounts(List<JobPosting> jobs) async {
    if (jobs.isEmpty) {
      applicantCountByJobId.clear();
      return;
    }
    final ids = jobs.map((j) => j.id).toSet().toList();
    final entries = await Future.wait(
      ids.map((id) async {
        try {
          final n = await ApiService.instance.fetchMyJobApplicationCount(id);
          return MapEntry(id, n);
        } catch (_) {
          return MapEntry(id, 0);
        }
      }),
    );
    applicantCountByJobId.assignAll(Map<String, int>.fromEntries(entries));
  }

  void clearSessionStateAfterLogout() {
    items.clear();
    postedJobs.clear();
    applicantCountByJobId.clear();
    errorMessage.value = null;
    isLoading.value = false;
    searchQuery.value = '';
    selectedStatus.value = null;
    selectedGovernorate.value = null;
    activeSection.value = TalabatSection.applications;
    searchController.clear();
  }

  Future<void> load() async {
    isLoading.value = true;
    errorMessage.value = null;
    try {
      final results = await Future.wait<dynamic>([
        ApiService.instance.fetchMyJobApplications(),
        ApiService.instance.fetchMyPostedJobs(),
      ]);
      final myApplications = results[0] as List<MyJobApplicationItem>;
      final myPosted = results[1] as List<JobPosting>;

      items.assignAll(myApplications);
      postedJobs.assignAll(myPosted);
      await _loadApplicantCounts(myPosted);
    } on ApiException catch (e) {
      errorMessage.value = e.message;
      items.clear();
      postedJobs.clear();
      applicantCountByJobId.clear();
    } catch (_) {
      errorMessage.value = 'تعذر تحميل الطلبات';
      items.clear();
      postedJobs.clear();
      applicantCountByJobId.clear();
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }
}
