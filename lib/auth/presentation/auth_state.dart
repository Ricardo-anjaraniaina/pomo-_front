import 'package:flutter/material.dart';
import '../../timer/data/session_repository.dart';
import '../data/auth_repository.dart';
import '../domain/user_model.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository;
  final SessionRepository _sessionRepository;
  bool _isLoading = false;
  bool _isInitializing = true;
  String? _errorMessage;

  AuthProvider(this._authRepository, this._sessionRepository) {
    _restoreSession();
  }

  bool get isLoading => _isLoading;
  bool get isInitializing => _isInitializing;
  String? get errorMessage => _errorMessage;
  UserModel? get currentUser => _authRepository.currentUser;
  bool get isAuthenticated => currentUser != null;

  Future<void> _restoreSession() async {
    try {
      await _authRepository.restoreSession();
      if (isAuthenticated) {
        await _sessionRepository.syncOfflineSessions();
      }
    } finally {
      _isInitializing = false;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authRepository.login(email, password);
      // Sync any guest/offline sessions accumulated
      await _sessionRepository.syncOfflineSessions();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String name, String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authRepository.register(name, email, password);
      // Sync any guest/offline sessions accumulated
      await _sessionRepository.syncOfflineSessions();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _authRepository.logout();
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
