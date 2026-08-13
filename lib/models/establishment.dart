/// Заведение-клиент (кафе, ресторан, фастфуд), которое обслуживает
/// сервисная компания.
class Establishment {
  final String id;
  final String name;
  final String? address;
  final String? contactPhone;
  final String? ico;
  final String? entrancePhotoUrl;
  final DateTime connectedAt;

  const Establishment({
    required this.id,
    required this.name,
    required this.connectedAt,
    this.address,
    this.contactPhone,
    this.ico,
    this.entrancePhotoUrl,
  });

  factory Establishment.fromJson(Map<String, dynamic> json) {
    return Establishment(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String?,
      contactPhone: json['contact_phone'] as String?,
      ico: json['ico'] as String?,
      entrancePhotoUrl: json['entrance_photo_url'] as String?,
      connectedAt: DateTime.parse(json['connected_at'] as String),
    );
  }
}
