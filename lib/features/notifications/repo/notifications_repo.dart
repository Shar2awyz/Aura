import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification_model.dart';

class NotificationsRepo {
  final _client = Supabase.instance.client;

  String? get _currentUserId => _client.auth.currentUser?.id;

  Future<List<NotificationModel>> fetchNotifications() async {
    final userId = _currentUserId;
    if (userId == null) return [];

    final data = await _client
        .from('notifications')
        .select('*, profiles!sender_id(*)')
        .eq('receiver_id', userId)
        .order('created_at', ascending: false)
        .limit(50);

    return (data as List)
        .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> markAllAsRead() async {
    final userId = _currentUserId;
    if (userId == null) return;

    await _client
        .from('notifications')
        .update({'is_read': true})
        .eq('receiver_id', userId)
        .eq('is_read', false);
  }

  Future<void> acceptFollowRequest({
    required String followerId,
    required String notificationId,
  }) async {
    final userId = _currentUserId;
    if (userId == null) return;

    try {
      // 1. Add to followers table
      await _client.from('followers').insert({
        'follower_id': followerId,
        'following_id': userId,
      });

      // 2. Adjust follow counts
      await _adjustCount(userId: userId, column: 'followers_count', delta: 1);
      await _adjustCount(userId: followerId, column: 'following_count', delta: 1);

      // 3. Update the notification to indicate it is accepted
      await _client.from('notifications').update({
        'target_type': 'accepted',
        'is_read': true,
      }).eq('id', notificationId);

      // 4. Send a notification to the follower that their request was accepted
      await _client.from('notifications').insert({
        'receiver_id': followerId,
        'sender_id': userId,
        'type': 'follow',
        'target_type': 'accept',
      });
    } catch (e, s) {
      debugPrint('Error accepting follow request: $e\n$s');
      rethrow;
    }
  }

  Future<void> declineFollowRequest({
    required String notificationId,
  }) async {
    try {
      // Simply delete the request notification
      await _client.from('notifications').delete().eq('id', notificationId);
    } catch (e, s) {
      debugPrint('Error declining follow request: $e\n$s');
      rethrow;
    }
  }

  Future<void> _adjustCount({
    required String userId,
    required String column,
    required int delta,
  }) async {
    try {
      final row = await _client
          .from('profiles')
          .select(column)
          .eq('id', userId)
          .single();
      final current = (row[column] as int?) ?? 0;
      final updated = (current + delta).clamp(0, 999999999);
      await _client.from('profiles').update({column: updated}).eq('id', userId);
    } catch (e, s) {
      debugPrint('Error adjusting count for $userId column $column: $e\n$s');
    }
  }

  Future<Map<String, dynamic>?> fetchSenderProfile(String senderId) async {
    return await _client
        .from('profiles')
        .select('username, avatar_url')
        .eq('id', senderId)
        .maybeSingle();
  }

  RealtimeChannel subscribeToNotifications(void Function(Map<String, dynamic> row) onNew) {
    final userId = _currentUserId;
    return _client
        .channel('public_notifications_updates')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'receiver_id',
            value: userId ?? '',
          ),
          callback: (payload) {
            final row = payload.newRecord;
            if (row.isNotEmpty) {
              onNew(row);
            }
          },
        )
        .subscribe();
  }
}
