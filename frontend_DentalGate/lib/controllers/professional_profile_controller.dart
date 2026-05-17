import 'package:get/get.dart';

import 'package:dental_gate/core/media_url.dart';
import 'package:dental_gate/models/doctor_profile_full.dart';
import 'package:dental_gate/services/api_service.dart' show ApiException, ApiService;
import 'package:dental_gate/view/profile/experience_score_breakdown.dart';

class ProfessionalProfileController extends GetxController {
  ProfessionalProfileController({
    this.viewJobId,
    this.viewApplicationId,
    this.viewUserId,
  });

  /// عند التعيين: تحميل بروفايل متقدّم عبر مسار صاحب الإعلان (قراءة فقط).
  final String? viewJobId;
  final String? viewApplicationId;
  final String? viewUserId;

  final profile = Rxn<DoctorProfileFull>();
  final isLoading = true.obs;
  final errorMessage = RxnString();
  /// تقييمات واردة/صادرة للبروفايل المعروض حالياً.
  final peerRatingsReceived = 0.obs;
  final peerRatingsGiven = 0.obs;
  /// تقييمات الحساب المسجّل (للتوصيات ونقاط الجلسة).
  final sessionPeerRatingsReceived = 0.obs;
  final sessionPeerRatingsGiven = 0.obs;

  /// معرّف الحساب المسجّل دخوله (لمنع تقييم الذات عند فتح بروفايلك من البحث).
  String? sessionUserId;

  /// بروفايل الحساب الحالي — لحساب نقاط الخبرة عند التوصية.
  DoctorProfileFull? sessionProfile;

  bool get isApplicantReadOnlyView =>
      (viewJobId != null && viewJobId!.isNotEmpty) &&
      (viewApplicationId != null && viewApplicationId!.isNotEmpty);

  bool get isDoctorSearchReadOnlyView =>
      viewUserId != null && viewUserId!.isNotEmpty;

  bool get isReadOnlyView => isApplicantReadOnlyView || isDoctorSearchReadOnlyView;

  /// تقييم طبيب آخر فقط — وليس بروفايلك من البحث.
  bool get canSubmitPeerRatingOnViewedProfile {
    if (!isReadOnlyView) return false;
    final viewedId = profile.value?.id ?? viewUserId;
    if (viewedId == null || viewedId.isEmpty) return false;
    final mine = sessionUserId;
    if (mine != null && mine == viewedId) return false;
    return true;
  }

  /// توصية طبيب آخر — نفس شروط التقييم (ليس بروفايلك).
  bool get canSubmitRecommendationOnViewedProfile =>
      canSubmitPeerRatingOnViewedProfile;

  /// نقاط خبرة الحساب الحالي (للتحقق قبل كتابة توصية).
  int get sessionExperiencePoints {
    final p = sessionProfile;
    if (p == null) return 0;
    return resolveExperienceScoreBreakdown(
      p,
      peerRatingsReceived: sessionPeerRatingsReceived.value,
      peerRatingsGiven: sessionPeerRatingsGiven.value,
    ).totalEarned;
  }

  Future<void> _loadPeerExperienceStats() async {
    final p = profile.value;
    if (p == null) {
      peerRatingsReceived.value = 0;
      peerRatingsGiven.value = 0;
      sessionPeerRatingsReceived.value = 0;
      sessionPeerRatingsGiven.value = 0;
      return;
    }
    try {
      if (isReadOnlyView) {
        final page = await ApiService.instance.fetchDoctorPeerRatings(p.id);
        peerRatingsReceived.value = page.totalCount;
        peerRatingsGiven.value = 0;
        try {
          final mine = await ApiService.instance.fetchMyPeerRatings();
          sessionPeerRatingsReceived.value = mine.totalCount;
          sessionPeerRatingsGiven.value = mine.ratingsGivenCount;
        } catch (_) {
          sessionPeerRatingsReceived.value = 0;
          sessionPeerRatingsGiven.value = 0;
        }
      } else {
        final page = await ApiService.instance.fetchMyPeerRatings();
        peerRatingsReceived.value = page.totalCount;
        peerRatingsGiven.value = page.ratingsGivenCount;
        sessionPeerRatingsReceived.value = page.totalCount;
        sessionPeerRatingsGiven.value = page.ratingsGivenCount;
      }
    } catch (_) {
      peerRatingsReceived.value = 0;
      peerRatingsGiven.value = 0;
      sessionPeerRatingsReceived.value = 0;
      sessionPeerRatingsGiven.value = 0;
    }
  }

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    errorMessage.value = null;
    try {
      if (isReadOnlyView) {
        try {
          final me = await ApiService.instance.fetchDoctorProfileFull();
          sessionUserId = me.id;
          sessionProfile = me;
        } catch (_) {
          sessionUserId = null;
          sessionProfile = null;
        }
      }
      if (isApplicantReadOnlyView) {
        profile.value = await ApiService.instance.fetchJobApplicantProfileFull(
          jobId: viewJobId!,
          applicationId: viewApplicationId!,
        );
      } else if (isDoctorSearchReadOnlyView) {
        profile.value = await ApiService.instance.fetchDoctorProfileByUserId(
          viewUserId!,
        );
      } else {
        profile.value = await ApiService.instance.fetchDoctorProfileFull();
        sessionUserId = profile.value?.id;
        sessionProfile = profile.value;
      }
    } on ApiException catch (e) {
      errorMessage.value = e.message;
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
    if (profile.value != null) {
      await _loadPeerExperienceStats();
    }
  }

  Future<void> reload() => load();

  /// إضافة حالة للمعرض (PATCH جزئي).
  Future<void> addGalleryCase({
    required String title,
    required String description,
    required List<String> imageUrls,
  }) async {
    if (isReadOnlyView) return;
    final p = profile.value;
    if (p == null) return;
    final t = title.trim();
    final d = description.trim();
    if (t.isEmpty) return;
    final newImgs = imageUrls
        .map(stripMediaToApiPath)
        .where((s) => s.isNotEmpty)
        .take(4)
        .toList();
    if (newImgs.isEmpty) return;

    final galleryPayload = <Map<String, dynamic>>[];
    for (final item in p.gallery) {
      final imgs = item.images
          .map(stripMediaToApiPath)
          .where((s) => s.isNotEmpty)
          .take(4)
          .toList();
      if (imgs.isEmpty) continue;
      galleryPayload.add(<String, dynamic>{
        'caption': item.caption,
        'images': imgs,
      });
    }
    final caption = d.isEmpty ? t : '$t\n\n$d';
    galleryPayload.add(<String, dynamic>{
      'caption': caption,
      'images': newImgs,
    });

    try {
      final updated = await ApiService.instance.patchDoctorProfile(
        body: <String, dynamic>{'gallery': galleryPayload},
      );
      profile.value = updated;
    } on ApiException catch (e) {
      Get.snackbar(
        'تعذّر الإضافة',
        e.message,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'تعذّر الإضافة',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// حذف عنصر معرض من البروفايل الخاص (PATCH جزئي).
  Future<void> removeGalleryCaseAt(int index) async {
    if (isReadOnlyView) return;
    final p = profile.value;
    if (p == null || index < 0 || index >= p.gallery.length) return;

    final remaining = <GalleryItemDto>[
      for (var i = 0; i < p.gallery.length; i++)
        if (i != index) p.gallery[i],
    ];

    final galleryPayload = <Map<String, dynamic>>[];
    for (final item in remaining) {
      final imgs = item.images
          .map(stripMediaToApiPath)
          .where((s) => s.isNotEmpty)
          .take(4)
          .toList();
      if (imgs.isEmpty) continue;
      galleryPayload.add(<String, dynamic>{
        'caption': item.caption,
        'images': imgs,
      });
    }

    try {
      final updated = await ApiService.instance.patchDoctorProfile(
        body: <String, dynamic>{'gallery': galleryPayload},
      );
      profile.value = updated;
    } on ApiException catch (e) {
      Get.snackbar(
        'تعذّر الحذف',
        e.message,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'تعذّر الحذف',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// إضافة شهادة (PATCH جزئي لـ [certificate_images]).
  Future<void> addCertificate({
    required String title,
    required String issuer,
    required String imageUrl,
  }) async {
    if (isReadOnlyView) return;
    final p = profile.value;
    if (p == null) return;
    final t = title.trim();
    final iss = issuer.trim();
    final path = stripMediaToApiPath(imageUrl.trim());
    if (path.isEmpty) return;

    final certificatePayload = <Map<String, dynamic>>[];
    for (final cert in p.certificateImages) {
      final u = stripMediaToApiPath(cert.url);
      if (u.isEmpty) continue;
      certificatePayload.add(<String, dynamic>{
        'url': u,
        if ((cert.title ?? '').trim().isNotEmpty) 'title': cert.title!.trim(),
        if ((cert.issuer ?? '').trim().isNotEmpty) 'issuer': cert.issuer!.trim(),
      });
    }
    certificatePayload.add(<String, dynamic>{
      'url': path,
      if (t.isNotEmpty) 'title': t,
      if (iss.isNotEmpty) 'issuer': iss,
    });

    try {
      final updated = await ApiService.instance.patchDoctorProfile(
        body: <String, dynamic>{'certificate_images': certificatePayload},
      );
      profile.value = updated;
    } on ApiException catch (e) {
      Get.snackbar(
        'تعذّر الإضافة',
        e.message,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'تعذّر الإضافة',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// حذف شهادة بالفهرس (PATCH جزئي).
  Future<void> removeCertificateAt(int index) async {
    if (isReadOnlyView) return;
    final p = profile.value;
    if (p == null || index < 0 || index >= p.certificateImages.length) return;

    final remaining = <CertificateImageDto>[
      for (var i = 0; i < p.certificateImages.length; i++)
        if (i != index) p.certificateImages[i],
    ];

    final certificatePayload = <Map<String, dynamic>>[];
    for (final cert in remaining) {
      final u = stripMediaToApiPath(cert.url);
      if (u.isEmpty) continue;
      certificatePayload.add(<String, dynamic>{
        'url': u,
        if ((cert.title ?? '').trim().isNotEmpty) 'title': cert.title!.trim(),
        if ((cert.issuer ?? '').trim().isNotEmpty) 'issuer': cert.issuer!.trim(),
      });
    }

    try {
      final updated = await ApiService.instance.patchDoctorProfile(
        body: <String, dynamic>{'certificate_images': certificatePayload},
      );
      profile.value = updated;
    } on ApiException catch (e) {
      Get.snackbar(
        'تعذّر الحذف',
        e.message,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'تعذّر الحذف',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}
