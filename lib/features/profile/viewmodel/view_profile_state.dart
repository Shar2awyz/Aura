import '../../home/models/post_model.dart';
import '../../home/models/profile_model.dart';

abstract class ViewProfileState {
  const ViewProfileState();
}

class ViewProfileInitial extends ViewProfileState {
  const ViewProfileInitial();
}

class ViewProfileLoading extends ViewProfileState {
  const ViewProfileLoading();
}

class ViewProfileSuccess extends ViewProfileState {
  final ProfileModel profile;
  final List<PostModel> posts;
  final bool isFollowing;
  final bool isRequested;
  final int followersCount; // mutable for optimistic UI

  const ViewProfileSuccess({
    required this.profile,
    required this.posts,
    required this.isFollowing,
    this.isRequested = false,
    required this.followersCount,
  });

  ViewProfileSuccess copyWith({
    bool? isFollowing,
    bool? isRequested,
    int? followersCount,
    List<PostModel>? posts,
  }) =>
      ViewProfileSuccess(
        profile: profile,
        posts: posts ?? this.posts,
        isFollowing: isFollowing ?? this.isFollowing,
        isRequested: isRequested ?? this.isRequested,
        followersCount: followersCount ?? this.followersCount,
      );
}

class ViewProfileFailure extends ViewProfileState {
  final String error;
  const ViewProfileFailure(this.error);
}
