import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/technician.dart';
import 'supabase_service.dart';

/// Техники сервиса — читает и меняет только администратор (RLS, см.
/// technicians в supabase/schema.sql).
class TechnicianRepository {
  final SupabaseClient _client = SupabaseService.client;

  /// [includeHidden] — вместе со скрытыми (для экрана управления
  /// техниками и подписи старых визитов в планировщике).
  Future<List<Technician>> fetchAll({bool includeHidden = false}) async {
    var query = _client.from('technicians').select();
    if (!includeHidden) query = query.eq('is_active', true);
    final data = await query.order('sort_order').order('created_at');
    return (data as List<dynamic>)
        .map((row) => Technician.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<void> create({
    required String name,
    required String? phone,
    required Color color,
    required int sortOrder,
  }) {
    return _client.from('technicians').insert({
      'name': name,
      'phone': phone,
      'color': Technician.colorToHex(color),
      'sort_order': sortOrder,
    });
  }

  Future<void> update({
    required String id,
    required String name,
    required String? phone,
    required Color color,
    required bool isActive,
  }) {
    return _client.from('technicians').update({
      'name': name,
      'phone': phone,
      'color': Technician.colorToHex(color),
      'is_active': isActive,
    }).eq('id', id);
  }
}
