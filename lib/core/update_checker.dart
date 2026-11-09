// AG_UPD1 — проверка новой версии приложения и окно «Вышло обновление».
// Данные берутся со страницы скачивания: https://autogrom.ru/app/?json=1
// (номер версии, номер сборки и список «Что нового» меняются там, в начале index.php).
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'theme.dart';
import '../core/i18n.dart'; // AG_I18N1

class AgUpdateChecker {
  AgUpdateChecker._();

  static const String feedUrl = 'https://autogrom.ru/app/?json=1';
  static bool _checked = false;

  /// Вызывать на главном экране. Проверяет один раз за запуск приложения.
  static Future<void> check(BuildContext context) async {
    if (_checked || kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    _checked = true;
    await _run(context, manual: false);
  }

  /// AG_FIX1: кнопка «Проверить обновления» в настройках.
  static Future<void> checkManually(BuildContext context) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (kIsWeb) {
      messenger?.showSnackBar(SnackBar(content: Text(tr('Веб-версия обновляется сама — просто обновите страницу'))));
      return;
    }
    messenger?.showSnackBar(SnackBar(content: Text(tr('Проверяем обновления…')), duration: Duration(seconds: 2)));
    await _run(context, manual: true);
  }

  static Future<void> _run(BuildContext context, {required bool manual}) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    try {
      final info = await PackageInfo.fromPlatform();
      final current = int.tryParse(info.buildNumber) ?? 0;

      final res = await http
          .get(Uri.parse(feedUrl), headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) {
        if (manual) messenger?.showSnackBar(SnackBar(content: Text(tr('Не удалось проверить обновления. Попробуйте позже'))));
        return;
      }

      final data = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      final latest = int.tryParse('${data['build']}') ?? 0;
      if (latest <= current) {
        if (manual) {
          messenger?.hideCurrentSnackBar();
          messenger?.showSnackBar(SnackBar(content: Text(trf('У вас последняя версия {0} ✅', [info.version]))));
        }
        return;
      }
      messenger?.hideCurrentSnackBar();

      final fromPlay = (info.installerStore ?? '') == 'com.android.vending';
      final url = (fromPlay ? data['play_url'] : data['apk_url'])?.toString() ?? '';
      if (url.isEmpty || !context.mounted) return;

      final changes = (data['changes'] as List? ?? [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        isDismissible: data['force'] != true,
        enableDrag: data['force'] != true,
        backgroundColor: Colors.transparent,
        builder: (_) => _UpdateSheet(
          version: '${data['version'] ?? ''}',
          size: '${data['size'] ?? ''}',
          currentVersion: info.version,
          changes: changes,
          url: url,
          fromPlay: fromPlay,
          force: data['force'] == true,
        ),
      );
    } catch (e) {
      debugPrint('[Update] check skipped: $e');
      if (manual) {
        messenger?.hideCurrentSnackBar();
        messenger?.showSnackBar(SnackBar(content: Text(tr('Нет связи. Проверьте интернет и попробуйте ещё раз'))));
      }
    }
  }
}

class _UpdateSheet extends StatefulWidget {
  const _UpdateSheet({
    required this.version,
    required this.size,
    required this.currentVersion,
    required this.changes,
    required this.url,
    required this.fromPlay,
    required this.force,
  });

  final String version;
  final String size;
  final String currentVersion;
  final List<Map<String, dynamic>> changes;
  final String url;
  final bool fromPlay;
  final bool force;

  @override
  State<_UpdateSheet> createState() => _UpdateSheetState();
}

class _UpdateSheetState extends State<_UpdateSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();
  bool _opening = false;

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  Future<void> _update() async {
    setState(() => _opening = true);
    final ok = await launchUrl(
      Uri.parse(widget.url),
      mode: LaunchMode.externalApplication,
    );
    if (!mounted) return;
    setState(() => _opening = false);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('Не удалось открыть загрузку. Откройте autogrom.ru/app'))),
      );
      return;
    }
    if (!widget.force) Navigator.of(context).pop();
  }

  ({Color color, IconData icon, String label}) _type(String t) {
    switch (t) {
      case 'better':
        return (color: const Color(0xFF2F6BFF), icon: Icons.bolt_rounded, label: tr('Улучшено'));
      case 'fix':
        return (color: const Color(0xFF17A864), icon: Icons.build_rounded, label: tr('Исправлено'));
      default:
        return (color: BrandColors.orange, icon: Icons.auto_awesome_rounded, label: tr('Новое'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    Widget fade(int i, Widget child) {
      final start = (0.15 + i * 0.08).clamp(0.0, 0.8);
      final a = CurvedAnimation(
        parent: _anim,
        curve: Interval(start, (start + 0.35).clamp(0.0, 1.0), curve: Curves.easeOutCubic),
      );
      return FadeTransition(
        opacity: a,
        child: SlideTransition(
          position: Tween(begin: const Offset(0, 0.25), end: Offset.zero).animate(a),
          child: child,
        ),
      );
    }

    return PopScope(
      canPop: !widget.force,
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF10151B) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.4)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colors.onSurfaceVariant.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(9),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                ScaleTransition(
                  scale: CurvedAnimation(parent: _anim, curve: const Interval(0, 0.6, curve: Curves.easeOutBack)),
                  child: Center(
                    child: Container(
                      width: 78,
                      height: 78,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF6B00), Color(0xFFFFA24D)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: BrandColors.orange.withValues(alpha: 0.35),
                            blurRadius: 26,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.system_update_rounded, color: Colors.white, size: 40),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                fade(0, Text(
                  tr('Вышло обновление'),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                )),
                const SizedBox(height: 6),
                fade(1, Text(
                  trf('Версия {0}{1}  ·  у вас {2}', [widget.version, widget.size.isNotEmpty ? ' · ${widget.size}' : '', widget.currentVersion]),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13),
                )),
                const SizedBox(height: 20),
                if (widget.changes.isNotEmpty)
                  fade(2, Text(tr('Что нового'), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800))),
                const SizedBox(height: 10),
                for (var i = 0; i < widget.changes.length; i++)
                  fade(3 + i, Builder(builder: (_) {
                    final c = widget.changes[i];
                    final t = _type('${c['type']}');
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: t.color.withValues(alpha: 0.13),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(t.icon, color: t.color, size: 21),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(
                                  spacing: 8,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Text('${c['title'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: t.color.withValues(alpha: 0.13),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(t.label, style: TextStyle(color: t.color, fontSize: 10.5, fontWeight: FontWeight.w800)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text('${c['text'] ?? ''}', style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13, height: 1.35)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  })),
                const SizedBox(height: 14),
                fade(3 + widget.changes.length, Row(
                  children: [
                    if (!widget.force) ...[
                      Expanded(
                        child: SizedBox(
                          height: 54,
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text(tr('Позже')),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        height: 54,
                        child: ElevatedButton.icon(
                          onPressed: _opening ? null : _update,
                          icon: _opening
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white))
                              : Icon(widget.fromPlay ? Icons.shop_rounded : Icons.download_rounded),
                          label: Text(widget.fromPlay ? tr('Обновить в Google Play') : tr('Обновить')),
                        ),
                      ),
                    ),
                  ],
                )),
                if (!widget.fromPlay) ...[
                  const SizedBox(height: 10),
                  Text(
                    tr('Файл скачается — откройте его и нажмите «Установить». Ваши данные сохранятся.'),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
