/// معايير شيت «فلترة نتائج البحث» لتمريرها إلى [JobSearchResultsView] عبر GetX.
class JobSearchFilterCriteria {
  const JobSearchFilterCriteria({
    required this.specialtyText,
    required this.experienceIndex,
    this.province,
  });

  final String specialtyText;
  /// 0: 1–3 سنوات، 1: 3–5، 2: أكثر من 5
  final int experienceIndex;
  final String? province;
}
