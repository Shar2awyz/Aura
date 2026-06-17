import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/cloudinary_service.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';

class MessagesRepo {
  final _client = Supabase.instance.client;

  String? get _currentUserId => _client.auth.currentUser?.id;

  // ── Chats ─────────────────────────────────────────────────────────────────

  Future<List<ChatModel>> fetchChats() async {
    final userId = _currentUserId;
    if (userId == null) return [];

    final memberships = await _client
        .from('chat_members')
        .select('chat_id')
        .eq('user_id', userId);

    final chatIds =
        (memberships as List).map((m) => m['chat_id'] as String).toList();
    if (chatIds.isEmpty) return [];

    final data = await _client
        .from('chats')
        .select('*, chat_members(user_id, profiles(*))')
        .inFilter('id', chatIds)
        .order('updated_at', ascending: false);

    final chats = (data as List)
        .map((e) => ChatModel.fromJson(e as Map<String, dynamic>, userId))
        .toList();

    // Compute unread counts from is_seen column
    final unread = await _fetchUnreadCounts(chatIds, userId);
    return chats
        .map((c) => c.copyWith(unreadCount: unread[c.id] ?? 0))
        .toList();
  }

  Future<Map<String, int>> _fetchUnreadCounts(
      List<String> chatIds, String userId) async {
    if (chatIds.isEmpty) return {};
    final rows = await _client
        .from('messages')
        .select('chat_id')
        .inFilter('chat_id', chatIds)
        .eq('is_seen', false)
        .neq('sender_id', userId);

    final counts = <String, int>{};
    for (final row in (rows as List)) {
      final id = row['chat_id'] as String;
      counts[id] = (counts[id] ?? 0) + 1;
    }
    return counts;
  }

  /// Finds an existing 1-on-1 chat with [otherUserId] or creates one.
  Future<String> createOrGetDirectChat(String otherUserId) async {
    final userId = _currentUserId;
    if (userId == null) throw Exception('Not authenticated');

    // My chat IDs
    final mine = await _client
        .from('chat_members')
        .select('chat_id')
        .eq('user_id', userId);
    final myChatIds =
        (mine as List).map((m) => m['chat_id'] as String).toSet();

    // Their chat IDs
    final theirs = await _client
        .from('chat_members')
        .select('chat_id')
        .eq('user_id', otherUserId);
    final theirChatIds =
        (theirs as List).map((m) => m['chat_id'] as String).toSet();

    final common = myChatIds.intersection(theirChatIds).toList();

    if (common.isNotEmpty) {
      final existing = await _client
          .from('chats')
          .select('id')
          .inFilter('id', common)
          .eq('is_group', false)
          .limit(1)
          .maybeSingle();
      if (existing != null) return existing['id'] as String;
    }

    // Create new DM chat
    final chat = await _client
        .from('chats')
        .insert({'is_group': false})
        .select()
        .single();
    final chatId = chat['id'] as String;

    await _client.from('chat_members').insert([
      {'chat_id': chatId, 'user_id': userId},
      {'chat_id': chatId, 'user_id': otherUserId},
    ]);

    return chatId;
  }

  // ── Messages ──────────────────────────────────────────────────────────────

  Future<List<MessageModel>> fetchMessages(String chatId) async {
    final data = await _client
        .from('messages')
        .select('*, profiles(*)')
        .eq('chat_id', chatId)
        .eq('is_deleted', false)
        .order('created_at', ascending: false)
        .limit(50);

    final messages = (data as List)
        .map((e) => MessageModel.fromJson(e as Map<String, dynamic>))
        .toList();

    // Attach replied-to messages from the same batch (avoids extra queries)
    final msgMap = {for (final m in messages) m.id: m};
    return messages.map((m) {
      if (m.replyToMessageId != null && msgMap.containsKey(m.replyToMessageId)) {
        return m.copyWith(replyToMessage: msgMap[m.replyToMessageId]);
      }
      return m;
    }).toList();
  }

  Future<MessageModel?> fetchMessageById(String messageId) async {
    final data = await _client
        .from('messages')
        .select('*, profiles(*)')
        .eq('id', messageId)
        .maybeSingle();
    if (data == null) return null;
    return MessageModel.fromJson(data);
  }

  Future<String?> sendTextMessage({
    required String chatId,
    required String content,
    String? replyToMessageId,
  }) async {
    final userId = _currentUserId;
    if (userId == null) return null;

    final msgData = <String, dynamic>{
      'chat_id': chatId,
      'sender_id': userId,
      'message_type': 'text',
      'content': content,
    };
    if (replyToMessageId != null) {
      msgData['reply_to_message_id'] = replyToMessageId;
    }

    final result = await _client
        .from('messages')
        .insert(msgData)
        .select('id')
        .single();
    await _client.from('chats').update({
      'last_message': content,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', chatId);
    return result['id'] as String?;
  }

  Future<String?> sendMediaMessage({
    required String chatId,
    String? filePath,
    Uint8List? fileBytes,
    required String messageType,
    String? fileName,
    String? webUrl,
    String? replyToMessageId,
  }) async {
    final userId = _currentUserId;
    if (userId == null) return null;

    String? mediaUrl;
    if (webUrl != null && webUrl.trim().isNotEmpty) {
      mediaUrl = webUrl.trim();
    } else {
      final resourceType = CloudinaryService.resourceTypeFor(messageType);
      mediaUrl = await CloudinaryService.uploadFile(
        filePath: filePath,
        fileBytes: fileBytes,
        fileName: fileName ?? 'message_file',
        resourceType: resourceType,
      );
    }
    if (mediaUrl == null) return null;

    final preview = _previewFor(messageType);
    final msgData = <String, dynamic>{
      'chat_id': chatId,
      'sender_id': userId,
      'message_type': messageType,
      'media_url': mediaUrl,
    };
    if (fileName != null) msgData['file_name'] = fileName;
    if (replyToMessageId != null) {
      msgData['reply_to_message_id'] = replyToMessageId;
    }

    final result = await _client
        .from('messages')
        .insert(msgData)
        .select('id')
        .single();
    await _client.from('chats').update({
      'last_message': preview,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', chatId);
    return result['id'] as String?;
  }

  Future<void> reactToMessage(String messageId, String? emoji) async {
    await _client
        .from('messages')
        .update({'reaction': emoji}).eq('id', messageId);
  }

  Future<void> unsendMessage(String messageId) async {
    await _client
        .from('messages')
        .update({'is_deleted': true, 'content': null, 'media_url': null})
        .eq('id', messageId);
  }

  Future<void> markMessagesAsSeen(String chatId) async {
    final userId = _currentUserId;
    if (userId == null) return;
    await _client
        .from('messages')
        .update({'is_seen': true})
        .eq('chat_id', chatId)
        .eq('is_seen', false)
        .neq('sender_id', userId);
  }

  // ── Search users ──────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    if (query.trim().isEmpty) return [];
    final userId = _currentUserId;
    final data = await _client
        .from('profiles')
        .select('id, username, full_name, avatar_url')
        .ilike('username', '%${query.trim()}%')
        .limit(20);
    return (data as List)
        .cast<Map<String, dynamic>>()
        .where((u) => u['id'] != userId)
        .toList();
  }

  // ── Realtime ──────────────────────────────────────────────────────────────

  /// Subscribes to INSERT and UPDATE events on messages for [chatId].
  /// [onNew] fires for new messages, [onUpdated] fires for reaction/unsend updates.
  RealtimeChannel subscribeToMessages(
    String chatId,
    void Function(MessageModel) onNew,
    void Function(MessageModel) onUpdated,
  ) {
    return _client
        .channel('messages:$chatId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'chat_id',
            value: chatId,
          ),
          callback: (payload) {
            final row = payload.newRecord;
            if (row.isNotEmpty) {
              // Fetch full message with profile join
              fetchMessageById(row['id'] as String).then((msg) {
                if (msg != null) onNew(msg);
              });
            }
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'chat_id',
            value: chatId,
          ),
          callback: (payload) {
            final row = payload.newRecord;
            if (row.isNotEmpty) onUpdated(MessageModel.fromJson(row));
          },
        )
        .subscribe();
  }

  /// Subscribes to chat row updates and new message events.
  RealtimeChannel subscribeToChats({
    required void Function() onChatUpdate,
    required void Function(Map<String, dynamic> messageRecord) onNewMessage,
  }) {
    return _client
        .channel('chats_and_messages_updates')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'chats',
          callback: (_) => onChatUpdate(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          callback: (payload) {
            onNewMessage(payload.newRecord);
            onChatUpdate();
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'messages',
          callback: (_) => onChatUpdate(),
        )
        .subscribe();
  }

  // ── Typing presence ───────────────────────────────────────────────────────

  RealtimeChannel createTypingChannel(String chatId) {
    return _client.channel('typing:$chatId');
  }

  Future<void> trackTyping(
      RealtimeChannel channel, String username, bool isTyping) async {
    if (isTyping) {
      await channel.track({'username': username, 'typing': true});
    } else {
      await channel.untrack();
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _previewFor(String type) {
    switch (type) {
      case 'image':
        return '📷 Photo';
      case 'video':
        return '🎥 Video';
      case 'audio':
        return '🎙 Audio message';
      default:
        return '📄 File';
    }
  }
}
