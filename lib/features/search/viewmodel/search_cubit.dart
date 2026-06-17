import 'package:flutter_bloc/flutter_bloc.dart';
import '../repo/search_repo.dart';
import 'search_state.dart';

class SearchCubit extends Cubit<SearchState> {
  SearchCubit() : super(const SearchInitial());

  final _repo = SearchRepo();

  Future<void> loadExplorePosts() async {
    emit(const SearchLoading());
    try {
      final posts = await _repo.fetchExplorePosts();
      emit(SearchExploreSuccess(posts));
    } catch (e) {
      emit(SearchFailure(e.toString()));
    }
  }

  Future<void> searchUsers(String query) async {
    if (query.trim().isEmpty) {
      loadExplorePosts();
      return;
    }
    emit(const SearchLoading());
    try {
      final users = await _repo.searchUsers(query);
      emit(SearchUsersSuccess(users));
    } catch (e) {
      emit(SearchFailure(e.toString()));
    }
  }
}
