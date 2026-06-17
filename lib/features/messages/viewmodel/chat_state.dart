import '../models/message_model.dart';

abstract class ChatState {}

class ChatInitial extends ChatState {}

class ChatLoading extends ChatState {}

class ChatSuccess extends ChatState {
  final List<MessageModel> messages;
  final bool isSending;
  final MessageModel? replyToMessage;
  final List<String> typingUsernames;

  ChatSuccess({
    required this.messages,
    this.isSending = false,
    this.replyToMessage,
    this.typingUsernames = const [],
  });

  ChatSuccess copyWith({
    List<MessageModel>? messages,
    bool? isSending,
    Object? replyToMessage = _absent,
    List<String>? typingUsernames,
  }) {
    return ChatSuccess(
      messages: messages ?? this.messages,
      isSending: isSending ?? this.isSending,
      replyToMessage: identical(replyToMessage, _absent)
          ? this.replyToMessage
          : replyToMessage as MessageModel?,
      typingUsernames: typingUsernames ?? this.typingUsernames,
    );
  }
}

class ChatFailure extends ChatState {
  final String error;
  ChatFailure(this.error);
}

const _absent = Object();
