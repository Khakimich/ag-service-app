import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart'; // AG_CLIENTLOG1

class ApiException implements Exception {
  ApiException(this.statusCode, this.message);
  final int statusCode;
  final String message;
  @override
  String toString() => 'ApiException($statusCode): $message';
}

class ApiClient {
  ApiClient({String? baseUrl})
    : baseUrl =
          baseUrl ??
          const String.fromEnvironment(
            'API_BASE_URL',
            defaultValue: 'https://api.autogrom-group.com',
          );

  final String baseUrl;

  // AG_CLIENTLOG1: версия приложения и платформа — для «Журнала клиентов» в AG Service
  static final Map<String, String> agInfo = _agStart();
  static Map<String, String> _agStart() {
    final m = <String, String>{'x-app-platform': kIsWeb ? 'web' : defaultTargetPlatform.name};
    PackageInfo.fromPlatform().then((p) {
      m['x-app-version'] = p.version;
      m['x-app-build'] = p.buildNumber;
    }).catchError((Object _) {});
    return m;
  }
  String? _token;

  void setToken(String token) => _token = token;
  void clearToken() => _token = null;
  bool get hasToken => _token != null;

  /// AG_FIX5 — сервер сказал «аккаунт удалён / заблокирован / вход устарел».
  void Function(int status, String message)? onAuthError;

  void _agAuth(int status, dynamic body, String message) {
    if (_token == null) return;
    final code = body is Map ? body['code'] : null;
    if (status == 401 || (status == 403 && (code == 'account_blocked' || code == 'account_deleted'))) {
      final cb = onAuthError;
      if (cb != null) cb(status, message);
    }
  }

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final base = Uri.parse('$baseUrl$path');
    if (query == null || query.isEmpty) return base;
    return base.replace(
      queryParameters: query.map((k, v) => MapEntry(k, v.toString())),
    );
  }

  Map<String, String> get _headers => {
    'content-type': 'application/json',
    ...agInfo,
    if (_token != null) 'authorization': 'Bearer $_token',
  };

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) async {
    final res = await http.get(_uri(path, query), headers: _headers);
    return _handle(res);
  }

  Future<dynamic> patch(String path, Map<String, dynamic> body) async {
    final res = await http.patch(
      _uri(path),
      headers: _headers,
      body: jsonEncode(body),
    );
    return _handle(res);
  }

  Future<dynamic> delete(String path) async {
    final res = await http.delete(_uri(path), headers: _headers);
    final body = res.body.isEmpty ? null : jsonDecode(res.body);
    if (res.statusCode >= 200 && res.statusCode < 300) return body;
    final message =
        body is Map && body['error'] is String
            ? body['error'] as String
            : 'Request failed (${res.statusCode})';
    _agAuth(res.statusCode, body, message); // AG_FIX5
    throw ApiException(res.statusCode, message);
  }

  Future<dynamic> post(String path, Map<String, dynamic> body) async {
    final uri = _uri(path);

    debugPrint('========== API POST ==========');
    debugPrint('BASE URL: $baseUrl');
    debugPrint('PATH: $path');
    debugPrint('FULL URL: $uri');
    debugPrint('==============================');

    final res = await http.post(uri, headers: _headers, body: jsonEncode(body));
    return _handle(res);
  }

  dynamic _handle(http.Response res) {
    final body = res.body.isEmpty ? null : jsonDecode(res.body);
    if (res.statusCode >= 200 && res.statusCode < 300) return body;
    final message =
        body is Map && body['error'] is String
            ? body['error'] as String
            : 'Request failed';
    _agAuth(res.statusCode, body, message); // AG_FIX5
    throw ApiException(res.statusCode, message);
  }
}
