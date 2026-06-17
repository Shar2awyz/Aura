class ProfileModel {
  final String id;
  final String username;
  final String? fullName;
  final String? bio;
  final String? avatarUrl;
  final String? coverUrl;
  final bool isVerified;
  final bool isPrivate;
  final int followersCount;
  final int followingCount;
  final int postsCount;
  final int auraScore;

  const ProfileModel({
    required this.id,
    required this.username,
    this.fullName,
    this.bio,
    this.avatarUrl,
    this.coverUrl,
    this.isVerified = false,
    this.isPrivate = false,
    this.followersCount = 0,
    this.followingCount = 0,
    this.postsCount = 0,
    this.auraScore = 0,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) => ProfileModel(
        id: json['id'] as String,
        username: json['username'] as String? ?? 'user',
        fullName: json['full_name'] as String?,
        bio: json['bio'] as String?,
        avatarUrl: json['avatar_url'] as String?,
        coverUrl: json['cover_url'] as String?,
        isVerified: json['is_verified'] as bool? ?? false,
        isPrivate: json['is_private'] as bool? ?? false,
        followersCount: json['followers_count'] as int? ?? 0,
        followingCount: json['following_count'] as int? ?? 0,
        postsCount: json['posts_count'] as int? ?? 0,
        auraScore: json['aura_score'] as int? ?? 0,
      );

  String get displayName => fullName ?? username;

  ProfileModel copyWith({
    String? id,
    String? username,
    String? fullName,
    String? bio,
    String? avatarUrl,
    String? coverUrl,
    bool? isVerified,
    bool? isPrivate,
    int? followersCount,
    int? followingCount,
    int? postsCount,
    int? auraScore,
  }) {
    return ProfileModel(
      id: id ?? this.id,
      username: username ?? this.username,
      fullName: fullName ?? this.fullName,
      bio: bio ?? this.bio,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      coverUrl: coverUrl ?? this.coverUrl,
      isVerified: isVerified ?? this.isVerified,
      isPrivate: isPrivate ?? this.isPrivate,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      postsCount: postsCount ?? this.postsCount,
      auraScore: auraScore ?? this.auraScore,
    );
  }
}
