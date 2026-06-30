class TaskModel {
  final String id;
  final String title;
  final String description;
  final bool isCompleted;
  final int estimatedPomodoros;
  final int completedPomodoros;
  final bool isLocal; // true = offline-only, not synced to server

  TaskModel({
    required this.id,
    required this.title,
    required this.description,
    this.isCompleted = false,
    required this.estimatedPomodoros,
    this.completedPomodoros = 0,
    this.isLocal = false,
  });

  TaskModel copyWith({
    String? id,
    String? title,
    String? description,
    bool? isCompleted,
    int? estimatedPomodoros,
    int? completedPomodoros,
    bool? isLocal,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      estimatedPomodoros: estimatedPomodoros ?? this.estimatedPomodoros,
      completedPomodoros: completedPomodoros ?? this.completedPomodoros,
      isLocal: isLocal ?? this.isLocal,
    );
  }

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      isCompleted: json['isCompleted'] as bool? ?? false,
      estimatedPomodoros: json['estimatedPomodoros'] as int? ?? 1,
      completedPomodoros: json['completedPomodoros'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'isCompleted': isCompleted,
      'estimatedPomodoros': estimatedPomodoros,
      'completedPomodoros': completedPomodoros,
    };
  }
}
