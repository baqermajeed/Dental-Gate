class DoctorSearchItem {
  const DoctorSearchItem({
    required this.id,
    this.name,
    this.professionalTitle,
    this.imageUrl,
    this.yearsExperience,
    this.governorate,
    required this.phone,
  });

  final String id;
  final String? name;
  final String? professionalTitle;
  final String? imageUrl;
  final int? yearsExperience;
  final String? governorate;
  final String phone;

  factory DoctorSearchItem.fromJson(Map<String, dynamic> j) {
    return DoctorSearchItem(
      id: j['id'] as String,
      name: j['name'] as String?,
      professionalTitle: j['professional_title'] as String?,
      imageUrl: j['imageUrl'] as String?,
      yearsExperience: (j['years_experience'] as num?)?.toInt(),
      governorate: j['governorate'] as String?,
      phone: j['phone'] as String? ?? '',
    );
  }

  String get displayName =>
      (name?.trim().isNotEmpty ?? false) ? name!.trim() : 'طبيب';

  String get specialtyLabel =>
      (professionalTitle?.trim().isNotEmpty ?? false)
          ? professionalTitle!.trim()
          : 'طبيب أسنان';

  String get experienceLine {
    final y = yearsExperience;
    if (y == null) return 'خبرة غير محددة';
    return '$y سنوات خبرة';
  }

  String get locationLine =>
      (governorate?.trim().isNotEmpty ?? false) ? governorate!.trim() : '—';
}
