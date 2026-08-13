import 'package:flutter/material.dart';

/// Статус заявки на ремонт.
///
/// Значения совпадают со значениями enum request_status в базе данных.
/// Жизненный цикл: newRequest -> scheduled -> done (либо -> cancelled).
enum RequestStatus { newRequest, scheduled, done, cancelled }

extension RequestStatusX on RequestStatus {
  String get value => switch (this) {
        RequestStatus.newRequest => 'new',
        RequestStatus.scheduled => 'scheduled',
        RequestStatus.done => 'done',
        RequestStatus.cancelled => 'cancelled',
      };

  String get label => switch (this) {
        RequestStatus.newRequest => 'Новая',
        RequestStatus.scheduled => 'Согласовано время',
        RequestStatus.done => 'Выполнено',
        RequestStatus.cancelled => 'Отменено',
      };

  /// Служебный цвет статуса — намеренно отдельный от основного цвета
  /// бренда (см. AppTheme). Зелёный — заявка ещё в работе (новая или
  /// согласовано время), синий — выполнена, красный — отменена.
  Color get color => switch (this) {
        RequestStatus.newRequest => const Color(0xFF2F9E63),
        RequestStatus.scheduled => const Color(0xFF2F9E63),
        RequestStatus.done => const Color(0xFF2F6FED),
        RequestStatus.cancelled => const Color(0xFFC4453B),
      };

  /// Новая или согласовано время — заявка ещё в работе, а не закрыта.
  bool get isActive =>
      this == RequestStatus.newRequest || this == RequestStatus.scheduled;

  static RequestStatus fromValue(String value) {
    return RequestStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => RequestStatus.newRequest,
    );
  }
}
