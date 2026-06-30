import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/constants.dart';
import '../../auth/data/auth_repository.dart';
import '../domain/task_model.dart';

class TaskRepository {
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (AuthRepository.token != null)
      'Authorization': 'Bearer ${AuthRepository.token}',
  };

  Future<List<TaskModel>> getTasks() async {
    final url = Uri.parse('${AppConfig.baseUrl}/tasks');
    final response = await http.get(url, headers: _headers);

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch tasks');
    }

    final List<dynamic> jsonList = jsonDecode(response.body);
    return jsonList.map((json) {
      final done = json['done'] as bool? ?? false;
      final estimated = json['estimated'] as int? ?? 1;

      return TaskModel(
        id: json['id'] as String,
        title: json['title'] as String,
        description: '',
        isCompleted: done,
        estimatedPomodoros: estimated,
        // Mock completed pomodoros as estimated if task is done, or 0
        completedPomodoros: done ? estimated : 0,
      );
    }).toList();
  }

  Future<TaskModel> addTask(
    String title,
    String description,
    int estimatedPomodoros,
  ) async {
    final url = Uri.parse('${AppConfig.baseUrl}/tasks');
    final response = await http.post(
      url,
      headers: _headers,
      body: jsonEncode({
        'title': title,
        'description': description,
        'estimated': estimatedPomodoros,
      }),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw Exception(body['message'] ?? 'Failed to create task');
    }

    final json = jsonDecode(response.body);
    final done = json['done'] as bool? ?? false;
    final estimated = json['estimated'] as int? ?? 1;

    return TaskModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: description,
      isCompleted: done,
      estimatedPomodoros: estimated,
      completedPomodoros: 0,
    );
  }

  Future<TaskModel> updateTask(TaskModel updatedTask) async {
    final url = Uri.parse('${AppConfig.baseUrl}/tasks/${updatedTask.id}');
    final response = await http.patch(
      url,
      headers: _headers,
      body: jsonEncode({
        'title': updatedTask.title,
        'estimated': updatedTask.estimatedPomodoros,
        'done': updatedTask.isCompleted,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update task');
    }

    final json = jsonDecode(response.body);
    final done = json['done'] as bool? ?? false;
    final estimated = json['estimated'] as int? ?? 1;

    return TaskModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: updatedTask.description,
      isCompleted: done,
      estimatedPomodoros: estimated,
      completedPomodoros: updatedTask.completedPomodoros,
    );
  }

  Future<void> deleteTask(String id) async {
    final url = Uri.parse('${AppConfig.baseUrl}/tasks/$id');
    final response = await http.delete(url, headers: _headers);

    if (response.statusCode != 200) {
      throw Exception('Failed to delete task');
    }
  }
}
