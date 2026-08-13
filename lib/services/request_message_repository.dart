import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/request_message.dart';
import 'supabase_service.dart';

class RequestMessageRepository {
  final SupabaseClient _client = SupabaseService.client;

  /// Живой поток сообщений по заявке — новые сообщения (свои и чужие)
  /// появляются сами, без ручного обновления экрана (Supabase Realtime).
  Stream<List<RequestMessage>> watchMessages(String requestId) {
    return _client
        .from('request_messages')
        .stream(primaryKey: ['id'])
        .eq('request_id', requestId)
        .order('created_at')
        .map((rows) => rows.map(RequestMessage.fromJson).toList());
  }

  Future<void> send({required String requestId, required String body}) {
    final senderId = _client.auth.currentUser!.id;
    return _client.from('request_messages').insert({
      'request_id': requestId,
      'sender_id': senderId,
      'body': body,
    });
  }
}
