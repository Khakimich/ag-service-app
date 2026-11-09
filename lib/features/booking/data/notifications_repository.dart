import '../../../core/api_client.dart';
import '../../../models/notification.dart';

class NotificationsRepository {
  NotificationsRepository(this._api);
  final ApiClient _api;

  bool get hasToken => _api.hasToken;

  Future<List<AppNotification>> listNotifications() async {
    final data = await _api.get('/api/notifications') as Map<String, dynamic>;
    final raw = data['notifications'] as List<dynamic>;
    return raw
        .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<void> markAsRead(String id) async {
    await _api.patch('/api/notifications/$id/read', {});
  }

  Future<void> markAllAsRead() async {
    await _api.post('/api/notifications/read-all', {});
  }

  Future<void> registerToken(String token, String platform) async {
    await _api.post('/api/notifications/tokens', {
      'token': token,
      'platform': platform,
    });
  }

  Future<void> unregisterToken(String token) async {
    await _api.delete('/api/notifications/tokens/$token');
  }
}
