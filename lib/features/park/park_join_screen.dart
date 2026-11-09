// AG_PARK1 — «Подключение к парку Азия Про»: ФИО, телефон, 2 фото СТС → заявка уходит в группу «Азия парк» на job.autogrom.ru.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'dart:typed_data';

import '../../core/i18n.dart';
import '../../core/theme.dart';
import '../auth/providers/auth_provider.dart';

const _parkApi = 'https://job.autogrom.ru/ag_park_api.php';

class ParkJoinScreen extends StatefulWidget {
  const ParkJoinScreen({super.key});

  @override
  State<ParkJoinScreen> createState() => _ParkJoinScreenState();
}

class _ParkJoinScreenState extends State<ParkJoinScreen> {
  final _fio = TextEditingController();
  final _phone = TextEditingController();
  // AG_PARK2: 0 — СТС лицевая, 1 — СТС оборот, 2 — права лицевая, 3 — права оборот
  final List<XFile?> _files = [null, null, null, null];
  final List<Uint8List?> _bytes = [null, null, null, null];
  String? _country;

  static const _countries = <List<String>>[
    ['🇷🇺', 'Россия'], ['🇹🇯', 'Таджикистан'], ['🇺🇿', 'Узбекистан'], ['🇰🇬', 'Кыргызстан'],
    ['🇰🇿', 'Казахстан'], ['🇦🇲', 'Армения'], ['🇦🇿', 'Азербайджан'], ['🇧🇾', 'Беларусь'], ['🌍', 'Другая страна'],
  ];
  bool _sending = false;
  String? _error;
  String? _doneNumber;

  @override
  void initState() {
    super.initState();
    final u = context.read<AuthProvider>().user;
    if (u != null) {
      if (u.name.trim().split(RegExp(r'\s+')).length >= 2) _fio.text = u.name.trim();
      if ((u.phone ?? '').isNotEmpty) _phone.text = u.phone!;
    }
  }

  @override
  void dispose() {
    _fio.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _pick(int slot) async {
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
      final f = await ImagePicker().pickImage(source: src, maxWidth: 2200, imageQuality: 82);
      if (f == null) return;
      final bytes = await f.readAsBytes();
      setState(() {
        _files[slot] = f;
        _bytes[slot] = bytes;
        _error = null;
      });
    } catch (_) {
      setState(() => _error = tr('Не удалось открыть камеру или галерею'));
    }
  }

  String? _validate() {
    final fio = _fio.text.trim();
    if (fio.split(RegExp(r'\s+')).length < 2 || fio.length < 5) return tr('Укажите фамилию, имя и отчество');
    final d = _phone.text.replaceAll(RegExp(r'\D'), '');
    if (d.length < 10) return tr('Проверьте номер телефона');
    if (_bytes[0] == null) return tr('Добавьте фото СТС — лицевая сторона');
    if (_bytes[1] == null) return tr('Добавьте фото СТС — оборотная сторона');
    if (_country == null) return tr('Выберите, какой страны у вас права');
    if (_bytes[2] == null) return tr('Добавьте фото прав — лицевая сторона');
    if (_bytes[3] == null) return tr('Добавьте фото прав — оборотная сторона');
    return null;
  }

  Future<void> _send() async {
    final err = _validate();
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      final req = http.MultipartRequest('POST', Uri.parse(_parkApi))
        ..fields['fio'] = _fio.text.trim()
        ..fields['phone'] = _phone.text.trim()
        ..fields['user_id'] = context.read<AuthProvider>().user?.id ?? ''
        ..fields['license_country'] = _country!;
      const names = ['sts_front', 'sts_back', 'license_front', 'license_back'];
      for (var i = 0; i < 4; i++) {
        req.files.add(http.MultipartFile.fromBytes(names[i], _bytes[i]!, filename: _name(_files[i], names[i])));
      }
      final res = await http.Response.fromStream(await req.send().timeout(const Duration(seconds: 90)));
      Map<String, dynamic> j = {};
      try {
        j = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      } catch (_) {}
      if (j['ok'] == true) {
        setState(() => _doneNumber = (j['number'] ?? '').toString());
      } else {
        setState(() => _error = (j['error'] ?? tr('Не удалось отправить заявку. Попробуйте ещё раз')).toString());
      }
    } catch (_) {
      setState(() => _error = tr('Нет связи. Проверьте интернет и попробуйте ещё раз'));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  String _name(XFile? f, String def) {
    final n = f?.name ?? '';
    return n.contains('.') ? n : '$def.jpg';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(tr('Подключение к парку'))),
      body: SafeArea(
        child: _doneNumber != null ? _done(colors) : _form(colors),
      ),
    );
  }

  Widget _done(ColorScheme colors) {
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
          Text(tr('Ваша заявка отправлена!'), textAlign: TextAlign.center, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -.4)),
          const SizedBox(height: 10),
          Text(tr('Скоро менеджер парка «Азия Про» свяжется с вами по указанному номеру.'),
              textAlign: TextAlign.center, style: TextStyle(fontSize: 15.5, height: 1.4, color: colors.onSurfaceVariant)),
          if (_doneNumber!.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(color: BrandColors.orange.withValues(alpha: .1), borderRadius: BorderRadius.circular(12)),
              child: Text(trf('Номер заявки: {0}', [_doneNumber]), style: const TextStyle(color: BrandColors.orange, fontWeight: FontWeight.w800)),
            ),
          ],
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: FilledButton(
              style: FilledButton.styleFrom(backgroundColor: BrandColors.orange, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              onPressed: () => context.canPop() ? context.pop() : context.go('/'),
              child: Text(tr('Готово'), style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800)),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _form(ColorScheme colors) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    InputDecoration deco(String label, IconData icon) => InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: BrandColors.orange),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        );
    return ListView(
      padding: EdgeInsets.fromLTRB(18, 8, 18, 120 + MediaQuery.paddingOf(context).bottom),
      children: [
        // шапка
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFFF8A2A), Color(0xFFC94400)]),
          ),
          child: Row(children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: .2), borderRadius: BorderRadius.circular(16)),
              child: const Icon(Icons.local_taxi_rounded, color: Colors.white, size: 30),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(tr('Парк «Азия Про»'), style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                const SizedBox(height: 3),
                Text(tr('Оставьте заявку — менеджер свяжется с вами и поможет подключиться'),
                    style: TextStyle(color: Colors.white.withValues(alpha: .92), fontSize: 13, height: 1.3, fontWeight: FontWeight.w600)),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 20),
        TextField(controller: _fio, textCapitalization: TextCapitalization.words, decoration: deco(tr('Фамилия Имя Отчество'), Icons.person_rounded)),
        const SizedBox(height: 12),
        TextField(controller: _phone, keyboardType: TextInputType.phone, decoration: deco(tr('Номер телефона'), Icons.phone_rounded)),
        const SizedBox(height: 22),
        Text(tr('Фото СТС (свидетельство о регистрации ТС)'), style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(tr('Сфотографируйте обе стороны так, чтобы все данные читались'),
            style: TextStyle(fontSize: 13, color: colors.onSurfaceVariant)),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _photoBox(tr('Лицевая сторона'), _bytes[0], () => _pick(0), dark)),
          const SizedBox(width: 12),
          Expanded(child: _photoBox(tr('Оборотная сторона'), _bytes[1], () => _pick(1), dark)),
        ]),
        const SizedBox(height: 26),
        // AG_PARK2: водительские права — сначала страна, потом фото
        Text(tr('Водительское удостоверение'), style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(tr('Права какой страны у вас?'), style: TextStyle(fontSize: 13, color: colors.onSurfaceVariant)),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final c in _countries)
            ChoiceChip(
              label: Text('${c[0]}  ${tr(c[1])}'),
              selected: _country == c[1],
              showCheckmark: false,
              selectedColor: BrandColors.orange,
              labelStyle: TextStyle(fontWeight: FontWeight.w700, color: _country == c[1] ? Colors.white : null),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              side: BorderSide(color: _country == c[1] ? BrandColors.orange : colors.outlineVariant),
              onSelected: _sending ? null : (_) => setState(() { _country = c[1]; _error = null; }),
            ),
        ]),
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          child: _country == null
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(trf('Фото прав ({0}) — обе стороны', [tr(_country!)]), style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 10),
                    Row(children: [
                      Expanded(child: _photoBox(tr('Лицевая сторона'), _bytes[2], () => _pick(2), dark)),
                      const SizedBox(width: 12),
                      Expanded(child: _photoBox(tr('Оборотная сторона'), _bytes[3], () => _pick(3), dark)),
                    ]),
                  ]),
                ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFFDECEA), borderRadius: BorderRadius.circular(14)),
            child: Text(_error!, style: const TextStyle(color: Color(0xFFB91C1C), fontWeight: FontWeight.w700)),
          ),
        ],
        const SizedBox(height: 22),
        SizedBox(
          height: 56,
          child: FilledButton(
            style: FilledButton.styleFrom(backgroundColor: BrandColors.orange, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
            onPressed: _sending ? null : _send,
            child: _sending
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.6, color: Colors.white))
                : Text(tr('Отправить заявку'), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
          ),
        ),
        const SizedBox(height: 10),
        Text(tr('Нажимая «Отправить», вы соглашаетесь на обработку персональных данных для связи с вами.'),
            textAlign: TextAlign.center, style: TextStyle(fontSize: 11.5, color: colors.onSurfaceVariant)),
      ],
    );
  }

  Widget _photoBox(String label, Uint8List? bytes, VoidCallback onTap, bool dark) {
    return GestureDetector(
      onTap: _sending ? null : onTap,
      child: AspectRatio(
        aspectRatio: 1.3,
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: dark ? const Color(0xFF1B1E22) : const Color(0xFFFFF4EC),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: bytes == null ? BrandColors.orange.withValues(alpha: .45) : const Color(0xFF16A34A), width: 1.5),
          ),
          child: bytes == null
              ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.add_a_photo_rounded, color: BrandColors.orange, size: 30),
                  const SizedBox(height: 6),
                  Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800)),
                ])
              : Stack(fit: StackFit.expand, children: [
                  Image.memory(bytes, fit: BoxFit.cover),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      color: Colors.black.withValues(alpha: .55),
                      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const Icon(Icons.check_circle_rounded, color: Color(0xFF4ADE80), size: 15),
                        const SizedBox(width: 4),
                        Text(label, style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w700)),
                      ]),
                    ),
                  ),
                ]),
        ),
      ),
    );
  }
}
