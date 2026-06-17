import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/comment_model.dart';
import '../repo/comments_repo.dart';
import 'comments_state.dart';

class CommentsCubit extends Cubit<CommentsState> {
  CommentsCubit() : super(CommentsInitial());

  final _repo = CommentsRepo();
  List<CommentModel> _comments = [];

  Future<void> loadComments(String postId) async {
    emit(CommentsLoading());
    try {
      _comments = await _repo.fetchComments(postId);
      emit(CommentsSuccess(List.from(_comments)));
    } catch (e) {
      emit(CommentsFailure(e.toString()));
    }
  }

  Future<void> addComment({
    required String postId,
    required String text,
    required String postOwnerId,
  }) async {
    if (text.trim().isEmpty) return;
    emit(CommentsSubmitting(List.from(_comments)));
    try {
      final comment = await _repo.addComment(
        postId: postId,
        text: text.trim(),
        postOwnerId: postOwnerId,
      );
      _comments.add(comment);
      emit(CommentsSuccess(List.from(_comments)));
    } catch (_) {
      emit(CommentsSuccess(List.from(_comments)));
    }
  }

  Future<void> deleteComment(String commentId) async {
    try {
      await _repo.deleteComment(commentId);
      _comments.removeWhere((c) => c.id == commentId);
      emit(CommentsSuccess(List.from(_comments)));
    } catch (_) {}
  }
}
