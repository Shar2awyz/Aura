import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:video_player/video_player.dart';
import '../../../core/theme/app_colors.dart';
import '../../comments/view/comments_sheet.dart';
import '../../home/models/post_model.dart';
import '../repo/reels_repo.dart';
import '../viewmodel/reels_cubit.dart';
import '../viewmodel/reels_state.dart';

class ReelsPage extends StatelessWidget {
  const ReelsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ReelsCubit(ReelsRepo())..loadReels(),
      child: const _ReelsView(),
    );
  }
}

class _ReelsView extends StatelessWidget {
  const _ReelsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          BlocBuilder<ReelsCubit, ReelsState>(
            builder: (context, state) {
              if (state is ReelsLoading || state is ReelsInitial) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                );
              }
              if (state is ReelsError) {
                return const Center(
                  child: Text(
                    'Could not load reels',
                    style: TextStyle(color: Colors.white70),
                  ),
                );
              }
              if (state is ReelsLoaded) {
                if (state.reels.isEmpty) return const _EmptyState();
                return _ReelsFeed(reels: state.reels);
              }
              return const SizedBox();
            },
          ),
          // Floating "For You" header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black87, Colors.transparent],
                ),
              ),
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 12,
                bottom: 20,
                left: 20,
                right: 20,
              ),
              child: const Text(
                'For You',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.video_library_outlined,
            size: 72,
            color: AppColors.textSubtleOnDark,
          ),
          const SizedBox(height: 20),
          const Text(
            'Add Yours',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Be the first to share a reel',
            style: TextStyle(
              color: AppColors.textSubtleOnDark,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReelsFeed extends StatefulWidget {
  final List<PostModel> reels;

  const _ReelsFeed({required this.reels});

  @override
  State<_ReelsFeed> createState() => _ReelsFeedState();
}

class _ReelsFeedState extends State<_ReelsFeed> {
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      scrollDirection: Axis.vertical,
      itemCount: widget.reels.length,
      onPageChanged: (index) => setState(() => _currentPage = index),
      itemBuilder: (context, index) => _ReelItem(
        post: widget.reels[index],
        isActive: index == _currentPage,
      ),
    );
  }
}

class _ReelItem extends StatefulWidget {
  final PostModel post;
  final bool isActive;

  const _ReelItem({required this.post, required this.isActive});

  @override
  State<_ReelItem> createState() => _ReelItemState();
}

class _ReelItemState extends State<_ReelItem> {
  VideoPlayerController? _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    final videoMedia =
        widget.post.media.where((m) => m.mediaType == 'video').firstOrNull;
    if (videoMedia != null) {
      _controller =
          VideoPlayerController.networkUrl(Uri.parse(videoMedia.mediaUrl))
            ..initialize().then((_) {
              if (!mounted) return;
              setState(() => _initialized = true);
              _controller!.setLooping(true);
              if (widget.isActive) _controller!.play();
            });
    }
  }

  @override
  void didUpdateWidget(_ReelItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive == oldWidget.isActive) return;
    if (widget.isActive) {
      _controller?.play();
    } else {
      _controller?.pause();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return GestureDetector(
      onTap: () {
        if (_controller == null) return;
        if (_controller!.value.isPlaying) {
          _controller!.pause();
        } else {
          _controller!.play();
        }
        setState(() {});
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Video / background
          if (_initialized && _controller != null)
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _controller!.value.size.width,
                height: _controller!.value.size.height,
                child: VideoPlayer(_controller!),
              ),
            )
          else
            Container(color: Colors.black),

          // Loading spinner
          if (!_initialized && _controller != null)
            const Center(
              child: CircularProgressIndicator(
                color: Colors.white54,
                strokeWidth: 2,
              ),
            ),

          // Pause icon flash
          if (_initialized &&
              _controller != null &&
              !_controller!.value.isPlaying)
            const Center(
              child: Icon(
                Icons.play_arrow_rounded,
                color: Colors.white54,
                size: 64,
              ),
            ),

          // Bottom gradient
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 280,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black87, Colors.transparent],
                ),
              ),
            ),
          ),

          // User info + caption
          Positioned(
            left: 16,
            right: 80,
            bottom: bottomPad + 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    if (widget.post.profile.avatarUrl != null)
                      CircleAvatar(
                        radius: 18,
                        backgroundImage:
                            NetworkImage(widget.post.profile.avatarUrl!),
                      )
                    else
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.3),
                        child: const Icon(
                          Icons.person,
                          color: AppColors.primary,
                          size: 18,
                        ),
                      ),
                    const SizedBox(width: 8),
                    Text(
                      '@${widget.post.profile.username}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                if (widget.post.caption != null &&
                    widget.post.caption!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      widget.post.caption!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),

          // Right action buttons
          Positioned(
            right: 12,
            bottom: bottomPad + 32,
            child: Column(
              children: [
                GestureDetector(
                  onTap: () {
                    context.read<ReelsCubit>().toggleLike(widget.post.id);
                  },
                  child: _ActionButton(
                    icon: widget.post.isLiked
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    label: _fmt(widget.post.likesCount),
                    color: widget.post.isLiked
                        ? const Color(0xFFFF4D6D)
                        : Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: () async {
                    await CommentsSheet.show(context, widget.post);
                    if (mounted) setState(() {});
                  },
                  child: _ActionButton(
                    icon: Icons.chat_bubble_outline_rounded,
                    label: _fmt(widget.post.commentsCount),
                  ),
                ),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: () {
                    context.read<ReelsCubit>().toggleSave(widget.post.id);
                  },
                  child: _ActionButton(
                    icon: widget.post.isSaved
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                    label: '',
                    color: widget.post.isSaved
                        ? AppColors.primary
                        : Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                const _ActionButton(
                  icon: Icons.share_rounded,
                  label: '',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n > 0 ? n.toString() : '';
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _ActionButton({
    required this.icon,
    required this.label,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 30),
        if (label.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}
