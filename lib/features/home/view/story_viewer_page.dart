import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';
import '../../../core/theme/app_colors.dart';
import '../models/story_model.dart';
import '../repo/feed_repo.dart';

class StoryViewerPage extends StatefulWidget {
  final List<StoryModel> stories;
  final int initialIndex;

  const StoryViewerPage({
    super.key,
    required this.stories,
    required this.initialIndex,
  });

  @override
  State<StoryViewerPage> createState() => _StoryViewerPageState();
}

class _StoryViewerPageState extends State<StoryViewerPage>
    with SingleTickerProviderStateMixin {
  late int _currentIndex;
  late AnimationController _progressController;
  VideoPlayerController? _videoController;
  bool _videoReady = false;
  final _repo = FeedRepo();

  static const _imageDuration = Duration(seconds: 5);

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _progressController = AnimationController(vsync: this);
    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed) _next();
    });
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _loadCurrent();
  }

  @override
  void dispose() {
    _progressController.dispose();
    _videoController?.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  StoryModel get _current => widget.stories[_currentIndex];

  Future<void> _loadCurrent() async {
    _progressController.reset();
    final old = _videoController;
    _videoController = null;
    _videoReady = false;
    if (mounted) setState(() {});
    old?.dispose();

    _markViewed();

    if (_current.mediaType == 'video') {
      await _initVideo();
    } else {
      if (!mounted) return;
      _progressController.duration = _imageDuration;
      _progressController.forward();
    }
  }

  Future<void> _initVideo() async {
    final url = _current.mediaUrl;
    final controller = VideoPlayerController.networkUrl(Uri.parse(url));
    _videoController = controller;
    try {
      await controller.initialize();
      if (!mounted || _videoController != controller) {
        controller.dispose();
        return;
      }
      final duration = controller.value.duration;
      _progressController.duration =
          duration > Duration.zero ? duration : _imageDuration;
      controller.play();
      setState(() => _videoReady = true);
      _progressController.forward();
    } catch (_) {
      if (!mounted || _videoController != controller) return;
      _progressController.duration = _imageDuration;
      _progressController.forward();
      setState(() {});
    }
  }

  void _markViewed() {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null || _current.userId == userId) return;
    _repo.markStoryViewed(storyId: _current.id);
  }

  void _next() {
    if (_currentIndex < widget.stories.length - 1) {
      setState(() => _currentIndex++);
      _loadCurrent();
    } else {
      Navigator.pop(context);
    }
  }

  void _prev() {
    if (_currentIndex > 0) {
      setState(() => _currentIndex--);
      _loadCurrent();
    } else {
      Navigator.pop(context);
    }
  }

  void _pause() {
    _videoController?.pause();
    _progressController.stop();
  }

  void _resume() {
    _videoController?.play();
    _progressController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapUp: (details) {
          final half = MediaQuery.of(context).size.width / 2;
          if (details.globalPosition.dx < half) {
            _prev();
          } else {
            _next();
          }
        },
        onLongPressStart: (_) => _pause(),
        onLongPressEnd: (_) => _resume(),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildMedia(),
            _buildTopGradient(context),
            _buildProgressBars(context),
            _buildUserInfo(context),
            _buildCloseButton(context),
            if (_current.caption?.isNotEmpty == true)
              _buildCaption(context),
          ],
        ),
      ),
    );
  }

  Widget _buildMedia() {
    final story = _current;
    if (story.mediaType == 'video') {
      if (_videoReady && _videoController != null) {
        return SizedBox.expand(
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: _videoController!.value.size.width,
              height: _videoController!.value.size.height,
              child: VideoPlayer(_videoController!),
            ),
          ),
        );
      }
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }
    return Image.network(
      story.mediaUrl,
      fit: BoxFit.cover,
      loadingBuilder: (_, child, progress) =>
          progress == null ? child : const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
      errorBuilder: (_, _, _) => const Center(
        child: Icon(Icons.broken_image, color: Colors.white30, size: 80),
      ),
    );
  }

  Widget _buildTopGradient(BuildContext context) {
    return Positioned(
      top: 0, left: 0, right: 0,
      height: MediaQuery.of(context).padding.top + 100,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black54, Colors.transparent],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBars(BuildContext context) {
    final top = MediaQuery.of(context).padding.top + 8;
    return Positioned(
      top: top, left: 8, right: 8,
      child: Row(
        children: List.generate(widget.stories.length, (i) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: i < _currentIndex
                    ? const _SegmentBar(value: 1)
                    : i == _currentIndex
                        ? AnimatedBuilder(
                            animation: _progressController,
                            builder: (_, _) => _SegmentBar(
                              value: _progressController.value,
                            ),
                          )
                        : const _SegmentBar(value: 0),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildUserInfo(BuildContext context) {
    final story = _current;
    final top = MediaQuery.of(context).padding.top + 22;
    return Positioned(
      top: top, left: 12, right: 56,
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.darkSurface,
            backgroundImage: story.profile.avatarUrl != null
                ? NetworkImage(story.profile.avatarUrl!)
                : null,
            child: story.profile.avatarUrl == null
                ? const Icon(Icons.person, color: Colors.white, size: 18)
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  story.profile.displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    shadows: [Shadow(blurRadius: 4, color: Colors.black45)],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _timeAgo(story.createdAt),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCloseButton(BuildContext context) {
    final top = MediaQuery.of(context).padding.top + 10;
    return Positioned(
      top: top, right: 4,
      child: IconButton(
        icon: const Icon(Icons.close, color: Colors.white, size: 26),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildCaption(BuildContext context) {
    return Positioned(
      bottom: MediaQuery.of(context).padding.bottom + 24,
      left: 16, right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          _current.caption!,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class _SegmentBar extends StatelessWidget {
  final double value;
  const _SegmentBar({required this.value});

  @override
  Widget build(BuildContext context) {
    return LinearProgressIndicator(
      value: value,
      minHeight: 2.5,
      backgroundColor: Colors.white30,
      valueColor: const AlwaysStoppedAnimation(Colors.white),
    );
  }
}
