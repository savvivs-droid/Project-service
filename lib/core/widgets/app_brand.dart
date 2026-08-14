import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Логотип FixMyGastro — иконка (вилка + гаечный ключ) и название,
/// в двух размерах. Компактный вариант — для шапки (AppBar), крупный —
/// для экранов входа и регистрации.
class AppBrandTitle extends StatelessWidget {
  const AppBrandTitle({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset('assets/brand/logo_mark.png', width: 26, height: 26),
        const SizedBox(width: 10),
        const _Wordmark(fontSize: 19),
      ],
    );
  }
}

/// Просто иконка бренда — для шапок, где название экрана своё
/// ("Регистрация" и т. п.), но фирменный значок всё равно должен быть виден.
class AppBrandIcon extends StatelessWidget {
  const AppBrandIcon({super.key, this.size = 24});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset('assets/brand/logo_mark.png', width: size, height: size);
  }
}

class AppBrandLockup extends StatelessWidget {
  const AppBrandLockup({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: AppTheme.primary,
            borderRadius: BorderRadius.circular(18),
          ),
          padding: const EdgeInsets.all(14),
          child: Image.asset('assets/brand/logo_mark.png'),
        ),
        const SizedBox(height: 14),
        const _Wordmark(fontSize: 26, dark: true),
      ],
    );
  }
}

class _Wordmark extends StatelessWidget {
  const _Wordmark({required this.fontSize, this.dark = false});

  final double fontSize;

  /// true — тёмный текст для светлого фона (экраны входа/регистрации),
  /// false — кремовый текст для тёмного AppBar.
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final baseColor = dark ? AppTheme.primary : AppTheme.onPrimary;
    return Text.rich(
      TextSpan(
        children: [
          const TextSpan(
            text: 'Fix',
            style: TextStyle(
              color: AppTheme.accent,
              fontWeight: FontWeight.w800,
            ),
          ),
          TextSpan(
            text: 'MyGastro',
            style: TextStyle(color: baseColor, fontWeight: FontWeight.w600),
          ),
        ],
      ),
      style: TextStyle(fontSize: fontSize, letterSpacing: -0.3),
    );
  }
}
