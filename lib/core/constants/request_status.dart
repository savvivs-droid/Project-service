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

  static RequestStatus fromValue(String value) {
    return RequestStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => RequestStatus.newRequest,
    );
  }
}
