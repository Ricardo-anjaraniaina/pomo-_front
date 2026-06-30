import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants.dart';
import '../domain/user_model.dart';

class AuthRepository {
  static String? token;
  final http.Client _client;
  UserModel? _currentUser;

  AuthRepository({http.Client? client}) : _client = client ?? http.Client();

  UserModel? get currentUser => _currentUser;
  String? get tokenValue => token;

  // Simple native helper to decode JWT payload without external libraries
  Map<String, dynamic> _decodeJwt(String tokenStr) {
    try {
      final parts = tokenStr.split('.');
      if (parts.length != 3) return {};
      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      return json.decode(decoded);
    } catch (_) {
      return {};
    }
  }

  Future<void> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final savedToken = prefs.getString('auth_token');
    final savedUserId = prefs.getString('auth_user_id');
    final savedUserEmail = prefs.getString('auth_user_email');
    final savedUserName = prefs.getString('auth_user_name');

    if (savedToken == null || savedToken.isEmpty) {
      _currentUser = null;
      token = null;
      return;
    }

    token = savedToken;
    _currentUser = UserModel(
      id: savedUserId ?? 'user_id',
      email: savedUserEmail ?? 'user@example.com',
      name:
          savedUserName ??
          (savedUserEmail?.split('@').first.toUpperCase() ?? 'USER'),
      token: savedToken,
    );
  }

  Future<UserModel> login(String email, String password) async {
    if (email.isEmpty || password.isEmpty) {
      throw Exception('Email and password cannot be empty');
    }

    final url = Uri.parse('${AppConfig.baseUrl}/auth/login');
    final response = await _client.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      try {
        final body = jsonDecode(response.body);
        throw Exception(body['message'] ?? 'Authentication failed');
      } catch (_) {
        throw Exception('Authentication failed');
      }
    }

    final body = response.body.trim();
    if (body.isEmpty) {
      throw Exception('Authentication failed');
    }

    final data = jsonDecode(body);
    final accessToken = data['access_token'] ?? data['token'];
    if (accessToken is! String || accessToken.isEmpty) {
      throw Exception('Authentication failed');
    }
    token = accessToken;

    final payload = _decodeJwt(accessToken);
    final userId = payload['sub'] as String? ?? 'user_id';
    final userEmail = payload['email'] as String? ?? email;

    _currentUser = UserModel(
      id: userId,
      email: userEmail,
      name: userEmail.split('@').first.toUpperCase(),
      token: accessToken,
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', accessToken);
    await prefs.setString('auth_user_id', userId);
    await prefs.setString('auth_user_email', userEmail);
    await prefs.setString('auth_user_name', _currentUser!.name);

    return _currentUser!;
  }

  Future<UserModel> register(String name, String email, String password) async {
    if (email.isEmpty || password.isEmpty) {
      throw Exception('All fields are required');
    }

    final url = Uri.parse('${AppConfig.baseUrl}/auth/register');
    final response = await _client.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      try {
        final body = jsonDecode(response.body);
        throw Exception(body['message'] ?? 'Registration failed');
      } catch (_) {
        throw Exception('Registration failed');
      }
    }

    final body = response.body.trim();
    if (body.isEmpty) {
      throw Exception('Registration failed');
    }

    final data = jsonDecode(body);
    final accessToken = data['access_token'] ?? data['token'];
    if (accessToken is! String || accessToken.isEmpty) {
      throw Exception('Registration failed');
    }
    token = accessToken;

    final payload = _decodeJwt(accessToken);
    final userId = payload['sub'] as String? ?? 'user_id';
    final userEmail = payload['email'] as String? ?? email;

    _currentUser = UserModel(
      id: userId,
      email: userEmail,
      name: userEmail.split('@').first.toUpperCase(),
      token: accessToken,
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', accessToken);
    await prefs.setString('auth_user_id', userId);
    await prefs.setString('auth_user_email', userEmail);
    await prefs.setString('auth_user_name', _currentUser!.name);

    return _currentUser!;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('auth_user_id');
    await prefs.remove('auth_user_email');
    await prefs.remove('auth_user_name');

    _currentUser = null;
    token = null;
  }
}
