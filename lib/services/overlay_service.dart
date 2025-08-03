import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/monitored_app.dart';
import '../models/app_goal.dart';

class OverlayService {
  static final OverlayService _instance = OverlayService._internal();
  factory OverlayService() => _instance;
  OverlayService._internal();

  bool _isOverlayActive = false;

  Future<bool> requestOverlayPermission() async {
    final permission = await Permission.systemAlertWindow.request();
    return permission.isGranted;
  }

  Future<bool> hasOverlayPermission() async {
    return await Permission.systemAlertWindow.isGranted;
  }

  Future<void> showGoalSelectionOverlay({
    required MonitoredApp app,
    required List<AppGoal> availableGoals,
  }) async {
    if (_isOverlayActive) {
      await hideOverlay();
    }

    try {
      final hasPermission = await hasOverlayPermission();
      if (!hasPermission) {
        throw Exception('Overlay permission not granted');
      }

      await FlutterOverlayWindow.showOverlay(
        enableDrag: false,
        overlayTitle: "Goal Selection",
        overlayContent: 'Selecting goal for ${app.appName}',
        flag: OverlayFlag.defaultFlag,
        visibility: NotificationVisibility.visibilityPublic,
        positionGravity: PositionGravity.auto,
        width: 350,
        height: 500,
      );

      _isOverlayActive = true;
    } catch (e) {
      print('Error showing overlay: $e');
      throw e;
    }
  }

  Future<void> showTimerOverlay({
    required String appName,
    required int remainingMinutes,
    required int totalMinutes,
  }) async {
    try {
      await FlutterOverlayWindow.showOverlay(
        enableDrag: true,
        overlayTitle: "Timer",
        overlayContent: '$remainingMinutes min left for $appName',
        flag: OverlayFlag.defaultFlag,
        visibility: NotificationVisibility.visibilityPublic,
        positionGravity: PositionGravity.auto,
        width: 200,
        height: 100,
      );

      _isOverlayActive = true;
    } catch (e) {
      print('Error showing timer overlay: $e');
    }
  }

  Future<void> showWarningOverlay({
    required String appName,
    required int remainingMinutes,
  }) async {
    try {
      await FlutterOverlayWindow.showOverlay(
        enableDrag: false,
        overlayTitle: "Warning",
        overlayContent: 'Only $remainingMinutes minutes left for $appName!',
        flag: OverlayFlag.defaultFlag,
        visibility: NotificationVisibility.visibilityPublic,
        positionGravity: PositionGravity.auto,
        width: 300,
        height: 150,
      );

      _isOverlayActive = true;

      // Auto-hide after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        hideOverlay();
      });
    } catch (e) {
      print('Error showing warning overlay: $e');
    }
  }

  Future<void> showTimeUpOverlay({
    required String appName,
    required int overtimeMinutes,
  }) async {
    try {
      await FlutterOverlayWindow.showOverlay(
        enableDrag: false,
        overlayTitle: "Time's Up!",
        overlayContent: 'Time limit exceeded for $appName by $overtimeMinutes minutes',
        flag: OverlayFlag.defaultFlag,
        visibility: NotificationVisibility.visibilityPublic,
        positionGravity: PositionGravity.auto,
        width: 350,
        height: 200,
      );

      _isOverlayActive = true;
    } catch (e) {
      print('Error showing time up overlay: $e');
    }
  }

  Future<void> hideOverlay() async {
    try {
      if (_isOverlayActive) {
        await FlutterOverlayWindow.closeOverlay();
        _isOverlayActive = false;
      }
    } catch (e) {
      print('Error hiding overlay: $e');
    }
  }

  bool get isOverlayActive => _isOverlayActive;

  // Listen to overlay events
  Stream<dynamic> get overlayListener => FlutterOverlayWindow.overlayListener;

  void dispose() {
    hideOverlay();
  }
}

// Overlay widget for goal selection
class GoalSelectionOverlayWidget extends StatefulWidget {
  final MonitoredApp app;
  final List<AppGoal> availableGoals;

  const GoalSelectionOverlayWidget({
    Key? key,
    required this.app,
    required this.availableGoals,
  }) : super(key: key);

  @override
  State<GoalSelectionOverlayWidget> createState() => _GoalSelectionOverlayWidgetState();
}

class _GoalSelectionOverlayWidgetState extends State<GoalSelectionOverlayWidget> {
  AppGoal? selectedGoal;
  int customDuration = 10;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'تحديد هدف الاستخدام',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.app.appName,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            
            // Goals list
            ...widget.availableGoals.map((goal) => 
              RadioListTile<AppGoal>(
                title: Text(goal.name),
                subtitle: Text('${goal.durationMinutes} دقيقة'),
                value: goal,
                groupValue: selectedGoal,
                onChanged: (value) {
                  setState(() {
                    selectedGoal = value;
                    customDuration = goal.durationMinutes;
                  });
                },
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      FlutterOverlayWindow.closeOverlay();
                    },
                    child: const Text('إلغاء'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: selectedGoal != null ? () {
                      // Send result back to main app
                      FlutterOverlayWindow.shareData({
                        'action': 'goal_selected',
                        'goal_id': selectedGoal!.id,
                        'duration': customDuration,
                        'app_package': widget.app.packageName,
                      });
                      FlutterOverlayWindow.closeOverlay();
                    } : null,
                    child: const Text('بدء'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

