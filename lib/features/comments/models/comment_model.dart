import '../../home/models/profile_model.dart';

class CommentModel {
  final String id;
  final String targetId;
  final String targetType;
  final String userId;
  final String content;
  final int likesCount;
  final DateTime createdAt;
  final ProfileModel profile;

  CommentModel({
    required this.id,
    required this.targetId,
    required this.targetType,
    required this.userId,
    required this.content,
    required this.likesCount,
    required this.createdAt,
    required this.profile,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: json['id'] as String,
      targetId: json['target_id'] as String,
      targetType: json['target_type'] as String,
      userId: json['user_id'] as String,
      content: json['content'] as String,
      likesCount: json['likes_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      profile: ProfileModel.fromJson(
        json['profiles'] as Map<String, dynamic>,
      ),
    );
  }
}
