import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_colors.dart';
import '../../post/view/post_detail_page.dart';
import '../../profile/view/view_profile_page.dart';
import '../models/notification_model.dart';
import '../viewmodel/notifications_cubit.dart';
import '../viewmodel/notifications_state.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  @override
  void initState() {
    super.initState();
    // Mark all notifications as read upon opening the screen
    context.read<NotificationsCubit>().markAllAsRead();
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8),
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.darkSurface,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.darkBorder, width: 0.5),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: BlocListener<NotificationsCubit, NotificationsState>(
        listenWhen: (previous, current) => current is NotificationsActionFailure,
        listener: (context, state) {
          if (state is NotificationsActionFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  state.error.contains('violates row-level security')
                      ? 'Database permission denied. Please run the RLS SQL script in your Supabase SQL Editor.'
                      : 'Action failed: ${state.error}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                ),
                backgroundColor: Colors.red.shade900.withValues(alpha: 0.95),
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        },
        child: RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: AppColors.darkSurface,
          onRefresh: () => context.read<NotificationsCubit>().loadNotifications(),
          child: BlocBuilder<NotificationsCubit, NotificationsState>(
            builder: (context, state) {
            if (state is NotificationsLoading || state is NotificationsInitial) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }
            if (state is NotificationsFailure) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: AppColors.primary,
                        size: 48,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        state.error,
                        style: const TextStyle(color: AppColors.textSubtleOnDark),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () => context.read<NotificationsCubit>().loadNotifications(),
                        child: const Text(
                          'Retry',
                          style: TextStyle(color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (state is NotificationsSuccess) {
              final notifications = state.notifications;
              if (notifications.isEmpty) {
                return _buildEmptyState();
              }

              return ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: notifications.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  return _NotificationTile(
                    notification: notifications[index],
                    timeAgo: _timeAgo(notifications[index].createdAt),
                    isCurrentUserPrivate: state.isCurrentUserPrivate,
                  );
                },
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    ),
  );
}

  Widget _buildEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.25),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.darkSurface,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.darkBorder, width: 0.5),
                ),
                child: const Icon(
                  Icons.notifications_none_rounded,
                  color: AppColors.primary,
                  size: 44,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'No Notifications Yet',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Likes, comments, and friend requests will appear here.',
                style: TextStyle(
                  color: AppColors.textSubtleOnDark,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final String timeAgo;
  final bool isCurrentUserPrivate;

  const _NotificationTile({
    required this.notification,
    required this.timeAgo,
    required this.isCurrentUserPrivate,
  });

  @override
  Widget build(BuildContext context) {
    final profile = notification.senderProfile;
    final username = profile?.username ?? 'Someone';
    final hasAvatar = profile?.avatarUrl != null && profile!.avatarUrl!.isNotEmpty;

    // Construct text message
    String actionText = '';
    IconData actionIcon = Icons.notifications;
    Color iconColor = AppColors.primary;

    switch (notification.type) {
      case 'follow':
        actionIcon = Icons.person_add_rounded;
        iconColor = const Color(0xFF00E5FF);
        if (notification.targetType == 'accept') {
          actionText = ' accepted your friend request.';
          actionIcon = Icons.person_outline_rounded;
          iconColor = const Color(0xFFA78BFA);
        } else if (notification.targetType == 'accepted') {
          actionText = ' sent you a friend request (Accepted).';
        } else {
          actionText = isCurrentUserPrivate
              ? ' sent you a friend request.'
              : ' started following you.';
        }
        break;
      case 'like':
        actionText = ' liked your post.';
        actionIcon = Icons.favorite_rounded;
        iconColor = const Color(0xFFFF5A5F);
        break;
      case 'comment':
        actionText = ' commented on your post.';
        actionIcon = Icons.chat_bubble_rounded;
        iconColor = const Color(0xFFA78BFA);
        break;
      default:
        actionText = ' performed an action.';
        actionIcon = Icons.star_rounded;
        iconColor = Colors.amber;
    }

    return InkWell(
      onTap: () => _handleTap(context),
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        decoration: BoxDecoration(
          color: AppColors.darkSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: notification.isRead ? AppColors.darkBorder : AppColors.primary.withValues(alpha: 0.3),
            width: 0.8,
          ),
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Sender Avatar with icon badge
            Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.darkBackground,
                  backgroundImage: hasAvatar ? NetworkImage(profile.avatarUrl!) : null,
                  child: !hasAvatar
                      ? const Icon(
                          Icons.person,
                          color: AppColors.primary,
                          size: 22,
                        )
                      : null,
                ),
                Positioned(
                  right: -4,
                  bottom: -4,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: AppColors.darkBackground,
                      shape: BoxShape.circle,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(1),
                      decoration: BoxDecoration(
                        color: iconColor.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        actionIcon,
                        color: iconColor,
                        size: 11,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 14),

            // Notification text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.white,
                        height: 1.35,
                      ),
                      children: [
                        TextSpan(
                          text: username,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                          text: actionText,
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    timeAgo,
                    style: const TextStyle(
                      color: AppColors.textSubtleOnDark,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),

            // Action Chevron or unread indicator or follow request buttons
            if (notification.type == 'follow' &&
                notification.targetType == null &&
                isCurrentUserPrivate)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () {
                      context.read<NotificationsCubit>().acceptRequest(
                            notification.senderId,
                            notification.id,
                          );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFA78BFA), Color(0xFF7C5FC8)],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Accept',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () {
                      context.read<NotificationsCubit>().declineRequest(
                            notification.id,
                          );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.darkBackground,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.darkBorder),
                      ),
                      child: const Text(
                        'Delete',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            else if (!notification.isRead)
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              )
            else
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSubtleOnDark,
                size: 18,
              ),
          ],
        ),
      ),
    );
  }

  void _handleTap(BuildContext context) {
    if (notification.type == 'follow') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ViewProfilePage(userId: notification.senderId),
        ),
      );
    } else if (notification.type == 'like' || notification.type == 'comment') {
      final targetId = notification.targetId;
      if (targetId != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PostDetailPage(postId: targetId),
          ),
        );
      }
    }
  }
}
