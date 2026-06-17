import 'package:flutter/material.dart';
import '../models/story_model.dart';
import 'story_circle.dart';

class StoryItem extends StatelessWidget {
  final StoryModel story;
  final VoidCallback onTap;
  // true = unviewed gradient ring; false = dimmed ring.
  // Supplied by the parent so a group of stories can be treated as one unit.
  final bool isActive;

  const StoryItem({
    super.key,
    required this.story,
    required this.onTap,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            StoryCircle(
              imageUrl: story.profile.avatarUrl,
              isActive: isActive,
            ),
            const SizedBox(height: 6),
            Text(
              story.profile.displayName,
              style: TextStyle(
                color: isActive
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.45),
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
