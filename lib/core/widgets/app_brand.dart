import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Логотип FixMyGastro — иконка (вилка + ложка + гаечные ключи) и
/// название, в двух размерах. Компактный вариант — для шапки (AppBar),
/// крупный — для экранов входа и регистрации.
///
/// AppBar всегда тёмно-бирюзовый (deep teal), поэтому здесь и в
/// [AppBrandIcon] используется белая инверсия знака (logo_mark_white.png,
/// см. Brand Book 2026, раздел 3 "Инверсия") — полноцветная версия
/// (teal-иконка на teal-фоне) была бы не видна.
class AppBrandTitle extends StatelessWidget {
  const AppBrandTitle({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset('assets/brand/logo_mark_white.png', width: 26, height: 26),
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
    return Image.asset('assets/brand/logo_mark_white.png', width: size, height: size);
  }
}

/// Заголовок AppBar, где название FixMyGastro всегда видно первым, а
/// специфичный для экрана текст (если есть) идёт следом через
/// разделитель и обрезается многоточием, если места не хватает —
/// бренд не должен пропадать при переходе вглубь приложения.
class AppBrandAppBarTitle extends StatelessWidget {
  const AppBrandAppBarTitle({super.key, this.subtitle});

  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    if (subtitle == null || subtitle!.isEmpty) return const AppBrandTitle();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const AppBrandTitle(),
        const SizedBox(width: 10),
        Container(width: 1, height: 18, color: AppTheme.onPrimary.withValues(alpha: 0.4)),
        const SizedBox(width: 10),
        Flexible(
          child: Text(subtitle!, overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}

/// Крупный логотип для экрана входа/регистрации — полноцветная версия
/// знака (teal + orange) прямо на светлом фоне экрана, без тёмной
/// подложки: так задаёт "Основную версию" Brand Book 2026 (раздел 2).
class AppBrandLockup extends StatelessWidget {
  const AppBrandLockup({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset('assets/brand/logo_mark.png', width: 92, height: 92),
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
    // "Название FixMy остаётся teal, Gastro — orange" — Brand Book
    // 2026, раздел 2. На тёмном AppBar teal заменяется на белый
    // (см. onPrimary), чтобы остаться читаемым.
    final baseColor = dark ? AppTheme.primary : AppTheme.onPrimary;
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: 'FixMy',
            style: TextStyle(color: baseColor, fontWeight: FontWeight.w600),
          ),
          const TextSpan(
            text: 'Gastro',
            style: TextStyle(
              color: AppTheme.accent,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
      style: TextStyle(fontSize: fontSize, letterSpacing: -0.3),
    );
  }
}
