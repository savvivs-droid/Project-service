/// Запись в истории ремонта конкретной единицы оборудования.
class RepairHistoryEntry {
  final String id;
  final String equipmentId;
  final String? requestId;
  final DateTime performedAt;
  final String workDescription;
  final String? result;

  const RepairHistoryEntry({
    required this.id,
    required this.equipmentId,
    required this.performedAt,
    required this.workDescription,
    this.requestId,
    this.result,
  });

  factory RepairHistoryEntry.fromJson(Map<String, dynamic> json) {
    return RepairHistoryEntry(
      id: json['id'] as String,
      equipmentId: json['equipment_id'] as String,
      requestId: json['request_id'] as String?,
      performedAt: DateTime.parse(json['performed_at'] as String),
      workDescription: json['work_description'] as String,
      result: json['result'] as String?,
    );
  }
}
