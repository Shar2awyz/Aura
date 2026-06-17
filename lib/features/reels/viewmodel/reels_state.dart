import '../../home/models/post_model.dart';

sealed class ReelsState {}

class ReelsInitial extends ReelsState {}

class ReelsLoading extends ReelsState {}

class ReelsLoaded extends ReelsState {
  final List<PostModel> reels;
  ReelsLoaded(this.reels);
}

class ReelsError extends ReelsState {
  final String message;
  ReelsError(this.message);
}
