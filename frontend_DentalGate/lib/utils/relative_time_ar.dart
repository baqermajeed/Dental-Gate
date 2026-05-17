/// وقت نسبي ب العربية للبطاقات (منذ X دقائق).
String relativeTimeAr(DateTime createdAtUtc) {
  final t = createdAtUtc.toLocal();
  var diff = DateTime.now().difference(t);
  if (diff.isNegative) diff = Duration.zero;

  if (diff.inMinutes < 1) return 'الآن';
  if (diff.inMinutes < 60) {
    final m = diff.inMinutes;
    if (m == 1) return 'منذ دقيقة';
    if (m == 2) return 'منذ دقيقتين';
    if (m <= 10) return 'منذ $m دقائق';
    return 'منذ $m دقيقة';
  }
  if (diff.inHours < 24) {
    final h = diff.inHours;
    if (h == 1) return 'منذ ساعة';
    if (h == 2) return 'منذ ساعتين';
    if (h <= 10) return 'منذ $h ساعات';
    return 'منذ $h ساعة';
  }
  final d = diff.inDays;
  if (d == 1) return 'منذ يوم';
  if (d == 2) return 'منذ يومين';
  if (d <= 10) return 'منذ $d أيام';
  return 'منذ $d يوم';
}
