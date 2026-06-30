import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants.dart';
import '../domain/user_model.dart';

class AuthRepository {
  static String? token;
  UserModel? _currentUser;

  UserModel? get currentUser => _currentUser;

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

  Future<UserModel> login(String email, String password) async {
    if (email.isEmpty || password.isEmpty) {
      throw Exception('Email and password cannot be empty');
    }

    final url = Uri.parse('${AppConfig.baseUrl}/auth/login');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 210) {
      final body = jsonDecode(response.body);
      throw Exception(body['message'] ?? 'Authentication failed');
    }

    final data = jsonDecode(response.body);
    final accessToken = data['access_token'] as String;
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

    return _currentUser!;
  }

  Future<UserModel> register(String name, String email, String password) async {
    if (email.isEmpty || password.isEmpty) {
      throw Exception('All fields are required');
    }

    final url = Uri.parse('${AppConfig.baseUrl}/auth/register');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw Exception(body['message'] ?? 'Registration failed');
    }

    final data = jsonDecode(response.body);
    final accessToken = data['access_token'] as String;
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

    return _currentUser!;
  }

  Future<void> logout() async {
    _currentUser = null;
    token = null;
  }
}
