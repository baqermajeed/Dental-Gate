import 'package:dental_gate/utils/api_date_time.dart';

/// أنواع الإشعارات (حقل `type` في الـ API و Firestore إن وُجد).
enum AppNotificationType {
  /// طلب تقديم على وظيفة نشرها المستخدم الحالي (يظهر في «طلبات الوظائف»).
  jobPostingApplication('job_posting_application'),

  /// حالة طلب التقديم على وظيفة قدّم عليها المستخدم (يظهر في «طلبات التوظيف»).
  myApplicationStatus('my_application_status'),

  /// إشعارات النظام من لوحة التحكم (يظهر في «أشعارات التطبيق»).
  appAnnouncement('app_announcement');

  const AppNotificationType(this.apiValue);
  final String apiValue;

  static AppNotificationType? fromString(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    for (final t in AppNotificationType.values) {
      if (t.apiValue == raw) return t;
    }
    return null;
  }
}

class AppNotificationItem {
  const AppNotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.read,
    required this.createdAt,
    this.jobId,
    this.jobTitle,
    this.actorName,
    this.applicationStatus,
  });

  final String id;
  final AppNotificationType type;
  final String title;
  final String body;
  final bool read;
  final DateTime? createdAt;
  final String? jobId;
  final String? jobTitle;
  final String? actorName;
  /// `accepted` | `rejected` لنوع [AppNotificationType.myApplicationStatus].
  final String? applicationStatus;

  /// استجابة `GET /notifications` من الباكند (Pydantic: snake_case).
  factory AppNotificationItem.fromApiJson(Map<String, dynamic> json) {
    final type = AppNotificationType.fromString(json['type'] as String?) ??
        AppNotificationType.appAnnouncement;
    final rawTime = json['created_at'] ?? json['createdAt'];
    final created = parseApiDateTimeUtc(rawTime);
    return AppNotificationItem(
      id: json['id'] as String? ?? '',
      type: type,
      title: (json['title'] as String?)?.trim() ?? '',
      body: (json['body'] as String?)?.trim() ?? '',
      read: json['read'] as bool? ?? false,
      createdAt: created,
      jobId: json['job_id'] as String? ?? json['jobId'] as String?,
      jobTitle: json['job_title'] as String? ?? json['jobTitle'] as String?,
      actorName: json['actor_name'] as String? ?? json['actorName'] as String?,
      applicationStatus: json['application_status'] as String? ??
          json['applicationStatus'] as String?,
    );
  }

  AppNotificationItem copyWith({bool? read}) {
    return AppNotificationItem(
      id: id,
      type: type,
      title: title,
      body: body,
      read: read ?? this.read,
      createdAt: createdAt,
      jobId: jobId,
      jobTitle: jobTitle,
      actorName: actorName,
      applicationStatus: applicationStatus,
    );
  }

  /// نص العرض إن كان title/body فارغين (من الحقول المنظّمة).
  String get displayTitle {
    if (title.isNotEmpty) return title;
    switch (type) {
      case AppNotificationType.jobPostingApplication:
        return 'طلب جديد';
      case AppNotificationType.myApplicationStatus:
        return 'تحديث طلب التوظيف';
      case AppNotificationType.appAnnouncement:
        return 'إشعار';
    }
  }

  String get displayBody {
    if (body.isNotEmpty) return body;
    final name = actorName?.trim();
    final jt = jobTitle?.trim();
    switch (type) {
      case AppNotificationType.jobPostingApplication:
        if (name != null && name.isNotEmpty) {
          return 'قام $name بالتقديم على الوظيفة التي نشرتها';
        }
        return 'تقديم جديد على إحدى وظائفك';
      case AppNotificationType.myApplicationStatus:
        final st = applicationStatus?.toLowerCase();
        if (st == 'accepted' && jt != null && jt.isNotEmpty) {
          return 'تم قبولك في الوظيفة: $jt';
        }
        if (st == 'rejected' && jt != null && jt.isNotEmpty) {
          return 'لم يتم قبولك في الوظيفة: $jt';
        }
        if (jt != null && jt.isNotEmpty) {
          return 'تحديث بخصوص الوظيفة: $jt';
        }
        return 'تحديث بخصوص طلب التقديم';
      case AppNotificationType.appAnnouncement:
        return '';
    }
  }
}
