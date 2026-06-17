import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../home/models/post_model.dart';
import '../../home/repo/feed_repo.dart';
import '../repo/profile_repo.dart';
import 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit() : super(ProfileInitial());

  final _repo = ProfileRepo();
  final _feedRepo = FeedRepo();

  Future<void> loadProfile() async {
    emit(ProfileLoading());
    try {
      final profile = await _repo.fetchCurrentProfile();
      // Existing loadProfile remains unchanged
      if (profile == null) {
        emit(ProfileFailure('Profile not found'));
        return;
      }
      final postsFuture = _repo.fetchUserPosts(profile.id);
      final savedFuture = _repo.fetchSavedPosts().catchError((_) => <PostModel>[]);
      final results = await Future.wait([postsFuture, savedFuture]);
      emit(ProfileSuccess(
        profile: profile,
        posts: results[0],
        savedPosts: results[1],
      ));
    } catch (e) {
      emit(ProfileFailure(e.toString()));
    }
  }

  Future<void> toggleLike(String postId) async {
    if (state is! ProfileSuccess) return;
    final current = state as ProfileSuccess;

    final updatedPosts = current.posts.map((p) {
      if (p.id == postId) {
        final newLiked = !p.isLiked;
        p.isLiked = newLiked;
        p.likesCount += newLiked ? 1 : -1;
      }
      return p;
    }).toList();

    final updatedSaved = current.savedPosts.map((p) {
      if (p.id == postId) {
        final newLiked = !p.isLiked;
        p.isLiked = newLiked;
        p.likesCount += newLiked ? 1 : -1;
      }
      return p;
    }).toList();

    emit(ProfileSuccess(
      profile: current.profile,
      posts: updatedPosts,
      savedPosts: updatedSaved,
    ));

    final targetPost = updatedPosts.firstWhere((p) => p.id == postId, orElse: () => updatedSaved.firstWhere((p) => p.id == postId));
    await _feedRepo.toggleLike(
      postId: postId,
      liked: targetPost.isLiked,
      postOwnerId: targetPost.userId,
    );
  }

  Future<void> toggleSave(String postId) async {
    if (state is! ProfileSuccess) return;
    final current = state as ProfileSuccess;

    // Check if it exists in saved list to toggle or add/remove it
    bool isNowSaved = false;
    final updatedPosts = current.posts.map((p) {
      if (p.id == postId) {
        p.isSaved = !p.isSaved;
        isNowSaved = p.isSaved;
      }
      return p;
    }).toList();

    // If it was toggled from updatedPosts, we know the status. Otherwise check savedPosts.
    if (current.posts.any((p) => p.id == postId)) {
      isNowSaved = updatedPosts.firstWhere((p) => p.id == postId).isSaved;
    } else if (current.savedPosts.any((p) => p.id == postId)) {
      isNowSaved = !current.savedPosts.firstWhere((p) => p.id == postId).isSaved;
    }

    List<PostModel> updatedSaved;
    if (isNowSaved) {
      // If it became saved and not in savedPosts, add it (we need the post object)
      final alreadySaved = current.savedPosts.any((p) => p.id == postId);
      if (alreadySaved) {
        updatedSaved = current.savedPosts.map((p) {
          if (p.id == postId) p.isSaved = true;
          return p;
        }).toList();
      } else {
        // Find it in posts
        final post = current.posts.firstWhere((p) => p.id == postId);
        post.isSaved = true;
        updatedSaved = [post, ...current.savedPosts];
      }
    } else {
      // If it was unsaved, remove it from savedPosts (or set isSaved=false)
      updatedSaved = current.savedPosts.where((p) => p.id != postId).toList();
    }

    emit(ProfileSuccess(
      profile: current.profile,
      posts: updatedPosts,
      savedPosts: updatedSaved,
    ));

    await _feedRepo.toggleSave(postId: postId, saved: isNowSaved);
  }

  // New method to update user profile
  Future<void> updateUserProfile({
    String? name,
    String? username,
    String? email,
    String? password,
    File? picture,
  }) async {
    emit(ProfileLoading());
    try {
      await _repo.updateUserProfile(
        name: name,
        username: username,
        email: email,
        password: password,
        picture: picture,
      );
      // Refresh profile and posts after update
      await loadProfile();
    } catch (e) {
      emit(ProfileFailure(e.toString()));
    }
  }

  Future<void> toggleProfilePrivacy(bool isPrivate) async {
    if (state is! ProfileSuccess) return;
    final current = state as ProfileSuccess;
    try {
      await _repo.toggleProfilePrivacy(isPrivate);
      emit(ProfileSuccess(
        profile: current.profile.copyWith(isPrivate: isPrivate),
        posts: current.posts,
        savedPosts: current.savedPosts,
      ));
    } catch (e) {
      emit(ProfileFailure(e.toString()));
    }
  }
}
