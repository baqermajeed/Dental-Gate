import 'dart:io' show Platform;

/// يُستورد فقط على منصات تدعم dart:io (ليس الويب).
bool get isAndroidHost => Platform.isAndroid;
