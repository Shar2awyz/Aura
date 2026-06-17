import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/cloudinary_service.dart';
import '../../home/models/post_model.dart';

class PostRepo {
  final _client = Supabase.instance.client;

  Future<PostModel?> fetchPostById(String postId) async {
    final currentUserId = _client.auth.currentUser?.id;
    final data = await _client
        .from('posts')
        .select('*, profiles(*), post_media(*)')
        .eq('id', postId)
        .maybeSingle();

    if (data == null) return null;
    final post = PostModel.fromJson(data);

    if (currentUserId != null) {
      try {
        final liked = await _client
            .from('likes')
            .select('target_id')
            .eq('user_id', currentUserId)
            .eq('target_type', 'post')
            .eq('target_id', postId)
            .maybeSingle();
        post.isLiked = liked != null;
      } catch (_) {}

      try {
        final saved = await _client
            .from('saved_items')
            .select('target_id')
            .eq('user_id', currentUserId)
            .eq('target_type', 'post')
            .eq('target_id', postId)
            .maybeSingle();
        post.isSaved = saved != null;
      } catch (_) {}
    }

    return post;
  }

  Future<String> uploadMedia({
    String? filePath,
    Uint8List? fileBytes,
    required String fileName,
    required String mediaType,
  }) async {
    final url = await CloudinaryService.uploadFile(
      filePath: filePath,
      fileBytes: fileBytes,
      fileName: fileName,
      resourceType: mediaType,
    );
    if (url == null) throw Exception('Upload failed — check Cloudinary config in .env');
    return url;
  }

  Future<void> createPost({
    required String mediaUrl,
    required String mediaType,
    required double aspectRatio,
    String? caption,
    String? location,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    final post = await _client.from('posts').insert({
      'user_id': userId,
      if (caption?.trim().isNotEmpty ?? false) 'caption': caption!.trim(),
      if (location?.trim().isNotEmpty ?? false) 'location': location!.trim(),
    }).select('id').single();

    await _client.from('post_media').insert({
      'post_id': post['id'] as String,
      'media_url': mediaUrl,
      'media_type': mediaType,
      'aspect_ratio': aspectRatio,
      'media_order': 0,
    });
  }
}
