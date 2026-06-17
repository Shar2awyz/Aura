import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../home/models/post_model.dart';
import 'profile_grid_item.dart';

class ProfilePostsGrid extends StatelessWidget {
  final List<PostModel> posts;
  final String storageKey;
  final void Function(int index)? onPostTap;
  final String emptyMessage;
  final IconData emptyIcon;

  const ProfilePostsGrid({
    super.key,
    required this.posts,
    this.storageKey = 'profile_grid',
    this.onPostTap,
    this.emptyMessage = 'No posts yet',
    this.emptyIcon = Icons.photo_library_outlined,
  });

  @override
  Widget build(BuildContext context) {
    if (posts.isEmpty) {
      return CustomScrollView(
        key: PageStorageKey<String>(storageKey),
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    emptyIcon,
                    size: 56,
                    color: AppColors.textSubtleOnDark.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    emptyMessage,
                    style: const TextStyle(
                      color: AppColors.textSubtleOnDark,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return GridView.builder(
      key: PageStorageKey<String>(storageKey),
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: posts.length,
      itemBuilder: (context, index) => ProfileGridItem(
        post: posts[index],
        onTap: () => onPostTap?.call(index),
      ),
    );
  }
}
