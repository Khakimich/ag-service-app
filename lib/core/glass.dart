import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform, kIsWeb;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

/// Главный выключатель размытия. Если на слабом телефоне или в браузере
/// главная начнёт подтормаживать при прокрутке, поставьте false:
/// стекло останется полупрозрачным, но без размытия фона.
// AG_WEBFAST1: размытие только в приложении на iPhone. В браузере (Safari на iPhone, веб-версия) — без размытия: оно сильно тормозит
final bool kGlassBlur = !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS; // AG_FIX3: Android — без размытия

/// Цвет светлой кромки стекла для текущей темы.
Color glassEdgeColor(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return isDark
      ? Colors.white.withValues(alpha: .13)
      : Colors.white.withValues(alpha: .90);
}

/// Стеклянная подложка: размытие фона, полупрозрачная заливка и мягкая тень.
/// Сама подстраивается под светлую и тёмную тему.
///
/// Внутрь можно класть InkWell: всплески нажатия рисуются поверх стекла.
class GlassSurface extends StatelessWidget {
  const GlassSurface({
    super.key,
    required this.child,
    this.radius = 22,
    this.blur = 18,
    this.shadow = true,
  });

  final Widget child;
  final double radius;
  final double blur;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderRadius = BorderRadius.circular(radius);

    final fillTop =
        isDark
            ? Colors.white.withValues(alpha: kGlassBlur ? .10 : .13)
            : Colors.white.withValues(alpha: kGlassBlur ? .78 : .92);
    final fillBottom =
        isDark
            ? Colors.white.withValues(alpha: kGlassBlur ? .04 : .08)
            : Colors.white.withValues(alpha: kGlassBlur ? .52 : .82);

    Widget content = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [fillTop, fillBottom],
        ),
      ),
      child: Material(type: MaterialType.transparency, child: child),
    );

    if (kGlassBlur && blur > 0) {
      content = BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: content,
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow:
            shadow
                ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? .28 : .06),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ]
                : null,
      ),
      child: ClipRRect(borderRadius: borderRadius, child: content),
    );
  }
}

/// Фон с мягкими цветными пятнами. Без него стеклу нечего размывать:
/// на ровном тёмном или светлом фоне эффект почти не виден.
class GlassBackground extends StatelessWidget {
  const GlassBackground({super.key, required this.child});

  final Widget child;

  static const _orange = Color(0xFFFF6A00);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cool = isDark ? const Color(0xFF7C9CFF) : const Color(0xFF2057DF);

    return Stack(
      children: [
        Positioned.fill(
          child: ColoredBox(color: theme.scaffoldBackgroundColor),
        ),
        Positioned(
          top: -130,
          right: -110,
          child: _GlassGlow(
            color: _orange.withValues(alpha: isDark ? .34 : .26),
            size: 380,
          ),
        ),
        Positioned(
          top: 300,
          left: -170,
          child: _GlassGlow(
            color: cool.withValues(alpha: isDark ? .20 : .16),
            size: 360,
          ),
        ),
        Positioned(
          bottom: -90,
          right: -130,
          child: _GlassGlow(
            color: _orange.withValues(alpha: isDark ? .24 : .20),
            size: 340,
          ),
        ),
        Positioned.fill(child: child),
      ],
    );
  }
}

class _GlassGlow extends StatelessWidget {
  const _GlassGlow({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withValues(alpha: 0)],
          ),
        ),
      ),
    );
  }
}
