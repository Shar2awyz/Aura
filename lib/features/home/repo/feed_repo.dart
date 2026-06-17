import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/post_model.dart';
import '../models/profile_model.dart';
import '../models/story_model.dart';

class FeedRepo {
  final _client = Supabase.instance.client;

  Future<ProfileModel?> fetchCurrentUserProfile() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    final data = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (data == null) return null;
    return ProfileModel.fromJson(data);
  }

  Future<List<StoryModel>> fetchStories() async {
    final currentUserId = _client.auth.currentUser?.id;
    if (currentUserId == null) return [];

    // Fetch the IDs of users the current user follows
    final followingData = await _client
        .from('followers')
        .select('following_id')
        .eq('follower_id', currentUserId);

    final followingIds = (followingData as List)
        .map((e) => e['following_id'] as String)
        .toList();

    // Include the current user's own stories plus followed users' stories
    final userIds = [...followingIds, currentUserId];

    final data = await _client
        .from('stories')
        .select('*, profiles(*)')
        .gt('expires_at', DateTime.now().toUtc().toIso8601String())
        .inFilter('user_id', userIds)
        .order('created_at', ascending: false);

    final stories = (data as List)
        .map((e) => StoryModel.fromJson(e as Map<String, dynamic>))
        .toList();

    if (stories.isNotEmpty) {
      final viewed = await _client
          .from('story_views')
          .select('story_id')
          .eq('viewer_id', currentUserId)
          .inFilter('story_id', stories.map((s) => s.id).toList());

      final viewedIds = {
        for (final v in viewed as List) v['story_id'] as String,
      };
      return stories
          .map((s) => s.copyWith(isViewed: viewedIds.contains(s.id)))
          .toList();
    }

    return stories;
  }

  Future<List<PostModel>> fetchFeed() async {
    final currentUserId = _client.auth.currentUser?.id;

    final data = await _client
        .from('posts')
        .select('*, profiles(*), post_media(*)')
        .order('created_at', ascending: false)
        .limit(20);

    final posts = (data as List)
        .map((e) => PostModel.fromJson(e as Map<String, dynamic>))
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

  Future<List<PostModel>> fetchSavedPosts() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final data = await _client
        .from('saved_items')
        .select('posts:target_id(*, profiles(*), post_media(*))')
        .eq('user_id', userId)
        .eq('target_type', 'post')
        .order('created_at', ascending: false);

    return (data as List)
        .map((e) => e['posts'] as Map<String, dynamic>?)
        .where((e) => e != null)
        .map((e) => PostModel.fromJson(e!))
        .toList();
  }

  Future<void> markStoryViewed({required String storyId}) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    try {
      await _client.from('story_views').insert({
        'story_id': storyId,
        'viewer_id': userId,
      });
    } catch (_) {}
  }

  Future<void> uploadStory({
    required String mediaUrl,
    required String mediaType,
    String? caption,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    await _client.from('stories').insert({
      'user_id': userId,
      'media_url': mediaUrl,
      'media_type': mediaType,
      if (caption != null && caption.isNotEmpty) 'caption': caption,
    });
  }

  Future<void> toggleLike({
    required String postId,
    required bool liked,
    required String postOwnerId,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    if (liked) {
      await _client.from('likes').insert({
        'user_id': userId,
        'target_type': 'post',
        'target_id': postId,
      });

      // Insert like notification if the user liking is not the owner
      if (userId != postOwnerId) {
        await _client.from('notifications').insert({
          'receiver_id': postOwnerId,
          'sender_id': userId,
          'type': 'like',
          'target_type': 'post',
          'target_id': postId,
        }).catchError((e, s) {
          debugPrint('Error inserting like notification: $e\n$s');
          return <String, dynamic>{};
        });
      }
    } else {
      await _client
          .from('likes')
          .delete()
          .eq('user_id', userId)
          .eq('target_type', 'post')
          .eq('target_id', postId);

      // Delete the like notification if unliked
      if (userId != postOwnerId) {
        await _client
            .from('notifications')
            .delete()
            .eq('receiver_id', postOwnerId)
            .eq('sender_id', userId)
            .eq('type', 'like')
            .eq('target_id', postId)
            .catchError((_) => <String, dynamic>{});
      }
    }
  }

  Future<void> toggleSave({
    required String postId,
    required bool saved,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    if (saved) {
      await _client.from('saved_items').upsert({
        'user_id': userId,
        'target_type': 'post',
        'target_id': postId,
      });
    } else {
      await _client
          .from('saved_items')
          .delete()
          .eq('user_id', userId)
          .eq('target_type', 'post')
          .eq('target_id', postId);
    }
  }
}
