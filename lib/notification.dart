
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('America/Chicago'));

    debugPrint('SECURERX NOTIFICATION SERVICE STARTED');

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const initSettings =
        InitializationSettings(android: androidSettings);

    await _notificationsPlugin.initialize(initSettings);

    const AndroidNotificationChannel channel =
        AndroidNotificationChannel(
      'med_reminder_id',
      'Medication Reminders',
      description: 'Notifications for medication reminders',
      importance: Importance.max,
    );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    final androidPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    final permissionGranted =
        await androidPlugin?.requestNotificationsPermission();

    final exactAllowed =
        await androidPlugin?.canScheduleExactNotifications();

    debugPrint(
        'Notification permission request result: $permissionGranted');
    debugPrint('Exact alarms allowed: $exactAllowed');
  }

  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDateTime,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    final scheduledTZ =
        tz.TZDateTime.from(scheduledDateTime, tz.local);

    debugPrint('Current local time: $now');
    debugPrint('Original reminder time: $scheduledDateTime');
    debugPrint('Converted reminder time: $scheduledTZ');
    debugPrint('Timezone used: ${tz.local.name}');

    if (!scheduledTZ.isAfter(now)) {
      debugPrint('NOT SCHEDULED: The reminder time has passed.');
      return;
    }

    try {
      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledTZ,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'med_reminder_id',
            'Medication Reminders',
            channelDescription: 'Notifications for medication reminders',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode:
            AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );

      debugPrint('SCHEDULE SUCCESS: Reminder ID $id');

      final pending =
          await _notificationsPlugin.pendingNotificationRequests();

      debugPrint('PENDING NOTIFICATIONS: ${pending.length}');
    } catch (e, stackTrace) {
      debugPrint('SCHEDULING FAILED: $e');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }
}
