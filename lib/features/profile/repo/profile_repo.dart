import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../home/models/post_model.dart';
import '../../home/models/profile_model.dart';

class ProfileRepo {
  final _client = Supabase.instance.client;

  Future<ProfileModel?> fetchCurrentProfile() async {
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

  Future<ProfileModel?> fetchProfile(String userId) async {
    final data = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (data == null) return null;
    return ProfileModel.fromJson(data);
  }

  Future<List<PostModel>> fetchUserPosts(String userId) async {
    final currentUserId = _client.auth.currentUser?.id;

    final data = await _client
        .from('posts')
        .select('*, profiles(*), post_media(*)')
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    final posts = (data as List)
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

  Future<List<PostModel>> fetchSavedPosts() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final data = await _client
        .from('saved_items')
        .select('posts:target_id(*, profiles(*), post_media(*))')
        .eq('user_id', userId)
        .eq('target_type', 'post')
        .order('created_at', ascending: false);

    final posts = (data as List)
        .map((e) => e['posts'] as Map<String, dynamic>?)
        .where((e) => e != null)
        .map((e) {
          final post = PostModel.fromJson(e!);
          post.isSaved = true;
          return post;
        })
        .toList();

    if (posts.isNotEmpty) {
      final liked = await _client
          .from('likes')
          .select('target_id')
          .eq('user_id', userId)
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

  // ── Followers / Following ────────────────────────────────────────────────
  Future<List<ProfileModel>> fetchFollowers(String userId) async {
    // Get follower IDs where the target user is being followed
    final data = await _client
        .from('followers')
        .select('follower_id')
        .eq('following_id', userId);
    final ids = (data as List).map((e) => e['follower_id'] as String).toList();
    if (ids.isEmpty) return [];
    // Fetch profiles for each id
    final profilesData = await _client
        .from('profiles')
        .select()
        .inFilter('id', ids);
    return (profilesData as List)
        .map((e) => ProfileModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<ProfileModel>> fetchFollowing(String userId) async {
    // Get following IDs where the user follows others
    final data = await _client
        .from('followers')
        .select('following_id')
        .eq('follower_id', userId);
    final ids = (data as List).map((e) => e['following_id'] as String).toList();
    if (ids.isEmpty) return [];
    final profilesData = await _client
        .from('profiles')
        .select()
        .inFilter('id', ids);
    return (profilesData as List)
        .map((e) => ProfileModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Map<String, dynamic>>> fetchFollowersWithRelation(String targetUserId) async {
    final currentUserId = _client.auth.currentUser?.id;
    if (currentUserId == null) return [];

    final followersList = await fetchFollowers(targetUserId);
    if (followersList.isEmpty) return [];

    final userIds = followersList.map((e) => e.id).toList();

    final followingData = await _client
        .from('followers')
        .select('following_id')
        .eq('follower_id', currentUserId)
        .inFilter('following_id', userIds);

    final followersData = await _client
        .from('followers')
        .select('follower_id')
        .eq('following_id', currentUserId)
        .inFilter('follower_id', userIds);

    final followingSet = (followingData as List).map((e) => e['following_id'] as String).toSet();
    final followersSet = (followersData as List).map((e) => e['follower_id'] as String).toSet();

    return followersList.map((profile) {
      final isFollowing = followingSet.contains(profile.id);
      final isFollower = followersSet.contains(profile.id);
      return {
        'profile': profile,
        'isFollowing': isFollowing,
        'isFollower': isFollower,
      };
    }).toList();
  }

  Future<List<Map<String, dynamic>>> fetchFollowingWithRelation(String targetUserId) async {
    final currentUserId = _client.auth.currentUser?.id;
    if (currentUserId == null) return [];

    final followingList = await fetchFollowing(targetUserId);
    if (followingList.isEmpty) return [];

    final userIds = followingList.map((e) => e.id).toList();

    final followingData = await _client
        .from('followers')
        .select('following_id')
        .eq('follower_id', currentUserId)
        .inFilter('following_id', userIds);

    final followersData = await _client
        .from('followers')
        .select('follower_id')
        .eq('following_id', currentUserId)
        .inFilter('follower_id', userIds);

    final followingSet = (followingData as List).map((e) => e['following_id'] as String).toSet();
    final followersSet = (followersData as List).map((e) => e['follower_id'] as String).toSet();

    return followingList.map((profile) {
      final isFollowing = followingSet.contains(profile.id);
      final isFollower = followersSet.contains(profile.id);
      return {
        'profile': profile,
        'isFollowing': isFollowing,
        'isFollower': isFollower,
      };
    }).toList();
  }


  // ── Follow ────────────────────────────────────────────────────────────────

  Future<bool> checkIsFollowing(String targetUserId) async {
    final currentUserId = _client.auth.currentUser?.id;
    if (currentUserId == null) return false;

    final data = await _client
        .from('followers')
        .select('id')
        .eq('follower_id', currentUserId)
        .eq('following_id', targetUserId)
        .maybeSingle();

    return data != null;
  }

  Future<bool> checkHasPendingRequest(String targetUserId) async {
    final currentUserId = _client.auth.currentUser?.id;
    if (currentUserId == null) return false;

    final data = await _client
        .from('notifications')
        .select('id')
        .eq('receiver_id', targetUserId)
        .eq('sender_id', currentUserId)
        .eq('type', 'follow')
        .isFilter('target_type', null)
        .maybeSingle();

    return data != null;
  }

  Future<void> followUser(String targetUserId) async {
    final currentUserId = _client.auth.currentUser?.id;
    if (currentUserId == null) return;

    try {
      final targetProfile = await fetchProfile(targetUserId);
      final isPrivate = targetProfile?.isPrivate ?? false;

      if (isPrivate) {
        // If private, only insert the follow request notification (do not follow directly yet)
        await _client.from('notifications').insert({
          'receiver_id': targetUserId,
          'sender_id': currentUserId,
          'type': 'follow',
        });
      } else {
        // If public, follow directly
        await _client.from('followers').insert({
          'follower_id': currentUserId,
          'following_id': targetUserId,
        });

        await _adjustCount(userId: targetUserId, column: 'followers_count', delta: 1);
        await _adjustCount(userId: currentUserId, column: 'following_count', delta: 1);

        // Insert follow notification
        await _client.from('notifications').insert({
          'receiver_id': targetUserId,
          'sender_id': currentUserId,
          'type': 'follow',
        }).catchError((e, s) {
          debugPrint('Error inserting follow notification for public follow: $e\n$s');
          return <String, dynamic>{};
        });
      }
    } catch (e, s) {
      debugPrint('Error in followUser: $e\n$s');
      rethrow;
    }
  }

  Future<void> unfollowUser(String targetUserId) async {
    final currentUserId = _client.auth.currentUser?.id;
    if (currentUserId == null) return;

    try {
      final wasFollowing = await checkIsFollowing(targetUserId);

      await _client
          .from('followers')
          .delete()
          .eq('follower_id', currentUserId)
          .eq('following_id', targetUserId);

      // Also delete any pending follow request notifications
      await _client
          .from('notifications')
          .delete()
          .eq('receiver_id', targetUserId)
          .eq('sender_id', currentUserId)
          .eq('type', 'follow')
          .isFilter('target_type', null);

      if (wasFollowing) {
        await _adjustCount(userId: targetUserId, column: 'followers_count', delta: -1);
        await _adjustCount(userId: currentUserId, column: 'following_count', delta: -1);
      }
    } catch (e, s) {
      debugPrint('Error in unfollowUser: $e\n$s');
      rethrow;
    }
  }

  Future<void> _adjustCount({
    required String userId,
    required String column,
    required int delta,
  }) async {
    try {
      final row = await _client
          .from('profiles')
          .select(column)
          .eq('id', userId)
          .single();
      final current = (row[column] as int?) ?? 0;
      final updated = (current + delta).clamp(0, 999999999);
      await _client.from('profiles').update({column: updated}).eq('id', userId);
    } catch (e, s) {
      debugPrint('Error in _adjustCount for profile $userId: $e\n$s');
    }
  }
  // New method to update user profile
  Future<void> updateUserProfile({
    String? name,
    String? username,
    String? email,
    String? password,
    File? picture,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    final updates = <String, dynamic>{};
    if (name != null) updates['full_name'] = name;
    if (username != null) updates['username'] = username;
    if (updates.isNotEmpty) {
      await _client.from('profiles').update(updates).eq('id', userId);
    }
    if (email != null) {
      await _client.auth.updateUser(UserAttributes(email: email));
    }
    if (password != null) {
      await _client.auth.updateUser(UserAttributes(password: password));
    }
    if (picture != null) {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${picture.path.split(RegExp(r"[/\\]")).last}';
      await _client.storage.from('profile-pictures').upload(fileName, picture);
      final publicUrl = _client.storage.from('profile-pictures').getPublicUrl(fileName);
      await _client.from('profiles').update({'avatar_url': publicUrl}).eq('id', userId);
    }
  }

  Future<void> toggleProfilePrivacy(bool isPrivate) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    await _client.from('profiles').update({'is_private': isPrivate}).eq('id', userId);
  }
}
