class SessionModel {
  final String id;
  final String? taskId;
  final String type; // 'focus', 'short_break', 'long_break'
  final int durationMinutes;
  final DateTime timestamp;

  SessionModel({
    required this.id,
    this.taskId,
    required this.type,
    required this.durationMinutes,
    required this.timestamp,
  });

  factory SessionModel.fromJson(Map<String, dynamic> json) {
    return SessionModel(
      id: json['id'] as String,
      taskId: json['taskId'] as String?,
      type: json['type'] as String,
      durationMinutes: json['durationMinutes'] as int,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'taskId': taskId,
      'type': type,
      'durationMinutes': durationMinutes,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
