import '../../../core/api_client.dart';
import '../../../models/user.dart';

class AuthResult {
  AuthResult({required this.user, required this.token});

  final User user;
  final String token;

  factory AuthResult.fromJson(Map<String, dynamic> json) {
    return AuthResult(
      user: User.fromJson(json['user'] as Map<String, dynamic>),
      token: json['token'] as String,
    );
  }
}

class AuthRepository {
  AuthRepository(this._api);

  final ApiClient _api;

  // ============================================================
  // РЕГИСТРАЦИЯ
  // ============================================================

  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
    String? phone,
    String? code,
    String? requestId,
    String? linkRequestId,

    // Реферальный код, например ag0001
    String? referredBy,
  }) async {
    final body = <String, dynamic>{
      'name': name.trim(),
      'email': email.trim().toLowerCase(),
      'password': password,

      if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),

      if (code != null && code.trim().isNotEmpty) 'code': code.trim(),

      if (requestId != null && requestId.isNotEmpty) 'request_id': requestId,

      if (linkRequestId != null && linkRequestId.isNotEmpty)
        'link_request_id': linkRequestId,

      // Отправляем реферальный код серверу.
      if (referredBy != null && referredBy.trim().isNotEmpty)
        'referred_by': referredBy.trim().toLowerCase(),
    };

    final data =
        await _api.post('/api/auth/register', body) as Map<String, dynamic>;

    return AuthResult.fromJson(data);
  }

  // ============================================================
  // ВХОД
  // ============================================================

  Future<AuthResult> login({
    required String identifier,
    required String password,
  }) async {
    final data =
        await _api.post('/api/auth/login', {
              'identifier': identifier.trim(),
              'password': password,
            })
            as Map<String, dynamic>;

    return AuthResult.fromJson(data);
  }

  // ============================================================
  // ОТПРАВКА SMS-КОДА
  // ============================================================

  Future<void> sendOtp(String phone) async {
    await _api.post('/api/auth/otp/send', {'phone': phone.trim()});
  }

  // ============================================================
  // ПОДТВЕРЖДЕНИЕ ТЕЛЕФОНА
  // ============================================================

  Future<AuthResult> verifyPhone(String phone, String code) async {
    final data =
        await _api.post('/api/auth/verify-phone', {
              'phone': phone.trim(),
              'code': code.trim(),
            })
            as Map<String, dynamic>;

    return AuthResult.fromJson(data);
  }

  Future<Map<String, dynamic>> sendPhoneCode(
    String phone,
    String channel,
  ) async {
    final data = await _api.post('/api/auth/phone/send', {
      'phone': phone.trim(),
      'channel': channel,
    });

    return Map<String, dynamic>.from(data as Map);
  }

  // Проверить шестизначный код.
  Future<Map<String, dynamic>> confirmPhoneCode(
    String phone,
    String requestId,
    String code,
  ) async {
    final data = await _api.post('/api/auth/phone/verify', {
      'phone': phone.trim(),
      'request_id': requestId,
      'code': code.trim(),
    });

    return Map<String, dynamic>.from(data as Map);
  }

  // Создать ссылку подтверждения MAX.
  Future<Map<String, dynamic>> createMaxLink(
    String phone,
    String requestId,
  ) async {
    final data = await _api.post('/api/auth/max/link', {
      'phone': phone.trim(),
      'request_id': requestId,
    });

    return Map<String, dynamic>.from(data as Map);
  }

  // Проверить подтверждение в MAX.
  Future<Map<String, dynamic>> checkMaxLink(
    String linkRequestId,
    String requestId,
  ) async {
    final data = await _api.post('/api/auth/max/status', {
      'link_request_id': linkRequestId,
      'request_id': requestId,
    });

    return Map<String, dynamic>.from(data as Map);
  }

  // ?????? ????????????? ?????? ???????? ????? MAX.
  Future<Map<String, dynamic>> startMaxPhoneVerification(String phone) async {
    final data = await _api.post('/api/auth/phone/max/start', {
      'phone': phone.trim(),
    });

    return Map<String, dynamic>.from(data as Map);
  }

  // ????????? ????????????? ?????? ???????? ????? MAX.
  Future<Map<String, dynamic>> checkMaxPhoneVerification(
    String phone,
    String linkRequestId,
  ) async {
    final data = await _api.post('/api/auth/phone/max/status', {
      'phone': phone.trim(),
      'link_request_id': linkRequestId,
    });

    return Map<String, dynamic>.from(data as Map);
  }

  // ============================================================
  // MAX DIRECT REGISTRATION
  // ============================================================

  // Создать запрос регистрации через MAX.
  Future<Map<String, dynamic>> startMaxRegistration() async {
    final data = await _api.post(
      '/api/auth/max/register/start',
      <String, dynamic>{},
    );

    return Map<String, dynamic>.from(data as Map);
  }

  // Проверить подтверждение MAX.
  Future<Map<String, dynamic>> checkMaxRegistration({
    required String linkRequestId,
    required String clientSecret,
  }) async {
    final data = await _api.post('/api/auth/max/register/status', {
      'link_request_id': linkRequestId,
      'client_secret': clientSecret,
    });

    return Map<String, dynamic>.from(data as Map);
  }

  // Завершить регистрацию через MAX.
  Future<AuthResult> completeMaxRegistration({
    required String linkRequestId,
    required String clientSecret,
    required String name,
    required String email,
    required String password,
    String? referredBy,
  }) async {
    final data = await _api.post('/api/auth/max/register/complete', {
      'link_request_id': linkRequestId,
      'client_secret': clientSecret,
      'name': name.trim(),
      'email': email.trim().toLowerCase(),
      'password': password,
      if (referredBy != null && referredBy.trim().isNotEmpty)
        'referred_by': referredBy.trim().toLowerCase(),
    });

    return AuthResult.fromJson(Map<String, dynamic>.from(data as Map));
  }

  // ============================================================
  // MAX REGISTRATION — PHONE VERIFICATION
  // ============================================================

  Future<Map<String, dynamic>> sendMaxRegistrationPhone({
    required String linkRequestId,
    required String clientSecret,
    required String phone,
    required String channel,
  }) async {
    final data = await _api.post('/api/auth/max/register/phone/send', {
      'link_request_id': linkRequestId,
      'client_secret': clientSecret,
      'phone': phone.trim(),
      'channel': channel,
    });

    return Map<String, dynamic>.from(data as Map);
  }

  Future<Map<String, dynamic>> verifyMaxRegistrationPhone({
    required String linkRequestId,
    required String clientSecret,
    required String phone,
    required String otpRequestId,
    required String code,
  }) async {
    final data = await _api.post('/api/auth/max/register/phone/verify', {
      'link_request_id': linkRequestId,
      'client_secret': clientSecret,
      'phone': phone.trim(),
      'request_id': otpRequestId,
      'code': code.trim(),
    });

    return Map<String, dynamic>.from(data as Map);
  }
  // ============================================================
  // ВОССТАНОВЛЕНИЕ ПАРОЛЯ
  // ============================================================

  // ============================================================
  // ПРОФИЛЬ
  // ============================================================

  Future<AuthResult> updateProfile({
    required String name,
    String? birthDate,
  }) async {
    final data =
        await _api.patch('/api/auth/profile', {
              'name': name.trim(),
              'birth_date': birthDate,
            })
            as Map<String, dynamic>;

    return AuthResult.fromJson(data);
  }

  Future<AuthResult> uploadAvatar({
    required String imageBase64,
    required String fileName,
  }) async {
    final data =
        await _api.post('/api/auth/avatar', {
              'image_base64': imageBase64,
              'file_name': fileName,
            })
            as Map<String, dynamic>;

    return AuthResult.fromJson(data);
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _api.patch('/api/auth/password', {
      'current_password': currentPassword,
      'new_password': newPassword,
    });
  }

  Future<String> startPasswordReset({
    required String login,
    required String channel,
  }) async {
    final data =
        await _api.post('/api/auth/password/reset/start', {
              'login': login.trim(),
              'channel': channel,
            })
            as Map<String, dynamic>;

    return data['request_id'] as String;
  }

  Future<void> verifyPasswordReset({
    required String requestId,
    required String code,
  }) async {
    await _api.post('/api/auth/password/reset/verify', {
      'request_id': requestId,
      'code': code.trim(),
    });
  }

  Future<void> completePasswordReset({
    required String requestId,
    required String password,
  }) async {
    await _api.post('/api/auth/password/reset/complete', {
      'request_id': requestId,
      'password': password,
    });
  }
}

// ============================================================
// AG SERVICE — PHONE VERIFICATION
// ============================================================

class PhoneVerificationResult {
  PhoneVerificationResult({required this.requestId, required this.channel});

  final String requestId;
  final String channel;

  factory PhoneVerificationResult.fromJson(Map<String, dynamic> json) {
    return PhoneVerificationResult(
      requestId: json['request_id'] as String,
      channel: json['channel'] as String,
    );
  }
}

class MaxLinkResult {
  MaxLinkResult({required this.linkRequestId, required this.url});

  final String linkRequestId;
  final String url;
}
