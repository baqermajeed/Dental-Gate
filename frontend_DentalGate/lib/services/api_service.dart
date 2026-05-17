import 'dart:convert';

import 'package:flutter/foundation.dart' show compute, debugPrint;
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import 'package:dental_gate/core/api_config.dart';
import 'package:dental_gate/models/auth_tokens.dart';
import 'package:dental_gate/models/doctor_peer_rating.dart';
import 'package:dental_gate/models/doctor_profile_full.dart';
import 'package:dental_gate/models/home_slider_item.dart';
import 'package:dental_gate/models/job_applicant_item.dart';
import 'package:dental_gate/models/job_posting.dart';
import 'package:dental_gate/models/app_notification.dart';
import 'package:dental_gate/models/doctor_search_item.dart';
import 'package:dental_gate/models/my_job_application_item.dart';
import 'package:dental_gate/models/user_profile.dart';
import 'package:dental_gate/services/token_storage.dart';

String _basenameFromPath(String filePath) {
  final norm = filePath.replaceAll(r'\', '/');
  final i = norm.lastIndexOf('/');
  return i >= 0 ? norm.substring(i + 1) : norm;
}

/// يُستدعى من [compute] — يجب أن يكون top-level لرفع التحميل عن الخيط الرئيسي عند قوائم ضخمة.
List<String> _decodeProfilePickListJson(String jsonUtf8) {
  final list = jsonDecode(jsonUtf8) as List<dynamic>;
  return list.map((e) => e.toString()).toList();
}

Future<List<String>> _profilePickListFromResponse(http.Response res) async {
  final raw = utf8.decode(res.bodyBytes);
  return compute(_decodeProfilePickListJson, raw);
}

/// نوع MIME يطابق ما يتوقعه الباكند؛ يُصلح رفض `application/octet-stream` من أندرويد.
MediaType _imageMediaTypeForPath(String filePath) {
  final lower = _basenameFromPath(filePath).toLowerCase();
  if (lower.endsWith('.png')) return MediaType('image', 'png');
  if (lower.endsWith('.webp')) return MediaType('image', 'webp');
  if (lower.endsWith('.jpeg') || lower.endsWith('.jpg')) {
    return MediaType('image', 'jpeg');
  }
  if (lower.endsWith('.heic')) return MediaType('image', 'heic');
  if (lower.endsWith('.heif')) return MediaType('image', 'heif');
  return MediaType('image', 'jpeg');
}

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

/// Verify OTP response: existing account with tokens, or no account yet.
class VerifyOtpResult {
  VerifyOtpResult({required this.accountExists, this.tokens});

  final bool accountExists;
  final AuthTokens? tokens;
}

class ApiService {
  ApiService._();

  static final ApiService instance = ApiService._();

  Uri _u(String path) => Uri.parse('${apiBaseUrl()}$path');

  Map<String, String> _jsonHeaders({String? bearer}) {
    final h = <String, String>{
      'Content-Type': 'application/json; charset=utf-8',
    };
    if (bearer != null && bearer.isNotEmpty) {
      h['Authorization'] = 'Bearer $bearer';
    }
    return h;
  }

  String _networkFailureMessage(Object e) {
    debugPrint('API network error: $e');
    final s = e.toString();
    if (s.contains('SocketException') ||
        s.contains('ClientException') ||
        s.contains('Connection refused') ||
        s.contains('Connection reset') ||
        s.contains('Network is unreachable') ||
        s.contains('Failed host lookup')) {
      return 'تعذر الاتصال بالخادم على ${apiBaseUrl()}. تأكد أن الباكند يعمل (uvicorn). على هاتف حقيقي عيّن IP الكمبيوتر عبر --dart-define=API_BASE_URL=...';
    }
    return 'تعذر الاتصال بالخادم';
  }

  Future<T> _withNetwork<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on ApiException {
      rethrow;
    } catch (e, st) {
      debugPrint('API: $e\n$st');
      throw ApiException(_networkFailureMessage(e));
    }
  }

  String _errorBody(http.Response res) {
    try {
      final j = jsonDecode(utf8.decode(res.bodyBytes));
      if (j is Map && j['detail'] != null) {
        final d = j['detail'];
        if (d is String) return d;
        if (d is List) {
          final parts = <String>[];
          for (final item in d) {
            if (item is Map) {
              final msg = item['msg']?.toString();
              if (msg != null && msg.isNotEmpty) {
                parts.add(msg);
              } else {
                parts.add(item.toString());
              }
            } else {
              parts.add(item.toString());
            }
          }
          if (parts.isNotEmpty) return parts.join('\n');
        }
        return d.toString();
      }
    } catch (_) {}
    return res.reasonPhrase ?? 'خطأ في الاتصال';
  }

  Future<void> requestOtp(String phone) async {
    await _withNetwork(() async {
      final res = await http.post(
        _u('/auth/request-otp'),
        headers: _jsonHeaders(),
        body: jsonEncode({'phone': phone.trim()}),
      );
      if (res.statusCode >= 400) {
        throw ApiException(_errorBody(res), statusCode: res.statusCode);
      }
    });
  }

  Future<VerifyOtpResult> verifyOtp({
    required String phone,
    required String code,
  }) async {
    return _withNetwork(() async {
      final res = await http.post(
        _u('/auth/verify-otp'),
        headers: _jsonHeaders(),
        body: jsonEncode({'phone': phone.trim(), 'code': code.trim()}),
      );
      if (res.statusCode >= 400) {
        throw ApiException(_errorBody(res), statusCode: res.statusCode);
      }
      final map =
          jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      final exists = map['account_exists'] == true;
      if (!exists) {
        return VerifyOtpResult(accountExists: false);
      }
      final tokenMap = map['token'] as Map<String, dynamic>?;
      if (tokenMap == null) {
        return VerifyOtpResult(accountExists: false);
      }
      final tokens = AuthTokens.fromJson(tokenMap);
      await TokenStorage.instance.saveTokens(tokens);
      return VerifyOtpResult(accountExists: true, tokens: tokens);
    });
  }

  Future<AuthTokens> register({
    required String name,
    required String phone,
    required String email,
    required int age,
    required String genderApi,
  }) async {
    return _withNetwork(() async {
      final res = await http.post(
        _u('/auth/register'),
        headers: _jsonHeaders(),
        body: jsonEncode({
          'name': name.trim(),
          'phone': phone.trim(),
          'email': email.trim(),
          'age': age,
          'gender': genderApi,
        }),
      );
      if (res.statusCode >= 400) {
        throw ApiException(_errorBody(res), statusCode: res.statusCode);
      }
      final map =
          jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      final tokens = AuthTokens.fromJson(map);
      await TokenStorage.instance.saveTokens(tokens);
      return tokens;
    });
  }

  /// بروفايل الطبيب الكامل من `/profile/me`.
  Future<DoctorProfileFull> fetchDoctorProfileFull() async {
    return _withNetwork(() async {
      var access = await TokenStorage.instance.accessToken();
      if (access == null || access.isEmpty) {
        throw ApiException('غير مسجل الدخول');
      }
      var res = await http.get(
        _u('/profile/me'),
        headers: _jsonHeaders(bearer: access),
      );
      if (res.statusCode == 401) {
        await _refreshOrThrow();
        access = await TokenStorage.instance.accessToken();
        if (access == null || access.isEmpty) {
          throw ApiException('انتهت الجلسة');
        }
        res = await http.get(
          _u('/profile/me'),
          headers: _jsonHeaders(bearer: access),
        );
      }
      if (res.statusCode >= 400) {
        throw ApiException(_errorBody(res), statusCode: res.statusCode);
      }
      final map =
          jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      return DoctorProfileFull.fromJson(map);
    });
  }

  Future<List<String>> fetchDentalSpecialties() async {
    return _withNetwork(() async {
      final res = await http.get(
        _u('/profile/specialties'),
        headers: _jsonHeaders(),
      );
      if (res.statusCode >= 400) {
        throw ApiException(_errorBody(res), statusCode: res.statusCode);
      }
      return _profilePickListFromResponse(res);
    });
  }

  Future<List<String>> fetchEducationOptions() async {
    return _withNetwork(() async {
      final res = await http.get(
        _u('/profile/education-options'),
        headers: _jsonHeaders(),
      );
      if (res.statusCode >= 400) {
        throw ApiException(_errorBody(res), statusCode: res.statusCode);
      }
      return _profilePickListFromResponse(res);
    });
  }

  Future<List<String>> fetchLanguageOptions() async {
    return _withNetwork(() async {
      final res = await http.get(
        _u('/profile/language-options'),
        headers: _jsonHeaders(),
      );
      if (res.statusCode >= 400) {
        throw ApiException(_errorBody(res), statusCode: res.statusCode);
      }
      return _profilePickListFromResponse(res);
    });
  }

  Future<List<String>> fetchUniversityOptions() async {
    return _withNetwork(() async {
      final res = await http.get(
        _u('/profile/university-options'),
        headers: _jsonHeaders(),
      );
      if (res.statusCode >= 400) {
        throw ApiException(_errorBody(res), statusCode: res.statusCode);
      }
      return _profilePickListFromResponse(res);
    });
  }

  Future<List<String>> fetchSkillOptions() async {
    return _withNetwork(() async {
      final res = await http.get(
        _u('/profile/skill-options'),
        headers: _jsonHeaders(),
      );
      if (res.statusCode >= 400) {
        throw ApiException(_errorBody(res), statusCode: res.statusCode);
      }
      return _profilePickListFromResponse(res);
    });
  }

  /// إرسال دورة معتمدة للتحقق الإداري.
  Future<DoctorProfileFull> submitAccreditedCourse({
    required String title,
    required String imageUrl,
    required String explanation,
  }) async {
    return _withNetwork(() async {
      var access = await TokenStorage.instance.accessToken();
      if (access == null || access.isEmpty) {
        throw ApiException('غير مسجل الدخول');
      }
      Future<http.Response> req(String token) => http.post(
        _u('/profile/me/accredited-courses'),
        headers: _jsonHeaders(bearer: token),
        body: jsonEncode({
          'title': title,
          'image_url': imageUrl,
          'explanation': explanation,
        }),
      );
      var res = await req(access);
      if (res.statusCode == 401) {
        await _refreshOrThrow();
        access = await TokenStorage.instance.accessToken();
        if (access == null || access.isEmpty) {
          throw ApiException('انتهت الجلسة');
        }
        res = await req(access);
      }
      if (res.statusCode >= 400) {
        throw ApiException(_errorBody(res), statusCode: res.statusCode);
      }
      final map =
          jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      return DoctorProfileFull.fromJson(map);
    });
  }

  /// إرسال شهادة ممارسة المهنة للتحقق الإداري.
  Future<DoctorProfileFull> submitPracticeLicense({
    required String imageUrl,
    required String explanation,
  }) async {
    return _withNetwork(() async {
      var access = await TokenStorage.instance.accessToken();
      if (access == null || access.isEmpty) {
        throw ApiException('غير مسجل الدخول');
      }
      Future<http.Response> req(String token) => http.post(
        _u('/profile/me/practice-license'),
        headers: _jsonHeaders(bearer: token),
        body: jsonEncode({
          'image_url': imageUrl,
          'explanation': explanation,
        }),
      );
      var res = await req(access);
      if (res.statusCode == 401) {
        await _refreshOrThrow();
        access = await TokenStorage.instance.accessToken();
        if (access == null || access.isEmpty) {
          throw ApiException('انتهت الجلسة');
        }
        res = await req(access);
      }
      if (res.statusCode >= 400) {
        throw ApiException(_errorBody(res), statusCode: res.statusCode);
      }
      final map =
          jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      return DoctorProfileFull.fromJson(map);
    });
  }

  Future<DoctorProfileFull> patchDoctorProfile({
    required Map<String, dynamic> body,
  }) async {
    return _withNetwork(() async {
      var access = await TokenStorage.instance.accessToken();
      if (access == null || access.isEmpty) {
        throw ApiException('غير مسجل الدخول');
      }
      Future<http.Response> req(String token) => http.patch(
        _u('/profile/me'),
        headers: _jsonHeaders(bearer: token),
        body: jsonEncode(body),
      );
      var res = await req(access);
      if (res.statusCode == 401) {
        await _refreshOrThrow();
        access = await TokenStorage.instance.accessToken();
        if (access == null || access.isEmpty) {
          throw ApiException('انتهت الجلسة');
        }
        res = await req(access);
      }
      if (res.statusCode >= 400) {
        throw ApiException(_errorBody(res), statusCode: res.statusCode);
      }
      final map =
          jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      return DoctorProfileFull.fromJson(map);
    });
  }

  /// رفع صورة للبروفايل؛ يُعاد المسار النسبي (مثل `/static/uploads/...`) للحفظ في الحقول.
  Future<String> uploadProfileImage({
    required String filePath,
    String purpose = 'general',
  }) async {
    return _withNetwork(() async {
      var access = await TokenStorage.instance.accessToken();
      if (access == null || access.isEmpty) {
        throw ApiException('غير مسجل الدخول');
      }
      final uri = _u(
        '/profile/me/upload',
      ).replace(queryParameters: <String, String>{'purpose': purpose});
      Future<http.StreamedResponse> send(String token) async {
        final req = http.MultipartRequest('POST', uri);
        req.headers['Authorization'] = 'Bearer $token';
        req.files.add(
          await http.MultipartFile.fromPath(
            'file',
            filePath,
            filename: _basenameFromPath(filePath),
            contentType: _imageMediaTypeForPath(filePath),
          ),
        );
        return req.send();
      }

      var streamed = await send(access);
      var res = await http.Response.fromStream(streamed);
      if (res.statusCode == 401) {
        await _refreshOrThrow();
        access = await TokenStorage.instance.accessToken();
        if (access == null || access.isEmpty) {
          throw ApiException('انتهت الجلسة');
        }
        streamed = await send(access);
        res = await http.Response.fromStream(streamed);
      }
      if (res.statusCode >= 400) {
        throw ApiException(_errorBody(res), statusCode: res.statusCode);
      }
      final map =
          jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      final url = map['url']?.toString().trim() ?? '';
      if (url.isEmpty) {
        throw ApiException('استجابة رفع غير صالحة');
      }
      return url;
    });
  }

  /// قائمة الأطباء لصفحة البحث.
  Future<List<DoctorSearchItem>> fetchDoctorsForSearch({String? query}) async {
    return _withNetwork(() async {
      var access = await TokenStorage.instance.accessToken();
      if (access == null || access.isEmpty) {
        throw ApiException('غير مسجل الدخول');
      }
      final q = (query ?? '').trim();
      final uri = q.isEmpty
          ? _u('/profile/doctors')
          : _u('/profile/doctors').replace(queryParameters: {'q': q});
      Future<http.Response> req(String token) =>
          http.get(uri, headers: _jsonHeaders(bearer: token));
      var res = await req(access);
      if (res.statusCode == 401) {
        await _refreshOrThrow();
        access = await TokenStorage.instance.accessToken();
        if (access == null || access.isEmpty) {
          throw ApiException('انتهت الجلسة');
        }
        res = await req(access);
      }
      if (res.statusCode >= 400) {
        throw ApiException(_errorBody(res), statusCode: res.statusCode);
      }
      final list = jsonDecode(utf8.decode(res.bodyBytes)) as List<dynamic>;
      return list
          .map((e) => DoctorSearchItem.fromJson(e as Map<String, dynamic>))
          .toList();
    });
  }

  /// بروفايل طبيب محدد (صفحة البحث عن أطباء).
  Future<DoctorProfileFull> fetchDoctorProfileByUserId(String userId) async {
    return _withNetwork(() async {
      var access = await TokenStorage.instance.accessToken();
      if (access == null || access.isEmpty) {
        throw ApiException('غير مسجل الدخول');
      }
      Future<http.Response> req(String token) => http.get(
        _u('/profile/doctors/$userId'),
        headers: _jsonHeaders(bearer: token),
      );
      var res = await req(access);
      if (res.statusCode == 401) {
        await _refreshOrThrow();
        access = await TokenStorage.instance.accessToken();
        if (access == null || access.isEmpty) {
          throw ApiException('انتهت الجلسة');
        }
        res = await req(access);
      }
      if (res.statusCode >= 400) {
        throw ApiException(_errorBody(res), statusCode: res.statusCode);
      }
      final map =
          jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      return DoctorProfileFull.fromJson(map);
    });
  }

  /// تقييمات واردة لبروفايلي.
  Future<DoctorPeerRatingsPage> fetchMyPeerRatings() async {
    return _withNetwork(() async {
      var access = await TokenStorage.instance.accessToken();
      if (access == null || access.isEmpty) {
        throw ApiException('غير مسجل الدخول');
      }
      Future<http.Response> req(String token) => http.get(
        _u('/profile/me/peer-ratings'),
        headers: _jsonHeaders(bearer: token),
      );
      var res = await req(access);
      if (res.statusCode == 401) {
        await _refreshOrThrow();
        access = await TokenStorage.instance.accessToken();
        if (access == null || access.isEmpty) {
          throw ApiException('انتهت الجلسة');
        }
        res = await req(access);
      }
      if (res.statusCode >= 400) {
        throw ApiException(_errorBody(res), statusCode: res.statusCode);
      }
      final map =
          jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      return DoctorPeerRatingsPage.fromJson(map);
    });
  }

  /// تقييمات طبيب من الزملاء.
  Future<DoctorPeerRatingsPage> fetchDoctorPeerRatings(String doctorUserId) async {
    final id = doctorUserId.trim();
    if (id.isEmpty) {
      throw ApiException('معرّف الطبيب غير صالح');
    }
    return _withNetwork(() async {
      var access = await TokenStorage.instance.accessToken();
      if (access == null || access.isEmpty) {
        throw ApiException('غير مسجل الدخول');
      }
      Future<http.Response> req(String token) => http.get(
        _u('/profile/doctors/$id/peer-ratings'),
        headers: _jsonHeaders(bearer: token),
      );
      var res = await req(access);
      if (res.statusCode == 401) {
        await _refreshOrThrow();
        access = await TokenStorage.instance.accessToken();
        if (access == null || access.isEmpty) {
          throw ApiException('انتهت الجلسة');
        }
        res = await req(access);
      }
      if (res.statusCode >= 400) {
        throw ApiException(_errorBody(res), statusCode: res.statusCode);
      }
      final map =
          jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      return DoctorPeerRatingsPage.fromJson(map);
    });
  }

  /// إرسال تقييم لطبيب (مرة واحدة فقط).
  Future<DoctorPeerRatingItem> submitDoctorPeerRating({
    required String doctorUserId,
    required int stars,
    required String comment,
  }) async {
    final id = doctorUserId.trim();
    if (id.isEmpty) {
      throw ApiException('معرّف الطبيب غير صالح');
    }
    return _withNetwork(() async {
      var access = await TokenStorage.instance.accessToken();
      if (access == null || access.isEmpty) {
        throw ApiException('غير مسجل الدخول');
      }
      Future<http.Response> req(String token) => http.post(
        _u('/profile/doctors/$id/peer-ratings'),
        headers: _jsonHeaders(bearer: token),
        body: jsonEncode({'stars': stars, 'comment': comment}),
      );
      var res = await req(access);
      if (res.statusCode == 401) {
        await _refreshOrThrow();
        access = await TokenStorage.instance.accessToken();
        if (access == null || access.isEmpty) {
          throw ApiException('انتهت الجلسة');
        }
        res = await req(access);
      }
      if (res.statusCode >= 400) {
        throw ApiException(_errorBody(res), statusCode: res.statusCode);
      }
      final map =
          jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      return DoctorPeerRatingItem.fromJson(map);
    });
  }

  /// بروفايل متقدّم على وظيفة (صاحب الإعلان فقط) — نفس شكل ``/profile/me``.
  Future<DoctorProfileFull> fetchJobApplicantProfileFull({
    required String jobId,
    required String applicationId,
  }) async {
    return _withNetwork(() async {
      var access = await TokenStorage.instance.accessToken();
      if (access == null || access.isEmpty) {
        throw ApiException('غير مسجل الدخول');
      }
      Future<http.Response> req(String token) => http.get(
        _u('/jobs/$jobId/applications/$applicationId/profile'),
        headers: _jsonHeaders(bearer: token),
      );
      var res = await req(access);
      if (res.statusCode == 401) {
        await _refreshOrThrow();
        access = await TokenStorage.instance.accessToken();
        if (access == null || access.isEmpty) {
          throw ApiException('انتهت الجلسة');
        }
        res = await req(access);
      }
      if (res.statusCode >= 400) {
        throw ApiException(_errorBody(res), statusCode: res.statusCode);
      }
      final map =
          jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      return DoctorProfileFull.fromJson(map);
    });
  }

  Future<UserProfile> fetchMe() async {
    return _withNetwork(() async {
      var access = await TokenStorage.instance.accessToken();
      if (access == null || access.isEmpty) {
        throw ApiException('غير مسجل الدخول');
      }
      var res = await http.get(
        _u('/auth/me'),
        headers: _jsonHeaders(bearer: access),
      );
      if (res.statusCode == 401) {
        await _refreshOrThrow();
        access = await TokenStorage.instance.accessToken();
        if (access == null || access.isEmpty) {
          throw ApiException('انتهت الجلسة');
        }
        res = await http.get(
          _u('/auth/me'),
          headers: _jsonHeaders(bearer: access),
        );
      }
      if (res.statusCode >= 400) {
        throw ApiException(_errorBody(res), statusCode: res.statusCode);
      }
      final map =
          jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      return UserProfile.fromJson(map);
    });
  }

  Future<void> _refreshOrThrow() async {
    final stored = await TokenStorage.instance.readTokens();
    if (stored == null) {
      await TokenStorage.instance.clear();
      throw ApiException('انتهت الجلسة');
    }
    try {
      final res = await http.post(
        _u('/auth/refresh'),
        headers: _jsonHeaders(),
        body: jsonEncode({'refresh_token': stored.refreshToken}),
      );
      if (res.statusCode >= 400) {
        await TokenStorage.instance.clear();
        throw ApiException('انتهت الجلسة');
      }
      final map =
          jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      await TokenStorage.instance.saveTokens(AuthTokens.fromJson(map));
    } catch (e, st) {
      if (e is ApiException) rethrow;
      debugPrint('refresh: $e\n$st');
      throw ApiException(_networkFailureMessage(e));
    }
  }

  Future<void> logout() => TokenStorage.instance.clear();

  /// حذف حساب المستخدم الحالي من الخادم (ثم نفّض التخزين المحلي عبر AccountDeleteCleanup).
  Future<void> deleteMyAccount() async {
    return _withNetwork(() async {
      var access = await TokenStorage.instance.accessToken();
      if (access == null || access.isEmpty) {
        throw ApiException('غير مسجل الدخول');
      }
      Future<http.Response> send(String token) async => http.delete(
            _u('/auth/me'),
            headers: _jsonHeaders(bearer: token),
          );
      var res = await send(access);
      if (res.statusCode == 401) {
        await _refreshOrThrow();
        access = await TokenStorage.instance.accessToken();
        if (access == null || access.isEmpty) {
          throw ApiException('انتهت الجلسة');
        }
        res = await send(access);
      }
      if (res.statusCode >= 400) {
        throw ApiException(_errorBody(res), statusCode: res.statusCode);
      }
    });
  }

  /// قائمة الوظائف العامة (الأحدث أولاً من الخادم).
  Future<List<JobPosting>> fetchJobPostings() async {
    return _withNetwork(() async {
      final res = await http.get(_u('/jobs'), headers: _jsonHeaders());
      if (res.statusCode >= 400) {
        throw ApiException(_errorBody(res), statusCode: res.statusCode);
      }
      final list = jsonDecode(utf8.decode(res.bodyBytes)) as List<dynamic>;
      return list
          .map((e) => JobPosting.fromJson(e as Map<String, dynamic>))
          .toList();
    });
  }

  /// الوظائف التي نشرها المستخدم الحالي (تتضمن المنتهية).
  Future<List<JobPosting>> fetchMyPostedJobs() async {
    return _withNetwork(() async {
      var access = await TokenStorage.instance.accessToken();
      if (access == null || access.isEmpty) {
        throw ApiException('سجّل الدخول لعرض وظائفك المنشورة');
      }
      var res = await http.get(
        _u('/jobs/mine'),
        headers: _jsonHeaders(bearer: access),
      );
      if (res.statusCode == 401) {
        await _refreshOrThrow();
        access = await TokenStorage.instance.accessToken();
        if (access == null || access.isEmpty) {
          throw ApiException('انتهت الجلسة');
        }
        res = await http.get(
          _u('/jobs/mine'),
          headers: _jsonHeaders(bearer: access),
        );
      }
      if (res.statusCode >= 400) {
        throw ApiException(_errorBody(res), statusCode: res.statusCode);
      }
      final list = jsonDecode(utf8.decode(res.bodyBytes)) as List<dynamic>;
      return list
          .map((e) => JobPosting.fromJson(e as Map<String, dynamic>))
          .toList();
    });
  }

  Future<JobPosting> fetchJobById(String jobId) async {
    return _withNetwork(() async {
      final res = await http.get(_u('/jobs/$jobId'), headers: _jsonHeaders());
      if (res.statusCode >= 400) {
        throw ApiException(_errorBody(res), statusCode: res.statusCode);
      }
      final map =
          jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      return JobPosting.fromJson(map);
    });
  }

  /// عدد المتقدمين على وظيفة (صاحب الإعلان فقط، يتطلب جلسة).
  Future<int> fetchMyJobApplicationCount(String jobId) async {
    return _withNetwork(() async {
      var access = await TokenStorage.instance.accessToken();
      if (access == null || access.isEmpty) {
        throw ApiException('سجّل الدخول');
      }
      var res = await http.get(
        _u('/jobs/$jobId/applications/count'),
        headers: _jsonHeaders(bearer: access),
      );
      if (res.statusCode == 401) {
        await _refreshOrThrow();
        access = await TokenStorage.instance.accessToken();
        if (access == null || access.isEmpty) {
          throw ApiException('انتهت الجلسة');
        }
        res = await http.get(
          _u('/jobs/$jobId/applications/count'),
          headers: _jsonHeaders(bearer: access),
        );
      }
      if (res.statusCode >= 400) {
        throw ApiException(_errorBody(res), statusCode: res.statusCode);
      }
      final map =
          jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      return (map['count'] as num).toInt();
    });
  }

  /// قائمة المتقدمين على وظيفة (صاحب الإعلان فقط).
  Future<List<JobApplicantItem>> fetchJobApplicantsForOwner(
    String jobId,
  ) async {
    return _withNetwork(() async {
      var access = await TokenStorage.instance.accessToken();
      if (access == null || access.isEmpty) {
        throw ApiException('سجّل الدخول');
      }
      var res = await http.get(
        _u('/jobs/$jobId/applications'),
        headers: _jsonHeaders(bearer: access),
      );
      if (res.statusCode == 401) {
        await _refreshOrThrow();
        access = await TokenStorage.instance.accessToken();
        if (access == null || access.isEmpty) {
          throw ApiException('انتهت الجلسة');
        }
        res = await http.get(
          _u('/jobs/$jobId/applications'),
          headers: _jsonHeaders(bearer: access),
        );
      }
      if (res.statusCode >= 400) {
        throw ApiException(_errorBody(res), statusCode: res.statusCode);
      }
      final list = jsonDecode(utf8.decode(res.bodyBytes)) as List<dynamic>;
      return list
          .map((e) => JobApplicantItem.fromJson(e as Map<String, dynamic>))
          .toList();
    });
  }

  /// تحديث حالة طلب تقديم (صاحب الإعلان فقط).
  Future<JobApplicationStatusApi> patchJobApplicationStatus({
    required String jobId,
    required String applicationId,
    required JobApplicationStatusApi status,
  }) async {
    return _withNetwork(() async {
      var access = await TokenStorage.instance.accessToken();
      if (access == null || access.isEmpty) {
        throw ApiException('سجّل الدخول');
      }
      final body = jsonEncode({'status': status.name});
      Future<http.Response> req(String token) => http.patch(
        _u('/jobs/$jobId/applications/$applicationId'),
        headers: _jsonHeaders(bearer: token),
        body: body,
      );
      var res = await req(access);
      if (res.statusCode == 401) {
        await _refreshOrThrow();
        access = await TokenStorage.instance.accessToken();
        if (access == null || access.isEmpty) {
          throw ApiException('انتهت الجلسة');
        }
        res = await req(access);
      }
      if (res.statusCode >= 400) {
        throw ApiException(_errorBody(res), statusCode: res.statusCode);
      }
      final map =
          jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      return MyJobApplicationItem.parseStatus(map['status'] as String?);
    });
  }

  /// إنشاء إعلان وظيفة (يتطلب جلسة).
  Future<JobPosting> createJobPosting(Map<String, dynamic> body) async {
    return _withNetwork(() async {
      var access = await TokenStorage.instance.accessToken();
      if (access == null || access.isEmpty) {
        throw ApiException('سجّل الدخول لنشر وظيفة');
      }
      var res = await http.post(
        _u('/jobs'),
        headers: _jsonHeaders(bearer: access),
        body: jsonEncode(body),
      );
      if (res.statusCode == 401) {
        await _refreshOrThrow();
        access = await TokenStorage.instance.accessToken();
        if (access == null || access.isEmpty) {
          throw ApiException('انتهت الجلسة');
        }
        res = await http.post(
          _u('/jobs'),
          headers: _jsonHeaders(bearer: access),
          body: jsonEncode(body),
        );
      }
      if (res.statusCode >= 400) {
        throw ApiException(_errorBody(res), statusCode: res.statusCode);
      }
      final map =
          jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      return JobPosting.fromJson(map);
    });
  }

  /// تحديث إعلان وظيفة (صاحب الإعلان فقط).
  Future<JobPosting> updateJobPosting(
    String jobId,
    Map<String, dynamic> body,
  ) async {
    return _withNetwork(() async {
      var access = await TokenStorage.instance.accessToken();
      if (access == null || access.isEmpty) {
        throw ApiException('سجّل الدخول لتعديل الوظيفة');
      }
      Future<http.Response> req(String token) => http.patch(
        _u('/jobs/$jobId'),
        headers: _jsonHeaders(bearer: token),
        body: jsonEncode(body),
      );
      var res = await req(access);
      if (res.statusCode == 401) {
        await _refreshOrThrow();
        access = await TokenStorage.instance.accessToken();
        if (access == null || access.isEmpty) {
          throw ApiException('انتهت الجلسة');
        }
        res = await req(access);
      }
      if (res.statusCode >= 400) {
        throw ApiException(_errorBody(res), statusCode: res.statusCode);
      }
      final map =
          jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      return JobPosting.fromJson(map);
    });
  }

  /// حذف إعلان وظيفة (صاحب الإعلان فقط).
  Future<void> deleteJobPosting(String jobId) async {
    return _withNetwork(() async {
      var access = await TokenStorage.instance.accessToken();
      if (access == null || access.isEmpty) {
        throw ApiException('سجّل الدخول لحذف الوظيفة');
      }
      Future<http.Response> req(String token) =>
          http.delete(_u('/jobs/$jobId'), headers: _jsonHeaders(bearer: token));
      var res = await req(access);
      if (res.statusCode == 401) {
        await _refreshOrThrow();
        access = await TokenStorage.instance.accessToken();
        if (access == null || access.isEmpty) {
          throw ApiException('انتهت الجلسة');
        }
        res = await req(access);
      }
      if (res.statusCode >= 400) {
        throw ApiException(_errorBody(res), statusCode: res.statusCode);
      }
    });
  }

  Future<List<HomeSliderItem>> fetchHomeSliders() async {
    return _withNetwork(() async {
      final res = await http.get(_u('/home-sliders'), headers: _jsonHeaders());
      if (res.statusCode >= 400) {
        throw ApiException(_errorBody(res), statusCode: res.statusCode);
      }
      final list = jsonDecode(utf8.decode(res.bodyBytes)) as List<dynamic>;
      return list
          .map((e) => HomeSliderItem.fromJson(e as Map<String, dynamic>))
          .toList();
    });
  }

  /// طلبات التوظيف التي قدّمها المستخدم الحالي (الأحدث أولاً).
  Future<List<MyJobApplicationItem>> fetchMyJobApplications() async {
    return _withNetwork(() async {
      var access = await TokenStorage.instance.accessToken();
      if (access == null || access.isEmpty) {
        throw ApiException('سجّل الدخول لعرض طلباتك');
      }
      var res = await http.get(
        _u('/jobs/applications/me'),
        headers: _jsonHeaders(bearer: access),
      );
      if (res.statusCode == 401) {
        await _refreshOrThrow();
        access = await TokenStorage.instance.accessToken();
        if (access == null || access.isEmpty) {
          throw ApiException('انتهت الجلسة');
        }
        res = await http.get(
          _u('/jobs/applications/me'),
          headers: _jsonHeaders(bearer: access),
        );
      }
      if (res.statusCode >= 400) {
        throw ApiException(_errorBody(res), statusCode: res.statusCode);
      }
      final list = jsonDecode(utf8.decode(res.bodyBytes)) as List<dynamic>;
      return list
          .map((e) => MyJobApplicationItem.fromJson(e as Map<String, dynamic>))
          .toList();
    });
  }

  /// التقديم على وظيفة (يتطلب جلسة).
  Future<void> applyToJob(String jobId) async {
    return _withNetwork(() async {
      var access = await TokenStorage.instance.accessToken();
      if (access == null || access.isEmpty) {
        throw ApiException('سجّل الدخول للتقديم على الوظيفة');
      }
      var res = await http.post(
        _u('/jobs/$jobId/apply'),
        headers: _jsonHeaders(bearer: access),
      );
      if (res.statusCode == 401) {
        await _refreshOrThrow();
        access = await TokenStorage.instance.accessToken();
        if (access == null || access.isEmpty) {
          throw ApiException('انتهت الجلسة');
        }
        res = await http.post(
          _u('/jobs/$jobId/apply'),
          headers: _jsonHeaders(bearer: access),
        );
      }
      if (res.statusCode >= 400) {
        throw ApiException(_errorBody(res), statusCode: res.statusCode);
      }
    });
  }

  /// الوظائف المحفوظة للمستخدم الحالي.
  Future<List<JobPosting>> fetchSavedJobs() async {
    return _withNetwork(() async {
      var access = await TokenStorage.instance.accessToken();
      if (access == null || access.isEmpty) {
        throw ApiException('سجّل الدخول لعرض المحفوظات');
      }
      var res = await http.get(
        _u('/saved-jobs'),
        headers: _jsonHeaders(bearer: access),
      );
      if (res.statusCode == 401) {
        await _refreshOrThrow();
        access = await TokenStorage.instance.accessToken();
        if (access == null || access.isEmpty) {
          throw ApiException('انتهت الجلسة');
        }
        res = await http.get(
          _u('/saved-jobs'),
          headers: _jsonHeaders(bearer: access),
        );
      }
      if (res.statusCode >= 400) {
        throw ApiException(_errorBody(res), statusCode: res.statusCode);
      }
      final list = jsonDecode(utf8.decode(res.bodyBytes)) as List<dynamic>;
      return list
          .map((e) => JobPosting.fromJson(e as Map<String, dynamic>))
          .toList();
    });
  }

  Future<void> saveJob(String jobId) async {
    return _withNetwork(() async {
      var access = await TokenStorage.instance.accessToken();
      if (access == null || access.isEmpty) {
        throw ApiException('سجّل الدخول للحفظ');
      }
      var res = await http.post(
        _u('/saved-jobs/$jobId'),
        headers: _jsonHeaders(bearer: access),
      );
      if (res.statusCode == 401) {
        await _refreshOrThrow();
        access = await TokenStorage.instance.accessToken();
        if (access == null || access.isEmpty) {
          throw ApiException('انتهت الجلسة');
        }
        res = await http.post(
          _u('/saved-jobs/$jobId'),
          headers: _jsonHeaders(bearer: access),
        );
      }
      if (res.statusCode >= 400) {
        throw ApiException(_errorBody(res), statusCode: res.statusCode);
      }
    });
  }

  /// إشعارات المستخدم من الباكند. `category`: all | job_posting_application | my_application_status | app_announcement
  Future<List<AppNotificationItem>> fetchNotifications({
    String category = 'all',
    int limit = 100,
  }) async {
    return _withNetwork(() async {
      var access = await TokenStorage.instance.accessToken();
      if (access == null || access.isEmpty) {
        throw ApiException('سجّل الدخول لعرض الإشعارات');
      }
      final q = <String, String>{'category': category, 'limit': '$limit'};
      var uri = _u('/notifications').replace(queryParameters: q);
      var res = await http.get(uri, headers: _jsonHeaders(bearer: access));
      if (res.statusCode == 401) {
        await _refreshOrThrow();
        access = await TokenStorage.instance.accessToken();
        if (access == null || access.isEmpty) {
          throw ApiException('انتهت الجلسة');
        }
        uri = _u('/notifications').replace(queryParameters: q);
        res = await http.get(uri, headers: _jsonHeaders(bearer: access));
      }
      if (res.statusCode >= 400) {
        throw ApiException(_errorBody(res), statusCode: res.statusCode);
      }
      final list = jsonDecode(utf8.decode(res.bodyBytes)) as List<dynamic>;
      return list
          .map(
            (e) => AppNotificationItem.fromApiJson(e as Map<String, dynamic>),
          )
          .toList();
    });
  }

  Future<AppNotificationItem> markNotificationRead(
    String notificationId,
  ) async {
    return _withNetwork(() async {
      var access = await TokenStorage.instance.accessToken();
      if (access == null || access.isEmpty) {
        throw ApiException('سجّل الدخول');
      }
      var res = await http.patch(
        _u('/notifications/$notificationId/read'),
        headers: _jsonHeaders(bearer: access),
      );
      if (res.statusCode == 401) {
        await _refreshOrThrow();
        access = await TokenStorage.instance.accessToken();
        if (access == null || access.isEmpty) {
          throw ApiException('انتهت الجلسة');
        }
        res = await http.patch(
          _u('/notifications/$notificationId/read'),
          headers: _jsonHeaders(bearer: access),
        );
      }
      if (res.statusCode >= 400) {
        throw ApiException(_errorBody(res), statusCode: res.statusCode);
      }
      final map =
          jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      return AppNotificationItem.fromApiJson(map);
    });
  }

  /// حفظ رمز FCM في الباكند (MongoDB) لإرسال الدفع لاحقاً.
  Future<void> registerFcmToken(String fcmToken) async {
    return _withNetwork(() async {
      var access = await TokenStorage.instance.accessToken();
      if (access == null || access.isEmpty) {
        throw ApiException('غير مسجل الدخول');
      }
      var res = await http.patch(
        _u('/auth/me/fcm-token'),
        headers: _jsonHeaders(bearer: access),
        body: jsonEncode({'fcm_token': fcmToken}),
      );
      if (res.statusCode == 401) {
        await _refreshOrThrow();
        access = await TokenStorage.instance.accessToken();
        if (access == null || access.isEmpty) {
          throw ApiException('انتهت الجلسة');
        }
        res = await http.patch(
          _u('/auth/me/fcm-token'),
          headers: _jsonHeaders(bearer: access),
          body: jsonEncode({'fcm_token': fcmToken}),
        );
      }
      if (res.statusCode >= 400) {
        throw ApiException(_errorBody(res), statusCode: res.statusCode);
      }
    });
  }

  /// الأطباء المحفوظة للمستخدم الحالي (بيانات محدّثة من الباكند).
  Future<List<DoctorSearchItem>> fetchSavedDoctors() async {
    return _withNetwork(() async {
      var access = await TokenStorage.instance.accessToken();
      if (access == null || access.isEmpty) {
        throw ApiException('سجّل الدخول لعرض المحفوظات');
      }
      var res = await http.get(
        _u('/saved-doctors'),
        headers: _jsonHeaders(bearer: access),
      );
      if (res.statusCode == 401) {
        await _refreshOrThrow();
        access = await TokenStorage.instance.accessToken();
        if (access == null || access.isEmpty) {
          throw ApiException('انتهت الجلسة');
        }
        res = await http.get(
          _u('/saved-doctors'),
          headers: _jsonHeaders(bearer: access),
        );
      }
      if (res.statusCode >= 400) {
        throw ApiException(_errorBody(res), statusCode: res.statusCode);
      }
      final list = jsonDecode(utf8.decode(res.bodyBytes)) as List<dynamic>;
      return list
          .map(
            (e) => DoctorSearchItem.fromJson(e as Map<String, dynamic>),
          )
          .toList();
    });
  }

  Future<void> saveDoctor(String doctorUserId) async {
    return _withNetwork(() async {
      var access = await TokenStorage.instance.accessToken();
      if (access == null || access.isEmpty) {
        throw ApiException('سجّل الدخول للحفظ');
      }
      var res = await http.post(
        _u('/saved-doctors/$doctorUserId'),
        headers: _jsonHeaders(bearer: access),
      );
      if (res.statusCode == 401) {
        await _refreshOrThrow();
        access = await TokenStorage.instance.accessToken();
        if (access == null || access.isEmpty) {
          throw ApiException('انتهت الجلسة');
        }
        res = await http.post(
          _u('/saved-doctors/$doctorUserId'),
          headers: _jsonHeaders(bearer: access),
        );
      }
      if (res.statusCode >= 400) {
        throw ApiException(_errorBody(res), statusCode: res.statusCode);
      }
    });
  }

  Future<void> unsaveDoctor(String doctorUserId) async {
    return _withNetwork(() async {
      var access = await TokenStorage.instance.accessToken();
      if (access == null || access.isEmpty) {
        throw ApiException('سجّل الدخول لتعديل المحفوظات');
      }
      var res = await http.delete(
        _u('/saved-doctors/$doctorUserId'),
        headers: _jsonHeaders(bearer: access),
      );
      if (res.statusCode == 401) {
        await _refreshOrThrow();
        access = await TokenStorage.instance.accessToken();
        if (access == null || access.isEmpty) {
          throw ApiException('انتهت الجلسة');
        }
        res = await http.delete(
          _u('/saved-doctors/$doctorUserId'),
          headers: _jsonHeaders(bearer: access),
        );
      }
      if (res.statusCode >= 400) {
        throw ApiException(_errorBody(res), statusCode: res.statusCode);
      }
    });
  }

  Future<void> unsaveJob(String jobId) async {
    return _withNetwork(() async {
      var access = await TokenStorage.instance.accessToken();
      if (access == null || access.isEmpty) {
        throw ApiException('سجّل الدخول لتعديل المحفوظات');
      }
      var res = await http.delete(
        _u('/saved-jobs/$jobId'),
        headers: _jsonHeaders(bearer: access),
      );
      if (res.statusCode == 401) {
        await _refreshOrThrow();
        access = await TokenStorage.instance.accessToken();
        if (access == null || access.isEmpty) {
          throw ApiException('انتهت الجلسة');
        }
        res = await http.delete(
          _u('/saved-jobs/$jobId'),
          headers: _jsonHeaders(bearer: access),
        );
      }
      if (res.statusCode >= 400) {
        throw ApiException(_errorBody(res), statusCode: res.statusCode);
      }
    });
  }
}
