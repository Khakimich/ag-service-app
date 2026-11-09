import 'package:flutter/material.dart';

import 'theme.dart';

/// Круг-волна в месте касания. Работает поверх всего приложения.
class TapRipple extends StatefulWidget {
  const TapRipple({super.key, required this.child});

  final Widget child;

  @override
  State<TapRipple> createState() => _TapRippleState();
}

class _Dot {
  _Dot(this.id, this.position);

  final int id;
  final Offset position;
}

class _TapRippleState extends State<TapRipple> {
  final List<_Dot> _dots = [];
  int _nextId = 0;

  void _add(Offset position) {
    final dot = _Dot(_nextId++, position);
    setState(() => _dots.add(dot));
    Future.delayed(const Duration(milliseconds: 560), () {
      if (!mounted) return;
      setState(() => _dots.remove(dot));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (event) => _add(event.localPosition),
      child: Stack(
        fit: StackFit.expand,
        children: [
          widget.child,
          for (final dot in _dots)
            Positioned(
              key: ValueKey(dot.id),
              left: dot.position.dx - 44,
              top: dot.position.dy - 44,
              width: 88,
              height: 88,
              child: const IgnorePointer(child: _RippleDot()),
            ),
        ],
      ),
    );
  }
}

class _RippleDot extends StatelessWidget {
  const _RippleDot();

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOutCubic,
      builder: (context, t, _) {
        return Opacity(
          opacity: (1 - t) * 0.9,
          child: Transform.scale(
            scale: 0.25 + t * 0.75,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: BrandColors.orange.withValues(alpha: 0.22),
                border: Border.all(
                  color: BrandColors.orange.withValues(alpha: 0.45),
                  width: 1.5,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}