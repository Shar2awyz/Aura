import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../home/models/profile_model.dart';
import '../viewmodel/followers_following_cubit.dart';
import 'view_profile_page.dart';
import 'profile_page.dart';

class FollowersPage extends StatelessWidget {
  final String userId;
  const FollowersPage({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => FollowersFollowingCubit()..loadFollowers(userId),
      child: const _FollowersBody(),
    );
  }
}

class _FollowersBody extends StatelessWidget {
  const _FollowersBody();

  Future<bool> _showConfirmationDialog(BuildContext context, String username) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkSurface,
        title: const Text('Unfollow User', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          'Are you sure you want to remove @$username?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Unfollow',
              style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkBackground,
        title: const Text('Followers', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: BlocBuilder<FollowersFollowingCubit, FollowersFollowingState>(
        builder: (context, state) {
          if (state is FollowersFollowingLoading) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          if (state is FollowersFollowingFailure) {
            return Center(child: Text(state.error, style: const TextStyle(color: Colors.white)));
          }
          if (state is FollowersFollowingSuccess) {
            final items = state.items;
            if (items.isEmpty) {
              return const Center(child: Text('No followers', style: TextStyle(color: Colors.white70)));
            }
            return ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final profile = item['profile'] as ProfileModel;
                final isFollowing = item['isFollowing'] as bool;
                final isFollower = item['isFollower'] as bool;
                final isSelf = profile.id == currentUserId;

                // Determine relationship label
                String relationshipLabel = '';
                if (isFollowing) {
                  relationshipLabel = isFollower ? 'Friends' : 'Following';
                } else {
                  relationshipLabel = isFollower ? 'Follow Back' : 'Follow';
                }

                return ListTile(
                  onTap: () {
                    if (isSelf) {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ProfilePage()),
                      );
                    } else {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => ViewProfilePage(userId: profile.id)),
                      );
                    }
                  },
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: CircleAvatar(
                    radius: 24,
                    backgroundImage: profile.avatarUrl != null ? NetworkImage(profile.avatarUrl!) : null,
                    child: profile.avatarUrl == null ? const Icon(Icons.person, color: Colors.white) : null,
                  ),
                  title: Text(profile.displayName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  subtitle: Text('@${profile.username}', style: const TextStyle(color: Colors.white60)),
                  trailing: isSelf
                      ? null
                      : InkWell(
                          onTap: () async {
                            if (isFollowing) {
                              final confirmed = await _showConfirmationDialog(context, profile.username);
                              if (confirmed && context.mounted) {
                                context.read<FollowersFollowingCubit>().toggleFollow(profile.id, true);
                              }
                            } else {
                              context.read<FollowersFollowingCubit>().toggleFollow(profile.id, false);
                            }
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: isFollowing
                                  ? (relationshipLabel == 'Friends'
                                      ? AppColors.primary.withValues(alpha: 0.15)
                                      : AppColors.darkSurface)
                                  : AppColors.primary,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isFollowing
                                    ? (relationshipLabel == 'Friends'
                                        ? AppColors.primary.withValues(alpha: 0.3)
                                        : AppColors.darkBorder)
                                    : Colors.transparent,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              relationshipLabel,
                              style: TextStyle(
                                color: isFollowing
                                    ? (relationshipLabel == 'Friends'
                                        ? AppColors.primary
                                        : Colors.white70)
                                    : Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                );
              },
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
