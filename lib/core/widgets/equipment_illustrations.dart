import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../constants/equipment_icons.dart';
import '../theme/app_theme.dart';

/// Плоские векторные иллюстрации категорий оборудования — силуэты
/// конкретных приборов (холодильник, печь, миксер и т. д.) в цветах
/// бренда (deep teal + service orange), а не иконки из стандартного
/// набора Material Icons. Рисуются через CustomPainter, без внешних
/// ассетов и пакетов — работает на любом экране и в любом разрешении.
CustomPainter equipmentIllustrationFor(EquipmentCategory category) {
  switch (category) {
    case EquipmentCategory.thermal:
      return const _ThermalIllustration();
    case EquipmentCategory.refrigeration:
      return const _RefrigerationIllustration();
    case EquipmentCategory.dishwashing:
      return const _DishwashingIllustration();
    case EquipmentCategory.foodPrep:
      return const _FoodPrepIllustration();
    case EquipmentCategory.pizzaBakery:
      return const _PizzaBakeryIllustration();
    case EquipmentCategory.bar:
      return const _BarIllustration();
    case EquipmentCategory.water:
      return const _WaterIllustration();
    case EquipmentCategory.other:
      return const _OtherIllustration();
  }
}

/// Общая база: тело — deep teal, детали/акценты — service orange,
/// более светлый оттенок teal — для второстепенных линий/теней.
abstract class _EquipmentPainter extends CustomPainter {
  const _EquipmentPainter();

  static const Color body = AppTheme.primary;
  static const Color bodyLight = Color(0xFF3D7488);
  static const Color accent = AppTheme.accent;

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Печь/конвектомат: корпус с круглым окном дверцы и панелью управления.
class _ThermalIllustration extends _EquipmentPainter {
  const _ThermalIllustration();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final bodyRect = Rect.fromLTWH(w * 0.14, h * 0.12, w * 0.72, h * 0.76);

    canvas.drawRRect(
      RRect.fromRectAndRadius(bodyRect, Radius.circular(w * 0.1)),
      Paint()..color = _EquipmentPainter.body,
    );

    // Панель управления вверху — 3 индикатора.
    for (var i = 0; i < 3; i++) {
      canvas.drawCircle(
        Offset(w * (0.30 + i * 0.14), h * 0.24),
        w * 0.03,
        Paint()..color = _EquipmentPainter.accent,
      );
    }

    // Окно дверцы.
    final windowCenter = Offset(w * 0.5, h * 0.62);
    canvas.drawCircle(
      windowCenter,
      w * 0.24,
      Paint()..color = Colors.white.withValues(alpha: 0.92),
    );
    canvas.drawCircle(
      windowCenter,
      w * 0.24,
      Paint()
        ..color = _EquipmentPainter.bodyLight
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.025,
    );
    canvas.drawCircle(
      windowCenter,
      w * 0.13,
      Paint()..color = _EquipmentPainter.accent.withValues(alpha: 0.85),
    );
  }
}

/// Холодильник/морозильник: два отсека с ручками.
class _RefrigerationIllustration extends _EquipmentPainter {
  const _RefrigerationIllustration();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final bodyRect = Rect.fromLTWH(w * 0.2, h * 0.08, w * 0.6, h * 0.84);
    final freezerRect = Rect.fromLTWH(
      bodyRect.left,
      bodyRect.top,
      bodyRect.width,
      bodyRect.height * 0.32,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(bodyRect, Radius.circular(w * 0.09)),
      Paint()..color = _EquipmentPainter.body,
    );

    // Морозильная камера — светлее, чтобы два отсека читались отдельно.
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        freezerRect,
        topLeft: Radius.circular(w * 0.09),
        topRight: Radius.circular(w * 0.09),
      ),
      Paint()..color = _EquipmentPainter.bodyLight,
    );
    // Тонкий зазор между отсеками поверх границы.
    canvas.drawRect(
      Rect.fromLTWH(bodyRect.left, freezerRect.bottom - h * 0.008, bodyRect.width, h * 0.016),
      Paint()..color = Colors.white.withValues(alpha: 0.5),
    );

    // Ручки — короткие горизонтальные планки у правого края каждой дверцы.
    final handlePaint = Paint()
      ..color = _EquipmentPainter.accent
      ..strokeWidth = w * 0.05
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(bodyRect.right - w * 0.1, freezerRect.top + freezerRect.height * 0.5),
      Offset(bodyRect.right - w * 0.02, freezerRect.top + freezerRect.height * 0.5),
      handlePaint,
    );
    final fridgeCenterY = freezerRect.bottom + (bodyRect.bottom - freezerRect.bottom) * 0.42;
    canvas.drawLine(
      Offset(bodyRect.right - w * 0.1, fridgeCenterY),
      Offset(bodyRect.right - w * 0.02, fridgeCenterY),
      handlePaint,
    );
  }
}

/// Посудомоечная машина: корпус с панелью управления и брызгами воды.
class _DishwashingIllustration extends _EquipmentPainter {
  const _DishwashingIllustration();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final bodyRect = Rect.fromLTWH(w * 0.16, h * 0.2, w * 0.68, h * 0.66);

    canvas.drawRRect(
      RRect.fromRectAndRadius(bodyRect, Radius.circular(w * 0.08)),
      Paint()..color = _EquipmentPainter.body,
    );

    // Панель управления.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(bodyRect.left, bodyRect.top, bodyRect.width, h * 0.12),
        Radius.circular(w * 0.06),
      ),
      Paint()..color = _EquipmentPainter.accent,
    );

    // Ручка дверцы.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.3, h * 0.42, w * 0.4, h * 0.045),
        Radius.circular(w * 0.02),
      ),
      Paint()..color = _EquipmentPainter.bodyLight,
    );

    // Капли воды.
    final dropPaint = Paint()..color = _EquipmentPainter.accent.withValues(alpha: 0.85);
    _drawDrop(canvas, Offset(w * 0.24, h * 0.9), w * 0.06, dropPaint);
    _drawDrop(canvas, Offset(w * 0.5, h * 0.96), w * 0.05, dropPaint);
    _drawDrop(canvas, Offset(w * 0.76, h * 0.9), w * 0.06, dropPaint);
  }
}

/// Оборудование для обработки продуктов: миксер на подставке с чашей.
class _FoodPrepIllustration extends _EquipmentPainter {
  const _FoodPrepIllustration();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Чаша.
    final bowlPath = Path()
      ..moveTo(w * 0.26, h * 0.58)
      ..lineTo(w * 0.74, h * 0.58)
      ..quadraticBezierTo(w * 0.7, h * 0.92, w * 0.5, h * 0.92)
      ..quadraticBezierTo(w * 0.3, h * 0.92, w * 0.26, h * 0.58)
      ..close();
    canvas.drawPath(bowlPath, Paint()..color = _EquipmentPainter.accent);

    // Основание колонны.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.58, h * 0.5, w * 0.16, h * 0.12),
        Radius.circular(w * 0.02),
      ),
      Paint()..color = _EquipmentPainter.body,
    );

    // Колонна изгибается дугой над чашей — характерный силуэт
    // планетарного миксера.
    final armPaint = Paint()
      ..color = _EquipmentPainter.body
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.1
      ..strokeCap = StrokeCap.round;
    final armPath = Path()
      ..moveTo(w * 0.66, h * 0.54)
      ..lineTo(w * 0.66, h * 0.22)
      ..quadraticBezierTo(w * 0.66, h * 0.1, w * 0.48, h * 0.1)
      ..quadraticBezierTo(w * 0.34, h * 0.1, w * 0.34, h * 0.24);
    canvas.drawPath(armPath, armPaint);

    // Насадка-венчик над чашей.
    canvas.drawCircle(
      Offset(w * 0.34, h * 0.3),
      w * 0.035,
      Paint()..color = _EquipmentPainter.bodyLight,
    );
  }
}

/// Пицца и пекарня: разрезанная на дольки пицца.
class _PizzaBakeryIllustration extends _EquipmentPainter {
  const _PizzaBakeryIllustration();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w * 0.5, h * 0.5);
    final radius = w * 0.38;

    canvas.drawCircle(center, radius, Paint()..color = _EquipmentPainter.accent);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = _EquipmentPainter.body
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.06,
    );

    // Линии-дольки.
    final sliceLinePaint = Paint()
      ..color = _EquipmentPainter.body.withValues(alpha: 0.9)
      ..strokeWidth = w * 0.025
      ..strokeCap = StrokeCap.round;
    for (final angleDeg in [0, 60, 120]) {
      final rad = angleDeg * math.pi / 180;
      final dx = radius * 0.94 * math.cos(rad);
      final dy = radius * 0.94 * math.sin(rad);
      canvas.drawLine(
        Offset(center.dx - dx, center.dy - dy),
        Offset(center.dx + dx, center.dy + dy),
        sliceLinePaint,
      );
    }

    // "Начинка" — точки.
    final toppingPaint = Paint()..color = _EquipmentPainter.body;
    for (final offset in [
      Offset(w * 0.5, h * 0.36),
      Offset(w * 0.38, h * 0.5),
      Offset(w * 0.62, h * 0.5),
      Offset(w * 0.5, h * 0.62),
    ]) {
      canvas.drawCircle(offset, w * 0.035, toppingPaint);
    }
  }
}

/// Бар и напитки: чашка кофе с блюдцем и паром.
class _BarIllustration extends _EquipmentPainter {
  const _BarIllustration();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Блюдце.
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(w * 0.48, h * 0.78), width: w * 0.6, height: h * 0.09),
      Paint()..color = _EquipmentPainter.bodyLight,
    );

    // Чашка (трапеция).
    final cupPath = Path()
      ..moveTo(w * 0.28, h * 0.4)
      ..lineTo(w * 0.68, h * 0.4)
      ..lineTo(w * 0.6, h * 0.72)
      ..lineTo(w * 0.36, h * 0.72)
      ..close();
    canvas.drawPath(cupPath, Paint()..color = _EquipmentPainter.body);

    // Ручка.
    canvas.drawArc(
      Rect.fromLTWH(w * 0.62, h * 0.44, w * 0.22, h * 0.2),
      -1.3,
      2.6,
      false,
      Paint()
        ..color = _EquipmentPainter.body
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.05,
    );

    // Пар.
    final steamPaint = Paint()
      ..color = _EquipmentPainter.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.035
      ..strokeCap = StrokeCap.round;
    _drawSteamLine(canvas, w * 0.38, h, steamPaint);
    _drawSteamLine(canvas, w * 0.56, h, steamPaint);
  }

  void _drawSteamLine(Canvas canvas, double x, double h, Paint paint) {
    final path = Path()
      ..moveTo(x, h * 0.32)
      ..quadraticBezierTo(x - h * 0.06, h * 0.24, x, h * 0.16)
      ..quadraticBezierTo(x + h * 0.06, h * 0.1, x, h * 0.04);
    canvas.drawPath(path, paint);
  }
}

/// Вода и водоподготовка: капля с волнами.
class _WaterIllustration extends _EquipmentPainter {
  const _WaterIllustration();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Классическая форма капли: острый верх + круглый низ (треугольник
    // сглажен кривыми, переходящими в нижнюю полуокружность).
    const cx = 0.5, apexY = 0.08, bulgeY = 0.52, r = 0.26;
    final dropPath = Path()
      ..moveTo(w * cx, h * apexY)
      ..quadraticBezierTo(w * (cx - r * 1.15), h * (apexY + (bulgeY - apexY) * 0.65),
          w * (cx - r), h * bulgeY)
      ..arcToPoint(
        Offset(w * (cx + r), h * bulgeY),
        radius: Radius.circular(w * r),
        clockwise: false,
        largeArc: true,
      )
      ..quadraticBezierTo(w * (cx + r * 1.15), h * (apexY + (bulgeY - apexY) * 0.65),
          w * cx, h * apexY)
      ..close();
    canvas.drawPath(dropPath, Paint()..color = _EquipmentPainter.body);

    // Блик — намёк на объём.
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.4, h * 0.58), width: w * 0.14, height: h * 0.2),
      Paint()..color = Colors.white.withValues(alpha: 0.45),
    );

    // Волна у основания — водоподготовка / поток.
    final wavePaint = Paint()
      ..color = _EquipmentPainter.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.045
      ..strokeCap = StrokeCap.round;
    final wavePath = Path()
      ..moveTo(w * 0.18, h * 0.9)
      ..quadraticBezierTo(w * 0.32, h * 0.82, w * 0.5, h * 0.9)
      ..quadraticBezierTo(w * 0.68, h * 0.98, w * 0.82, h * 0.9);
    canvas.drawPath(wavePath, wavePaint);
  }
}

/// "Другое": ящик с инструментами.
class _OtherIllustration extends _EquipmentPainter {
  const _OtherIllustration();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Ручка.
    canvas.drawArc(
      Rect.fromLTWH(w * 0.32, h * 0.1, w * 0.36, h * 0.32),
      3.4,
      2.6,
      false,
      Paint()
        ..color = _EquipmentPainter.bodyLight
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.05,
    );

    // Корпус ящика.
    final boxRect = Rect.fromLTWH(w * 0.16, h * 0.42, w * 0.68, h * 0.42);
    canvas.drawRRect(
      RRect.fromRectAndRadius(boxRect, Radius.circular(w * 0.06)),
      Paint()..color = _EquipmentPainter.body,
    );

    // Разделительная линия крышки.
    canvas.drawRect(
      Rect.fromLTWH(boxRect.left, h * 0.55, boxRect.width, h * 0.02),
      Paint()..color = _EquipmentPainter.bodyLight,
    );

    // Защёлка.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.44, h * 0.5, w * 0.12, h * 0.1),
        Radius.circular(w * 0.02),
      ),
      Paint()..color = _EquipmentPainter.accent,
    );
  }
}

void _drawDrop(Canvas canvas, Offset tip, double size, Paint paint) {
  final path = Path()
    ..moveTo(tip.dx, tip.dy - size * 2)
    ..quadraticBezierTo(tip.dx + size, tip.dy - size * 0.4, tip.dx, tip.dy)
    ..quadraticBezierTo(tip.dx - size, tip.dy - size * 0.4, tip.dx, tip.dy - size * 2)
    ..close();
  canvas.drawPath(path, paint);
}
