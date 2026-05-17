import 'package:dental_gate/models/doctor_profile_full.dart';

/// شارة التصنيف حسب إجمالي النقاط (0–70).
enum ExperienceTier {
  silver,
  gold,
  platinum,
  diamond,
}

/// أقصى مجموع نقاط يُعرَض كنسبة من الإنجاز في نظام الخبرة الحالي.
const int kExperienceScoreTotalCap = 70;

/// نقاط الدورات المعتمدة بعد موافقة الإدارة.
const int kAccreditedCoursePointsEach = 2;
const int kAccreditedCoursePointsMax = 10;

/// نقاط تقييم الزملاء — وارد: 5 نقاط عند 10 تقييمات؛ صادر: نقطتان عند 5 تقييمات.
const int kPeerRatingsIncomingMax = 5;
const int kPeerRatingsOutgoingMax = 2;
const int kPeerRatingsIncomingRequired = 10;
const int kPeerRatingsOutgoingRequired = 5;

int peerRatingsIncomingPoints(int receivedCount) {
  if (receivedCount <= 0) return 0;
  final scaled = (receivedCount * kPeerRatingsIncomingMax) ~/
      kPeerRatingsIncomingRequired;
  return scaled.clamp(0, kPeerRatingsIncomingMax);
}

int peerRatingsOutgoingPoints(int givenCount) {
  if (givenCount <= 0) return 0;
  final scaled =
      (givenCount * kPeerRatingsOutgoingMax) ~/ kPeerRatingsOutgoingRequired;
  return scaled.clamp(0, kPeerRatingsOutgoingMax);
}

int accreditedCoursesPointsEarned(List<AccreditedCourseDto> courses) {
  var total = 0;
  for (final c in courses) {
    if (c.isApproved) {
      total += c.pointsAwarded > 0 ? c.pointsAwarded : kAccreditedCoursePointsEach;
    }
  }
  return total.clamp(0, kAccreditedCoursePointsMax);
}

String experienceTierLabelAr(ExperienceTier tier) => switch (tier) {
      ExperienceTier.silver => 'فضي',
      ExperienceTier.gold => 'ذهبي',
      ExperienceTier.platinum => 'بلاتين',
      ExperienceTier.diamond => 'دايموند',
    };

/// أقل نقطة تُصنَّف ضمن هذا التصنيف (ضمناً).
int experienceTierMinInclusive(ExperienceTier tier) => switch (tier) {
      ExperienceTier.silver => 0,
      ExperienceTier.gold => 20,
      ExperienceTier.platinum => 40,
      ExperienceTier.diamond => 55,
    };

/// أعلى نقطة ضمن هذا التصنيف (ضمناً).
int experienceTierMaxInclusive(ExperienceTier tier) => switch (tier) {
      ExperienceTier.silver => 19,
      ExperienceTier.gold => 39,
      ExperienceTier.platinum => 54,
      ExperienceTier.diamond => kExperienceScoreTotalCap,
    };

/// حالة التحقق لمهام تتطلب موافقة إدارية.
enum ExperienceTaskVerification {
  none,
  pending,
  approved,
  rejected,
}

/// مهمة واحدة في لوحة نقاط الخبرة.
class ExperienceScoreTask {
  const ExperienceScoreTask({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.earned,
    required this.max,
    this.comingSoon = false,
    this.verification = ExperienceTaskVerification.none,
    this.opensSubmitDialog = false,
  });

  final String id;
  final String title;
  final String subtitle;
  final int earned;
  final int max;
  final bool comingSoon;
  final ExperienceTaskVerification verification;
  /// عند الضغط تفتح واجهة إرسال/إعادة إرسال (مثل شهادة الممارسة).
  final bool opensSubmitDialog;

  double get progress => max <= 0 ? 0 : (earned / max).clamp(0.0, 1.0);
  bool get isComplete =>
      !comingSoon &&
      verification != ExperienceTaskVerification.pending &&
      earned >= max &&
      max > 0;

  bool get isPendingReview =>
      verification == ExperienceTaskVerification.pending;

  bool get isRejected =>
      verification == ExperienceTaskVerification.rejected;
}

/// نتيجة حساب النقاط لعرضها في الشريط وصفحة المهام.
class ExperienceScoreBreakdown {
  const ExperienceScoreBreakdown({
    required this.totalEarned,
    required this.totalMax,
    required this.tier,
    required this.tasks,
  });

  final int totalEarned;
  final int totalMax;
  final ExperienceTier tier;
  final List<ExperienceScoreTask> tasks;

  double get fraction => totalMax <= 0 ? 0 : totalEarned / totalMax;
}

int _highestDegreePoints(List<EducationEntryDto> education) {
  var maxPts = 0;
  for (final e in education) {
    final t = e.degreeType.trim().toLowerCase();
    final p = switch (t) {
      'doctorate' => 12,
      'master' => 8,
      'bachelor' => 5,
      'diploma' => 3,
      _ => 0,
    };
    if (p > maxPts) maxPts = p;
  }
  return maxPts;
}

/// نقاط سنوات الخبرة (من حقل البروفايل).
int _yearsExperiencePoints(int? years) {
  if (years == null || years < 1) return 0;
  if (years >= 10) return 8;
  if (years >= 5) return 6;
  if (years >= 3) return 4;
  return 2;
}

ExperienceTier _tierForPoints(int p) {
  if (p >= 55) return ExperienceTier.diamond;
  if (p >= 40) return ExperienceTier.platinum;
  if (p >= 20) return ExperienceTier.gold;
  return ExperienceTier.silver;
}

/// يحسب توزيع نقاط الخبرة من بيانات البروفايل وتقييمات الزملاء.
ExperienceScoreBreakdown computeExperienceScoreBreakdown(
  DoctorProfileFull p, {
  int peerRatingsReceived = 0,
  int peerRatingsGiven = 0,
}) {
  final hasBio = (p.bio ?? '').trim().isNotEmpty;
  final hasEducation = p.education.isNotEmpty;
  final hasExperiences = p.experiences.isNotEmpty;
  final hasSkills = p.skillIds.isNotEmpty;
  final hasLanguages = p.languages.isNotEmpty;
  final galleryCount = p.gallery.length;
  final pl = p.practiceLicense;

  final bioPts = hasBio ? 1 : 0;
  final eduInfoPts = hasEducation ? 2 : 0;
  final degreePts = _highestDegreePoints(p.education);
  final expPts = hasExperiences ? 2 : 0;
  final skillPts = hasSkills ? 1 : 0;
  final langPts = hasLanguages ? 1 : 0;

  final gallery3Pts = galleryCount >= 3 ? 3 : galleryCount.clamp(0, 3);
  final gallery15Pts = galleryCount >= 15 ? 5 : 0;
  const practiceLicenseMax = 8;
  final practiceLicensePts =
      pl != null && pl.isApproved ? practiceLicenseMax : 0;
  ExperienceTaskVerification plVerification =
      ExperienceTaskVerification.none;
  var plSubtitle =
      'ارفع صورة الشهادة مع شرح مختصر — تُراجع من الإدارة ثم تُحتسب النقاط';
  var plOpensDialog = true;
  if (pl != null) {
    if (pl.isApproved) {
      plVerification = ExperienceTaskVerification.approved;
      plSubtitle = 'تم التحقق من شهادتك — النقاط مضافة لملفك';
      plOpensDialog = false;
    } else if (pl.isPending) {
      plVerification = ExperienceTaskVerification.pending;
      plSubtitle = 'طلبك قيد المراجعة — سنُعلمك عند اعتماد الشهادة';
      plOpensDialog = false;
    } else if (pl.isRejected) {
      plVerification = ExperienceTaskVerification.rejected;
      final reason = (pl.rejectionReason ?? '').trim();
      plSubtitle = reason.isNotEmpty
          ? 'لم تُقبل الشهادة: $reason — يمكنك إعادة الإرسال'
          : 'لم تُقبل الشهادة — عدّل الصورة أو الشرح وأعد الإرسال';
      plOpensDialog = true;
    }
  }
  final yearsPts = _yearsExperiencePoints(p.yearsExperience);

  final courses = p.accreditedCourses;
  const coursesMax = kAccreditedCoursePointsMax;
  final coursesPts = accreditedCoursesPointsEarned(courses);
  final coursesPending =
      courses.where((c) => c.isPending).length;
  final coursesRejected =
      courses.where((c) => c.isRejected).length;
  ExperienceTaskVerification coursesVerification =
      ExperienceTaskVerification.none;
  var coursesSubtitle =
      'ارفع شهادة كل دورة مع شرح — تُراجع إدارياً (نقطتان لكل دورة، حتى $coursesMax نقاط)';
  var coursesOpensDialog = coursesPts < coursesMax;
  if (courses.isNotEmpty) {
    if (coursesPending > 0) {
      coursesVerification = ExperienceTaskVerification.pending;
      coursesSubtitle =
          '$coursesPending دورة قيد المراجعة — المعتمدة $coursesPts/$coursesMax نقطة';
    } else if (coursesRejected > 0 && coursesPts < coursesMax) {
      coursesVerification = ExperienceTaskVerification.rejected;
      coursesSubtitle =
          'دورة مرفوضة — يمكنك إرسال دورة جديدة أو تصحيح البيانات';
    } else if (coursesPts >= coursesMax) {
      coursesSubtitle = 'وصلت للحد الأقصى من نقاط الدورات المعتمدة';
      coursesOpensDialog = false;
    } else if (coursesPts > 0) {
      coursesSubtitle =
          'حصلت على $coursesPts/$coursesMax نقاط — يمكنك إرسال دورات إضافية';
    }
  }

  final peerInPts = peerRatingsIncomingPoints(peerRatingsReceived);
  final peerOutPts = peerRatingsOutgoingPoints(peerRatingsGiven);
  const stubPlatform = 0;

  final tasks = <ExperienceScoreTask>[
    ExperienceScoreTask(
      id: 'bio',
      title: 'النبذة المهنية',
      subtitle: 'نبذة واضحة تقدّمك للزملاء وأصحاب العمل',
      earned: bioPts,
      max: 1,
    ),
    ExperienceScoreTask(
      id: 'education_info',
      title: 'بيانات التعليم',
      subtitle: 'إضافة مسارك الأكاديمي في المنصة',
      earned: eduInfoPts,
      max: 2,
    ),
    ExperienceScoreTask(
      id: 'degree',
      title: 'أعلى مؤهل أكاديمي',
      subtitle: 'دبلوم، بكالوريوس، ماجستير أو دكتوراه — يُحتسب أعلى مؤهل',
      earned: degreePts,
      max: 12,
    ),
    ExperienceScoreTask(
      id: 'work',
      title: 'الخبرات العملية',
      subtitle: 'خبراتك في العيادات والمؤسسات',
      earned: expPts,
      max: 2,
    ),
    ExperienceScoreTask(
      id: 'skills',
      title: 'المهارات',
      subtitle: 'مهاراتك السريرية والفنية',
      earned: skillPts,
      max: 1,
    ),
    ExperienceScoreTask(
      id: 'languages',
      title: 'اللغات',
      subtitle: 'لغات التواصل مع المرضى والفريق',
      earned: langPts,
      max: 1,
    ),
    ExperienceScoreTask(
      id: 'gallery3',
      title: 'معرض الحالات (3 حالات)',
      subtitle: 'رفع ثلاث حالات سريرية مع صور منظّمة',
      earned: gallery3Pts,
      max: 3,
    ),
    ExperienceScoreTask(
      id: 'gallery15',
      title: 'معرض الحالات (15 حالة)',
      subtitle: 'حافظ على معرض غني يعكس خبرتك',
      earned: gallery15Pts,
      max: 5,
    ),
    ExperienceScoreTask(
      id: 'practice_license',
      title: 'شهادة ممارسة المهنة',
      subtitle: plSubtitle,
      earned: practiceLicensePts,
      max: practiceLicenseMax,
      verification: plVerification,
      opensSubmitDialog: plOpensDialog,
    ),
    ExperienceScoreTask(
      id: 'years',
      title: 'سنوات الخبرة',
      subtitle: 'مدة الممارسة المسجّلة في ملفك',
      earned: yearsPts,
      max: 8,
    ),
    ExperienceScoreTask(
      id: 'courses',
      title: 'دورات معتمدة',
      subtitle: coursesSubtitle,
      earned: coursesPts,
      max: coursesMax,
      verification: coursesVerification,
      opensSubmitDialog: coursesOpensDialog,
    ),
    ExperienceScoreTask(
      id: 'peer_in',
      title: 'تقييم الزملاء (وارد)',
      subtitle: peerRatingsReceived > 0
          ? 'استلمت $peerRatingsReceived/$kPeerRatingsIncomingRequired تقييمات — '
              '$peerInPts/$kPeerRatingsIncomingMax نقاط'
          : 'احصل على $kPeerRatingsIncomingMax نقاط عند '
              '$kPeerRatingsIncomingRequired تقييمات من زملائك',
      earned: peerInPts,
      max: kPeerRatingsIncomingMax,
    ),
    ExperienceScoreTask(
      id: 'peer_out',
      title: 'تقييم الزملاء (صادر)',
      subtitle: peerRatingsGiven > 0
          ? 'قيّمت $peerRatingsGiven/$kPeerRatingsOutgoingRequired أطباء — '
              '$peerOutPts/$kPeerRatingsOutgoingMax نقاط'
          : 'احصل على $kPeerRatingsOutgoingMax نقاط عند تقييم '
              '$kPeerRatingsOutgoingRequired أطباء من بروفايلهم',
      earned: peerOutPts,
      max: kPeerRatingsOutgoingMax,
    ),
    ExperienceScoreTask(
      id: 'platform',
      title: 'نشاط المنصة',
      subtitle: 'تفاعل مستمر وجودة مساهماتك',
      earned: stubPlatform,
      max: 10,
      comingSoon: true,
    ),
  ];

  final rawEarned = tasks.fold<int>(0, (s, t) => s + t.earned);
  final totalMax = tasks.fold<int>(0, (s, t) => s + t.max);
  final totalEarned = rawEarned.clamp(0, totalMax);

  return ExperienceScoreBreakdown(
    totalEarned: totalEarned,
    totalMax: totalMax,
    tier: _tierForPoints(totalEarned),
    tasks: tasks,
  );
}

ExperienceTier _tierFromApi(String raw) {
  switch (raw.trim().toLowerCase()) {
    case 'gold':
      return ExperienceTier.gold;
    case 'platinum':
      return ExperienceTier.platinum;
    case 'diamond':
      return ExperienceTier.diamond;
    case 'silver':
    default:
      return ExperienceTier.silver;
  }
}

ExperienceTaskVerification _verificationFromApi(String raw) {
  switch (raw.trim().toLowerCase()) {
    case 'pending':
      return ExperienceTaskVerification.pending;
    case 'approved':
      return ExperienceTaskVerification.approved;
    case 'rejected':
      return ExperienceTaskVerification.rejected;
    case 'none':
    default:
      return ExperienceTaskVerification.none;
  }
}

ExperienceScoreBreakdown? _breakdownFromApiSnapshot(DoctorProfileFull p) {
  final s = p.experienceScore;
  if (s == null) return null;
  final localTemplate = computeExperienceScoreBreakdown(
    p,
    peerRatingsReceived: s.peerRatingsReceived,
    peerRatingsGiven: s.peerRatingsGiven,
  );
  final byId = <String, ExperienceScoreTaskDto>{
    for (final t in s.tasks) t.id: t,
  };
  final mappedTasks = localTemplate.tasks.map((local) {
    final remote = byId[local.id];
    if (remote == null) return local;
    return ExperienceScoreTask(
      id: local.id,
      title: remote.title.isNotEmpty ? remote.title : local.title,
      subtitle: local.subtitle,
      earned: remote.earned,
      max: remote.max,
      comingSoon: remote.comingSoon,
      verification: _verificationFromApi(remote.verification),
      opensSubmitDialog: remote.opensSubmitDialog,
    );
  }).toList();
  return ExperienceScoreBreakdown(
    totalEarned: s.totalEarned,
    totalMax: s.totalMax <= 0 ? kExperienceScoreTotalCap : s.totalMax,
    tier: _tierFromApi(s.tier),
    tasks: mappedTasks,
  );
}

/// يعتمد على سكور الباكند المخزَّن؛ ويرجع للحساب المحلي فقط كحل احتياطي.
ExperienceScoreBreakdown resolveExperienceScoreBreakdown(
  DoctorProfileFull p, {
  int peerRatingsReceived = 0,
  int peerRatingsGiven = 0,
}) {
  final fromApi = _breakdownFromApiSnapshot(p);
  if (fromApi != null) return fromApi;
  return computeExperienceScoreBreakdown(
    p,
    peerRatingsReceived: peerRatingsReceived,
    peerRatingsGiven: peerRatingsGiven,
  );
}
