import 'package:mobile/core/nav.dart'; // AG_FIX3
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';

import '../../../core/theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/i18n.dart'; // AG_I18N1

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  static const _storage = FlutterSecureStorage();

  static const _pinKey = 'ag_security_pin';
  static const _biometricKey = 'ag_security_biometric';

  final LocalAuthentication _localAuth = LocalAuthentication();

  bool _loading = true;
  bool _pinEnabled = false;
  bool _biometricEnabled = false;
  bool _biometricAvailable = false;
  String _biometricLabel = tr('Биометрия');

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final pin = await _storage.read(key: _pinKey);
    final biometric = await _storage.read(key: _biometricKey);

    var biometricAvailable = false;
    var biometricLabel = tr('Биометрия');

    if (!kIsWeb) {
      try {
        final canCheck = await _localAuth.canCheckBiometrics;
        final supported = await _localAuth.isDeviceSupported();

        biometricAvailable = canCheck && supported;

        if (biometricAvailable) {
          final types = await _localAuth.getAvailableBiometrics();

          if (types.contains(BiometricType.face)) {
            biometricLabel = tr('Face ID / распознавание лица');
          } else if (types.contains(BiometricType.fingerprint)) {
            biometricLabel = tr('Отпечаток пальца');
          }
        }
      } catch (_) {
        biometricAvailable = false;
      }
    }

    if (!mounted) return;

    setState(() {
      _pinEnabled = pin != null && pin.length == 4;
      _biometricEnabled =
          biometric == 'true' && biometricAvailable && _pinEnabled;
      _biometricAvailable = biometricAvailable;
      _biometricLabel = biometricLabel;
      _loading = false;
    });
  }

  Future<void> _changePassword() async {
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();

    var saving = false;
    var obscureCurrent = true;
    var obscureNew = true;
    var obscureConfirm = true;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> submit() async {
              final current = currentController.text;
              final next = newController.text;
              final confirm = confirmController.text;

              if (current.isEmpty || next.isEmpty || confirm.isEmpty) {
                ScaffoldMessenger.of(this.context).showSnackBar(
                  SnackBar(content: Text(tr('Заполните все поля'))),
                );
                return;
              }

              if (next.length < 6) {
                ScaffoldMessenger.of(this.context).showSnackBar(
                  SnackBar(
                    content: Text(
                      tr('Новый пароль должен содержать минимум 6 символов'),
                    ),
                  ),
                );
                return;
              }

              if (next != confirm) {
                ScaffoldMessenger.of(this.context).showSnackBar(
                  SnackBar(content: Text(tr('Новые пароли не совпадают'))),
                );
                return;
              }

              final authProvider = this.context.read<AuthProvider>();

              setDialogState(() {
                saving = true;
              });

              try {
                await authProvider.changePassword(
                  currentPassword: current,
                  newPassword: next,
                );

                if (!mounted || !dialogContext.mounted) return;

                Navigator.of(dialogContext).pop();

                ScaffoldMessenger.of(this.context).showSnackBar(
                  SnackBar(content: Text(tr('Пароль успешно изменён'))),
                );
              } catch (e) {
                if (!mounted) return;

                setDialogState(() {
                  saving = false;
                });

                ScaffoldMessenger.of(this.context).showSnackBar(
                  SnackBar(content: Text(trf('Не удалось изменить пароль: {0}', [e]))),
                );
              }
            }

            return AlertDialog(
              title: Text(tr('Изменить пароль')),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: currentController,
                      obscureText: obscureCurrent,
                      autofillHints: const [AutofillHints.password],
                      decoration: InputDecoration(
                        labelText: tr('Текущий пароль'),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setDialogState(() {
                              obscureCurrent = !obscureCurrent;
                            });
                          },
                          icon: Icon(
                            obscureCurrent
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: newController,
                      obscureText: obscureNew,
                      autofillHints: const [AutofillHints.newPassword],
                      decoration: InputDecoration(
                        labelText: tr('Новый пароль'),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setDialogState(() {
                              obscureNew = !obscureNew;
                            });
                          },
                          icon: Icon(
                            obscureNew
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: confirmController,
                      obscureText: obscureConfirm,
                      decoration: InputDecoration(
                        labelText: tr('Повторите новый пароль'),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setDialogState(() {
                              obscureConfirm = !obscureConfirm;
                            });
                          },
                          icon: Icon(
                            obscureConfirm
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                      onSubmitted: (_) {
                        if (!saving) submit();
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed:
                      saving ? null : () => Navigator.of(dialogContext).pop(),
                  child: Text(tr('Отмена')),
                ),
                FilledButton(
                  onPressed: saving ? null : submit,
                  child:
                      saving
                          ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                          : Text(tr('Сохранить')),
                ),
              ],
            );
          },
        );
      },
    );

    currentController.dispose();
    newController.dispose();
    confirmController.dispose();
  }

  Future<String?> _requestPin({
    required String title,
    required String actionText,
  }) async {
    final controller = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        String? error;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            void submit() {
              final value = controller.text.trim();

              if (!RegExp(r'^\d{4}$').hasMatch(value)) {
                setDialogState(() {
                  error = tr('Введите ровно 4 цифры');
                });
                return;
              }

              Navigator.of(dialogContext).pop(value);
            }

            return AlertDialog(
              title: Text(title),
              content: SizedBox(
                width: 360,
                child: TextField(
                  controller: controller,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                  maxLength: 4,
                  obscureText: true,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 12,
                  ),
                  decoration: InputDecoration(
                    labelText: tr('PIN-код'),
                    errorText: error,
                    counterText: '',
                  ),
                  onSubmitted: (_) => submit(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(tr('Отмена')),
                ),
                FilledButton(onPressed: submit, child: Text(actionText)),
              ],
            );
          },
        );
      },
    );

    return result;
  }

  Future<void> _togglePin(bool enabled) async {
    if (enabled) {
      final first = await _requestPin(
        title: tr('Создайте PIN-код'),
        actionText: tr('Далее'),
      );

      if (first == null || !mounted) return;

      FocusManager.instance.primaryFocus?.unfocus();
      await Future<void>.delayed(const Duration(milliseconds: 250));

      if (!mounted) return;

      final second = await _requestPin(
        title: tr('Повторите PIN-код'),
        actionText: tr('Сохранить'),
      );

      if (second == null || !mounted) return;

      if (first != second) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(tr('PIN-коды не совпадают'))));
        return;
      }

      await _storage.write(key: _pinKey, value: first);

      if (!mounted) return;

      setState(() {
        _pinEnabled = true;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(tr('PIN-код включён'))));

      return;
    }

    final currentPin = await _storage.read(key: _pinKey);

    if (currentPin != null) {
      final entered = await _requestPin(
        title: tr('Введите текущий PIN-код'),
        actionText: tr('Отключить'),
      );

      if (entered == null || !mounted) return;

      if (entered != currentPin) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(tr('Неверный PIN-код'))));
        return;
      }
    }

    await _storage.delete(key: _pinKey);
    await _storage.write(key: _biometricKey, value: 'false');

    if (!mounted) return;

    setState(() {
      _pinEnabled = false;
      _biometricEnabled = false;
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(tr('PIN-код отключён'))));
  }

  Future<void> _toggleBiometric(bool enabled) async {
    if (!_biometricAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr('На этом устройстве биометрия недоступна или не настроена'),
          ),
        ),
      );
      return;
    }

    if (!_pinEnabled) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(tr('Сначала включите PIN-код'))));
      return;
    }

    if (enabled) {
      try {
        final authenticated = await _localAuth.authenticate(
          localizedReason: tr('Подтвердите включение биометрического входа'),
          biometricOnly: true,
          persistAcrossBackgrounding: true,
        );

        if (!authenticated || !mounted) return;

        await _storage.write(key: _biometricKey, value: 'true');

        if (!mounted) return;

        setState(() {
          _biometricEnabled = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('Биометрический вход включён'))),
        );
      } catch (e) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(trf('Не удалось включить биометрию: {0}', [e]))),
        );
      }

      return;
    }

    await _storage.write(key: _biometricKey, value: 'false');

    if (!mounted) return;

    setState(() {
      _biometricEnabled = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(leading: const AgBackButton(fallback: '/profile'), /* AG_FIX3 */ title: Text(tr('Безопасность'))),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : SafeArea(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  children: [
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 680),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _SecurityCard(
                              children: [
                                _SecurityTile(
                                  title: tr('Изменить пароль'),
                                  subtitle:
                                      tr('Обновить пароль от аккаунта AG Service'),
                                  trailing: const Icon(
                                    Icons.chevron_right_rounded,
                                  ),
                                  onTap: _changePassword,
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            Text(
                              tr('Вход в приложение'),
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 10),
                            _SecurityCard(
                              children: [
                                _SecurityTile(
                                  title: tr('PIN-код'),
                                  subtitle:
                                      _pinEnabled
                                          ? tr('PIN-код из 4 цифр включён')
                                          : tr('Запрашивать PIN при открытии приложения'),
                                  trailing: Switch.adaptive(
                                    value: _pinEnabled,
                                    activeTrackColor: BrandColors.orange,
                                    onChanged: _togglePin,
                                  ),
                                ),
                                const Divider(height: 1),
                                _SecurityTile(
                                  title: _biometricLabel,
                                  subtitle:
                                      kIsWeb
                                          ? tr('Доступно в мобильном приложении')
                                          : !_biometricAvailable
                                          ? tr('Недоступно или не настроено на устройстве')
                                          : _pinEnabled
                                          ? tr('Использовать системную биометрию')
                                          : tr('Сначала включите PIN-код'),
                                  trailing: Switch.adaptive(
                                    value: _biometricEnabled,
                                    activeTrackColor: BrandColors.orange,
                                    onChanged:
                                        kIsWeb
                                            ? null
                                            : (value) =>
                                                _toggleBiometric(value),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              tr('PIN-код хранится в защищённом хранилище устройства. Биометрические данные приложение не получает и не хранит — проверку выполняет система телефона.'),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}

class _SecurityCard extends StatelessWidget {
  const _SecurityCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.55),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}

class _SecurityTile extends StatelessWidget {
  const _SecurityTile({
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final Widget trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            trailing,
          ],
        ),
      ),
    );
  }
}
