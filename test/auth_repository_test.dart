import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pomo_front/auth/data/auth_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel(
    'plugins.flutter.io/shared_preferences',
  ).setMockMethodCallHandler((MethodCall methodCall) async {
    if (methodCall.method == 'getAll') {
      return <String, Object>{};
    }
    if (methodCall.method == 'setBool') {
      return true;
    }
    if (methodCall.method == 'setInt') {
      return true;
    }
    if (methodCall.method == 'setDouble') {
      return true;
    }
    if (methodCall.method == 'setString') {
      return true;
    }
    if (methodCall.method == 'setStringList') {
      return true;
    }
    if (methodCall.method == 'remove') {
      return true;
    }
    if (methodCall.method == 'clear') {
      return true;
    }
    return null;
  });

  group('AuthRepository', () {
    test('accepts 201 Created for login responses', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, equals('POST'));
        expect(request.url.path, equals('/auth/login'));

        return http.Response(
          jsonEncode({
            'access_token':
                'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJ1c2VyLTEiLCJlbWFpbCI6ImFkbWluQGV4YW1wbGUuY29tIn0.signature',
          }),
          201,
          headers: {'Content-Type': 'application/json'},
        );
      });

      final repository = AuthRepository(client: mockClient);
      final user = await repository.login('admin@example.com', 'password123');

      expect(user.email, 'admin@example.com');
      expect(repository.tokenValue, isNotNull);
      expect(repository.currentUser, isNotNull);
    });

    test('restores a persisted session on startup', () async {
      SharedPreferences.setMockInitialValues({
        'auth_token': 'persisted-token',
        'auth_user_id': 'user-1',
        'auth_user_email': 'admin@example.com',
        'auth_user_name': 'Admin',
      });

      final repository = AuthRepository();
      await repository.restoreSession();

      expect(repository.currentUser, isNotNull);
      expect(repository.currentUser!.email, 'admin@example.com');
      expect(repository.tokenValue, 'persisted-token');
    });
  });
}
