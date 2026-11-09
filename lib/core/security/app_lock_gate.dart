import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import '../../core/i18n.dart'; // AG_I18N1

class AppLockGate extends StatefulWidget {
  const AppLockGate({super.key, required this.child});

  final Widget child;

  @override
  State<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends State<AppLockGate> with WidgetsBindingObserver {
  static const _storage = FlutterSecureStorage();
  static const _pinKey = 'ag_security_pin';
  static const _biometricKey = 'ag_security_biometric';

  final LocalAuthentication _localAuth = LocalAuthentication();
  final TextEditingController _pinController = TextEditingController();
  final FocusNode _pinFocusNode = FocusNode();

  bool _loading = true;
  bool _locked = false;
  bool _biometricEnabled = false;
  bool _authenticating = false;
  bool _wentToBackground = false;

  String? _savedPin;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadSecurity();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pinController.dispose();
    _pinFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadSecurity() async {
    final pin = await _storage.read(key: _pinKey);
    final biometric = await _storage.read(key: _biometricKey);

    if (!mounted) return;

    final hasPin = pin != null && RegExp(r'^\d{4}$').hasMatch(pin);

    setState(() {
      _savedPin = hasPin ? pin : null;
      _biometricEnabled = biometric == 'true';
      _locked = hasPin;
      _loading = false;
    });

    if (hasPin) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        if (_biometricEnabled && !kIsWeb) {
          _authenticateBiometric();
        } else {
          _pinFocusNode.requestFocus();
        }
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_savedPin == null) return;

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _wentToBackground = true;
      return;
    }

    if (state == AppLifecycleState.resumed &&
        _wentToBackground &&
        !_authenticating) {
      _wentToBackground = false;
      _lockAgain();
    }
  }

  void _lockAgain() {
    if (!mounted || _savedPin == null) return;

    _pinController.clear();

    setState(() {
      _locked = true;
      _error = null;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      if (_biometricEnabled && !kIsWeb) {
        _authenticateBiometric();
      } else {
        _pinFocusNode.requestFocus();
      }
    });
  }

  void _submitPin() {
    final value = _pinController.text.trim();

    if (value.length != 4) return;

    if (value == _savedPin) {
      FocusManager.instance.primaryFocus?.unfocus();

      setState(() {
        _locked = false;
        _error = null;
      });

      _pinController.clear();
      return;
    }

    HapticFeedback.mediumImpact();

    setState(() {
      _error = tr('Неверный PIN-код');
    });

    _pinController.clear();
    _pinFocusNode.requestFocus();
  }

  Future<void> _authenticateBiometric() async {
    if (_authenticating || !_locked || kIsWeb) return;

    _authenticating = true;

    try {
      final supported = await _localAuth.isDeviceSupported();
      final canCheck = await _localAuth.canCheckBiometrics;

      if (!supported || !canCheck) {
        if (mounted) {
          _pinFocusNode.requestFocus();
        }
        return;
      }

      final authenticated = await _localAuth.authenticate(
        localizedReason: tr('Разблокируйте AG Service'),
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );

      if (!mounted) return;

      if (authenticated) {
        setState(() {
          _locked = false;
          _error = null;
        });
      } else {
        _pinFocusNode.requestFocus();
      }
    } on PlatformException {
      if (mounted) {
        _pinFocusNode.requestFocus();
      }
    } catch (_) {
      if (mounted) {
        _pinFocusNode.requestFocus();
      }
    } finally {
      _authenticating = false;
      _wentToBackground = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return ColoredBox(
        color: Theme.of(context).colorScheme.surface,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_locked) {
      return widget.child;
    }

    final keyboardHeight = MediaQuery.viewInsetsOf(context).bottom;
    final keyboardOpen = keyboardHeight > 0;

    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(
                24,
                keyboardOpen ? 16 : 32,
                24,
                keyboardOpen ? 20 : 32,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight:
                      keyboardOpen
                          ? 0
                          : (constraints.maxHeight - 64).clamp(
                            0.0,
                            double.infinity,
                          ),
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/logo.png',
                          width: keyboardOpen ? 118 : 150,
                          height: keyboardOpen ? 58 : 76,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) {
                            return const SizedBox(
                              height: 60,
                              child: Center(
                                child: Text(
                                  'AG Service',
                                  style: TextStyle(
                                    color: Color(0xFFFF4D06),
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    decoration: TextDecoration.none,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        SizedBox(height: keyboardOpen ? 10 : 20),
                        Text(
                          'AG Service',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            decoration: TextDecoration.none,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          tr('Введите PIN-код'),
                          style: TextStyle(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                            decoration: TextDecoration.none,
                          ),
                        ),
                        SizedBox(height: keyboardOpen ? 14 : 26),
                        SizedBox(
                          width: 220,
                          child: TextField(
                            controller: _pinController,
                            focusNode: _pinFocusNode,
                            autofocus: true,
                            keyboardType: TextInputType.number,
                            obscureText: true,
                            obscuringCharacter: '●',
                            textAlign: TextAlign.center,
                            maxLength: 4,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(4),
                            ],
                            style: const TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 14,
                            ),
                            decoration: InputDecoration(
                              counterText: '',
                              errorText: _error,
                              hintText: '••••',
                              filled: true,
                              fillColor:
                                  Theme.of(
                                    context,
                                  ).colorScheme.surfaceContainerHighest,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 16,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: BorderSide(
                                  color:
                                      Theme.of(
                                        context,
                                      ).colorScheme.outlineVariant,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: BorderSide(
                                  color:
                                      Theme.of(
                                        context,
                                      ).colorScheme.outlineVariant,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: const BorderSide(
                                  color: Color(0xFFFF4D06),
                                  width: 1.5,
                                ),
                              ),
                            ),
                            onChanged: (_) {
                              if (_error != null) {
                                setState(() => _error = null);
                              }

                              if (_pinController.text.length == 4) {
                                _submitPin();
                              }
                            },
                            onSubmitted: (_) => _submitPin(),
                          ),
                        ),
                        if (_biometricEnabled && !kIsWeb) ...[
                          SizedBox(height: keyboardOpen ? 8 : 16),
                          TextButton(
                            onPressed:
                                _authenticating ? null : _authenticateBiometric,
                            child: Text(
                              tr('Использовать биометрию'),
                              style: TextStyle(
                                color: Color(0xFFFF4D06),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
