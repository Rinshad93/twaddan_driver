import 'package:equatable/equatable.dart';

import '../../../data/models/notification_model.dart';

abstract class NotificationEvent extends Equatable {
  const NotificationEvent();

  @override
  List<Object?> get props => [];
}

class NotificationInitialize extends NotificationEvent {
  const NotificationInitialize();
}

class NotificationReceived extends NotificationEvent {
  final NotificationModel notification;

  const NotificationReceived(this.notification);

  @override
  List<Object?> get props => [notification];
}

class NotificationTapped extends NotificationEvent {
  final NotificationModel notification;

  const NotificationTapped(this.notification);

  @override
  List<Object?> get props => [notification];
}

class NotificationMarkAsRead extends NotificationEvent {
  final String notificationId;

  const NotificationMarkAsRead(this.notificationId);

  @override
  List<Object?> get props => [notificationId];
}

class NotificationMarkAllAsRead extends NotificationEvent {
  const NotificationMarkAllAsRead();
}

class NotificationDelete extends NotificationEvent {
  final String notificationId;

  const NotificationDelete(this.notificationId);

  @override
  List<Object?> get props => [notificationId];
}

class NotificationClearAll extends NotificationEvent {
  const NotificationClearAll();
}

class NotificationSettingsUpdate extends NotificationEvent {
  final NotificationSettings settings;

  const NotificationSettingsUpdate(this.settings);

  @override
  List<Object?> get props => [settings];
}

class NotificationPermissionRequested extends NotificationEvent {
  const NotificationPermissionRequested();
}