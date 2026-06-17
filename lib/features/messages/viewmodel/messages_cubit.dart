import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/notification_service.dart';
import '../../profile/repo/profile_repo.dart';
import '../models/chat_model.dart';
import '../repo/messages_repo.dart';
import '../view/chat_detail_page.dart';
import 'messages_state.dart';

class MessagesCubit extends Cubit<MessagesState> {
  MessagesCubit() : super(MessagesInitial());

  final _repo = MessagesRepo();
  RealtimeChannel? _chatsChannel;

  Future<void> loadChats() async {
    emit(MessagesLoading());
    try {
      final chats = await _repo.fetchChats();
      emit(MessagesSuccess(chats: chats));
      _subscribeToChats();
    } catch (e) {
      emit(MessagesFailure(e.toString()));
    }
  }

  void _subscribeToChats() {
    _chatsChannel?.unsubscribe();
    _chatsChannel = _repo.subscribeToChats(
      onChatUpdate: () async {
        try {
          final chats = await _repo.fetchChats();
          if (state is MessagesSuccess) {
            final q = (state as MessagesSuccess).searchQuery;
            emit(MessagesSuccess(chats: chats, searchQuery: q));
          } else {
            emit(MessagesSuccess(chats: chats));
          }
        } catch (_) {}
      },
      onNewMessage: (messageRecord) async {
        final senderId = messageRecord['sender_id'] as String?;
        final currentUserId = Supabase.instance.client.auth.currentUser?.id;
        if (senderId == null || senderId == currentUserId) return;

        final chatId = messageRecord['chat_id'] as String?;
        if (chatId != null && ChatDetailPage.activeChatId == chatId) return;

        String senderName = 'New Message';
        String content = messageRecord['content'] as String? ?? 'Sent a message';

        final messageType = messageRecord['message_type'] as String?;
        if (messageType != 'text') {
          if (messageType == 'image') {
            content = '📷 Sent a photo';
          } else if (messageType == 'video') {
            content = '🎥 Sent a video';
          } else if (messageType == 'audio') {
            content = '🎙 Sent an audio message';
          } else {
            content = '📄 Sent a file';
          }
        }

        try {
          if (state is MessagesSuccess) {
            final chats = (state as MessagesSuccess).chats;
            final chat = chats.firstWhere((c) => c.id == chatId);
            senderName = chat.displayName;
          } else {
            final res = await Supabase.instance.client
                .from('profiles')
                .select('username')
                .eq('id', senderId)
                .maybeSingle();
            if (res != null) {
              senderName = res['username'] as String;
            }
          }
        } catch (_) {}

        NotificationService.showNotification(
          title: senderName,
          body: content,
        );
      },
    );
  }

  void search(String query) {
    if (state is MessagesSuccess) {
      final current = state as MessagesSuccess;
      emit(MessagesSuccess(chats: current.chats, searchQuery: query));
    }
  }

  /// Creates or opens a DM with [otherUserId].
  /// Returns the [ChatModel] to navigate to, or null on error.
  Future<ChatModel?> createOrGetDirectChat(String otherUserId) async {
    try {
      final chatId = await _repo.createOrGetDirectChat(otherUserId);
      // Reload so the new chat appears in the list
      final chats = await _repo.fetchChats();
      if (state is MessagesSuccess) {
        emit(MessagesSuccess(
            chats: chats, searchQuery: (state as MessagesSuccess).searchQuery));
      } else {
        emit(MessagesSuccess(chats: chats));
      }
      
      try {
        return chats.firstWhere((c) => c.id == chatId);
      } catch (_) {
        // Fallback: fetch profile to populate otherMembers
        final profile = await ProfileRepo().fetchProfile(otherUserId);
        return ChatModel(
          id: chatId,
          isGroup: false,
          updatedAt: DateTime.now(),
          otherMembers: profile != null ? [profile] : [],
        );
      }
    } catch (e, stack) {
      debugPrint('Error creating or getting direct chat: $e\n$stack');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    return _repo.searchUsers(query);
  }

  @override
  Future<void> close() {
    _chatsChannel?.unsubscribe();
    return super.close();
  }
}
