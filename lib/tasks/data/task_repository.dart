import 'dart:async';
import '../domain/task_model.dart';

class TaskRepository {
  final List<TaskModel> _tasks = [
    TaskModel(
      id: '1',
      title: 'Design Dashboard UI',
      description: 'Create high-fidelity screens for the analytics tab.',
      estimatedPomodoros: 3,
      completedPomodoros: 2,
    ),
    TaskModel(
      id: '2',
      title: 'Integrate NestJS API',
      description: 'Connect login and task endpoints to NestJS backend.',
      estimatedPomodoros: 4,
      completedPomodoros: 0,
      isCompleted: false,
    ),
    TaskModel(
      id: '3',
      title: 'Write Unit Tests',
      description: 'Cover auth_repository and timer_state with tests.',
      estimatedPomodoros: 2,
      completedPomodoros: 2,
      isCompleted: true,
    ),
  ];

  Future<List<TaskModel>> getTasks() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.from(_tasks);
  }

  Future<TaskModel> addTask(String title, String description, int estimatedPomodoros) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final newTask = TaskModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      description: description,
      estimatedPomodoros: estimatedPomodoros,
      completedPomodoros: 0,
    );
    _tasks.add(newTask);
    return newTask;
  }

  Future<TaskModel> updateTask(TaskModel updatedTask) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final index = _tasks.indexWhere((task) => task.id == updatedTask.id);
    if (index != -1) {
      _tasks[index] = updatedTask;
      return updatedTask;
    }
    throw Exception('Task not found');
  }

  Future<void> deleteTask(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _tasks.removeWhere((task) => task.id == id);
  }
}
