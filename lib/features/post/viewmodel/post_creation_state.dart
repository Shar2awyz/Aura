abstract class PostCreationState {}

class PostCreationInitial extends PostCreationState {}

class PostCreationLoading extends PostCreationState {}

class PostCreationSuccess extends PostCreationState {}

class PostCreationFailure extends PostCreationState {
  final String error;
  PostCreationFailure(this.error);
}
