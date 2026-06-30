import 'package:flutter/material.dart';
import '../data/task_repository.dart';
import '../domain/task_model.dart';

class TasksProvider extends ChangeNotifier {
  final TaskRepository _taskRepository;
  List<TaskModel> _tasks = [];
  bool _isLoading = false;
  String? _errorMessage;
  TaskModel? _selectedTask;

  bool _isAuthenticated = false;

  TasksProvider(this._taskRepository);

  List<TaskModel> get tasks => _tasks;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  TaskModel? get selectedTask => _selectedTask;

  void updateAuth(bool isAuthenticated) {
    if (_isAuthenticated != isAuthenticated) {
      _isAuthenticated = isAuthenticated;
      if (_isAuthenticated) {
        fetchTasks();
      } else {
        clearTasks();
      }
    }
  }

  void clearTasks() {
    _tasks = [];
    _selectedTask = null;
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> fetchTasks() async {
    if (!_isAuthenticated) {
      clearTasks();
      return;
    }
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _tasks = await _taskRepository.getTasks();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> addTask(
    String title,
    String description,
    int estimatedPomodoros,
  ) async {
    _errorMessage = null;
    notifyListeners();

    try {
      final newTask = await _taskRepository.addTask(
        title,
        description,
        estimatedPomodoros,
      );
      _tasks.add(newTask);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }

  Future<void> toggleTaskCompletion(String id) async {
    final index = _tasks.indexWhere((task) => task.id == id);
    if (index != -1) {
      final task = _tasks[index];
      final updatedTask = task.copyWith(isCompleted: !task.isCompleted);

      // Update local state first for fast response
      _tasks[index] = updatedTask;
      if (_selectedTask?.id == id) {
        _selectedTask = updatedTask;
      }
      notifyListeners();

      try {
        await _taskRepository.updateTask(updatedTask);
      } catch (e) {
        // Rollback on error
        _tasks[index] = task;
        if (_selectedTask?.id == id) {
          _selectedTask = task;
        }
        _errorMessage = e.toString();
        notifyListeners();
      }
    }
  }

  Future<void> incrementCompletedPomodoros(String id) async {
    final index = _tasks.indexWhere((task) => task.id == id);
    if (index != -1) {
      final task = _tasks[index];
      final updatedTask = task.copyWith(
        completedPomodoros: task.completedPomodoros + 1,
      );

      _tasks[index] = updatedTask;
      if (_selectedTask?.id == id) {
        _selectedTask = updatedTask;
      }
      notifyListeners();

      try {
        await _taskRepository.updateTask(updatedTask);
      } catch (e) {
        _tasks[index] = task;
        if (_selectedTask?.id == id) {
          _selectedTask = task;
        }
        notifyListeners();
      }
    }
  }

  void selectTask(TaskModel? task) {
    _selectedTask = task;
    notifyListeners();
  }

  Future<void> deleteTask(String id) async {
    final index = _tasks.indexWhere((task) => task.id == id);
    if (index != -1) {
      final removedTask = _tasks[index];
      _tasks.removeAt(index);
      if (_selectedTask?.id == id) {
        _selectedTask = null;
      }
      notifyListeners();

      try {
        await _taskRepository.deleteTask(id);
      } catch (e) {
        // Rollback
        _tasks.insert(index, removedTask);
        _errorMessage = e.toString();
        notifyListeners();
      }
    }
  }
}
