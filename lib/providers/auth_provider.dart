import 'package:flutter/foundation.dart';

import '../services/api_client.dart';

class AuthProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient.instance;

  String? _token;
  String? _userId;
  String? _email;
  String? _username;
  bool _initialized = false;

  bool get isAuthenticated => _token != null && _token!.isNotEmpty;
  bool get initialized => _initialized;
  String get uid => _userId ?? '';
  String get email => _email ?? '';
  String get username => _username ?? '';

  AuthProvider() {
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    _token = await _api.token;
    if (_token != null && _token!.isNotEmpty) {
      try {
        final profile = await _api.get('/auth/me/');
        _userId = profile['id']?.toString();
        _email = profile['email']?.toString();
        _username = profile['username']?.toString();
      } catch (_) {
        await _api.clearToken();
        _token = null;
      }
    }
    _initialized = true;
    notifyListeners();
  }

  Future<void> signup(String username, String email, String password) async {
    final result = await _api.post('/auth/register/', authenticated: false, body: {
      'username': username.trim(),
      'email': email.trim(),
      'password': password,
    });
    await _acceptAuthResult(result);
  }

  Future<void> login(String username, String password) async {
    final result = await _api.post('/auth/login/', authenticated: false, body: {
      'username': username.trim(),
      'password': password,
    });
    await _acceptAuthResult(result);
  }

  Future<void> _acceptAuthResult(Map<String, dynamic> result) async {
    final value = result['token']?.toString();
    if (value == null || value.isEmpty) {
      throw ApiException('The API response did not include an authentication token.');
    }
    _token = value;
    final user = result['user'];
    _userId = result['id']?.toString() ?? (user is Map ? user['id']?.toString() : null);
    _email = result['email']?.toString() ?? (user is Map ? user['email']?.toString() : null);
    _username = result['username']?.toString() ?? (user is Map ? user['username']?.toString() : null);
    await _api.saveToken(value);
    notifyListeners();
  }

  Future<void> logout() async {
    try {
      await _api.post('/auth/logout/');
    } finally {
      await _api.clearToken();
      _token = null;
      _userId = null;
      _email = null;
      _username = null;
      notifyListeners();
    }
  }

  Future<void> tryAutoLogin() => _restoreSession();
}
