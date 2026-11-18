import 'package:mobile/core/nav.dart'; // AG_FIX3
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/api_client.dart';
import '../../../models/ag_news_item.dart';
import '../data/news_repository.dart';
import '../../../core/i18n.dart'; // AG_I18N1

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  static const orange = Color(0xFFFF6A00);

  late Future<List<AgNewsItem>> _future;
  int _filter = 0; // AG_NEWSLIST1

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = NewsRepository(context.read<ApiClient>()).fetchNews();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: const AgBackButton(fallback: '/'), /* AG_FIX3 */ 
        title: Text(
          tr('Акции и новости'),
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: FutureBuilder<List<AgNewsItem>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: orange),
            );
          }

          if (snapshot.hasError) {
            return Center(child: Text(tr('Не удалось загрузить новости')));
          }

          final items = snapshot.data ?? const [];

          if (items.isEmpty) {
            return Center(child: Text(tr('Пока нет акций и новостей')));
          }

          return RefreshIndicator(
            color: orange,
            onRefresh: () async {
              setState(_load);
              await _future;
            },
            // AG_NEWSLIST1: цветные карточки как страница акции + фильтр Все/Акции/Новости
            child: Builder(builder: (context) {
              final list = _filter == 1
                  ? items.where((e) => e.isPromotion).toList()
                  : _filter == 2
                      ? items.where((e) => !e.isPromotion).toList()
                      : items;
              final w = MediaQuery.sizeOf(context).width;
              final cols = w >= 900 ? 3 : w >= 600 ? 2 : 1;
              return CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                      child: Row(children: [
                        for (final (i, t) in [(0, tr('Все')), (1, tr('Акции')), (2, tr('Новости'))])
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text('$t · ${i == 0 ? items.length : i == 1 ? items.where((e) => e.isPromotion).length : items.where((e) => !e.isPromotion).length}'),
                              selected: _filter == i,
                              showCheckmark: false,
                              selectedColor: orange,
                              labelStyle: TextStyle(fontWeight: FontWeight.w800, color: _filter == i ? Colors.white : null),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              onSelected: (_) => setState(() => _filter = i),
                            ),
                          ),
                      ]),
                    ),
                  ),
                  if (list.isEmpty)
                    SliverFillRemaining(hasScrollBody: false, child: Center(child: Text(tr('Пока пусто'))))
                  else
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(16, 0, 16, 24 + MediaQuery.paddingOf(context).bottom + 80),
                      sliver: SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: cols, mainAxisSpacing: 14, crossAxisSpacing: 14, mainAxisExtent: 176,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _NewsCard(item: list[index]),
                          childCount: list.length,
                        ),
                      ),
                    ),
                ],
              );
            }),
          );
        },
      ),
    );
  }
}


/* AG_NEWSLIST1: карточка — оранжевая (акция) / синяя (новость), заголовок слева, предмет справа снизу */
class _NewsCard extends StatelessWidget {
  const _NewsCard({required this.item});
  final AgNewsItem item;

  @override
  Widget build(BuildContext context) {
    final colors = item.isPromotion
        ? const [Color(0xFFFF7A1A), Color(0xFFF05A00)]
        : const [Color(0xFF3B7BFF), Color(0xFF1F54D6)];
    final e = item.endsAt?.toLocal();
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => context.push('/news/${item.id}', extra: item),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: colors),
            boxShadow: [BoxShadow(color: colors[1].withValues(alpha: .25), blurRadius: 16, offset: const Offset(0, 6))],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: LayoutBuilder(builder: (context, c) {
              return Stack(children: [
                Positioned(
                  right: -40, top: -40,
                  child: Container(width: 150, height: 150,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: .08))),
                ),
                if (item.imageUrl != null)
                  Positioned(
                    right: 0, bottom: 0,
                    width: c.maxWidth * .5,
                    height: c.maxHeight * .86,
                    child: CachedNetworkImage(
                      imageUrl: item.imageUrl!,
                      fit: BoxFit.contain,
                      alignment: Alignment.bottomRight,
                      errorWidget: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                Positioned(
                  left: 16, top: 14, bottom: 14,
                  width: c.maxWidth * (item.imageUrl != null ? .54 : .9),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: .2), borderRadius: BorderRadius.circular(8)),
                      child: Text(item.isPromotion ? tr('АКЦИЯ') : tr('НОВОСТЬ'),
                          style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w900, letterSpacing: .5)),
                    ),
                    const SizedBox(height: 9),
                    Text(item.title, maxLines: 4, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontSize: 18, height: 1.15, fontWeight: FontWeight.w900, letterSpacing: -.3)),
                    const Spacer(),
                    Row(children: [
                      if (e != null)
                        Text('${tr('до')} ${e.day.toString().padLeft(2, '0')}.${e.month.toString().padLeft(2, '0')}.${(e.year % 100).toString().padLeft(2, '0')}',
                            style: TextStyle(color: Colors.white.withValues(alpha: .8), fontSize: 12.5, fontWeight: FontWeight.w800)),
                      if (e != null) const SizedBox(width: 8),
                      Container(
                        width: 28, height: 28,
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: .22), shape: BoxShape.circle),
                        child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 17),
                      ),
                    ]),
                  ]),
                ),
              ]);
            }),
          ),
        ),
      ),
    );
  }
}
