import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/notification_service.dart';
import '../../home/models/profile_model.dart';
import '../../profile/repo/profile_repo.dart';
import '../repo/notifications_repo.dart';
import 'notifications_state.dart';

class NotificationsCubit extends Cubit<NotificationsState> {
  NotificationsCubit() : super(NotificationsInitial());

  final _repo = NotificationsRepo();
  final _profileRepo = ProfileRepo();
  RealtimeChannel? _subscription;
  ProfileModel? _currentProfile;

  Future<void> loadNotifications() async {
    emit(NotificationsLoading());
    try {
      _currentProfile = await _profileRepo.fetchCurrentProfile();
      final isPrivate = _currentProfile?.isPrivate ?? false;

      final notifications = await _repo.fetchNotifications();
      final unreadCount = notifications.where((n) => !n.isRead).length;
      emit(NotificationsSuccess(
        notifications: notifications,
        unreadCount: unreadCount,
        isCurrentUserPrivate: isPrivate,
      ));
      _subscribe();
    } catch (e) {
      emit(NotificationsFailure(e.toString()));
    }
  }

  void _subscribe() {
    _subscription?.unsubscribe();
    _subscription = _repo.subscribeToNotifications((row) async {
      final senderId = row['sender_id'] as String?;
      final currentUserId = Supabase.instance.client.auth.currentUser?.id;
      if (senderId == null || senderId == currentUserId) return;

      final type = row['type'] as String?;
      final targetType = row['target_type'] as String?;
      String body = 'New notification';
      String username = 'Someone';

      try {
        final profile = await _repo.fetchSenderProfile(senderId);
        if (profile != null) {
          username = profile['username'] as String? ?? 'Someone';
        }
      } catch (_) {}

      switch (type) {
        case 'follow':
          if (targetType == 'accept') {
            body = '$username accepted your follow request';
          } else {
            final isPrivate = _currentProfile?.isPrivate ?? false;
            body = isPrivate
                ? '$username sent you a friend request'
                : '$username started following you';
          }
          break;
        case 'like':
          body = '$username liked your post';
          break;
        case 'comment':
          body = '$username commented on your post';
          break;
        default:
          body = '$username sent you an update';
          break;
      }

      await NotificationService.showNotification(
        title: 'Aura',
        body: body,
      );

      // Reload notifications list silently to keep UI and unread count in sync
      try {
        final isPrivate = _currentProfile?.isPrivate ?? false;
        final notifications = await _repo.fetchNotifications();
        final unreadCount = notifications.where((n) => !n.isRead).length;
        emit(NotificationsSuccess(
          notifications: notifications,
          unreadCount: unreadCount,
          isCurrentUserPrivate: isPrivate,
        ));
      } catch (_) {}
    });
  }

  Future<void> acceptRequest(String senderId, String notificationId) async {
    final prevState = state;
    try {
      await _repo.acceptFollowRequest(followerId: senderId, notificationId: notificationId);
      // Reload list to refresh UI
      final isPrivate = _currentProfile?.isPrivate ?? false;
      final notifications = await _repo.fetchNotifications();
      final unreadCount = notifications.where((n) => !n.isRead).length;
      emit(NotificationsSuccess(
        notifications: notifications,
        unreadCount: unreadCount,
        isCurrentUserPrivate: isPrivate,
      ));
    } catch (e) {
      emit(NotificationsActionFailure(e.toString()));
      if (prevState is NotificationsSuccess) {
        emit(prevState);
      }
    }
  }

  Future<void> declineRequest(String notificationId) async {
    final prevState = state;
    try {
      await _repo.declineFollowRequest(notificationId: notificationId);
      // Reload list to refresh UI
      final isPrivate = _currentProfile?.isPrivate ?? false;
      final notifications = await _repo.fetchNotifications();
      final unreadCount = notifications.where((n) => !n.isRead).length;
      emit(NotificationsSuccess(
        notifications: notifications,
        unreadCount: unreadCount,
        isCurrentUserPrivate: isPrivate,
      ));
    } catch (e) {
      emit(NotificationsActionFailure(e.toString()));
      if (prevState is NotificationsSuccess) {
        emit(prevState);
      }
    }
  }

  Future<void> markAllAsRead() async {
    if (state is! NotificationsSuccess) return;
    final current = state as NotificationsSuccess;
    
    // Optimistic update
    final updated = current.notifications.map((n) => n.copyWith(isRead: true)).toList();
    emit(NotificationsSuccess(
      notifications: updated,
      unreadCount: 0,
      isCurrentUserPrivate: current.isCurrentUserPrivate,
    ));

    try {
      await _repo.markAllAsRead();
    } catch (_) {
      // Revert if API fails, reload from DB to sync up
      try {
        final notifications = await _repo.fetchNotifications();
        final unreadCount = notifications.where((n) => !n.isRead).length;
        emit(NotificationsSuccess(
          notifications: notifications,
          unreadCount: unreadCount,
          isCurrentUserPrivate: current.isCurrentUserPrivate,
        ));
      } catch (_) {}
    }
  }

  @override
  Future<void> close() {
    _subscription?.unsubscribe();
    return super.close();
  }
}
