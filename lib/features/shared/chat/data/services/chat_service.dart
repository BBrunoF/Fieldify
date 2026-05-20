import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../core/supabase/supabase_client.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';

class ChatService {
  String get _uid {
    final user = supabase.auth.currentUser;
    if (user == null) {
      throw const AuthException('No authenticated user.');
    }
    return user.id;
  }

  /// All chat threads for the current user (as client or pro), only for
  /// jobs that already have an assigned professional. Newest activity first.
  Future<List<Conversation>> fetchConversations() async {
    final uid = _uid;

    final requests = await supabase
        .from('service_requests')
        .select('id, title, status, client_id, pro_id, created_at')
        .or('client_id.eq.$uid,pro_id.eq.$uid')
        .not('pro_id', 'is', null)
        .neq('status', 'pending');

    final rows = (requests as List).cast<Map<String, dynamic>>();
    if (rows.isEmpty) return const [];

    final counterpartyIds = <String>{};
    for (final r in rows) {
      final clientId = r['client_id'] as String;
      final proId = r['pro_id'] as String?;
      counterpartyIds.add(clientId == uid ? (proId ?? '') : clientId);
    }
    counterpartyIds.removeWhere((id) => id.isEmpty);

    final profiles = await _fetchProfiles(counterpartyIds);
    final requestIds = rows.map((r) => r['id'] as String).toList();
    final lastMessages = await _fetchLastMessages(requestIds);

    final conversations = rows.map((r) {
      final requestId = r['id'] as String;
      final clientId = r['client_id'] as String;
      final proId = r['pro_id'] as String?;
      final counterpartyId = clientId == uid ? (proId ?? '') : clientId;
      final profile = profiles[counterpartyId];
      final last = lastMessages[requestId];

      return Conversation(
        requestId: requestId,
        jobTitle: (r['title'] ?? '') as String,
        jobStatus: (r['status'] ?? '') as String,
        counterpartyId: counterpartyId,
        counterpartyName:
            (profile?['full_name'] as String?)?.trim().isNotEmpty == true
                ? profile!['full_name'] as String
                : 'Unknown',
        counterpartyAvatarUrl: profile?['avatar_url'] as String?,
        lastMessagePreview: last?.previewFor(uid),
        lastMessageAt: last?.message.createdAt,
        lastMessageFromMe: last?.message.senderId == uid,
        unreadCount: 0,
      );
    }).toList();

    conversations.sort((a, b) => b.sortKey.compareTo(a.sortKey));
    return conversations;
  }

  Future<Map<String, Map<String, dynamic>>> _fetchProfiles(
    Set<String> ids,
  ) async {
    if (ids.isEmpty) return const {};
    final rows = await supabase
        .from('profiles')
        .select('id, full_name, avatar_url')
        .inFilter('id', ids.toList());
    return {
      for (final row in (rows as List).cast<Map<String, dynamic>>())
        row['id'] as String: row,
    };
  }

  Future<Map<String, _LastMessage>> _fetchLastMessages(
    List<String> requestIds,
  ) async {
    if (requestIds.isEmpty) return const {};
    final rows = await supabase
        .from('messages')
        .select()
        .inFilter('request_id', requestIds)
        .order('created_at', ascending: false);

    final result = <String, _LastMessage>{};
    for (final row in (rows as List).cast<Map<String, dynamic>>()) {
      final msg = Message.fromJson(row);
      result.putIfAbsent(msg.requestId, () => _LastMessage(msg));
    }
    return result;
  }

  Future<List<Message>> fetchHistory(String requestId) async {
    final rows = await supabase
        .from('messages')
        .select()
        .eq('request_id', requestId)
        .order('created_at', ascending: true);
    return (rows as List)
        .cast<Map<String, dynamic>>()
        .map(Message.fromJson)
        .toList();
  }

  /// Live stream of all messages for a job, ordered oldest-first.
  Stream<List<Message>> streamMessages(String requestId) {
    return supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('request_id', requestId)
        .order('created_at')
        .map(
          (rows) => rows
              .cast<Map<String, dynamic>>()
              .map(Message.fromJson)
              .toList(),
        );
  }

  /// Live stream over the user's messages — used to refresh the inbox.
  Stream<void> streamInboxSignal() {
    return supabase.from('messages').stream(primaryKey: ['id']).map((_) {});
  }

  Future<void> sendMessage(String requestId, String content) async {
    await supabase.from('messages').insert({
      'request_id': requestId,
      'sender_id': _uid,
      'content': content,
      'type': 'text',
    });
  }

  Future<void> proposeReschedule(
    String requestId,
    DateTime proposedAt, {
    String note = '',
  }) async {
    await supabase.from('messages').insert({
      'request_id': requestId,
      'sender_id': _uid,
      'content': note,
      'type': 'reschedule',
      'reschedule_proposed_at': proposedAt.toUtc().toIso8601String(),
      'reschedule_status': 'pending',
    });
  }

  /// Accept or reject a reschedule request. The DB trigger updates the
  /// job schedule when the status becomes 'accepted'.
  Future<void> respondReschedule(String messageId, bool accept) async {
    await supabase.from('messages').update({
      'reschedule_status': accept ? 'accepted' : 'rejected',
      'reschedule_responded_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', messageId);
  }

  Future<void> markRead(String requestId) async {
    await supabase
        .from('messages')
        .update({'read_at': DateTime.now().toUtc().toIso8601String()})
        .eq('request_id', requestId)
        .neq('sender_id', _uid)
        .isFilter('read_at', null);
  }
}

class _LastMessage {
  final Message message;
  const _LastMessage(this.message);

  String previewFor(String uid) {
    if (message.isReschedule) {
      return message.senderId == uid
          ? 'You proposed a new time'
          : 'Proposed a new time';
    }
    return message.content;
  }
}
