import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;

import 'api_config_stub.dart'
    if (dart.library.io) 'api_config_io.dart' as host;

/// عنوان الـ API.
///
/// تجاوز صريح:
/// `flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8000`
///
/// يمكن مؤقتا توجيهه للسيرفر المحلي عبر:
/// `flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000`
const String kApiBaseUrlFromEnv = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: '',
);

String _defaultBaseWhenNoEnv() {
  return 'https://dentalgate.compassaccuracy.com';
}

String? _cachedApiBaseUrl;

/// عنوان الـ API مع تخزين مؤقت؛ سجل التشخيص يُطبع مرة واحدة فقط.
String apiBaseUrl() {
  if (_cachedApiBaseUrl != null) return _cachedApiBaseUrl!;
  final env = kApiBaseUrlFromEnv.trim();
  final base = env.isNotEmpty ? env : _defaultBaseWhenNoEnv();
  final normalized =
      base.endsWith('/') ? base.substring(0, base.length - 1) : base;
  _cachedApiBaseUrl = normalized;
  if (kDebugMode) {
    debugPrint('[API] Base URL: $normalized');
    if (host.isAndroidHost && env.isEmpty) {
      debugPrint('[API] Android emulator/host → $normalized');
    }
  }
  return normalized;
}
