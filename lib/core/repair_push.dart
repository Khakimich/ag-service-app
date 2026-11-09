import 'dart:async';
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;

import 'api_client.dart';

/// Пуши «Статус ремонта» с job.autogrom.ru.
///
/// Приложение сообщает сайту токен телефона и номера своих записей —
/// когда мастер нажимает «Начать работу» или завершает все работы,
/// сайт присылает пуш. Нажатие на пуш открывает экран «Статус ремонта».
class RepairPush {
  RepairPush._();

  static const String url = String.fromEnvironment(
    'REPAIR_STATUS_URL',
    defaultValue: 'https://job.autogrom.ru/repair.php',
  );

  static ApiClient? _api;
  static GoRouter? _router;
  static final RegExp _uuid = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  /// Вызывается один раз при запуске (main.dart).
  static void attach(ApiClient api) => _api = api;

  static Future<String?> _token() async {
    if (kIsWeb) return null;
    try {
      return await FirebaseMessaging.instance.getToken();
    } catch (_) {
      return null;
    }
  }

  static String get _platform =>
      defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';

  static Future<void> _post(Map<String, dynamic> body) async {
    try {
      await http
          .post(
            Uri.parse(url).replace(queryParameters: {'register': '1'}),
            headers: {'content-type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      debugPrint('[RepairPush] register error: $e');
    }
  }

  /// Привязать этот телефон к записям (номера записей клиента).
  static Future<void> registerIds(Iterable<String> ids) async {
    final list = ids.where(_uuid.hasMatch).toSet().take(30).toList();
    if (list.isEmpty) return;
    final token = await _token();
    if (token == null) return;
    await _post({'token': token, 'platform': _platform, 'bookings': list});
  }

  /// Загрузить свои записи и привязать телефон к актуальным (не старше 2 дней, не отменённым).
  static Future<void> sync() async {
    final api = _api;
    if (api == null || !api.hasToken || kIsWeb) return;
    try {
      final data = await api.get('/api/bookings/mine');
      final raw = (data is Map ? data['bookings'] : null);
      if (raw is! List) return;
      final since = DateTime.now().subtract(const Duration(days: 2));
      final ids = <String>[];
      for (final e in raw) {
        if (e is! Map) continue;
        if ((e['status'] ?? '').toString() == 'cancelled') continue;
        final at = DateTime.tryParse((e['scheduled_at'] ?? '').toString());
        if (at != null && at.isBefore(since)) continue;
        ids.add((e['id'] ?? '').toString());
      }
      await registerIds(ids);
    } catch (e) {
      debugPrint('[RepairPush] sync error: $e');
    }
  }

  /// При выходе из аккаунта — пуши о ремонте на этот телефон больше не слать.
  static Future<void> unregister() async {
    final token = await _token();
    if (token == null) return;
    await _post({'token': token, 'unregister': true});
  }

  /// Нажатие на пуш «Статус ремонта» открывает экран /repair.
  static void listenTaps(GoRouter router) {
    _router = router;
    if (kIsWeb) return;
    try {
      FirebaseMessaging.onMessageOpenedApp.listen(_open);
      FirebaseMessaging.instance.getInitialMessage().then((m) {
        if (m != null) {
          Future.delayed(const Duration(milliseconds: 800), () => _open(m));
        }
      });
    } catch (e) {
      debugPrint('[RepairPush] listen error: $e');
    }
  }

  static void _open(RemoteMessage m) {
    if (m.data['type'] != 'repair_status') return;
    try {
      _router?.go('/repair');
    } catch (_) {}
  }
}
