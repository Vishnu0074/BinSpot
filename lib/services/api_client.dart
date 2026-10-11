import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Base URL can be overridden at build time:
/// flutter run --dart-define=API_BASE_URL=https://your-api.example.com/api
class ApiClient {
  ApiClient._();

  static final ApiClient instance = ApiClient._();

  static const _defaultBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://binspot-api.onrender.com/api',
  );
  static const _tokenKey = 'binspot_api_token';

  String get baseUrl => _defaultBaseUrl.replaceAll(RegExp(r'/+$'), '');
  final http.Client _client = http.Client();

  Future<String?> get token async =>
      (await SharedPreferences.getInstance()).getString(_tokenKey);

  Future<void> saveToken(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, value);
  }

  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  Future<Map<String, dynamic>> get(String path, {bool authenticated = true}) =>
      _request('GET', path, authenticated: authenticated);

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = true,
  }) =>
      _request('POST', path, body: body, authenticated: authenticated);

  Future<Map<String, dynamic>> patch(
    String path, {
    Map<String, dynamic>? body,
  }) =>
      _request('PATCH', path, body: body);

  Future<void> delete(String path) async {
    final uri = Uri.parse('$baseUrl$path');
    final headers = await _headers();
    final response = await _client.delete(uri, headers: headers);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(_message(response.body, response.statusCode));
    }
  }

  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = true,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final headers = await _headers(authenticated: authenticated);
    late http.Response response;
    switch (method) {
      case 'GET':
        response = await _client.get(uri, headers: headers);
        break;
      case 'POST':
        response = await _client.post(uri, headers: headers, body: jsonEncode(body ?? {}));
        break;
      case 'PATCH':
        response = await _client.patch(uri, headers: headers, body: jsonEncode(body ?? {}));
        break;
      default:
        throw UnsupportedError('HTTP method $method is not supported');
    }
    final decoded = _decode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(_message(response.body, response.statusCode));
    }
    return decoded;
  }

  Future<Map<String, String>> _headers({bool authenticated = true}) async {
    final headers = <String, String>{'Accept': 'application/json'};
    headers['Content-Type'] = 'application/json';
    if (authenticated) {
      final value = await token;
      if (value != null && value.isNotEmpty) {
        headers['Authorization'] = 'Token $value';
      }
    }
    return headers;
  }

  Map<String, dynamic> _decode(String body) {
    if (body.trim().isEmpty) return <String, dynamic>{};
    final value = jsonDecode(body);
    if (value is Map<String, dynamic>) return value;
    if (value is List) return <String, dynamic>{'results': value};
    return <String, dynamic>{'data': value};
  }

  String _message(String body, int status) {
    try {
      final value = jsonDecode(body);
      if (value is Map) {
        final detail = value['detail'] ?? value['non_field_errors'] ?? value['error'];
        if (detail != null) return detail is List ? detail.join(', ') : detail.toString();
        return value.entries.map((e) => '${e.key}: ${e.value}').join('\n');
      }
    } catch (_) {}
    return 'Request failed (HTTP $status). Check the API URL and try again.';
  }
}

class ApiException implements Exception {
  ApiException(this.message);
  final String message;

  @override
  String toString() => message;
}
