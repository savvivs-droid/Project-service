import '../core/constants/request_status.dart';

/// Заявка на ремонт одной или нескольких единиц оборудования.
///
/// Список [equipmentIds] не хранится в этой таблице напрямую — он
/// собирается из связующей таблицы service_request_equipment (см.
/// supabase/schema.sql), поэтому по умолчанию пуст и заполняется
/// отдельным запросом на уровне репозитория.
class ServiceRequest {
  final String id;
  final String establishmentId;
  final String clientId;
  final String description;
  final List<String> photos;
  final RequestStatus status;
  final DateTime createdAt;
  final DateTime? scheduledAt;
  final DateTime? completedAt;
  final String? technicianComment;
  final List<String> equipmentIds;

  const ServiceRequest({
    required this.id,
    required this.establishmentId,
    required this.clientId,
    required this.description,
    required this.status,
    required this.createdAt,
    this.photos = const [],
    this.scheduledAt,
    this.completedAt,
    this.technicianComment,
    this.equipmentIds = const [],
  });

  factory ServiceRequest.fromJson(Map<String, dynamic> json) {
    return ServiceRequest(
      id: json['id'] as String,
      establishmentId: json['establishment_id'] as String,
      clientId: json['client_id'] as String,
      description: json['description'] as String,
      photos: (json['photos'] as List<dynamic>? ?? const [])
          .map((e) => e as String)
          .toList(),
      status: RequestStatusX.fromValue(json['status'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      scheduledAt: json['scheduled_at'] == null
          ? null
          : DateTime.parse(json['scheduled_at'] as String),
      completedAt: json['completed_at'] == null
          ? null
          : DateTime.parse(json['completed_at'] as String),
      technicianComment: json['technician_comment'] as String?,
    );
  }
}
