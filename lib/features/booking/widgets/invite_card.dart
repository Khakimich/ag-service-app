// AG_INVITE1 — красивая карточка «Пригласи друга»: картинка для WhatsApp / Telegram + быстрые кнопки отправки.
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/i18n.dart';
import '../../../core/theme.dart';

class InviteShareSection extends StatefulWidget {
  const InviteShareSection({super.key, required this.code, required this.url, this.giftText});

  final String code;
  final String url;

  /// что получит друг, например «100 бонусов на первый ремонт»
  final String? giftText;

  @override
  State<InviteShareSection> createState() => _InviteShareSectionState();
}

class _InviteShareSectionState extends State<InviteShareSection> {
  final _cardKey = GlobalKey();
  bool _busy = false;

  String get _message => trf(
        'Привет! Обслуживаю машину в AG Service — рекомендую 🚗🔧\n'
        'Регистрируйся по моей ссылке и получи {0}:\n{1}\n'
        'Код приглашения: {2}',
        [widget.giftText ?? tr('приветственные бонусы'), widget.url, widget.code],
      );

  Future<Uint8List?> _renderPng() async {
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

  Future<void> _shareImage() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final png = await _renderPng();
      final box = context.findRenderObject() as RenderBox?;
      final origin = box == null ? null : box.localToGlobal(Offset.zero) & box.size;
      if (png != null) {
        await SharePlus.instance.share(ShareParams(
          text: _message,
          files: [XFile.fromData(png, mimeType: 'image/png', name: 'AG-Service-priglashenie.png')],
          sharePositionOrigin: origin,
        ));
      } else {
        await SharePlus.instance.share(ShareParams(text: _message, sharePositionOrigin: origin));
      }
    } catch (_) {
      await _copy();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _open(Uri uri) async {
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) await _copy();
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
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      RepaintBoundary(key: _cardKey, child: InviteCard(code: widget.code, url: widget.url, giftText: widget.giftText)),
      const SizedBox(height: 14),
      Row(children: [
        Expanded(
          child: _ShareBtn(
            color: const Color(0xFF25D366),
            label: 'WhatsApp',
            icon: Icons.chat_rounded,
            onTap: () => _open(Uri.parse('https://wa.me/?text=${Uri.encodeComponent(_message)}')),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ShareBtn(
            color: const Color(0xFF229ED9),
            label: 'Telegram',
            icon: Icons.send_rounded,
            onTap: () => _open(Uri.parse(
                'https://t.me/share/url?url=${Uri.encodeComponent(widget.url)}&text=${Uri.encodeComponent(_message.replaceAll(widget.url, '').trim())}')),
          ),
        ),
      ]),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(
          flex: 3,
          child: _ShareBtn(
            color: BrandColors.orange,
            label: _busy ? tr('Готовим…') : tr('Поделиться картинкой'),
            icon: Icons.image_rounded,
            onTap: _shareImage,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: _ShareBtn(
            color: BrandColors.orange.withValues(alpha: .12),
            fg: BrandColors.orange,
            label: tr('Копировать'),
            icon: Icons.copy_rounded,
            onTap: _copy,
          ),
        ),
      ]),
    ]);
  }
}

class _ShareBtn extends StatelessWidget {
  const _ShareBtn({required this.color, required this.label, required this.icon, required this.onTap, this.fg = Colors.white});

  final Color color;
  final Color fg;
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: SizedBox(
          height: 52,
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, color: fg, size: 20),
            const SizedBox(width: 8),
            Flexible(
              child: Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: fg, fontSize: 15, fontWeight: FontWeight.w800)),
            ),
          ]),
        ),
      ),
    );
  }
}

/// Сама карточка-картинка (то, что уходит в чат).
class InviteCard extends StatelessWidget {
  const InviteCard({super.key, required this.code, required this.url, this.giftText});

  final String code;
  final String url;
  final String? giftText;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.25,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFF9A3D), Color(0xFFF26200), Color(0xFFB83E00)],
          ),
        ),
        child: Stack(children: [
          Positioned(right: -50, top: -60, child: _circle(190, .13)),
          Positioned(left: -40, bottom: -70, child: _circle(170, .09)),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 20, 20, 18),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: Image.asset('assets/logo.png', width: 38, height: 38, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox(width: 38, height: 38)),
                ),
                const SizedBox(width: 10),
                const Text('AG SERVICE',
                    style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: .2), borderRadius: BorderRadius.circular(99)),
                  child: Text(tr('🎁 Подарок'), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800)),
                ),
              ]),
              const Spacer(),
              Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(tr('Приглашаю в автосервис'),
                        style: TextStyle(color: Colors.white.withValues(alpha: .9), fontSize: 13.5, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(giftText ?? tr('Бонусы на первый ремонт'),
                        maxLines: 2,
                        style: const TextStyle(color: Colors.white, fontSize: 23, height: 1.1, fontWeight: FontWeight.w900, letterSpacing: -.5)),
                    const SizedBox(height: 12),
                    Text(tr('КОД ПРИГЛАШЕНИЯ'),
                        style: TextStyle(color: Colors.white.withValues(alpha: .8), fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 1)),
                    const SizedBox(height: 3),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                      child: Text(code.toUpperCase(),
                          style: const TextStyle(color: Color(0xFFC94400), fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 2)),
                    ),
                  ]),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 104,
                  height: 104,
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                  child: QrImageView(data: url, padding: EdgeInsets.zero, gapless: true,
                      eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Color(0xFF15171C)),
                      dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Color(0xFF15171C))),
                ),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _circle(double s, double a) => Container(
      width: s, height: s, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: a)));
}
