class PostMediaModel {
  final String id;
  final String postId;
  final String mediaUrl;
  final String mediaType;
  final double aspectRatio;
  final int mediaOrder;

  const PostMediaModel({
    required this.id,
    required this.postId,
    required this.mediaUrl,
    required this.mediaType,
    required this.aspectRatio,
    required this.mediaOrder,
  });

  factory PostMediaModel.fromJson(Map<String, dynamic> json) => PostMediaModel(
        id: json['id'] as String,
        postId: json['post_id'] as String,
        mediaUrl: json['media_url'] as String,
        mediaType: json['media_type'] as String? ?? 'image',
        aspectRatio: (json['aspect_ratio'] as num?)?.toDouble() ?? 1.0,
        mediaOrder: json['media_order'] as int? ?? 0,
      );
}
