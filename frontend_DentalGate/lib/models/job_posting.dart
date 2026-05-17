import 'package:dental_gate/utils/iqd_format.dart';

enum JobEducationApi { diploma, bachelor, master, doctorate }

enum JobLanguageApi { arabic, english }

/// وظيفة من واجهة `/jobs` (قائمة من الأحدث للأقدم من الخادم).
class JobPosting {
  JobPosting({
    required this.id,
    required this.postedBy,
    required this.workplaceName,
    required this.workplaceAddress,
    required this.requiredSpecialty,
    required this.yearsExperience,
    required this.monthlySalaryIqd,
    required this.shiftHours,
    required this.workingHours,
    required this.description,
    required this.education,
    required this.languages,
    required this.coreSkills,
    required this.applicationDeadline,
    required this.postingStatus,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String postedBy;
  final String workplaceName;
  final String workplaceAddress;
  final String requiredSpecialty;
  final int yearsExperience;
  final int? monthlySalaryIqd;
  final int? shiftHours;
  final String workingHours;
  final String? description;
  final JobEducationApi education;
  final List<JobLanguageApi> languages;
  final List<String> coreSkills;
  final DateTime? applicationDeadline;

  /// قيمة الخادم: pending | accepted | rejected (حقل status في JSON).
  final String postingStatus;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory JobPosting.fromJson(Map<String, dynamic> j) {
    return JobPosting(
      id: j['id'] as String,
      postedBy: j['posted_by'] as String,
      workplaceName: j['workplace_name'] as String? ?? '',
      workplaceAddress: j['workplace_address'] as String? ?? '',
      requiredSpecialty: j['required_specialty'] as String? ?? '',
      yearsExperience: (j['years_experience'] as num).toInt(),
      monthlySalaryIqd: j['monthly_salary_iqd'] == null
          ? null
          : (j['monthly_salary_iqd'] as num).toInt(),
      shiftHours: j['shift_hours'] == null
          ? null
          : (j['shift_hours'] as num).toInt(),
      workingHours: j['working_hours'] as String? ?? '',
      description: j['description'] as String?,
      education: _parseEducation(j['education'] as String?),
      languages: (j['languages'] as List<dynamic>? ?? [])
          .map((e) => _parseLang(e as String))
          .toList(),
      coreSkills: (j['core_skills'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      applicationDeadline: (j['application_deadline'] as String?) == null
          ? null
          : DateTime.parse(j['application_deadline'] as String),
      postingStatus: j['status'] == null ? 'pending' : j['status'].toString(),
      createdAt: DateTime.parse(j['created_at'] as String),
      updatedAt: DateTime.parse(j['updated_at'] as String),
    );
  }

  /// سطر الموقع في البطاقة (RTL): العنوان ، اسم المكان.
  String get locationSubtitle {
    final a = workplaceAddress.trim();
    final n = workplaceName.trim();
    if (a.isEmpty) return n;
    if (n.isEmpty) return a;
    return '$a ، $n';
  }

  String get salaryChipText {
    final v = monthlySalaryIqd;
    if (v == null) return 'غير محدد';
    return '${formatIqdWithCommas(v)} شهرياً';
  }

  String get hoursChipText {
    final h = shiftHours ?? _firstIntFromString(workingHours);
    if (h == null) return workingHours.trim().isEmpty ? '—' : workingHours;
    return '$h ساعة';
  }

  String descriptionPreview({int maxChars = 120}) {
    final t = (description ?? '').trim();
    if (t.isEmpty) {
      return 'تفاصيل الوظيفة أو نبذة مختصرة عنها...';
    }
    if (t.length <= maxChars) return t;
    return '${t.substring(0, maxChars)}…';
  }

  static JobEducationApi _parseEducation(String? v) {
    return JobEducationApi.values.firstWhere(
      (e) => e.name == v,
      orElse: () => JobEducationApi.bachelor,
    );
  }

  static JobLanguageApi _parseLang(String v) {
    return JobLanguageApi.values.firstWhere(
      (e) => e.name == v,
      orElse: () => JobLanguageApi.arabic,
    );
  }

  static int? _firstIntFromString(String s) {
    final m = RegExp(r'(\d+)').firstMatch(s);
    if (m == null) return null;
    return int.tryParse(m.group(1)!);
  }
}

String jobEducationLabelAr(JobEducationApi e) {
  switch (e) {
    case JobEducationApi.diploma:
      return 'دبلوم';
    case JobEducationApi.bachelor:
      return 'بكالوريوس';
    case JobEducationApi.master:
      return 'ماجستير';
    case JobEducationApi.doctorate:
      return 'دكتوراه';
  }
}

String jobLanguageLabelAr(JobLanguageApi e) {
  switch (e) {
    case JobLanguageApi.arabic:
      return 'العربية';
    case JobLanguageApi.english:
      return 'الإنجليزية';
  }
}
