// AG_FEEDBACK1 — «Нашли ошибку или есть предложение?»: короткая форма, уходит в Telegram AG Service.
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../../../core/i18n.dart';
import '../../auth/providers/auth_provider.dart';

const _orange = Color(0xFFF26200);

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
    InputDecoration deco(String hint, IconData icon) => InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, size: 20),
          filled: true,
          fillColor: cs.surfaceContainerHighest.withValues(alpha: .5),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        );
    Widget chip(String k, String label, IconData icon) {
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
              Icon(icon, size: 18, color: on ? _orange : cs.onSurfaceVariant),
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
          chip('bug', tr('Ошибка'), Icons.bug_report_outlined),
          const SizedBox(width: 10),
          chip('idea', tr('Предложение'), Icons.lightbulb_outline_rounded),
        ]),
        const SizedBox(height: 12),
        TextField(controller: _email, keyboardType: TextInputType.emailAddress, style: const TextStyle(fontSize: 16), decoration: deco(tr('Ваша почта'), Icons.alternate_email_rounded)),
        const SizedBox(height: 10),
        TextField(
          controller: _text, minLines: 4, maxLines: 8, maxLength: 2000, style: const TextStyle(fontSize: 16),
          decoration: deco(_kind == 'bug' ? tr('Что случилось? На каком экране и что вы нажимали?') : tr('Что бы вы хотели улучшить или добавить?'), Icons.edit_note_rounded),
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
