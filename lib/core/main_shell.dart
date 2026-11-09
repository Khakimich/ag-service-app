import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:provider/provider.dart';

import 'ag_extras.dart'; // AG_EXTRAS1
import 'ag_icons.dart';
import 'api_client.dart';
import 'theme.dart';
import '../core/i18n.dart'; // AG_I18N1

class MainShell extends StatefulWidget {
  const MainShell({super.key, required this.child});

  final Widget child;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int? _pressedIndex;
  int? _bounceIndex;

  // AG_EXTRAS1: счётчик непрочитанных на «Чаты» + окно оценки мастера после ремонта
  void _onUnread() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    AgUnread.instance.addListener(_onUnread);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      AgUnread.instance.start(context.read<ApiClient>());
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) AgReviewPrompt.maybeShow(context);
      });
    });
  }

  @override
  void dispose() {
    AgUnread.instance.removeListener(_onUnread);
    super.dispose();
  }

  Future<void> _playBounce(int index) async {
    if (!mounted) return;

    setState(() {
      _bounceIndex = index;
    });

    await Future<void>.delayed(const Duration(milliseconds: 280));

    if (!mounted) return;

    setState(() {
      _bounceIndex = null;
    });
  }

  int _tabIndex(String location) {
    if (location.startsWith('/chats')) {
      return 1;
    }

    if (location.startsWith('/bookings')) {
      return 3;
    }

    if (location.startsWith('/profile')) {
      return 4;
    }

    return 0;
  }

  void _openTab(BuildContext context, int index, int currentIndex) {
    HapticFeedback.selectionClick();

    if (index == 2) {
      _showMapChooser(context);
      return;
    }

    if (index == currentIndex) return;

    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/chats');
        break;
      case 3:
        context.go('/bookings');
        break;
      case 4:
        context.go('/profile');
        break;
    }
  }

  Future<void> _showMapChooser(BuildContext context) async {
    final theme = Theme.of(context);

    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: theme.colorScheme.surface,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 14 + MediaQuery.of(sheetContext).viewPadding.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                tr('Построить маршрут'),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 2),
              Text(
                tr('Выберите приложение для навигации'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 12),
              _mapButton(
                context: sheetContext,
                title:
                    tr('Яндекс Карты'),
                subtitle:
                    tr('Построить маршрут'),
                icon: 'assets/icons/nav/yandex_map.png',
                url:
                    'https://yandex.ru/profile/151067457406?lang=ru&utm_source=copy_link&utm_medium=social&utm_campaign=share',
              ),
              const SizedBox(height: 7),
              _mapButton(
                context: sheetContext,
                title: tr('2ГИС'),
                subtitle:
                    tr('Построить маршрут'),
                icon: 'assets/icons/nav/two_gis.png',
                url: 'https://go.2gis.com/gXJ9M',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _mapButton({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String icon,
    required String url,
  }) {
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: colors.surfaceContainerHighest.withValues(alpha: .55),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () async {
          // AG_FIX1: на Android 11+ canLaunchUrl без <queries> всегда false — открываем напрямую
          final navigator = Navigator.of(context);
          final messenger = ScaffoldMessenger.maybeOf(context);
          final uri = Uri.parse(url);
          navigator.pop();
          var opened = false;
          try {
            opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
          } catch (_) {}
          if (!opened) {
            try {
              opened = await launchUrl(uri, mode: LaunchMode.platformDefault);
            } catch (_) {}
          }
          if (!opened) {
            messenger?.showSnackBar(
              SnackBar(content: Text(tr('Не удалось открыть карту. Установите Яндекс Карты или 2ГИС'))),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Image.asset(
                      icon,
                      width: constraints.maxWidth,
                      height: constraints.maxHeight,
                      fit: BoxFit.contain,
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: colors.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final currentIndex = _tabIndex(location);

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final items = <_NavItem>[
      _NavItem(
        icon: AgIcons.home,
        activeIcon: AgIcons.home,
        label: tr('Главная'),
      ),
      _NavItem(
        icon: AgIcons.chat,
        activeIcon: AgIcons.chat,
        label: tr('Чаты'), // AG_EXTRAS1: «Чаты»
      ),
      _NavItem(
        icon: AgIcons.pin,
        activeIcon: AgIcons.pin,
        label: tr('Карта'),
      ),
      _NavItem(
        icon: AgIcons.history,
        activeIcon: AgIcons.history,
        label: tr('История'),
      ),
      _NavItem(
        icon: AgIcons.settings,
        activeIcon: AgIcons.settings,
        label: tr('Настройки'),
      ),
    ];

    return Scaffold(
      extendBody: true,
      // AG_FIX1: системная «Назад» на вкладке — сначала на главный экран, а не выход из приложения
      body: PopScope(
        canPop: location == '/',
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) context.go('/');
        },
        child: widget.child,
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: 8),
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.40 : 0.10,
                      ),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                    child: Container(
                      height: 68,
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface.withValues(
                          alpha: isDark ? 0.58 : 0.66,
                        ),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: Colors.white.withValues(
                            alpha: isDark ? 0.13 : 0.90,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          for (var i = 0; i < items.length; i++)
                            _buildTabItem(
                              context,
                              index: i,
                              item: items[i],
                              isActive: currentIndex == i,
                              isPressed: _pressedIndex == i,
                              isBouncing: _bounceIndex == i,
                              onTap: () => _openTab(context, i, currentIndex),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabItem(
    BuildContext context, {
    required int index,
    required _NavItem item,
    required bool isActive,
    required bool isPressed,
    required bool isBouncing,
    required VoidCallback onTap,
  }) {
    final color =
        isActive
            ? BrandColors.orange
            : Theme.of(context).colorScheme.onSurfaceVariant;

    final scale =
        isPressed
            ? 0.86
            : isBouncing
            ? 1.22
            : isActive
            ? 1.08
            : 1.0;

    return Expanded(
      child: Semantics(
        button: true,
        selected: isActive,
        label: item.label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,

          onTapDown: (_) {
            setState(() {
              _pressedIndex = index;
            });
          },

          onTapCancel: () {
            setState(() {
              _pressedIndex = null;
            });
          },

          onTapUp: (_) {
            setState(() {
              _pressedIndex = null;
            });

            _playBounce(index);
            onTap();
          },

          child: AnimatedScale(
            scale: isPressed ? 0.90 : 1.0,
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              decoration: BoxDecoration(
                color:
                    isActive
                        ? BrandColors.orange.withValues(alpha: 0.12)
                        : Colors.transparent,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedSlide(
                    offset:
                        isPressed
                            ? const Offset(0, 0.12)
                            : isBouncing
                            ? const Offset(0, -0.28)
                            : isActive
                            ? const Offset(0, -0.08)
                            : Offset.zero,
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOutBack,
                    child: AnimatedScale(
                      scale: scale,
                      duration: const Duration(milliseconds: 260),
                      curve: Curves.easeOutBack,
                      child: _withBadge(
                        AgIcon(
                          isActive ? item.activeIcon : item.icon,
                          size: 26,
                          color: color,
                          strokeWidth: isActive ? 2.0 : 1.8,
                        ),
                        index == 1 ? AgUnread.instance.total : 0,
                      ),
                    ),
                  ),

                  const SizedBox(height: 3),

                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    style: TextStyle(
                      color: color,
                      fontSize: 11,
                      height: 1.1,
                      fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                    ),
                    child: Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Widget _withBadge(Widget icon, int count) {
  if (count <= 0) return icon;
  return Stack(
    clipBehavior: Clip.none,
    children: [
      icon,
      Positioned(
        right: -9,
        top: -6,
        child: TweenAnimationBuilder<double>(
          key: ValueKey(count),
          tween: Tween(begin: .4, end: 1),
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutBack,
          builder: (_, v, child) => Transform.scale(scale: v, child: child),
          child: Container(
            constraints: const BoxConstraints(minWidth: 18),
            height: 18,
            padding: const EdgeInsets.symmetric(horizontal: 5),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFE52B3D),
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: Colors.white, width: 1.6),
            ),
            child: Text(
              count > 99 ? '99+' : '$count',
              style: const TextStyle(color: Colors.white, fontSize: 10.5, height: 1, fontWeight: FontWeight.w900),
            ),
          ),
        ),
      ),
    ],
  );
}

class _NavItem {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });

  final String icon;
  final String activeIcon;
  final String label;
}
