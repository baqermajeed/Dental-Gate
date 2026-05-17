/// تحليل تواريخ الـ API: النصوص بدون offset تُفترض UTC (مثل Mongo/Pydantic قبل التصحيح).
DateTime? parseApiDateTimeUtc(dynamic raw) {
  if (raw == null) return null;
  if (raw is! String) return null;
  final s = raw.trim();
  if (s.isEmpty) return null;
  final d = DateTime.tryParse(s);
  if (d == null) return null;
  if (d.isUtc) return d;
  return DateTime.utc(
    d.year,
    d.month,
    d.day,
    d.hour,
    d.minute,
    d.second,
    d.millisecond,
    d.microsecond,
  );
}
