import '../../home/models/post_model.dart';
import '../../home/models/profile_model.dart';

abstract class ProfileState {}

class ProfileInitial extends ProfileState {}

class ProfileLoading extends ProfileState {}

class ProfileSuccess extends ProfileState {
  final ProfileModel profile;
  final List<PostModel> posts;
  final List<PostModel> savedPosts;

  ProfileSuccess({
    required this.profile,
    required this.posts,
    this.savedPosts = const [],
  });
}



class ProfileFailure extends ProfileState {
  final String error;
  ProfileFailure(this.error);
}
