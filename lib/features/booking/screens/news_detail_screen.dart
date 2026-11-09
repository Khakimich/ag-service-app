import 'package:mobile/core/nav.dart'; // AG_FIX3
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../models/ag_news_item.dart';
import '../../../core/i18n.dart'; // AG_I18N1

class NewsDetailScreen extends StatelessWidget {
  const NewsDetailScreen({super.key, required this.item});

  final AgNewsItem item;

  static const orange = Color(0xFFFF6A00);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: const AgBackButton(fallback: '/news'), /* AG_FIX3 */ 
        title: Text(
          item.isPromotion ? tr('Акция') : tr('Новость'),
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: ListView(
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
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).brightness == Brightness.dark
                            ? orange.withValues(alpha: 0.12)
                            : const Color(0xFFFFF1E8),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    item.isPromotion ? tr('АКЦИЯ') : tr('НОВОСТЬ'),
                    style: const TextStyle(
                      color: orange,
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 26,
                    height: 1.15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (item.shortDescription.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    item.shortDescription,
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                if (item.publishedAt != null) ...[
                  Text(
                    '${item.publishedAt!.toLocal().day.toString().padLeft(2, '0')}.${item.publishedAt!.toLocal().month.toString().padLeft(2, '0')}.${item.publishedAt!.toLocal().year}',
                    style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 12),
                ],
                SelectableText(
                  item.body,
                  style: const TextStyle(fontSize: 16, height: 1.55),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
