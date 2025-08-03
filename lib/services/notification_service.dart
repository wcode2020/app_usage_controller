import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _isInitialized = true;
  }

  Future<bool> requestPermissions() async {
    final permission = await Permission.notification.request();
    return permission.isGranted;
  }

  void _onNotificationTapped(NotificationResponse notificationResponse) {
    // Handle notification tap
    print('Notification tapped: ${notificationResponse.payload}');
  }

  Future<void> showTimeUpNotification({
    required String appName,
    required int plannedMinutes,
    required int actualMinutes,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'time_up_channel',
      'انتهاء الوقت المحدد',
      channelDescription: 'إشعارات انتهاء الوقت المحدد لاستخدام التطبيقات',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    final title = 'انتهى الوقت المحدد!';
    final body = 'لقد انتهت الـ $plannedMinutes دقيقة المحددة لاستخدام $appName';

    await _flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      platformChannelSpecifics,
      payload: 'time_up:$appName',
    );
  }

  Future<void> showWarningNotification({
    required String appName,
    required int remainingMinutes,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'warning_channel',
      'تحذير الوقت',
      channelDescription: 'تحذيرات قرب انتهاء الوقت المحدد',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      showWhen: true,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    final title = 'تحذير: الوقت ينفد!';
    final body = 'باقي $remainingMinutes دقيقة فقط لاستخدام $appName';

    await _flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      platformChannelSpecifics,
      payload: 'warning:$appName',
    );
  }

  Future<void> showOvertimeNotification({
    required String appName,
    required int overtimeMinutes,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'overtime_channel',
      'تجاوز الوقت المحدد',
      channelDescription: 'إشعارات تجاوز الوقت المحدد',
      importance: Importance.max,
      priority: Priority.max,
      showWhen: true,
      enableVibration: true,
      playSound: true,
      ongoing: true, // Make it persistent
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    final title = '⚠️ تجاوزت الوقت المحدد!';
    final body = 'لقد تجاوزت الوقت المحدد بـ $overtimeMinutes دقيقة في $appName';

    await _flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      platformChannelSpecifics,
      payload: 'overtime:$appName',
    );
  }

  Future<void> scheduleReminderNotification({
    required String appName,
    required int delayMinutes,
    required String message,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'reminder_channel',
      'تذكيرات',
      channelDescription: 'تذكيرات استخدام التطبيقات',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    final scheduledDate = tz.TZDateTime.from(
      DateTime.now().add(Duration(minutes: delayMinutes)),
      tz.local,
    );

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      'تذكير',
      message,
      scheduledDate,
      platformChannelSpecifics,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'reminder:$appName',
    );
  }

  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }

  Future<void> cancelNotification(int id) async {
    await _flutterLocalNotificationsPlugin.cancel(id);
  }
}

