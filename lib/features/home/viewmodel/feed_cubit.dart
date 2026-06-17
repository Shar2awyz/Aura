import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/post_model.dart';
import '../repo/feed_repo.dart';
import 'feed_state.dart';

class FeedCubit extends Cubit<FeedState> {
  FeedCubit() : super(FeedInitial());

  final _repo = FeedRepo();

  Future<void> loadFeed() async {
    emit(FeedLoading());
    try {
      final profileFuture = _repo.fetchCurrentUserProfile();
      final storiesFuture = _repo.fetchStories();
      final postsFuture = _repo.fetchFeed();

      final stories = await storiesFuture;
      debugPrint('[FeedCubit] stories fetched: ${stories.length}');

      emit(FeedSuccess(
        currentUserProfile: await profileFuture,
        stories: stories,
        posts: await postsFuture,
      ));
    } catch (e, st) {
      debugPrint('[FeedCubit] loadFeed error: $e\n$st');
      emit(FeedFailure(e.toString()));
    }
  }

  Future<void> refreshStories() async {
    if (state is! FeedSuccess) return;
    final current = state as FeedSuccess;
    try {
      final stories = await _repo.fetchStories();
      emit(FeedSuccess(
        stories: stories,
        posts: current.posts,
        currentUserProfile: current.currentUserProfile,
      ));
    } catch (_) {}
  }

  Future<void> toggleLike(String postId) async {
    if (state is! FeedSuccess) return;
    final current = state as FeedSuccess;

    final post = current.posts.firstWhere((p) => p.id == postId);
    final newLiked = !post.isLiked;

    post.isLiked = newLiked;
    post.likesCount += newLiked ? 1 : -1;

    emit(FeedSuccess(
      stories: current.stories,
      posts: List<PostModel>.from(current.posts),
      currentUserProfile: current.currentUserProfile,
    ));

    await _repo.toggleLike(postId: postId, liked: newLiked, postOwnerId: post.userId);
  }

  Future<void> toggleSave(String postId) async {
    if (state is! FeedSuccess) return;
    final current = state as FeedSuccess;

    final post = current.posts.firstWhere((p) => p.id == postId);
    final newSaved = !post.isSaved;

    post.isSaved = newSaved;

    emit(FeedSuccess(
      stories: current.stories,
      posts: List<PostModel>.from(current.posts),
      currentUserProfile: current.currentUserProfile,
    ));

    await _repo.toggleSave(postId: postId, saved: newSaved);
  }
}
