import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Показывает выбор "Камера / Галерея" и возвращает байты выбранного
/// фото, либо null, если пользователь отменил выбор.
Future<Uint8List?> pickImageBytes(BuildContext context) async {
  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: const Text('Камера'),
            onTap: () => Navigator.of(context).pop(ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Галерея'),
            onTap: () => Navigator.of(context).pop(ImageSource.gallery),
          ),
        ],
      ),
    ),
  );
  if (source == null) return null;

  final file = await ImagePicker().pickImage(
    source: source,
    maxWidth: 1600,
    imageQuality: 85,
  );
  if (file == null) return null;

  return file.readAsBytes();
}
