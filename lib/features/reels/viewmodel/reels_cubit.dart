import 'package:flutter_bloc/flutter_bloc.dart';
import '../../home/models/post_model.dart';
import '../../home/repo/feed_repo.dart';
import '../repo/reels_repo.dart';
import 'reels_state.dart';

class ReelsCubit extends Cubit<ReelsState> {
  final ReelsRepo _repo;
  final FeedRepo _feedRepo = FeedRepo();

  ReelsCubit(this._repo) : super(ReelsInitial());

  Future<void> loadReels() async {
    emit(ReelsLoading());
    try {
      final reels = await _repo.fetchReels();
      emit(ReelsLoaded(reels));
    } catch (e) {
      emit(ReelsError(e.toString()));
    }
  }

  Future<void> toggleLike(String reelId) async {
    if (state is! ReelsLoaded) return;
    final current = state as ReelsLoaded;
    final reels = List<PostModel>.from(current.reels);
    final index = reels.indexWhere((r) => r.id == reelId);
    if (index == -1) return;

    final reel = reels[index];
    final newLiked = !reel.isLiked;
    reel.isLiked = newLiked;
    reel.likesCount += newLiked ? 1 : -1;

    emit(ReelsLoaded(reels));

    try {
      await _feedRepo.toggleLike(
        postId: reelId,
        liked: newLiked,
        postOwnerId: reel.userId,
      );
    } catch (_) {
      // Revert if API fails
      reel.isLiked = !newLiked;
      reel.likesCount += newLiked ? -1 : 1;
      emit(ReelsLoaded(reels));
    }
  }

  Future<void> toggleSave(String reelId) async {
    if (state is! ReelsLoaded) return;
    final current = state as ReelsLoaded;
    final reels = List<PostModel>.from(current.reels);
    final index = reels.indexWhere((r) => r.id == reelId);
    if (index == -1) return;

    final reel = reels[index];
    final newSaved = !reel.isSaved;
    reel.isSaved = newSaved;

    emit(ReelsLoaded(reels));

    try {
      await _feedRepo.toggleSave(postId: reelId, saved: newSaved);
    } catch (_) {
      // Revert if API fails
      reel.isSaved = !newSaved;
      emit(ReelsLoaded(reels));
    }
  }
}
