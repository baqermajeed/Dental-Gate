import 'dart:async';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:get/get.dart';
import 'package:hive/hive.dart';

import 'package:dental_gate/models/doctor_search_item.dart';
import 'package:dental_gate/models/job_posting.dart';
import 'package:dental_gate/services/api_service.dart';

class BookmarksController extends GetxController {
  /// اسم صندوق Hive للمحفوظات — يُستخدم عند حذف الحساب لتفريغ القرص.
  static const String hiveBoxName = 'saved_jobs_cache_v1';
  static const String _boxKey = 'saved_jobs';
  static const String _doctorsBoxKey = 'saved_doctors';

  final savedJobs = <JobPosting>[].obs;
  final savedDoctors = <DoctorSearchItem>[].obs;
  final isSyncingDoctors = false.obs;

  late final Box _box;
  bool _boxReady = false;

  bool isSaved(String jobId) => savedJobs.any((j) => j.id == jobId);
  bool isDoctorSaved(String doctorId) =>
      savedDoctors.any((d) => d.id == doctorId);

  @override
  void onInit() {
    super.onInit();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      _box = await Hive.openBox(hiveBoxName);
      _boxReady = true;
      _loadFromCache();
    } catch (e, st) {
      debugPrint('Bookmarks cache init error: $e\n$st');
    }
    unawaited(syncFromServer());
  }

  void _loadFromCache() {
    if (!_boxReady) return;
    try {
      final raw = _box.get(_boxKey);
      if (raw is List) {
        final jobs = raw
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .map(JobPosting.fromJson)
            .toList();
        savedJobs.assignAll(jobs);
      }

      final doctorsRaw = _box.get(_doctorsBoxKey);
      if (doctorsRaw is List) {
        final doctors = doctorsRaw
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .map(DoctorSearchItem.fromJson)
            .toList();
        savedDoctors.assignAll(doctors);
      }
    } catch (e, st) {
      debugPrint('Bookmarks cache read error: $e\n$st');
    }
  }

  Future<void> _saveCache() async {
    if (!_boxReady) return;
    try {
      await _box.put(
        _boxKey,
        savedJobs.map(_jobToJson).toList(),
      );
      await _box.put(
        _doctorsBoxKey,
        savedDoctors.map(_doctorToJson).toList(),
      );
    } catch (e, st) {
      debugPrint('Bookmarks cache write error: $e\n$st');
    }
  }

  Map<String, dynamic> _jobToJson(JobPosting j) {
    return {
      'id': j.id,
      'posted_by': j.postedBy,
      'workplace_name': j.workplaceName,
      'workplace_address': j.workplaceAddress,
      'required_specialty': j.requiredSpecialty,
      'years_experience': j.yearsExperience,
      'monthly_salary_iqd': j.monthlySalaryIqd,
      'shift_hours': j.shiftHours,
      'working_hours': j.workingHours,
      'description': j.description,
      'education': j.education.name,
      'languages': j.languages.map((e) => e.name).toList(),
      'core_skills': j.coreSkills,
      'status': j.postingStatus,
      'created_at': j.createdAt.toIso8601String(),
      'updated_at': j.updatedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> _doctorToJson(DoctorSearchItem d) {
    return {
      'id': d.id,
      'name': d.name,
      'professional_title': d.professionalTitle,
      'imageUrl': d.imageUrl,
      'years_experience': d.yearsExperience,
      'governorate': d.governorate,
      'phone': d.phone,
    };
  }

  Future<void> clearPersistedCacheForAccountRemoval() async {
    savedJobs.clear();
    savedDoctors.clear();
    if (_boxReady) {
      try {
        await _box.clear();
        await _box.close();
      } catch (_) {}
      _boxReady = false;
    }
    try {
      await Hive.deleteBoxFromDisk(hiveBoxName);
    } catch (_) {}
  }

  /// مزامنة الوظائف والأطباء المحفوظين من الباكند (بيانات محدّثة).
  Future<void> syncFromServer() async {
    await Future.wait([
      _syncSavedJobs(),
      syncSavedDoctorsFromServer(),
    ]);
  }

  Future<void> _syncSavedJobs() async {
    try {
      final list = await ApiService.instance.fetchSavedJobs();
      savedJobs.assignAll(list);
      await _saveCache();
    } catch (e, st) {
      debugPrint('Bookmarks jobs sync error: $e\n$st');
    }
  }

  /// جلب الأطباء المحفوظين من السيرفر وتحديث الكاش.
  Future<void> syncSavedDoctorsFromServer() async {
    if (isSyncingDoctors.value) return;
    isSyncingDoctors.value = true;
    try {
      final localOnlyIds = savedDoctors.map((d) => d.id).toList();
      await _migrateLocalDoctorsToServer(localOnlyIds);

      final list = await ApiService.instance.fetchSavedDoctors();
      savedDoctors.assignAll(list);
      await _saveCache();
    } catch (e, st) {
      debugPrint('Bookmarks doctors sync error: $e\n$st');
    } finally {
      isSyncingDoctors.value = false;
    }
  }

  /// رفع المحفوظات المحلية القديمة إلى الباكند مرة واحدة عند المزامنة.
  Future<void> _migrateLocalDoctorsToServer(List<String> localIds) async {
    if (localIds.isEmpty) return;
    try {
      final onServer = await ApiService.instance.fetchSavedDoctors();
      final serverIds = onServer.map((d) => d.id).toSet();
      for (final id in localIds) {
        if (serverIds.contains(id)) continue;
        try {
          await ApiService.instance.saveDoctor(id);
        } catch (e, st) {
          debugPrint('Bookmarks doctor migrate $id: $e\n$st');
        }
      }
    } catch (e, st) {
      debugPrint('Bookmarks doctor migrate list: $e\n$st');
    }
  }

  Future<void> toggle(JobPosting job) async {
    final index = savedJobs.indexWhere((j) => j.id == job.id);
    if (index >= 0) {
      savedJobs.removeAt(index);
      await _saveCache();
      unawaited(_unsaveRemoteJob(job.id));
      return;
    }
    savedJobs.insert(0, job);
    await _saveCache();
    unawaited(_saveRemoteJob(job.id));
  }

  Future<void> _saveRemoteJob(String jobId) async {
    try {
      await ApiService.instance.saveJob(jobId);
    } catch (e, st) {
      debugPrint('Bookmarks remote save job error: $e\n$st');
    }
  }

  Future<void> _unsaveRemoteJob(String jobId) async {
    try {
      await ApiService.instance.unsaveJob(jobId);
    } catch (e, st) {
      debugPrint('Bookmarks remote unsave job error: $e\n$st');
    }
  }

  Future<void> removeById(String jobId) async {
    savedJobs.removeWhere((j) => j.id == jobId);
    await _saveCache();
    unawaited(_unsaveRemoteJob(jobId));
  }

  Future<void> toggleDoctor(DoctorSearchItem doctor) async {
    final i = savedDoctors.indexWhere((d) => d.id == doctor.id);
    if (i >= 0) {
      savedDoctors.removeAt(i);
      await _saveCache();
      unawaited(_unsaveRemoteDoctor(doctor.id));
      return;
    }
    savedDoctors.insert(0, doctor);
    await _saveCache();
    unawaited(_saveRemoteDoctor(doctor));
  }

  Future<void> _saveRemoteDoctor(DoctorSearchItem doctor) async {
    try {
      await ApiService.instance.saveDoctor(doctor.id);
      final list = await ApiService.instance.fetchSavedDoctors();
      DoctorSearchItem? updated;
      for (final d in list) {
        if (d.id == doctor.id) {
          updated = d;
          break;
        }
      }
      if (updated != null) {
        final idx = savedDoctors.indexWhere((d) => d.id == doctor.id);
        if (idx >= 0) {
          savedDoctors[idx] = updated;
        } else {
          savedDoctors.insert(0, updated);
        }
        await _saveCache();
      }
    } catch (e, st) {
      debugPrint('Bookmarks remote save doctor error: $e\n$st');
    }
  }

  Future<void> _unsaveRemoteDoctor(String doctorId) async {
    try {
      await ApiService.instance.unsaveDoctor(doctorId);
    } catch (e, st) {
      debugPrint('Bookmarks remote unsave doctor error: $e\n$st');
    }
  }

  @override
  void onClose() {
    if (_boxReady) {
      unawaited(_box.close());
    }
    super.onClose();
  }
}
