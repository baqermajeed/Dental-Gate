import 'package:dental_gate/models/job_posting.dart';

enum JobApplicationStatusApi {
  pending,
  accepted,
  rejected,
}

/// عنصر من `GET /jobs/applications/me`.
class MyJobApplicationItem {
  MyJobApplicationItem({
    required this.applicationId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.job,
  });

  final String applicationId;
  final JobApplicationStatusApi status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final JobPosting job;

  factory MyJobApplicationItem.fromJson(Map<String, dynamic> j) {
    return MyJobApplicationItem(
      applicationId: j['id'] as String,
      status: parseStatus(j['status'] as String?),
      createdAt: DateTime.parse(j['created_at'] as String),
      updatedAt: DateTime.parse(j['updated_at'] as String),
      job: JobPosting.fromJson(j['job'] as Map<String, dynamic>),
    );
  }

  static JobApplicationStatusApi parseStatus(String? v) {
    return JobApplicationStatusApi.values.firstWhere(
      (e) => e.name == v,
      orElse: () => JobApplicationStatusApi.pending,
    );
  }

  /// نص الشارة كما في التصميم.
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
}
