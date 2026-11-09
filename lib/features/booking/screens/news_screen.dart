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
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final item = items[index];

                return InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => context.push('/news/${item.id}', extra: item),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (item.imageUrl != null)
                          AspectRatio( // AG_FIX1: баннер 2:1 (1200×600)
                            aspectRatio: 2,
                            child: CachedNetworkImage(
                              imageUrl: item.imageUrl!,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? orange.withValues(alpha: 0.12)
                                          : const Color(0xFFFFF1E8),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  item.isPromotion ? tr('АКЦИЯ') : tr('НОВОСТЬ'),
                                  style: const TextStyle(
                                    color: orange,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                item.title,
                                style: const TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              if (item.shortDescription.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  item.shortDescription,
                                  style: TextStyle(
                                    color:
                                        Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                    fontSize: 13,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
