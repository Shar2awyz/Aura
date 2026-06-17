import 'profile_model.dart';
import 'post_media_model.dart';

class PostModel {
  final String id;
  final String userId;
  final String? caption;
  final String? location;
  final DateTime createdAt;
  final ProfileModel profile;
  final List<PostMediaModel> media;
  int likesCount;
  int commentsCount;
  bool isLiked;
  bool isSaved;

  PostModel({
    required this.id,
    required this.userId,
    this.caption,
    this.location,
    required this.createdAt,
    required this.profile,
    required this.media,
    required this.likesCount,
    required this.commentsCount,
    this.isLiked = false,
    this.isSaved = false,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    final mediaList = (json['post_media'] as List? ?? [])
        .map((e) => PostMediaModel.fromJson(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.mediaOrder.compareTo(b.mediaOrder));

    return PostModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      caption: json['caption'] as String?,
      location: json['location'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      profile: ProfileModel.fromJson(
        json['profiles'] as Map<String, dynamic>,
      ),
      media: mediaList,
      likesCount: json['likes_count'] as int? ?? 0,
      commentsCount: json['comments_count'] as int? ?? 0,
    );
  }
}
