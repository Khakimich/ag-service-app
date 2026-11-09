import 'package:mobile/core/phone_input.dart'; // AG_PHONE7
import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme_provider.dart';
import '../../../core/theme.dart';
import '../../../core/ag_auth_shell.dart'; // AG_AUTH4
import '../providers/auth_provider.dart';
import '../../../core/i18n.dart'; // AG_I18N1

// AG_REG2 + AG_AUTH4 — новое оформление регистрации (логика прежняя)
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  // AG_REFUI1: реферальный код при регистрации
  final _refCtrl = TextEditingController();
  bool _hasReferral = false;
  static final _refRe = RegExp(r'^ag[0-9]{2,10}$', caseSensitive: false);

  bool _loading = false;
  bool _obscure = true;
  bool _phoneVerified = false;
  bool _otpSent = false;

  String? _error;
  String? _channel;
  String? _requestId;
  String? _linkRequestId;
  String? _verifiedPhone;

  int _countdown = 0;
  Timer? _timer;
  Timer? _maxVerificationTimer;
  bool _maxCheckInProgress = false;

  @override
  void initState() {
    super.initState();
    if (_phoneCtrl.text.isEmpty) _phoneCtrl.text = '+7'; // AG_PHONE7
    _phoneCtrl.addListener(_onPhoneChanged);

    // AG_REFUI1: код из приглашения (Google Play или ссылка ?ref=) подставляем сами
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      String code = context.read<AuthProvider>().referralCode ?? '';
      try {
        final q = Uri.base.queryParameters;
        final fromUrl = (q['ref'] ?? q['referral'] ?? '').trim();
        if (fromUrl.isNotEmpty) code = fromUrl;
      } catch (_) {}
      final value = code.trim();
      if (_refRe.hasMatch(value)) {
        setState(() {
          _hasReferral = true;
          _refCtrl.text = value.toUpperCase();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _maxVerificationTimer?.cancel();

    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _codeCtrl.dispose();
    _passCtrl.dispose();
    _refCtrl.dispose();

    super.dispose();
  }

  void _onPhoneChanged() {
    final phone = _phoneCtrl.text.trim();

    if (_verifiedPhone != null && phone != _verifiedPhone) {
      _resetVerification();
    }
  }

  void _resetVerification() {
    _timer?.cancel();
    _maxVerificationTimer?.cancel();

    if (!mounted) return;

    setState(() {
      _phoneVerified = false;
      _otpSent = false;
      _channel = null;
      _requestId = null;
      _linkRequestId = null;
      _verifiedPhone = null;
      _countdown = 0;
      _codeCtrl.clear();
    });
  }

  bool _validPhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    return digits.length >= 8 && digits.length <= 15;
  }

  void _startTimer() {
    _timer?.cancel();

    setState(() => _countdown = 60);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_countdown <= 1) {
        timer.cancel();
        setState(() => _countdown = 0);
      } else {
        setState(() => _countdown--);
      }
    });
  }

  Future<void> _showVerificationMethods() async {
    final phone = _phoneCtrl.text.trim();

    if (!_validPhone(phone)) {
      setState(() {
        _error = tr('Введите корректный номер телефона');
      });
      return;
    }

    FocusScope.of(context).unfocus();

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  tr('Подтвердить номер'),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  phone,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                _methodButton(
                  icon: Icons.sms_outlined,
                  title: 'SMS',
                  subtitle: tr('Получить код в SMS'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _sendCode('sms');
                  },
                ),
                const SizedBox(height: 10),
                _methodButton(
                  icon: Icons.send_rounded,
                  title: 'Telegram',
                  subtitle: tr('Получить код через Telegram'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _sendCode('telegram');
                  },
                ),
                const SizedBox(height: 10),
                _methodButton(
                  icon: Icons.chat_bubble_outline_rounded,
                  title: 'MAX',
                  subtitle: tr('Подтвердить номер через MAX без кода'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _startMaxVerification();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _methodButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        alignment: Alignment.centerLeft,
      ),
      child: Row(
        children: [
          Icon(icon, size: 26),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }

  Future<void> _sendCode(String channel) async {
    final phone = _phoneCtrl.text.trim();

    if (!_validPhone(phone)) {
      setState(() {
        _error = tr('Введите корректный номер телефона');
      });
      return;
    }

    if (_loading || _countdown > 0) return;

    setState(() {
      _loading = true;
      _error = null;
      _channel = channel;
      _linkRequestId = null;
      _requestId = null;
      _phoneVerified = false;
      _otpSent = false;
      _codeCtrl.clear();
    });

    try {
      final result = await context.read<AuthProvider>().sendPhoneCode(
        phone,
        channel,
      );

      if (!mounted) return;

      final requestId = result['request_id']?.toString();

      if (requestId == null || requestId.isEmpty) {
        throw Exception(tr('Сервер не вернул номер запроса подтверждения'));
      }

      setState(() {
        _requestId = requestId;
        _otpSent = true;
      });

      _startTimer();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            channel == 'sms'
                ? tr('Код отправлен по SMS')
                : tr('Код отправлен через Telegram'),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _verifyCode() async {
    final requestId = _requestId;

    if (requestId == null || requestId.isEmpty) {
      setState(() {
        _error = tr('Сначала запросите код подтверждения');
      });
      return;
    }

    final code = _codeCtrl.text.trim();

    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      setState(() {
        _error = tr('Введите шестизначный код');
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final phone = _phoneCtrl.text.trim();

      final result = await context.read<AuthProvider>().confirmPhoneCode(
        phone,
        requestId,
        code,
      );

      if (!mounted) return;

      if (result['verified'] != true) {
        throw Exception(tr('Номер телефона не подтверждён'));
      }

      _timer?.cancel();

      setState(() {
        _phoneVerified = true;
        _verifiedPhone = phone;
        _countdown = 0;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('Номер телефона успешно подтверждён'))),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _startMaxVerification() async {
    final phone = _phoneCtrl.text.trim();

    if (!_validPhone(phone)) {
      setState(() {
        _error = tr('Введите корректный номер телефона');
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _channel = 'max';
      _requestId = null;
      _linkRequestId = null;
      _phoneVerified = false;
      _otpSent = false;
      _codeCtrl.clear();
    });

    try {
      final result = await context
          .read<AuthProvider>()
          .startMaxPhoneVerification(phone);

      if (!mounted) return;

      final linkRequestId = result['link_request_id']?.toString();
      final url = result['max_url']?.toString();

      if (linkRequestId == null ||
          linkRequestId.isEmpty ||
          url == null ||
          url.isEmpty) {
        throw Exception(tr('Сервер не вернул ссылку MAX'));
      }

      final uri = Uri.parse(url);

      if (uri.scheme != 'https' || uri.host != 'max.ru') {
        throw Exception(tr('Получена некорректная ссылка MAX'));
      }

      setState(() {
        _linkRequestId = linkRequestId;
      });

      _startAutomaticMaxVerification();

      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);

      if (!opened) {
        throw Exception(tr('Не удалось открыть MAX'));
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _startAutomaticMaxVerification() {
    _maxVerificationTimer?.cancel();

    _maxVerificationTimer = Timer.periodic(const Duration(seconds: 2), (
      timer,
    ) async {
      if (!mounted || _phoneVerified || _linkRequestId == null) {
        timer.cancel();
        return;
      }

      if (_maxCheckInProgress) return;

      _maxCheckInProgress = true;

      try {
        final phone = _phoneCtrl.text.trim();
        final linkRequestId = _linkRequestId;

        if (linkRequestId == null || linkRequestId.isEmpty) {
          timer.cancel();
          return;
        }

        final result = await context
            .read<AuthProvider>()
            .checkMaxPhoneVerification(phone, linkRequestId);

        if (!mounted) {
          timer.cancel();
          return;
        }

        final status = result['status']?.toString();

        if (status == 'confirmed') {
          final requestId = result['request_id']?.toString();

          if (requestId == null || requestId.isEmpty) {
            return;
          }

          timer.cancel();

          setState(() {
            _requestId = requestId;
            _phoneVerified = true;
            _verifiedPhone = phone;
            _countdown = 0;
            _otpSent = false;
            _error = null;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                tr('Номер телефона автоматически подтверждён через MAX'),
              ),
            ),
          );
        }
      } catch (_) {
        // При автоматической проверке временные сетевые ошибки
        // пользователю не показываем. Следующая проверка будет через 2 сек.
      } finally {
        _maxCheckInProgress = false;
      }
    });
  }

  Future<void> _checkMaxVerification() async {
    final linkRequestId = _linkRequestId;

    if (linkRequestId == null || linkRequestId.isEmpty) {
      setState(() {
        _error = tr('Сначала откройте MAX для подтверждения');
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final phone = _phoneCtrl.text.trim();

      final result = await context
          .read<AuthProvider>()
          .checkMaxPhoneVerification(phone, linkRequestId);

      if (!mounted) return;

      final status = result['status']?.toString();

      if (status == 'confirmed') {
        final requestId = result['request_id']?.toString();

        if (requestId == null || requestId.isEmpty) {
          throw Exception(tr('MAX подтверждён, но сервер не вернул номер запроса'));
        }

        _timer?.cancel();

        setState(() {
          _requestId = requestId;
          _phoneVerified = true;
          _verifiedPhone = phone;
          _countdown = 0;
          _otpSent = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('Номер телефона подтверждён через MAX'))),
        );

        return;
      }

      if (status == 'pending') {
        setState(() {
          _error =
              tr('Подтверждение ещё не получено. Подтвердите номер в MAX и нажмите «Проверить подтверждение».');
        });
        return;
      }

      setState(() {
        _error =
            tr('Ссылка MAX недействительна или срок её действия истёк. Запросите подтверждение заново.');
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final phone = _phoneCtrl.text.trim();

    if (!_phoneVerified || _requestId == null || _verifiedPhone != phone) {
      setState(() {
        _error = tr('Сначала подтвердите номер телефона');
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await context.read<AuthProvider>().register(
        _nameCtrl.text.trim(),
        _emailCtrl.text.trim(),
        _passCtrl.text,
        phone: phone,
        code: _channel == 'max' ? '' : _codeCtrl.text.trim(),
        requestId: _requestId,
        linkRequestId: null,
        referral: _hasReferral ? _refCtrl.text.trim().toLowerCase() : '',
      );

      if (!mounted) return;

      context.go('/');
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  bool _acceptedRegistrationRules = false;
  void _showRegistrationDocument({
    required String title,
    required String text,
    required IconData icon,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        final colors = theme.colorScheme;
        final isDark = theme.brightness == Brightness.dark;

        return FractionallySizedBox(
          heightFactor: 0.88,
          child: Container(
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              border: Border.all(
                color: colors.outlineVariant.withValues(alpha: 0.45),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.14),
                  blurRadius: 28,
                  offset: const Offset(0, -6),
                ),
              ],
            ),
            child: Column(
              children: [
                const SizedBox(height: 10),

                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.onSurfaceVariant.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 12, 14),
                  child: Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: BrandColors.orange.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(icon, color: BrandColors.orange, size: 25),
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Text(
                          title,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            height: 1.15,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: tr('Закрыть'),
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),

                Divider(
                  height: 1,
                  color: colors.outlineVariant.withValues(alpha: 0.55),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                    child: SelectableText(
                      text,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        height: 1.6,
                        fontSize: 14,
                        color: colors.onSurface,
                      ),
                    ),
                  ),
                ),

                Container(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    border: Border(
                      top: BorderSide(
                        color: colors.outlineVariant.withValues(alpha: 0.45),
                      ),
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    child: SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        child: Text(tr('Понятно')),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showRegistrationRules() {
    _showRegistrationDocument(
      title: tr('Правила регистрации'),
      icon: Icons.fact_check_outlined,
      text: '''ПРАВИЛА РЕГИСТРАЦИИ В AG SERVICE

1. Общие положения

Регистрация в приложении AG Service создаёт личный аккаунт пользователя для использования возможностей сервиса.

При регистрации пользователь указывает достоверные данные и подтверждает свой номер телефона доступным способом.

2. Подтверждение номера телефона

Для создания аккаунта необходимо подтвердить номер телефона.

Подтверждение может выполняться через доступные в приложении каналы, включая MAX, Telegram или SMS.

Один пользователь должен использовать принадлежащий ему или находящийся в его законном использовании номер телефона.

3. Данные аккаунта

Пользователь самостоятельно указывает имя, адрес электронной почты и пароль.

Пользователь несёт ответственность за сохранность данных для входа и не должен передавать пароль третьим лицам.

4. Использование сервиса

После регистрации пользователь получает доступ к функциям AG Service, доступным для его аккаунта.

Запрещается использовать приложение для противоправных действий, попыток получить несанкционированный доступ к сервису или данным других пользователей.

5. Согласие с документами

Продолжая регистрацию, пользователь подтверждает, что ознакомился и согласен с настоящими Правилами регистрации и Политикой конфиденциальности.

6. Изменение правил

Правила могут обновляться по мере развития AG Service и изменения требований законодательства.

Оператор сервиса:
ИП Охунджанов Мухаммаджон Кудратович
ИНН 667906235552
ОГРНИП 320665800119462
г. Екатеринбург, ул. Чемпионов, 13А
app@autogrom.ru''',
    );
  }

  void _showPrivacyPolicy() {
    _showRegistrationDocument(
      title: tr('Политика конфиденциальности'),
      icon: Icons.shield_outlined,
      text: '''ПОЛИТИКА КОНФИДЕНЦИАЛЬНОСТИ AG SERVICE

1. Общие положения

Настоящая Политика описывает основные правила обработки информации пользователей приложения AG Service.

2. Какие данные могут обрабатываться

При использовании приложения могут обрабатываться данные, предоставленные пользователем, в том числе:

• имя;
• номер телефона;
• адрес электронной почты;
• сведения об автомобиле;
• данные, связанные с записью на услуги;
• техническая информация, необходимая для работы приложения.

3. Цели обработки

Информация используется для:

• создания и обслуживания аккаунта;
• подтверждения номера телефона;
• предоставления функций приложения;
• оформления и сопровождения записей;
• связи с пользователем;
• обеспечения безопасности и стабильной работы сервиса.

4. Защита информации

AG Service принимает необходимые организационные и технические меры для защиты информации от неправомерного доступа, изменения, раскрытия или уничтожения.

5. Передача данных

Данные могут передаваться третьим лицам только в случаях, необходимых для работы сервиса, исполнения обязательств перед пользователем либо предусмотренных законодательством.

6. Согласие пользователя

Нажимая флажок согласия при регистрации и продолжая создание аккаунта, пользователь подтверждает ознакомление с настоящей Политикой.

7. Контакты оператора

ИП Охунджанов Мухаммаджон Кудратович
ИНН 667906235552
ОГРНИП 320665800119462

Адрес:
г. Екатеринбург, ул. Чемпионов, 13А

Телефон:
+7 999 566 1001

Email:
app@autogrom.ru''',
    );
  }

  // AG_REFUI1: блок «У меня есть реферальный код»
  void _toggleReferral(bool value) {
    setState(() {
      _hasReferral = value;
      if (!value) _refCtrl.clear();
    });
  }

  Widget _referralBlock() {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: _hasReferral
            ? BrandColors.orange.withValues(alpha: isDark ? 0.10 : 0.06)
            : (isDark ? const Color(0xFF0E141A) : Colors.white),
        border: Border.all(
          color: _hasReferral
              ? BrandColors.orange.withValues(alpha: 0.55)
              : colors.outlineVariant.withValues(alpha: 0.6),
          width: _hasReferral ? 1.4 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: _loading ? null : () => _toggleReferral(!_hasReferral),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
              child: Row(
                children: [
                  AnimatedScale(
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOutBack,
                    scale: _hasReferral ? 1.08 : 1.0,
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: BrandColors.orange.withValues(
                          alpha: _hasReferral ? 0.22 : 0.12,
                        ),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: const Icon(
                        Icons.card_giftcard_rounded,
                        color: BrandColors.orange,
                        size: 23,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tr('У меня есть реферальный код'),
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          tr('Код друга, который вас пригласил'),
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Checkbox(
                    value: _hasReferral,
                    activeColor: BrandColors.orange,
                    onChanged: _loading
                        ? null
                        : (value) => _toggleReferral(value ?? false),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: !_hasReferral
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                    child: TextFormField(
                      controller: _refCtrl,
                      enabled: !_loading,
                      textCapitalization: TextCapitalization.characters,
                      autocorrect: false,
                      enableSuggestions: false,
                      maxLength: 12,
                      decoration: InputDecoration(
                        labelText: tr('Реферальный код'),
                        hintText: tr('Например, AG0012'),
                        helperText:
                            tr('После регистрации вы попадёте в группу пригласившего'),
                        counterText: '',
                        prefixIcon: Icon(Icons.confirmation_number_outlined),
                      ),
                      validator: (value) {
                        if (!_hasReferral) return null;
                        final v = (value ?? '').trim();
                        if (v.isEmpty) {
                          return tr('Введите код или снимите галочку');
                        }
                        if (!_refRe.hasMatch(v)) {
                          return tr('Код выглядит так: AG0012');
                        }
                        return null;
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF05090D) : const Color(0xFFF7F8FA),

      body: _agRegShell(context, isDark, Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _phoneCtrl, inputFormatters: [AgPhoneFormatter()], // AG_PHONE7
              enabled: !_loading && !_phoneVerified,
              decoration: InputDecoration(
                hintText: '+7 999 123-45-67',
                labelText: tr('Телефон'),
                suffixIcon:
                    _phoneVerified
                        ? const Icon(
                          Icons.verified_rounded,
                          color: Colors.green,
                        )
                        : null,
              ),
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              validator: (value) {
                final phone = value?.trim() ?? '';

                if (!_validPhone(phone)) {
                  return tr('Введите корректный номер телефона');
                }

                return null;
              },
            ),

            const SizedBox(height: 12),

            if (!_phoneVerified && !_otpSent && _linkRequestId == null)
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _loading ? null : _showVerificationMethods,
                  icon: const Icon(Icons.verified_user_outlined),
                  label: Text(tr('Подтвердить номер')),
                ),
              ),

            if (!_phoneVerified && _otpSent) ...[
              const SizedBox(height: 8),

              Text(
                _channel == 'sms'
                    ? tr('Введите код из SMS')
                    : tr('Введите код из Telegram'),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),

              const SizedBox(height: 10),

              TextFormField(
                controller: _codeCtrl,
                decoration: InputDecoration(
                  hintText: tr('Код подтверждения'),
                  counterText: '',
                ),
                keyboardType: TextInputType.number,
                maxLength: 6,
              ),

              const SizedBox(height: 10),

              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _loading ? null : _verifyCode,
                  child: Text(tr('Подтвердить код')),
                ),
              ),

              const SizedBox(height: 10),

              if (_countdown > 0)
                Text(
                  trf('Повторная отправка через {0} сек.', [_countdown]),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                )
              else
                TextButton(
                  onPressed:
                      _loading || _channel == null
                          ? null
                          : () => _sendCode(_channel!),
                  child: Text(tr('Отправить код повторно')),
                ),

              TextButton(
                onPressed: _loading ? null : _showVerificationMethods,
                child: Text(tr('Выбрать другой способ')),
              ),
            ],

            if (!_phoneVerified &&
                _channel == 'max' &&
                _linkRequestId != null) ...[
              const SizedBox(height: 8),

              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.chat_bubble_outline_rounded),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        tr('Подтвердите номер в MAX. После подтверждения вернитесь в AG Service.'),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _loading ? null : _checkMaxVerification,
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(tr('Проверить подтверждение')),
                ),
              ),

              TextButton(
                onPressed: _loading ? null : _startMaxVerification,
                child: Text(tr('Открыть MAX снова')),
              ),

              TextButton(
                onPressed: _loading ? null : _showVerificationMethods,
                child: Text(tr('Выбрать другой способ')),
              ),
            ],

            if (_phoneVerified) ...[
              const SizedBox(height: 8),

              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: Colors.green),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _channel == 'max'
                            ? tr('Телефон подтверждён через MAX')
                            : _channel == 'telegram'
                            ? tr('Телефон подтверждён через Telegram')
                            : tr('Телефон подтверждён по SMS'),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              TextFormField(
                controller: _nameCtrl,
                decoration: InputDecoration(
                  labelText: tr('Имя'),
                  hintText: tr('Введите имя'),
                ),
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return tr('Введите имя');
                  }

                  return null;
                },
              ),

              const SizedBox(height: 12),

              TextFormField(
                controller: _emailCtrl,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  hintText: 'example@mail.ru',
                ),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || !value.contains('@')) {
                    return tr('Введите корректный email');
                  }

                  return null;
                },
              ),

              const SizedBox(height: 12),

              TextFormField(
                controller: _passCtrl,
                obscureText: _obscure,
                decoration: InputDecoration(
                  labelText: tr('Пароль'),
                  hintText: tr('Минимум 6 символов'),
                  suffixIcon: IconButton(
                    icon: SvgPicture.asset(
                      _obscure
                          ? 'assets/icons/auth/eye_off.svg'
                          : 'assets/icons/auth/eye.svg',
                      width: 22,
                      height: 22,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscure = !_obscure;
                      });
                    },
                  ),
                ),
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                validator: (value) {
                  if (value == null || value.length < 6) {
                    return tr('Минимум 6 символов');
                  }

                  return null;
                },
              ),

              const SizedBox(height: 18),

              _referralBlock(),

              const SizedBox(height: 14),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: _acceptedRegistrationRules,
                      activeColor: BrandColors.orange,
                      onChanged:
                          _loading
                              ? null
                              : (value) {
                                setState(() {
                                  _acceptedRegistrationRules = value ?? false;
                                  if (_acceptedRegistrationRules) {
                                    _error = null;
                                  }
                                });
                              },
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 11),
                        child: Text.rich(
                          TextSpan(
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.35,
                              color:
                                  Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                            ),
                            children: [
                              TextSpan(text: tr('Я принимаю ')),
                              TextSpan(
                                text: tr('Правила регистрации'),
                                style: const TextStyle(
                                  color: BrandColors.orange,
                                  fontWeight: FontWeight.w700,
                                  decoration: TextDecoration.underline,
                                  decorationColor: BrandColors.orange,
                                ),
                                recognizer:
                                    TapGestureRecognizer()
                                      ..onTap = _showRegistrationRules,
                              ),
                              TextSpan(text: tr(' и ')),
                              TextSpan(
                                text: tr('Политику конфиденциальности'),
                                style: const TextStyle(
                                  color: BrandColors.orange,
                                  fontWeight: FontWeight.w700,
                                  decoration: TextDecoration.underline,
                                  decorationColor: BrandColors.orange,
                                ),
                                recognizer:
                                    TapGestureRecognizer()
                                      ..onTap = _showPrivacyPolicy,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed:
                      _loading || !_acceptedRegistrationRules ? null : _submit,
                  child:
                      _loading
                          ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: Colors.white,
                            ),
                          )
                          : Text(tr('Зарегистрироваться')),
                ),
              ),
            ],

            if (_error != null) ...[
              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: BrandColors.orange.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _error!,
                  style: const TextStyle(color: BrandColors.orange),
                ),
              ),
            ],

            const SizedBox(height: 20),

          ],
        ),
      )),
    );
  }

  // AG_AUTH4: оформление регистрации — общий вид со входом (живой фон, карта AG BONUS, стеклянная форма)
  Widget _agRegShell(BuildContext context, bool isDark, Widget form) {
    final p = AgAuthPal(isDark);
    final ink = p.ink, mut = p.mut, field = p.field, line = p.line;
    final step = _phoneVerified ? 2 : 1;
    final base = Theme.of(context);
    OutlineInputBorder b(Color c, [double w = 1]) =>
        OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: c, width: w));
    final themed = base.copyWith(
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: field,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
        labelStyle: TextStyle(color: mut, fontWeight: FontWeight.w600),
        hintStyle: TextStyle(color: mut),
        floatingLabelStyle: const TextStyle(color: BrandColors.orange, fontWeight: FontWeight.w700),
        border: b(line),
        enabledBorder: b(line),
        focusedBorder: b(BrandColors.orange, 1.6),
        errorBorder: b(const Color(0xFFE5484D)),
        focusedErrorBorder: b(const Color(0xFFE5484D), 1.6),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: BrandColors.orange,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(54),
          elevation: 0,
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ink,
          backgroundColor: field,
          minimumSize: const Size.fromHeight(52),
          side: BorderSide(color: BrandColors.orange.withValues(alpha: .55), width: 1.4),
          textStyle: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: BrandColors.orange, textStyle: const TextStyle(fontWeight: FontWeight.w800)),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        fillColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? BrandColors.orange : null),
      ),
    );

    Widget stepDot(int n, String label) {
      final done = step > n, on = step == n;
      return Expanded(
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: done || on ? const LinearGradient(colors: [Color(0xFFFF8A2B), Color(0xFFF26200)]) : null,
                color: done || on ? null : field,
                border: Border.all(color: done || on ? Colors.transparent : line),
                boxShadow: on ? [BoxShadow(color: BrandColors.orange.withValues(alpha: .35), blurRadius: 12, offset: const Offset(0, 4))] : null,
              ),
              child: done
                  ? const Icon(Icons.check_rounded, size: 18, color: Colors.white)
                  : Text('$n', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: on ? Colors.white : mut)),
            ),
            const SizedBox(height: 6),
            Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12.5, fontWeight: on ? FontWeight.w800 : FontWeight.w600, color: on || done ? ink : mut)),
          ],
        ),
      );
    }

    Widget bar(int n) => Expanded(
          child: Container(
            height: 3,
            margin: const EdgeInsets.only(bottom: 22),
            decoration: BoxDecoration(color: step > n ? BrandColors.orange : line, borderRadius: BorderRadius.circular(3)),
          ),
        );

    return AgAuthShell(
      register: true,
      title: tr('Создайте аккаунт'),
      subtitle: tr('Подтвердите телефон и заполните данные — это займёт меньше минуты'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(children: [stepDot(1, tr('Телефон')), bar(1), stepDot(2, tr('Данные')), bar(2), stepDot(3, tr('Готово'))]),
          const SizedBox(height: 14),
          Theme(data: themed, child: form),
        ],
      ),
    );
  }
}
