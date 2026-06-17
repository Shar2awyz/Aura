import '../../home/models/profile_model.dart';

class ChatModel {
  final String id;
  final bool isGroup;
  final String? groupName;
  final String? groupImage;
  final String? lastMessage;
  final DateTime updatedAt;
  final List<ProfileModel> otherMembers;
  final int unreadCount;

  const ChatModel({
    required this.id,
    required this.isGroup,
    this.groupName,
    this.groupImage,
    this.lastMessage,
    required this.updatedAt,
    required this.otherMembers,
    this.unreadCount = 0,
  });

  ProfileModel? get otherUser =>
      isGroup ? null : (otherMembers.isEmpty ? null : otherMembers.first);

  String get displayName {
    if (isGroup) return groupName ?? 'Group';
    return otherUser?.displayName ?? 'Unknown';
  }

  String? get displayAvatar {
    if (isGroup) return groupImage;
    return otherUser?.avatarUrl;
  }

  String get lastMessagePreview => lastMessage ?? '';

  ChatModel copyWith({int? unreadCount, String? lastMessage, DateTime? updatedAt}) {
    return ChatModel(
      id: id,
      isGroup: isGroup,
      groupName: groupName,
      groupImage: groupImage,
      lastMessage: lastMessage ?? this.lastMessage,
      updatedAt: updatedAt ?? this.updatedAt,
      otherMembers: otherMembers,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }

  factory ChatModel.fromJson(Map<String, dynamic> json, String currentUserId) {
    final members = json['chat_members'] as List? ?? [];
    final otherMembers = members
        .where((m) => (m as Map)['user_id'] != currentUserId)
        .where((m) => (m as Map)['profiles'] != null)
        .map((m) => ProfileModel.fromJson(
            (m as Map<String, dynamic>)['profiles'] as Map<String, dynamic>))
        .toList();

    return ChatModel(
      id: json['id'] as String,
      isGroup: json['is_group'] as bool? ?? false,
      groupName: json['group_name'] as String?,
      groupImage: json['group_image'] as String?,
      lastMessage: json['last_message'] as String?,
      updatedAt: DateTime.parse(json['updated_at'] as String),
      otherMembers: otherMembers,
    );
  }
}
