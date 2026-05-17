import 'package:dental_gate/models/my_job_application_item.dart';

/// عنصر من `GET /jobs/{job_id}/applications` (صاحب الإعلان).
class JobApplicantItem {
  JobApplicantItem({
    required this.applicationId,
    required this.status,
    required this.userId,
    required this.name,
    required this.phone,
    required this.email,
    required this.imageUrl,
    required this.yearsExperience,
    required this.governorate,
    required this.professionalTitle,
  });

  final String applicationId;
  final JobApplicationStatusApi status;
  final String userId;
  final String? name;
  final String phone;
  final String email;
  final String? imageUrl;
  final int? yearsExperience;
  final String? governorate;
  final String? professionalTitle;

  factory JobApplicantItem.fromJson(Map<String, dynamic> j) {
    return JobApplicantItem(
      applicationId: j['application_id'] as String,
      status: MyJobApplicationItem.parseStatus(j['status'] as String?),
      userId: j['user_id'] as String,
      name: j['name'] as String?,
      phone: j['phone'] as String,
      email: j['email'] as String,
      imageUrl: j['image_url'] as String?,
      yearsExperience: (j['years_experience'] as num?)?.toInt(),
      governorate: j['governorate'] as String?,
      professionalTitle: j['professional_title'] as String?,
    );
  }

  String get statusLabel {
    switch (status) {
      case JobApplicationStatusApi.pending:
        return 'قيد المراجعة';
      case JobApplicationStatusApi.accepted:
        return 'تم القبول';
      case JobApplicationStatusApi.rejected:
        return 'لم يقبل';
    }
  }

  String get displayName => (name?.trim().isNotEmpty ?? false) ? name!.trim() : 'متقدم';

  String get experienceLine {
    final y = yearsExperience;
    if (y == null) return 'خبرة غير محددة';
    return '$y سنوات خبرة';
  }

  String get locationLine =>
      (governorate?.trim().isNotEmpty ?? false) ? governorate!.trim() : '—';

  JobApplicantItem copyWith({JobApplicationStatusApi? status}) {
    return JobApplicantItem(
      applicationId: applicationId,
      status: status ?? this.status,
      userId: userId,
      name: name,
      phone: phone,
      email: email,
      imageUrl: imageUrl,
      yearsExperience: yearsExperience,
      governorate: governorate,
      professionalTitle: professionalTitle,
    );
  }
}
