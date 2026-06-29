import 'dart:async';
import '../domain/session_model.dart';

class SessionRepository {
  final List<SessionModel> _sessions = [
    SessionModel(
      id: 's1',
      taskId: '1',
      type: 'focus',
      durationMinutes: 25,
      timestamp: DateTime.now().subtract(const Duration(hours: 4)),
    ),
    SessionModel(
      id: 's2',
      taskId: '1',
      type: 'focus',
      durationMinutes: 25,
      timestamp: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    SessionModel(
      id: 's3',
      taskId: null,
      type: 'short_break',
      durationMinutes: 5,
      timestamp: DateTime.now().subtract(const Duration(hours: 2, minutes: 35)),
    ),
    SessionModel(
      id: 's4',
      taskId: '3',
      type: 'focus',
      durationMinutes: 25,
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    SessionModel(
      id: 's5',
      taskId: '3',
      type: 'focus',
      durationMinutes: 25,
      timestamp: DateTime.now().subtract(const Duration(hours: 1)),
    ),
  ];

  Future<List<SessionModel>> getSessions() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.from(_sessions);
  }

  Future<SessionModel> logSession(String? taskId, String type, int durationMinutes) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final newSession = SessionModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      taskId: taskId,
      type: type,
      durationMinutes: durationMinutes,
      timestamp: DateTime.now(),
    );
    _sessions.add(newSession);
    return newSession;
  }
}
