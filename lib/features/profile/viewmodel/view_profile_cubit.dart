import 'package:flutter_bloc/flutter_bloc.dart';
import '../../home/models/post_model.dart';
import '../../home/models/profile_model.dart';
import '../../home/repo/feed_repo.dart';
import '../repo/profile_repo.dart';
import 'view_profile_state.dart';

class ViewProfileCubit extends Cubit<ViewProfileState> {
  ViewProfileCubit() : super(const ViewProfileInitial());

  final _repo = ProfileRepo();
  final _feedRepo = FeedRepo();

  Future<void> loadProfile(String userId) async {
    emit(const ViewProfileLoading());
    try {
      final ProfileModel? profile = await _repo.fetchProfile(userId);
      if (profile == null) {
        emit(const ViewProfileFailure('Profile not found'));
        return;
      }
      final results = await Future.wait([
        _repo.fetchUserPosts(userId),
        _repo.checkIsFollowing(userId),
        _repo.checkHasPendingRequest(userId),
      ]);
      emit(ViewProfileSuccess(
        profile: profile,
        posts: results[0] as List<PostModel>,
        isFollowing: results[1] as bool,
        isRequested: results[2] as bool,
        followersCount: profile.followersCount,
      ));
    } catch (e) {
      emit(ViewProfileFailure(e.toString()));
    }
  }

  Future<void> toggleFollow(String targetUserId) async {
    final s = state;
    if (s is! ViewProfileSuccess) return;

    final wasFollowing = s.isFollowing;
    final wasRequested = s.isRequested;
    final prevCount = s.followersCount;
    final isPrivate = s.profile.isPrivate;

    // Optimistic update
    if (wasFollowing) {
      emit(s.copyWith(
        isFollowing: false,
        isRequested: false,
        followersCount: prevCount - 1,
      ));
    } else if (wasRequested) {
      emit(s.copyWith(
        isFollowing: false,
        isRequested: false,
      ));
    } else {
      emit(s.copyWith(
        isFollowing: !isPrivate,
        isRequested: isPrivate,
        followersCount: isPrivate ? prevCount : prevCount + 1,
      ));
    }

    try {
      if (wasFollowing || wasRequested) {
        await _repo.unfollowUser(targetUserId);
      } else {
        await _repo.followUser(targetUserId);
      }
    } catch (_) {
      // Rollback on failure
      emit(s.copyWith(
        isFollowing: wasFollowing,
        isRequested: wasRequested,
        followersCount: prevCount,
      ));
    }
  }

  Future<void> toggleLike(String postId) async {
    final s = state;
    if (s is! ViewProfileSuccess) return;

    final updatedPosts = s.posts.map((p) {
      if (p.id == postId) {
        final newLiked = !p.isLiked;
        p.isLiked = newLiked;
        p.likesCount += newLiked ? 1 : -1;
      }
      return p;
    }).toList();

    emit(s.copyWith(posts: updatedPosts));

    final targetPost = updatedPosts.firstWhere((p) => p.id == postId);
    await _feedRepo.toggleLike(
      postId: postId,
      liked: targetPost.isLiked,
      postOwnerId: targetPost.userId,
    );
  }

  Future<void> toggleSave(String postId) async {
    final s = state;
    if (s is! ViewProfileSuccess) return;

    final updatedPosts = s.posts.map((p) {
      if (p.id == postId) {
        p.isSaved = !p.isSaved;
      }
      return p;
    }).toList();

    emit(s.copyWith(posts: updatedPosts));

    final targetPost = updatedPosts.firstWhere((p) => p.id == postId);
    await _feedRepo.toggleSave(postId: postId, saved: targetPost.isSaved);
  }
}
