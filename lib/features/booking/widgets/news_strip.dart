// AG_FIX1 — лента «Новости и акции» на главном экране: настоящие баннеры из AG Service.
// Нажатие открывает полную новость. Если новостей нет — показывается прежний блок (fallback).
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/api_client.dart';
import '../../../models/ag_news_item.dart';
import '../data/news_repository.dart';
import '../../../core/i18n.dart'; // AG_I18N1

class AgNewsStrip extends StatefulWidget {
  const AgNewsStrip({super.key, required this.fallback});

  final Widget fallback;

  @override
  State<AgNewsStrip> createState() => _AgNewsStripState();
}

class _AgNewsStripState extends State<AgNewsStrip> {
  static const _orange = Color(0xFFFF6A00);
  List<AgNewsItem>? _items;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final list = await NewsRepository(context.read<ApiClient>()).fetchNews();
      if (!mounted) return;
      setState(() => _items = list.take(8).toList());
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    if (_failed || (items != null && items.isEmpty)) return widget.fallback;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: 132,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: items?.length ?? 3,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          if (items == null) {
            return Container(
              width: 264,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                color: isDark ? const Color(0xFF161B22) : const Color(0xFFEFF1F4),
              ),
            );
          }
          final item = items[i];
          return _NewsCard(
            item: item,
            orange: _orange,
            onTap: () => context.push('/news/${item.id}', extra: item),
          );
        },
      ),
    );
  }
}

class _NewsCard extends StatefulWidget {
  const _NewsCard({required this.item, required this.orange, required this.onTap});

  final AgNewsItem item;
  final Color orange;
  final VoidCallback onTap;

  @override
  State<_NewsCard> createState() => _NewsCardState();
}

class _NewsCardState extends State<_NewsCard> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final hasImage = item.imageUrl != null;
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? 0.97 : 1,
        duration: const Duration(milliseconds: 140),
        child: Container(
          width: 264, // баннер 2:1 — рекомендуемый размер 1200×600
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: hasImage
                ? null
                : LinearGradient(
                    colors: [widget.orange, const Color(0xFFFFA24D)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 14, offset: const Offset(0, 6)),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (hasImage)
                CachedNetworkImage(imageUrl: item.imageUrl!, fit: BoxFit.cover),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x00000000), Color(0xB3000000)],
                    stops: [0.35, 1],
                  ),
                ),
              ),
              Positioned(
                left: 12,
                top: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: item.isPromotion ? widget.orange : Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    item.isPromotion ? tr('АКЦИЯ') : tr('НОВОСТЬ'),
                    style: TextStyle(
                      color: item.isPromotion ? Colors.white : widget.orange,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 12,
                right: 12,
                bottom: 10,
                child: Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800, height: 1.2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
