import 'package:mobile/core/nav.dart'; // AG_FIX3
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme.dart';
import '../providers/auth_provider.dart';
import '../../../core/i18n.dart'; // AG_I18N1

class MaxRegistrationScreen extends StatefulWidget {
  const MaxRegistrationScreen({super.key});

  @override
  State<MaxRegistrationScreen> createState() => _MaxRegistrationScreenState();
}

class _MaxRegistrationScreenState extends State<MaxRegistrationScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();

  String? _linkRequestId;
  String? _clientSecret;
  String? _maxUrl;
  String? _shortCode;
  String? _otpRequestId;
  String? _error;

  String _channel = 'sms';

  int _step = 0;
  bool _loading = false;
  bool _maxConfirmed = false;
  bool _phoneVerified = false;

  Timer? _pollTimer;
  bool _pollBusy = false;

  @override
  void dispose() {
    _pollTimer?.cancel();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _phoneCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  String get _phone {
    return _phoneCtrl.text.replaceAll(RegExp(r'\D'), '');
  }

  String _message(Object error) {
    return error.toString().replaceFirst(
      RegExp(r'^ApiException\(\d+\):\s*'),
      '',
    );
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_loading) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await action();
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = _message(error));
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _startMax() async {
    await _run(() async {
      _pollTimer?.cancel();

      final result = await context.read<AuthProvider>().startMaxRegistration();

      if (!mounted) return;

      setState(() {
        _linkRequestId = result['link_request_id'] as String;
        _clientSecret = result['client_secret'] as String;
        _maxUrl = result['max_url'] as String;
        _shortCode = result['short_code'].toString();
        _maxConfirmed = false;
        _phoneVerified = false;
        _otpRequestId = null;
        _step = 1;
      });

      _startPolling();
    });
  }

  void _startPolling() {
    _pollTimer?.cancel();

    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) => _checkMax());
  }

  Future<void> _checkMax() async {
    if (_pollBusy ||
        _maxConfirmed ||
        !mounted ||
        _linkRequestId == null ||
        _clientSecret == null) {
      return;
    }

    _pollBusy = true;

    try {
      final result = await context.read<AuthProvider>().checkMaxRegistration(
        linkRequestId: _linkRequestId!,
        clientSecret: _clientSecret!,
      );

      if (!mounted) return;

      final status = result['status'];

      if (status == 'confirmed') {
        _pollTimer?.cancel();

        setState(() {
          _maxConfirmed = true;
          _step = 2;
          _error = null;
        });
      } else if (status == 'expired' || status == 'completed') {
        _pollTimer?.cancel();

        setState(() {
          _step = 0;
          _error =
              status == 'expired'
                  ? tr('Срок подтверждения MAX истёк. Начните регистрацию заново.')
                  : tr('Этот запрос регистрации уже использован.');
        });
      }
    } catch (error) {
      if (!mounted) return;

      _pollTimer?.cancel();

      setState(() {
        _error = _message(error);
      });
    } finally {
      _pollBusy = false;
    }
  }

  Future<void> _openMax() async {
    final url = _maxUrl;

    if (url == null) return;

    final uri = Uri.parse(url);

    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!opened && mounted) {
      setState(() {
        _error =
            tr('Не удалось открыть MAX. Откройте бота вручную и отправьте код.');
      });
    }
  }

  Future<void> _sendPhoneCode() async {
    if (!_maxConfirmed) return;

    if (_phone.length < 8 || _phone.length > 15) {
      setState(() {
        _error = tr('Введите правильный номер телефона');
      });
      return;
    }

    await _run(() async {
      final result = await context
          .read<AuthProvider>()
          .sendMaxRegistrationPhone(
            linkRequestId: _linkRequestId!,
            clientSecret: _clientSecret!,
            phone: _phone,
            channel: _channel,
          );

      if (!mounted) return;

      setState(() {
        _otpRequestId = result['request_id'] as String;
        _codeCtrl.clear();
        _step = 3;
      });
    });
  }

  Future<void> _verifyPhone() async {
    if (_otpRequestId == null) return;

    final code = _codeCtrl.text.trim();

    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      setState(() {
        _error = tr('Введите шестизначный код');
      });
      return;
    }

    await _run(() async {
      final result = await context
          .read<AuthProvider>()
          .verifyMaxRegistrationPhone(
            linkRequestId: _linkRequestId!,
            clientSecret: _clientSecret!,
            phone: _phone,
            otpRequestId: _otpRequestId!,
            code: code,
          );

      if (result['phone_verified'] != true) {
        throw StateError(tr('Не удалось подтвердить номер телефона'));
      }

      if (!mounted) return;

      setState(() {
        _phoneVerified = true;
        _step = 4;
      });
    });
  }

  Future<void> _completeRegistration() async {
    if (!_maxConfirmed || !_phoneVerified) {
      setState(() {
        _error = tr('Подтвердите MAX и номер телефона');
      });
      return;
    }

    if (_nameCtrl.text.trim().isEmpty) {
      setState(() => _error = tr('Введите ваше имя'));
      return;
    }

    if (!RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    ).hasMatch(_emailCtrl.text.trim())) {
      setState(() => _error = tr('Введите правильный email'));
      return;
    }

    if (_passwordCtrl.text.length < 6) {
      setState(() {
        _error = tr('Пароль должен содержать минимум 6 символов');
      });
      return;
    }

    await _run(() async {
      await context.read<AuthProvider>().completeMaxRegistration(
        linkRequestId: _linkRequestId!,
        clientSecret: _clientSecret!,
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );

      if (!mounted) return;

      context.go('/');
    });
  }

  Widget _button(String title, VoidCallback action) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _loading ? null : action,
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
                : Text(title),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    TextInputType? keyboard,
    bool obscure = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboard,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _buildStart() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.account_circle_outlined, size: 80, color: Colors.blue),
        const SizedBox(height: 20),
        Text(
          tr('Регистрация через MAX'),
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Text(
          tr('Подключите MAX и подтвердите номер телефона, чтобы создать аккаунт AG Service.'),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 30),
        _button(tr('Начать регистрацию'), _startMax),
      ],
    );
  }

  Widget _buildMaxConfirmation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.chat_bubble_outline, size: 64, color: Colors.blue),
        const SizedBox(height: 20),
        Text(
          tr('Подтвердите MAX'),
          style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Text(
          tr('Откройте бота AG Service в MAX и отправьте ему этот код:'),
        ),
        const SizedBox(height: 20),
        SelectableText(
          _shortCode ?? '',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 38,
            fontWeight: FontWeight.bold,
            letterSpacing: 6,
          ),
        ),
        const SizedBox(height: 20),
        _button(tr('Открыть MAX'), _openMax),
        const SizedBox(height: 12),
        Center(child: Text(tr('Ожидаем подтверждение MAX...'))),
        const SizedBox(height: 12),
        TextButton(
          onPressed: _loading ? null : _checkMax,
          child: Text(tr('Проверить подтверждение')),
        ),
      ],
    );
  }

  Widget _buildPhone() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.verified_user_outlined, size: 60, color: Colors.green),
        const SizedBox(height: 16),
        Text(
          tr('MAX подтверждён!'),
          style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Text(tr('Теперь подтвердите ваш номер телефона.')),
        const SizedBox(height: 24),
        _field(
          _phoneCtrl,
          tr('Номер телефона, например +7 999 123 45 67'),
          keyboard: TextInputType.phone,
        ),
        const SizedBox(height: 24),
        Text(
          tr('Куда отправить код?'),
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        RadioGroup<String>(
          groupValue: _channel,
          onChanged: (value) {
            if (value != null) {
              setState(() => _channel = value);
            }
          },
          child: Column(
            children: [
              RadioListTile<String>(
                title: Text('SMS'),
                subtitle: Text(tr('Код в SMS-сообщении')),
                value: 'sms',
              ),
              RadioListTile<String>(
                title: Text('Telegram'),
                subtitle: Text(tr('Код через Telegram Gateway')),
                value: 'telegram',
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _button(tr('Отправить код'), _sendPhoneCode),
      ],
    );
  }

  Widget _buildOtp() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.sms_outlined, size: 60, color: Colors.blue),
        const SizedBox(height: 16),
        Text(
          tr('Подтверждение телефона'),
          style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Text(trf('Код отправлен на номер +{0}', [_phone])),
        const SizedBox(height: 24),
        _field(_codeCtrl, tr('Шестизначный код'), keyboard: TextInputType.number),
        const SizedBox(height: 24),
        _button(tr('Подтвердить номер'), _verifyPhone),
        const SizedBox(height: 12),
        TextButton(
          onPressed:
              _loading
                  ? null
                  : () {
                    setState(() {
                      _otpRequestId = null;
                      _codeCtrl.clear();
                      _step = 2;
                    });
                  },
          child: Text(tr('Изменить номер или способ отправки')),
        ),
      ],
    );
  }

  Widget _buildProfile() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.check_circle, size: 64, color: Colors.green),
        const SizedBox(height: 16),
        Text(
          tr('Телефон подтверждён!'),
          style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Text(tr('Заполните данные для создания аккаунта.')),
        const SizedBox(height: 24),
        _field(_nameCtrl, tr('Ваше имя')),
        const SizedBox(height: 14),
        _field(_emailCtrl, 'Email', keyboard: TextInputType.emailAddress),
        const SizedBox(height: 14),
        _field(_passwordCtrl, tr('Пароль (минимум 6 символов)'), obscure: true),
        const SizedBox(height: 24),
        _button(tr('Завершить регистрацию'), _completeRegistration),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: const AgBackButton(fallback: '/login'), /* AG_FIX3 */ title: const Text('AG Service — MAX')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            if (_step == 0) _buildStart(),
            if (_step == 1) _buildMaxConfirmation(),
            if (_step == 2) _buildPhone(),
            if (_step == 3) _buildOtp(),
            if (_step == 4) _buildProfile(),
            if (_error != null) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: BrandColors.orange.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _error!,
                  style: const TextStyle(color: BrandColors.orange),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
