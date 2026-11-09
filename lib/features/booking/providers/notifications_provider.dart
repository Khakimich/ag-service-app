import 'package:flutter/widgets.dart' show WidgetsBinding, AppLifecycleState;
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../models/notification.dart';
import '../data/notifications_repository.dart';

class NotificationsProvider extends ChangeNotifier {
  NotificationsProvider(this._repo) {
    _startPolling();
  }
  final NotificationsRepository _repo;

  List<AppNotification> _notifications = [];
  bool _loading = false;
  String? _error;
  Timer? _timer;

  List<AppNotification> get notifications => _notifications;
  bool get loading => _loading;
  String? get error => _error;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  void _startPolling() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 15), (t) async {
      if (_repo.hasToken && WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) { // AG_FIX3
        try {
          final list = await _repo.listNotifications();
          _notifications = list;
          notifyListeners();
        } catch (_) {}
      }
    });
  }

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _notifications = await _repo.listNotifications();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      await _repo.markAsRead(id);
      final idx = _notifications.indexWhere((n) => n.id == id);
      if (idx != -1) {
        final n = _notifications[idx];
        _notifications[idx] = AppNotification(
          id: n.id,
          title: n.title,
          body: n.body,
          type: n.type,
          relatedId: n.relatedId,
          isRead: true,
          createdAt: n.createdAt,
        );
        notifyListeners();
      }
    } catch (_) {
      // Fail silently
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _repo.markAllAsRead();
      _notifications = _notifications.map((n) {
        return AppNotification(
          id: n.id,
          title: n.title,
          body: n.body,
          type: n.type,
          relatedId: n.relatedId,
          isRead: true,
          createdAt: n.createdAt,
        );
      }).toList();
      notifyListeners();
    } catch (_) {
      // Fail silently
    }
  }

  void addNotification(AppNotification n) {
    _notifications.insert(0, n);
    notifyListeners();
  }

  void clear() {
    _notifications = [];
    _loading = false;
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
