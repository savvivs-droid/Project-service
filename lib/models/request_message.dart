/// Сообщение в чате по заявке — клиент и администратор обсуждают детали
/// и стоимость ремонта.
class RequestMessage {
  final String id;
  final String requestId;
  final String senderId;
  final String body;
  final DateTime createdAt;

  const RequestMessage({
    required this.id,
    required this.requestId,
    required this.senderId,
    required this.body,
    required this.createdAt,
  });

  factory RequestMessage.fromJson(Map<String, dynamic> json) {
    return RequestMessage(
      id: json['id'] as String,
      requestId: json['request_id'] as String,
      senderId: json['sender_id'] as String,
      body: json['body'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
