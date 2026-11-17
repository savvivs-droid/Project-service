import 'package:flutter/material.dart';

/// Техник сервиса — исполнитель визитов в планировщике администратора.
/// Своего входа в приложение у техников пока нет. См. technicians в
/// supabase/schema.sql.
class Technician {
  final String id;
  final String name;
  final String? phone;
  final Color color;
  final bool isActive;
  final int sortOrder;

  const Technician({
    required this.id,
    required this.name,
    required this.color,
    this.phone,
    this.isActive = true,
    this.sortOrder = 0,
  });

  /// Палитра на выбор при добавлении техника — достаточно контрастные
  /// друг к другу цвета, на которых читается белый текст.
  static const palette = [
    Color(0xFF2F9E63), // зелёный
    Color(0xFF2F6FED), // синий
    Color(0xFFF37012), // фирменный оранжевый
    Color(0xFF8E44AD), // фиолетовый
    Color(0xFFC4453B), // красный
    Color(0xFF02445A), // фирменный тил
  ];

  factory Technician.fromJson(Map<String, dynamic> json) {
    return Technician(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String?,
      color: colorFromHex(json['color'] as String?),
      isActive: json['is_active'] as bool? ?? true,
      sortOrder: json['sort_order'] as int? ?? 0,
    );
  }

  static Color colorFromHex(String? hex) {
    final digits = (hex ?? '').replaceFirst('#', '');
    final rgb = int.tryParse(digits, radix: 16);
    if (digits.length != 6 || rgb == null) return palette.first;
    return Color(0xFF000000 | rgb);
  }

  static String colorToHex(Color color) {
    String channel(double value) =>
        (value * 255).round().clamp(0, 255).toRadixString(16).padLeft(2, '0');
    return '#${channel(color.r)}${channel(color.g)}${channel(color.b)}'
        .toUpperCase();
  }
}
