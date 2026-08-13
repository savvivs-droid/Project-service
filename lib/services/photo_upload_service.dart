import 'dart:math';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_service.dart';

/// Загрузка фото в общий бакет Supabase Storage "equipment-photos"
/// (см. supabase/schema.sql, раздел 8) — используется и для фото
/// оборудования/стикера, и для фото входной группы заведения.
class PhotoUploadService {
  static const _bucket = 'equipment-photos';

  final SupabaseClient _client = SupabaseService.client;

  /// Загружает одну фотографию в подпапку [folder] и возвращает
  /// публичную ссылку на неё.
  Future<String> upload({
    required String folder,
    required Uint8List bytes,
  }) async {
    final random = Random().nextInt(1 << 32).toRadixString(16);
    final path =
        '$folder/${DateTime.now().microsecondsSinceEpoch}_$random.jpg';

    await _client.storage.from(_bucket).uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(contentType: 'image/jpeg'),
        );

    return _client.storage.from(_bucket).getPublicUrl(path);
  }
}
