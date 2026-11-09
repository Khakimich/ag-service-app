import '../../../core/api_client.dart';
import '../../../models/ag_news_item.dart';

class NewsRepository {
  NewsRepository(this._api);

  final ApiClient _api;

  Future<List<AgNewsItem>> fetchNews() async {
    final data = await _api.get('/api/news')
        as Map<String, dynamic>;

    final list = data['news'] as List<dynamic>? ?? const [];

    return list
        .map((e) => AgNewsItem.fromJson(
              e as Map<String, dynamic>,
            ))
        .toList();
  }
}