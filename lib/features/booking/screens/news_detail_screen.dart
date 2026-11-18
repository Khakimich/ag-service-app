import 'package:mobile/core/nav.dart'; // AG_FIX3
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../models/ag_news_item.dart';
import '../../../core/i18n.dart'; // AG_I18N1

/// AG_NEWSDET1 — страница акции/новости как в образце:
/// цветная шапка (оранжевая — акция, синяя — новость) с крупным заголовком,
/// подзаголовком, сроком «до 30.11.26» и картинкой-предметом справа снизу;
/// большая кнопка «Записаться» и текст ниже.
class NewsDetailScreen extends StatelessWidget {
  const NewsDetailScreen({super.key, required this.item});

  final AgNewsItem item;

  static const orange = Color(0xFFF26200);

  String _d(DateTime d) {
    final l = d.toLocal();
    return '${l.day.toString().padLeft(2, '0')}.${l.month.toString().padLeft(2, '0')}.${(l.year % 100).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final promo = item.isPromotion;
    final colors = promo
        ? const [Color(0xFFFF7A1A), Color(0xFFF05A00)]
        : const [Color(0xFF3B7BFF), Color(0xFF1F54D6)];
    final top = MediaQuery.paddingOf(context).top;
    final w = MediaQuery.sizeOf(context).width;
    final heroH = (w * .74).clamp(280.0, 420.0) + top;
    final body = item.body.trim();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: CustomScrollView(slivers: [
          SliverToBoxAdapter(
            child: Container(
              height: heroH,
              decoration: BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: colors),
              ),
              child: Stack(children: [
                // декоративный круг
                Positioned(
                  right: -60, top: top - 40,
                  child: Container(width: 220, height: 220,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: .08))),
                ),
                if (item.imageUrl != null)
                  Positioned(
                    right: 0, bottom: 0,
                    width: w * .66,
                    height: heroH * .62,
                    child: CachedNetworkImage(
                      imageUrl: item.imageUrl!,
                      fit: BoxFit.contain,
                      alignment: Alignment.bottomRight,
                      errorWidget: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                Positioned(
                  left: 8, top: top + 6,
                  child: IconButton(
                    onPressed: () => context.canPop() ? context.pop() : context.go('/news'),
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 26),
                  ),
                ),
                Positioned(
                  left: 22, right: 22, top: top + 70,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: .2), borderRadius: BorderRadius.circular(9)),
                      child: Text(promo ? tr('АКЦИЯ') : tr('НОВОСТЬ'),
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: .6)),
                    ),
                    const SizedBox(height: 12),
                    ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: w * .72),
                      child: Text(item.title,
                          maxLines: 4, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontSize: 28, height: 1.12, fontWeight: FontWeight.w900, letterSpacing: -.5,
                              shadows: [Shadow(color: Color(0x33000000), blurRadius: 8)])),
                    ),
                    // AG_NEWSDET2: описание в шапке убрано — оно перекрывало картинку
                    if (item.endsAt != null) ...[
                      const SizedBox(height: 12),
                      Text('${tr('до')} ${_d(item.endsAt!)}',
                          style: TextStyle(color: Colors.white.withValues(alpha: .75), fontSize: 13.5, fontWeight: FontWeight.w800)),
                    ],
                  ]),
                ),
              ]),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
              child: SizedBox(
                height: 56,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: const LinearGradient(colors: [Color(0xFFFF8A3D), orange]),
                    boxShadow: [BoxShadow(color: orange.withValues(alpha: .3), blurRadius: 16, offset: const Offset(0, 6))],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () => context.push('/services'),
                      child: Center(
                        child: Text(promo ? tr('Записаться по акции 🚘') : tr('Записаться в сервис 🚘'),
                            style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900)),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(22, 22, 22, 40 + MediaQuery.paddingOf(context).bottom + 90),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (body.isNotEmpty)
                  SelectableText(body, style: TextStyle(fontSize: 16, height: 1.55, color: cs.onSurface)),
                if (item.endsAt != null) ...[
                  const SizedBox(height: 18),
                  Text('${promo ? tr('Акция действует до') : tr('Актуально до')} ${_d(item.endsAt!)}',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: cs.onSurface)),
                ],
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}
