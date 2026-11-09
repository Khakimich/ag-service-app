import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/api_client.dart';
import '../../../core/theme_provider.dart';
import '../../../core/ag_auth_shell.dart'; // AG_AUTH6
import '../../../core/ag_icons.dart';
import '../data/auth_repository.dart';
import '../../../core/i18n.dart'; // AG_I18N1

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _repository = AuthRepository(ApiClient());

  final _loginCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  String? _requestId;
  String? _error;

  String _recoveryType = 'phone';
  String _selectedChannel = 'max';

  int _step = 0;

  bool _loading = false;
  bool _showPassword = false;

  static const green = Color(0xFF16A34A);

  @override
  void dispose() {
    _loginCtrl.dispose();
    _codeCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    if (_loginCtrl.text.trim().isEmpty) {
      setState(() {
        _error = tr('Введите номер телефона или Email');
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final id = await _repository.startPasswordReset(
        login: _loginCtrl.text.trim(),
        channel: _recoveryType == 'email' ? 'email' : _selectedChannel,
      );

      if (!mounted) return;

      setState(() {
        _requestId = id;
        _step = 1;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = _errorText(e);
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _verifyCode() async {
    if (_codeCtrl.text.trim().length != 6) {
      setState(() {
        _error = tr('Введите шестизначный код');
      });
      return;
    }

    if (_requestId == null) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await _repository.verifyPasswordReset(
        requestId: _requestId!,
        code: _codeCtrl.text.trim(),
      );

      if (!mounted) return;

      setState(() {
        _step = 2;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = _errorText(e);
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _savePassword() async {
    final password = _passwordCtrl.text;

    if (password.length < 8) {
      setState(() {
        _error = tr('Пароль должен содержать минимум 8 символов');
      });
      return;
    }

    if (password != _confirmCtrl.text) {
      setState(() {
        _error = tr('Пароли не совпадают');
      });
      return;
    }

    if (_requestId == null) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await _repository.completePasswordReset(
        requestId: _requestId!,
        password: password,
      );

      if (!mounted) return;

      setState(() {
        _step = 3;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = _errorText(e);
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  String _errorText(Object error) {
    if (error is ApiException) {
      return error.message;
    }

    return tr('Не удалось выполнить запрос. Проверьте интернет и попробуйте ещё раз.');
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    IconData? icon,
    bool obscure = false,
    Widget? suffix,
    TextInputType? keyboardType,
    int? maxLength,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      maxLength: maxLength,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon == null ? null : Icon(icon),
        suffixIcon: suffix,
        counterText: '',
        filled: true,
      ),
    );
  }

  Widget _actionButton(String title, VoidCallback action) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: _loading ? null : action,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFF26200), // AG_AUTH6
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child:
            _loading
                ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                : Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
      ),
    );
  }

  Widget _content() {
    if (_step == 0) {
      final theme = Theme.of(context);
      final isDark = theme.brightness == Brightness.dark;

      final cardColor = isDark ? const Color(0xFF10161C) : Colors.white;

      final fieldColor =
          isDark ? const Color(0xFF191F26) : const Color(0xFFF5F6F8);

      final borderColor =
          isDark ? const Color(0xFF2C343D) : const Color(0xFFE3E6EA);

      final primaryText =
          isDark ? const Color(0xFFF7F8FA) : const Color(0xFF17191D);

      final secondaryText =
          isDark ? const Color(0xFFA6AFB9) : const Color(0xFF707782);

      Widget svg(String asset, {Color? color, double size = 22}) {
        return SvgPicture.asset(
          asset,
          width: size,
          height: size,
          colorFilter: ColorFilter.mode(
            color ?? secondaryText,
            BlendMode.srcIn,
          ),
        );
      }

      Widget typeCard({
        required String value,
        required String title,
        required String subtitle,
        required String icon,
      }) {
        final selected = _recoveryType == value;

        return Expanded(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap:
                  _loading
                      ? null
                      : () {
                        setState(() {
                          _recoveryType = value;
                          _error = null;
                          _loginCtrl.clear();

                          if (value == 'phone') {
                            if (_selectedChannel == 'email') {
                              _selectedChannel = 'max';
                            }
                          } else {
                            _selectedChannel = 'email';
                          }
                        });
                      },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color:
                      selected
                          ? const Color(
                            0xFFFF6B00,
                          ).withValues(alpha: isDark ? 0.15 : 0.08)
                          : fieldColor,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: selected ? const Color(0xFFFF6B00) : borderColor,
                    width: selected ? 1.7 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 43,
                          height: 43,
                          decoration: BoxDecoration(
                            color:
                                selected ? const Color(0xFFFF6B00) : cardColor,
                            borderRadius: BorderRadius.circular(13),
                          ),
                          alignment: Alignment.center,
                          child: svg(
                            icon,
                            size: 21,
                            color: selected ? Colors.white : primaryText,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color:
                                selected
                                    ? const Color(0xFFFF6B00)
                                    : Colors.transparent,
                            border: Border.all(
                              color:
                                  selected
                                      ? const Color(0xFFFF6B00)
                                      : borderColor,
                            ),
                          ),
                          child:
                              selected
                                  ? const Icon(
                                    Icons.check_rounded,
                                    color: Colors.white,
                                    size: 15,
                                  )
                                  : null,
                        ),
                      ],
                    ),
                    const SizedBox(height: 13),
                    Text(
                      title,
                      style: TextStyle(
                        color: primaryText,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: secondaryText,
                        fontSize: 11,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }

      Widget channelCard({
        required String value,
        required String title,
        required String subtitle,
        required String icon,
      }) {
        final selected = _selectedChannel == value;

        return Padding(
          padding: const EdgeInsets.only(bottom: 9),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(17),
              onTap:
                  _loading
                      ? null
                      : () {
                        setState(() {
                          _selectedChannel = value;
                          _error = null;
                        });
                      },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color:
                      selected
                          ? const Color(
                            0xFFFF6B00,
                          ).withValues(alpha: isDark ? 0.14 : 0.07)
                          : fieldColor,
                  borderRadius: BorderRadius.circular(17),
                  border: Border.all(
                    color: selected ? const Color(0xFFFF6B00) : borderColor,
                    width: selected ? 1.6 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: selected ? const Color(0xFFFF6B00) : cardColor,
                        borderRadius: BorderRadius.circular(13),
                      ),
                      alignment: Alignment.center,
                      child: svg(
                        icon,
                        color: selected ? Colors.white : primaryText,
                      ),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              color: primaryText,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            subtitle,
                            style: TextStyle(
                              color: secondaryText,
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                            selected
                                ? const Color(0xFFFF6B00)
                                : Colors.transparent,
                        border: Border.all(
                          color:
                              selected ? const Color(0xFFFF6B00) : borderColor,
                        ),
                      ),
                      child:
                          selected
                              ? const Icon(
                                Icons.check_rounded,
                                color: Colors.white,
                                size: 15,
                              )
                              : null,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }

      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color:
                isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : const Color(0xFFE8EAED),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.06),
              blurRadius: 30,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              tr('Восстановление пароля'),
              style: TextStyle(
                color: primaryText,
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.4,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              tr('Выберите способ восстановления доступа к аккаунту.'),
              style: TextStyle(color: secondaryText, fontSize: 13, height: 1.4),
            ),

            const SizedBox(height: 24),

            Text(
              tr('Способ восстановления'),
              style: TextStyle(
                color: primaryText,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 11),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                typeCard(
                  value: 'phone',
                  title: tr('Телефон'),
                  subtitle: tr('По номеру телефона'),
                  icon: 'assets/icons/auth/phone.svg',
                ),
                const SizedBox(width: 10),
                typeCard(
                  value: 'email',
                  title: 'Email',
                  subtitle: tr('По электронной почте'),
                  icon: 'assets/icons/auth/email.svg',
                ),
              ],
            ),

            const SizedBox(height: 23),

            Text(
              _recoveryType == 'phone' ? tr('Номер телефона') : tr('Электронная почта'),
              style: TextStyle(
                color: primaryText,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 8),

            TextField(
              controller: _loginCtrl,
              keyboardType:
                  _recoveryType == 'phone'
                      ? TextInputType.phone
                      : TextInputType.emailAddress,
              style: TextStyle(color: primaryText, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                hintText:
                    _recoveryType == 'phone'
                        ? '+7 999 123-45-67'
                        : 'example@mail.ru',
                hintStyle: TextStyle(
                  color: secondaryText.withValues(alpha: 0.8),
                ),
                prefixIcon: Padding(
                  padding: const EdgeInsets.all(14),
                  child: svg(
                    _recoveryType == 'phone'
                        ? 'assets/icons/auth/phone.svg'
                        : 'assets/icons/auth/email.svg',
                  ),
                ),
                filled: true,
                fillColor: fieldColor,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 17,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: Color(0xFFFF6B00),
                    width: 1.7,
                  ),
                ),
              ),
            ),

            if (_recoveryType == 'phone') ...[
              const SizedBox(height: 22),

              Text(
                tr('Куда отправить код?'),
                style: TextStyle(
                  color: primaryText,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),

              const SizedBox(height: 11),

              channelCard(
                value: 'max',
                title: 'MAX',
                subtitle: tr('Получить код через MAX'),
                icon: 'assets/icons/auth/max.svg',
              ),

              channelCard(
                value: 'telegram',
                title: 'Telegram',
                subtitle: tr('Получить код через Telegram'),
                icon: 'assets/icons/auth/telegram.svg',
              ),

              channelCard(
                value: 'sms',
                title: 'SMS',
                subtitle: tr('Получить код в SMS-сообщении'),
                icon: 'assets/icons/auth/sms.svg',
              ),
            ] else ...[
              const SizedBox(height: 18),

              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color:
                      isDark
                          ? const Color(0xFF13231C)
                          : const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF16A34A).withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  children: [
                    svg(
                      'assets/icons/auth/email.svg',
                      color: const Color(0xFF16A34A),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        tr('Код подтверждения будет отправлен на указанную почту.'),
                        style: TextStyle(
                          color:
                              isDark
                                  ? const Color(0xFFC7E8D2)
                                  : const Color(0xFF166534),
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: _loading ? null : _sendCode,
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: const Color(0xFFFF6B00),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(
                    0xFFFF6B00,
                  ).withValues(alpha: 0.45),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child:
                    _loading
                        ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.white,
                          ),
                        )
                        : Text(
                          tr('Получить код'),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
              ),
            ),
          ],
        ),
      );
    }
    if (_step == 1) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            tr('Подтверждение кода'),
            style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 12),

          Text(
            tr('Введите шестизначный код, полученный выбранным способом. Код действует 5 минут.'),
          ),

          const SizedBox(height: 28),

          _field(
            controller: _codeCtrl,
            label: tr('Код подтверждения'),
            icon: Icons.verified_user_outlined,
            keyboardType: TextInputType.number,
            maxLength: 6,
          ),

          const SizedBox(height: 24),

          _actionButton(tr('Подтвердить код'), _verifyCode),

          const SizedBox(height: 12),

          TextButton(
            onPressed:
                _loading
                    ? null
                    : () {
                      setState(() {
                        _step = 0;
                        _requestId = null;
                        _codeCtrl.clear();
                        _error = null;
                      });
                    },
            child: Text(tr('Запросить новый код')),
          ),
        ],
      );
    }

    if (_step == 2) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            tr('Новый пароль'),
            style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 12),

          Text(
            tr('Придумайте новый пароль для входа в приложение AG Service.'),
          ),

          const SizedBox(height: 28),

          _field(
            controller: _passwordCtrl,
            label: tr('Новый пароль'),
            icon: Icons.lock_outline,
            obscure: !_showPassword,
            suffix: IconButton(
              icon: Icon(
                _showPassword ? Icons.visibility_off : Icons.visibility,
              ),
              onPressed: () {
                setState(() {
                  _showPassword = !_showPassword;
                });
              },
            ),
          ),

          const SizedBox(height: 16),

          _field(
            controller: _confirmCtrl,
            label: tr('Повторите новый пароль'),
            icon: Icons.lock_outline,
            obscure: !_showPassword,
          ),

          const SizedBox(height: 12),

          Text(
            tr('Минимум 8 символов'),
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 13,
            ),
          ),

          const SizedBox(height: 26),

          _actionButton(tr('Сохранить новый пароль'), _savePassword),
        ],
      );
    }

    return Column(
      children: [
        const Icon(Icons.check_circle, color: green, size: 85),

        const SizedBox(height: 20),

        Text(
          tr('Пароль успешно изменён!'),
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 12),

        Text(
          tr('Теперь вы можете войти в AG Service с новым паролем.'),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 28),

        _actionButton(tr('Войти в приложение'), () => context.go('/login')),
      ],
    );
  }

  // AG_AUTH6: восстановление пароля в общем оформлении входа
  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final p = AgAuthPal(dark);
    final base = Theme.of(context);
    OutlineInputBorder b(Color c, [double w = 1]) =>
        OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: c, width: w));
    final themed = base.copyWith(
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.field,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
        labelStyle: TextStyle(color: p.mut, fontWeight: FontWeight.w600),
        hintStyle: TextStyle(color: p.mut),
        floatingLabelStyle: const TextStyle(color: Color(0xFFF26200), fontWeight: FontWeight.w700),
        prefixIconColor: p.mut,
        border: b(p.line),
        enabledBorder: b(p.line),
        focusedBorder: b(const Color(0xFFF26200), 1.6),
        errorBorder: b(const Color(0xFFE5484D)),
        focusedErrorBorder: b(const Color(0xFFE5484D), 1.6),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: const Color(0xFFF26200), textStyle: const TextStyle(fontWeight: FontWeight.w800)),
      ),
    );
    return AgAuthShell(
      register: false,
      showSwitch: false,
      title: tr('Восстановление пароля'),
      subtitle: tr('Получите код подтверждения и задайте новый пароль'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Theme(data: themed, child: _content()),
          if (_error != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
              decoration: BoxDecoration(
                color: const Color(0xFFE5484D).withValues(alpha: dark ? .16 : .08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE5484D).withValues(alpha: .3)),
              ),
              child: Text(_error!, style: const TextStyle(color: Color(0xFFE5484D), fontWeight: FontWeight.w600, height: 1.3)),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            height: 52,
            child: OutlinedButton(
              onPressed: () => context.go('/login'),
              style: OutlinedButton.styleFrom(
                foregroundColor: p.ink,
                backgroundColor: p.field,
                side: BorderSide(color: p.line),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                AgIcon(AgAuthIcons.back, size: 18, color: p.ink, strokeWidth: 2.2),
                const SizedBox(width: 8),
                Text(tr('Вернуться ко входу'), style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              ]),
            ),
          ),
          const SizedBox(height: 14),
          Text(tr('Есть вопросы? +7 343 226 13 01 · app@autogrom.ru'),
              textAlign: TextAlign.center, style: TextStyle(color: p.mut, fontSize: 12.5)),
        ],
      ),
    );
  }
}
