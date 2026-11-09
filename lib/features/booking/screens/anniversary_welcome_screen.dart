import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/i18n.dart'; // AG_I18N1

class AnniversaryWelcomeScreen extends StatefulWidget {
  const AnniversaryWelcomeScreen({super.key});

  @override
  State<AnniversaryWelcomeScreen> createState() =>
      _AnniversaryWelcomeScreenState();
}

class _AnniversaryWelcomeScreenState extends State<AnniversaryWelcomeScreen>
    with SingleTickerProviderStateMixin {
  static const _orange = Color(0xFFFF6A00);
  late final AnimationController _controller;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();

    _timer = Timer(const Duration(seconds: 3), () {
      if (mounted) context.go('/');
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            const Positioned(
              top: -85,
              right: -75,
              child: _SoftCircle(size: 230),
            ),
            const Positioned(
              bottom: -125,
              left: -90,
              child: _SoftCircle(size: 270),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
              child: Column(
                children: [
                  FadeTransition(
                    opacity: CurvedAnimation(
                      parent: _controller,
                      curve: const Interval(0, .55, curve: Curves.easeOut),
                    ),
                    child: Image.asset(
                      'assets/logo.png',
                      width: 185,
                      height: 105,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ScaleTransition(
                    scale: Tween<double>(begin: .78, end: 1).animate(
                      CurvedAnimation(
                        parent: _controller,
                        curve: const Interval(
                          .12,
                          .85,
                          curve: Curves.elasticOut,
                        ),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          tr('НАМ'),
                          style: TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                        ),
                        Text(
                          '5',
                          style: TextStyle(
                            fontSize: 124,
                            height: .92,
                            fontWeight: FontWeight.w900,
                            color: _orange,
                          ),
                        ),
                        Text(
                          tr('ЛЕТ ВМЕСТЕ!'),
                          style: TextStyle(
                            fontSize: 33,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 13,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: _orange,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x33FF6A00),
                          blurRadius: 20,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Text(
                      tr('СПАСИБО, ЧТО ВЫБИРАЕТЕ НАС!'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      _Benefit(
                        icon: Icons.verified_outlined,
                        title: tr('КАЧЕСТВО'),
                        subtitle: tr('Проверенные\nспециалисты'),
                      ),
                      _Benefit(
                        icon: Icons.schedule,
                        title: tr('БЫСТРО'),
                        subtitle: tr('Запись без\nлишних ожиданий'),
                      ),
                      _Benefit(
                        icon: Icons.shield_outlined,
                        title: tr('НАДЁЖНО'),
                        subtitle: tr('Гарантия на\nработы и запчасти'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      minHeight: 5,
                      value: .72,
                      backgroundColor:
                          Theme.of(context).brightness == Brightness.dark
                              ? Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest
                              : const Color(0xFFEFEFEF),
                      valueColor: AlwaysStoppedAnimation<Color>(_orange),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    tr('AG Service • 5 лет с вами'),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SoftCircle extends StatelessWidget {
  const _SoftCircle({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color:
            Theme.of(context).brightness == Brightness.dark
                ? _AnniversaryWelcomeScreenState._orange.withValues(alpha: 0.12)
                : const Color(0xFFFFF2E8),
        shape: BoxShape.circle,
      ),
    );
  }
}

class _Benefit extends StatelessWidget {
  const _Benefit({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color:
                  Theme.of(context).brightness == Brightness.dark
                      ? _AnniversaryWelcomeScreenState._orange.withValues(
                        alpha: 0.12,
                      )
                      : const Color(0xFFFFF3EA),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: _AnniversaryWelcomeScreenState._orange,
              size: 25,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10.5,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}
