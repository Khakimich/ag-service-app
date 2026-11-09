// AG_FIX1 — безопасная кнопка «Назад»: если некуда вернуться, открываем главный экран.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/i18n.dart'; // AG_I18N1

extension AgNav on BuildContext {
  void agBack([String fallback = '/']) {
    if (canPop()) {
      pop();
    } else {
      go(fallback);
    }
  }
}

/// AG_FIX3 — кнопка «Назад» для шапки экрана: всегда видна; если возвращаться некуда — открывает [fallback].
class AgBackButton extends StatelessWidget {
  const AgBackButton({super.key, this.fallback = '/'});
  final String fallback;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tr('Назад'),
      icon: const Icon(Icons.arrow_back_rounded),
      onPressed: () {
        final nav = Navigator.of(context);
        if (nav.canPop()) {
          nav.maybePop();
        } else {
          GoRouter.of(context).go(fallback);
        }
      },
    );
  }
}

/// AG_FIX5 — общий «показыватель» сообщений (например «Аккаунт заблокирован»), работает с любого экрана.
final GlobalKey<ScaffoldMessengerState> agMessengerKey = GlobalKey<ScaffoldMessengerState>();
