import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/constants/request_status.dart';
import '../models/request_message.dart';
import 'supabase_service.dart';

/// Заявки с непрочитанными сообщениями, разложенные по вкладкам — чтобы
/// красная точка на вкладке "Активные" горела только из-за активных
/// заявок, а на "Выполненные" — только из-за закрытых.
class UnreadRequests {
  const UnreadRequests({this.active = const {}, this.closed = const {}});

  final Set<String> active;
  final Set<String> closed;

  Set<String> get all => {...active, ...closed};

  bool contains(String requestId) =>
      active.contains(requestId) || closed.contains(requestId);
}

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
        // В UTC: "голое" локальное время база приняла бы за UTC, и отметка
        // прочтения уехала бы на час-два вперёд.
        'last_read_at': DateTime.now().toUtc().toIso8601String(),
      },
      onConflict: 'request_id,profile_id',
    );
  }

  Future<UnreadRequests> fetchUnreadRequests() async {
    final data = await _client.rpc('unread_message_request_ids');
    final ids = (data as List<dynamic>).map((id) => id as String).toList();
    if (ids.isEmpty) return const UnreadRequests();

    final rows = await _client
        .from('service_requests')
        .select('id, status')
        .inFilter('id', ids);
    final active = <String>{};
    final closed = <String>{};
    for (final row in rows as List<dynamic>) {
      final map = row as Map<String, dynamic>;
      final status = RequestStatus.fromValue(map['status'] as String);
      (status.isActive ? active : closed).add(map['id'] as String);
    }
    return UnreadRequests(active: active, closed: closed);
  }

  /// Живой набор id заявок с непрочитанными сообщениями — используется,
  /// чтобы показать индикатор на вкладках и карточках заявок сразу на
  /// всех экранах, а не только там, где открыт конкретный чат. Считать
  /// точный набор на клиенте по потоку сообщений неудобно (нужно ещё
  /// учитывать отметки прочтения) — вместо этого любое изменение в
  /// request_messages или request_read_state просто запускает пересчёт
  /// через unread_message_request_ids() на сервере.
  Stream<UnreadRequests> watchUnreadRequests() {
    final controller = StreamController<UnreadRequests>();

    Future<void> refresh() async {
      if (controller.isClosed) return;
      try {
        controller.add(await fetchUnreadRequests());
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
      // Заявку закрыли/вернули в работу — точка переезжает между вкладками.
      ..onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'service_requests',
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
