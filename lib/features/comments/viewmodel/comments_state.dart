import '../models/comment_model.dart';

abstract class CommentsState {}

class CommentsInitial extends CommentsState {}

class CommentsLoading extends CommentsState {}

class CommentsSuccess extends CommentsState {
  final List<CommentModel> comments;
  CommentsSuccess(this.comments);
}

class CommentsSubmitting extends CommentsState {
  final List<CommentModel> comments;
  CommentsSubmitting(this.comments);
}

class CommentsFailure extends CommentsState {
  final String error;
  CommentsFailure(this.error);
}
