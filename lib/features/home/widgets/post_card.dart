import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../../core/theme/app_colors.dart';
import '../models/post_media_model.dart';
import '../models/post_model.dart';

class PostCard extends StatelessWidget {
  final PostModel post;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onSave;

  const PostCard({
    super.key,
    required this.post,
    required this.onLike,
    required this.onComment,
    required this.onSave,
  });

  static String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}k';
    return count.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.darkBorder, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PostHeader(post: post),
          if (post.media.isNotEmpty) _PostMediaView(media: post.media),
          if (post.caption != null && post.caption!.isNotEmpty)
            _PostCaption(caption: post.caption!),
          _PostActions(
            post: post,
            onLike: onLike,
            onComment: onComment,
            onSave: onSave,
            formatCount: _formatCount,
          ),
        ],
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _PostHeader extends StatelessWidget {
  final PostModel post;

  const _PostHeader({required this.post});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.darkBackground,
            backgroundImage: post.profile.avatarUrl != null
                ? NetworkImage(post.profile.avatarUrl!)
                : null,
            child: post.profile.avatarUrl == null
                ? const Icon(Icons.person, color: AppColors.primary, size: 18)
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      post.profile.displayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (post.profile.isVerified) ...[
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.verified,
                        color: AppColors.primary,
                        size: 14,
                      ),
                    ],
                  ],
                ),
                if (post.location != null && post.location!.isNotEmpty)
                  Text(
                    post.location!,
                    style: const TextStyle(
                      color: AppColors.textSubtleOnDark,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          const Icon(Icons.more_horiz, color: AppColors.textSubtleOnDark),
        ],
      ),
    );
  }
}

// ── Media (single or multi-page) ─────────────────────────────────────────────

class _PostMediaView extends StatefulWidget {
  final List<PostMediaModel> media;

  const _PostMediaView({required this.media});

  @override
  State<_PostMediaView> createState() => _PostMediaViewState();
}

class _PostMediaViewState extends State<_PostMediaView> {
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    final isSingle = widget.media.length == 1;
    final first = widget.media.first;
    final ratio = first.aspectRatio > 0 ? first.aspectRatio : 1.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: AspectRatio(
              aspectRatio: ratio,
              child: isSingle
                  ? _MediaItem(media: first)
                  : PageView.builder(
                      onPageChanged: (i) => setState(() => _currentPage = i),
                      itemCount: widget.media.length,
                      itemBuilder: (_, i) =>
                          _MediaItem(media: widget.media[i]),
                    ),
            ),
          ),
          if (!isSingle) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.media.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == _currentPage ? 14 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: i == _currentPage
                        ? AppColors.primary
                        : Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MediaItem extends StatelessWidget {
  final PostMediaModel media;

  const _MediaItem({required this.media});

  @override
  Widget build(BuildContext context) {
    if (media.mediaType == 'video') {
      return FeedVideoPlayer(videoUrl: media.mediaUrl);
    }

    return Image.network(
      media.mediaUrl,
      fit: BoxFit.cover,
      loadingBuilder: (_, child, progress) {
        if (progress == null) return child;
        return Container(
          color: AppColors.darkBackground,
          child: const Center(
            child: CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 2,
            ),
          ),
        );
      },
      errorBuilder: (_, _, _) => Container(
        color: AppColors.darkBackground,
        child: const Center(
          child: Icon(
            Icons.broken_image_outlined,
            color: AppColors.primary,
            size: 40,
          ),
        ),
      ),
    );
  }
}

class FeedVideoPlayer extends StatefulWidget {
  final String videoUrl;
  const FeedVideoPlayer({super.key, required this.videoUrl});

  @override
  State<FeedVideoPlayer> createState() => _FeedVideoPlayerState();
}

class _FeedVideoPlayerState extends State<FeedVideoPlayer> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _isMuted = true;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() => _isInitialized = true);
        _controller.setLooping(true);
        _controller.setVolume(_isMuted ? 0.0 : 1.0);
        _controller.play();
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlay() {
    if (!_isMuted) {
      // Small user interaction helper: toggle playing
    }
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
      } else {
        _controller.play();
      }
    });
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
      _controller.setVolume(_isMuted ? 0.0 : 1.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Container(
        color: AppColors.darkBackground,
        child: const Center(
          child: CircularProgressIndicator(
            color: AppColors.primary,
            strokeWidth: 2,
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: _togglePlay,
      child: Stack(
        fit: StackFit.expand,
        children: [
          FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: _controller.value.size.width,
              height: _controller.value.size.height,
              child: VideoPlayer(_controller),
            ),
          ),
          if (!_controller.value.isPlaying)
            Center(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withValues(alpha: 0.5),
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 36,
                ),
              ),
            ),
          Positioned(
            right: 12,
            bottom: 12,
            child: GestureDetector(
              onTap: _toggleMute,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withValues(alpha: 0.6),
                ),
                child: Icon(
                  _isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Actions ───────────────────────────────────────────────────────────────────

class _PostActions extends StatelessWidget {
  final PostModel post;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onSave;
  final String Function(int) formatCount;

  const _PostActions({
    required this.post,
    required this.onLike,
    required this.onComment,
    required this.onSave,
    required this.formatCount,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: onLike,
            child: Row(
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    post.isLiked ? Icons.favorite : Icons.favorite_border,
                    key: ValueKey(post.isLiked),
                    color: post.isLiked ? const Color(0xFFFF5A5F) : Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  formatCount(post.likesCount),
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          GestureDetector(
            onTap: onComment,
            child: Row(
              children: [
                const Icon(
                  Icons.chat_bubble_outline,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 5),
                Text(
                  formatCount(post.commentsCount),
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ],
            ),
          ),
          const Spacer(),
          const Icon(Icons.send_outlined, color: Colors.white, size: 22),
          const SizedBox(width: 16),
          GestureDetector(
            onTap: onSave,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                post.isSaved ? Icons.bookmark : Icons.bookmark_border,
                key: ValueKey(post.isSaved),
                color: post.isSaved ? AppColors.primary : Colors.white,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Caption ───────────────────────────────────────────────────────────────────

class _PostCaption extends StatelessWidget {
  final String caption;

  const _PostCaption({required this.caption});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      child: Text(
        caption,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          height: 1.4,
        ),
      ),
    );
  }
}
