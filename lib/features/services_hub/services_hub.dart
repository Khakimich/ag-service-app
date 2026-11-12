// AG_SVCHUB1 — раздел «Сервисы» на главной + экраны «Эвакуатор» и «Кузовной ремонт».
// Заявки уходят в чат клиента с отделом «Автосервис AUTOGROM» (тот же, что в разделе «Чаты»),
// поэтому сервер дорабатывать не нужно: менеджер видит текст, точку на Яндекс Картах и фото.
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/i18n.dart';
import '../../core/theme.dart';
import '../auth/providers/auth_provider.dart';
import '../booking/providers/company_provider.dart';
import '../chat/data/chat_repository.dart';

const _orange = BrandColors.orange;
const _dept = 'autogrom_service';

// ───────────────────────── Иконки (SVG) ─────────────────────────
// Все иконки внутри экранов — SVG (без шрифтовых Material-иконок), чтобы везде отображались одинаково.
class _Ico {
  // AG_SVCHUB4: строгие залитые силуэты (белые на оранжевой плашке)
  static const _taxi =
      '<path d="M9.5 2h5a1 1 0 0 1 1 1v1.5h-7V3a1 1 0 0 1 1-1z"/>'
      '<path d="M7.3 6h9.4a2 2 0 0 1 1.85 1.24L20 11a2 2 0 0 1 1 1.73V18a1 1 0 0 1-1 1h-1v1.5a1.5 1.5 0 0 1-3 0V19H8v1.5a1.5 1.5 0 0 1-3 0V19H4a1 1 0 0 1-1-1v-5.27A2 2 0 0 1 4 11l1.45-3.76A2 2 0 0 1 7.3 6zm.2 2-1.15 3h11.3l-1.15-3zM6.5 13.25a1.25 1.25 0 1 0 0 2.5 1.25 1.25 0 0 0 0-2.5zm11 0a1.25 1.25 0 1 0 0 2.5 1.25 1.25 0 0 0 0-2.5zM10 14v1.5h4V14z"/>';
  static const _tow =
      '<path d="M2 8a1 1 0 0 1 1-1h5.6a1 1 0 0 1 .86.49L11.6 11H13V9.4l7.3-3.65a1 1 0 0 1 .9 1.79L15 10.64V11h6a1 1 0 0 1 1 1v4a1 1 0 0 1-1 1h-.8a3 3 0 0 0-5.4 0H9.2a3 3 0 0 0-5.4 0H3a1 1 0 0 1-1-1zm2 1v3h5.3L7.9 9z"/>'
      '<circle cx="6.5" cy="17.5" r="2"/><circle cx="17.5" cy="17.5" r="2"/>';
  static const _body =
      '<path d="M15 1.5h1.3l.6-1h2.2l.6 1H21a1 1 0 0 1 1 1V6a1 1 0 0 1-1 1h-6a1 1 0 0 1-1-1V2.5a1 1 0 0 1 1-1zm3 1.4a1.35 1.35 0 1 0 0 2.7 1.35 1.35 0 0 0 0-2.7z"/>'
      '<path fill-rule="evenodd" transform="translate(0 2)" d="M2 15.5v-1.8a2 2 0 0 1 1.2-1.8L5.3 11l2.2-3.1A2 2 0 0 1 9.1 7h4.6a2 2 0 0 1 1.5.7L18 11l2 .4a2 2 0 0 1 1.7 2V16a1 1 0 0 1-1 1h-.9a2.6 2.6 0 0 0-5.1 0H9.4a2.6 2.6 0 0 0-5.1 0H3a1 1 0 0 1-1-1zM8.7 8.7 7.1 11h3.7V8.7zm3.8 0V11h3.7l-1.8-2.3z"/>'
      '<circle cx="6.85" cy="19.2" r="1.9"/><circle cx="17.25" cy="19.2" r="1.9"/>';
  static const _osago =
      '<path d="M12 1.8 20 5v6.2c0 5-3.4 9.5-8 10.9-4.6-1.4-8-5.9-8-10.9V5zm3.9 7.3-5.1 5.2-2.4-2.4-1.4 1.4 3.8 3.8 6.5-6.6z"/>';
  static String glyph(String key, [String color = '#FFFFFF']) =>
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="$color">${switch (key) { 'taxi' => _taxi, 'tow' => _tow, 'bodycam' => _body, _ => _osago }}</svg>';
  static String _l(String c, String p, [double w = 2]) =>
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="$c" stroke-width="$w" stroke-linecap="round" stroke-linejoin="round">$p</svg>';
  static String pin([String c = '#FF6A00']) => _l(c, '<path d="M12 21s-7-6.2-7-11.5a7 7 0 0 1 14 0C19 14.8 12 21 12 21z"/><circle cx="12" cy="9.5" r="2.5"/>');
  static String gps([String c = '#FF6A00']) => _l(c, '<circle cx="12" cy="12" r="7"/><circle cx="12" cy="12" r="2.6" fill="$c"/><path d="M12 2v3M12 19v3M2 12h3M19 12h3"/>');
  static String flag([String c = '#FF6A00']) => _l(c, '<path d="M5 21V4"/><path d="M5 4h11l-2 4 2 4H5"/>');
  static String phone([String c = '#FF6A00']) => _l(c, '<path d="M5 4h3.5l1.8 4.5-2.3 1.4a11 11 0 0 0 6.1 6.1l1.4-2.3L20 15.5V19a2 2 0 0 1-2 2A16 16 0 0 1 3 6a2 2 0 0 1 2-2z"/>');
  static String car([String c = '#FF6A00']) => _l(c, '<path d="M4 16v-3.5l1.8-4.6A2 2 0 0 1 7.7 6.6h8.6a2 2 0 0 1 1.9 1.3L20 12.5V16"/><path d="M3 12.5h18v4a1 1 0 0 1-1 1H4a1 1 0 0 1-1-1z"/><circle cx="7.5" cy="17.5" r="1.6"/><circle cx="16.5" cy="17.5" r="1.6"/>');
  static String calendar([String c = '#FF6A00']) => _l(c, '<rect x="3.5" y="5" width="17" height="15.5" rx="3"/><path d="M3.5 10h17M8 3v4M16 3v4"/>');
  static String palette([String c = '#FF6A00']) => _l(c, '<path d="M12 3a9 9 0 1 0 0 18c1.2 0 2-.8 2-1.8 0-.5-.2-.9-.5-1.3-.3-.4-.5-.8-.5-1.3 0-1 .8-1.8 1.8-1.8H17a4 4 0 0 0 4-4C21 6.6 17 3 12 3z"/><circle cx="7.5" cy="11" r="1" fill="$c"/><circle cx="10.5" cy="7" r="1" fill="$c"/><circle cx="15" cy="7.5" r="1" fill="$c"/>');
  static String camera([String c = '#FF6A00']) => _l(c, '<path d="M4 8h3l1.6-2.4h6.8L17 8h3a1 1 0 0 1 1 1v9a1 1 0 0 1-1 1H4a1 1 0 0 1-1-1V9a1 1 0 0 1 1-1z"/><circle cx="12" cy="13" r="3.6"/>');
  static String gallery([String c = '#FF6A00']) => _l(c, '<rect x="3" y="4" width="18" height="16" rx="3"/><circle cx="8.5" cy="9.5" r="1.8"/><path d="M21 16l-5-5-9 9"/>');
  static String plus([String c = '#FF6A00']) => _l(c, '<path d="M12 5v14M5 12h14"/>', 2.4);
  static String close([String c = '#FFFFFF']) => _l(c, '<path d="M6 6l12 12M18 6L6 18"/>', 2.6);
  static String check([String c = '#FFFFFF']) => _l(c, '<path d="M5 12.5l4.5 4.5L19 7.5"/>', 3);
  static String chat([String c = '#FFFFFF']) => _l(c, '<path d="M4 5h16a1 1 0 0 1 1 1v10a1 1 0 0 1-1 1H9l-5 4V6a1 1 0 0 1 1-1z"/>');
  static String clock([String c = '#FFFFFF']) => _l(c, '<circle cx="12" cy="12" r="8.5"/><path d="M12 7.5V12l3 2"/>');
  static String ruble([String c = '#FFFFFF']) => _l(c, '<path d="M8 20V4h5.5a4 4 0 0 1 0 8H6M6 16h8"/>');
  static String shield([String c = '#FFFFFF']) => _l(c, '<path d="M12 3l7 3v5c0 4.5-3 8.2-7 10-4-1.8-7-5.5-7-10V6z"/><path d="M9 12l2 2 4-4"/>');
  static String alert([String c = '#B91C1C']) => _l(c, '<circle cx="12" cy="12" r="9"/><path d="M12 7.5v5.5"/><circle cx="12" cy="16.5" r=".6" fill="$c"/>');
}

Widget _svg(String s, double size) => SvgPicture.string(s, width: size, height: size);

// ───────────────────────── Раздел на главной ─────────────────────────
// AG_SVCHUB3: четыре плитки в один ряд — 3D-иконка сверху, короткая подпись снизу.
class ServicesHubSection extends StatelessWidget {
  const ServicesHubSection({super.key});

  @override
  Widget build(BuildContext context) {
    final items = <_HubItem>[
      _HubItem('taxi', tr('Работа в такси'), tr('0% комиссии'), const Color(0xFFF5A300), () => context.push('/park')),
      _HubItem('tow', tr('Эвакуатор'), tr('от 4000 ₽'), const Color(0xFFFF6A00), () => context.push('/evacuator')),
      _HubItem('bodycam', tr('Кузовной ремонт'), tr('По фото'), const Color(0xFF2057DF), () => context.push('/body-repair')),
      _HubItem('shield', tr('ОСАГО для такси'), tr('Скоро'), const Color(0xFF059669), () => _soon(context), soon: true),
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(tr('Сервисы'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -.4)),
      const SizedBox(height: 12),
      IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          for (var i = 0; i < items.length; i++) ...[
            Expanded(child: _HubTile(item: items[i])),
            if (i != items.length - 1) const SizedBox(width: 8),
          ],
        ]),
      ),
    ]);
  }

  static void _soon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(tr('Сравнение ОСАГО для такси скоро появится'))),
    );
  }
}

class _HubItem {
  const _HubItem(this.icon, this.title, this.caption, this.color, this.onTap, {this.soon = false});
  final String icon, title, caption;
  final Color color;
  final VoidCallback onTap;
  final bool soon;
}

class _HubTile extends StatelessWidget {
  const _HubTile({required this.item});
  final _HubItem item;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: dark ? const Color(0xFF1B1E22) : Colors.white,
      borderRadius: BorderRadius.circular(22),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: item.onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(6, 12, 6, 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: cs.outlineVariant.withValues(alpha: .45)),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: dark ? 0 : .04), blurRadius: 14, offset: const Offset(0, 6))],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 50,
              height: 50,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: item.soon ? const Color(0xFFFFB27A) : _orange,
                boxShadow: [BoxShadow(color: _orange.withValues(alpha: .28), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: _svg(_Ico.glyph(item.icon), 28),
            ),
            const SizedBox(height: 8),
            Text(item.title,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: const TextStyle(fontSize: 12, height: 1.15, fontWeight: FontWeight.w800, letterSpacing: -.2)),
            const Spacer(),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
              decoration: BoxDecoration(
                color: item.soon ? cs.surfaceContainerHighest : _orange.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(item.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: item.soon ? cs.onSurfaceVariant : _orange)),
            ),
          ]),
        ),
      ),
    );
  }
}

// ───────────────────────── Общие части экранов ─────────────────────────
const _bgLight = Color(0xFFF6F6F8);

String _yandexPoint(double lat, double lon) =>
    'https://yandex.ru/maps/?pt=${lon.toStringAsFixed(6)},${lat.toStringAsFixed(6)}&z=17&l=map';

/// Отправка заявки в чат с автосервисом. Возвращает id переписки.
Future<String> _sendToServiceChat(
  BuildContext context, {
  required String text,
  Position? location,
  List<Uint8List> photos = const [],
}) async {
  final repo = context.read<ChatRepository>();
  final conv = await repo.getOrCreateDepartmentConversation(_dept);
  await repo.sendMessage(conv.id, body: text);
  if (location != null) {
    // тот же формат, что в чате: менеджер видит карту и кнопку маршрута
    await repo.sendMessage(conv.id, body: '📍 Местоположение\n${_yandexPoint(location.latitude, location.longitude)}');
  }
  for (final p in photos) {
    await repo.sendMessage(conv.id, photoBase64: base64Encode(p));
  }
  return conv.id;
}

String _userPhone(BuildContext context) => context.read<AuthProvider>().user?.phone ?? '';

bool _isDark(BuildContext c) => Theme.of(c).brightness == Brightness.dark;

/// Каркас экрана: оранжевая шапка с 3D-иконкой, белое тело, кнопка снизу.
class _SvcScaffold extends StatelessWidget {
  const _SvcScaffold({
    required this.title,
    required this.subtitle,
    required this.icon3d,
    required this.chips,
    required this.children,
    required this.bottom,
  });
  final String title, subtitle, icon3d;
  final List<(String, String)> chips; // (svg, текст)
  final List<Widget> children;
  final Widget bottom;

  @override
  Widget build(BuildContext context) {
    final dark = _isDark(context);
    final top = MediaQuery.paddingOf(context).top;
    return Scaffold(
      backgroundColor: dark ? const Color(0xFF111113) : _bgLight,
      body: Column(children: [
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              Container(
                padding: EdgeInsets.fromLTRB(18, top + 8, 18, 34),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
                      colors: [Color(0xFFFF8A2A), Color(0xFFFF6A00), Color(0xFFE85500)]),
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _BackBtn(),
                  const SizedBox(height: 14),
                  Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(title, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: -.6, height: 1.1)),
                        const SizedBox(height: 6),
                        Text(subtitle, style: TextStyle(color: Colors.white.withValues(alpha: .9), fontSize: 14, height: 1.3, fontWeight: FontWeight.w600)),
                      ]),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      width: 76,
                      height: 76,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .12), blurRadius: 18, offset: const Offset(0, 8))]),
                      child: _svg(_Ico.glyph(icon3d, '#FF6A00'), 42),
                    ),
                  ]),
                  if (chips.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Wrap(spacing: 8, runSpacing: 8, children: [
                      for (final c in chips)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(color: Colors.white.withValues(alpha: .18), borderRadius: BorderRadius.circular(20)),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            _svg(c.$1, 15),
                            const SizedBox(width: 6),
                            Text(c.$2, style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w800)),
                          ]),
                        ),
                    ]),
                  ],
                ]),
              ),
              Transform.translate(
                offset: const Offset(0, -18),
                child: Padding(padding: const EdgeInsets.symmetric(horizontal: 14), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children)),
              ),
            ],
          ),
        ),
        Container(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + MediaQuery.paddingOf(context).bottom),
          decoration: BoxDecoration(
            color: dark ? const Color(0xFF1B1E22) : Colors.white,
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .06), blurRadius: 16, offset: const Offset(0, -4))],
          ),
          child: bottom,
        ),
      ]),
    );
  }
}

class _BackBtn extends StatelessWidget {
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () => context.canPop() ? context.pop() : context.go('/'),
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: .2), borderRadius: BorderRadius.circular(14)),
          child: _svg(_Ico._l('#FFFFFF', '<path d="M15 5l-7 7 7 7"/>', 2.6), 20),
        ),
      );
}

/// Белая карточка-блок.
class _Card extends StatelessWidget {
  const _Card({required this.children, this.title});
  final String? title;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _isDark(context) ? const Color(0xFF1B1E22) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .05), blurRadius: 20, offset: const Offset(0, 6))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (title != null) ...[
            Text(title!, style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w900, letterSpacing: -.3)),
            const SizedBox(height: 12),
          ],
          ...children,
        ]),
      );
}

/// Поле ввода с SVG-иконкой слева.
class _Field extends StatelessWidget {
  const _Field({required this.controller, required this.hint, required this.icon, this.label, this.keyboard, this.caps = TextCapitalization.none, this.maxLength, this.onChanged});
  final TextEditingController controller;
  final String hint, icon;
  final String? label;
  final TextInputType? keyboard;
  final TextCapitalization caps;
  final int? maxLength;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final dark = _isDark(context);
    final cs = Theme.of(context).colorScheme;
    OutlineInputBorder b(Color c, [double w = 1.2]) =>
        OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: c, width: w));
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (label != null)
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(label!, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: cs.onSurfaceVariant)),
        ),
      TextField(
        controller: controller,
        keyboardType: keyboard,
        textCapitalization: caps,
        maxLength: maxLength,
        onChanged: onChanged,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: hint,
          counterText: '',
          filled: true,
          fillColor: dark ? const Color(0xFF24282D) : const Color(0xFFF6F6F8),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          prefixIcon: Padding(padding: const EdgeInsets.only(left: 14, right: 10), child: _svg(icon, 21)),
          prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
          enabledBorder: b(Colors.transparent),
          focusedBorder: b(_orange, 1.6),
          border: b(Colors.transparent),
        ),
      ),
    ]);
  }
}

Widget _errBox(String e) => Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFFFDECEA), borderRadius: BorderRadius.circular(16)),
      child: Row(children: [
        _svg(_Ico.alert(), 20),
        const SizedBox(width: 8),
        Expanded(child: Text(e, style: const TextStyle(color: Color(0xFFB91C1C), fontWeight: FontWeight.w700))),
      ]),
    );

Widget _primary(String text, bool busy, VoidCallback? onTap) => SizedBox(
      height: 56,
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(colors: [Color(0xFFFF8A2A), Color(0xFFFF6A00)]),
          boxShadow: [BoxShadow(color: _orange.withValues(alpha: .35), blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          ),
          onPressed: busy ? null : onTap,
          child: busy
              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.6, color: Colors.white))
              : Text(text, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Colors.white)),
        ),
      ),
    );

class _Done extends StatelessWidget {
  const _Done({required this.title, required this.text, required this.chatId});
  final String title, text, chatId;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: _isDark(context) ? const Color(0xFF111113) : Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(children: [
            const Spacer(),
            Container(
              width: 112,
              height: 112,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(colors: [Color(0xFFFF8A2A), Color(0xFFE85500)]),
                boxShadow: [BoxShadow(color: _orange.withValues(alpha: .35), blurRadius: 30, offset: const Offset(0, 12))],
              ),
              child: _svg(_Ico.check(), 56),
            ),
            const SizedBox(height: 26),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: -.5)),
            const SizedBox(height: 10),
            Text(text, textAlign: TextAlign.center, style: TextStyle(fontSize: 15.5, height: 1.4, color: cs.onSurfaceVariant)),
            const Spacer(),
            _primary(tr('Открыть чат'), false, () => context.pushReplacement('/chats/$chatId')),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => context.canPop() ? context.pop() : context.go('/'),
              child: Text(tr('На главную'), style: const TextStyle(fontWeight: FontWeight.w800, color: _orange, fontSize: 15.5)),
            ),
          ]),
        ),
      ),
    );
  }
}

Future<ImageSource?> _pickSource(BuildContext context) => showModalBottomSheet<ImageSource>(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (c) => Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(color: _isDark(c) ? const Color(0xFF1B1E22) : Colors.white, borderRadius: BorderRadius.circular(24)),
        child: SafeArea(
          top: false,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            for (final o in [
              (ImageSource.camera, _Ico.camera(), tr('Сфотографировать')),
              (ImageSource.gallery, _Ico.gallery(), tr('Выбрать из галереи')),
            ])
              ListTile(
                leading: Container(
                  width: 42, height: 42, alignment: Alignment.center,
                  decoration: BoxDecoration(color: _orange.withValues(alpha: .1), borderRadius: BorderRadius.circular(13)),
                  child: _svg(o.$2, 22),
                ),
                title: Text(o.$3, style: const TextStyle(fontWeight: FontWeight.w800)),
                onTap: () => Navigator.pop(c, o.$1),
              ),
          ]),
        ),
      ),
    );

// ───────────────────────── Эвакуатор ─────────────────────────
class EvacuatorScreen extends StatefulWidget {
  const EvacuatorScreen({super.key});
  @override
  State<EvacuatorScreen> createState() => _EvacuatorScreenState();
}

class _EvacuatorScreenState extends State<EvacuatorScreen> {
  final _from = TextEditingController();
  final _to = TextEditingController();
  final _phone = TextEditingController();
  Position? _pos;
  bool _locating = false, _sending = false;
  String? _error, _chatId;

  @override
  void initState() {
    super.initState();
    _to.text = tr('Автосервис AUTOGROM');
    _phone.text = _userPhone(context);
  }

  @override
  void dispose() {
    _from.dispose();
    _to.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _locate() async {
    setState(() {
      _locating = true;
      _error = null;
    });
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw tr('Включите геолокацию (GPS) на телефоне и попробуйте ещё раз.');
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        throw tr('Нет доступа к местоположению. Разрешите его в настройках.');
      }
      final p = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 20)),
      );
      if (!mounted) return;
      setState(() {
        _pos = p;
        _from.text = trf('Моё местоположение ({0}, {1})', [p.latitude.toStringAsFixed(5), p.longitude.toStringAsFixed(5)]);
      });
    } catch (e) {
      if (mounted) setState(() => _error = e is String ? e : tr('Не удалось определить местоположение. Попробуйте ещё раз.'));
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _openMap() async {
    final p = _pos;
    if (p == null) return;
    // сначала приложение Яндекс Карт/Навигатора, иначе — веб-версия карт
    final app = Uri.parse('yandexmaps://maps.yandex.ru/?pt=${p.longitude},${p.latitude}&z=17');
    try {
      if (await launchUrl(app)) return;
    } catch (_) {}
    await launchUrl(Uri.parse(_yandexPoint(p.latitude, p.longitude)), mode: LaunchMode.externalApplication);
  }

  Future<void> _callOperator() async {
    final phone = context.read<CompanyProvider>().profile?.phone ?? '';
    final digits = phone.replaceAll(RegExp(r'[^\d+]'), '');
    if (digits.isEmpty) {
      setState(() => _error = tr('Номер оператора недоступен. Отправьте заявку — мы перезвоним.'));
      return;
    }
    await launchUrl(Uri.parse('tel:$digits'));
  }

  Future<void> _send() async {
    final from = _from.text.trim();
    final d = _phone.text.replaceAll(RegExp(r'\D'), '');
    if (from.isEmpty && _pos == null) return setState(() => _error = tr('Укажите, где находится машина'));
    if (d.length < 10) return setState(() => _error = tr('Проверьте номер телефона'));
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      final text = [
        '🚨 ${tr('Заявка: эвакуатор')}',
        '${tr('Откуда')}: $from',
        '${tr('Куда')}: ${_to.text.trim().isEmpty ? tr('Автосервис AUTOGROM') : _to.text.trim()}',
        '${tr('Телефон')}: ${_phone.text.trim()}',
      ].join('\n');
      final id = await _sendToServiceChat(context, text: text, location: _pos);
      if (mounted) setState(() => _chatId = id);
    } catch (_) {
      if (mounted) setState(() => _error = tr('Не удалось отправить заявку. Проверьте интернет и попробуйте ещё раз'));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_chatId != null) {
      return _Done(
          title: tr('Заявка отправлена!'),
          text: tr('Оператор свяжется с вами в ближайшее время. Переписка — в чате с автосервисом.'),
          chatId: _chatId!);
    }
    final cs = Theme.of(context).colorScheme;
    return _SvcScaffold(
      title: tr('Вызвать эвакуатор'),
      subtitle: tr('Приедем быстро и отвезём машину в сервис'),
      icon3d: 'tow',
      chips: [(_Ico.ruble(), tr('от 4000 ₽ по городу')), (_Ico.clock(), tr('24/7'))],
      bottom: Column(mainAxisSize: MainAxisSize.min, children: [
        _primary(tr('Отправить заявку'), _sending, _send),
        const SizedBox(height: 8),
        SizedBox(
          height: 50,
          width: double.infinity,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: _orange,
              side: BorderSide(color: _orange.withValues(alpha: .5), width: 1.4),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            ),
            onPressed: _callOperator,
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              _svg(_Ico.phone(), 19),
              const SizedBox(width: 8),
              Text(tr('Позвонить оператору'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            ]),
          ),
        ),
      ]),
      children: [
        _Card(title: tr('Где находится машина?'), children: [
          _Field(
            controller: _from,
            hint: tr('Введите адрес или ориентир'),
            icon: _Ico.pin(),
            onChanged: (_) {
              if (_pos != null) setState(() => _pos = null);
            },
          ),
          const SizedBox(height: 10),
          Material(
            color: _orange.withValues(alpha: .08),
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: _locating || _sending ? null : _locate,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  if (_locating)
                    const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.4, color: _orange))
                  else
                    _svg(_Ico.gps(), 20),
                  const SizedBox(width: 10),
                  Text(_locating ? tr('Определяю…') : tr('Указать моё местоположение'),
                      style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, color: _orange)),
                ]),
              ),
            ),
          ),
          if (_pos != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 6, 8),
              decoration: BoxDecoration(color: const Color(0xFFE8F7EE), borderRadius: BorderRadius.circular(14)),
              child: Row(children: [
                Container(
                  width: 22, height: 22, alignment: Alignment.center,
                  decoration: const BoxDecoration(color: Color(0xFF16A34A), shape: BoxShape.circle),
                  child: _svg(_Ico.check(), 13),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(tr('Точка определена — оператор увидит её на карте'),
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF166534)))),
                TextButton(
                  onPressed: _openMap,
                  child: Text(tr('Яндекс Карты'), style: const TextStyle(color: _orange, fontWeight: FontWeight.w900)),
                ),
              ]),
            ),
          ],
        ]),
        _Card(title: tr('Куда отвезти?'), children: [
          _Field(controller: _to, hint: tr('Автосервис AUTOGROM'), icon: _Ico.flag()),
        ]),
        _Card(title: tr('Телефон для связи'), children: [
          _Field(controller: _phone, hint: '+7 (___) ___-__-__', icon: _Ico.phone(), keyboard: TextInputType.phone),
        ]),
        if (_error != null) _errBox(_error!),
        Text(tr('Нажимая «Отправить», вы соглашаетесь на обработку персональных данных для связи с вами.'),
            textAlign: TextAlign.center, style: TextStyle(fontSize: 11.5, color: cs.onSurfaceVariant)),
      ],
    );
  }
}

// ───────────────────────── Кузовной ремонт ─────────────────────────
class BodyRepairScreen extends StatefulWidget {
  const BodyRepairScreen({super.key});
  @override
  State<BodyRepairScreen> createState() => _BodyRepairScreenState();
}

class _BodyRepairScreenState extends State<BodyRepairScreen> {
  static const _max = 5;
  final _phone = TextEditingController();
  final _car = TextEditingController();
  final _year = TextEditingController();
  final _color = TextEditingController();
  final List<Uint8List> _photos = [];
  bool _sending = false;
  String? _error, _chatId;

  @override
  void initState() {
    super.initState();
    _phone.text = _userPhone(context);
  }

  @override
  void dispose() {
    for (final c in [_phone, _car, _year, _color]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _add() async {
    final left = _max - _photos.length;
    if (left <= 0) return;
    final src = await _pickSource(context);
    if (src == null) return;
    try {
      final picker = ImagePicker();
      final files = src == ImageSource.camera
          ? [if (await picker.pickImage(source: src, maxWidth: 1600, imageQuality: 80) case final f?) f]
          : await picker.pickMultiImage(maxWidth: 1600, imageQuality: 80, limit: left > 1 ? left : null);
      final added = <Uint8List>[];
      for (final f in files.take(left)) {
        added.add(await f.readAsBytes());
      }
      if (mounted) setState(() { _photos.addAll(added); _error = null; });
    } catch (_) {
      if (mounted) setState(() => _error = tr('Не удалось открыть камеру или галерею'));
    }
  }

  Future<void> _send() async {
    final d = _phone.text.replaceAll(RegExp(r'\D'), '');
    final y = int.tryParse(_year.text.trim());
    if (d.length < 10) return setState(() => _error = tr('Проверьте номер телефона'));
    if (_car.text.trim().length < 2) return setState(() => _error = tr('Укажите марку и модель'));
    if (y == null || y < 1960 || y > DateTime.now().year + 1) return setState(() => _error = tr('Укажите год выпуска'));
    if (_color.text.trim().isEmpty) return setState(() => _error = tr('Укажите цвет машины'));
    if (_photos.isEmpty) return setState(() => _error = tr('Добавьте хотя бы одно фото повреждения'));
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      final text = [
        '🛠 ${tr('Заявка: кузовной ремонт — оценка по фото')}',
        '${tr('Машина')}: ${_car.text.trim()}, $y, ${_color.text.trim()}',
        '${tr('Телефон')}: ${_phone.text.trim()}',
        '${tr('Фото')}: ${_photos.length}',
      ].join('\n');
      final id = await _sendToServiceChat(context, text: text, photos: _photos);
      if (mounted) setState(() => _chatId = id);
    } catch (_) {
      if (mounted) setState(() => _error = tr('Не удалось отправить заявку. Проверьте интернет и попробуйте ещё раз'));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_chatId != null) {
      return _Done(
          title: tr('Фото отправлены!'),
          text: tr('Мастер оценит повреждения и напишет стоимость в чате с автосервисом.'),
          chatId: _chatId!);
    }
    final cs = Theme.of(context).colorScheme;
    final dark = _isDark(context);
    return _SvcScaffold(
      title: tr('Кузовной ремонт'),
      subtitle: tr('Пришлите фото — оценим стоимость бесплатно'),
      icon3d: 'bodycam',
      chips: [(_Ico.camera('#FFFFFF'), tr('до 5 фото')), (_Ico.shield(), tr('Бесплатно'))],
      bottom: _primary(tr('Отправить на оценку'), _sending, _send),
      children: [
        _Card(title: tr('Фото повреждений'), children: [
          Text(trf('Общий вид и крупно место удара — до {0} фото', [_max]),
              style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            children: [
              for (var i = 0; i < _photos.length; i++)
                Stack(fit: StackFit.expand, children: [
                  ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.memory(_photos[i], fit: BoxFit.cover)),
                  Positioned(
                    top: 5,
                    right: 5,
                    child: GestureDetector(
                      onTap: _sending ? null : () => setState(() => _photos.removeAt(i)),
                      child: Container(
                        width: 24, height: 24, alignment: Alignment.center,
                        decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                        child: _svg(_Ico.close(), 12),
                      ),
                    ),
                  ),
                ]),
              if (_photos.length < _max)
                GestureDetector(
                  onTap: _sending ? null : _add,
                  child: Container(
                    decoration: BoxDecoration(
                      color: dark ? const Color(0xFF24282D) : const Color(0xFFFFF4EC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _orange.withValues(alpha: .4), width: 1.4),
                    ),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Container(
                        width: 36, height: 36, alignment: Alignment.center,
                        decoration: const BoxDecoration(color: _orange, shape: BoxShape.circle),
                        child: _svg(_Ico.plus('#FFFFFF'), 20),
                      ),
                      const SizedBox(height: 6),
                      Text('${_photos.length}/$_max', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: _orange)),
                    ]),
                  ),
                ),
            ],
          ),
        ]),
        _Card(title: tr('Автомобиль'), children: [
          _Field(controller: _car, hint: tr('Например, Kia Rio'), label: tr('Марка и модель'), icon: _Ico.car(), caps: TextCapitalization.words),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _Field(controller: _year, hint: '2019', label: tr('Год'), icon: _Ico.calendar(), keyboard: TextInputType.number, maxLength: 4)),
            const SizedBox(width: 10),
            Expanded(child: _Field(controller: _color, hint: tr('Белый'), label: tr('Цвет'), icon: _Ico.palette(), caps: TextCapitalization.sentences)),
          ]),
        ]),
        _Card(title: tr('Телефон для связи'), children: [
          _Field(controller: _phone, hint: '+7 (___) ___-__-__', icon: _Ico.phone(), keyboard: TextInputType.phone),
        ]),
        if (_error != null) _errBox(_error!),
        Text(tr('Нажимая «Отправить», вы соглашаетесь на обработку персональных данных для связи с вами.'),
            textAlign: TextAlign.center, style: TextStyle(fontSize: 11.5, color: cs.onSurfaceVariant)),
      ],
    );
  }
}
