import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/comment_model.dart';

class CommentsRepo {
  final _client = Supabase.instance.client;

  Future<List<CommentModel>> fetchComments(String postId) async {
    final data = await _client
        .from('comments')
        .select('*, profiles(*)')
        .eq('target_type', 'post')
        .eq('target_id', postId)
        .order('created_at', ascending: true);

    return (data as List)
        .map((e) => CommentModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<CommentModel> addComment({
    required String postId,
    required String text,
    required String postOwnerId,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    final data = await _client
        .from('comments')
        .insert({
          'target_type': 'post',
          'target_id': postId,
          'user_id': userId,
          'content': text,
        })
        .select('*, profiles(*)')
        .single();

    // Insert comment notification (only if commenter is not post owner)
    if (userId != postOwnerId) {
      await _client.from('notifications').insert({
        'receiver_id': postOwnerId,
        'sender_id': userId,
        'type': 'comment',
        'target_type': 'post',
        'target_id': postId,
      }).catchError((e, s) {
        debugPrint('Error inserting comment notification: $e\n$s');
        return <String, dynamic>{};
      });
    }

    return CommentModel.fromJson(data);
  }

  Future<void> deleteComment(String commentId) async {
    await _client.from('comments').delete().eq('id', commentId);
  }
}
