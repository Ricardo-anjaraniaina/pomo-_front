import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants.dart';
import '../../auth/data/auth_repository.dart';
import '../domain/session_model.dart';

class SessionRepository {
  final List<SessionModel> _localOfflineSessions = [];
  List<SessionModel> _cachedServerSessions = [];
  bool _isInitialized = false;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (AuthRepository.token != null)
          'Authorization': 'Bearer ${AuthRepository.token}',
      };

  // Helper to ensure lists are loaded from local SharedPreferences once
  Future<void> _ensureInitialized() async {
    if (_isInitialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load offline sessions
      final offlineJson = prefs.getStringList('pomo_local_offline_sessions');
      if (offlineJson != null) {
        _localOfflineSessions.clear();
        for (final item in offlineJson) {
          try {
            _localOfflineSessions.add(SessionModel.fromJson(jsonDecode(item)));
          } catch (_) {}
        }
      }

      // Load cached server sessions
      final cachedJson = prefs.getStringList('pomo_cached_server_sessions');
      if (cachedJson != null) {
        _cachedServerSessions.clear();
        for (final item in cachedJson) {
          try {
            _cachedServerSessions.add(SessionModel.fromJson(jsonDecode(item)));
          } catch (_) {}
        }
      }
    } catch (_) {}
    _isInitialized = true;
  }

  // Save local offline sessions to SharedPreferences
  Future<void> _saveLocalSessions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final offlineJson = _localOfflineSessions
          .map((session) => jsonEncode(session.toJson()))
          .toList();
      await prefs.setStringList('pomo_local_offline_sessions', offlineJson);
    } catch (_) {}
  }

  // Save cached server sessions to SharedPreferences
  Future<void> _saveCachedServerSessions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = _cachedServerSessions
          .map((session) => jsonEncode(session.toJson()))
          .toList();
      await prefs.setStringList('pomo_cached_server_sessions', cachedJson);
    } catch (_) {}
  }

  // Expose the count of unsynced sessions
  Future<int> getUnsyncedCount() async {
    await _ensureInitialized();
    return _localOfflineSessions.length;
  }

  Future<List<SessionModel>> getSessions() async {
    await _ensureInitialized();

    if (AuthRepository.token == null) {
      // Offline/Guest mode: Return locally accumulated sessions
      return List.from(_localOfflineSessions);
    }

    // Auto-sync offline sessions first if we have internet and are logged in
    if (_localOfflineSessions.isNotEmpty) {
      await syncOfflineSessions();
    }

    try {
      final url = Uri.parse('${AppConfig.baseUrl}/sessions');
      final response = await http.get(url, headers: _headers);

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        _cachedServerSessions = jsonList.map((json) {
          return SessionModel(
            id: json['localId'] as String? ?? json['id'] as String,
            taskId: null,
            type: json['type'] as String,
            durationMinutes: json['duration'] as int? ?? 25,
            timestamp: DateTime.parse(json['completedAt'] as String),
          );
        }).toList();
        await _saveCachedServerSessions();
      }
    } catch (_) {
      // Fallback on request failure
    }

    // Merge server-synced sessions with local ones that are not yet synced
    return [..._localOfflineSessions, ..._cachedServerSessions];
  }

  Future<SessionModel> logSession(String? taskId, String type, int durationMinutes) async {
    await _ensureInitialized();

    final newSession = SessionModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      taskId: taskId,
      type: type,
      durationMinutes: durationMinutes,
      timestamp: DateTime.now(),
    );

    _localOfflineSessions.add(newSession);
    await _saveLocalSessions();

    if (AuthRepository.token == null) {
      // Guest mode: Save locally in memory
      return newSession;
    }

    // Authenticated mode: Save locally and push immediately to sync
    await syncOfflineSessions();
    return newSession;
  }

  Future<bool> syncOfflineSessions() async {
    await _ensureInitialized();
    if (AuthRepository.token == null) return false;
    if (_localOfflineSessions.isEmpty) return true;

    final url = Uri.parse('${AppConfig.baseUrl}/sessions/sync');
    final sessionsPayload = _localOfflineSessions.map((session) {
      return {
        'localId': session.id,
        'type': session.type,
        'duration': session.durationMinutes,
        'completedAt': session.timestamp.toIso8601String(),
      };
    }).toList();

    try {
      final response = await http.post(
        url,
        headers: _headers,
        body: jsonEncode({'sessions': sessionsPayload}),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        // Clear locally cached sessions once successfully synced to the backend
        _localOfflineSessions.clear();
        await _saveLocalSessions();
        return true;
      }
      return false;
    } catch (_) {
      return false; // Keep local sessions for next sync attempt if network fails
    }
  }
}
