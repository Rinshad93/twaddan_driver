import 'package:equatable/equatable.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

enum NotificationType {
  newOrder,
  orderUpdate,
  earnings,
  emergency,
  promotional,
  general,
}

extension NotificationTypeExtension on NotificationType {
  String get displayName {
    switch (this) {
      case NotificationType.newOrder:
        return 'New Order';
      case NotificationType.orderUpdate:
        return 'Order Update';
      case NotificationType.earnings:
        return 'Earnings';
      case NotificationType.emergency:
        return 'Emergency';
      case NotificationType.promotional:
        return 'Promotional';
      case NotificationType.general:
        return 'General';
    }
  }

  String get value {
    switch (this) {
      case NotificationType.newOrder:
        return 'new_order';
      case NotificationType.orderUpdate:
        return 'order_update';
      case NotificationType.earnings:
        return 'earnings';
      case NotificationType.emergency:
        return 'emergency';
      case NotificationType.promotional:
        return 'promotional';
      case NotificationType.general:
        return 'general';
    }
  }

  static NotificationType fromString(String value) {
    switch (value) {
      case 'new_order':
        return NotificationType.newOrder;
      case 'order_update':
        return NotificationType.orderUpdate;
      case 'earnings':
        return NotificationType.earnings;
      case 'emergency':
        return NotificationType.emergency;
      case 'promotional':
        return NotificationType.promotional;
      default:
        return NotificationType.general;
    }
  }
}

class NotificationModel extends Equatable {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final bool isRead;
  final String? imageUrl;
  final String? actionUrl;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.data = const {},
    required this.timestamp,
    this.isRead = false,
    this.imageUrl,
    this.actionUrl,
  });

  NotificationModel copyWith({
    String? id,
    String? title,
    String? body,
    NotificationType? type,
    Map<String, dynamic>? data,
    DateTime? timestamp,
    bool? isRead,
    String? imageUrl,
    String? actionUrl,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      data: data ?? this.data,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      imageUrl: imageUrl ?? this.imageUrl,
      actionUrl: actionUrl ?? this.actionUrl,
    );
  }

  factory NotificationModel.fromRemoteMessage(RemoteMessage message) {
    final notificationType = message.data['type'] != null
        ? NotificationTypeExtension.fromString(message.data['type'])
        : NotificationType.general;

    return NotificationModel(
      id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: message.notification?.title ?? 'Notification',
      body: message.notification?.body ?? '',
      type: notificationType,
      data: message.data,
      timestamp: DateTime.now(),
      imageUrl: message.notification?.android?.imageUrl ?? message.notification?.apple?.imageUrl,
      actionUrl: message.data['action_url'],
    );
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      type: NotificationTypeExtension.fromString(json['type'] ?? 'general'),
      data: Map<String, dynamic>.from(json['data'] ?? {}),
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      isRead: json['isRead'] ?? false,
      imageUrl: json['imageUrl'],
      actionUrl: json['actionUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'type': type.value,
      'data': data,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'imageUrl': imageUrl,
      'actionUrl': actionUrl,
    };
  }

  // Helper getters for specific notification types
  String? get orderId => data['orderId'];
  String? get restaurantName => data['restaurantName'];
  double? get deliveryFee => double.tryParse(data['deliveryFee'] ?? '');
  double? get estimatedTime => double.tryParse(data['estimatedTime'] ?? '');
  String? get orderStatus => data['status'];
  String? get earningsPeriod => data['period'];
  double? get earningsAmount => double.tryParse(data['amount'] ?? '');
  int? get deliveriesCount => int.tryParse(data['deliveries'] ?? '');

  // Notification priority based on type
  int get priority {
    switch (type) {
      case NotificationType.emergency:
        return 4; // Highest
      case NotificationType.newOrder:
        return 3; // High
      case NotificationType.orderUpdate:
        return 2; // Medium
      case NotificationType.earnings:
        return 1; // Low
      default:
        return 0; // Lowest
    }
  }

  // Check if notification is time-sensitive
  bool get isTimeSensitive {
    return type == NotificationType.newOrder ||
        type == NotificationType.emergency ||
        type == NotificationType.orderUpdate;
  }

  // Check if notification should show actions
  bool get hasActions {
    return type == NotificationType.newOrder;
  }

  // Get display time for UI
  String get displayTime {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  // Get notification icon based on type
  String get iconPath {
    switch (type) {
      case NotificationType.newOrder:
        return 'assets/icons/order_notification.png';
      case NotificationType.orderUpdate:
        return 'assets/icons/update_notification.png';
      case NotificationType.earnings:
        return 'assets/icons/earnings_notification.png';
      case NotificationType.emergency:
        return 'assets/icons/emergency_notification.png';
      case NotificationType.promotional:
        return 'assets/icons/promo_notification.png';
      default:
        return 'assets/icons/general_notification.png';
    }
  }

  @override
  List<Object?> get props => [
    id,
    title,
    body,
    type,
    data,
    timestamp,
    isRead,
    imageUrl,
    actionUrl,
  ];
}

// Notification action model
class NotificationAction extends Equatable {
  final String id;
  final String label;
  final String? iconPath;
  final Map<String, dynamic>? data;

  const NotificationAction({
    required this.id,
    required this.label,
    this.iconPath,
    this.data,
  });

  factory NotificationAction.fromJson(Map<String, dynamic> json) {
    return NotificationAction(
      id: json['id'] ?? '',
      label: json['label'] ?? '',
      iconPath: json['iconPath'],
      data: json['data'] != null ? Map<String, dynamic>.from(json['data']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'iconPath': iconPath,
      'data': data,
    };
  }

  @override
  List<Object?> get props => [id, label, iconPath, data];
}

// Notification settings model
class NotificationSettings extends Equatable {
  final bool pushNotifications;
  final bool orderAlerts;
  final bool earningsNotifications;
  final bool emergencyAlerts;
  final bool promotionalNotifications;
  final bool soundEnabled;
  final bool vibrationEnabled;
  final String? customSound;
  final bool doNotDisturbEnabled;
  final TimeOfDay? doNotDisturbStart;
  final TimeOfDay? doNotDisturbEnd;

  const NotificationSettings({
    this.pushNotifications = true,
    this.orderAlerts = true,
    this.earningsNotifications = true,
    this.emergencyAlerts = true,
    this.promotionalNotifications = false,
    this.soundEnabled = true,
    this.vibrationEnabled = true,
    this.customSound,
    this.doNotDisturbEnabled = false,
    this.doNotDisturbStart,
    this.doNotDisturbEnd,
  });

  NotificationSettings copyWith({
    bool? pushNotifications,
    bool? orderAlerts,
    bool? earningsNotifications,
    bool? emergencyAlerts,
    bool? promotionalNotifications,
    bool? soundEnabled,
    bool? vibrationEnabled,
    String? customSound,
    bool? doNotDisturbEnabled,
    TimeOfDay? doNotDisturbStart,
    TimeOfDay? doNotDisturbEnd,
  }) {
    return NotificationSettings(
      pushNotifications: pushNotifications ?? this.pushNotifications,
      orderAlerts: orderAlerts ?? this.orderAlerts,
      earningsNotifications: earningsNotifications ?? this.earningsNotifications,
      emergencyAlerts: emergencyAlerts ?? this.emergencyAlerts,
      promotionalNotifications: promotionalNotifications ?? this.promotionalNotifications,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      customSound: customSound ?? this.customSound,
      doNotDisturbEnabled: doNotDisturbEnabled ?? this.doNotDisturbEnabled,
      doNotDisturbStart: doNotDisturbStart ?? this.doNotDisturbStart,
      doNotDisturbEnd: doNotDisturbEnd ?? this.doNotDisturbEnd,
    );
  }

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      pushNotifications: json['pushNotifications'] ?? true,
      orderAlerts: json['orderAlerts'] ?? true,
      earningsNotifications: json['earningsNotifications'] ?? true,
      emergencyAlerts: json['emergencyAlerts'] ?? true,
      promotionalNotifications: json['promotionalNotifications'] ?? false,
      soundEnabled: json['soundEnabled'] ?? true,
      vibrationEnabled: json['vibrationEnabled'] ?? true,
      customSound: json['customSound'],
      doNotDisturbEnabled: json['doNotDisturbEnabled'] ?? false,
      doNotDisturbStart: json['doNotDisturbStart'] != null
          ? TimeOfDay(
        hour: json['doNotDisturbStart']['hour'],
        minute: json['doNotDisturbStart']['minute'],
      )
          : null,
      doNotDisturbEnd: json['doNotDisturbEnd'] != null
          ? TimeOfDay(
        hour: json['doNotDisturbEnd']['hour'],
        minute: json['doNotDisturbEnd']['minute'],
      )
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pushNotifications': pushNotifications,
      'orderAlerts': orderAlerts,
      'earningsNotifications': earningsNotifications,
      'emergencyAlerts': emergencyAlerts,
      'promotionalNotifications': promotionalNotifications,
      'soundEnabled': soundEnabled,
      'vibrationEnabled': vibrationEnabled,
      'customSound': customSound,
      'doNotDisturbEnabled': doNotDisturbEnabled,
      'doNotDisturbStart': doNotDisturbStart != null
          ? {
        'hour': doNotDisturbStart!.hour,
        'minute': doNotDisturbStart!.minute,
      }
          : null,
      'doNotDisturbEnd': doNotDisturbEnd != null
          ? {
        'hour': doNotDisturbEnd!.hour,
        'minute': doNotDisturbEnd!.minute,
      }
          : null,
    };
  }

  // Check if notifications should be silenced based on Do Not Disturb
  bool shouldSilenceNotifications() {
    if (!doNotDisturbEnabled || doNotDisturbStart == null || doNotDisturbEnd == null) {
      return false;
    }

    final now = TimeOfDay.now();
    final start = doNotDisturbStart!;
    final end = doNotDisturbEnd!;

    // Handle overnight Do Not Disturb periods
    if (start.hour > end.hour || (start.hour == end.hour && start.minute > end.minute)) {
      // Overnight period (e.g., 22:00 to 06:00)
      return (now.hour > start.hour || (now.hour == start.hour && now.minute >= start.minute)) ||
          (now.hour < end.hour || (now.hour == end.hour && now.minute <= end.minute));
    } else {
      // Same day period (e.g., 12:00 to 14:00)
      return (now.hour > start.hour || (now.hour == start.hour && now.minute >= start.minute)) &&
          (now.hour < end.hour || (now.hour == end.hour && now.minute <= end.minute));
    }
  }

  // Check if specific notification type is enabled
  bool isNotificationTypeEnabled(NotificationType type) {
    if (!pushNotifications) return false;

    switch (type) {
      case NotificationType.newOrder:
      case NotificationType.orderUpdate:
        return orderAlerts;
      case NotificationType.earnings:
        return earningsNotifications;
      case NotificationType.emergency:
        return emergencyAlerts;
      case NotificationType.promotional:
        return promotionalNotifications;
      default:
        return true;
    }
  }

  @override
  List<Object?> get props => [
    pushNotifications,
    orderAlerts,
    earningsNotifications,
    emergencyAlerts,
    promotionalNotifications,
    soundEnabled,
    vibrationEnabled,
    customSound,
    doNotDisturbEnabled,
    doNotDisturbStart,
    doNotDisturbEnd,
  ];
}