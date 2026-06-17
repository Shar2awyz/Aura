import '../../home/models/profile_model.dart';

// Sentinel used by copyWith to distinguish "not provided" from null.
const _absent = Object();

class MessageModel {
  final String id;
  final String chatId;
  final String senderId;
  final String messageType;
  final String? content;
  final String? mediaUrl;
  final String? fileName;
  final bool isSeen;
  final String? replyToMessageId;
  final String? reaction;
  final bool isDeleted;
  final DateTime createdAt;
  final ProfileModel? sender;
  final MessageModel? replyToMessage;

  const MessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.messageType,
    this.content,
    this.mediaUrl,
    this.fileName,
    required this.isSeen,
    this.replyToMessageId,
    this.reaction,
    this.isDeleted = false,
    required this.createdAt,
    this.sender,
    this.replyToMessage,
  });

  bool get isText => messageType == 'text';
  bool get isImage => messageType == 'image';
  bool get isVideo => messageType == 'video';
  bool get isAudio => messageType == 'audio';
  bool get isFile => messageType == 'file';

  String get replyPreview {
    if (isDeleted) return 'Message unsent';
    if (isImage) return '📷 Photo';
    if (isVideo) return '🎥 Video';
    if (isAudio) return '🎙 Audio';
    if (isFile) return '📄 ${fileName ?? 'File'}';
    return content ?? '';
  }

  MessageModel copyWith({
    Object? reaction = _absent,
    bool? isDeleted,
    bool? isSeen,
    Object? replyToMessage = _absent,
  }) {
    return MessageModel(
      id: id,
      chatId: chatId,
      senderId: senderId,
      messageType: messageType,
      content: content,
      mediaUrl: mediaUrl,
      fileName: fileName,
      isSeen: isSeen ?? this.isSeen,
      replyToMessageId: replyToMessageId,
      reaction: identical(reaction, _absent) ? this.reaction : reaction as String?,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt,
      sender: sender,
      replyToMessage: identical(replyToMessage, _absent)
          ? this.replyToMessage
          : replyToMessage as MessageModel?,
    );
  }

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] as String,
      chatId: json['chat_id'] as String,
      senderId: json['sender_id'] as String,
      messageType: json['message_type'] as String? ?? 'text',
      content: json['content'] as String?,
      mediaUrl: json['media_url'] as String?,
      fileName: json['file_name'] as String?,
      isSeen: json['is_seen'] as bool? ?? false,
      replyToMessageId: json['reply_to_message_id'] as String?,
      reaction: json['reaction'] as String?,
      isDeleted: json['is_deleted'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      sender: json['profiles'] != null
          ? ProfileModel.fromJson(json['profiles'] as Map<String, dynamic>)
          : null,
    );
  }
}
