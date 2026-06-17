import '../models/post_model.dart';
import '../models/profile_model.dart';
import '../models/story_model.dart';

abstract class FeedState {}

class FeedInitial extends FeedState {}

class FeedLoading extends FeedState {}

class FeedSuccess extends FeedState {
  final List<StoryModel> stories;
  final List<PostModel> posts;
  final ProfileModel? currentUserProfile;

  FeedSuccess({
    required this.stories,
    required this.posts,
    this.currentUserProfile,
  });
}

class FeedFailure extends FeedState {
  final String error;
  FeedFailure(this.error);
}
