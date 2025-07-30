import 'package:equatable/equatable.dart';

import '../../../data/models/notification_model.dart';

abstract class NotificationState extends Equatable {
  const NotificationState();

  @override
  List<Object?> get props => [];
}

class NotificationInitial extends NotificationState {
  const NotificationInitial();
}

class NotificationLoading extends NotificationState {
  const NotificationLoading();
}

class NotificationLoaded extends NotificationState {
  final List<NotificationModel> notifications;
  final NotificationSettings settings;
  final int unreadCount;

  const NotificationLoaded({
    required this.notifications,
    required this.settings,
    required this.unreadCount,
  });

  @override
  List<Object?> get props => [notifications, settings, unreadCount];

  NotificationLoaded copyWith({
    List<NotificationModel>? notifications,
    NotificationSettings? settings,
    int? unreadCount,
  }) {
    return NotificationLoaded(
      notifications: notifications ?? this.notifications,
      settings: settings ?? this.settings,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}

class NotificationError extends NotificationState {
  final String message;

  const NotificationError(this.message);

  @override
  List<Object?> get props => [message];
}

class NotificationPermissionDenied extends NotificationState {
  const NotificationPermissionDenied();
}

class NotificationActionTriggered extends NotificationState {
  final NotificationModel notification;
  final String action;

  const NotificationActionTriggered({
    required this.notification,
    required this.action,
  });

  @override
  List<Object?> get props => [notification, action];
}