import 'package:supabase_flutter/supabase_flutter.dart';
import '../../home/models/post_model.dart';
import '../../home/models/profile_model.dart';

class SearchRepo {
  final _client = Supabase.instance.client;

  Future<List<PostModel>> fetchExplorePosts() async {
    final currentUserId = _client.auth.currentUser?.id;

    final data = await _client
        .from('posts')
        .select('*, profiles(*), post_media(*)')
        .eq('profiles.is_private', false)
        .order('created_at', ascending: false)
        .limit(60);

    final posts = (data as List)
        .where((e) {
          final profile = e['profiles'];
          if (profile == null) return false;
          final isPrivate = profile['is_private'] as bool? ?? false;
          return !isPrivate;
        })
        .map((e) => PostModel.fromJson(e as Map<String, dynamic>))
        .where((p) => p.media.isNotEmpty)
        .toList();

    if (currentUserId != null && posts.isNotEmpty) {
      final liked = await _client
          .from('likes')
          .select('target_id')
          .eq('user_id', currentUserId)
          .eq('target_type', 'post')
          .inFilter('target_id', posts.map((p) => p.id).toList());

      final likedIds = {
        for (final l in liked as List) l['target_id'] as String,
      };
      for (final post in posts) {
        post.isLiked = likedIds.contains(post.id);
      }
    }

    return posts;
  }

  Future<List<ProfileModel>> searchUsers(String query) async {
    if (query.trim().isEmpty) return [];

    final q = query.trim().toLowerCase();

    final data = await _client
        .from('profiles')
        .select()
        .or('username.ilike.%$q%,full_name.ilike.%$q%')
        .eq('is_private', false)
        .limit(30);

    return (data as List)
        .map((e) => ProfileModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
