import 'package:mobile/core/nav.dart'; // AG_FIX3
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/api_client.dart';
import '../../../core/theme.dart';
import '../../../core/i18n.dart'; // AG_I18N1

class MaxConnectionScreen extends StatefulWidget {
  const MaxConnectionScreen({super.key});

  @override
  State<MaxConnectionScreen> createState() => _MaxConnectionScreenState();
}

class _MaxConnectionScreenState extends State<MaxConnectionScreen>
    with WidgetsBindingObserver {
  final ApiClient _api = ApiClient();

  bool _loading = true;
  bool _connected = false;
  bool _connecting = false;

  String? _error;
  String? _maxUrl;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final token = prefs.getString('auth_token');

      if (token == null || token.isEmpty) {
        throw Exception(tr('Войдите в аккаунт AG Service'));
      }

      _api.setToken(token);

      await _checkStatus();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _checkStatus() async {
    try {
      final result =
          await _api.get('/api/auth/max/account/status')
              as Map<String, dynamic>;

      if (!mounted) return;

      setState(() {
        _connected = result['connected'] == true;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _connectMax() async {
    if (_connecting || _connected) return;

    setState(() {
      _connecting = true;
      _error = null;
    });

    try {
      final result =
          await _api.post('/api/auth/max/account/link', {})
              as Map<String, dynamic>;

      final url = result['max_url'] as String?;

      if (url == null) {
        throw Exception(tr('Сервер не вернул ссылку MAX'));
      }

      final uri = Uri.parse(url);

      if (uri.scheme != 'https' || uri.host != 'max.ru') {
        throw Exception(tr('Некорректная ссылка MAX'));
      }

      if (!mounted) return;

      setState(() {
        _maxUrl = url;
      });

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
        setState(() {
          _connecting = false;
        });
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkStatus();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: const AgBackButton(fallback: '/profile'), /* AG_FIX3 */ title: Text(tr('Подключение MAX'))),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.chat_bubble_rounded,
                size: 72,
                color: BrandColors.orange,
              ),

              const SizedBox(height: 24),

              Text(
                tr('MAX для AG Service'),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 12),

              Text(
                _connected
                    ? tr('MAX успешно подключён к вашему аккаунту')
                    : tr('Подключите MAX для получения кодов подтверждения.'),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              if (_loading) const Center(child: CircularProgressIndicator()),

              if (!_loading && _connected)
                const Center(
                  child: Icon(
                    Icons.check_circle,
                    size: 64,
                    color: Colors.green,
                  ),
                ),

              if (!_loading && !_connected)
                ElevatedButton.icon(
                  onPressed: _connecting ? null : _connectMax,
                  icon: const Icon(Icons.link),
                  label: Text(
                    _connecting
                        ? tr('Подключение...')
                        : _maxUrl == null
                        ? tr('Подключить MAX')
                        : tr('Создать новую ссылку MAX'),
                  ),
                ),

              if (_maxUrl != null && !_connected) ...[
                const SizedBox(height: 16),

                OutlinedButton.icon(
                  onPressed: _checkStatus,
                  icon: const Icon(Icons.refresh),
                  label: Text(tr('Проверить подключение')),
                ),
              ],

              if (_error != null) ...[
                const SizedBox(height: 16),

                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ],

              const SizedBox(height: 24),

              Text(
                tr('Подключение MAX необязательно. Вы можете продолжать пользоваться AG Service без MAX.'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
