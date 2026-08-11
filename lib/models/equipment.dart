import '../core/constants/equipment_status.dart';

/// Единица кухонного оборудования, установленная в заведении.
class Equipment {
  final String id;
  final String establishmentId;
  final String type;
  final String? model;
  final String? stickerCode;
  final List<String> photos;
  final DateTime? installedAt;
  final EquipmentStatus status;

  const Equipment({
    required this.id,
    required this.establishmentId,
    required this.type,
    required this.status,
    this.model,
    this.stickerCode,
    this.photos = const [],
    this.installedAt,
  });

  factory Equipment.fromJson(Map<String, dynamic> json) {
    return Equipment(
      id: json['id'] as String,
      establishmentId: json['establishment_id'] as String,
      type: json['type'] as String,
      model: json['model'] as String?,
      stickerCode: json['sticker_code'] as String?,
      photos: (json['photos'] as List<dynamic>? ?? const [])
          .map((e) => e as String)
          .toList(),
      installedAt: json['installed_at'] == null
          ? null
          : DateTime.parse(json['installed_at'] as String),
      status: EquipmentStatusX.fromValue(json['status'] as String),
    );
  }
}
