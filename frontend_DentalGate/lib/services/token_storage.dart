import 'package:shared_preferences/shared_preferences.dart';

import 'package:dental_gate/models/auth_tokens.dart';

class TokenStorage {
  TokenStorage._();

  static final TokenStorage instance = TokenStorage._();

  static const _kAccess = 'dg_access_token';
  static const _kRefresh = 'dg_refresh_token';

  Future<void> saveTokens(AuthTokens tokens) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kAccess, tokens.accessToken);
    await p.setString(_kRefresh, tokens.refreshToken);
  }

  Future<AuthTokens?> readTokens() async {
    final p = await SharedPreferences.getInstance();
    final a = p.getString(_kAccess);
    final r = p.getString(_kRefresh);
    if (a == null || r == null || a.isEmpty || r.isEmpty) return null;
    return AuthTokens(accessToken: a, refreshToken: r);
  }

  Future<void> clear() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_kAccess);
    await p.remove(_kRefresh);
  }

  Future<String?> accessToken() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_kAccess);
  }
}
