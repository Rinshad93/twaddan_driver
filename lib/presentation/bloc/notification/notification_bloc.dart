import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/notification_model.dart';
import '../../../data/services/notification_service.dart';
import '../../../data/services/realtime_service.dart';
import 'notification_event.dart';
import 'notification_state.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final NotificationService _notificationService;
  final RealtimeService _realtimeService;

  List<NotificationModel> _notifications = [];
  NotificationSettings _settings = const NotificationSettings();

  late StreamSubscription<NotificationModel> _notificationSubscription;
  late StreamSubscription<NotificationModel> _notificationTapSubscription;
  late StreamSubscription<NotificationModel> _realtimeNotificationSubscription;

  NotificationBloc({
    NotificationService? notificationService,
    RealtimeService? realtimeService,
  })  : _notificationService = notificationService ?? NotificationService(),
        _realtimeService = realtimeService ?? RealtimeService(),
        super(const NotificationInitial()) {

    on<NotificationInitialize>(_onInitialize);
    on<NotificationReceived>(_onNotificationReceived);
    on<NotificationTapped>(_onNotificationTapped);
    on<NotificationMarkAsRead>(_onMarkAsRead);
    on<NotificationMarkAllAsRead>(_onMarkAllAsRead);
    on<NotificationDelete>(_onDelete);
    on<NotificationClearAll>(_onClearAll);
    on<NotificationSettingsUpdate>(_onSettingsUpdate);
    on<NotificationPermissionRequested>(_onPermissionRequested);
  }

  Future<void> _onInitialize(
      NotificationInitialize event,
      Emitter<NotificationState> emit,
      ) async {
    try {
      emit(const NotificationLoading());

      // Initialize notification service
      await _notificationService.initialize();

      // Load settings
      final settingsMap = await _notificationService.getNotificationSettings();
      _settings = NotificationSettings(
        pushNotifications: settingsMap['pushNotifications'] ?? true,
        orderAlerts: settingsMap['orderAlerts'] ?? true,
        earningsNotifications: settingsMap['earningsNotifications'] ?? true,
        soundEnabled: settingsMap['soundEffects'] ?? true,
        vibrationEnabled: settingsMap['vibration'] ?? true,
      );

      // Load existing notifications (from local storage)
      await _loadStoredNotifications();

      // Subscribe to notification streams
      _subscribeToNotifications();

      // Schedule recurring notifications
      await _scheduleRecurringNotifications();

      emit(NotificationLoaded(
        notifications: _notifications,
        settings: _settings,
        unreadCount: _getUnreadCount(),
      ));

    } catch (e) {
      emit(NotificationError('Failed to initialize notifications: ${e.toString()}'));
    }
  }

  Future<void> _onNotificationReceived(
      NotificationReceived event,
      Emitter<NotificationState> emit,
      ) async {
    try {
      final notification = event.notification;

      // Check if notification type is enabled
      if (!_settings.isNotificationTypeEnabled(notification.type)) {
        return;
      }

      // Check Do Not Disturb
      if (_settings.shouldSilenceNotifications() &&
          notification.type != NotificationType.emergency) {
        // Store silently without showing
        _notifications.insert(0, notification);
        await _saveNotifications();
        return;
      }

      // Add to notifications list
      _notifications.insert(0, notification);

      // Limit notifications to prevent memory issues
      if (_notifications.length > 100) {
        _notifications = _notifications.take(100).toList();
      }

      // Save to storage
      await _saveNotifications();

      emit(NotificationLoaded(
        notifications: _notifications,
        settings: _settings,
        unreadCount: _getUnreadCount(),
      ));

      // Handle special notification types
      await _handleSpecialNotifications(notification);

    } catch (e) {
      emit(NotificationError('Failed to process notification: ${e.toString()}'));
    }
  }

  Future<void> _onNotificationTapped(
      NotificationTapped event,
      Emitter<NotificationState> emit,
      ) async {
    try {
      final notification = event.notification;

      // Mark as read
      final updatedNotification = notification.copyWith(isRead: true);
      final index = _notifications.indexWhere((n) => n.id == notification.id);

      if (index != -1) {
        _notifications[index] = updatedNotification;
        await _saveNotifications();
      }

      // Emit action triggered state
      emit(NotificationActionTriggered(
        notification: updatedNotification,
        action: 'tap',
      ));

      // Return to loaded state
      emit(NotificationLoaded(
        notifications: _notifications,
        settings: _settings,
        unreadCount: _getUnreadCount(),
      ));

    } catch (e) {
      emit(NotificationError('Failed to handle notification tap: ${e.toString()}'));
    }
  }

  Future<void> _onMarkAsRead(
      NotificationMarkAsRead event,
      Emitter<NotificationState> emit,
      ) async {
    try {
      final index = _notifications.indexWhere((n) => n.id == event.notificationId);

      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
        await _saveNotifications();

        emit(NotificationLoaded(
          notifications: _notifications,
          settings: _settings,
          unreadCount: _getUnreadCount(),
        ));
      }
    } catch (e) {
      emit(NotificationError('Failed to mark notification as read: ${e.toString()}'));
    }
  }

  Future<void> _onMarkAllAsRead(
      NotificationMarkAllAsRead event,
      Emitter<NotificationState> emit,
      ) async {
    try {
      _notifications = _notifications
          .map((notification) => notification.copyWith(isRead: true))
          .toList();

      await _saveNotifications();

      emit(NotificationLoaded(
        notifications: _notifications,
        settings: _settings,
        unreadCount: 0,
      ));
    } catch (e) {
      emit(NotificationError('Failed to mark all notifications as read: ${e.toString()}'));
    }
  }

  Future<void> _onDelete(
      NotificationDelete event,
      Emitter<NotificationState> emit,
      ) async {
    try {
      _notifications.removeWhere((n) => n.id == event.notificationId);
      await _saveNotifications();

      emit(NotificationLoaded(
        notifications: _notifications,
        settings: _settings,
        unreadCount: _getUnreadCount(),
      ));
    } catch (e) {
      emit(NotificationError('Failed to delete notification: ${e.toString()}'));
    }
  }

  Future<void> _onClearAll(
      NotificationClearAll event,
      Emitter<NotificationState> emit,
      ) async {
    try {
      _notifications.clear();
      await _saveNotifications();
      await _notificationService.cancelAllNotifications();

      emit(NotificationLoaded(
        notifications: _notifications,
        settings: _settings,
        unreadCount: 0,
      ));
    } catch (e) {
      emit(NotificationError('Failed to clear all notifications: ${e.toString()}'));
    }
  }

  Future<void> _onSettingsUpdate(
      NotificationSettingsUpdate event,
      Emitter<NotificationState> emit,
      ) async {
    try {
      _settings = event.settings;

      // Save settings
      await _notificationService.updateNotificationSettings({
        'pushNotifications': _settings.pushNotifications,
        'orderAlerts': _settings.orderAlerts,
        'earningsNotifications': _settings.earningsNotifications,
        'soundEffects': _settings.soundEnabled,
        'vibration': _settings.vibrationEnabled,
      });

      emit(NotificationLoaded(
        notifications: _notifications,
        settings: _settings,
        unreadCount: _getUnreadCount(),
      ));
    } catch (e) {
      emit(NotificationError('Failed to update settings: ${e.toString()}'));
    }
  }

  Future<void> _onPermissionRequested(
      NotificationPermissionRequested event,
      Emitter<NotificationState> emit,
      ) async {
    try {
      await _notificationService.initialize();

      emit(NotificationLoaded(
        notifications: _notifications,
        settings: _settings,
        unreadCount: _getUnreadCount(),
      ));
    } catch (e) {
      emit(const NotificationPermissionDenied());
    }
  }

  /// Subscribe to notification streams
  void _subscribeToNotifications() {
    // Local notifications
    _notificationSubscription = _notificationService.onNotificationReceived.listen(
          (notification) => add(NotificationReceived(notification)),
    );

    _notificationTapSubscription = _notificationService.onNotificationTapped.listen(
          (notification) => add(NotificationTapped(notification)),
    );

    // Real-time notifications
    _realtimeNotificationSubscription = _realtimeService.notifications.listen(
          (notification) => add(NotificationReceived(notification)),
    );
  }

  /// Load stored notifications from local storage
  Future<void> _loadStoredNotifications() async {
    try {
      // Implementation would load from SharedPreferences or local database
      // For now, start with empty list
      _notifications = [];
    } catch (e) {
      print('Error loading stored notifications: $e');
    }
  }

  /// Save notifications to local storage
  Future<void> _saveNotifications() async {
    try {
      // Implementation would save to SharedPreferences or local database
      // For now, just keep in memory
    } catch (e) {
      print('Error saving notifications: $e');
    }
  }

  /// Schedule recurring notifications
  Future<void> _scheduleRecurringNotifications() async {
    if (_settings.earningsNotifications) {
      await _notificationService.scheduleDailyEarningsSummary();
      await _notificationService.scheduleWeeklyEarningsSummary();
    }
  }

  /// Handle special notification types
  Future<void> _handleSpecialNotifications(NotificationModel notification) async {
    switch (notification.type) {
      case NotificationType.newOrder:
      // Auto-dismiss after 60 seconds for new orders
        Timer(const Duration(seconds: 60), () {
          _notificationService.cancelNotification(notification.id.hashCode);
        });
        break;

      case NotificationType.emergency:
      // Emergency notifications should be persistent and attention-grabbing
      // Could trigger additional alerts like ringtone or flashlight
        break;

      default:
        break;
    }
  }

  /// Get unread notification count
  int _getUnreadCount() {
    return _notifications.where((n) => !n.isRead).length;
  }

  /// Get notifications by type
  List<NotificationModel> getNotificationsByType(NotificationType type) {
    return _notifications.where((n) => n.type == type).toList();
  }

  /// Get recent notifications (last 24 hours)
  List<NotificationModel> getRecentNotifications() {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return _notifications.where((n) => n.timestamp.isAfter(yesterday)).toList();
  }

  @override
  Future<void> close() {
    _notificationSubscription.cancel();
    _notificationTapSubscription.cancel();
    _realtimeNotificationSubscription.cancel();
    return super.close();
  }
}