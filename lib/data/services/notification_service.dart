import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../models/notification_model.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  // Stream controllers for notification events
  final _onNotificationReceived = StreamController<NotificationModel>.broadcast();
  final _onNotificationTapped = StreamController<NotificationModel>.broadcast();

  // Notification streams
  Stream<NotificationModel> get onNotificationReceived => _onNotificationReceived.stream;
  Stream<NotificationModel> get onNotificationTapped => _onNotificationTapped.stream;

  // Notification channels
  static const String _orderChannelId = 'order_notifications';
  static const String _earningsChannelId = 'earnings_notifications';
  static const String _generalChannelId = 'general_notifications';
  static const String _emergencyChannelId = 'emergency_notifications';

  bool _isInitialized = false;
  String? _fcmToken;

  /// Initialize notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize timezone data
    tz.initializeTimeZones();

    await _initializeLocalNotifications();
    await _initializeFirebaseMessaging();
    await _setupNotificationChannels();

    _isInitialized = true;
  }

  /// Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
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

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );
  }

  /// Initialize Firebase messaging
  Future<void> _initializeFirebaseMessaging() async {
    // Request permissions
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
    } else {
      print('User declined or has not accepted permission');
    }

    // Get FCM token
    _fcmToken = await _firebaseMessaging.getToken();
    print('FCM Token: $_fcmToken');

    // Listen to token refresh
    _firebaseMessaging.onTokenRefresh.listen((token) {
      _fcmToken = token;
      _saveFCMToken(token);
    });

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background message taps
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessageTap);

    // Check for initial message (app opened from terminated state)
    final initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleBackgroundMessageTap(initialMessage);
    }
  }

  /// Setup notification channels
  Future<void> _setupNotificationChannels() async {
    final androidPlugin = _localNotifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      // Order notifications channel
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          _orderChannelId,
          'Order Notifications',
          description: 'Notifications for new orders and order updates',
          importance: Importance.high,
          sound: RawResourceAndroidNotificationSound('order_sound'),
        ),
      );

      // Earnings notifications channel
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          _earningsChannelId,
          'Earnings Notifications',
          description: 'Daily and weekly earnings summaries',
          importance: Importance.defaultImportance,
        ),
      );

      // General notifications channel
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          _generalChannelId,
          'General Notifications',
          description: 'General app notifications and updates',
          importance: Importance.defaultImportance,
        ),
      );

      // Emergency notifications channel
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          _emergencyChannelId,
          'Emergency Notifications',
          description: 'Critical safety and emergency notifications',
          importance: Importance.max,
          sound: RawResourceAndroidNotificationSound('emergency_sound'),
        ),
      );
    }
  }

  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    final notification = NotificationModel.fromRemoteMessage(message);

    // Show local notification
    _showLocalNotification(notification);

    // Emit to stream
    _onNotificationReceived.add(notification);
  }

  /// Handle background message tap
  void _handleBackgroundMessageTap(RemoteMessage message) {
    final notification = NotificationModel.fromRemoteMessage(message);
    _onNotificationTapped.add(notification);
  }

  /// Handle local notification response
  void _onNotificationResponse(NotificationResponse response) {
    if (response.payload != null) {
      try {
        final notificationData = json.decode(response.payload!);
        final notification = NotificationModel.fromJson(notificationData);
        _onNotificationTapped.add(notification);
      } catch (e) {
        print('Error parsing notification payload: $e');
      }
    }
  }

  /// Show local notification
  Future<void> _showLocalNotification(NotificationModel notification) async {
    final androidDetails = AndroidNotificationDetails(
      _getChannelId(notification.type),
      _getChannelName(notification.type),
      channelDescription: _getChannelDescription(notification.type),
      importance: _getImportance(notification.type),
      priority: _getPriority(notification.type),
      icon: _getNotificationIcon(notification.type),
      color: _getNotificationColor(notification.type),
      playSound: true,
      enableVibration: true,
      actions: _getNotificationActions(notification.type),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      notification.id.hashCode,
      notification.title,
      notification.body,
      notificationDetails,
      payload: json.encode(notification.toJson()),
    );
  }

  /// Show new order notification
  Future<void> showNewOrderNotification({
    required String orderId,
    required String restaurantName,
    required double deliveryFee,
    required double estimatedTime,
  }) async {
    final notification = NotificationModel(
      id: 'order_$orderId',
      title: 'New Order Available! 🚗',
      body: '$restaurantName • \$${deliveryFee.toStringAsFixed(2)} • ${estimatedTime.toInt()}min',
      type: NotificationType.newOrder,
      data: {
        'orderId': orderId,
        'restaurantName': restaurantName,
        'deliveryFee': deliveryFee.toString(),
        'estimatedTime': estimatedTime.toString(),
      },
      timestamp: DateTime.now(),
    );

    await _showLocalNotification(notification);
    _onNotificationReceived.add(notification);
  }

  /// Show order status update notification
  Future<void> showOrderStatusNotification({
    required String orderId,
    required String status,
    required String message,
  }) async {
    final notification = NotificationModel(
      id: 'status_$orderId',
      title: 'Order Update',
      body: message,
      type: NotificationType.orderUpdate,
      data: {
        'orderId': orderId,
        'status': status,
      },
      timestamp: DateTime.now(),
    );

    await _showLocalNotification(notification);
    _onNotificationReceived.add(notification);
  }

  /// Show earnings notification
  Future<void> showEarningsNotification({
    required String period,
    required double amount,
    required int deliveries,
  }) async {
    final notification = NotificationModel(
      id: 'earnings_$period',
      title: '$period Earnings Summary 💰',
      body: 'You earned \$${amount.toStringAsFixed(2)} from $deliveries deliveries',
      type: NotificationType.earnings,
      data: {
        'period': period,
        'amount': amount.toString(),
        'deliveries': deliveries.toString(),
      },
      timestamp: DateTime.now(),
    );

    await _showLocalNotification(notification);
    _onNotificationReceived.add(notification);
  }

  /// Show emergency notification
  Future<void> showEmergencyNotification({
    required String title,
    required String message,
    Map<String, dynamic>? data,
  }) async {
    final notification = NotificationModel(
      id: 'emergency_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      body: message,
      type: NotificationType.emergency,
      data: data ?? {},
      timestamp: DateTime.now(),
    );

    await _showLocalNotification(notification);
    _onNotificationReceived.add(notification);
  }

  /// Show promotional notification
  Future<void> showPromotionalNotification({
    required String title,
    required String message,
    Map<String, dynamic>? data,
  }) async {
    final notification = NotificationModel(
      id: 'promo_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      body: message,
      type: NotificationType.promotional,
      data: data ?? {},
      timestamp: DateTime.now(),
    );

    await _showLocalNotification(notification);
    _onNotificationReceived.add(notification);
  }

  /// Schedule daily earnings summary
  Future<void> scheduleDailyEarningsSummary() async {
    await _localNotifications.zonedSchedule(
      1001, // Unique ID for daily summary
      'Daily Earnings Summary',
      'Tap to view your earnings for today',
      _nextInstanceOfTime(22, 0), // 10 PM daily
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _earningsChannelId,
          'Earnings Notifications',
          channelDescription: 'Daily and weekly earnings summaries',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: json.encode({
        'type': 'daily_summary',
        'action': 'show_earnings',
      }),
    );
  }

  /// Schedule weekly earnings summary
  Future<void> scheduleWeeklyEarningsSummary() async {
    await _localNotifications.zonedSchedule(
      1002, // Unique ID for weekly summary
      'Weekly Earnings Summary',
      'See how much you earned this week!',
      _nextInstanceOfWeekday(DateTime.monday, 9, 0), // Monday 9 AM
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _earningsChannelId,
          'Earnings Notifications',
          channelDescription: 'Daily and weekly earnings summaries',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      payload: json.encode({
        'type': 'weekly_summary',
        'action': 'show_earnings',
      }),
    );
  }

  /// Get notification settings
  Future<Map<String, bool>> getNotificationSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'pushNotifications': prefs.getBool('push_notifications') ?? true,
      'orderAlerts': prefs.getBool('order_alerts') ?? true,
      'earningsNotifications': prefs.getBool('earnings_notifications') ?? true,
      'soundEffects': prefs.getBool('sound_effects') ?? true,
      'vibration': prefs.getBool('vibration') ?? true,
    };
  }

  /// Update notification settings
  Future<void> updateNotificationSettings(Map<String, bool> settings) async {
    final prefs = await SharedPreferences.getInstance();
    for (final entry in settings.entries) {
      await prefs.setBool(entry.key, entry.value);
    }
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  /// Cancel notification by ID
  Future<void> cancelNotification(int id) async {
    await _localNotifications.cancel(id);
  }

  /// Get FCM token
  String? get fcmToken => _fcmToken;

  /// Save FCM token
  Future<void> _saveFCMToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('fcm_token', token);
  }

  /// Helper methods for notification configuration
  String _getChannelId(NotificationType type) {
    switch (type) {
      case NotificationType.newOrder:
      case NotificationType.orderUpdate:
        return _orderChannelId;
      case NotificationType.earnings:
        return _earningsChannelId;
      case NotificationType.emergency:
        return _emergencyChannelId;
      default:
        return _generalChannelId;
    }
  }

  String _getChannelName(NotificationType type) {
    switch (type) {
      case NotificationType.newOrder:
      case NotificationType.orderUpdate:
        return 'Order Notifications';
      case NotificationType.earnings:
        return 'Earnings Notifications';
      case NotificationType.emergency:
        return 'Emergency Notifications';
      default:
        return 'General Notifications';
    }
  }

  String _getChannelDescription(NotificationType type) {
    switch (type) {
      case NotificationType.newOrder:
      case NotificationType.orderUpdate:
        return 'Notifications for new orders and order updates';
      case NotificationType.earnings:
        return 'Daily and weekly earnings summaries';
      case NotificationType.emergency:
        return 'Critical safety and emergency notifications';
      default:
        return 'General app notifications and updates';
    }
  }

  Importance _getImportance(NotificationType type) {
    switch (type) {
      case NotificationType.newOrder:
      case NotificationType.emergency:
        return Importance.high;
      case NotificationType.orderUpdate:
        return Importance.defaultImportance;
      default:
        return Importance.low;
    }
  }

  Priority _getPriority(NotificationType type) {
    switch (type) {
      case NotificationType.newOrder:
      case NotificationType.emergency:
        return Priority.high;
      case NotificationType.orderUpdate:
        return Priority.defaultPriority;
      default:
        return Priority.low;
    }
  }

  String? _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.newOrder:
        return 'ic_order';
      case NotificationType.orderUpdate:
        return 'ic_update';
      case NotificationType.earnings:
        return 'ic_money';
      case NotificationType.emergency:
        return 'ic_emergency';
      default:
        return null;
    }
  }

  Color? _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.newOrder:
        return const Color(0xFF4CAF50); // Green
      case NotificationType.orderUpdate:
        return const Color(0xFF2196F3); // Blue
      case NotificationType.earnings:
        return const Color(0xFFFF9800); // Orange
      case NotificationType.emergency:
        return const Color(0xFFF44336); // Red
      default:
        return null;
    }
  }

  List<AndroidNotificationAction>? _getNotificationActions(NotificationType type) {
    switch (type) {
      case NotificationType.newOrder:
        return [
          const AndroidNotificationAction(
            'accept_order',
            'Accept',
            icon: DrawableResourceAndroidBitmap('ic_check'),
          ),
          const AndroidNotificationAction(
            'decline_order',
            'Decline',
            icon: DrawableResourceAndroidBitmap('ic_close'),
          ),
        ];
      default:
        return null;
    }
  }

  /// Helper to get next instance of time
  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  /// Helper to get next instance of weekday
  tz.TZDateTime _nextInstanceOfWeekday(int weekday, int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

    while (scheduledDate.weekday != weekday) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 7));
    }

    return scheduledDate;
  }

  /// Dispose resources
  void dispose() {
    _onNotificationReceived.close();
    _onNotificationTapped.close();
  }
}