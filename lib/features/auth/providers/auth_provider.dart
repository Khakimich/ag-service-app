import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show SnackBar, Text; // AG_FIX5
import '../../../core/nav.dart' show agMessengerKey; // AG_FIX5
import 'package:play_install_referrer/play_install_referrer.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/api_client.dart';
import '../../../core/notifications_service.dart';
import '../../../models/user.dart';
import '../data/auth_repository.dart';
import '../../../core/i18n.dart'; // AG_I18N1

class AuthProvider extends ChangeNotifier {
  AuthProvider(this._repo, this._api, this._notificationsService) {
    _api.onAuthError = _agOnAuthError; // AG_FIX5
  }

  // AG_FIX5 — аккаунт удалён/заблокирован или вход устарел: выходим и объясняем почему
  bool _agForcing = false;
  void _agOnAuthError(int status, String message) {
    if (_agForcing || _user == null) return;
    _agForcing = true;
    () async {
      try {
        final prefs = await SharedPreferences.getInstance();
        _api.clearToken();
        await prefs.remove('auth_token');
        await prefs.remove('auth_user');
        _user = null;
        notifyListeners();
        agMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text(status == 401 ? tr('Вход устарел — войдите снова') : message),
            duration: const Duration(seconds: 7),
          ),
        );
      } catch (_) {
      } finally {
        _agForcing = false;
      }
    }();
  }

  final AuthRepository _repo;
  final ApiClient _api;
  final NotificationsService _notificationsService;

  User? _user;
  bool _loading = true;

  String? _referralCode;

  User? get user => _user;

  bool get isLoggedIn => _user != null;

  bool get loading => _loading;

  String? get referralCode => _referralCode;

  // ============================================================
  // ИНИЦИАЛИЗАЦИЯ
  // ============================================================

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();

    /*
     * Сначала пытаемся получить ранее
     * сохранённый referral-код.
     */
    _referralCode = prefs.getString('referral_code');

    /*
     * Если кода ещё нет,
     * пытаемся получить его из Google Play.
     */
    if (_referralCode == null || _referralCode!.isEmpty) {
      await _loadInstallReferrer(prefs);
    }

    /*
     * Восстанавливаем авторизацию.
     */
    final token = prefs.getString('auth_token');

    final userJson = prefs.getString('auth_user');

    if (token != null && userJson != null) {
      try {
        _user = User.fromJson(jsonDecode(userJson) as Map<String, dynamic>);

        _api.setToken(token);
        _api.get('/api/auth/me').catchError((_) => null); // AG_FIX5: проверить, что аккаунт ещё жив

        /*
         * Регистрируем push-token.
         * Не блокируем запуск приложения.
         */
        try {
          _notificationsService.registerDeviceToken().catchError((_) {}); // AG_FIX4: не ждём сеть при запуске
        } catch (e) {
          debugPrint('[Notifications] Register token error: $e');
        }
      } catch (e) {
        debugPrint('[Auth] Restore session error: $e');

        await _clearSession(prefs);
      }
    }

    _loading = false;

    notifyListeners();
  }

  // ============================================================
  // GOOGLE PLAY INSTALL REFERRER
  // ============================================================

  Future<void> _loadInstallReferrer(SharedPreferences prefs) async {
    try {
      final details = await PlayInstallReferrer.installReferrer.timeout(const Duration(seconds: 3)); // AG_FIX4

      /*
       * installReferrer имеет тип String?,
       * поэтому обязательно используем
       * ?.trim() ?? ''
       */
      final rawReferrer = details.installReferrer?.trim() ?? '';

      debugPrint('[Referral] Raw install referrer: $rawReferrer');

      if (rawReferrer.isEmpty) {
        return;
      }

      String? referralCode;

      /*
       * ----------------------------------------------------------
       * Вариант №1:
       *
       * Google Play вернул напрямую:
       *
       * ag0001
       * ----------------------------------------------------------
       */
      final directMatch = RegExp(
        r'^ag[0-9]{2,10}$',
        caseSensitive: false,
      ).firstMatch(rawReferrer);

      if (directMatch != null) {
        referralCode = directMatch.group(0);
      }

      /*
       * ----------------------------------------------------------
       * Вариант №2:
       *
       * ref=ag0001
       *
       * referral=ag0001
       *
       * code=ag0001
       * ----------------------------------------------------------
       */
      if (referralCode == null) {
        try {
          final params = Uri.splitQueryString(rawReferrer);

          final possibleCode =
              params['ref'] ?? params['referral'] ?? params['code'];

          if (possibleCode != null &&
              RegExp(
                r'^ag[0-9]{2,10}$',
                caseSensitive: false,
              ).hasMatch(possibleCode)) {
            referralCode = possibleCode;
          }
        } catch (e) {
          debugPrint('[Referral] Query parse error: $e');
        }
      }

      /*
       * ----------------------------------------------------------
       * Вариант №3:
       *
       * referrer=ag0001
       *
       * На случай, если Google Play вернёт
       * строку в таком формате.
       * ----------------------------------------------------------
       */
      if (referralCode == null) {
        final match = RegExp(
          r'(?:^|[?&])referrer=(ag[0-9]{2,10})(?:&|$)',
          caseSensitive: false,
        ).firstMatch(rawReferrer);

        if (match != null) {
          referralCode = match.group(1);
        }
      }

      /*
       * ----------------------------------------------------------
       * Если referral-код не найден.
       * ----------------------------------------------------------
       */
      if (referralCode == null || referralCode.isEmpty) {
        debugPrint('[Referral] Referral code not found.');

        return;
      }

      referralCode = referralCode.toLowerCase();

      /*
       * Дополнительная проверка формата.
       */
      final valid = RegExp(r'^ag[0-9]{2,10}$').hasMatch(referralCode);

      if (!valid) {
        debugPrint('[Referral] Invalid referral code: $referralCode');

        return;
      }

      /*
       * Сохраняем код локально.
       *
       * Он будет храниться до успешной
       * регистрации пользователя.
       */
      _referralCode = referralCode;

      await prefs.setString('referral_code', referralCode);

      debugPrint('[Referral] Saved referral code: $referralCode');
    } catch (e) {
      /*
       * Это не критическая ошибка.
       *
       * Например, если приложение
       * установлено вручную через APK,
       * Google Play Install Referrer
       * может быть недоступен.
       */
      debugPrint('[Referral] Install Referrer unavailable: $e');
    }
  }

  // ============================================================
  // LOGIN
  // ============================================================

  Future<void> login(String identifier, String password) async {
    final result = await _repo.login(
      identifier: identifier,
      password: password,
    );

    await _saveSession(result);
  }

  // ============================================================
  // REGISTER
  // ============================================================

  Future<void> register(
    String name,
    String email,
    String password, {
    String? phone,
    String? code,
    String? requestId,
    String? linkRequestId,
    // AG_REFUI1: null — взять сохранённый код (Google Play), '' — без кода, иначе — введённый код
    String? referral,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    /*
     * Получаем referral-код.
     *
     * Сначала из памяти Provider,
     * потом из SharedPreferences.
     */
    final savedReferral = referral != null
        ? (referral.trim().isEmpty ? null : referral.trim().toLowerCase())
        : (_referralCode ?? prefs.getString('referral_code'));

    debugPrint('[Referral] Register with code: $savedReferral');

    final result = await _repo.register(
      name: name,
      email: email,
      password: password,
      phone: phone,
      code: code,
      requestId: requestId,
      linkRequestId: linkRequestId,
      referredBy: savedReferral,
    );

    /*
     * Сначала сохраняем успешную сессию.
     */
    await _saveSession(result);

    /*
     * Referral-код удаляем только
     * ПОСЛЕ успешной регистрации.
     *
     * Если регистрация завершится ошибкой,
     * код останется и не потеряется.
     */
    if (savedReferral != null && savedReferral.isNotEmpty) {
      await prefs.remove('referral_code');

      _referralCode = null;

      debugPrint('[Referral] Referral code cleared after registration.');
    }
  }

  // ============================================================
  // SEND OTP
  // ============================================================

  Future<void> sendOtp(String phone) async {
    await _repo.sendOtp(phone);
  }

  // ============================================================
  // VERIFY PHONE
  // ============================================================

  Future<void> verifyPhone(String phone, String code) async {
    final result = await _repo.verifyPhone(phone, code);

    await _saveSession(result);
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  // ============================================================
  // PROFILE
  // ============================================================

  Future<void> updateProfile({required String name, String? birthDate}) async {
    final result = await _repo.updateProfile(name: name, birthDate: birthDate);

    await _saveSession(result);
  }

  Future<void> uploadAvatar({
    required String imageBase64,
    required String fileName,
  }) async {
    final result = await _repo.uploadAvatar(
      imageBase64: imageBase64,
      fileName: fileName,
    );

    await _saveSession(result);
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _repo.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();

    await _clearSession(prefs);
  }

  // ============================================================
  // SAVE SESSION
  // ============================================================

  Future<void> _saveSession(AuthResult result) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('auth_token', result.token);

    await prefs.setString('auth_user', jsonEncode(result.user.toJson()));

    _api.setToken(result.token);

    _user = result.user;

    notifyListeners();

    try {
      await _notificationsService.registerDeviceToken();
    } catch (e) {
      debugPrint('[Notifications] Register token error: $e');
    }
  }

  // ============================================================
  // CLEAR SESSION
  // ============================================================

  Future<void> _clearSession(SharedPreferences prefs) async {
    try {
      await _notificationsService.unregisterDeviceToken();
    } catch (e) {
      debugPrint('[Notifications] Unregister token error: $e');
    }

    await prefs.remove('auth_token');

    await prefs.remove('auth_user');

    /*
     * referral_code здесь специально
     * НЕ удаляем.
     *
     * Если человек ещё не зарегистрировался,
     * приглашение должно сохраниться.
     */

    _api.clearToken();

    _user = null;

    notifyListeners();
  }

  // ============================================================
  // MAX DIRECT REGISTRATION
  // ============================================================

  Future<Map<String, dynamic>> startMaxRegistration() async {
    return _repo.startMaxRegistration();
  }

  Future<Map<String, dynamic>> checkMaxRegistration({
    required String linkRequestId,
    required String clientSecret,
  }) async {
    return _repo.checkMaxRegistration(
      linkRequestId: linkRequestId,
      clientSecret: clientSecret,
    );
  }

  Future<void> completeMaxRegistration({
    required String linkRequestId,
    required String clientSecret,
    required String name,
    required String email,
    required String password,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final savedReferral = _referralCode ?? prefs.getString('referral_code');

    final result = await _repo.completeMaxRegistration(
      linkRequestId: linkRequestId,
      clientSecret: clientSecret,
      name: name,
      email: email,
      password: password,
      referredBy: savedReferral,
    );

    await _saveSession(result);

    if (savedReferral != null && savedReferral.isNotEmpty) {
      await prefs.remove('referral_code');
      _referralCode = null;
    }
  }

  // ============================================================
  // MAX REGISTRATION PHONE VERIFICATION
  // ============================================================

  Future<Map<String, dynamic>> sendMaxRegistrationPhone({
    required String linkRequestId,
    required String clientSecret,
    required String phone,
    required String channel,
  }) async {
    return _repo.sendMaxRegistrationPhone(
      linkRequestId: linkRequestId,
      clientSecret: clientSecret,
      phone: phone,
      channel: channel,
    );
  }

  Future<Map<String, dynamic>> verifyMaxRegistrationPhone({
    required String linkRequestId,
    required String clientSecret,
    required String phone,
    required String otpRequestId,
    required String code,
  }) async {
    return _repo.verifyMaxRegistrationPhone(
      linkRequestId: linkRequestId,
      clientSecret: clientSecret,
      phone: phone,
      otpRequestId: otpRequestId,
      code: code,
    );
  }
  // TELEGRAM AND MAX VERIFICATION

  Future<Map<String, dynamic>> sendPhoneCode(
    String phone,
    String channel,
  ) async {
    return await _repo.sendPhoneCode(phone, channel);
  }

  Future<Map<String, dynamic>> confirmPhoneCode(
    String phone,
    String requestId,
    String code,
  ) async {
    return await _repo.confirmPhoneCode(phone, requestId, code);
  }

  Future<Map<String, dynamic>> startMaxPhoneVerification(String phone) async {
    return await _repo.startMaxPhoneVerification(phone);
  }

  Future<Map<String, dynamic>> checkMaxPhoneVerification(
    String phone,
    String linkRequestId,
  ) async {
    return await _repo.checkMaxPhoneVerification(phone, linkRequestId);
  }

  Future<Map<String, dynamic>> createMaxLink(
    String phone,
    String requestId,
  ) async {
    return await _repo.createMaxLink(phone, requestId);
  }

  Future<Map<String, dynamic>> checkMaxLink(
    String linkRequestId,
    String requestId,
  ) async {
    return await _repo.checkMaxLink(linkRequestId, requestId);
  }
}
