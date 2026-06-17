import '../../home/models/post_model.dart';
import '../../home/models/profile_model.dart';

abstract class SearchState {
  const SearchState();
}

class SearchInitial extends SearchState {
  const SearchInitial();
}

class SearchLoading extends SearchState {
  const SearchLoading();
}

class SearchExploreSuccess extends SearchState {
  final List<PostModel> posts;
  const SearchExploreSuccess(this.posts);
}

class SearchUsersSuccess extends SearchState {
  final List<ProfileModel> users;
  const SearchUsersSuccess(this.users);
}

class SearchFailure extends SearchState {
  final String error;
  const SearchFailure(this.error);
}
