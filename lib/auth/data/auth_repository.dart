import 'dart:async';
import '../domain/user_model.dart';

class AuthRepository {
  UserModel? _currentUser;

  UserModel? get currentUser => _currentUser;

  Future<UserModel> login(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 800));
    
    if (email.isEmpty || password.isEmpty) {
      throw Exception('Email and password cannot be empty');
    }
    
    _currentUser = UserModel(
      id: 'mock_user_123',
      email: email,
      name: email.split('@').first.toUpperCase(),
      token: 'mock_jwt_token_xyz',
    );
    return _currentUser!;
  }

  Future<UserModel> register(String name, String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 1000));
    
    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      throw Exception('All fields are required');
    }
    
    _currentUser = UserModel(
      id: 'mock_user_123',
      email: email,
      name: name,
      token: 'mock_jwt_token_xyz',
    );
    return _currentUser!;
  }

  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 400));
    _currentUser = null;
  }
}
