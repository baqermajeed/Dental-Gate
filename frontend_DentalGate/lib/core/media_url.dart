import 'package:dental_gate/core/api_config.dart';

String? _cachedApiBase;

/// يحوّل مساراً من الـ API (مثل `/static/uploads/...`) إلى URL كامل لـ [Image.network].
/// مسارات `http/https` تُعاد كما هي (مقارنة غير حساسة لحالة الأحرف).
String resolveMediaUrl(String? path) {
  final p = path?.trim() ?? '';
  if (p.isEmpty) return '';
  final lower = p.toLowerCase();
  if (lower.startsWith('http://') || lower.startsWith('https://')) return p;
  _cachedApiBase ??= apiBaseUrl();
  final b = _cachedApiBase!;
  if (b.isEmpty) return p;
  if (p.startsWith('/')) return '$b$p';
  return '$b/$p';
}

/// عكس [resolveMediaUrl]: يعيد المسار النسبي (مثل `/static/...`) لإرساله في JSON للباكند.
String stripMediaToApiPath(String resolvedOrPath) {
  final u = resolvedOrPath.trim();
  if (u.isEmpty) return '';
  if (u.startsWith('/')) return u;
  final lower = u.toLowerCase();
  if (lower.startsWith('http://') || lower.startsWith('https://')) {
    _cachedApiBase ??= apiBaseUrl();
    final b = _cachedApiBase!;
    if (b.isNotEmpty && u.startsWith(b)) {
      var rest = u.substring(b.length);
      if (rest.isNotEmpty && !rest.startsWith('/')) {
        rest = '/$rest';
      }
      return rest;
    }
  }
  return u;
}
