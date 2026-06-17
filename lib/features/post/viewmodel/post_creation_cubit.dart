import 'dart:typed_data';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../repo/post_repo.dart';
import 'post_creation_state.dart';

class PostCreationCubit extends Cubit<PostCreationState> {
  PostCreationCubit() : super(PostCreationInitial());

  final _repo = PostRepo();

  Future<void> submitPost({
    String? filePath,
    Uint8List? fileBytes,
    String? fileName,
    String? webUrl,
    required String mediaType,
    required double aspectRatio,
    String? caption,
    String? location,
  }) async {
    emit(PostCreationLoading());
    try {
      String mediaUrl;
      if (webUrl != null && webUrl.trim().isNotEmpty) {
        mediaUrl = webUrl.trim();
      } else {
        mediaUrl = await _repo.uploadMedia(
          filePath: filePath,
          fileBytes: fileBytes,
          fileName: fileName ?? 'upload_file',
          mediaType: mediaType,
        );
      }

      await _repo.createPost(
        mediaUrl: mediaUrl,
        mediaType: mediaType,
        aspectRatio: aspectRatio,
        caption: caption,
        location: location,
      );
      emit(PostCreationSuccess());
    } catch (e) {
      emit(PostCreationFailure(e.toString()));
    }
  }
}
