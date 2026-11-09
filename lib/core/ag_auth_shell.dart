// AG_AUTH4..6 — общий вид входа и регистрации: живой фон, фирменная карта AG BONUS, стеклянная форма,
// переключатель «Вход / Регистрация». Светлая и тёмная тема, телефон / планшет / компьютер.
import 'glass.dart' show kGlassBlur; // AG_WEBFAST1
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'ag_icons.dart';
import 'theme.dart';
import 'theme_provider.dart';
import '../core/i18n.dart'; // AG_I18N1


/// AG_AUTH6: SVG-иконки экранов входа (линия 24×24, рисуются [AgIcon]).
class AgAuthIcons {
  const AgAuthIcons._();
  static const back = '<path d="M15 18l-6-6 6-6"/>';
  static const home = '<path d="M3 11l9-7 9 7"/><path d="M5 10v10h5v-6h4v6h5V10"/>';
  static const sun = '<circle cx="12" cy="12" r="4"/><path d="M12 2v2M12 20v2M4.9 4.9l1.4 1.4M17.7 17.7l1.4 1.4M2 12h2M20 12h2M4.9 19.1l1.4-1.4M17.7 6.3l1.4-1.4"/>';
  static const moon = '<path d="M20 14.5A8 8 0 1 1 9.5 4a6.5 6.5 0 0 0 10.5 10.5z"/>';
  static const calendar = '<rect x="3" y="5" width="18" height="16" rx="3"/><path d="M3 10h18M8 3v4M16 3v4"/><path d="M9 15l2 2 4-4"/>';
  static const camera = '<path d="M4 8h3l2-3h6l2 3h3a1 1 0 0 1 1 1v10a1 1 0 0 1-1 1H4a1 1 0 0 1-1-1V9a1 1 0 0 1 1-1z"/><circle cx="12" cy="13.5" r="3.6"/>';
  static const wallet = '<path d="M4 7a2 2 0 0 1 2-2h11a1 1 0 0 1 1 1v2"/><rect x="3" y="7" width="18" height="13" rx="3"/><path d="M16 13.5h2"/>';
  static const tap = '<path d="M9 11V5.5a1.5 1.5 0 0 1 3 0V11"/><path d="M12 10.5a1.5 1.5 0 0 1 3 0v1a1.5 1.5 0 0 1 3 0V16a5 5 0 0 1-5 5h-1.2a5 5 0 0 1-4.1-2.1L4.5 15a1.5 1.5 0 0 1 2.3-1.9L9 15"/>';
  static const userPlus = '<circle cx="9" cy="8" r="4"/><path d="M2 21a7 7 0 0 1 14 0"/><path d="M19 8v6M16 11h6"/>';
  static const link = '<path d="M10 14a4 4 0 0 0 5.7 0l3-3a4 4 0 0 0-5.7-5.7l-1 1"/><path d="M14 10a4 4 0 0 0-5.7 0l-3 3a4 4 0 0 0 5.7 5.7l1-1"/>';
  static const cash = '<rect x="2" y="6" width="20" height="12" rx="2"/><circle cx="12" cy="12" r="2.5"/><path d="M6 9v.01M18 15v.01"/>';
  static const trend = '<path d="M3 17l6-6 4 4 8-8"/><path d="M15 7h6v6"/>';
  static const login = '<path d="M10 17l5-5-5-5"/><path d="M15 12H3"/><path d="M14 4h4a2 2 0 0 1 2 2v12a2 2 0 0 1-2 2h-4"/>';
  static const key = '<circle cx="8" cy="15" r="4"/><path d="M10.8 12.2L20 3M17 6l3 3M14 9l2 2"/>';
}

class AgAuthPal {
  const AgAuthPal(this.dark);
  final bool dark;
  Color get bg => dark ? const Color(0xFF090B10) : const Color(0xFFFFF8F2);
  Color get glass => dark ? const Color(0xFF151920).withValues(alpha: .82) : Colors.white.withValues(alpha: .86);
  Color get field => dark ? const Color(0xFF1C2129) : const Color(0xFFF6F3F0);
  Color get line => dark ? const Color(0xFF2B323C) : const Color(0xFFEDE4DC);
  Color get ink => dark ? const Color(0xFFF7F7F8) : const Color(0xFF16181D);
  Color get mut => dark ? const Color(0xFFA0A7B1) : const Color(0xFF6E7480);
}

class AgAuthShell extends StatefulWidget {
  const AgAuthShell({super.key, required this.register, required this.child, this.title, this.subtitle, this.showSwitch = true});
  final bool register;
  final bool showSwitch;
  final Widget child;
  final String? title;
  final String? subtitle;

  @override
  State<AgAuthShell> createState() => _AgAuthShellState();
}

class _AgAuthShellState extends State<AgAuthShell> with SingleTickerProviderStateMixin {
  late final AnimationController _a = AnimationController(vsync: this, duration: const Duration(seconds: 14))..repeat();

  @override
  void dispose() {
    _a.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final p = AgAuthPal(dark);
    return Scaffold(
      backgroundColor: p.bg,
      body: Stack(
        children: [
          Positioned.fill(
            child: RepaintBoundary(
              child: AnimatedBuilder(animation: _a, builder: (_, __) => CustomPaint(painter: _BgPainter(_a.value, dark))),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(builder: (context, box) {
              final wide = box.maxWidth >= 920;
              final form = _FormCard(p: p, register: widget.register, showSwitch: widget.showSwitch, title: widget.title, subtitle: widget.subtitle, child: widget.child);
              return Column(
                children: [
                  _TopBar(p: p, dark: dark),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(wide ? 40 : 16, 4, wide ? 40 : 16, 24),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: box.maxHeight - 90),
                        child: Center(
                          child: wide
                              ? ConstrainedBox(
                                  constraints: const BoxConstraints(maxWidth: 1080),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Expanded(child: _Promo(p: p, wide: true)),
                                      const SizedBox(width: 48),
                                      SizedBox(width: 460, child: form),
                                    ],
                                  ),
                                )
                              : ConstrainedBox(
                                  constraints: const BoxConstraints(maxWidth: 480),
                                  child: Column(children: [_Promo(p: p, wide: false), const SizedBox(height: 18), form]),
                                ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.p, required this.dark});
  final AgAuthPal p;
  final bool dark;

  Widget _btn(String i, VoidCallback onTap, String tip) => Tooltip(
        message: tip,
        child: Material(
          color: p.glass,
          shape: CircleBorder(side: BorderSide(color: p.line)),
          child: InkWell(customBorder: const CircleBorder(), onTap: onTap, child: SizedBox(width: 44, height: 44, child: Center(child: AgIcon(i, size: 20, color: p.ink, strokeWidth: 2)))),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Row(children: [
        if (context.canPop()) ...[_btn(AgAuthIcons.back, () => context.pop(), tr('Назад')), const SizedBox(width: 8)],
        // AG_AUTH5: кнопка «Главная» — можно смотреть приложение без входа
        Material(
          color: p.glass,
          shape: StadiumBorder(side: BorderSide(color: p.line)),
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: () => context.go('/'),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                height: 44,
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const AgIcon(AgAuthIcons.home, size: 20, color: BrandColors.orange, strokeWidth: 2),
                  const SizedBox(width: 7),
                  Text(tr('Главная'), style: TextStyle(color: p.ink, fontSize: 14.5, fontWeight: FontWeight.w800)),
                ]),
              ),
            ),
          ),
        ),
        const Spacer(),
        // AG_I18N1: выбор языка
        Material(
          color: p.glass,
          shape: StadiumBorder(side: BorderSide(color: p.line)),
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: () => AgI18n.pick(context),
            child: SizedBox(
              height: 44,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(AgI18n.current.flag, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 6),
                  Text(AgI18n.code.toUpperCase(), style: TextStyle(color: p.ink, fontSize: 13.5, fontWeight: FontWeight.w900)),
                ]),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        _btn(dark ? AgAuthIcons.sun : AgAuthIcons.moon,
            () => context.read<ThemeProvider>().setThemeMode(dark ? ThemeMode.light : ThemeMode.dark), tr('Светлая или тёмная тема')),
      ]),
    );
  }
}

/// Бренд + фирменная карта AG BONUS + преимущества.
class _Promo extends StatelessWidget {
  const _Promo({required this.p, required this.wide});
  final AgAuthPal p;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final brand = Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: wide ? 54 : 44,
        height: wide ? 54 : 44,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(wide ? 17 : 14),
            boxShadow: [BoxShadow(color: BrandColors.orange.withValues(alpha: .25), blurRadius: 18, offset: const Offset(0, 6))]),
        child: Image.asset('assets/logo.png', fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Center(child: Text('AG', style: TextStyle(color: BrandColors.orange, fontWeight: FontWeight.w900)))),
      ),
      const SizedBox(width: 12),
      Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Text('AG SERVICE', style: TextStyle(color: p.ink, fontSize: wide ? 22 : 18, fontWeight: FontWeight.w900, letterSpacing: 2.2)),
        Text(tr('автосервис в телефоне'), style: TextStyle(color: p.mut, fontSize: 13, fontWeight: FontWeight.w600)),
      ]),
    ]);
    if (!wide) {
      return Column(children: [
        brand,
        const SizedBox(height: 16),
        const SizedBox(height: 178, child: AgBonusMiniCard(compact: true)),
      ]);
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      brand,
      const SizedBox(height: 26),
      Text(tr('Запись в сервис,\nремонт и бонусы —\nв одном приложении'),
          style: TextStyle(color: p.ink, fontSize: 38, height: 1.12, fontWeight: FontWeight.w900, letterSpacing: -1)),
      const SizedBox(height: 26),
      const SizedBox(width: 380, height: 236, child: AgBonusMiniCard(compact: false)),
      const SizedBox(height: 26),
      for (final f in [
        (AgAuthIcons.calendar, tr('Запись к мастеру за минуту')),
        (AgAuthIcons.camera, tr('Фото и видео приёмки вашего авто')),
        (AgAuthIcons.wallet, tr('Бонусный счёт в рублях')),
      ])
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(color: BrandColors.orange.withValues(alpha: .12), borderRadius: BorderRadius.circular(12)),
              child: Center(child: AgIcon(f.$1, size: 20, color: BrandColors.orange, strokeWidth: 2)),
            ),
            const SizedBox(width: 12),
            Text(f.$2, style: TextStyle(color: p.ink, fontSize: 15.5, fontWeight: FontWeight.w700)),
          ]),
        ),
    ]);
  }
}

/// Фирменная карта AG BONUS (чип, бесконтактный значок, волны). AG_AUTH5: нажатие — карта переворачивается, на обороте правила.
class AgBonusMiniCard extends StatefulWidget {
  const AgBonusMiniCard({super.key, required this.compact});
  final bool compact;
  @override
  State<AgBonusMiniCard> createState() => _AgBonusMiniCardState();
}

class _AgBonusMiniCardState extends State<AgBonusMiniCard> with SingleTickerProviderStateMixin {
  late final AnimationController _f = AnimationController(vsync: this, duration: const Duration(milliseconds: 650));
  late final Animation<double> _t = CurvedAnimation(parent: _f, curve: Curves.easeInOutCubic);

  @override
  void dispose() {
    _f.dispose();
    super.dispose();
  }

  void _flip() => _f.status == AnimationStatus.completed || _f.status == AnimationStatus.forward ? _f.reverse() : _f.forward();

  BoxDecoration _deco(bool back) => BoxDecoration(
        borderRadius: BorderRadius.circular(widget.compact ? 18 : 22),
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: back ? const [Color(0xFFE85D00), Color(0xFFB43C00), Color(0xFF6E2400)] : const [Color(0xFFFFA24C), Color(0xFFF26200), Color(0xFFB83E00)],
            stops: const [0, .5, 1]),
        boxShadow: [BoxShadow(color: const Color(0xFFC24400).withValues(alpha: .45), blurRadius: 34, offset: const Offset(0, 16))],
      );

  Widget _front() {
    final c = widget.compact;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: _deco(false),
      child: CustomPaint(
        painter: _CardPainter(),
        child: Padding(
          padding: EdgeInsets.all(c ? 14 : 20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text('AG BONUS', style: TextStyle(color: Colors.white, fontSize: c ? 13 : 15, fontWeight: FontWeight.w900, letterSpacing: 2.4)),
              const Spacer(),
              CustomPaint(size: Size.square(c ? 18 : 22), painter: _NfcPainter()),
            ]),
            const Spacer(),
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              CustomPaint(size: Size(c ? 36 : 44, c ? 27 : 33), painter: _ChipPainter()),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: .2), borderRadius: BorderRadius.circular(20)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const AgIcon(AgAuthIcons.tap, size: 14, color: Colors.white, strokeWidth: 2),
                  const SizedBox(width: 4),
                  Text(tr('правила'), style: TextStyle(color: Colors.white, fontSize: c ? 10.5 : 12, fontWeight: FontWeight.w800)),
                ]),
              ),
            ]),
            SizedBox(height: c ? 10 : 14),
            Text('AG  ••••  ••••  2026',
                style: TextStyle(color: Colors.white.withValues(alpha: .95), fontSize: c ? 13 : 16, letterSpacing: 2.5, fontWeight: FontWeight.w700,
                    fontFeatures: const [ui.FontFeature.tabularFigures()])),
            SizedBox(height: c ? 4 : 8),
            Text(tr('КОПИТЕ БОНУСЫ С КАЖДОГО РЕМОНТА'),
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.white.withValues(alpha: .8), fontSize: c ? 8.5 : 10, fontWeight: FontWeight.w800, letterSpacing: 1.4)),
          ]),
        ),
      ),
    );
  }

  Widget _back() {
    final c = widget.compact;
    Widget row(String i, String t) => Padding(
          padding: EdgeInsets.only(bottom: c ? 5 : 8),
          child: Row(children: [
            Container(
              width: c ? 22 : 28, height: c ? 22 : 28,
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: .18), borderRadius: BorderRadius.circular(8)),
              child: Center(child: AgIcon(i, size: c ? 13 : 16, color: Colors.white, strokeWidth: 2)),
            ),
            SizedBox(width: c ? 8 : 10),
            Expanded(child: Text(t, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.white, fontSize: c ? 11.5 : 13.5, fontWeight: FontWeight.w700))),
          ]),
        );
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: _deco(true),
      child: Stack(children: [
        Positioned(left: 0, right: 0, top: c ? 20 : 26, child: Container(height: c ? 22 : 30, color: Colors.black.withValues(alpha: .55))),
        Padding(
          padding: EdgeInsets.fromLTRB(c ? 14 : 20, c ? 50 : 66, c ? 14 : 20, c ? 10 : 14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(tr('Правила AG BONUS'), style: TextStyle(color: Colors.white, fontSize: c ? 13 : 16, fontWeight: FontWeight.w900)),
            SizedBox(height: c ? 7 : 10),
            row(AgAuthIcons.userPlus, tr('300 ₽ за каждого приглашённого друга')),
            row(AgAuthIcons.link, tr('Друг регистрируется по вашему коду')),
            row(AgAuthIcons.cash, tr('Бонусами можно оплатить до 20%')),
            row(AgAuthIcons.trend, tr('1 бонус = 1 ₽, больше друзей — выше статус')),
          ]),
        ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _flip,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Transform.rotate(
          angle: widget.compact ? -.035 : -.05,
          child: AspectRatio(
            aspectRatio: 1.586,
            child: AnimatedBuilder(
              animation: _t,
              builder: (_, __) {
                final a = _t.value * math.pi;
                final showBack = a > math.pi / 2;
                return Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, .0012)
                    ..rotateY(a)
                    ..multiply(Matrix4.diagonal3Values(1 + .06 * math.sin(a), 1 + .06 * math.sin(a), 1)),
                  child: showBack
                      ? Transform(alignment: Alignment.center, transform: Matrix4.identity()..rotateY(math.pi), child: _back())
                      : _front(),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _CardPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;
    for (var i = 0; i < 9; i++) {
      p.color = Colors.white.withValues(alpha: .28 - i * .025);
      final y = s.height * .55 + i * s.height * .055;
      final path = Path()..moveTo(-10, y);
      path.cubicTo(s.width * .25, y - s.height * .25, s.width * .55, y + s.height * .2, s.width + 10, y - s.height * .15);
      c.drawPath(path, p);
    }
    c.drawCircle(Offset(s.width * .95, s.height * .05), s.width * .35, Paint()..color = Colors.white.withValues(alpha: .08));
  }

  @override
  bool shouldRepaint(_CardPainter o) => false;
}

class _ChipPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final r = RRect.fromRectAndRadius(Offset.zero & s, Radius.circular(s.height * .2));
    c.drawRRect(r, Paint()..shader = const LinearGradient(colors: [Color(0xFFFCE7A8), Color(0xFFE2B657), Color(0xFFA97A1E)]).createShader(Offset.zero & s));
    final l = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = const Color(0xFF7A5512).withValues(alpha: .55);
    final w = s.width, h = s.height;
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * .34, h * .33, w * .32, h * .34), Radius.circular(h * .09)), l);
    for (final x in [w * .34, w * .66]) {
      c.drawLine(Offset(x, 0), Offset(x, h * .33), l);
      c.drawLine(Offset(x, h * .67), Offset(x, h), l);
    }
    c.drawLine(Offset(0, h * .33), Offset(w * .34, h * .33), l);
    c.drawLine(Offset(w * .66, h * .33), Offset(w, h * .33), l);
    c.drawLine(Offset(0, h * .67), Offset(w * .34, h * .67), l);
    c.drawLine(Offset(w * .66, h * .67), Offset(w, h * .67), l);
    c.drawLine(Offset(w * .5, h * .33), Offset(w * .5, h * .67), l);
  }

  @override
  bool shouldRepaint(_ChipPainter o) => false;
}

class _NfcPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = s.width * .09
      ..strokeCap = StrokeCap.round
      ..color = Colors.white;
    for (var i = 0; i < 4; i++) {
      final rad = s.width * (.2 + i * .19);
      p.color = Colors.white.withValues(alpha: i == 3 ? .55 : 1);
      c.drawArc(Rect.fromCircle(center: Offset(0, s.height / 2), radius: rad), -.75, 1.5, false, p);
    }
  }

  @override
  bool shouldRepaint(_NfcPainter o) => false;
}

class _BgPainter extends CustomPainter {
  _BgPainter(this.t, this.dark);
  final double t;
  final bool dark;
  @override
  void paint(Canvas c, Size s) {
    final a = t * math.pi * 2;
    void blob(double cx, double cy, double r, Color col) {
      c.drawCircle(Offset(cx, cy), r, Paint()..shader = RadialGradient(colors: [col, col.withValues(alpha: 0)]).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r)));
    }
    final m = math.max(s.width, s.height);
    blob(s.width * (.15 + .08 * math.sin(a)), s.height * (.12 + .05 * math.cos(a)), m * .55, const Color(0xFFFF7A1A).withValues(alpha: dark ? .30 : .22));
    blob(s.width * (.9 + .06 * math.cos(a * 1.3)), s.height * (.85 + .05 * math.sin(a)), m * .5, const Color(0xFFFFB25C).withValues(alpha: dark ? .18 : .20));
    blob(s.width * (.85 + .05 * math.sin(a * .7)), s.height * .1, m * .3, const Color(0xFFF26200).withValues(alpha: dark ? .16 : .10));
    final g = Paint()
      ..color = (dark ? Colors.white : const Color(0xFF8A4A1A)).withValues(alpha: dark ? .035 : .045)
      ..strokeWidth = 1;
    for (double x = 0; x < s.width; x += 36) {
      c.drawLine(Offset(x, 0), Offset(x, s.height), g);
    }
    for (double y = 0; y < s.height; y += 36) {
      c.drawLine(Offset(0, y), Offset(s.width, y), g);
    }
  }

  @override
  bool shouldRepaint(_BgPainter o) => o.t != t || o.dark != dark;
}

class _FormCard extends StatelessWidget {
  const _FormCard({required this.p, required this.register, required this.child, this.title, this.subtitle, this.showSwitch = true});
  final AgAuthPal p;
  final bool register;
  final bool showSwitch;
  final Widget child;
  final String? title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        enabled: kGlassBlur, // AG_WEBFAST1
        filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
          decoration: BoxDecoration(
            color: p.glass,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: p.line),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: p.dark ? .35 : .07), blurRadius: 40, offset: const Offset(0, 18))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showSwitch) ...[_Switch(p: p, register: register), const SizedBox(height: 20)],
              if (title != null)
                Text(title!, style: TextStyle(color: p.ink, fontSize: 25, height: 1.15, fontWeight: FontWeight.w900, letterSpacing: -.6)),
              if (subtitle != null) ...[
                const SizedBox(height: 6),
                Text(subtitle!, style: TextStyle(color: p.mut, fontSize: 14.5, height: 1.4)),
              ],
              if (title != null || subtitle != null) const SizedBox(height: 18),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

/// Переключатель «Вход / Регистрация».
class _Switch extends StatelessWidget {
  const _Switch({required this.p, required this.register});
  final AgAuthPal p;
  final bool register;

  @override
  Widget build(BuildContext context) {
    Widget tab(String t, String i, bool on, VoidCallback go) => Expanded(
          child: GestureDetector(
            onTap: on ? null : go,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                gradient: on ? const LinearGradient(colors: [Color(0xFFFF8A2B), Color(0xFFF26200)]) : null,
                boxShadow: on ? [BoxShadow(color: BrandColors.orange.withValues(alpha: .35), blurRadius: 14, offset: const Offset(0, 6))] : null,
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(children: [
                  AgIcon(i, size: 18, color: on ? Colors.white : p.mut, strokeWidth: 2),
                  const SizedBox(width: 7),
                  Text(t, style: TextStyle(color: on ? Colors.white : p.mut, fontSize: 15, fontWeight: FontWeight.w800)),
                ]),
              ),
            ),
          ),
        );
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(color: p.field, borderRadius: BorderRadius.circular(19), border: Border.all(color: p.line)),
      child: Row(children: [
        tab(tr('Вход'), AgAuthIcons.login, !register, () => context.go('/login')),
        const SizedBox(width: 5),
        tab(tr('Регистрация'), AgAuthIcons.userPlus, register, () => context.go('/register')),
      ]),
    );
  }
}
