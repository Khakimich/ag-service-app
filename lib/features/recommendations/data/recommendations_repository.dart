import '../../../core/api_client.dart';
import '../../../models/recommendation.dart';

class RecommendationsRepository {
  RecommendationsRepository(this._api);

  final ApiClient _api;

  Future<List<Recommendation>> list() async {
    final data = await _api.get('/api/recommendations') as Map<String, dynamic>;

    final raw = data['recommendations'] as List<dynamic>? ?? [];

    return raw
        .map(
          (item) =>
              Recommendation.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList(growable: false);
  }

  Future<Recommendation> setStatus({
    required String id,
    required String status,
  }) async {
    final data =
        await _api.patch('/api/recommendations/$id/status', {'status': status})
            as Map<String, dynamic>;

    final raw = data['recommendation'];

    if (raw is Map) {
      return Recommendation.fromJson(Map<String, dynamic>.from(raw));
    }

    throw StateError('Recommendation was not returned by API');
  }
}
