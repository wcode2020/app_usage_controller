import 'dart:async';
import '../models/monitored_app.dart';
import '../models/app_goal.dart';
import '../models/usage_session.dart';
import 'app_usage_service.dart';
import 'notification_service.dart';
import 'overlay_service.dart';
import 'storage_service.dart';

class AppControllerService {
  static final AppControllerService _instance = AppControllerService._internal();
  factory AppControllerService() => _instance;
  AppControllerService._internal();

  final AppUsageService _usageService = AppUsageService();
  final NotificationService _notificationService = NotificationService();
  final OverlayService _overlayService = OverlayService();
  final StorageService _storageService = StorageService();

  List<MonitoredApp> _monitoredApps = [];
  List<AppGoal> _availableGoals = [];
  UsageSession? _currentSession;
  Timer? _sessionTimer;
  StreamSubscription? _appLaunchSubscription;

  bool _isInitialized = false;
  bool _isMonitoring = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize all services
    await _notificationService.initialize();
    await _storageService.initialize();

    // Load saved data
    await _loadSettings();

    // Request permissions
    await _requestPermissions();

    _isInitialized = true;
  }

  Future<void> _requestPermissions() async {
    await _notificationService.requestPermissions();
    await _overlayService.requestOverlayPermission();
    await _usageService.requestPermissions();
  }

  Future<void> _loadSettings() async {
    _monitoredApps = await _storageService.getMonitoredApps();
    _availableGoals = await _storageService.getCustomGoals();

    // Add default goals if none exist
    if (_availableGoals.isEmpty) {
      _availableGoals = _getDefaultGoals();
      await _storageService.saveCustomGoals(_availableGoals);
    }
  }

  List<AppGoal> _getDefaultGoals() {
    return [
      AppGoal(
        id: 'quick_browse',
        name: 'تصفح سريع',
        durationMinutes: 10,
        description: 'تصفح سريع للمحتوى الجديد',
      ),
      AppGoal(
        id: 'post_content',
        name: 'نشر محتوى',
        durationMinutes: 5,
        description: 'نشر منشور أو قصة',
      ),
      AppGoal(
        id: 'search_specific',
        name: 'البحث عن شيء محدد',
        durationMinutes: 15,
        description: 'البحث عن معلومة أو شخص معين',
      ),
      AppGoal(
        id: 'social_interaction',
        name: 'التفاعل الاجتماعي',
        durationMinutes: 20,
        description: 'الرد على الرسائل والتعليقات',
      ),
    ];
  }

  Future<void> startMonitoring() async {
    if (_isMonitoring) return;

    _usageService.setMonitoredApps(_monitoredApps);
    _usageService.startMonitoring();

    // Listen to app launches
    _appLaunchSubscription = _usageService.appLaunchStream.listen((packageName) {
      _handleAppLaunch(packageName);
    });

    _isMonitoring = true;
  }

  Future<void> stopMonitoring() async {
    if (!_isMonitoring) return;

    _usageService.stopMonitoring();
    _appLaunchSubscription?.cancel();
    _sessionTimer?.cancel();

    _isMonitoring = false;
  }

  Future<void> _handleAppLaunch(String packageName) async {
    final app = _monitoredApps.firstWhere(
      (app) => app.packageName == packageName,
      orElse: () => MonitoredApp(packageName: '', appName: ''),
    );

    if (app.packageName.isEmpty || !app.isEnabled) return;

    // If there's an active session for a different app, end it
    if (_currentSession != null && _currentSession!.packageName != packageName) {
      await _endCurrentSession();
    }

    // If there's already an active session for this app, don't show overlay again
    if (_currentSession?.packageName == packageName && _currentSession!.isActive) {
      return;
    }

    // Show goal selection overlay
    await _showGoalSelection(app);
  }

  Future<void> _showGoalSelection(MonitoredApp app) async {
    try {
      await _overlayService.showGoalSelectionOverlay(
        app: app,
        availableGoals: _availableGoals,
      );

      // Listen for overlay response
      _overlayService.overlayListener.listen((data) {
        if (data['action'] == 'goal_selected') {
          final goalId = data['goal_id'];
          final duration = data['duration'];
          final goal = _availableGoals.firstWhere((g) => g.id == goalId);
          
          _startSession(app, goal, duration);
        }
      });
    } catch (e) {
      print('Error showing goal selection: $e');
      // Fallback: start with default goal
      final defaultGoal = _availableGoals.first;
      _startSession(app, defaultGoal, defaultGoal.durationMinutes);
    }
  }

  void _startSession(MonitoredApp app, AppGoal goal, int durationMinutes) {
    _currentSession = UsageSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      packageName: app.packageName,
      appName: app.appName,
      goalId: goal.id,
      goalName: goal.name,
      plannedDurationMinutes: durationMinutes,
      startTime: DateTime.now(),
      isActive: true,
    );

    _usageService.startSession(_currentSession!);
    _startSessionTimer();
    
    // Save session
    _storageService.saveUsageSession(_currentSession!);
  }

  void _startSessionTimer() {
    _sessionTimer?.cancel();
    
    _sessionTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (_currentSession == null || !_currentSession!.isActive) {
        timer.cancel();
        return;
      }

      final remainingMinutes = _currentSession!.remainingMinutes;
      
      if (remainingMinutes <= 0) {
        // Time's up
        _handleTimeUp();
      } else if (remainingMinutes == 5) {
        // 5 minutes warning
        _notificationService.showWarningNotification(
          appName: _currentSession!.appName,
          remainingMinutes: remainingMinutes,
        );
      } else if (remainingMinutes == 1) {
        // 1 minute warning
        _notificationService.showWarningNotification(
          appName: _currentSession!.appName,
          remainingMinutes: remainingMinutes,
        );
      }
    });
  }

  Future<void> _handleTimeUp() async {
    if (_currentSession == null) return;

    final overtimeMinutes = -_currentSession!.remainingMinutes;
    
    // Show notifications
    await _notificationService.showTimeUpNotification(
      appName: _currentSession!.appName,
      plannedMinutes: _currentSession!.plannedDurationMinutes,
      actualMinutes: _currentSession!.actualDurationMinutes,
    );

    if (overtimeMinutes > 0) {
      await _notificationService.showOvertimeNotification(
        appName: _currentSession!.appName,
        overtimeMinutes: overtimeMinutes,
      );
    }

    // Show overlay warning
    await _overlayService.showTimeUpOverlay(
      appName: _currentSession!.appName,
      overtimeMinutes: overtimeMinutes,
    );
  }

  Future<void> _endCurrentSession() async {
    if (_currentSession == null) return;

    _currentSession = _currentSession!.copyWith(
      endTime: DateTime.now(),
      isActive: false,
      wasCompleted: _currentSession!.remainingMinutes >= 0,
    );

    _usageService.endCurrentSession();
    _sessionTimer?.cancel();
    
    // Save final session
    await _storageService.saveUsageSession(_currentSession!);
    
    _currentSession = null;
  }

  // Public methods for UI
  List<MonitoredApp> get monitoredApps => _monitoredApps;
  List<AppGoal> get availableGoals => _availableGoals;
  UsageSession? get currentSession => _currentSession;
  bool get isMonitoring => _isMonitoring;

  Future<void> updateMonitoredApps(List<MonitoredApp> apps) async {
    _monitoredApps = apps;
    await _storageService.saveMonitoredApps(apps);
    _usageService.setMonitoredApps(apps);
  }

  Future<void> updateCustomGoals(List<AppGoal> goals) async {
    _availableGoals = goals;
    await _storageService.saveCustomGoals(goals);
  }

  Future<void> addCustomGoal(AppGoal goal) async {
    _availableGoals.add(goal);
    await updateCustomGoals(_availableGoals);
  }

  Future<void> removeCustomGoal(String goalId) async {
    _availableGoals.removeWhere((goal) => goal.id == goalId);
    await updateCustomGoals(_availableGoals);
  }

  Future<List<UsageSession>> getUsageHistory({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return await _storageService.getUsageSessions(
      startDate: startDate,
      endDate: endDate,
    );
  }

  void dispose() {
    stopMonitoring();
    _overlayService.dispose();
    _usageService.dispose();
  }
}

