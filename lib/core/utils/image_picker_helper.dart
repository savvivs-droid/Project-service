import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Выбирает фото и возвращает его байты, либо null, если пользователь
/// отменил выбор.
///
/// На вебе браузеры (в частности мобильный Safari) не дают напрямую
/// запустить камеру отдельной кнопкой — вместо этого сразу открываем
/// системный выбор файла: внутри него на телефоне всё равно есть кнопка
/// "Сделать фото" наравне с "Библиотекой фото", просто в интерфейсе
/// самого браузера/ОС, а не нашего приложения. В настоящем приложении на
/// iOS/Android (не в веб-демке) камера открывается напрямую по кнопке.
Future<Uint8List?> pickImageBytes(BuildContext context) async {
  if (kIsWeb) {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 85,
    );
    return file?.readAsBytes();
  }

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
