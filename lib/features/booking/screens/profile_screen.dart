import 'package:mobile/core/update_checker.dart'; // AG_FIX1
import 'dart:async';
import 'package:flutter/material.dart';
import '../../profile/screens/documents_screen.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme.dart';
import '../../../core/ag_icons.dart'; // AG_PROF6
import '../../../core/api_client.dart'; // AG_PROF7
import '../../../core/theme_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/my_bookings_provider.dart';
import '../providers/notifications_provider.dart';
import '../../../core/i18n.dart'; // AG_I18N1
import '../../bonus/my_qr_sheet.dart'; // AG_BONUSQR1

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          if (auth.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!auth.isLoggedIn) {
            return _GuestView();
          }
          return _UserView(auth: auth);
        },
      ),
    );
  }
}

class _GuestView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SafeArea(
      bottom: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
            children: [
              Text(
                tr('Настройки'),
                style: TextStyle(
                  fontSize: 28,
                  height: 1.15,
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurface,
                ),
              ),

              const SizedBox(height: 18),

              const _AgGuestHero(), // AG_PROF6

              const SizedBox(height: 22),

              _ProfileSectionTitle(title: tr('Настройки')),
              const SizedBox(height: 10),

              _ProfileCard(
                children: [
                  _ProfileItem( // AG_I18N1
                    icon: 'assets/icons/profile/theme.svg',
                    title: tr('Язык'),
                    subtitle: '${AgI18n.current.flag}  ${AgI18n.current.name}',
                    onTap: () => AgI18n.pick(context),
                  ),
                  const _ProfileDivider(),
                  _ProfileItem(
                    icon: 'assets/icons/profile/theme.svg',
                    title: tr('Оформление'),
                    subtitle: tr('Системная, светлая или тёмная тема'),
                    onTap: () => _showThemeSelector(context),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              _ProfileSectionTitle(title: tr('Приложение')),
              const SizedBox(height: 10),

              _ProfileCard(
                children: [
                  _ProfileItem( // AG_FIX1
                    icon: 'assets/icons/profile/info.svg',
                    title: tr('Проверить обновления'),
                    subtitle: tr('Новая версия и что в ней нового'),
                    onTap: () => AgUpdateChecker.checkManually(context),
                  ),
                  const _ProfileDivider(),
                  _ProfileItem(
                    icon: 'assets/icons/profile/cache.svg',
                    title: tr('Очистить кэш'),
                    subtitle: tr('Освободить место на устройстве'),
                    onTap: () => _confirmClearCache(context),
                  ),

                  const _ProfileDivider(),

                  _ProfileItem(
                    icon: 'assets/icons/profile/info.svg',
                    title: tr('Документы'),
                    subtitle: tr('Политика, соглашения и правовая информация'),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const DocumentsScreen(),
                        ),
                      );
                    },
                  ),

                  const _ProfileDivider(),

                  _ProfileItem(
                    icon: 'assets/icons/profile/info.svg',
                    title: tr('О приложении'),
                    subtitle: tr('AG Service, контакты и информация'),
                    onTap: () => context.push('/about'),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              const _AppVersionFooter(),
            ],
          ),
        ),
      ),
    );
  }
}

class _UserView extends StatelessWidget {
  const _UserView({required this.auth});

  final AuthProvider auth;

  @override
  Widget build(BuildContext context) {
    final user = auth.user!;
    final initial =
        user.name.trim().isNotEmpty ? user.name.trim()[0].toUpperCase() : '?';

    return SafeArea(
      bottom: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
            children: [
              Text(
                tr('Настройки'),
                style: TextStyle(
                  fontSize: 28,
                  height: 1.15,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 20),

              _AgProfileHero(user: user, initial: initial), // AG_PROF6

              const SizedBox(height: 26),

              _ProfileSectionTitle(title: tr('Аккаунт')),
              const SizedBox(height: 10),
              _ProfileCard(
                children: [
                  _ProfileItem(
                    icon: 'assets/icons/profile/personal.svg',
                    title: tr('Личные данные'),
                    subtitle: tr('Имя, телефон и дата рождения'),
                    onTap: () => context.push('/profile/personal'),
                  ),
                  const _ProfileDivider(),
                  _ProfileItem(
                    icon: 'assets/icons/profile/car.svg',
                    title: tr('Мои автомобили'),
                    subtitle: tr('Гараж и данные автомобилей'),
                    onTap: () => context.push('/profile/my-cars'),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              _ProfileSectionTitle(title: tr('Сервисы')),
              const SizedBox(height: 10),
              _ProfileCard(
                children: [
                  Consumer<NotificationsProvider>(
                    builder: (context, provider, _) {
                      return _ProfileItem(
                        icon: 'assets/icons/profile/notifications.svg',
                        title: tr('Уведомления'),
                        subtitle: tr('История уведомлений'),
                        badge:
                            provider.unreadCount > 0
                                ? provider.unreadCount.toString()
                                : null,
                        onTap: () => context.push('/profile/notifications'),
                      );
                    },
                  ),
                  const _ProfileDivider(),
                  ValueListenableBuilder<int?>( // AG_PROF7: настоящий баланс бонусного счёта
                    valueListenable: _AgBal.v,
                    builder: (context, b, _) => _ProfileItem(
                      icon: 'assets/icons/profile/gift.svg',
                      title: tr('Бонусы и приглашения'),
                      subtitle: trf('Бонусный счёт: {0} ₽', [b ?? user.bonusPoints]),
                      onTap: () => context.push('/profile/referrals'),
                    ),
                  ),
                  const _ProfileDivider(),
                  _ProfileItem(
                    icon: 'assets/icons/profile/message.svg',
                    title: tr('Подключение MAX'),
                    subtitle: tr('Получение кодов подтверждения'),
                    accent: true,
                    onTap: () => context.push('/profile/max'),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              _ProfileSectionTitle(title: tr('Настройки')),
              const SizedBox(height: 10),
              _ProfileCard(
                children: [
                  _ProfileItem(
                    icon: 'assets/icons/profile/lock.svg',
                    title: tr('Безопасность'),
                    subtitle: tr('Пароль, PIN-код и биометрия'),
                    onTap: () => context.push('/profile/security'),
                  ),
                  const _ProfileDivider(),
                  _ProfileItem( // AG_I18N1
                    icon: 'assets/icons/profile/theme.svg',
                    title: tr('Язык'),
                    subtitle: '${AgI18n.current.flag}  ${AgI18n.current.name}',
                    onTap: () => AgI18n.pick(context),
                  ),
                  const _ProfileDivider(),
                  _ProfileItem(
                    icon: 'assets/icons/profile/theme.svg',
                    title: tr('Оформление'),
                    subtitle: tr('Системная, светлая или тёмная тема'),
                    onTap: () => _showThemeSelector(context),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              _ProfileSectionTitle(title: tr('Приложение')),
              const SizedBox(height: 10),
              _ProfileCard(
                children: [
                  _ProfileItem( // AG_FIX1
                    icon: 'assets/icons/profile/info.svg',
                    title: tr('Проверить обновления'),
                    subtitle: tr('Новая версия и что в ней нового'),
                    onTap: () => AgUpdateChecker.checkManually(context),
                  ),
                  const _ProfileDivider(),
                  _ProfileItem(
                    icon: 'assets/icons/profile/cache.svg',
                    title: tr('Очистить кэш'),
                    subtitle: tr('Освободить место на устройстве'),
                    onTap: () => _confirmClearCache(context),
                  ),
                  const _ProfileDivider(),
                  _ProfileItem(
                    icon: 'assets/icons/profile/info.svg',
                    title: tr('Документы'),
                    subtitle: tr('Политика, соглашения и правовая информация'),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const DocumentsScreen(),
                        ),
                      );
                    },
                  ),
                  const _ProfileDivider(),
                  _ProfileItem(
                    icon: 'assets/icons/profile/info.svg',
                    title: tr('О приложении'),
                    subtitle: tr('AG Service, контакты и информация'),
                    onTap: () => context.push('/about'),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              SizedBox(
                height: 54,
                child: OutlinedButton(
                  onPressed: () async {
                    await context.read<AuthProvider>().logout();
                    if (context.mounted) {
                      context.read<MyBookingsProvider>().clear();
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: BrandColors.orange,
                    side: BorderSide(
                      color: BrandColors.orange.withValues(alpha: 0.45),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SvgPicture.asset(
                        'assets/icons/profile/logout.svg',
                        width: 21,
                        height: 21,
                        colorFilter: const ColorFilter.mode(
                          BrandColors.orange,
                          BlendMode.srcIn,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        tr('Выйти из аккаунта'),
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 26),
              const _AppVersionFooter(),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _showThemeSelector(BuildContext context) async {
  final provider = context.read<ThemeProvider>();

  await showModalBottomSheet<void>(
    useRootNavigator: true,
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tr('Оформление'),
                style: Theme.of(
                  sheetContext,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                tr('Выберите тему приложения'),
                style: Theme.of(sheetContext).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(sheetContext).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 18),
              _ThemeChoice(
                title: tr('Системная'),
                subtitle: tr('Как установлено на телефоне'),
                value: ThemeMode.system,
                selected: provider.themeMode == ThemeMode.system,
              ),
              const SizedBox(height: 8),
              _ThemeChoice(
                title: tr('Светлая'),
                subtitle: tr('Всегда светлое оформление'),
                value: ThemeMode.light,
                selected: provider.themeMode == ThemeMode.light,
              ),
              const SizedBox(height: 8),
              _ThemeChoice(
                title: tr('Тёмная'),
                subtitle: tr('Всегда тёмное оформление'),
                value: ThemeMode.dark,
                selected: provider.themeMode == ThemeMode.dark,
              ),
            ],
          ),
        ),
      );
    },
  );
}

Future<void> _confirmClearCache(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(tr('Очистить кэш?')),
        content: Text(
          tr('Временные изображения и загруженные файлы будут удалены. Аккаунт, PIN-код, автомобили и настройки останутся.'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(tr('Отмена')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(tr('Очистить')),
          ),
        ],
      );
    },
  );

  if (confirmed != true || !context.mounted) return;

  try {
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
    await DefaultCacheManager().emptyCache();

    if (!context.mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(tr('Кэш успешно очищен'))));
  } catch (_) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(tr('Не удалось полностью очистить кэш'))),
    );
  }
}

class _ThemeChoice extends StatelessWidget {
  const _ThemeChoice({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.selected,
  });

  final String title;
  final String subtitle;
  final ThemeMode value;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color:
          selected
              ? scheme.primary.withValues(alpha: 0.10)
              : scheme.surfaceContainerHighest.withValues(alpha: 0.45),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () async {
          await context.read<ThemeProvider>().setThemeMode(value);

          if (context.mounted) {
            Navigator.of(context).pop();
          }
        },
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
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? scheme.primary : Colors.transparent,
                  border: Border.all(
                    color: selected ? scheme.primary : scheme.outlineVariant,
                    width: 2,
                  ),
                ),
                alignment: Alignment.center,
                child:
                    selected
                        ? const Text(
                          '✓',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        )
                        : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppVersionFooter extends StatefulWidget {
  const _AppVersionFooter();

  @override
  State<_AppVersionFooter> createState() => _AppVersionFooterState();
}

class _AppVersionFooterState extends State<_AppVersionFooter> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();

      if (!mounted) return;

      setState(() {
        _version = info.version;
      });
    } catch (_) {
      // Версия просто не показывается, если платформа её не вернула.
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_version.isEmpty) {
      return const SizedBox.shrink();
    }

    final secondary = Theme.of(context).colorScheme.onSurfaceVariant;

    return Center(
      child: Column(
        children: [
          Image.asset(
            'assets/logo.png',
            width: 74,
            height: 34,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 6),
          Text(
            'AG Service',
            style: TextStyle(
              color: secondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            trf('Версия {0}', [_version]),
            style: TextStyle(
              color: secondary.withValues(alpha: 0.75),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileSectionTitle extends StatelessWidget {
  const _ProfileSectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          letterSpacing: 1.4,
          fontWeight: FontWeight.w800,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF14181E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: dark ? const Color(0xFF262D36) : const Color(0xFFEDEFF2)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: dark ? .25 : .045), blurRadius: 24, offset: const Offset(0, 10))],
      ),
      child: Column(children: children),
    );
  }
}

class _ProfileDivider extends StatelessWidget {
  const _ProfileDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 72),
      child: Divider(
        height: 1,
        thickness: 1,
        color: Theme.of(context).colorScheme.outlineVariant,
      ),
    );
  }
}

class _ProfileItem extends StatelessWidget {
  const _ProfileItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badge,
    this.accent = false,
  });

  final String icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final String? badge;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              _AgTile(title: title, asset: icon), // AG_PROF6
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.3,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (badge != null) ...[
                const SizedBox(width: 8),
                Container(
                  constraints: const BoxConstraints(minWidth: 24),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: BrandColors.orange,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    badge!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
              const SizedBox(width: 8),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .05),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: AgIcon('<path d="M9 6l6 6-6 6"/>', size: 15, strokeWidth: 2.4, color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VerifyPhoneDialog extends StatefulWidget {
  const _VerifyPhoneDialog();

  @override
  State<_VerifyPhoneDialog> createState() => _VerifyPhoneDialogState();
}

class _VerifyPhoneDialogState extends State<_VerifyPhoneDialog> {
  final _formKey = GlobalKey<FormState>();
  final _phoneCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  bool _loading = false;
  bool _otpSent = false;
  String? _error;
  int _countdown = 0;
  Timer? _timer;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _codeCtrl.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _countdown = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown == 0) {
        timer.cancel();
      } else {
        setState(() => _countdown--);
      }
    });
  }

  Future<void> _sendOtp() async {
    final phone = _phoneCtrl.text.trim();
    if (phone.length < 5) {
      setState(() => _error = tr('Введите корректный номер'));
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await context.read<AuthProvider>().sendOtp(phone);
      setState(() => _otpSent = true);
      _startTimer();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _verify() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await context.read<AuthProvider>().verifyPhone(
        _phoneCtrl.text.trim(),
        _codeCtrl.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('Телефон успешно подтвержден'))),
      );
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(tr('Подтверждение телефона')),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _phoneCtrl,
                decoration: InputDecoration(
                  hintText: tr('Номер телефона'),
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
                enabled: !_otpSent,
                validator:
                    (v) =>
                        (v == null || v.trim().length < 5)
                            ? tr('Введите телефон')
                            : null,
              ),
              if (_otpSent) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _codeCtrl,
                  decoration: InputDecoration(
                    hintText: tr('Код из SMS'),
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  keyboardType: TextInputType.number,
                  validator:
                      (v) =>
                          (v == null || v.trim().length != 6)
                              ? tr('Введите 6 цифр')
                              : null,
                ),
                if (_countdown > 0) ...[
                  const SizedBox(height: 8),
                  Text(
                    trf('Повторить отправку через {0} сек.', [_countdown]),
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: const TextStyle(
                    color: BrandColors.orange,
                    fontSize: 13,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(tr('Отмена')),
        ),
        if (!_otpSent)
          ElevatedButton(
            onPressed: _loading ? null : _sendOtp,
            style: ElevatedButton.styleFrom(minimumSize: const Size(120, 44)),
            child:
                _loading
                    ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                    : Text(tr('Получить код')),
          )
        else
          ElevatedButton(
            onPressed: _loading ? null : _verify,
            style: ElevatedButton.styleFrom(minimumSize: const Size(120, 44)),
            child:
                _loading
                    ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                    : Text(tr('Подтвердить')),
          ),
      ],
    );
  }
}

// ---------- AG_PROF6: новый вид «Настроек» — цветные SVG-плитки, карточка профиля, карточка входа ----------

class _AgTile extends StatelessWidget { // AG_PROFICON2: двухцветные SVG-иконки, светлая и тёмная тема
  const _AgTile({required this.title, required this.asset});
  final String title;
  final String asset;

  static const Map<String, String> _svg = {
    'personal': '<circle cx="12" cy="8" r="4.2" fill="A"/><path d="M3.8 20.2c.6-4.3 4-7 8.2-7s7.6 2.7 8.2 7c.1.5-.3.8-.8.8H4.6c-.5 0-.9-.3-.8-.8z" fill="B"/><circle cx="10.6" cy="6.8" r="1.2" fill="W" opacity=".55"/>',
    'car': '<path d="M5.2 10.2l1.6-4c.4-1 1.3-1.6 2.3-1.6h5.8c1 0 1.9.6 2.3 1.6l1.6 4" fill="B"/><rect x="2.6" y="9.6" width="18.8" height="7.4" rx="2.4" fill="A"/><rect x="4.2" y="16" width="3.6" height="3.4" rx="1.1" fill="A"/><rect x="16.2" y="16" width="3.6" height="3.4" rx="1.1" fill="A"/><circle cx="6.6" cy="13.2" r="1.4" fill="W"/><circle cx="17.4" cy="13.2" r="1.4" fill="W"/><path d="M8 7.4h8l1 2.4H7z" fill="W" opacity=".5"/>',
    'notifications': '<path d="M12 3a6 6 0 0 0-6 6v3.6l-1.6 2.6c-.4.7.1 1.6.9 1.6h13.4c.8 0 1.3-.9.9-1.6L18 12.6V9a6 6 0 0 0-6-6z" fill="A"/><path d="M9.5 18.6a2.6 2.6 0 0 0 5 0z" fill="B"/><circle cx="18" cy="5.5" r="2.6" fill="B" stroke="W" stroke-width="1.2"/><path d="M8.6 7.6a3.6 3.6 0 0 1 2.2-2" stroke="W" stroke-width="1.4" stroke-linecap="round" fill="none" opacity=".6"/>',
    'gift': '<rect x="3.5" y="8.5" width="17" height="4" rx="1.2" fill="A"/><rect x="4.8" y="12.5" width="14.4" height="8" rx="1.4" fill="B"/><rect x="10.8" y="8.5" width="2.4" height="12" fill="W" opacity=".85"/><path d="M12 8.4c-1.3-3-5.2-4.1-5.6-1.8-.3 1.6 2.3 1.9 5.6 1.8zm0 0c1.3-3 5.2-4.1 5.6-1.8.3 1.6-2.3 1.9-5.6 1.8z" fill="A"/>',
    'message': '<path d="M4 5.5A2.5 2.5 0 0 1 6.5 3h11A2.5 2.5 0 0 1 20 5.5v8a2.5 2.5 0 0 1-2.5 2.5H10l-4.2 3.6c-.5.4-1.2.1-1.2-.6V16A2.5 2.5 0 0 1 4 13.5z" fill="A"/><path d="M7.5 12.2V7.4l4.5 3.6 4.5-3.6v4.8" stroke="W" stroke-width="1.7" stroke-linejoin="round" stroke-linecap="round" fill="none"/>',
    'lock': '<path d="M7.5 10V7.6a4.5 4.5 0 0 1 9 0V10" stroke="B" stroke-width="2.4" fill="none" stroke-linecap="round"/><rect x="4.5" y="9.6" width="15" height="11" rx="3" fill="A"/><circle cx="12" cy="14.4" r="1.7" fill="W"/><rect x="11.2" y="15" width="1.6" height="3" rx=".8" fill="W"/>',
    'globe': '<circle cx="12" cy="12" r="9" fill="A"/><path d="M3.4 9.6c2.2.4 3 1.6 4.6 1.6 1.4 0 1.4 1.8 2.8 2.6 1 .6.6 2.4-.2 3.4-.7.9-.4 2.4.2 3.6A9 9 0 0 1 3.4 9.6zM14.6 3.4c-.6 1.2-.2 2.2 1 2.6 1.3.4 1.4 1.8 2.6 2.2 1 .3 1.9-.1 2.6-.6a9 9 0 0 0-6.2-4.2zM20.4 14.2c-1.2-.4-2.6.2-3.2 1.4-.6 1.1-1.8 1.6-1.6 3 .1.8.4 1.4.8 1.9a9 9 0 0 0 4-6.3z" fill="B"/><circle cx="9" cy="7" r="1.4" fill="W" opacity=".5"/>',
    'theme': '<circle cx="12" cy="12" r="8.6" fill="B"/><path d="M12 3.4a8.6 8.6 0 0 1 0 17.2z" fill="A"/><circle cx="12" cy="12" r="3.4" fill="W"/><path d="M12 8.6a3.4 3.4 0 0 1 0 6.8z" fill="A"/>',
    'refresh': '<path d="M19.5 12a7.5 7.5 0 0 1-13 5.1" stroke="A" stroke-width="2.6" fill="none" stroke-linecap="round"/><path d="M4.5 12a7.5 7.5 0 0 1 13-5.1" stroke="B" stroke-width="2.6" fill="none" stroke-linecap="round"/><path d="M18.6 3.2v4.6H14z" fill="B"/><path d="M5.4 20.8v-4.6H10z" fill="A"/>',
    'cache': '<rect x="4" y="5.6" width="16" height="2.6" rx="1.3" fill="A"/><path d="M9.4 5.6V4.4c0-.8.6-1.4 1.4-1.4h2.4c.8 0 1.4.6 1.4 1.4v1.2" stroke="A" stroke-width="1.8" fill="none"/><path d="M5.6 9.2h12.8l-1 10.2c-.1 1-1 1.6-2 1.6H8.6c-1 0-1.9-.7-2-1.6z" fill="B"/><path d="M10 12v5.6M14 12v5.6" stroke="W" stroke-width="1.7" stroke-linecap="round"/>',
    'doc': '<path d="M6.5 2.8h7.6l4.6 4.6V19a2.2 2.2 0 0 1-2.2 2.2H6.5A2.2 2.2 0 0 1 4.3 19V5a2.2 2.2 0 0 1 2.2-2.2z" fill="A"/><path d="M14.1 2.8v3.4c0 .7.5 1.2 1.2 1.2h3.4z" fill="B"/><path d="M8 11.2h8M8 14.4h8M8 17.6h5" stroke="W" stroke-width="1.6" stroke-linecap="round"/>',
    'info': '<circle cx="12" cy="12" r="9" fill="A"/><circle cx="12" cy="7.6" r="1.5" fill="W"/><rect x="10.7" y="10.4" width="2.6" height="7.4" rx="1.3" fill="W"/><path d="M5.6 9a7 7 0 0 1 3.2-4" stroke="B" stroke-width="1.6" stroke-linecap="round" fill="none"/>',
    'history': '<circle cx="12" cy="12.6" r="8.4" fill="A"/><path d="M12 8v5l3.2 2" stroke="W" stroke-width="2" stroke-linecap="round" fill="none"/><path d="M3 5.6l3.2.4-.6 3" stroke="B" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" fill="none"/>'
  };

  (String, Color, Color) _style() {
    final t = AgI18n.orig(title).toLowerCase(); // AG_I18N1
    if (t.contains('язык')) return ('globe', const Color(0xFF0284C7), const Color(0xFF7DD3FC));
    if (t.contains('личн')) return ('personal', const Color(0xFF2563EB), const Color(0xFF93C5FD));
    if (t.contains('автомоб')) return ('car', const Color(0xFFF26200), const Color(0xFFFFB27A));
    if (t.contains('уведомл')) return ('notifications', const Color(0xFFDC2626), const Color(0xFFFCA5A5));
    if (t.contains('истори')) return ('history', const Color(0xFFDC2626), const Color(0xFFFCA5A5));
    if (t.contains('бонус')) return ('gift', const Color(0xFFF59E0B), const Color(0xFFFCD34D));
    if (t.contains('max')) return ('message', const Color(0xFF4F46E5), const Color(0xFFA5B4FC));
    if (t.contains('безопас')) return ('lock', const Color(0xFF059669), const Color(0xFF6EE7B7));
    if (t.contains('оформл')) return ('theme', const Color(0xFF7C3AED), const Color(0xFFC4B5FD));
    if (t.contains('обновл')) return ('refresh', const Color(0xFF0891B2), const Color(0xFF67E8F9));
    if (t.contains('кэш')) return ('cache', const Color(0xFF64748B), const Color(0xFFCBD5E1));
    if (t.contains('документ')) return ('doc', const Color(0xFF0D9488), const Color(0xFF5EEAD4));
    if (t.contains('о прилож')) return ('info', const Color(0xFFF26200), const Color(0xFFFFB27A));
    return ('info', const Color(0xFF6B7280), const Color(0xFFD1D5DB));
  }

  static String _hex(Color c) => '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final (key, main, light) = _style();
    final body = _svg[key]!
        .replaceAll('"A"', '"${_hex(main)}"')
        .replaceAll('"B"', '"${_hex(light)}"')
        .replaceAll('"W"', '"#FFFFFF"');
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(13),
        color: main.withValues(alpha: dark ? .22 : .12),
        border: Border.all(color: main.withValues(alpha: dark ? .30 : .10)),
      ),
      alignment: Alignment.center,
      child: SvgPicture.string('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">$body</svg>', width: 24, height: 24),
    );
  }
}

class _AgWaves extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;
    for (var i = 0; i < 8; i++) {
      p.color = Colors.white.withValues(alpha: .22 - i * .022);
      final y = s.height * .5 + i * s.height * .07;
      c.drawPath(
          Path()
            ..moveTo(-10, y)
            ..cubicTo(s.width * .3, y - s.height * .3, s.width * .6, y + s.height * .25, s.width + 10, y - s.height * .2),
          p);
    }
    c.drawCircle(Offset(s.width * .95, 0), s.width * .3, Paint()..color = Colors.white.withValues(alpha: .08));
  }

  @override
  bool shouldRepaint(_AgWaves o) => false;
}

BoxDecoration _agHeroDeco() => BoxDecoration(
      borderRadius: BorderRadius.circular(28),
      gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFFFFA24C), Color(0xFFF26200), Color(0xFFB83E00)], stops: [0, .55, 1]),
      boxShadow: [BoxShadow(color: const Color(0xFFC24400).withValues(alpha: .35), blurRadius: 30, offset: const Offset(0, 14))],
    );

class _AgProfileHero extends StatelessWidget {
  const _AgProfileHero({required this.user, required this.initial});
  final dynamic user;
  final String initial;

  Widget _quick(BuildContext context, String path, String label, String value, VoidCallback onTap) => Expanded(
        child: Material(
          color: Colors.white.withValues(alpha: .16),
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
              child: Row(children: [
                AgIcon(path, size: 20, color: Colors.white, strokeWidth: 2),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(label, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.white.withValues(alpha: .85), fontSize: 11.5, fontWeight: FontWeight.w700)),
                    Text(value, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900)),
                  ]),
                ),
              ]),
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final String name = (user.name ?? '').toString();
    final String phone = (user.phone ?? '').toString().trim();
    final String email = (user.email ?? '').toString();
    final String avatar = (user.avatarUrl ?? '').toString().trim();
    final int bonus = (user.bonusPoints as num?)?.toInt() ?? 0;
    _AgBal.load(context); // AG_PROF7
    final initialText = Text(initial, style: const TextStyle(color: Color(0xFFF26200), fontSize: 30, fontWeight: FontWeight.w900));
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: _agHeroDeco(),
      child: CustomPaint(
        painter: _AgWaves(),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              GestureDetector(
                onTap: () => context.push('/profile/personal'),
                child: Stack(clipBehavior: Clip.none, children: [
                  Container(
                    width: 74,
                    height: 74,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: .35)),
                    child: Container(
                      decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                      alignment: Alignment.center,
                      clipBehavior: Clip.antiAlias,
                      child: avatar.isNotEmpty
                          ? Image.network(avatar, width: 68, height: 68, fit: BoxFit.cover, errorBuilder: (_, __, ___) => initialText)
                          : initialText,
                    ),
                  ),
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(color: const Color(0xFF15171C), shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                      alignment: Alignment.center,
                      child: const AgIcon('<path d="M4 8h3l2-3h6l2 3h3a1 1 0 0 1 1 1v10a1 1 0 0 1-1 1H4a1 1 0 0 1-1-1V9a1 1 0 0 1 1-1z"/><circle cx="12" cy="13.5" r="3.6"/>',
                          size: 14, color: Colors.white, strokeWidth: 2.2),
                    ),
                  ),
                ]),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(name.isEmpty ? tr('Клиент AG Service') : name, maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontSize: 20, height: 1.15, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  if (phone.isNotEmpty)
                    Text(phone, style: TextStyle(color: Colors.white.withValues(alpha: .9), fontSize: 14, fontWeight: FontWeight.w600)),
                  if (email.isNotEmpty)
                    Text(email, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white.withValues(alpha: .8), fontSize: 12.5)),
                  if (phone.isEmpty)
                    GestureDetector(
                      onTap: () => showDialog(context: context, builder: (_) => const _VerifyPhoneDialog()),
                      child: Container(
                        margin: const EdgeInsets.only(top: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                        child: Text(tr('Подтвердить телефон'), style: TextStyle(color: Color(0xFFF26200), fontSize: 12.5, fontWeight: FontWeight.w800)),
                      ),
                    ),
                ]),
              ),
            ]),
            const SizedBox(height: 16),
            ValueListenableBuilder<int?>(
              valueListenable: _AgBal.v,
              builder: (context, b, _) => Row(children: [
                _quick(context, '<path d="M4 7a2 2 0 0 1 2-2h11a1 1 0 0 1 1 1v2"/><rect x="3" y="7" width="18" height="13" rx="3"/><path d="M16 13.5h2"/>',
                    tr('Бонусный счёт'), '${_AgBal.fmt(b ?? bonus)} ₽', () => context.push('/profile/referrals')),
                const SizedBox(width: 10),
                _quick(context, '<path d="M5 16V11l2-5h10l2 5v5"/><path d="M3 16h18v3H3zM7 19v2M17 19v2"/>', tr('Гараж'), tr('Мои авто'),
                    () => context.push('/profile/my-cars')),
              ]),
            ),
            const SizedBox(height: 10), // AG_BONUSQR1
            GestureDetector(
              onTap: () => showMyBonusQr(context),
              child: Container(
                height: 50,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const AgIcon('<rect x="3" y="3" width="7" height="7" rx="1"/><rect x="14" y="3" width="7" height="7" rx="1"/><rect x="3" y="14" width="7" height="7" rx="1"/><path d="M14 14h3v3h-3zM20 14v.01M14 20h.01M17 20h4v-3"/>',
                      size: 20, color: Color(0xFFF26200), strokeWidth: 2.2),
                  const SizedBox(width: 8),
                  Text(tr('Оплатить бонусами · Мой QR'), style: const TextStyle(color: Color(0xFFF26200), fontSize: 15, fontWeight: FontWeight.w900)),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _AgGuestHero extends StatelessWidget {
  const _AgGuestHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: _agHeroDeco(),
      child: CustomPaint(
        painter: _AgWaves(),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              alignment: Alignment.center,
              child: const AgIcon('<circle cx="12" cy="8" r="4"/><path d="M4 21a8 8 0 0 1 16 0"/>', size: 26, color: Color(0xFFF26200), strokeWidth: 2),
            ),
            const SizedBox(height: 14),
            Text(tr('Войдите в AG Service'), style: TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text(tr('Записи, автомобили, фото приёмки и бонусный счёт — в одном месте'),
                style: TextStyle(color: Colors.white.withValues(alpha: .9), fontSize: 13.5, height: 1.35)),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: FilledButton(
                    onPressed: () => context.push('/login'),
                    style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xFFF26200),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                    child: Text(tr('Войти'), style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () => context.push('/register'),
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                    child: FittedBox(child: Text(tr('Регистрация'), style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15))),
                  ),
                ),
              ),
            ]),
          ]),
        ),
      ),
    );
  }
}

/// AG_PROF7: баланс бонусного счёта берём с сервера (как на главной), а не из сохранённого профиля.
class _AgBal {
  static final ValueNotifier<int?> v = ValueNotifier<int?>(null);
  static DateTime _at = DateTime(2000);
  static void load(BuildContext context) {
    if (DateTime.now().difference(_at).inSeconds < 15) return;
    _at = DateTime.now();
    try {
      context.read<ApiClient>().get('/api/referrals/summary').then((r) {
        if (r is Map && r['bonus_points'] is num) v.value = (r['bonus_points'] as num).toInt();
      }).catchError((Object _) {});
    } catch (_) {}
  }

  static String fmt(int n) {
    final s = n.abs().toString();
    final b = StringBuffer(n < 0 ? '-' : '');
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write(' ');
      b.write(s[i]);
    }
    return b.toString();
  }
}
