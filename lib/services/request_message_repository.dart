import 'dart:async';

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

  /// Отмечает чат заявки прочитанным текущим пользователем "по сейчас" —
  /// сообщения от другой стороны до этого момента больше не считаются
  /// непрочитанными (см. unread_message_request_ids() в schema.sql).
  Future<void> markRead(String requestId) {
    final profileId = _client.auth.currentUser!.id;
    return _client.from('request_read_state').upsert(
      {
        'request_id': requestId,
        'profile_id': profileId,
        'last_read_at': DateTime.now().toIso8601String(),
      },
      onConflict: 'request_id,profile_id',
    );
  }

  Future<Set<String>> fetchUnreadRequestIds() async {
    final data = await _client.rpc('unread_message_request_ids');
    return (data as List<dynamic>).map((id) => id as String).toSet();
  }

  /// Живой набор id заявок с непрочитанными сообщениями — используется,
  /// чтобы показать индикатор на вкладках и карточках заявок сразу на
  /// всех экранах, а не только там, где открыт конкретный чат. Считать
  /// точный набор на клиенте по потоку сообщений неудобно (нужно ещё
  /// учитывать отметки прочтения) — вместо этого любое изменение в
  /// request_messages или request_read_state просто запускает пересчёт
  /// через unread_message_request_ids() на сервере.
  Stream<Set<String>> watchUnreadRequestIds() {
    final controller = StreamController<Set<String>>();

    Future<void> refresh() async {
      if (controller.isClosed) return;
      try {
        controller.add(await fetchUnreadRequestIds());
      } catch (_) {
        // Сеть могла на секунду пропасть — просто подождём следующего
        // события или ручного обновления.
      }
    }

    final channel = _client.channel('unread-request-ids')
      ..onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'request_messages',
        callback: (_) => refresh(),
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'request_read_state',
        callback: (_) => refresh(),
      )
      ..subscribe();

    unawaited(refresh());

    controller.onCancel = () {
      unawaited(_client.removeChannel(channel));
    };

    return controller.stream;
  }
}
