/// استجابة `GET /profile/me` — بروفايل الطبيب الكامل.
class DoctorProfileFull {
  const DoctorProfileFull({
    required this.id,
    this.name,
    required this.phone,
    required this.email,
    this.professionalTitle,
    this.gender,
    this.age,
    this.imageUrl,
    this.governorate,
    this.bio,
    this.yearsExperience,
    this.languages = const [],
    this.education = const [],
    this.experiences = const [],
    this.skillIds = const [],
    this.gallery = const [],
    this.certificateImages = const [],
    this.practiceLicense,
    this.accreditedCourses = const [],
    this.experienceScore,
    this.experienceScoreUpdatedAt,
  });

  final String id;
  final String? name;
  final String phone;
  final String email;
  final String? professionalTitle;
  final String? gender;
  final int? age;
  final String? imageUrl;
  final String? governorate;
  final String? bio;
  final int? yearsExperience;
  final List<String> languages;
  final List<EducationEntryDto> education;
  final List<WorkExperienceDto> experiences;
  final List<String> skillIds;
  final List<GalleryItemDto> gallery;
  final List<CertificateImageDto> certificateImages;
  final PracticeLicenseDto? practiceLicense;
  final List<AccreditedCourseDto> accreditedCourses;
  final ExperienceScoreSnapshotDto? experienceScore;
  final String? experienceScoreUpdatedAt;

  factory DoctorProfileFull.fromJson(Map<String, dynamic> json) {
    return DoctorProfileFull(
      id: json['id'] as String,
      name: json['name'] as String?,
      phone: json['phone'] as String,
      email: json['email'] as String,
      professionalTitle:
          (json['professional_title'] ?? json['professionalTitle'] ?? json['specialty'])
              as String?,
      gender: json['gender'] as String?,
      age: json['age'] as int?,
      imageUrl: json['imageUrl'] as String?,
      governorate: json['governorate'] as String?,
      bio: json['bio'] as String?,
      yearsExperience: json['years_experience'] as int?,
      languages: (json['languages'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      education: (json['education'] as List<dynamic>?)
              ?.map((e) => EducationEntryDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      experiences: (json['experiences'] as List<dynamic>?)
              ?.map((e) => WorkExperienceDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      skillIds: (json['skill_ids'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      gallery: (json['gallery'] as List<dynamic>?)
              ?.map((e) => GalleryItemDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      certificateImages: (json['certificate_images'] as List<dynamic>?)
              ?.map((e) => CertificateImageDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      practiceLicense: json['practice_license'] != null
          ? PracticeLicenseDto.fromJson(
              json['practice_license'] as Map<String, dynamic>,
            )
          : null,
      accreditedCourses: (json['accredited_courses'] as List<dynamic>?)
              ?.map(
                (e) => AccreditedCourseDto.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const [],
      experienceScore: json['experience_score'] is Map<String, dynamic>
          ? ExperienceScoreSnapshotDto.fromJson(
              json['experience_score'] as Map<String, dynamic>,
            )
          : (json['experience_score'] is Map
              ? ExperienceScoreSnapshotDto.fromJson(
                  Map<String, dynamic>.from(json['experience_score'] as Map),
                )
              : null),
      experienceScoreUpdatedAt: json['experience_score_updated_at']?.toString(),
    );
  }
}

class ExperienceScoreTaskDto {
  const ExperienceScoreTaskDto({
    required this.id,
    required this.title,
    required this.earned,
    required this.max,
    this.comingSoon = false,
    this.verification = 'none',
    this.opensSubmitDialog = false,
  });

  final String id;
  final String title;
  final int earned;
  final int max;
  final bool comingSoon;
  final String verification;
  final bool opensSubmitDialog;

  factory ExperienceScoreTaskDto.fromJson(Map<String, dynamic> json) {
    final earnedRaw = json['earned'];
    final maxRaw = json['max'];
    return ExperienceScoreTaskDto(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      earned: earnedRaw is int
          ? earnedRaw
          : (earnedRaw is num ? earnedRaw.round() : 0),
      max: maxRaw is int ? maxRaw : (maxRaw is num ? maxRaw.round() : 0),
      comingSoon: json['coming_soon'] == true,
      verification: (json['verification'] as String? ?? 'none').trim(),
      opensSubmitDialog: json['opens_submit_dialog'] == true,
    );
  }
}

class ExperienceScoreSnapshotDto {
  const ExperienceScoreSnapshotDto({
    required this.totalEarned,
    required this.totalMax,
    required this.tier,
    this.tasks = const [],
    this.peerRatingsReceived = 0,
    this.peerRatingsGiven = 0,
    this.computedAt,
  });

  final int totalEarned;
  final int totalMax;
  final String tier;
  final List<ExperienceScoreTaskDto> tasks;
  final int peerRatingsReceived;
  final int peerRatingsGiven;
  final String? computedAt;

  factory ExperienceScoreSnapshotDto.fromJson(Map<String, dynamic> json) {
    final totalEarnedRaw = json['total_earned'];
    final totalMaxRaw = json['total_max'];
    final inRaw = json['peer_ratings_received'];
    final outRaw = json['peer_ratings_given'];
    return ExperienceScoreSnapshotDto(
      totalEarned: totalEarnedRaw is int
          ? totalEarnedRaw
          : (totalEarnedRaw is num ? totalEarnedRaw.round() : 0),
      totalMax: totalMaxRaw is int
          ? totalMaxRaw
          : (totalMaxRaw is num ? totalMaxRaw.round() : 0),
      tier: (json['tier'] as String? ?? 'silver').trim(),
      tasks: (json['tasks'] as List<dynamic>?)
              ?.map((e) {
                if (e is Map<String, dynamic>) {
                  return ExperienceScoreTaskDto.fromJson(e);
                }
                if (e is Map) {
                  return ExperienceScoreTaskDto.fromJson(
                    Map<String, dynamic>.from(e),
                  );
                }
                return null;
              })
              .whereType<ExperienceScoreTaskDto>()
              .toList() ??
          const [],
      peerRatingsReceived: inRaw is int ? inRaw : (inRaw is num ? inRaw.round() : 0),
      peerRatingsGiven: outRaw is int ? outRaw : (outRaw is num ? outRaw.round() : 0),
      computedAt: json['computed_at']?.toString(),
    );
  }
}

/// دورة معتمدة — مراجعة إدارية (2 نقطة لكل دورة معتمدة، حد أقصى 10).
class AccreditedCourseDto {
  const AccreditedCourseDto({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.explanation,
    required this.status,
    this.pointsAwarded = 0,
    this.rejectionReason,
    this.submittedAt,
    this.reviewedAt,
  });

  final String id;
  final String title;
  final String imageUrl;
  final String explanation;
  final String status;
  final int pointsAwarded;
  final String? rejectionReason;
  final String? submittedAt;
  final String? reviewedAt;

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';

  factory AccreditedCourseDto.fromJson(Map<String, dynamic> json) {
    return AccreditedCourseDto(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      imageUrl: json['image_url'] as String? ?? '',
      explanation: json['explanation'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      pointsAwarded: json['points_awarded'] as int? ?? 0,
      rejectionReason: json['rejection_reason'] as String?,
      submittedAt: json['submitted_at'] as String?,
      reviewedAt: json['reviewed_at'] as String?,
    );
  }
}

/// شهادة ممارسة المهنة — مراجعة إدارية قبل احتساب النقاط.
class PracticeLicenseDto {
  const PracticeLicenseDto({
    required this.imageUrl,
    required this.explanation,
    required this.status,
    this.rejectionReason,
    this.submittedAt,
    this.reviewedAt,
  });

  final String imageUrl;
  final String explanation;
  /// pending | approved | rejected
  final String status;
  final String? rejectionReason;
  final String? submittedAt;
  final String? reviewedAt;

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';

  factory PracticeLicenseDto.fromJson(Map<String, dynamic> json) {
    return PracticeLicenseDto(
      imageUrl: json['image_url'] as String? ?? '',
      explanation: json['explanation'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      rejectionReason: json['rejection_reason'] as String?,
      submittedAt: json['submitted_at'] as String?,
      reviewedAt: json['reviewed_at'] as String?,
    );
  }
}

class EducationEntryDto {
  const EducationEntryDto({
    required this.degreeType,
    required this.specialty,
    required this.university,
    this.startYear,
    this.graduationYear,
    this.graduationDate,
  });

  final String degreeType;
  final String specialty;
  final String university;
  final int? startYear;
  final int? graduationYear;
  final String? graduationDate;

  factory EducationEntryDto.fromJson(Map<String, dynamic> json) {
    return EducationEntryDto(
      degreeType: json['degree_type'] as String? ?? '',
      specialty: json['specialty'] as String? ?? '',
      university: json['university'] as String? ?? '',
      startYear: json['start_year'] as int?,
      graduationYear: json['graduation_year'] as int?,
      graduationDate: json['graduation_date'] as String?,
    );
  }
}

class WorkExperienceDto {
  const WorkExperienceDto({
    required this.experienceType,
    required this.workplace,
    this.periodStart,
    this.periodEnd,
    this.description,
  });

  final String experienceType;
  final String workplace;
  final String? periodStart;
  final String? periodEnd;
  final String? description;

  factory WorkExperienceDto.fromJson(Map<String, dynamic> json) {
    return WorkExperienceDto(
      experienceType: json['experience_type'] as String? ?? '',
      workplace: json['workplace'] as String? ?? '',
      periodStart: json['period_start'] as String?,
      periodEnd: json['period_end'] as String?,
      description: json['description'] as String?,
    );
  }
}

class GalleryItemDto {
  const GalleryItemDto({
    required this.images,
    required this.caption,
  });

  final List<String> images;
  final String caption;

  factory GalleryItemDto.fromJson(Map<String, dynamic> json) {
    return GalleryItemDto(
      images: (json['images'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      caption: json['caption'] as String? ?? '',
    );
  }
}

class CertificateImageDto {
  const CertificateImageDto({
    required this.url,
    this.title,
    this.issuer,
  });

  final String url;
  final String? title;
  final String? issuer;

  factory CertificateImageDto.fromJson(Map<String, dynamic> json) {
    return CertificateImageDto(
      url: json['url'] as String? ?? '',
      title: json['title'] as String?,
      issuer: json['issuer'] as String?,
    );
  }
}
