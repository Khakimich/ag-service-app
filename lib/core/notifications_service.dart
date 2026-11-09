import 'dart:async'; // AG_FIX4
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../features/booking/data/notifications_repository.dart';
import 'repair_push.dart';

// Platform-specific Firebase options
FirebaseOptions get _firebaseOptions {
  if (Platform.isIOS) {
    return const FirebaseOptions(
      apiKey: 'AIzaSyBlhgdETy1osIHPb9bxSR9d3yyzKz2gbx8',
      appId: '1:854397099001:ios:2de5ade5e7afefc854bb28',
      messagingSenderId: '854397099001',
      projectId: 'm-service-6f8d7',
      storageBucket: 'm-service-6f8d7.firebasestorage.app',
      iosBundleId: 'com.avtogrom.mobile',
    );
  }
  return const FirebaseOptions(
    apiKey: 'AIzaSyCy5MG2GLQl3I9M02IV36QN4Kq_wANaeIY',
    appId: '1:900012233834:android:5253549fe6fd66e85ae613',
    messagingSenderId: '900012233834',
    projectId: 'ag-service-afe64',
    storageBucket: 'ag-service-afe64.firebasestorage.app',
  );
}

// Background message handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: _firebaseOptions);
  print('Handling background message: ${message.messageId}');
}

class NotificationsService {
  NotificationsService(this._repo);
  final NotificationsRepository _repo;

  String? _fcmToken;

  Future<void> init() async {
    try {
      // 1. Initialize Firebase Core
      await Firebase.initializeApp(options: _firebaseOptions).timeout(const Duration(seconds: 8)); // AG_FIX4

      // 2. Set background message handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    } catch (e) {
      debugPrint('[Notifications Service] Firebase init failed: $e');
      return;
    }
    // AG_FIX4: всё остальное — в фоне, чтобы запуск приложения никогда не ждал Google-сервисы
    unawaited(_finishInit());
  }

  Future<void> _finishInit() async {
    try {
      // 3. Request permissions (crucial for iOS)
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      print('User granted permission: ${settings.authorizationStatus}');

      // 4. Retrieve FCM token
      _fcmToken = await messaging.getToken().timeout(const Duration(seconds: 20)); // AG_FIX4
      if (_repo.hasToken) unawaited(registerDeviceToken()); // AG_FIX4
      print('[Notifications Service] FCM Token: $_fcmToken');

      // 5. Set up foreground presentation options
      await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // 6. Listen for token refresh
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        registerDeviceToken();
      });

    } catch (e) {
      debugPrint('[Notifications Service] push setup failed: $e'); // AG_FIX4
    }
  }

  // Register token to backend
  Future<void> registerDeviceToken() async {
    if (_fcmToken == null) return;
    RepairPush.sync();
    try {
      final platform = kIsWeb
          ? 'web'
          : Platform.isIOS
              ? 'ios'
              : 'android';

      await _repo.registerToken(_fcmToken!, platform);
      print('[Notifications Service] Token registered successfully on backend.');
    } catch (e) {
      print('[Notifications Service] Failed to register token: $e');
    }
  }

  // Unregister token from backend (on logout)
  Future<void> unregisterDeviceToken() async {
    if (_fcmToken == null) return;
    await RepairPush.unregister();
    try {
      await _repo.unregisterToken(_fcmToken!);
      print('[Notifications Service] Token unregistered successfully from backend.');
    } catch (e) {
      print('[Notifications Service] Failed to unregister token: $e');
    }
  }
}
