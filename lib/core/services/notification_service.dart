import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  Future<void> _onNotificationTapped(NotificationResponse response) async {
    // TODO: Handle notification tap based on payload
    print('Notification tapped: ${response.payload}');
  }

  Future<void> showBookingConfirmation({
    required String bookingId,
    required String serviceName,
    required String date,
    required String time,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'booking_updates',
      'Booking Updates',
      channelDescription: 'Notifications for booking status updates',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      bookingId.hashCode,
      'Booking Confirmed',
      'Your $serviceName booking for $date at $time has been confirmed.',
      details,
      payload: 'booking:$bookingId',
    );
  }

  Future<void> showBookingReminder({
    required String bookingId,
    required String serviceName,
    required String date,
    required String time,
  }) async {
    // Schedule notification for 1 hour before the booking
    final scheduledTime = _parseDateTime(date, time).subtract(const Duration(hours: 1));

    const androidDetails = AndroidNotificationDetails(
      'booking_reminders',
      'Booking Reminders',
      channelDescription: 'Reminders for upcoming bookings',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      bookingId.hashCode + 1, // Different ID from confirmation
      'Upcoming Booking Reminder',
      'Your $serviceName booking is scheduled for $date at $time.',
      tz.TZDateTime.from(scheduledTime, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: 'booking:$bookingId',
    );
  }

  Future<void> showBookingStatusUpdate({
    required String bookingId,
    required String serviceName,
    required String status,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'booking_updates',
      'Booking Updates',
      channelDescription: 'Notifications for booking status updates',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    String title;
    String body;

    switch (status.toLowerCase()) {
      case 'cancelled':
        title = 'Booking Cancelled';
        body = 'Your $serviceName booking has been cancelled.';
        break;
      case 'completed':
        title = 'Service Completed';
        body = 'Your $serviceName has been completed. Please rate your experience.';
        break;
      case 'in_progress':
        title = 'Service in Progress';
        body = 'Your $serviceName is currently being provided.';
        break;
      default:
        title = 'Booking Update';
        body = 'Your $serviceName booking status has been updated to $status.';
    }

    await _notifications.show(
      bookingId.hashCode + 2, // Different ID from confirmation and reminder
      title,
      body,
      details,
      payload: 'booking:$bookingId',
    );
  }

  DateTime _parseDateTime(String date, String time) {
    final dateParts = date.split('-');
    final timeParts = time.split(':');
    final isPM = time.toLowerCase().contains('pm');
    var hour = int.parse(timeParts[0]);
    
    if (isPM && hour != 12) {
      hour += 12;
    } else if (!isPM && hour == 12) {
      hour = 0;
    }

    return DateTime(
      int.parse(dateParts[0]), // year
      int.parse(dateParts[1]), // month
      int.parse(dateParts[2]), // day
      hour,
      int.parse(timeParts[1].replaceAll(RegExp(r'[^0-9]'), '')), // minutes
    );
  }
} 