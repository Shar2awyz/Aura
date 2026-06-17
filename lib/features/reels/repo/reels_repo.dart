import 'package:supabase_flutter/supabase_flutter.dart';
import '../../home/models/post_model.dart';

class ReelsRepo {
  final _client = Supabase.instance.client;

  Future<List<PostModel>> fetchReels() async {
    final currentUserId = _client.auth.currentUser?.id;

    final data = await _client
        .from('posts')
        .select('*, profiles(*), post_media(*)')
        .order('created_at', ascending: false)
        .limit(100);

    final posts = (data as List)
        .map((e) => PostModel.fromJson(e as Map<String, dynamic>))
        .where((p) => p.media.any((m) => m.mediaType == 'video'))
        .toList();

    if (currentUserId != null && posts.isNotEmpty) {
      final postIds = posts.map((p) => p.id).toList();

      final liked = await _client
          .from('likes')
          .select('target_id')
          .eq('user_id', currentUserId)
          .eq('target_type', 'post')
          .inFilter('target_id', postIds);

      final likedIds = {
        for (final l in liked as List) l['target_id'] as String,
      };

      try {
        final saved = await _client
            .from('saved_items')
            .select('target_id')
            .eq('user_id', currentUserId)
            .eq('target_type', 'post')
            .inFilter('target_id', postIds);

        final savedIds = {
          for (final s in saved as List) s['target_id'] as String,
        };
        for (final post in posts) {
          post.isLiked = likedIds.contains(post.id);
          post.isSaved = savedIds.contains(post.id);
        }
      } catch (_) {
        for (final post in posts) {
          post.isLiked = likedIds.contains(post.id);
        }
      }
    }

    return posts;
  }
}
