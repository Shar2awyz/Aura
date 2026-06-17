import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/message_model.dart';
import '../repo/messages_repo.dart';
import 'chat_state.dart';

class ChatCubit extends Cubit<ChatState> {
  ChatCubit(this.chatId) : super(ChatInitial());

  final String chatId;
  final _repo = MessagesRepo();

  RealtimeChannel? _msgChannel;
  RealtimeChannel? _typingChannel;
  Timer? _typingTimer;

  String? get _currentUserId =>
      Supabase.instance.client.auth.currentUser?.id;

  String? get _currentUsername =>
      Supabase.instance.client.auth.currentUser?.userMetadata?['username']
          as String?;

  Future<void> loadMessages() async {
    emit(ChatLoading());
    try {
      final messages = await _repo.fetchMessages(chatId);
      await _repo.markMessagesAsSeen(chatId);
      emit(ChatSuccess(messages: messages));
      _subscribeToMessages();
      _subscribeToTyping();
    } catch (e) {
      emit(ChatFailure(e.toString()));
    }
  }

  void _subscribeToMessages() {
    _msgChannel = _repo.subscribeToMessages(
      chatId,
      // New message
      (message) {
        if (state is! ChatSuccess) return;
        final current = state as ChatSuccess;
        // Don't duplicate messages we sent ourselves (realtime echoes back)
        if (current.messages.any((m) => m.id == message.id)) return;
        final updated = [message, ...current.messages];
        emit(current.copyWith(messages: updated));
        // Mark incoming messages as seen
        if (message.senderId != _currentUserId) {
          _repo.markMessagesAsSeen(chatId);
        }
      },
      // Updated message (reaction / unsend)
      (updated) {
        if (state is! ChatSuccess) return;
        final current = state as ChatSuccess;
        final msgs = current.messages.map((m) {
          if (m.id == updated.id) {
            // Preserve sender profile which isn't in the UPDATE payload
            return updated.copyWith(
              replyToMessage: m.replyToMessage,
            );
          }
          return m;
        }).toList();
        emit(current.copyWith(messages: msgs));
      },
    );
  }

  void _subscribeToTyping() {
    final username = _currentUsername;
    if (username == null) return;

    _typingChannel = _repo.createTypingChannel(chatId);

    _typingChannel!.onPresenceSync((_) {
      if (state is! ChatSuccess) return;
      final current = state as ChatSuccess;
      final presenceState = _typingChannel!.presenceState();
      final typing = presenceState
          .expand((s) => s.presences)
          .where((p) =>
              p.payload['typing'] == true &&
              p.payload['username'] != username)
          .map((p) => p.payload['username'] as String)
          .toList();
      emit(current.copyWith(typingUsernames: typing));
    });

    _typingChannel!.subscribe();
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  Future<void> sendText(String content) async {
    if (content.trim().isEmpty) return;
    final replyId = state is ChatSuccess
        ? (state as ChatSuccess).replyToMessage?.id
        : null;

    if (state is ChatSuccess && replyId != null) {
      emit((state as ChatSuccess).copyWith(replyToMessage: null));
    }

    try {
      final messageId = await _repo.sendTextMessage(
        chatId: chatId,
        content: content.trim(),
        replyToMessageId: replyId,
      );
      if (messageId != null) {
        final msg = await _repo.fetchMessageById(messageId);
        if (msg != null && state is ChatSuccess) {
          final current = state as ChatSuccess;
          if (!current.messages.any((m) => m.id == msg.id)) {
            emit(current.copyWith(messages: [msg, ...current.messages]));
          }
        }
      }
    } catch (_) {}
  }

  Future<void> sendMedia({
    String? filePath,
    Uint8List? fileBytes,
    required String messageType,
    String? fileName,
    String? webUrl,
  }) async {
    if (state is! ChatSuccess) return;
    final current = state as ChatSuccess;
    final replyId = current.replyToMessage?.id;
    emit(current.copyWith(isSending: true, replyToMessage: null));
    try {
      final messageId = await _repo.sendMediaMessage(
        chatId: chatId,
        filePath: filePath,
        fileBytes: fileBytes,
        messageType: messageType,
        fileName: fileName,
        webUrl: webUrl,
        replyToMessageId: replyId,
      );
      if (messageId != null) {
        final msg = await _repo.fetchMessageById(messageId);
        if (msg != null && state is ChatSuccess) {
          final cur = state as ChatSuccess;
          if (!cur.messages.any((m) => m.id == msg.id)) {
            emit(cur.copyWith(isSending: false, messages: [msg, ...cur.messages]));
            return;
          }
        }
      }
    } catch (_) {}
    if (state is ChatSuccess) {
      emit((state as ChatSuccess).copyWith(isSending: false));
    }
  }

  void setReply(MessageModel message) {
    if (state is ChatSuccess) {
      emit((state as ChatSuccess).copyWith(replyToMessage: message));
    }
  }

  void clearReply() {
    if (state is ChatSuccess) {
      emit((state as ChatSuccess).copyWith(replyToMessage: null));
    }
  }

  Future<void> reactToMessage(String messageId, String? emoji) async {
    try {
      await _repo.reactToMessage(messageId, emoji);
    } catch (_) {}
  }

  Future<void> unsendMessage(String messageId) async {
    try {
      await _repo.unsendMessage(messageId);
    } catch (_) {}
  }

  void onTypingChanged(bool isTyping) {
    final username = _currentUsername;
    if (username == null || _typingChannel == null) return;

    _typingTimer?.cancel();
    _repo.trackTyping(_typingChannel!, username, isTyping);

    if (isTyping) {
      // Auto-stop typing indicator after 3 seconds of no input
      _typingTimer = Timer(const Duration(seconds: 3), () {
        _repo.trackTyping(_typingChannel!, username, false);
      });
    }
  }

  @override
  Future<void> close() {
    _msgChannel?.unsubscribe();
    _typingChannel?.unsubscribe();
    _typingTimer?.cancel();
    return super.close();
  }
}
