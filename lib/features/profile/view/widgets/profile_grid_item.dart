import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../home/models/post_model.dart';

class ProfileGridItem extends StatelessWidget {
  final PostModel post;
  final VoidCallback onTap;

  const ProfileGridItem({super.key, required this.post, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final firstMedia = post.media.isNotEmpty ? post.media.first : null;
    final isVideo = firstMedia?.mediaType == 'video';
    final hasMultiple = post.media.length > 1;

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ── Thumbnail ────────────────────────────────────────────────────────
          if (firstMedia != null)
            Image.network(
              firstMedia.mediaUrl,
              fit: BoxFit.cover,
              loadingBuilder: (_, child, prog) =>
                  prog == null ? child : _shimmer,
              errorBuilder: (_, _, _) => _shimmer,
            )
          else
            _shimmer,

          // ── Multi-image badge ─────────────────────────────────────────────
          if (hasMultiple)
            Positioned(
              top: 7,
              right: 7,
              child: Icon(
                Icons.layers_rounded,
                color: Colors.white,
                size: 18,
                shadows: [Shadow(blurRadius: 6, color: Colors.black54)],
              ),
            ),

          // ── Video play overlay ────────────────────────────────────────────
          if (isVideo)
            Center(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget get _shimmer => Container(color: AppColors.darkSurface);
}
