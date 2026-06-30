import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service de persistance des paramètres utilisateur (durées Pomodoro,
/// préférences de notifications, etc.) via shared_preferences.
/// Sur le web, utilise des valeurs en mémoire si shared_preferences échoue.
class SettingsService extends ChangeNotifier {
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  static const String _keyFocusDuration = 'focus_duration_minutes';
  static const String _keyShortBreakDuration = 'short_break_duration_minutes';
  static const String _keyLongBreakDuration = 'long_break_duration_minutes';
  static const String _keyNotificationsEnabled = 'notifications_enabled';

  // Default values (also used as in-memory fallback)
  int _focusDuration = 25;
  int _shortBreakDuration = 5;
  int _longBreakDuration = 15;
  bool _notificationsEnabled = true;

  bool _loaded = false;

  // ─── Getters ──────────────────────────────────────────────────────────────

  int get focusDuration => _focusDuration;
  int get shortBreakDuration => _shortBreakDuration;
  int get longBreakDuration => _longBreakDuration;
  bool get notificationsEnabled => _notificationsEnabled;

  // ─── Load ─────────────────────────────────────────────────────────────────

  Future<void> load() async {
    if (_loaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      _focusDuration = prefs.getInt(_keyFocusDuration) ?? 25;
      _shortBreakDuration = prefs.getInt(_keyShortBreakDuration) ?? 5;
      _longBreakDuration = prefs.getInt(_keyLongBreakDuration) ?? 15;
      _notificationsEnabled = prefs.getBool(_keyNotificationsEnabled) ?? true;
    } catch (e) {
      // Sur certaines plateformes (web en dev), shared_preferences peut être
      // indisponible → on garde les valeurs par défaut en mémoire.
      debugPrint('[SettingsService] shared_preferences non disponible: $e');
    }
    _loaded = true;
    notifyListeners();
  }

  // ─── Helpers d'accès à SharedPreferences (silencieux sur web) ─────────────

  Future<SharedPreferences?> _getPrefs() async {
    try {
      return await SharedPreferences.getInstance();
    } catch (_) {
      return null;
    }
  }

  // ─── Setters ──────────────────────────────────────────────────────────────

  Future<void> setFocusDuration(int minutes) async {
    _focusDuration = minutes;
    notifyListeners();
    final prefs = await _getPrefs();
    await prefs?.setInt(_keyFocusDuration, minutes);
  }

  Future<void> setShortBreakDuration(int minutes) async {
    _shortBreakDuration = minutes;
    notifyListeners();
    final prefs = await _getPrefs();
    await prefs?.setInt(_keyShortBreakDuration, minutes);
  }

  Future<void> setLongBreakDuration(int minutes) async {
    _longBreakDuration = minutes;
    notifyListeners();
    final prefs = await _getPrefs();
    await prefs?.setInt(_keyLongBreakDuration, minutes);
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    _notificationsEnabled = enabled;
    notifyListeners();
    final prefs = await _getPrefs();
    await prefs?.setBool(_keyNotificationsEnabled, enabled);
  }

  Future<void> resetToDefaults() async {
    _focusDuration = 25;
    _shortBreakDuration = 5;
    _longBreakDuration = 15;
    _notificationsEnabled = true;
    _loaded = false;
    notifyListeners();
    final prefs = await _getPrefs();
    await prefs?.remove(_keyFocusDuration);
    await prefs?.remove(_keyShortBreakDuration);
    await prefs?.remove(_keyLongBreakDuration);
    await prefs?.remove(_keyNotificationsEnabled);
  }
}
