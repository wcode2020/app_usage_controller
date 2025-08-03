import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/monitored_app.dart';
import '../models/app_goal.dart';
import '../models/usage_session.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  SharedPreferences? _prefs;

  // Keys for storage
  static const String _monitoredAppsKey = 'monitored_apps';
  static const String _customGoalsKey = 'custom_goals';
  static const String _usageSessionsKey = 'usage_sessions';
  static const String _settingsKey = 'app_settings';

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Monitored Apps
  Future<void> saveMonitoredApps(List<MonitoredApp> apps) async {
    final jsonList = apps.map((app) => app.toJson()).toList();
    await _prefs?.setString(_monitoredAppsKey, jsonEncode(jsonList));
  }

  Future<List<MonitoredApp>> getMonitoredApps() async {
    final jsonString = _prefs?.getString(_monitoredAppsKey);
    if (jsonString == null) return [];

    try {
      final jsonList = jsonDecode(jsonString) as List;
      return jsonList.map((json) => MonitoredApp.fromJson(json)).toList();
    } catch (e) {
      print('Error loading monitored apps: $e');
      return [];
    }
  }

  // Custom Goals
  Future<void> saveCustomGoals(List<AppGoal> goals) async {
    final jsonList = goals.map((goal) => goal.toJson()).toList();
    await _prefs?.setString(_customGoalsKey, jsonEncode(jsonList));
  }

  Future<List<AppGoal>> getCustomGoals() async {
    final jsonString = _prefs?.getString(_customGoalsKey);
    if (jsonString == null) return [];

    try {
      final jsonList = jsonDecode(jsonString) as List;
      return jsonList.map((json) => AppGoal.fromJson(json)).toList();
    } catch (e) {
      print('Error loading custom goals: $e');
      return [];
    }
  }

  // Usage Sessions
  Future<void> saveUsageSession(UsageSession session) async {
    final sessions = await getUsageSessions();
    
    // Remove existing session with same ID if any
    sessions.removeWhere((s) => s.id == session.id);
    
    // Add the new/updated session
    sessions.add(session);
    
    // Keep only last 1000 sessions to prevent storage bloat
    if (sessions.length > 1000) {
      sessions.sort((a, b) => b.startTime.compareTo(a.startTime));
      sessions.removeRange(1000, sessions.length);
    }
    
    await _saveAllUsageSessions(sessions);
  }

  Future<void> _saveAllUsageSessions(List<UsageSession> sessions) async {
    final jsonList = sessions.map((session) => session.toJson()).toList();
    await _prefs?.setString(_usageSessionsKey, jsonEncode(jsonList));
  }

  Future<List<UsageSession>> getUsageSessions({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final jsonString = _prefs?.getString(_usageSessionsKey);
    if (jsonString == null) return [];

    try {
      final jsonList = jsonDecode(jsonString) as List;
      var sessions = jsonList.map((json) => UsageSession.fromJson(json)).toList();
      
      // Filter by date range if provided
      if (startDate != null) {
        sessions = sessions.where((s) => s.startTime.isAfter(startDate) || s.startTime.isAtSameMomentAs(startDate)).toList();
      }
      if (endDate != null) {
        sessions = sessions.where((s) => s.startTime.isBefore(endDate) || s.startTime.isAtSameMomentAs(endDate)).toList();
      }
      
      // Sort by start time (newest first)
      sessions.sort((a, b) => b.startTime.compareTo(a.startTime));
      
      return sessions;
    } catch (e) {
      print('Error loading usage sessions: $e');
      return [];
    }
  }

  Future<void> deleteUsageSession(String sessionId) async {
    final sessions = await getUsageSessions();
    sessions.removeWhere((s) => s.id == sessionId);
    await _saveAllUsageSessions(sessions);
  }

  Future<void> clearUsageHistory() async {
    await _prefs?.remove(_usageSessionsKey);
  }

  // App Settings
  Future<void> saveAppSettings(Map<String, dynamic> settings) async {
    await _prefs?.setString(_settingsKey, jsonEncode(settings));
  }

  Future<Map<String, dynamic>> getAppSettings() async {
    final jsonString = _prefs?.getString(_settingsKey);
    if (jsonString == null) return _getDefaultSettings();

    try {
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      print('Error loading app settings: $e');
      return _getDefaultSettings();
    }
  }

  Map<String, dynamic> _getDefaultSettings() {
    return {
      'notifications_enabled': true,
      'overlay_enabled': true,
      'monitoring_enabled': true,
      'warning_at_5_minutes': true,
      'warning_at_1_minute': true,
      'auto_start_monitoring': true,
      'theme_mode': 'system', // light, dark, system
      'language': 'ar',
    };
  }

  // Individual setting getters and setters
  Future<bool> isNotificationsEnabled() async {
    final settings = await getAppSettings();
    return settings['notifications_enabled'] ?? true;
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    final settings = await getAppSettings();
    settings['notifications_enabled'] = enabled;
    await saveAppSettings(settings);
  }

  Future<bool> isOverlayEnabled() async {
    final settings = await getAppSettings();
    return settings['overlay_enabled'] ?? true;
  }

  Future<void> setOverlayEnabled(bool enabled) async {
    final settings = await getAppSettings();
    settings['overlay_enabled'] = enabled;
    await saveAppSettings(settings);
  }

  Future<bool> isMonitoringEnabled() async {
    final settings = await getAppSettings();
    return settings['monitoring_enabled'] ?? true;
  }

  Future<void> setMonitoringEnabled(bool enabled) async {
    final settings = await getAppSettings();
    settings['monitoring_enabled'] = enabled;
    await saveAppSettings(settings);
  }

  // Statistics helpers
  Future<Map<String, dynamic>> getUsageStatistics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final sessions = await getUsageSessions(
      startDate: startDate,
      endDate: endDate,
    );

    if (sessions.isEmpty) {
      return {
        'total_sessions': 0,
        'total_time_minutes': 0,
        'average_session_minutes': 0,
        'completed_sessions': 0,
        'overtime_sessions': 0,
        'most_used_apps': <String, int>{},
        'most_used_goals': <String, int>{},
      };
    }

    final totalSessions = sessions.length;
    final totalTimeMinutes = sessions.fold<int>(0, (sum, session) => sum + session.actualDurationMinutes);
    final averageSessionMinutes = totalTimeMinutes / totalSessions;
    final completedSessions = sessions.where((s) => s.wasCompleted).length;
    final overtimeSessions = sessions.where((s) => s.isOvertime).length;

    // Most used apps
    final appUsage = <String, int>{};
    for (final session in sessions) {
      appUsage[session.appName] = (appUsage[session.appName] ?? 0) + session.actualDurationMinutes;
    }

    // Most used goals
    final goalUsage = <String, int>{};
    for (final session in sessions) {
      goalUsage[session.goalName] = (goalUsage[session.goalName] ?? 0) + 1;
    }

    return {
      'total_sessions': totalSessions,
      'total_time_minutes': totalTimeMinutes,
      'average_session_minutes': averageSessionMinutes.round(),
      'completed_sessions': completedSessions,
      'overtime_sessions': overtimeSessions,
      'most_used_apps': appUsage,
      'most_used_goals': goalUsage,
    };
  }

  // Clear all data
  Future<void> clearAllData() async {
    await _prefs?.clear();
  }

  // Export data
  Future<Map<String, dynamic>> exportData() async {
    return {
      'monitored_apps': await getMonitoredApps(),
      'custom_goals': await getCustomGoals(),
      'usage_sessions': await getUsageSessions(),
      'app_settings': await getAppSettings(),
      'export_date': DateTime.now().toIso8601String(),
    };
  }

  // Import data
  Future<bool> importData(Map<String, dynamic> data) async {
    try {
      if (data['monitored_apps'] != null) {
        final apps = (data['monitored_apps'] as List)
            .map((json) => MonitoredApp.fromJson(json))
            .toList();
        await saveMonitoredApps(apps);
      }

      if (data['custom_goals'] != null) {
        final goals = (data['custom_goals'] as List)
            .map((json) => AppGoal.fromJson(json))
            .toList();
        await saveCustomGoals(goals);
      }

      if (data['usage_sessions'] != null) {
        final sessions = (data['usage_sessions'] as List)
            .map((json) => UsageSession.fromJson(json))
            .toList();
        await _saveAllUsageSessions(sessions);
      }

      if (data['app_settings'] != null) {
        await saveAppSettings(data['app_settings']);
      }

      return true;
    } catch (e) {
      print('Error importing data: $e');
      return false;
    }
  }
}

