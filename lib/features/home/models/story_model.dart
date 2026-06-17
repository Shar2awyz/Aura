import 'profile_model.dart';

class StoryModel {
  final String id;
  final String userId;
  final String mediaUrl;
  final String mediaType;
  final String? caption;
  final int viewsCount;
  final DateTime createdAt;
  final ProfileModel profile;
  final bool isViewed;

  const StoryModel({
    required this.id,
    required this.userId,
    required this.mediaUrl,
    required this.mediaType,
    this.caption,
    required this.viewsCount,
    required this.createdAt,
    required this.profile,
    this.isViewed = false,
  });

  factory StoryModel.fromJson(Map<String, dynamic> json) => StoryModel(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        mediaUrl: json['media_url'] as String,
        mediaType: json['media_type'] as String? ?? 'image',
        caption: json['caption'] as String?,
        viewsCount: json['views_count'] as int? ?? 0,
        createdAt: DateTime.parse(json['created_at'] as String),
        profile: ProfileModel.fromJson(
          json['profiles'] as Map<String, dynamic>,
        ),
      );

  StoryModel copyWith({bool? isViewed}) => StoryModel(
        id: id,
        userId: userId,
        mediaUrl: mediaUrl,
        mediaType: mediaType,
        caption: caption,
        viewsCount: viewsCount,
        createdAt: createdAt,
        profile: profile,
        isViewed: isViewed ?? this.isViewed,
      );
}
