import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/constants.dart';
import '../../auth/data/auth_repository.dart';
import '../domain/session_model.dart';

class SessionRepository {
  final List<SessionModel> _localOfflineSessions = [];
  List<SessionModel> _cachedServerSessions = [];

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (AuthRepository.token != null)
          'Authorization': 'Bearer ${AuthRepository.token}',
      };

  Future<List<SessionModel>> getSessions() async {
    if (AuthRepository.token == null) {
      // Offline/Guest mode: Return locally accumulated sessions
      return List.from(_localOfflineSessions);
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
      }
    } catch (_) {
      // Fallback on request failure
    }

    // Merge server-synced sessions with local ones that are not yet synced
    return [..._localOfflineSessions, ..._cachedServerSessions];
  }

  Future<SessionModel> logSession(String? taskId, String type, int durationMinutes) async {
    final newSession = SessionModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      taskId: taskId,
      type: type,
      durationMinutes: durationMinutes,
      timestamp: DateTime.now(),
    );

    if (AuthRepository.token == null) {
      // Guest mode: Save locally in memory
      _localOfflineSessions.add(newSession);
      return newSession;
    }

    // Authenticated mode: Save locally and push immediately to sync
    _localOfflineSessions.add(newSession);
    await syncOfflineSessions();
    return newSession;
  }

  Future<void> syncOfflineSessions() async {
    if (AuthRepository.token == null || _localOfflineSessions.isEmpty) return;

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
        // Refresh local cache from the server
        await getSessions();
      }
    } catch (_) {
      // Keep local sessions for next sync attempt if network fails
    }
  }
}
