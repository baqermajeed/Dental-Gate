import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// حفظ سجل البحث عن الوظائف محلياً.
class JobSearchHistoryService {
  JobSearchHistoryService._();

  static const _key = 'job_search_history_v1';
  static const int maxItems = 20;

  static List<String> _decodeList(String? raw) {
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<List<String>> load() async {
    final p = await SharedPreferences.getInstance();
    return _decodeList(p.getString(_key));
  }

  static Future<void> save(List<String> items) async {
    final p = await SharedPreferences.getInstance();
    final trimmed = items
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    await p.setString(_key, jsonEncode(trimmed));
  }

  /// يضيف الاستعلام في المقدمة بدون تكرار (قراءة/كتابة واحدة لتقليل انتظار القناة).
  static Future<List<String>> addQuery(String query) async {
    final q = query.trim();
    if (q.isEmpty) return load();
    final p = await SharedPreferences.getInstance();
    final prev = _decodeList(p.getString(_key));
    final next = <String>[q, ...prev.where((e) => e != q)];
    if (next.length > maxItems) {
      next.removeRange(maxItems, next.length);
    }
    await p.setString(_key, jsonEncode(next));
    return next;
  }

  static Future<List<String>> removeAt(int index) async {
    final prev = await load();
    if (index < 0 || index >= prev.length) return prev;
    prev.removeAt(index);
    await save(prev);
    return prev;
  }

  static Future<List<String>> clearAll() async {
    await save([]);
    return [];
  }
}
