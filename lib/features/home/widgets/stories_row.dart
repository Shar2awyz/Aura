import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_colors.dart';
import '../models/profile_model.dart';
import '../models/story_model.dart';
import '../view/story_upload_page.dart';
import '../view/story_viewer_page.dart';
import '../viewmodel/feed_cubit.dart';
import 'story_circle.dart';
import 'story_item.dart';

class StoriesRow extends StatelessWidget {
  final List<StoryModel> stories;
  final ProfileModel? currentUserProfile;

  const StoriesRow({
    super.key,
    required this.stories,
    this.currentUserProfile,
  });

  @override
  Widget build(BuildContext context) {
    // Group stories by userId, preserving first-appearance order.
    final Map<String, List<StoryModel>> grouped = {};
    for (final story in stories) {
      (grouped[story.userId] ??= []).add(story);
    }
    final groups = grouped.values.toList();

    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: groups.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _YourAuraItem(profile: currentUserProfile);
          }
          final userStories = groups[index - 1];
          final hasUnviewed = userStories.any((s) => !s.isViewed);
          return StoryItem(
            story: userStories.first,
            isActive: hasUnviewed,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => StoryViewerPage(
                  stories: userStories,
                  initialIndex: 0,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _YourAuraItem extends StatelessWidget {
  final ProfileModel? profile;

  const _YourAuraItem({this.profile});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
          final feedCubit = context.read<FeedCubit>();
          Navigator.push(
            context,
            MaterialPageRoute(
              fullscreenDialog: true,
              builder: (_) => StoryUploadPage(feedCubit: feedCubit),
            ),
          );
        },
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                StoryCircle(imageUrl: profile?.avatarUrl, isActive: true),
                Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primaryDark,
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 14),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Your Aura',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w400,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
