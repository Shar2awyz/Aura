import '../models/notification_model.dart';

abstract class NotificationsState {
  const NotificationsState();
}

class NotificationsInitial extends NotificationsState {}

class NotificationsLoading extends NotificationsState {}

class NotificationsSuccess extends NotificationsState {
  final List<NotificationModel> notifications;
  final int unreadCount;
  final bool isCurrentUserPrivate;

  const NotificationsSuccess({
    required this.notifications,
    required this.unreadCount,
    this.isCurrentUserPrivate = false,
  });

  NotificationsSuccess copyWith({
    List<NotificationModel>? notifications,
    int? unreadCount,
    bool? isCurrentUserPrivate,
  }) {
    return NotificationsSuccess(
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      isCurrentUserPrivate: isCurrentUserPrivate ?? this.isCurrentUserPrivate,
    );
  }
}

class NotificationsFailure extends NotificationsState {
  final String error;

  const NotificationsFailure(this.error);
}

class NotificationsActionFailure extends NotificationsState {
  final String error;

  const NotificationsActionFailure(this.error);
}
