import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme.dart';
import '../../../models/chat_conversation.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/chat_repository.dart';
import 'chat_screen.dart';
import '../../../core/i18n.dart'; // AG_I18N1

/// Вкладка «Чат». Экрана выбора направления больше нет:
/// сразу открывается диалог с мастером-приёмщиком.
class ChatsScreen extends StatefulWidget {
  const ChatsScreen({super.key});

  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
  /// Направление, в которое попадает клиент. Другие варианты на сервере:
  /// 'm_service', 'autogrom_shop', 'taxi_park'.
  static const _department = 'autogrom_service';

  ChatConversation? _conversation;

  bool _loading = false;
  bool? _wasLoggedIn;
  String? _error;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final loggedIn = context.read<AuthProvider>().isLoggedIn;

      _wasLoggedIn = loggedIn;

      if (loggedIn) {
        _openChat();
      }
    });
  }

  Future<void> _openChat() async {
    if (_loading) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final conversation = await context
          .read<ChatRepository>()
          .getOrCreateDepartmentConversation(_department);

      if (!mounted) return;

      setState(() {
        _conversation = conversation;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (_wasLoggedIn != null && _wasLoggedIn != auth.isLoggedIn) {
      _wasLoggedIn = auth.isLoggedIn;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        if (auth.isLoggedIn) {
          _openChat();
        } else {
          setState(() {
            _conversation = null;
            _error = null;
          });
        }
      });
    }

    if (!auth.isLoggedIn) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.support_agent_rounded,
                  size: 70,
                  color: BrandColors.orange,
                ),
                const SizedBox(height: 18),
                Text(
                  tr('Чат с мастером'),
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  tr('Войдите в аккаунт, чтобы написать нам.'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 22),
                ElevatedButton(
                  onPressed: () => context.push('/login'),
                  child: Text(tr('Войти')),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final conversation = _conversation;

    if (conversation != null) {
      return ChatScreen(
        key: ValueKey(conversation.id),
        conversationId: conversation.id,
        conversation: conversation,
        // Небольшой зазор между полем ввода и плавающим нижним меню.
        bottomInset: 6,
      );
    }

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 48,
                  color: BrandColors.orange,
                ),
                const SizedBox(height: 12),
                Text(
                  trf('Не удалось открыть чат: {0}', [_error]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: _openChat,
                  child: Text(tr('Повторить')),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
