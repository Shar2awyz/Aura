import 'package:flutter_bloc/flutter_bloc.dart';
import '../../home/models/profile_model.dart';
import '../repo/profile_repo.dart';

abstract class FollowersFollowingState {}

class FollowersFollowingInitial extends FollowersFollowingState {}

class FollowersFollowingLoading extends FollowersFollowingState {}

class FollowersFollowingSuccess extends FollowersFollowingState {
  final List<Map<String, dynamic>> items;
  FollowersFollowingSuccess(this.items);
}

class FollowersFollowingFailure extends FollowersFollowingState {
  final String error;
  FollowersFollowingFailure(this.error);
}

class FollowersFollowingCubit extends Cubit<FollowersFollowingState> {
  FollowersFollowingCubit() : super(FollowersFollowingInitial());

  final _repo = ProfileRepo();

  Future<void> loadFollowers(String userId) async {
    emit(FollowersFollowingLoading());
    try {
      final items = await _repo.fetchFollowersWithRelation(userId);
      emit(FollowersFollowingSuccess(items));
    } catch (e) {
      emit(FollowersFollowingFailure(e.toString()));
    }
  }

  Future<void> loadFollowing(String userId) async {
    emit(FollowersFollowingLoading());
    try {
      final items = await _repo.fetchFollowingWithRelation(userId);
      emit(FollowersFollowingSuccess(items));
    } catch (e) {
      emit(FollowersFollowingFailure(e.toString()));
    }
  }

  Future<void> toggleFollow(String targetUserId, bool isFollowing) async {
    final s = state;
    if (s is! FollowersFollowingSuccess) return;

    final updatedItems = s.items.map((item) {
      final profile = item['profile'] as ProfileModel;
      if (profile.id == targetUserId) {
        return {
          ...item,
          'isFollowing': !isFollowing,
        };
      }
      return item;
    }).toList();

    emit(FollowersFollowingSuccess(updatedItems));

    try {
      if (isFollowing) {
        await _repo.unfollowUser(targetUserId);
      } else {
        await _repo.followUser(targetUserId);
      }
    } catch (e) {
      // Rollback on failure
      final rollbackItems = s.items.map((item) {
        final profile = item['profile'] as ProfileModel;
        if (profile.id == targetUserId) {
          return {
            ...item,
            'isFollowing': isFollowing,
          };
        }
        return item;
      }).toList();
      emit(FollowersFollowingSuccess(rollbackItems));
    }
  }
}
