// AG_I18N1 — языки приложения: русский, узбекский, таджикский, туркменский, английский.
// tr('Текст') — перевод фразы на выбранный язык; trf('Баланс: {0} ₽', [x]) — фраза с подстановкой.
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'i18n_data.dart';

class AgLang {
  const AgLang(this.code, this.name, this.flag, this.hint);
  final String code;
  final String name;
  final String flag;
  final String hint;
}

class AgI18n {
  const AgI18n._();

  static const langs = <AgLang>[
    AgLang('ru', 'Русский', '🇷🇺', 'Russian'),
    AgLang('uz', 'O‘zbekcha', '🇺🇿', 'Uzbek'),
    AgLang('tg', 'Тоҷикӣ', '🇹🇯', 'Tajik'),
    AgLang('tk', 'Türkmençe', '🇹🇲', 'Turkmen'),
    AgLang('en', 'English', '🇬🇧', 'English'),
  ];

  static final ValueNotifier<String> lang = ValueNotifier<String>('ru');
  static const _prefKey = 'ag_lang';

  static String get code => lang.value;
  static AgLang get current => langs.firstWhere((l) => l.code == lang.value, orElse: () => langs.first);

  /// Язык для дат и чисел (intl): для таджикского и туркменского — русские названия месяцев.
  static String get dateLocale => const {'ru': 'ru', 'uz': 'uz', 'en': 'en', 'tg': 'ru', 'tk': 'ru'}[lang.value] ?? 'ru';

  static Future<void> init() async {
    try {
      final p = await SharedPreferences.getInstance();
      final saved = p.getString(_prefKey);
      if (saved != null && langs.any((l) => l.code == saved)) {
        lang.value = saved;
        return;
      }
      final sys = ui.PlatformDispatcher.instance.locale.languageCode;
      if (langs.any((l) => l.code == sys)) lang.value = sys;
    } catch (_) {}
  }

  static Future<void> set(String code) async {
    if (!langs.any((l) => l.code == code) || code == lang.value) return;
    lang.value = code;
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(_prefKey, code);
    } catch (_) {}
    _rebuildAll();
  }

  static void _rebuildAll() {
    final root = WidgetsBinding.instance.rootElement;
    if (root == null) return;
    void rb(Element e) {
      e.markNeedsBuild();
      e.visitChildren(rb);
    }
    rb(root);
  }

  static Map<String, String>? _rev;

  /// Исходная (русская) фраза по переводу — для логики, которая сравнивает тексты.
  static String orig(String s) {
    if (lang.value == 'ru') return s;
    final m = agI18nData[lang.value];
    if (m == null) return s;
    _rev ??= {};
    final key = '${lang.value}\u0000$s';
    final hit = _rev![key];
    if (hit != null) return hit;
    for (final e in m.entries) {
      if (e.value == s) {
        _rev![key] = e.key;
        return e.key;
      }
    }
    return s;
  }

  /// Окно выбора языка.
  static Future<void> pick(BuildContext context) async {
    final dark = Theme.of(context).brightness == Brightness.dark;
    await showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheet) {
        final bg = dark ? const Color(0xFF14181E) : Colors.white;
        final ink = dark ? const Color(0xFFF6F7F8) : const Color(0xFF15171C);
        final mut = dark ? const Color(0xFFA3AAB4) : const Color(0xFF69717D);
        final line = dark ? const Color(0xFF262D36) : const Color(0xFFEDEFF2);
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(28), border: Border.all(color: line)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: line, borderRadius: BorderRadius.circular(4)))),
                const SizedBox(height: 14),
                Text(tr('Язык приложения'), style: TextStyle(color: ink, fontSize: 21, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text('Язык · Til · Забон · Dil · Language', style: TextStyle(color: mut, fontSize: 13)),
                const SizedBox(height: 14),
                for (final l in langs)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Material(
                      color: l.code == lang.value ? const Color(0xFFF26200).withValues(alpha: .1) : Colors.transparent,
                      borderRadius: BorderRadius.circular(18),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () {
                          Navigator.of(sheet).pop();
                          set(l.code);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: l.code == lang.value ? const Color(0xFFF26200) : line, width: l.code == lang.value ? 1.6 : 1),
                          ),
                          child: Row(children: [
                            Text(l.flag, style: const TextStyle(fontSize: 26)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(l.name, style: TextStyle(color: ink, fontSize: 16, fontWeight: FontWeight.w800)),
                                Text(l.hint, style: TextStyle(color: mut, fontSize: 12.5)),
                              ]),
                            ),
                            if (l.code == lang.value)
                              Container(
                                width: 26,
                                height: 26,
                                decoration: const BoxDecoration(color: Color(0xFFF26200), shape: BoxShape.circle),
                                child: const Icon(Icons.check_rounded, size: 17, color: Colors.white),
                              ),
                          ]),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Перевод фразы на выбранный язык (если перевода нет — исходный текст).
String tr(String s) {
  final l = AgI18n.lang.value;
  if (l == 'ru') return s;
  return agI18nData[l]?[s] ?? s;
}

/// Перевод фразы с подстановками: trf('Баланс: {0} ₽', [x]).
String trf(String template, List<Object?> args) {
  var s = tr(template);
  for (var i = 0; i < args.length; i++) {
    s = s.replaceAll('{$i}', '${args[i] ?? ''}');
  }
  return s;
}
