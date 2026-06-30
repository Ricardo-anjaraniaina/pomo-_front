import 'dart:async';
import 'package:flutter/material.dart';
import '../data/session_repository.dart';
import '../../tasks/presentation/tasks_state.dart';
import '../../core/notification_service.dart';
import '../../core/settings_service.dart';

enum PomodoroMode { focus, shortBreak, longBreak }

class TimerProvider extends ChangeNotifier {
  final SessionRepository _sessionRepository;
  final NotificationService _notificationService;
  final SettingsService _settingsService;
  TasksProvider? _tasksProvider;

  PomodoroMode _mode = PomodoroMode.focus;
  bool _isRunning = false;
  Duration _durationRemaining = const Duration(minutes: 25);
  Duration _totalDuration = const Duration(minutes: 25);
  int _completedFocusCycles = 0;
  Timer? _ticker;

  TimerProvider({
    required SessionRepository sessionRepository,
    required NotificationService notificationService,
    required SettingsService settingsService,
    TasksProvider? tasksProvider,
  })  : _sessionRepository = sessionRepository,
        _notificationService = notificationService,
        _settingsService = settingsService,
        _tasksProvider = tasksProvider {
    // Apply loaded settings immediately
    _setDurationForMode(_mode);
  }

  // Update tasks provider reference when updated in MultiProvider
  void updateTasksProvider(TasksProvider tasksProvider) {
    _tasksProvider = tasksProvider;
  }

  /// Called when SettingsService values change so the timer adapts live
  /// (only when not currently running to avoid mid-session glitches).
  void onSettingsChanged() {
    if (!_isRunning) {
      _setDurationForMode(_mode);
      notifyListeners();
    }
  }

  PomodoroMode get mode => _mode;
  bool get isRunning => _isRunning;
  Duration get durationRemaining => _durationRemaining;
  Duration get totalDuration => _totalDuration;
  int get completedFocusCycles => _completedFocusCycles;

  double get progress {
    if (_totalDuration.inSeconds == 0) return 0.0;
    return (_totalDuration.inSeconds - _durationRemaining.inSeconds) /
        _totalDuration.inSeconds;
  }

  String get modeName {
    switch (_mode) {
      case PomodoroMode.focus:
        return 'Focus';
      case PomodoroMode.shortBreak:
        return 'Short Break';
      case PomodoroMode.longBreak:
        return 'Long Break';
    }
  }

  Color get modeColor {
    switch (_mode) {
      case PomodoroMode.focus:
        return const Color(0xFFEF4444); // Red 500
      case PomodoroMode.shortBreak:
      case PomodoroMode.longBreak:
        return const Color(0xFF38BDF8); // Sky 400
    }
  }

  void start() {
    if (_isRunning) return;
    _isRunning = true;
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) => _tick());
    notifyListeners();
  }

  void pause() {
    if (!_isRunning) return;
    _isRunning = false;
    _ticker?.cancel();
    notifyListeners();
  }

  void reset() {
    pause();
    _setDurationForMode(_mode);
    notifyListeners();
  }

  void skip() {
    pause();
    _handleSessionComplete(skipped: true);
  }

  void selectMode(PomodoroMode newMode) {
    pause();
    _mode = newMode;
    _setDurationForMode(newMode);
    notifyListeners();
  }

  void _tick() {
    if (_durationRemaining.inSeconds > 0) {
      _durationRemaining = _durationRemaining - const Duration(seconds: 1);
      notifyListeners();
    } else {
      pause();
      _handleSessionComplete(skipped: false);
    }
  }

  Future<void> _handleSessionComplete({required bool skipped}) async {
    final activeTask = _tasksProvider?.selectedTask;
    final completedModeName = modeName;

    if (!skipped) {
      // 1. Log the completed session to repository
      String typeString = '';
      if (_mode == PomodoroMode.focus) {
        typeString = 'focus';
      } else if (_mode == PomodoroMode.shortBreak) {
        typeString = 'short_break';
      } else {
        typeString = 'long_break';
      }

      await _sessionRepository.logSession(
        activeTask?.id,
        typeString,
        _totalDuration.inMinutes,
      );

      // 2. If it was focus, increment task pomodoros
      if (_mode == PomodoroMode.focus) {
        _completedFocusCycles++;
        if (activeTask != null) {
          await _tasksProvider?.incrementCompletedPomodoros(activeTask.id);
        }
      }
    }

    // 3. Switch modes automatically
    if (_mode == PomodoroMode.focus) {
      // After 4 focus sessions, take a long break. Otherwise, take a short break.
      if (_completedFocusCycles > 0 && _completedFocusCycles % 4 == 0) {
        _mode = PomodoroMode.longBreak;
      } else {
        _mode = PomodoroMode.shortBreak;
      }
    } else {
      _mode = PomodoroMode.focus;
    }

    _setDurationForMode(_mode);
    notifyListeners();

    // 4. Send native notification if not skipped and notifications enabled
    if (!skipped && _settingsService.notificationsEnabled) {
      await _notificationService.showTimerCompleteNotification(
        modeName: completedModeName,
        nextMode: modeName,
      );
    }
  }

  void _setDurationForMode(PomodoroMode mode) {
    switch (mode) {
      case PomodoroMode.focus:
        _durationRemaining =
            Duration(minutes: _settingsService.focusDuration);
        break;
      case PomodoroMode.shortBreak:
        _durationRemaining =
            Duration(minutes: _settingsService.shortBreakDuration);
        break;
      case PomodoroMode.longBreak:
        _durationRemaining =
            Duration(minutes: _settingsService.longBreakDuration);
        break;
    }
    _totalDuration = _durationRemaining;
  }

  // Debug helper to fast-forward countdown for demonstration
  void debugFastForward(Duration duration) {
    if (_durationRemaining > duration) {
      _durationRemaining = _durationRemaining - duration;
    } else {
      _durationRemaining = Duration.zero;
      _tick();
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
