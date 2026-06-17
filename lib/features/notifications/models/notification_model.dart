import '../../home/models/profile_model.dart';

class NotificationModel {
  final String id;
  final String receiverId;
  final String senderId;
  final String type; // 'follow', 'like', 'comment', 'message'
  final String? targetType;
  final String? targetId;
  final bool isRead;
  final DateTime createdAt;
  final ProfileModel? senderProfile;

  NotificationModel({
    required this.id,
    required this.receiverId,
    required this.senderId,
    required this.type,
    this.targetType,
    this.targetId,
    required this.isRead,
    required this.createdAt,
    this.senderProfile,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    // If profiles was joined via `profiles!sender_id(*)` or standard `profiles`,
    // it will be returned as key 'profiles' or sometimes a different alias.
    // We look up 'profiles' directly.
    final profilesData = json['profiles'] as Map<String, dynamic>?;
    
    return NotificationModel(
      id: json['id'] as String,
      receiverId: json['receiver_id'] as String,
      senderId: json['sender_id'] as String,
      type: json['type'] as String,
      targetType: json['target_type'] as String?,
      targetId: json['target_id'] as String?,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      senderProfile: profilesData != null ? ProfileModel.fromJson(profilesData) : null,
    );
  }

  NotificationModel copyWith({
    String? id,
    String? receiverId,
    String? senderId,
    String? type,
    String? targetType,
    String? targetId,
    bool? isRead,
    DateTime? createdAt,
    ProfileModel? senderProfile,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      receiverId: receiverId ?? this.receiverId,
      senderId: senderId ?? this.senderId,
      type: type ?? this.type,
      targetType: targetType ?? this.targetType,
      targetId: targetId ?? this.targetId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      senderProfile: senderProfile ?? this.senderProfile,
    );
  }
}
