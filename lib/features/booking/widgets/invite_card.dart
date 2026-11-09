// AG_INVITE2 — «Пригласить друзей»: одна кнопка → нижняя панель с карточкой-приглашением и мессенджерами.
// Логотипы мессенджеров берутся из assets/icons/share/{whatsapp,telegram,max}.svg (официальные файлы брендов).
// Если файла нет — показывается нейтральный значок.
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/i18n.dart';
import '../../../core/theme.dart';

/// Большая кнопка на экране «Пригласить друзей».
class InviteFriendsButton extends StatelessWidget {
  const InviteFriendsButton({super.key, required this.code, required this.url, this.giftText});

  final String code;
  final String url;
  final String? giftText;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => showInviteSheet(context, code: code, url: url, giftText: giftText),
        child: Ink(
          height: 62,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(colors: [Color(0xFFFF8A2A), Color(0xFFF26200)]),
            boxShadow: [BoxShadow(color: BrandColors.orange.withValues(alpha: .35), blurRadius: 22, offset: const Offset(0, 10))],
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.person_add_alt_1_rounded, color: Colors.white, size: 24),
            const SizedBox(width: 10),
            Text(tr('Пригласить друзей'),
                style: const TextStyle(color: Colors.white, fontSize: 17.5, fontWeight: FontWeight.w900, letterSpacing: -.2)),
          ]),
        ),
      ),
    );
  }
}

Future<void> showInviteSheet(BuildContext context, {required String code, required String url, String? giftText}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    useRootNavigator: true, // поверх нижнего меню приложения
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: .55),
    builder: (_) => _InviteSheet(code: code, url: url, giftText: giftText),
  );
}

class _InviteSheet extends StatefulWidget {
  const _InviteSheet({required this.code, required this.url, this.giftText});

  final String code;
  final String url;
  final String? giftText;

  @override
  State<_InviteSheet> createState() => _InviteSheetState();
}

class _InviteSheetState extends State<_InviteSheet> {
  final _cardKey = GlobalKey();
  bool _busy = false;

  String get _gift => widget.giftText ?? tr('приветственные бонусы');

  String get _message => trf(
        'Привет! Обслуживаю машину в AG Service — рекомендую 🚗🔧\n'
        'Регистрируйся по моей ссылке и получи {0}:\n{1}\n'
        'Код приглашения: {2}',
        [_gift, widget.url, widget.code.toUpperCase()],
      );

  Future<Uint8List?> _png() async {
    try {
      final b = _cardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (b == null) return null;
      final img = await b.toImage(pixelRatio: 3);
      final data = await img.toByteData(format: ui.ImageByteFormat.png);
      return data?.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }

  /// системное меню «Поделиться» (картинка + текст) — для MAX и «Ещё»
  Future<void> _shareSystem() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final png = await _png();
      final box = context.findRenderObject() as RenderBox?;
      final origin = box == null ? null : box.localToGlobal(Offset.zero) & box.size;
      await SharePlus.instance.share(ShareParams(
        text: _message,
        files: png == null ? null : [XFile.fromData(png, mimeType: 'image/png', name: 'AG-Service-priglashenie.png')],
        sharePositionOrigin: origin,
      ));
    } catch (_) {
      await _copy();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _open(String link) async {
    bool ok = false;
    try {
      ok = await launchUrl(Uri.parse(link), mode: LaunchMode.externalApplication);
    } catch (_) {}
    if (!ok) await _shareSystem();
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: _message));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(tr('Приглашение скопировано — вставьте его в чат')),
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Container(
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF14161A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      padding: EdgeInsets.fromLTRB(18, 10, 18, 18 + bottom),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Center(
            child: Container(
              width: 42,
              height: 5,
              decoration: BoxDecoration(color: colors.onSurfaceVariant.withValues(alpha: .25), borderRadius: BorderRadius.circular(9)),
            ),
          ),
          const SizedBox(height: 6),
          Row(children: [
            const SizedBox(width: 44),
            Expanded(
              child: Text(tr('Пригласите друга'),
                  textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -.4)),
            ),
            Material(
              color: colors.onSurfaceVariant.withValues(alpha: .12),
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => Navigator.of(context).pop(),
                child: const SizedBox(width: 40, height: 40, child: Icon(Icons.close_rounded, size: 22)),
              ),
            ),
          ]),
          const SizedBox(height: 4),
          Text(trf('Друг получит {0}, а вы — бонусы за его визит', [_gift]),
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13.5, height: 1.35, fontWeight: FontWeight.w500)),
          const SizedBox(height: 18),
          RepaintBoundary(key: _cardKey, child: InviteCard(code: widget.code, url: widget.url, giftText: widget.giftText)),
          const SizedBox(height: 22),
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, crossAxisAlignment: CrossAxisAlignment.start, children: [
            _Messenger(
              label: 'WhatsApp',
              asset: 'assets/icons/share/whatsapp.svg',
              fallbackColor: const Color(0xFF25D366),
              onTap: () => _open('https://wa.me/?text=${Uri.encodeComponent(_message)}'),
            ),
            _Messenger(
              label: 'Telegram',
              asset: 'assets/icons/share/telegram.svg',
              fallbackColor: const Color(0xFF229ED9),
              onTap: () => _open('https://t.me/share/url?url=${Uri.encodeComponent(widget.url)}'
                  '&text=${Uri.encodeComponent(_message.replaceAll(widget.url, '').trim())}'),
            ),
            _Messenger(
              label: 'MAX',
              asset: 'assets/icons/share/max.svg',
              fallbackColor: const Color(0xFF6B4EFF),
              onTap: _shareSystem, // у MAX нет публичной ссылки «поделиться» — системное меню, выбрать MAX
            ),
            _Messenger(
              label: tr('Ещё'),
              icon: Icons.ios_share_rounded,
              fallbackColor: colors.onSurfaceVariant,
              busy: _busy,
              onTap: _shareSystem,
            ),
          ]),
          const SizedBox(height: 18),
          Material(
            color: dark ? const Color(0xFF1E2126) : const Color(0xFFF6F2EE),
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: _copy,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                child: Row(children: [
                  const Icon(Icons.link_rounded, color: BrandColors.orange),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(widget.url.replaceFirst('https://', ''),
                        maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
                  Text(tr('Копировать'), style: const TextStyle(color: BrandColors.orange, fontWeight: FontWeight.w900)),
                ]),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class _Messenger extends StatelessWidget {
  const _Messenger({required this.label, required this.onTap, required this.fallbackColor, this.asset, this.icon, this.busy = false});

  final String label;
  final String? asset;
  final IconData? icon;
  final Color fallbackColor;
  final VoidCallback onTap;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final fallback = Container(
      decoration: BoxDecoration(color: fallbackColor.withValues(alpha: asset == null ? .12 : 1), shape: BoxShape.circle),
      child: Icon(icon ?? Icons.chat_bubble_rounded, color: asset == null ? fallbackColor : Colors.white, size: 28),
    );
    return GestureDetector(
      onTap: busy ? null : onTap,
      child: SizedBox(
        width: 72,
        child: Column(children: [
          Container(
            width: 62,
            height: 62,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: dark ? const Color(0xFF1E2126) : Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: dark ? .3 : .08), blurRadius: 14, offset: const Offset(0, 6))],
            ),
            child: busy
                ? const Padding(padding: EdgeInsets.all(18), child: CircularProgressIndicator(strokeWidth: 2.4, color: BrandColors.orange))
                : asset == null
                    ? fallback
                    : ClipOval(child: _AssetSvg(asset: asset!, fallback: fallback)),
          ),
          const SizedBox(height: 7),
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
        ]),
      ),
    );
  }
}

/// SVG из assets, если файл есть; иначе — запасной значок (без ошибок сборки, если логотип ещё не положили).
class _AssetSvg extends StatelessWidget {
  const _AssetSvg({required this.asset, required this.fallback});

  final String asset;
  final Widget fallback;

  static final Map<String, Future<String?>> _cache = {};

  @override
  Widget build(BuildContext context) {
    final f = _cache.putIfAbsent(asset, () => rootBundle.loadString(asset).then<String?>((s) => s).catchError((_) => null));
    return FutureBuilder<String?>(
      future: f,
      builder: (_, s) => s.data == null ? fallback : SvgPicture.string(s.data!, fit: BoxFit.cover),
    );
  }
}

/// Карточка-приглашение — «билет»: слева текст и код, справа отрывной корешок с QR.
class InviteCard extends StatelessWidget {
  const InviteCard({super.key, required this.code, required this.url, this.giftText});

  final String code;
  final String url;
  final String? giftText;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.62,
      child: LayoutBuilder(builder: (context, c) {
        final stub = c.maxWidth * .36;
        final h = c.maxWidth / 1.62;
        final qr = (stub - 28) < (h - 58) ? (stub - 28) : (h - 58);
        return ClipPath(
          clipper: _TicketClipper(notchX: c.maxWidth - stub),
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1F1A17), Color(0xFF2B211B), Color(0xFF3A2416)],
              ),
            ),
            child: Stack(children: [
              // мягкое оранжевое свечение
              Positioned(
                left: -60,
                bottom: -90,
                child: Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [
                    const Color(0xFFF26200).withValues(alpha: .55),
                    const Color(0xFFF26200).withValues(alpha: 0),
                  ])),
                ),
              ),
              Row(children: [
                // основная часть
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 16, 12, 16),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(9),
                          child: Image.asset('assets/logo.png', width: 30, height: 30, fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const SizedBox(width: 30, height: 30)),
                        ),
                        const SizedBox(width: 8),
                        const Text('AG SERVICE',
                            style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1.6)),
                      ]),
                      const Spacer(),
                      Text(tr('ПРИГЛАШЕНИЕ'),
                          style: const TextStyle(color: Color(0xFFFFA45C), fontSize: 10.5, fontWeight: FontWeight.w900, letterSpacing: 1.6)),
                      const SizedBox(height: 4),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(giftText ?? tr('Бонусы на первый ремонт'),
                            style: const TextStyle(color: Colors.white, fontSize: 19, height: 1.1, fontWeight: FontWeight.w900, letterSpacing: -.4)),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFF26200), width: 1.4),
                          color: const Color(0xFFF26200).withValues(alpha: .12),
                        ),
                        child: Text(code.toUpperCase(),
                            style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900, letterSpacing: 3)),
                      ),
                    ]),
                  ),
                ),
                // отрывной корешок с QR — размер QR считается от размеров карточки, всегда квадрат
                SizedBox(
                  width: stub,
                  child: CustomPaint(
                    painter: _DashPainter(),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Container(
                        width: qr,
                        height: qr,
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                        child: QrImageView(
                          data: url,
                          size: qr - 12,
                          padding: EdgeInsets.zero,
                          gapless: true,
                          eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Color(0xFF1F1A17)),
                          dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Color(0xFF1F1A17)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(tr('Наведите камеру'),
                          maxLines: 1,
                          style: TextStyle(color: Colors.white.withValues(alpha: .7), fontSize: 10.5, fontWeight: FontWeight.w700)),
                    ]),
                  ),
                ),
              ]),
            ]),
          ),
        );
      }),
    );
  }
}

/// форма билета: скруглённые углы + полукруглые вырезы на линии отрыва
class _TicketClipper extends CustomClipper<Path> {
  _TicketClipper({required this.notchX});

  final double notchX;

  @override
  Path getClip(Size s) {
    const r = 24.0, n = 11.0;
    final card = Path()..addRRect(RRect.fromRectAndRadius(Offset.zero & s, const Radius.circular(r)));
    final holes = Path()
      ..addOval(Rect.fromCircle(center: Offset(notchX, 0), radius: n))
      ..addOval(Rect.fromCircle(center: Offset(notchX, s.height), radius: n));
    return Path.combine(PathOperation.difference, card, holes);
  }

  @override
  bool shouldReclip(_TicketClipper old) => old.notchX != notchX;
}

/// пунктир линии отрыва
class _DashPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.white.withValues(alpha: .28)
      ..strokeWidth = 1.4;
    for (double y = 16; y < size.height - 16; y += 9) {
      canvas.drawLine(Offset(0, y), Offset(0, y + 4.5), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
