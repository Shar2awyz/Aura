import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../home/models/post_model.dart';
import '../../home/widgets/post_card.dart';
import '../../post/repo/post_repo.dart';
import '../../comments/view/comments_sheet.dart';
import '../../home/repo/feed_repo.dart';

class PostDetailPage extends StatefulWidget {
  final String postId;

  const PostDetailPage({super.key, required this.postId});

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  final _postRepo = PostRepo();
  final _feedRepo = FeedRepo();
  PostModel? _post;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPost();
  }

  Future<void> _loadPost() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final post = await _postRepo.fetchPostById(widget.postId);
      if (mounted) {
        setState(() {
          _post = post;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
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
          'Post',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, color: AppColors.primary, size: 48),
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _loadPost,
              child: const Text('Retry', style: TextStyle(color: AppColors.primary)),
            ),
          ],
        ),
      );
    }
    if (_post == null) {
      return const Center(
        child: Text('Post not found', style: TextStyle(color: Colors.white70)),
      );
    }

    return SingleChildScrollView(
      child: PostCard(
        post: _post!,
        onLike: () async {
          final newLiked = !_post!.isLiked;
          setState(() {
            _post!.isLiked = newLiked;
            _post!.likesCount += newLiked ? 1 : -1;
          });
          try {
            await _feedRepo.toggleLike(
              postId: _post!.id,
              liked: newLiked,
              postOwnerId: _post!.userId,
            );
          } catch (_) {
            setState(() {
              _post!.isLiked = !newLiked;
              _post!.likesCount += newLiked ? -1 : 1;
            });
          }
        },
        onComment: () async {
          await CommentsSheet.show(context, _post!);
          setState(() {});
        },
        onSave: () async {
          final newSaved = !_post!.isSaved;
          setState(() {
            _post!.isSaved = newSaved;
          });
          try {
            await _feedRepo.toggleSave(postId: _post!.id, saved: newSaved);
          } catch (_) {
            setState(() {
              _post!.isSaved = !newSaved;
            });
          }
        },
      ),
    );
  }
}
