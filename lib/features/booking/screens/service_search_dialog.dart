import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme.dart';
import '../../../models/service.dart';
import '../data/booking_repository.dart';
import '../../../core/i18n.dart'; // AG_I18N1

/// Поиск услуг по центру экрана: список услуг берётся с сервера.
Future<void> showServiceSearch(BuildContext context) {
  final repository = context.read<BookingRepository>();
  final router = GoRouter.of(context);

  return showGeneralDialog<void>(
    context: context,
    useRootNavigator: true,
    barrierDismissible: true,
    barrierLabel: tr('Закрыть поиск'),
    barrierColor: Colors.black.withValues(alpha: 0.5),
    transitionDuration: const Duration(milliseconds: 240),
    pageBuilder:
        (dialogContext, _, __) =>
            _ServiceSearchDialog(repository: repository, router: router),
    transitionBuilder: (context, animation, _, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.92, end: 1).animate(curved),
          child: child,
        ),
      );
    },
  );
}

String _norm(String value) => value.toLowerCase().replaceAll('ё', tr('е'));

/// Отбрасывает окончание, чтобы «замена» находила «замену», «заменить» и т.д.
String _stem(String token) {
  if (token.length <= 4) return token;
  if (token.length <= 6) return token.substring(0, token.length - 1);
  return token.substring(0, token.length - 2);
}

List<Service> _filterServices(List<Service> all, String query) {
  final tokens =
      _norm(query)
          .split(RegExp(r'\s+'))
          .where((t) => t.isNotEmpty)
          .map(_stem)
          .toList();
  if (tokens.isEmpty) return all;

  final scored = <MapEntry<Service, int>>[];
  for (final service in all) {
    final title = _norm(service.title);
    final description = _norm(service.description ?? '');
    var score = 0;
    var matches = true;
    for (final token in tokens) {
      if (title.startsWith(token)) {
        score += 3;
      } else if (title.contains(token)) {
        score += 2;
      } else if (description.contains(token)) {
        score += 1;
      } else {
        matches = false;
        break;
      }
    }
    if (matches) scored.add(MapEntry(service, score));
  }
  scored.sort((a, b) => b.value.compareTo(a.value));
  return scored.map((e) => e.key).toList();
}

class _ServiceSearchDialog extends StatefulWidget {
  const _ServiceSearchDialog({required this.repository, required this.router});

  final BookingRepository repository;
  final GoRouter router;

  @override
  State<_ServiceSearchDialog> createState() => _ServiceSearchDialogState();
}

class _ServiceSearchDialogState extends State<_ServiceSearchDialog> {
  final TextEditingController _controller = TextEditingController();
  late Future<List<Service>> _future;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _future = widget.repository.listServices();
    _controller.addListener(() {
      if (_controller.text != _query) {
        setState(() => _query = _controller.text);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openAll() {
    final q = _query.trim();
    Navigator.of(context).pop();
    widget.router.go(
      q.isEmpty ? '/services' : '/services?search=${Uri.encodeQueryComponent(q)}',
    );
  }

  void _openService(Service service) {
    Navigator.of(context).pop();
    widget.router.push('/services/${service.id}');
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final media = MediaQuery.of(context);
    final listHeight = (media.size.height - media.viewInsets.bottom) * 0.42;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Material(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(28),
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              tr('Найти услугу'),
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -.4,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close_rounded),
                            color: scheme.onSurfaceVariant,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _controller,
                        autofocus: true,
                        textInputAction: TextInputAction.search,
                        onSubmitted: (_) => _openAll(),
                        decoration: InputDecoration(
                          hintText: tr('Например: замена масла'),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            color: scheme.onSurfaceVariant,
                          ),
                          suffixIcon:
                              _query.isEmpty
                                  ? null
                                  : IconButton(
                                    icon: const Icon(Icons.close_rounded),
                                    onPressed: _controller.clear,
                                  ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ConstrainedBox(
                        constraints: BoxConstraints(maxHeight: listHeight),
                        child: _buildResults(context),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResults(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return FutureBuilder<List<Service>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 110,
            child: Center(child: CircularProgressIndicator(strokeWidth: 3)),
          );
        }

        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  tr('Не удалось загрузить услуги'),
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
                TextButton(
                  onPressed:
                      () => setState(() {
                        _future = widget.repository.listServices();
                      }),
                  child: Text(tr('Повторить')),
                ),
              ],
            ),
          );
        }

        final found = _filterServices(snapshot.data ?? const [], _query);

        if (found.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  tr('Ничего не найдено'),
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  tr('Попробуйте другое слово, например «масло» или «диагностика»'),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          );
        }

        final label =
            _query.trim().isEmpty ? tr('Все услуги') : trf('Найдено: {0}', [found.length]);

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: found.length,
                itemBuilder: (context, index) => _tile(context, found[index]),
              ),
            ),
            if (_query.trim().isNotEmpty)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _openAll,
                  child: Text(tr('Показать в каталоге')),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _tile(BuildContext context, Service service) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _openService(service),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 9),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color:
                    isDark
                        ? BrandColors.orange.withValues(alpha: 0.14)
                        : BrandColors.orangeSoft,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.build_rounded,
                color: BrandColors.orange,
                size: 21,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${service.priceLabel} • ${service.durationLabel}',
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}