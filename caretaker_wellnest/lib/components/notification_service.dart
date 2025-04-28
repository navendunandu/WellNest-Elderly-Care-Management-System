import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';

class RoutineNotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static final StreamController<NotificationResponse> streamController =
      StreamController<NotificationResponse>.broadcast();

  // Handle notification taps
  static void onTap(NotificationResponse notificationResponse) {
    print('Notification tapped: ${notificationResponse.payload}');
    streamController.add(notificationResponse);
  }

  static Future<void> scheduleOneTimeNotification({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
  }) async {
    try {
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'appointment_channel', // Use a different channel for appointments
        'Appointment Notifications',
        channelDescription: 'Reminders for doctor appointments',
        importance: Importance.max,
        priority: Priority.high,
      );
      const NotificationDetails notificationDetails =
          NotificationDetails(android: androidDetails);

      final bool canUseExact = await Permission.scheduleExactAlarm.isGranted;

      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        notificationDetails,
        androidScheduleMode: canUseExact
            ? AndroidScheduleMode.exactAllowWhileIdle
            : AndroidScheduleMode.inexactAllowWhileIdle,
        // No matchDateTimeComponents here, making it one-time
        payload: 'appointment-$id',
      );

      print('One-time notification scheduled: ID $id at $scheduledDate');
    } catch (e) {
      print('Error scheduling one-time notification: $e');
    }
  }

  // Initialize the service
  static Future<void> init() async {
    // Initialize time zones
    tz.initializeTimeZones();
    print("Available time zones: ${tz.timeZoneDatabase.locations.keys}");
    tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
    print("Set local time zone to: ${tz.local.name}");

    // Define initialization settings
    const AndroidInitializationSettings androidInitSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings =
        InitializationSettings(android: androidInitSettings);

    // Initialize the plugin FIRST
    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: onTap,
      onDidReceiveBackgroundNotificationResponse: onTap,
    );
    print("Notification plugin initialized");

    // Create the notification channel AFTER initializing the plugin
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'routine_channel',
      'Daily Routine Notifications',
      description: 'Reminders for daily routines',
      importance: Importance.max,
    );
    final androidPlugin =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(channel);
    print("Notification channel created: ${channel.id}");

    // Request and log permissions
    await _requestAndLogPermissions();
  }

  // Request and log permissions
  static Future<void> _requestAndLogPermissions() async {
    // Notification permission (Android 13+)
    print("Checking notification permission...");
    PermissionStatus notificationStatus = await Permission.notification.status;
    print("Notification permission status: $notificationStatus");
    if (notificationStatus.isDenied) {
      notificationStatus = await Permission.notification.request();
      print("Notification permission after request: $notificationStatus");
      if (notificationStatus.isPermanentlyDenied) {
        print(
            "Notification permission permanently denied. Opening settings...");
        await openAppSettings();
      }
    }

    // Exact alarm permission (Android 12+)
    print("Checking exact alarm permission...");
    PermissionStatus alarmStatus = await Permission.scheduleExactAlarm.status;
    print("Exact alarm permission status: $alarmStatus");
    if (alarmStatus.isDenied) {
      alarmStatus = await Permission.scheduleExactAlarm.request();
      print("Exact alarm permission after request: $alarmStatus");
      if (alarmStatus.isPermanentlyDenied) {
        print("Exact alarm permission permanently denied. Opening settings...");
        await openAppSettings();
      }
    }

    // Battery optimization exemption
    print("Checking battery optimization exemption...");
    PermissionStatus batteryStatus =
        await Permission.ignoreBatteryOptimizations.status;
    print("Battery optimization exemption status: $batteryStatus");
    if (batteryStatus.isDenied) {
      batteryStatus = await Permission.ignoreBatteryOptimizations.request();
      print("Battery optimization exemption after request: $batteryStatus");
      if (batteryStatus.isPermanentlyDenied) {
        print(
            "Battery optimization exemption permanently denied. Opening settings...");
        await openAppSettings();
      }
    }

    // Check if notifications are enabled (Android-specific)
    final bool? areNotificationsEnabled = await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.areNotificationsEnabled();
    print("Are notifications enabled: $areNotificationsEnabled");
  }

  // Show an immediate notification
  static Future<void> showImmediateNotification() async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'routine_channel',
      'Daily Routine Notifications',
      channelDescription: 'Reminders for daily routines',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidDetails);
    await _notificationsPlugin.show(
      0,
      'Test Notification',
      'This is an immediate test notification',
      notificationDetails,
    );
    print("Immediate notification shown");
  }

  // Schedule a notification
  static Future<void> scheduleNotification(
      int id, String title, String timeString) async {
    try {
      final timeParts = timeString.split(':');
      if (timeParts.length != 2) {
        print('Invalid time format for $title: $timeString');
        return;
      }

      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);
      print('Parsed time: $hour:$minute');

      final now = tz.TZDateTime.now(tz.local);
      print('Current local time: $now');
      print('Local time zone: ${tz.local.name}');
      tz.TZDateTime scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );

      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
        print('Scheduled for tomorrow: $scheduledDate');
      } else {
        print('Scheduled for today: $scheduledDate');
      }

      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'routine_channel',
        'Daily Routine Notifications',
        channelDescription: 'Reminders for daily routines',
        importance: Importance.max,
        priority: Priority.high,
      );
      const NotificationDetails notificationDetails =
          NotificationDetails(android: androidDetails);

      // Check if exact alarm permission is granted
      final bool canUseExact = await Permission.scheduleExactAlarm.isGranted;
      print("Can use exact scheduling: $canUseExact");

      await _notificationsPlugin.zonedSchedule(
        id,
        'Reminder',
        '$title is scheduled now',
        scheduledDate,
        notificationDetails,
        androidScheduleMode: canUseExact
            ? AndroidScheduleMode.exactAllowWhileIdle
            : AndroidScheduleMode.inexactAllowWhileIdle,
        payload: 'routine_notification',
      );

      print('Notification scheduled for $title at $scheduledDate');

      // Confirm alarm scheduling with AndroidAlarmManager
      await AndroidAlarmManager.oneShot(
        scheduledDate.difference(DateTime.now()),
        id,
        () => print("Alarm triggered for ID $id"),
      );

      // Check pending notifications to confirm scheduling
      await checkPendingNotifications();
    } catch (e) {
      print('Error scheduling notification for $title: $e');
    }
  }

  // Check pending notifications
  static Future<void> checkPendingNotifications() async {
    final List<PendingNotificationRequest> pendingNotifications =
        await _notificationsPlugin.pendingNotificationRequests();
    print("Pending notifications: ${pendingNotifications.length}");
    for (final request in pendingNotifications) {
      print(
          "Pending notification - ID: ${request.id}, Title: ${request.title}, Body: ${request.body}, Payload: ${request.payload}");
    }
  }

  // Cancel a specific notification
  static Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
    print("Notification with ID $id canceled");
  }

  // Cancel all notifications
  static Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
    print("All notifications canceled");
  }

  // Add a test method for scheduling
  static void testScheduling() async {
    await scheduleNotification(
      999,
      "Test",
      "11:37", // Replace with a time 2 minutes in the future
    );
  }
}
