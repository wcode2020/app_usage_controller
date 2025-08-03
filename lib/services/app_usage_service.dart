import 'dart:async';
import 'package:app_usage/app_usage.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/monitored_app.dart';
import '../models/usage_session.dart';

class AppUsageService {
  static final AppUsageService _instance = AppUsageService._internal();
  factory AppUsageService() => _instance;
  AppUsageService._internal();

  StreamController<String>? _appLaunchController;
  Timer? _monitoringTimer;
  List<MonitoredApp> _monitoredApps = [];
  UsageSession? _currentSession;

  Stream<String> get appLaunchStream => _appLaunchController?.stream ?? const Stream.empty();

  Future<bool> requestPermissions() async {
    // Request usage access permission
    final usagePermission = await Permission.systemAlertWindow.request();
    
    // Note: For app usage stats, we need to guide user to settings
    // as it requires manual permission grant
    return usagePermission.isGranted;
  }

  Future<bool> hasUsagePermission() async {
    try {
      final endDate = DateTime.now();
      final startDate = endDate.subtract(const Duration(days: 1));
      
      // Try to get usage info to check if permission is granted
      await AppUsage().getAppUsage(startDate, endDate);
      return true;
    } catch (e) {
      return false;
    }
  }

  void setMonitoredApps(List<MonitoredApp> apps) {
    _monitoredApps = apps.where((app) => app.isEnabled).toList();
  }

  void startMonitoring() {
    if (_monitoringTimer != null) {
      stopMonitoring();
    }

    _appLaunchController = StreamController<String>.broadcast();
    
    // Start periodic monitoring
    _monitoringTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _checkCurrentApp();
    });
  }

  void stopMonitoring() {
    _monitoringTimer?.cancel();
    _monitoringTimer = null;
    _appLaunchController?.close();
    _appLaunchController = null;
  }

  Future<void> _checkCurrentApp() async {
    try {
      final endDate = DateTime.now();
      final startDate = endDate.subtract(const Duration(minutes: 1));
      
      final usageInfos = await AppUsage().getAppUsage(startDate, endDate);
      
      if (usageInfos.isNotEmpty) {
        // Get the most recently used app
        final recentApp = usageInfos.reduce((a, b) => 
          a.endDate.isAfter(b.endDate) ? a : b);
        
        // Check if it's a monitored app and recently opened
        final monitoredApp = _monitoredApps.firstWhere(
          (app) => app.packageName == recentApp.packageName,
          orElse: () => MonitoredApp(packageName: '', appName: ''),
        );
        
        if (monitoredApp.packageName.isNotEmpty) {
          final timeSinceLastUse = DateTime.now().difference(recentApp.endDate);
          
          // If app was used within last 10 seconds, consider it as newly opened
          if (timeSinceLastUse.inSeconds < 10) {
            _appLaunchController?.add(recentApp.packageName);
          }
        }
      }
    } catch (e) {
      print('Error checking current app: $e');
    }
  }

  Future<List<AppUsageInfo>> getUsageStats({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      return await AppUsage().getAppUsage(startDate, endDate);
    } catch (e) {
      print('Error getting usage stats: $e');
      return [];
    }
  }

  void startSession(UsageSession session) {
    _currentSession = session;
  }

  void endCurrentSession() {
    if (_currentSession != null) {
      _currentSession = _currentSession!.copyWith(
        endTime: DateTime.now(),
        isActive: false,
        wasCompleted: true,
      );
    }
  }

  UsageSession? getCurrentSession() {
    return _currentSession;
  }

  bool isSessionActive() {
    return _currentSession?.isActive ?? false;
  }

  int getRemainingMinutes() {
    if (_currentSession == null || !_currentSession!.isActive) {
      return 0;
    }
    return _currentSession!.remainingMinutes;
  }

  void dispose() {
    stopMonitoring();
  }
}

