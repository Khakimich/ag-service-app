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

import '../../core/ag_icon3d.dart';
import '../../core/i18n.dart';
import '../../core/theme.dart';
import '../auth/providers/auth_provider.dart';
import '../booking/providers/company_provider.dart';
import '../chat/data/chat_repository.dart';

const _orange = BrandColors.orange;
const _dept = 'autogrom_service';

// ───────────────────────── Иконки (SVG) ─────────────────────────
class _Ico {
  static const pin = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#FF6A00" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">'
      '<path d="M12 21s-7-6.2-7-11.5a7 7 0 0 1 14 0C19 14.8 12 21 12 21z"/><circle cx="12" cy="9.5" r="2.5"/></svg>';
}

Widget _svg(String s, double size) => SvgPicture.string(s, width: size, height: size);

// ───────────────────────── Раздел на главной ─────────────────────────
class ServicesHubSection extends StatelessWidget {
  const ServicesHubSection({super.key});

  @override
  Widget build(BuildContext context) {
    final items = <_HubItem>[
      _HubItem('taxi', tr('Работа в Яндекс Такси'), tr('Парк «Азия Про» · комиссия 0%'),
          const [Color(0xFFFFC53D), Color(0xFFF59E0B)], () => context.push('/park')),
      _HubItem('tow', tr('Вызвать эвакуатор'), tr('По городу от 4000 ₽'),
          const [Color(0xFFFF8A2A), Color(0xFFE04E00)], () => context.push('/evacuator')),
      _HubItem('bodycam', tr('Кузовной ремонт'), tr('Оценка стоимости по фото'),
          const [Color(0xFF4F8BFF), Color(0xFF2057DF)], () => context.push('/body-repair')),
      _HubItem('shield', tr('Сравни ОСАГО для такси'), tr('Выгодный полис для работы в такси'),
          const [Color(0xFF34D399), Color(0xFF059669)], () => _soon(context), soon: true),
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(tr('Сервисы'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -.4)),
      const SizedBox(height: 12),
      for (var i = 0; i < items.length; i++) ...[
        _HubTile(item: items[i]),
        if (i != items.length - 1) const SizedBox(height: 10),
      ],
    ]);
  }

  static void _soon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(tr('Сравнение ОСАГО для такси скоро появится'))),
    );
  }
}

class _HubItem {
  const _HubItem(this.icon, this.title, this.subtitle, this.colors, this.onTap, {this.soon = false});
  final String icon, title, subtitle;
  final List<Color> colors;
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
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: item.onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: cs.outlineVariant.withValues(alpha: .5)),
          ),
          child: Row(children: [
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
                    colors: [item.colors[0].withValues(alpha: .14), item.colors[1].withValues(alpha: .08)]),
              ),
              child: AgIcon3D(item.icon, size: 40),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: -.2)),
                const SizedBox(height: 2),
                Text(item.subtitle, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: cs.onSurfaceVariant)),
              ]),
            ),
            if (item.soon)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: cs.surfaceContainerHighest, borderRadius: BorderRadius.circular(8)),
                child: Text(tr('Скоро'), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: cs.onSurfaceVariant)),
              )
            else
              const Icon(Icons.chevron_right_rounded, color: _orange, size: 24),
          ]),
        ),
      ),
    );
  }
}

// ───────────────────────── Общие части экранов ─────────────────────────
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

InputDecoration _deco(BuildContext context, String hint) {
  final dark = Theme.of(context).brightness == Brightness.dark;
  final cs = Theme.of(context).colorScheme;
  OutlineInputBorder b(Color c) => OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: c, width: 1.2));
  return InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: dark ? const Color(0xFF1B1E22) : Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    enabledBorder: b(cs.outlineVariant),
    focusedBorder: b(_orange),
    border: b(cs.outlineVariant),
  );
}

Widget _label(String t) => Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 18),
      child: Text(t, style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800)),
    );

Widget _errBox(String e) => Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFFFDECEA), borderRadius: BorderRadius.circular(14)),
      child: Text(e, style: const TextStyle(color: Color(0xFFB91C1C), fontWeight: FontWeight.w700)),
    );

Widget _primary(String text, bool busy, VoidCallback? onTap) => SizedBox(
      height: 56,
      child: FilledButton(
        style: FilledButton.styleFrom(backgroundColor: _orange, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
        onPressed: busy ? null : onTap,
        child: busy
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.6, color: Colors.white))
            : Text(text, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
      ),
    );

class _Done extends StatelessWidget {
  const _Done({required this.title, required this.text, required this.chatId});
  final String title, text, chatId;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 96,
            height: 96,
            decoration: const BoxDecoration(color: Color(0xFFE8F7EE), shape: BoxShape.circle),
            child: const Icon(Icons.check_rounded, color: Color(0xFF16A34A), size: 56),
          ),
          const SizedBox(height: 22),
          Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -.4)),
          const SizedBox(height: 10),
          Text(text, textAlign: TextAlign.center, style: TextStyle(fontSize: 15.5, height: 1.4, color: cs.onSurfaceVariant)),
          const SizedBox(height: 28),
          SizedBox(width: double.infinity, child: _primary(tr('Открыть чат'), false, () => context.pushReplacement('/chats/$chatId'))),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => context.canPop() ? context.pop() : context.go('/'),
            child: Text(tr('На главную'), style: const TextStyle(fontWeight: FontWeight.w800, color: _orange)),
          ),
        ]),
      ),
    );
  }
}

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
    // сначала Яндекс Навигатор/Карты, если не установлены — веб-версия карт
    final nav = Uri.parse('yandexmaps://maps.yandex.ru/?pt=${p.longitude},${p.latitude}&z=17');
    if (await canLaunchUrl(nav) && await launchUrl(nav)) return;
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
    return Scaffold(
      appBar: AppBar(title: Text(tr('Вызвать эвакуатор'))),
      body: SafeArea(
        child: _chatId != null
            ? _Done(
                title: tr('Заявка отправлена!'),
                text: tr('Оператор свяжется с вами в ближайшее время. Переписка — в чате с автосервисом.'),
                chatId: _chatId!)
            : _form(),
      ),
    );
  }

  Widget _form() {
    final cs = Theme.of(context).colorScheme;
    return ListView(
      padding: EdgeInsets.fromLTRB(18, 4, 18, 40 + MediaQuery.paddingOf(context).bottom),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: _orange.withValues(alpha: .08), borderRadius: BorderRadius.circular(16)),
          child: Row(children: [
            Container(
              width: 42, height: 42, alignment: Alignment.center,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: _orange.withValues(alpha: .14)),
              child: const AgIcon3D('tow', size: 34),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(tr('Эвакуатор по городу от 4000 ₽'), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800))),
          ]),
        ),
        _label(tr('Где находится машина?')),
        TextField(controller: _from, decoration: _deco(context, tr('Введите адрес или ориентир')),
            onChanged: (_) { if (_pos != null) setState(() => _pos = null); }),
        const SizedBox(height: 10),
        SizedBox(
          height: 52,
          child: FilledButton.tonal(
            style: FilledButton.styleFrom(
              backgroundColor: _orange.withValues(alpha: .1),
              foregroundColor: cs.onSurface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: _locating || _sending ? null : _locate,
            child: _locating
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: _orange))
                : Row(mainAxisSize: MainAxisSize.min, children: [
                    _svg(_Ico.pin, 20),
                    const SizedBox(width: 8),
                    Text(tr('Указать моё местоположение'), style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800)),
                  ]),
          ),
        ),
        if (_pos != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(children: [
              const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 18),
              const SizedBox(width: 6),
              Expanded(child: Text(tr('Точка определена — оператор увидит её на карте'),
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: cs.onSurfaceVariant))),
              TextButton(onPressed: _openMap, child: Text(tr('Яндекс Карты'), style: const TextStyle(color: _orange, fontWeight: FontWeight.w800))),
            ]),
          ),
        _label(tr('Куда отвезти?')),
        TextField(controller: _to, decoration: _deco(context, tr('Автосервис AUTOGROM'))),
        _label(tr('Телефон для связи')),
        TextField(controller: _phone, keyboardType: TextInputType.phone, decoration: _deco(context, '+7 (___) ___-__-__')),
        if (_error != null) _errBox(_error!),
        const SizedBox(height: 22),
        _primary(tr('Отправить заявку'), _sending, _send),
        const SizedBox(height: 10),
        SizedBox(
          height: 52,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: cs.onSurface,
              side: BorderSide(color: cs.outlineVariant),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            ),
            onPressed: _callOperator,
            child: Text(tr('Позвонить оператору'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          ),
        ),
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
    final src = await showModalBottomSheet<ImageSource>(
      context: context,
      useRootNavigator: true,
      builder: (c) => SafeArea(
        child: Wrap(children: [
          ListTile(leading: const Icon(Icons.photo_camera_rounded), title: Text(tr('Сфотографировать')), onTap: () => Navigator.pop(c, ImageSource.camera)),
          ListTile(leading: const Icon(Icons.photo_library_rounded), title: Text(tr('Выбрать из галереи')), onTap: () => Navigator.pop(c, ImageSource.gallery)),
        ]),
      ),
    );
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
    return Scaffold(
      appBar: AppBar(title: Text(tr('Кузовной ремонт'))),
      body: SafeArea(
        child: _chatId != null
            ? _Done(
                title: tr('Фото отправлены!'),
                text: tr('Мастер оценит повреждения и напишет стоимость в чате с автосервисом.'),
                chatId: _chatId!)
            : _form(),
      ),
    );
  }

  Widget _form() {
    final cs = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return ListView(
      padding: EdgeInsets.fromLTRB(18, 4, 18, 40 + MediaQuery.paddingOf(context).bottom),
      children: [
        Text(tr('Оценим стоимость по фото — бесплатно'), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurfaceVariant)),
        _label(tr('Номер телефона')),
        TextField(controller: _phone, keyboardType: TextInputType.phone, decoration: _deco(context, '+7 (___) ___-__-__')),
        _label(tr('Марка и модель')),
        TextField(controller: _car, textCapitalization: TextCapitalization.words, decoration: _deco(context, tr('Например, Kia Rio'))),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _label(tr('Год')),
            TextField(controller: _year, keyboardType: TextInputType.number, maxLength: 4,
                decoration: _deco(context, '2019').copyWith(counterText: '')),
          ])),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _label(tr('Цвет')),
            TextField(controller: _color, textCapitalization: TextCapitalization.sentences, decoration: _deco(context, tr('Белый'))),
          ])),
        ]),
        _label(trf('Фото повреждений (до {0})', [_max])),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          children: [
            for (var i = 0; i < _photos.length; i++)
              Stack(fit: StackFit.expand, children: [
                ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.memory(_photos[i], fit: BoxFit.cover)),
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: _sending ? null : () => setState(() => _photos.removeAt(i)),
                    child: Container(
                      decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                      padding: const EdgeInsets.all(3),
                      child: const Icon(Icons.close_rounded, size: 16, color: Colors.white),
                    ),
                  ),
                ),
              ]),
            if (_photos.length < _max)
              GestureDetector(
                onTap: _sending ? null : _add,
                child: Container(
                  decoration: BoxDecoration(
                    color: dark ? const Color(0xFF1B1E22) : const Color(0xFFFFF4EC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _orange.withValues(alpha: .45), width: 1.4),
                  ),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.add_a_photo_rounded, color: _orange, size: 26),
                    const SizedBox(height: 4),
                    Text('${_photos.length}/$_max', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                  ]),
                ),
              ),
          ],
        ),
        if (_error != null) _errBox(_error!),
        const SizedBox(height: 22),
        _primary(tr('Отправить на оценку'), _sending, _send),
        const SizedBox(height: 10),
        Text(tr('Нажимая «Отправить», вы соглашаетесь на обработку персональных данных для связи с вами.'),
            textAlign: TextAlign.center, style: TextStyle(fontSize: 11.5, color: cs.onSurfaceVariant)),
      ],
    );
  }
}
