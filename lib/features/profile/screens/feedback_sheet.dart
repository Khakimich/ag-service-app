// AG_FEEDBACK1 — «Нашли ошибку или есть предложение?»: короткая форма, уходит в Telegram AG Service.
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../../../core/i18n.dart';
import '../../auth/providers/auth_provider.dart';

const _orange = Color(0xFFF26200);

// AG_FEEDBACK2: SVG-иконки (шрифт Material Icons в веб-версии не всегда загружается)
const _ic = {
  'bug': '<path d="M9 9a3 3 0 0 1 6 0"/><rect x="7.5" y="9" width="9" height="11" rx="4.5"/><path d="M12 12v8M4 13h3.5M16.5 13H20M5 8.5l2.8 2M19 8.5l-2.8 2M5 19l2.8-2M19 19l-2.8-2M10 6.2 8.8 4.5M14 6.2l1.2-1.7"/>',
  'idea': '<path d="M9 18h6M10 21h4"/><path d="M12 3a6 6 0 0 0-3.5 10.9c.6.5 1 1.2 1 2V16h5v-.1c0-.8.4-1.5 1-2A6 6 0 0 0 12 3z"/>',
  'mail': '<rect x="3" y="5" width="18" height="14" rx="2.5"/><path d="M3.5 6.5 12 13l8.5-6.5"/>',
  'note': '<path d="M4 20h4l10.5-10.5a2.1 2.1 0 0 0-3-3L5 17v3z"/><path d="M13.5 8.5l3 3"/>',
};
Widget _svgIc(String k, Color c, [double size = 20]) => SvgPicture.string(
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">${_ic[k]}</svg>',
    width: size, height: size);

Future<void> showFeedbackSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    useRootNavigator: true, // поверх нижнего меню, кнопка не перекрывается
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => const _FeedbackSheet(),
  );
}

class _FeedbackSheet extends StatefulWidget {
  const _FeedbackSheet();
  @override
  State<_FeedbackSheet> createState() => _FeedbackSheetState();
}

class _FeedbackSheetState extends State<_FeedbackSheet> {
  String _kind = 'bug';
  final _email = TextEditingController();
  final _text = TextEditingController();
  bool _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final u = context.read<AuthProvider>().user;
    if (u != null && u.email.contains('@')) _email.text = u.email;
  }

  @override
  void dispose() { _email.dispose(); _text.dispose(); super.dispose(); }

  Future<void> _send() async {
    final email = _email.text.trim(), text = _text.text.trim();
    if (RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email) == false) { setState(() => _error = tr('Укажите почту, чтобы мы могли ответить')); return; }
    if (text.length < 5) { setState(() => _error = tr('Опишите подробнее, хотя бы пару слов')); return; }
    setState(() { _sending = true; _error = null; });
    final u = context.read<AuthProvider>().user;
    try {
      final r = await http.post(
        Uri.parse('https://job.autogrom.ru/ag_feedback.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'kind': _kind, 'email': email, 'text': text,
          'name': u?.name ?? '', 'phone': u?.phone ?? '',
          'platform': kIsWeb ? 'web' : defaultTargetPlatform.name,
        }),
      ).timeout(const Duration(seconds: 20));
      final ok = r.statusCode == 200 && (jsonDecode(r.body) as Map)['ok'] == true;
      if (mounted == false) return;
      if (ok) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('Спасибо! Сообщение отправлено команде AG Service'))));
      } else {
        setState(() { _sending = false; _error = tr('Не удалось отправить. Попробуйте ещё раз'); });
      }
    } catch (_) {
      if (mounted) setState(() { _sending = false; _error = tr('Нет связи. Проверьте интернет и попробуйте ещё раз'); });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    InputDecoration deco(String hint, String icon) => InputDecoration(
          hintText: hint,
          prefixIcon: Padding(padding: const EdgeInsets.all(13), child: _svgIc(icon, cs.onSurfaceVariant)),
          filled: true,
          fillColor: cs.surfaceContainerHighest.withValues(alpha: .5),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        );
    Widget chip(String k, String label, String icon) {
      final on = _kind == k;
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _kind = k),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: on ? _orange.withValues(alpha: .12) : cs.surfaceContainerHighest.withValues(alpha: .5),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: on ? _orange : Colors.transparent, width: 1.5),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              _svgIc(icon, on ? _orange : cs.onSurfaceVariant, 19),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(fontWeight: FontWeight.w800, color: on ? _orange : cs.onSurface)),
            ]),
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.only(left: 20, right: 20, top: 12, bottom: MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom + 24),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: cs.outlineVariant, borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 16),
        Text(tr('Нашли ошибку или есть идея?'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        Text(tr('Напишите нам — сообщение сразу получит команда AG Service.'), style: TextStyle(color: cs.onSurfaceVariant)),
        const SizedBox(height: 16),
        Row(children: [
          chip('bug', tr('Ошибка'), 'bug'),
          const SizedBox(width: 10),
          chip('idea', tr('Предложение'), 'idea'),
        ]),
        const SizedBox(height: 12),
        TextField(controller: _email, keyboardType: TextInputType.emailAddress, style: const TextStyle(fontSize: 16), decoration: deco(tr('Ваша почта'), 'mail')),
        const SizedBox(height: 10),
        TextField(
          controller: _text, minLines: 4, maxLines: 8, maxLength: 2000, style: const TextStyle(fontSize: 16),
          decoration: deco(_kind == 'bug' ? tr('Что случилось? На каком экране и что вы нажимали?') : tr('Что бы вы хотели улучшить или добавить?'), 'note'),
        ),
        if (_error != null) Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(_error!, style: const TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.w700))),
        SizedBox(
          height: 52,
          child: FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _orange, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
            onPressed: _sending ? null : _send,
            child: _sending
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                : Text(tr('Отправить'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          ),
        ),
      ]),
    );
  }
}
