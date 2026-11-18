import 'package:flutter/material.dart';

/// Открывает фото на весь экран с возможностью зума (pinch-to-zoom) и
/// закрытием по тапу или системной кнопке "назад". Используется везде,
/// где показывается настоящее фото конкретной единицы оборудования
/// (Equipment.photos) — в отличие от стоковых фото категорий/видов,
/// которые не разворачиваются.
Future<void> openFullscreenPhoto(BuildContext context, String url) {
  return Navigator.of(context).push(
    PageRouteBuilder<void>(
      opaque: false,
      barrierColor: Colors.black,
      pageBuilder: (context, animation, secondaryAnimation) => FadeTransition(
        opacity: animation,
        child: _FullscreenPhotoView(url: url),
      ),
    ),
  );
}

class _FullscreenPhotoView extends StatelessWidget {
  const _FullscreenPhotoView({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Stack(
            children: [
              Center(
                child: InteractiveViewer(
                  maxScale: 4,
                  child: Image.network(url, fit: BoxFit.contain),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
