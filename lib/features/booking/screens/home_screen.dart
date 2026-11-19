import 'package:flutter/foundation.dart' show kIsWeb; // AG_WEATHER2
import 'package:geolocator/geolocator.dart'; // AG_WEATHER2
import 'package:http/http.dart' as http; // AG_HDR_E
import 'dart:convert'; // AG_HDR_E
import '../providers/booking_flow_provider.dart'; // AG_QUICKBOOK1
import 'package:mobile/core/promo_splash.dart'; // AG_PROMO1
import '../../../core/update_checker.dart'; // AG_UPD1
import 'package:mobile/features/booking/widgets/news_strip.dart'; // AG_FIX1
import 'package:mobile/core/ag_icon3d.dart'; // AG_UI2
import 'package:mobile/features/booking/data/booking_repository.dart'; // AG_UI2
import 'package:mobile/models/service.dart'; // AG_UI2
import 'package:mobile/features/my_cars/screens/car_form_screen.dart'; // AG_UI2
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/notifications_provider.dart';
import 'service_search_dialog.dart';

import '../../auth/providers/auth_provider.dart';
import '../../my_cars/providers/my_cars_provider.dart';
import '../../../core/ag_icons.dart';
import '../../../core/glass.dart';
import '../../../models/user_car.dart';
import '../providers/company_provider.dart';
import '../providers/referrals_provider.dart';
import '../../../core/i18n.dart'; // AG_I18N1
import '../../../core/ag_levels.dart'; // AG_REFLVL1
import '../../services_hub/services_hub.dart'; // AG_SVCHUB1

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  static const orange = Color(0xFFFF6A00);

  late final AnimationController _bookingAnimation;

  @override
  void initState() {
    super.initState();

    _bookingAnimation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
      lowerBound: 0,
      upperBound: 1,
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CompanyProvider>().loadAll();

      final auth = context.read<AuthProvider>();
      if (auth.isLoggedIn) {
        context.read<ReferralsProvider>().loadSummary(); AgPromoSplash.show(context).whenComplete(() { if (context.mounted) AgUpdateChecker.check(context); }); // AG_UPD1 AG_PROMO1
        context.read<MyCarsProvider>().load();
      }
    });
  }

  @override
  void dispose() {
    _bookingAnimation.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final auth = context.read<AuthProvider>();

    if (auth.isLoggedIn) {
      await Future.wait([
        context.read<ReferralsProvider>().loadSummary(),
        context.read<MyCarsProvider>().load(),
      ]);
    }

    if (!mounted) return; // AG_FIX3
    await context.read<CompanyProvider>().loadAll();
  }

  Color get _orangeSoft {
    return Theme.of(context).brightness == Brightness.dark
        ? orange.withValues(alpha: .14)
        : const Color(0xFFFFF1E7);
  }

  Color get _border {
    return glassEdgeColor(context);
  }

  Color get _muted {
    return Theme.of(context).colorScheme.onSurfaceVariant;
  }

  Widget _svg(String name, {double size = 24, Color? color}) {
    return SvgPicture.asset(
      'assets/icons/home/$name.svg',
      width: size,
      height: size,
      fit: BoxFit.contain,
      colorFilter: ColorFilter.mode(color ?? orange, BlendMode.srcIn),
    );
  }

  void _openSearch() {
    showServiceSearch(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: GlassBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: RefreshIndicator(
                color: orange,
                onRefresh: _refresh,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
                  children: [
                    _header(),
                    const SizedBox(height: 18),

                    _referralBankCard(),
                    const SizedBox(height: 12),

                    _bookingButton(),
                    const SizedBox(height: 18),

                    _quickActions(),
                    const SizedBox(height: 16),

                    const SizedBox(height: 4), // AG_SVCHUB1: баннер «Азия Про» перенесён в раздел «Сервисы»

                    _sectionHeader(
                      tr('Популярные услуги'),
                      action: 'Все',
                      onTap: () => context.push('/services'),
                    ),
                    const SizedBox(height: 12),
                    _serviceBannersRow(),
                    const SizedBox(height: 24),

                    _sectionHeader(
                      tr('Мой гараж'),
                      action: 'Все',
                      onTap: () => context.push('/profile/my-cars'),
                    ),
                    const SizedBox(height: 10),
                    _garage(),
                    const SizedBox(height: 24),

                    _newsPreview(),
                    const SizedBox(height: 24),

                    const ServicesHubSection(), // AG_SVCHUB1
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 5) return tr('Доброй ночи');
    if (h < 12) return tr('Доброе утро');
    if (h < 18) return tr('Добрый день');
    return tr('Добрый вечер');
  }

  // AG_HDR_E: шапка «вариант Е» — бренд слева, уведомления и аватар справа, приветствие с датой и погодой
  Widget _header() {
    final auth = context.watch<AuthProvider>();
    final unreadCount = context.watch<NotificationsProvider>().unreadCount;
    final fullName = (auth.user?.name ?? '').trim();
    final firstName = fullName.isEmpty ? '' : fullName.split(RegExp(r'\s+')).first;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? Colors.white : const Color(0xFF15171C);
    final mut = isDark ? const Color(0xFFAEB1B8) : const Color(0xFF7A7F88);
    const months = ['января', 'февраля', 'марта', 'апреля', 'мая', 'июня', 'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря'];
    const days = ['Понедельник', 'Вторник', 'Среда', 'Четверг', 'Пятница', 'Суббота', 'Воскресенье'];
    final now = DateTime.now();
    final dateText = '${tr(days[now.weekday - 1])}, ${now.day} ${tr(months[now.month - 1])}';

    Widget tile({required Widget child, required VoidCallback onTap, Gradient? gradient}) => Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: Ink(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: gradient == null ? (isDark ? const Color(0xFF1F2227) : Colors.white) : null,
                gradient: gradient,
                borderRadius: BorderRadius.circular(14),
                boxShadow: isDark ? null : [BoxShadow(color: Colors.black.withValues(alpha: .06), blurRadius: 12, offset: const Offset(0, 4))],
              ),
              child: child,
            ),
          ),
        );

    final letter = firstName.isNotEmpty ? firstName.characters.first.toUpperCase() : '';
    void openProfile() => auth.isLoggedIn ? context.go('/profile') : context.push('/login');

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const SizedBox(height: 6),
      Row(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Image.asset('assets/logo.png', width: 44, height: 44, fit: BoxFit.cover),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text('AG Service', maxLines: 1, style: TextStyle(color: ink, fontSize: 19, height: 1.05, fontWeight: FontWeight.w900, letterSpacing: -.3)),
            const SizedBox(height: 2),
            Text(tr('АВТОСЕРВИС · ЕКБ'), maxLines: 1,
                style: const TextStyle(color: Color(0xFFF26200), fontSize: 11, height: 1.1, fontWeight: FontWeight.w800, letterSpacing: .6)),
          ]),
        ),
        tile(
          onTap: () => context.push('/profile/notifications'),
          child: Stack(clipBehavior: Clip.none, children: [
            Center(child: AgIcon(AgIcons.bell, size: 22, color: ink)),
            if (unreadCount > 0)
              Positioned(
                right: 5, top: 4,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 17, minHeight: 17),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF26200),
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: isDark ? const Color(0xFF1F2227) : Colors.white, width: 2),
                  ),
                  child: Text(unreadCount > 99 ? '99+' : '$unreadCount',
                      style: const TextStyle(color: Colors.white, fontSize: 9, height: 1, fontWeight: FontWeight.w900)),
                ),
              ),
          ]),
        ),
        const SizedBox(width: 8),
        tile(
          onTap: openProfile,
          gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFFFD7B8), Color(0xFFFFB27A)]),
          child: Center(
            child: letter.isNotEmpty
                ? Text(letter, style: const TextStyle(color: Color(0xFF8A3B00), fontSize: 18, fontWeight: FontWeight.w900))
                : const Icon(Icons.person_rounded, color: Color(0xFF8A3B00), size: 24),
          ),
        ),
      ]),
      const SizedBox(height: 14),
      Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: openProfile,
          child: Ink(
            padding: const EdgeInsets.fromLTRB(16, 13, 14, 13),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: isDark ? const [Color(0xFF1F2227), Color(0xFF2A2119)] : const [Colors.white, Color(0xFFFFF1E4)],
              ),
              boxShadow: isDark ? null : [BoxShadow(color: const Color(0xFFF26200).withValues(alpha: .07), blurRadius: 16, offset: const Offset(0, 6))],
            ),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(firstName.isNotEmpty ? '${_greeting()}, $firstName' : _greeting(),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: ink, fontSize: 20, height: 1.15, fontWeight: FontWeight.w900, letterSpacing: -.4)),
                  const SizedBox(height: 3),
                  Text(dateText, style: TextStyle(color: mut, fontSize: 13, fontWeight: FontWeight.w600)),
                ]),
              ),
              const SizedBox(width: 10),
              _AgWeather(ink: ink),
            ]),
          ),
        ),
      ),
    ]);
  }

  Widget _referralBankCard() {
    return _Pressable(pressedScale: 0.98, child: _referralBankCardBase());
  }

  // AG_PARK1: баннер «Подключение к парку Азия Про»
  Widget _parkBanner() {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return _Pressable(
      pressedScale: 0.98,
      child: GestureDetector(
        onTap: () => context.push('/park'),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
          decoration: BoxDecoration(
            color: dark ? const Color(0xFF1B1E22) : Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFF26200).withValues(alpha: .28)),
            boxShadow: [BoxShadow(color: const Color(0xFFF26200).withValues(alpha: dark ? .0 : .10), blurRadius: 18, offset: const Offset(0, 8))],
          ),
          child: Row(children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(colors: [Color(0xFFFFB13D), Color(0xFFF26200)]),
              ),
              child: const Icon(Icons.local_taxi_rounded, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(tr('Подключение к парку «Азия Про»'), style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w900, letterSpacing: -.2)),
                const SizedBox(height: 2),
                Text(tr('Оставьте заявку — менеджер перезвонит'),
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ]),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFFF26200), size: 26),
          ]),
        ),
      ),
    );
  }

  Widget _referralBankCardBase() {
    final auth = context.watch<AuthProvider>();
    final referrals = context.watch<ReferralsProvider>();
    final summary = referrals.summary;

    final points = summary?.bonusPoints ?? auth.user?.bonusPoints ?? 0;
    final invited = summary?.referrals.length ?? 0;
    final code = summary?.referralCode ?? '—';

    late final String rank;
    late final String rankIcon;
    late final int? nextAt;
    late final String? nextName;
    late final int levelStart;

    if (invited >= 25) {
      rank = 'AG ELITE';
      rankIcon = 'assets/icons/bonus_levels/elite.svg';
      nextAt = null;
      nextName = null;
      levelStart = 25;
    } else if (invited >= 18) {
      rank = 'DIAMOND';
      rankIcon = 'assets/icons/bonus_levels/diamond.svg';
      nextAt = 25;
      nextName = 'AG ELITE';
      levelStart = 18;
    } else if (invited >= 13) {
      rank = 'PLATINUM';
      rankIcon = 'assets/icons/bonus_levels/platinum.svg';
      nextAt = 18;
      nextName = 'DIAMOND';
      levelStart = 13;
    } else if (invited >= 10) {
      rank = 'GOLD';
      rankIcon = 'assets/icons/bonus_levels/gold.svg';
      nextAt = 13;
      nextName = 'PLATINUM';
      levelStart = 10;
    } else if (invited >= 5) {
      rank = 'SILVER';
      rankIcon = 'assets/icons/bonus_levels/silver.svg';
      nextAt = 10;
      nextName = 'GOLD';
      levelStart = 5;
    } else {
      rank = 'BRONZE';
      rankIcon = 'assets/icons/bonus_levels/bronze.svg';
      nextAt = 5;
      nextName = 'SILVER';
      levelStart = 0;
    }

    final double progress;

    if (nextAt == null) {
      progress = 1;
    } else {
      final range = nextAt - levelStart;
      final current = invited - levelStart;
      progress = (current / range).clamp(0.0, 1.0);
    }

    if (!auth.isLoggedIn) {
      return _bonusGuestCard();
    }

    // AG_BONUSCARD1: новая банковская карта AG BONUS (чип, светлая/тёмная тема)
    return _AgBonusCard(
      points: points,
      invited: invited,
      code: code,
      rank: rank,
      rankIcon: rankIcon,
      progress: progress,
      nextAt: nextAt,
      nextName: nextName,
      onInvite: () => context.push('/profile/referrals'),
      onRules: _showAgBonusRules,
    );
  }

  Widget _bonusGuestCard() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .18),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(28),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push('/login'),
          child: Container(
            foregroundDecoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white.withValues(alpha: .14)),
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF2B2C33), Color(0xFF17181C), Color(0xFF111114)],
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -70,
                  top: -90,
                  child: Container(
                    width: 260,
                    height: 260,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          orange.withValues(alpha: .55),
                          orange.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFFFF8A2B), Color(0xFFF05A00)],
                              ),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const AgIcon(
                              AgIcons.wallet,
                              size: 23,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 11),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'AG BONUS',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: .8,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  tr('Бонусная карта'),
                                  style: TextStyle(
                                    color: Color(0xFFB4B6BD),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 11,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: orange.withValues(alpha: .18),
                              borderRadius: BorderRadius.circular(13),
                              border: Border.all(
                                color: orange.withValues(alpha: .32),
                              ),
                            ),
                            child: Text(
                              tr('+300 ₽ за друга'),
                              style: TextStyle(
                                color: Color(0xFFFFB27A),
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        tr('Приглашайте друзей\nи копите бонусы'),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          height: 1.15,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        tr('Войдите и получайте 300 ₽ за друзей'),
                        style: TextStyle(
                          color: Color(0xFFB4B6BD),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        height: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              tr('Войти'),
                              style: TextStyle(
                                color: Color(0xFFA83200),
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            SizedBox(width: 7),
                            AgIcon(
                              AgIcons.arrowRight,
                              size: 17,
                              color: Color(0xFFA83200),
                              strokeWidth: 2.2,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAgBonusRules() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final background = isDark ? const Color(0xFF171717) : Colors.white;
        final primary = isDark ? Colors.white : const Color(0xFF181818);
        final secondary =
            isDark ? const Color(0xFFA8A8A8) : const Color(0xFF707070);

        return SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 22),
            decoration: BoxDecoration(
              color: background,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(30),
              ),
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: secondary.withValues(alpha: .30),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: orange.withValues(alpha: .12),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.workspace_premium_rounded,
                          color: orange,
                          size: 27,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tr('Правила AG BONUS'),
                              style: TextStyle(
                                color: primary,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              tr('Приглашайте друзей и получайте бонусы'),
                              style: TextStyle(color: secondary, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 22),

                  _agBonusRuleItem(
                    icon: Icons.person_add_alt_1_rounded,
                    title: tr('300 ₽ за приглашённого'),
                    text:
                        tr('За каждого успешно приглашённого участника начисляется 300 ₽ на бонусный баланс.'),
                  ),

                  _agBonusRuleItem(
                    icon: Icons.link_rounded,
                    title: tr('Реферальный код'),
                    text:
                        tr('Приглашённый участник должен зарегистрироваться по вашему реферальному коду.'),
                  ),

                  _agBonusRuleItem(
                    icon: Icons.trending_up_rounded,
                    title: tr('Повышайте статус'),
                    text:
                        tr('Чем больше участников вы пригласите, тем выше будет ваш статус AG BONUS.'),
                  ),

                  _agBonusRuleItem(
                    icon: Icons.account_balance_wallet_rounded,
                    title: tr('Вывод бонусов'),
                    text:
                        tr('С бонусного баланса можно снять до 20% доступной суммы.'),
                    highlight: true,
                  ),

                  _agBonusRuleItem(
                    icon: Icons.verified_user_rounded,
                    title: tr('Проверка начислений'),
                    text:
                        tr('При отмене, ошибочной регистрации или нарушении условий начисленный бонус может быть отменён.'),
                  ),

                  const SizedBox(height: 8),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: () => Navigator.of(sheetContext).pop(),
                      style: FilledButton.styleFrom(
                        backgroundColor: orange,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(17),
                        ),
                      ),
                      child: Text(
                        tr('Понятно'),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _agBonusRuleItem({
    required IconData icon,
    required String title,
    required String text,
    bool highlight = false,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final titleColor = isDark ? Colors.white : const Color(0xFF202020);
    final textColor =
        isDark ? const Color(0xFFA5A5A5) : const Color(0xFF727272);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:
            highlight
                ? orange.withValues(alpha: .10)
                : isDark
                ? Colors.white.withValues(alpha: .04)
                : const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color:
              highlight
                  ? orange.withValues(alpha: .22)
                  : isDark
                  ? Colors.white.withValues(alpha: .05)
                  : const Color(0xFFEEEEEE),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: orange.withValues(alpha: .11),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: orange),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: highlight ? orange : titleColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  text,
                  style: TextStyle(
                    color: textColor,
                    height: 1.4,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bankStat(String icon, String label, String value) {
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .07),
            borderRadius: BorderRadius.circular(10),
          ),
          child: _svg(icon, size: 17, color: const Color(0xFFFF8A3D)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF909090),
                  fontSize: 12.5,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _bookingButton() {
    return _Pressable(pressedScale: 0.97, child: _bookingButtonBase());
  }

  Widget _bookingButtonBase() {
    return AnimatedBuilder(
      animation: _bookingAnimation,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_bookingAnimation.value);

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: orange.withValues(
                  alpha: (Theme.of(context).brightness == Brightness.dark ? .26 : .14) + (t * .08),
                ),
                blurRadius: 15 + (t * 7),
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: child,
        );
      },
      child: Material(
        color: orange,
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () {
            final auth = context.read<AuthProvider>();

            if (!auth.isLoggedIn) {
              context.push('/login');
              return;
            }

            context.read<BookingFlowProvider>().reset();
            context.push('/booking/start'); // AG_QUICKBOOK1: сначала дата и время
          },
          child: Container(
            height: 66,
            padding: const EdgeInsets.symmetric(horizontal: 15),
            foregroundDecoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white.withValues(alpha: .30)),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withValues(alpha: .22),
                  Colors.white.withValues(alpha: 0),
                ],
                stops: const [0, .55],
              ),
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [Color(0xFFFF7200), Color(0xFFFF5700)],
              ),
            ),
            // AG_BOOKBTN1 + AG_BOOKBTN2: «ЗАПИСАТЬСЯ» по центру, слева календарь, справа стрелка
            child: Stack(
              alignment: Alignment.center,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: 42,
                    height: 42,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .18),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withValues(alpha: .22)),
                    ),
                    child: const AgIcon(
                      AgIcons.calendar,
                      size: 23,
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 52),
                  child: Text(
                    tr('ЗАПИСАТЬСЯ'),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .18),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const AgIcon(
                      AgIcons.arrowRight,
                      size: 19,
                      color: Colors.white,
                      strokeWidth: 2.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, {String? action, VoidCallback? onTap}) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -.4,
            ),
          ),
        ),
        if (action != null)
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
              child: Text(
                action,
                style: const TextStyle(
                  color: orange,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _garage() {
    final auth = context.watch<AuthProvider>();
    final provider = context.watch<MyCarsProvider>();

    if (!auth.isLoggedIn) {
      return _garageGuest();
    }

    if (provider.cars.isEmpty) {
      return _garageEmpty();
    }

    final cars = provider.cars;

    // AG_UI2: в гараже на главной — одна машина, остальные по кнопке
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, c) => SizedBox(
            width: c.maxWidth,
            child: _carMiniCard(cars.first),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            if (cars.length > 1) ...[
              Expanded(
                child: _garageButton(
                  label: trf('Все машины · {0}', [cars.length]),
                  icon: Icons.directions_car_filled_rounded,
                  filled: false,
                  onTap: () => context.push('/profile/my-cars'),
                ),
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: _garageButton(
                label: tr('Добавить машину'),
                icon: Icons.add_rounded,
                filled: true,
                onTap: _addCar,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _addCar() async {
    await Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute<void>(builder: (_) => const CarFormScreen()),
    );
    if (!mounted) return;
    await context.read<MyCarsProvider>().load();
  }

  Widget _garageButton({
    required String label,
    required IconData icon,
    required bool filled,
    required VoidCallback onTap,
  }) {
    return _Pressable(
      pressedScale: 0.97,
      child: Material(
        color: filled ? orange : _orangeSoft,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 46,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 19, color: filled ? Colors.white : orange),
                const SizedBox(width: 7),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: filled ? Colors.white : orange,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _garageGuest() {
    return _garageMessage(
      title: tr('Ваш гараж'),
      subtitle: tr('Войдите, чтобы добавить автомобиль'),
      onTap: () => context.push('/login'),
    );
  }

  Widget _garageEmpty() {
    return _garageMessage(
      title: tr('Добавьте автомобиль'),
      subtitle: tr('VIN, марка, модель и госномер'),
      onTap: () => context.push('/profile/my-cars'),
    );
  }

  Widget _garageMessage({
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GlassSurface(
      radius: 22,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          height: 88,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: _border),
          ),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _orangeSoft,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Image.asset(
                  'assets/home_v3/skoda_rapid.png',
                  width: 55,
                  height: 42,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: _muted, fontSize: 12.5),
                    ),
                  ],
                ),
              ),
              _svg('arrow', size: 18, color: _muted),
            ],
          ),
        ),
      ),
    );
  }

  static const Set<String> _carLogoSlugs = {
    '9ff',
    'abadal',
    'abarth',
    'abbott-detroit',
    'abt',
    'ac',
    'acura',
    'aiways',
    'aixam',
    'alfa-romeo',
    'alpina',
    'alpine',
    'alta',
    'alvis',
    'amc',
    'apollo',
    'arash',
    'arcfox',
    'ariel',
    'aro',
    'arrinera',
    'arrival',
    'artega',
    'ascari',
    'askam',
    'aspark',
    'aston-martin',
    'atalanta',
    'auburn',
    'audi',
    'audi-sport',
    'austin',
    'autobacs',
    'autobianchi',
    'axon',
    'bac',
    'baic-motor',
    'baojun',
    'beiben',
    'bentley',
    'berkeley',
    'berliet',
    'bertone',
    'bestune',
    'bharatbenz',
    'bitter',
    'bizzarrini',
    'bmw',
    'bmw-m',
    'borgward',
    'bowler',
    'brabus',
    'brammo',
    'brilliance',
    'bristol',
    'brooke',
    'bufori',
    'bugatti',
    'buick',
    'byd',
    'byton',
    'cadillac',
    'camc',
    'canoo',
    'caparo',
    'carlsson',
    'caterham',
    'changan',
    'changfeng',
    'chery',
    'chevrolet',
    'chevrolet-corvette',
    'chrysler',
    'cisitalia',
    'citroen',
    'cizeta',
    'cole',
    'corre-la-licorne',
    'cupra',
    'dacia',
    'daewoo',
    'daf',
    'daihatsu',
    'daimler',
    'dartz',
    'datsun',
    'david-brown',
    'dayun',
    'delage',
    'desoto',
    'de-tomaso',
    'detroit-electric',
    'devel-sixteen',
    'diatto',
    'dina',
    'dkw',
    'dmc',
    'dodge',
    'dodge-viper',
    'dongfeng',
    'donkervoort',
    'drako',
    'ds',
    'duesenberg',
    'eagle',
    'edag',
    'edsel',
    'eicher',
    'elemental',
    'elfin',
    'elva',
    'englon',
    'erf',
    'eterniti',
    'exeed',
    'facel-vega',
    'faraday-future',
    'faw',
    'faw-jiefang',
    'ferrari',
    'fiat',
    'fioravanti',
    'fisker',
    'foden',
    'force-motors',
    'ford',
    'ford-mustang',
    'foton',
    'fpv',
    'franklin',
    'freightliner',
    'fso',
    'gac-group',
    'gardner-douglas',
    'gaz',
    'geely',
    'general-motors',
    'genesis',
    'geo',
    'geometry',
    'gilbern',
    'gillet',
    'ginetta',
    'gmc',
    'golden-dragon',
    'gonow',
    'great-wall',
    'grinnall',
    'gumpert',
    'hafei',
    'haima',
    'haval',
    'hawtai',
    'hennessey',
    'higer',
    'hillman',
    'hindustan-motors',
    'hino',
    'hiphi',
    'hispano-suiza',
    'holden',
    'hommell',
    'honda',
    'hongqi',
    'hongyan',
    'horch',
    'hsv',
    'hudson',
    'hummer',
    'hupmobile',
    'hyundai',
    'ic-bus',
    'ih',
    'ikco',
    'infiniti',
    'innocenti',
    'intermeccanica',
    'international',
    'irizar',
    'isdera',
    'iso',
    'isuzu',
    'iveco',
    'jac',
    'jaguar',
    'jawa',
    'jba-motors',
    'jeep',
    'jensen',
    'jetour',
    'jetta',
    'jmc',
    'kaiser',
    'kamaz',
    'karlmann-king',
    'karma',
    'keating',
    'kenworth',
    'kia',
    'king-long',
    'koenigsegg',
    'ktm',
    'lada',
    'lagonda',
    'lamborghini',
    'lancia',
    'land-rover',
    'landwind',
    'laraki',
    'leapmotor',
    'levc',
    'lexus',
    'leyland',
    'li-auto',
    'lifan',
    'ligier',
    'lincoln',
    'lister',
    'lloyd',
    'lobini',
    'lordstown',
    'lotus',
    'lucid',
    'luxgen',
    'lynk-and-co',
    'mack',
    'mahindra',
    'man',
    'mansory',
    'marcos',
    'marlin',
    'maserati',
    'mastretta',
    'maxus',
    'maybach',
    'maz',
    'mazda',
    'mazzanti',
    'mclaren',
    'melkus',
    'mercedes-amg',
    'mercedes-benz',
    'mercury',
    'merkur',
    'mev',
    'mg',
    'microcar',
    'mini',
    'mitsubishi',
    'mitsuoka',
    'mk',
    'morgan',
    'morris',
    'mosler',
    'navistar',
    'nevs',
    'nikola',
    'nio',
    'nissan',
    'nissan-gt-r',
    'nissan-nismo',
    'noble',
    'oldsmobile',
    'oltcit',
    'omoda',
    'opel',
    'osca',
    'paccar',
    'packard',
    'pagani',
    'panhard',
    'panoz',
    'pegaso',
    'perodua',
    'peterbilt',
    'peugeot',
    'pgo',
    'pierce-arrow',
    'pininfarina',
    'plymouth',
    'polestar',
    'pontiac',
    'porsche',
    'praga',
    'premier',
    'prodrive',
    'proton',
    'qoros',
    'radical',
    'ram',
    'rambler',
    'ranz',
    'renault',
    'renault-samsung',
    'rezvani',
    'riley',
    'rimac',
    'rinspeed',
    'rivian',
    'roewe',
    'rolls-royce',
    'ronart',
    'rossion',
    'rover',
    'ruf',
    'saab',
    'saic-motor',
    'saipa',
    'saleen',
    'saturn',
    'scania',
    'scion',
    'seat',
    'setra',
    'sev',
    'shacman',
    'simca',
    'singer',
    'singulato',
    'sinotruk',
    'sisu',
    'skoda',
    'smart',
    'soueast',
    'spania-gta',
    'spirra',
    'spyker',
    'ssangyong',
    'ssc',
    'sterling',
    'studebaker',
    'stutz',
    'subaru',
    'suffolk',
    'suzuki',
    'talbot',
    'tata',
    'tatra',
    'tauro',
    'techart',
    'tesla',
    'toyota',
    'toyota-alphard',
    'toyota-century',
    'toyota-crown',
    'tramontana',
    'trion',
    'triumph',
    'troller',
    'tucker',
    'tvr',
    'uaz',
    'ud',
    'ultima',
    'vandenbrink',
    'vauxhall',
    'vector',
    'vencer',
    'venturi',
    'venucia',
    'vinfast',
    'vlf',
    'volkswagen',
    'volvo',
    'wanderer',
    'wartburg',
    'weltmeister',
    'western-star',
    'westfield',
    'wey',
    'wiesmann',
    'willys-overland',
    'w-motors',
    'workhorse',
    'wuling',
    'xpeng',
    'yulon',
    'yutong',
    'zarooq-motors',
    'zastava',
    'zaz',
    'zeekr',
    'zenos',
    'zenvo',
    'zhongtong',
    'zinoro',
    'zotye',
  };

  String? _carLogoSlug(String title) {
    var value = title.trim().toLowerCase();

    final replacements = <String, String>{
      'š': 's',
      'Š': 's',
      'ё': tr('е'),
      'а': 'a',
      'б': 'b',
      'в': 'v',
      'г': 'g',
      'д': 'd',
      'е': 'e',
      'ж': 'zh',
      'з': 'z',
      'и': 'i',
      'й': 'y',
      'к': 'k',
      'л': 'l',
      'м': 'm',
      'н': 'n',
      'о': 'o',
      'п': 'p',
      'р': 'r',
      'с': 's',
      'т': 't',
      'у': 'u',
      'ф': 'f',
      'х': 'kh',
      'ц': 'ts',
      'ч': 'ch',
      'ш': 'sh',
      'щ': 'shch',
      'ы': 'y',
      'э': 'e',
      'ю': 'yu',
      'я': 'ya',
      'ь': '',
      'ъ': '',
    };

    for (final entry in replacements.entries) {
      value = value.replaceAll(entry.key, entry.value);
    }

    value = value
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');

    const aliases = <String, String>{
      'mersedes': 'mercedes-benz',
      'mersedes-bents': 'mercedes-benz',
      'mercedes': 'mercedes-benz',
      'mercedes-benz': 'mercedes-benz',
      'folksvagen': 'volkswagen',
      'folkswagen': 'volkswagen',
      'volkswagen': 'volkswagen',
      'shkoda': 'skoda',
      'skoda': 'skoda',
      'henday': 'hyundai',
      'khenday': 'hyundai',
      'hyundai': 'hyundai',
      'tayota': 'toyota',
      'toyota': 'toyota',
      'kia': 'kia',
      'bmv': 'bmw',
      'bmw': 'bmw',
      'shevrole': 'chevrolet',
      'chevrolet': 'chevrolet',
      'reno': 'renault',
      'renault': 'renault',
      'lada': 'lada',
      'vaz': 'lada',
      'nisan': 'nissan',
      'nissan': 'nissan',
      'mitsubisi': 'mitsubishi',
      'mitsubishi': 'mitsubishi',
      'leksus': 'lexus',
      'lexus': 'lexus',
    };

    final words = value.split('-');

    // Ищем марку в начале названия, не включая модель.
    for (var length = words.length; length >= 1; length--) {
      final candidate = words.take(length).join('-');
      final normalized = aliases[candidate] ?? candidate;
      if (_carLogoSlugs.contains(normalized)) {
        return normalized;
      }
    }

    return null;
  }

  Widget _carBrandLogo(String title, {double size = 58}) {
    final slug = _carLogoSlug(title);

    if (slug == null) {
      return _svg('car', size: size * .62);
    }

    return Image.asset(
      'assets/car_logos/$slug.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      errorBuilder: (context, error, stackTrace) {
        return _svg('car', size: size * .62);
      },
    );
  }

  Widget _carMiniCard(UserCar car) {
    return _Pressable(child: _carMiniCardBase(car));
  }

  Widget _carMiniCardBase(UserCar car) {
    return GlassSurface(
      radius: 22,
      child: InkWell(
        onTap: () => context.push('/profile/my-cars'),
        borderRadius: BorderRadius.circular(22),
        child: Container(
          height: 104,
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: _border),
          ),
          child: Row(
            children: [
              Container(
                width: MediaQuery.sizeOf(context).width < 600 ? 66.0 : 82.0,
                height: MediaQuery.sizeOf(context).width < 600 ? 66.0 : 82.0,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  // AG_LOGODARK1: в тёмной теме логотип на светлой плашке, иначе тёмные буквы не видно
                  color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFFF3F4F6) : _orangeSoft,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: _carBrandLogo(
                  car.title,
                  size: MediaQuery.sizeOf(context).width < 600 ? 60.0 : 76.0,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      car.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.08,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      [
                        if (car.year != null) '${car.year}',
                        if (car.licensePlate?.trim().isNotEmpty == true)
                          car.licensePlate!.trim(),
                      ].join('  •  '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              _svg('arrow', size: 16, color: _muted),
            ],
          ),
        ),
      ),
    );
  }

  Widget _addCarCard() {
    return Center(
      child: _Pressable(
        pressedScale: 0.94,
        child: Material(
          color: _orangeSoft,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            onTap: () => context.push('/profile/my-cars'),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 80,
              height: 88,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: orange.withValues(alpha: .25),
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: orange,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: orange.withValues(alpha: .30),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.add_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    tr('Добавить'),
                    style: TextStyle(
                      color: orange,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
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

  Widget _quickActions() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _quickAction(
            icon: AgIcons.wrench,
            title: tr('Статус ремонта'),
            onTap: () => context.push('/repair'),
          ),
        ),
        Expanded(
          child: _quickAction(
            icon: AgIcons.calendar,
            title: tr('Мои записи'),
            onTap: () => context.go('/bookings'),
          ),
        ),
        Expanded(
          child: _quickAction(
            icon: AgIcons.tag,
            title: tr('Услуги и цены'),
            onTap: () => context.push('/services'),
          ),
        ),
        Expanded(
          child: _quickAction(
            icon: AgIcons.bulb,
            title: tr('Советы мастера'),
            onTap: () => context.push('/recommendations'),
          ),
        ),
      ],
    );
  }

  Widget _quickAction({
    required String icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return _Pressable(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          children: [
            GlassSurface(
              radius: 21,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(21),
                child: Container(
                  width: 60,
                  height: 60,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(21),
                    border: Border.all(color: _border),
                  ),
                  // AG_QICON1: иконка-картинка с сервера (меняется без обновления приложения); нет — прежняя 3D
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.network(
                      'https://job.autogrom.ru/svc_img/quick/${AgIcon3D.kindFor(icon) ?? 'none'}.png?v=1',
                      width: 60, height: 60, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Center(child: AgIcon3D.orLine(icon, size: 42, color: orange)),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Text(
                title,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.2,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _newsPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // AG_PROMO2: «Акции» — квадратные карточки, стрелка открывает все акции и новости
        InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => context.push('/news'),
          child: Row(children: [
            Expanded(child: Text(tr('Акции'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -.4))),
            const Icon(Icons.chevron_right_rounded, size: 28),
          ]),
        ),
        const SizedBox(height: 12),
        AgPromoSquares(fallback: SizedBox( // AG_FIX1: настоящие новости и акции из AG Service
          height: 126,
          child: ListView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            children: [
              _promoBanner(
                tr('Акции'),
                tr('Специальные предложения для клиентов'),
                AgIcons.percent,
              ),
              const SizedBox(width: 10),
              _promoBanner(
                'AG Service',
                tr('Новости нашего автосервиса'),
                AgIcons.wrench,
              ),
              const SizedBox(width: 10),
              _promoBanner(
                tr('Онлайн-запись'),
                tr('Запишитесь на удобное время'),
                AgIcons.calendar,
              ),
              const SizedBox(width: 10),
              _promoBanner('AG Bonus', tr('Бонусы и предложения'), AgIcons.wallet),
            ],
          ),
        )),
      ],
    );
  }

  // Баннеры услуг в разделе «Новости и акции».
  // На экране помещаются три, остальные листаются вбок.
  // Нажатие открывает шторку с информацией об услуге.
  // Тексты и состав услуг меняются в этом списке.
  static List<_ServiceBanner> get _serviceBanners => <_ServiceBanner>[
    _ServiceBanner(
      title: tr('Замена масла'),
      img: 'oil', // AG_POP1
      caption: tr('Масло и фильтр'),
      icon: AgIcons.oil,
      color: Color(0xFFFF6A00),
      about:
          tr('Свежее масло защищает двигатель от износа и перегрева. Подбираем масло по допускам производителя автомобиля.'),
      includes: [
        tr('Слив отработанного масла'),
        tr('Замена масляного фильтра'),
        tr('Заливка нового масла по уровню'),
        tr('Проверка на подтёки'),
      ],
      whenNeeded:
          tr('Обычно каждые 7–10 тыс. км или раз в год. Точный интервал зависит от автомобиля.'),
    ),
    _ServiceBanner(
      title: tr('Техническое обслуживание'),
      caption: tr('Плановое ТО'),
      icon: AgIcons.wrench,
      color: Color(0xFF2F7BFF),
      img: 'to',
      about:
          tr('Плановое ТО по регламенту производителя: меняем расходники и проверяем узлы, чтобы автомобиль не подвёл в дороге.'),
      includes: [
        tr('Замена масла и фильтров'),
        tr('Проверка подвески и тормозов'),
        tr('Проверка технических жидкостей'),
        tr('Отметка в сервисной книжке'),
      ],
      whenNeeded:
          tr('Каждые 10–15 тыс. км или раз в год — по регламенту вашего автомобиля.'),
    ),
    _ServiceBanner(
      title: tr('Шиномонтаж'),
      img: 'tire', // AG_POP1
      caption: tr('Смена шин'),
      icon: AgIcons.tire,
      color: Color(0xFF19B87A),
      about:
          tr('Аккуратно переобуем автомобиль и отбалансируем колёса, чтобы не было вибраций на скорости.'),
      includes: [
        tr('Снятие и установка колёс'),
        tr('Монтаж шин на диски'),
        tr('Балансировка'),
        tr('Проверка давления'),
      ],
      whenNeeded: tr('При сезонной смене шин, проколе или вибрации на руле.'),
    ),
    _ServiceBanner(
      title: tr('Диагностика'),
      img: 'diag', // AG_POP1
      caption: tr('Поиск причин'),
      icon: AgIcons.pulse,
      color: Color(0xFF8B5CF6),
      about:
          tr('Находим причину неисправности до того, как она превратится в дорогой ремонт.'),
      includes: [
        tr('Компьютерная диагностика'),
        tr('Осмотр подвески и тормозов'),
        tr('Проверка технических жидкостей'),
        tr('Рекомендации мастера'),
      ],
      whenNeeded:
          tr('Перед покупкой автомобиля, дальней поездкой или если загорелся индикатор на панели.'),
    ),
    _ServiceBanner(
      title: tr('Тормозная система'),
      img: 'brake', // AG_POP1
      caption: tr('Колодки, диски'),
      icon: AgIcons.brake,
      color: Color(0xFFF0443E),
      about:
          tr('Исправные тормоза — это короткий тормозной путь и уверенность в любой ситуации.'),
      includes: [
        tr('Проверка колодок и дисков'),
        tr('Замена изношенных деталей'),
        tr('Замена тормозной жидкости'),
        tr('Проверка шлангов и суппортов'),
      ],
      whenNeeded:
          tr('При скрипе, биении педали или если тормозной путь стал длиннее.'),
    ),
    _ServiceBanner(
      title: tr('Кондиционер'),
      img: 'ac', // AG_POP1
      caption: tr('Заправка'),
      icon: AgIcons.snow,
      color: Color(0xFF12B5CB),
      about:
          tr('Возвращаем прохладу в салон: проверяем систему и заправляем её хладагентом.'),
      includes: [
        tr('Проверка давления в системе'),
        tr('Поиск утечек'),
        tr('Заправка хладагентом'),
        tr('Проверка работы компрессора'),
      ],
      whenNeeded:
          tr('Если кондиционер слабо охлаждает или из дефлекторов появился запах.'),
    ),
  ];

  // AG_POP1: популярные услуги — сетка 3×2 картинками-плитками (как в макете); нет картинки — прежняя плитка
  Widget _serviceBannersRow() {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 10.0;
        final cols = constraints.maxWidth >= 700 ? 6 : 3;
        final width = ((constraints.maxWidth - gap * (cols - 1)) / cols).floorToDouble();
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final item in _serviceBanners)
              SizedBox(
                width: width,
                height: width,
                child: item.img.isEmpty
                    ? _serviceBanner(item, width)
                    : _Pressable(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _openServiceFor(item.title),
                            borderRadius: BorderRadius.circular(20),
                            child: Ink(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .07), blurRadius: 14, offset: const Offset(0, 6))],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Image.network(
                                  'https://job.autogrom.ru/svc_img/popular/${item.img}.jpg?v=1',
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => _serviceBanner(item, width),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
              ),
          ],
        );
      },
    );
  }

  Widget _serviceIconTile(_ServiceBanner item, {double size = 42}) {
    final k3 = AgIcon3D.kindFor(item.icon); // AG_UI2: объёмная иконка услуги
    if (k3 != null) return SizedBox(width: size, height: size, child: AgIcon3D(k3, size: size));
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * .33),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(item.color, Colors.white, .22) ?? item.color,
            item.color,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: item.color.withValues(alpha: .38),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: AgIcon(
        item.icon,
        size: size * .55,
        color: Colors.white,
        strokeWidth: 1.9,
      ),
    );
  }

  Widget _serviceBanner(_ServiceBanner item, double width) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return _Pressable(
      child: GlassSurface(
        radius: 22,
        child: InkWell(
          onTap: () => _openServiceFor(item.title), // AG_SVCTAP1: сразу в услугу
          borderRadius: BorderRadius.circular(22),
          child: Container(
            width: width,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: _border),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -34,
                  top: -34,
                  child: Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          item.color.withValues(alpha: isDark ? .42 : .28),
                          item.color.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 9,
                  top: 9,
                  child: AgIcon(
                    AgIcons.arrowUpRight,
                    size: 15,
                    color: _muted,
                    strokeWidth: 2,
                  ),
                ),
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.all(11),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _serviceIconTile(item),
                        const Spacer(),
                        Text(
                          item.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            height: 1.15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.caption,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _muted,
                            fontSize: 10.5,
                            height: 1.1,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // AG_UI2: «Записаться» из описания — сразу на страницу именно этой услуги
  Future<void> _openServiceFor(String title) async {
    String norm(String s) => s
        .toLowerCase()
        .replaceAll('ё', tr('е'))
        .replaceAll(RegExp(r'[^a-zа-я0-9 ]'), ' ')
        .replaceAll(RegExp(r' +'), ' ')
        .trim();
    final want = norm(AgI18n.orig(title)); // AG_SVCTAP1 + AG_I18N1: точнее ищем услугу по всем словам названия
    final stems = want.split(' ').where((w) => w.length >= 3).map((w) => w.length > 5 ? w.substring(0, 5) : w).toList();
    final stem = want.split(' ').first;
    try {
      final list = await context.read<BookingRepository>().listServices();
      if (!mounted) return;
      Service? best;
      var bestScore = 0;
      for (final s in list) {
        final t = norm(s.title);
        if (t == want) {
          best = s;
          bestScore = stems.length; // AG_SVCTAP2
          break;
        }
        final score = stems.where((k) => t.contains(k)).length;
        if (score > bestScore || (score == bestScore && score > 0 && best != null && s.title.length < best.title.length)) {
          best = s;
          bestScore = score;
        }
      }
      if (best != null && bestScore >= stems.length) { // AG_SVCTAP2: только при полном совпадении, иначе — список
        context.push('/services/${best.id}');
        return;
      }
    } catch (_) {}
    if (mounted) context.push('/services?search=${Uri.encodeComponent(stem)}');
  }

  void _showServiceInfo(_ServiceBanner item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final background = isDark ? const Color(0xFF171717) : Colors.white;
        final primary = isDark ? Colors.white : const Color(0xFF181818);
        final secondary =
            isDark ? const Color(0xFFA8A8A8) : const Color(0xFF707070);

        return SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 22),
            decoration: BoxDecoration(
              color: background,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(30),
              ),
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: secondary.withValues(alpha: .30),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Row(
                    children: [
                      _serviceIconTile(item, size: 52),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: TextStyle(
                                color: primary,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -.3,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              item.caption,
                              style: TextStyle(color: secondary, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  Text(
                    item.about,
                    style: TextStyle(
                      color: primary,
                      fontSize: 13.5,
                      height: 1.45,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 18),

                  Text(
                    tr('Что входит'),
                    style: TextStyle(
                      color: primary,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),

                  const SizedBox(height: 10),

                  for (final line in item.includes)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 9),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            size: 18,
                            color: item.color,
                          ),
                          const SizedBox(width: 9),
                          Expanded(
                            child: Text(
                              line,
                              style: TextStyle(
                                color: primary,
                                fontSize: 13,
                                height: 1.35,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 7),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: item.color.withValues(alpha: .10),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: item.color.withValues(alpha: .22),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 19,
                          color: item.color,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tr('Когда нужно'),
                                style: TextStyle(
                                  color: primary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.whenNeeded,
                                style: TextStyle(
                                  color: secondary,
                                  fontSize: 12,
                                  height: 1.4,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: () {
                        Navigator.of(sheetContext).pop();

                        final auth = context.read<AuthProvider>();

                        if (!auth.isLoggedIn) {
                          context.push('/login');
                          return;
                        }

                        _openServiceFor(item.title); // AG_UI2
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: orange,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(17),
                        ),
                      ),
                      child: Text(
                        tr('Записаться'),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _promoBanner(String title, String subtitle, String icon) {
    return _Pressable(child: _promoBannerBase(title, subtitle, icon));
  }

  Widget _promoBannerBase(String title, String subtitle, String icon) {
    return GlassSurface(
      radius: 22,
      child: InkWell(
        onTap: () => context.push('/news'),
        borderRadius: BorderRadius.circular(22),
        child: Container(
          width: 256,
          height: 126,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: _border),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 30,
                      height: 4,
                      decoration: BoxDecoration(
                        color: orange,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _muted,
                        fontSize: 11,
                        height: 1.15,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _orangeSoft,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: AgIcon(icon, size: 28, color: orange),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServiceBanner {
  const _ServiceBanner({
    required this.title,
    required this.caption,
    required this.icon,
    required this.color,
    required this.about,
    required this.includes,
    required this.whenNeeded,
    this.img = '', // AG_POP1: картинка-плитка с сервера job/svc_img/popular/<img>.jpg
  });

  final String img;
  final String title;
  final String caption;
  final String icon;
  final Color color;
  final String about;
  final List<String> includes;
  final String whenNeeded;
}

class _Pressable extends StatefulWidget {
  const _Pressable({required this.child, this.pressedScale = 0.96});

  final Widget child;
  final double pressedScale;

  @override
  State<_Pressable> createState() => _PressableState();
}

class _PressableState extends State<_Pressable> {
  bool _down = false;
  bool _armed = false;
  Offset _start = Offset.zero;

  void _set(bool value) {
    if (_down != value && mounted) setState(() => _down = value);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (e) {
        _armed = true;
        _start = e.position;
        Future.delayed(const Duration(milliseconds: 40), () {
          if (_armed) _set(true);
        });
      },
      onPointerMove: (e) {
        if (_armed && (e.position - _start).distance > 12) {
          _armed = false;
          _set(false);
        }
      },
      onPointerUp: (_) {
        if (_armed) HapticFeedback.selectionClick();
        _armed = false;
        _set(false);
      },
      onPointerCancel: (_) {
        _armed = false;
        _set(false);
      },
      child: AnimatedScale(
        scale: _down ? widget.pressedScale : 1.0,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}



/// AG_BONUSCARD1 — бонусная карта в виде банковской: EMV-чип, бесконтактный значок,
/// уровень, баланс, прогресс до следующего уровня, код приглашения.
/// Светлая тема — фирменная оранжевая карта, тёмная — графитовая с оранжевым свечением.
class _AgBonusCard extends StatelessWidget {
  const _AgBonusCard({
    required this.points,
    required this.invited,
    required this.code,
    required this.rank,
    required this.rankIcon,
    required this.progress,
    required this.nextAt,
    required this.nextName,
    required this.onInvite,
    required this.onRules,
  });

  final num points;
  final int invited;
  final String code;
  final String rank;
  final String rankIcon;
  final double progress;
  final int? nextAt;
  final String? nextName;
  final VoidCallback onInvite;
  final VoidCallback onRules;

  static const _chip = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 46 36">'
      '<defs><linearGradient id="g" x1="0" y1="0" x2="1" y2="1">'
      '<stop offset="0" stop-color="#FFF1C1"/><stop offset=".35" stop-color="#E9C46A"/>'
      '<stop offset=".7" stop-color="#C8962E"/><stop offset="1" stop-color="#F3D58A"/></linearGradient></defs>'
      '<rect x="1" y="1" width="44" height="34" rx="7" fill="url(#g)" stroke="#A97A1E" stroke-opacity=".55"/>'
      '<g fill="none" stroke="#8C6416" stroke-opacity=".7" stroke-width="1.3">'
      '<path d="M1 12h12a4 4 0 0 1 4 4v4a4 4 0 0 1-4 4H1"/><path d="M45 12H33a4 4 0 0 0-4 4v4a4 4 0 0 0 4 4h12"/>'
      '<path d="M17 18h12M23 1v10M23 25v10"/><rect x="17" y="11" width="12" height="14" rx="3"/></g></svg>';

  static const _nfc = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#FFFFFF" '
      'stroke-width="2" stroke-linecap="round"><path d="M7 8.5a5 5 0 0 1 0 7"/><path d="M10.5 6a8.5 8.5 0 0 1 0 12"/>'
      '<path d="M14 3.5a12 12 0 0 1 0 17"/></svg>';

  static const _copy = '<rect x="8" y="8" width="11" height="12" rx="2.5"/><path d="M5 15.5V6.5A2.5 2.5 0 0 1 7.5 4H14"/>';
  static const _users = '<circle cx="9" cy="8.5" r="3.2"/><path d="M3.5 19a5.5 5.5 0 0 1 11 0"/><path d="M15.5 5.6a3.2 3.2 0 0 1 0 6"/><path d="M17 14.2a5.5 5.5 0 0 1 3.5 4.8"/>';
  static const _doc = '<path d="M14 3.5H7.5a2 2 0 0 0-2 2v13a2 2 0 0 0 2 2h9a2 2 0 0 0 2-2V8z"/><path d="M14 3.5V8h4.5M9 12.5h6M9 16h4"/>';
  static const _plus = '<path d="M12 5v14M5 12h14"/>';

  // AG_BONUSCARD2: компактная карта — ~в 2 раза ниже прежней
  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    const orange = Color(0xFFFF6A00);
    final List<Color> bg = dark
        ? const [Color(0xFF2A2A2E), Color(0xFF18181B), Color(0xFF0E0E10)]
        : const [Color(0xFFFFA24A), Color(0xFFFF6A00), Color(0xFFE24E00)];
    final sub = Colors.white.withValues(alpha: dark ? .6 : .82);
    final pill = Colors.white.withValues(alpha: dark ? .09 : .2);
    final left = nextAt == null ? 0 : (nextAt! - invited);

    Widget icon(String p, double s, Color c, [double w = 2]) => SvgPicture.string(
          '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#000" stroke-width="$w" stroke-linecap="round" stroke-linejoin="round">$p</svg>',
          width: s, height: s, colorFilter: ColorFilter.mode(c, BlendMode.srcIn),
        );

    Widget chip({required Widget child, VoidCallback? onTap}) => Material(
          color: pill,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: Padding(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7), child: child),
          ),
        );

    final pts = points.round().toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]} ');

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: bg),
        boxShadow: [BoxShadow(color: dark ? Colors.black.withValues(alpha: .4) : orange.withValues(alpha: .28), blurRadius: 22, offset: const Offset(0, 10))],
      ),
      child: Stack(children: [
        Positioned(right: -40, top: -50, child: Container(width: 150, height: 150,
            decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: .08)))),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 14, 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            // 1: чип + бонусы + уровень
            Row(children: [
              SvgPicture.string(_chip, width: 30, height: 23),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(tr('Бонусы'), style: TextStyle(color: sub, fontSize: 11.5, fontWeight: FontWeight.w800, letterSpacing: .4)),
                  Text('$pts ₽', maxLines: 1,
                      style: const TextStyle(color: Colors.white, fontSize: 26, height: 1.05, fontWeight: FontWeight.w900, letterSpacing: -.6)),
                ]),
              ),
              chip(
                onTap: onRules,
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  SvgPicture.asset(rankIcon, width: 16, height: 16),
                  const SizedBox(width: 5),
                  Text(rank, style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w900, letterSpacing: .5)),
                ]),
              ),
            ]),
            const SizedBox(height: 12),
            // 2: код, приглашено, пригласить
            Row(children: [
              chip(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: code));
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('Код скопирован'))));
                },
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(code, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: .6)),
                  const SizedBox(width: 5),
                  icon(_copy, 14, Colors.white),
                ]),
              ),
              const SizedBox(width: 6),
              chip(
                onTap: onInvite,
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  icon(_users, 15, Colors.white),
                  const SizedBox(width: 4),
                  Text('$invited', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900)),
                ]),
              ),
              const Spacer(),
              Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: onInvite,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      icon(_plus, 14, dark ? const Color(0xFF18181B) : orange, 2.6),
                      const SizedBox(width: 3),
                      Text(tr('300 ₽ за друга'),
                          style: TextStyle(color: dark ? const Color(0xFF18181B) : orange, fontSize: 12.5, fontWeight: FontWeight.w900)),
                    ]),
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 12),
            // 3: прогресс до следующего уровня
            Row(children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: progress, minHeight: 5,
                    backgroundColor: Colors.white.withValues(alpha: .22),
                    valueColor: const AlwaysStoppedAnimation(Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(nextAt == null ? tr('максимальный уровень') : trf('ещё {0} до {1}', [left, nextName ?? '']),
                  style: TextStyle(color: sub, fontSize: 11.5, fontWeight: FontWeight.w800)),
            ]),
          ]),
        ),
      ]),
    );
  }
}

class _CardWavesPainter extends CustomPainter {
  _CardWavesPainter({required this.dark});
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.white.withValues(alpha: dark ? .045 : .10);
    for (var i = 0; i < 9; i++) {
      final y = size.height * .55 + i * 11.0;
      final path = Path()..moveTo(-10, y);
      path.cubicTo(size.width * .30, y - 38, size.width * .62, y + 34, size.width + 10, y - 16);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _CardWavesPainter old) => old.dark != dark;
}


/* AG_HDR_E: погода в Екатеринбурге (Open-Meteo, без ключа), кэш на 30 минут */
class _AgWeather extends StatefulWidget {
  const _AgWeather({required this.ink});
  final Color ink;
  @override
  State<_AgWeather> createState() => _AgWeatherState();
}

class _AgWeatherState extends State<_AgWeather> {
  static int? _t;
  static int? _code;
  static DateTime? _at;

  @override
  void initState() {
    super.initState();
    if (_at == null || DateTime.now().difference(_at!) > const Duration(minutes: 30)) _load();
  }

  Future<void> _load() async {
    try {
      // AG_WEATHER2: погода по месту телефона, если доступ к геолокации уже дан; иначе — Екатеринбург
      var lat = 56.84, lon = 60.61;
      try {
        final perm = await Geolocator.checkPermission();
        // AG_WEATHER4: на компьютере/в браузере место определяется по IP и через VPN бывает «за границей» —
        // там всегда Екатеринбург; в телефоне берём GPS, но только если точка в России
        if (!kIsWeb && (perm == LocationPermission.always || perm == LocationPermission.whileInUse)) {
          Position? p;
          if (!kIsWeb) p = await Geolocator.getLastKnownPosition();
          p ??= await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(accuracy: LocationAccuracy.low, timeLimit: Duration(seconds: 6)),
          );
          final inRu = p.latitude >= 41 && p.latitude <= 82 && (p.longitude >= 19 || p.longitude <= -168);
          if (inRu) {
            lat = p.latitude;
            lon = p.longitude;
          }
        }
      } catch (_) {}
      // AG_WEATHER3: сначала через наш сервер (работает и на мобильном интернете с «белыми списками»), запасной — Open-Meteo
      int? t;
      int? code;
      try {
        final r = await http
            .get(Uri.parse('https://api.autogrom-group.com/api/weather?lat=${lat.toStringAsFixed(2)}&lon=${lon.toStringAsFixed(2)}'))
            .timeout(const Duration(seconds: 8));
        final j = jsonDecode(r.body) as Map<String, dynamic>;
        t = (j['temperature'] as num).round();
        code = (j['code'] as num).toInt();
      } catch (_) {
        final r = await http
            .get(Uri.parse('https://api.open-meteo.com/v1/forecast?latitude=${lat.toStringAsFixed(2)}&longitude=${lon.toStringAsFixed(2)}&current=temperature_2m,weather_code&timezone=auto'))
            .timeout(const Duration(seconds: 8));
        final c = (jsonDecode(r.body) as Map<String, dynamic>)['current'] as Map<String, dynamic>;
        t = (c['temperature_2m'] as num).round();
        code = (c['weather_code'] as num).toInt();
      }
      _t = t;
      _code = code;
      _at = DateTime.now();
      if (mounted) setState(() {});
    } catch (_) {}
  }

  // AG_WEB2: погода — свои SVG (не зависят от шрифтов и кэша браузера)
  String _svg(int c) {
    const sun = '<circle cx="12" cy="12" r="4.2" fill="#FFD84D"/><g stroke="#FFD84D" stroke-width="2" stroke-linecap="round"><path d="M12 2.5v2.2M12 19.3v2.2M2.5 12h2.2M19.3 12h2.2M5.3 5.3l1.6 1.6M17.1 17.1l1.6 1.6M5.3 18.7l1.6-1.6M17.1 6.9l1.6-1.6"/></g>';
    const moon = '<path d="M19 14.5A7.5 7.5 0 1 1 9.5 5a6 6 0 0 0 9.5 9.5z" fill="#FFE9A8"/>';
    const cloud = '<path d="M7 18.5h10.5a4 4 0 0 0 .4-8 5.6 5.6 0 0 0-10.8 1.4A3.3 3.3 0 0 0 7 18.5z" fill="#fff"/>';
    const smallSun = '<circle cx="8" cy="8" r="3.4" fill="#FFD84D"/><g stroke="#FFD84D" stroke-width="1.6" stroke-linecap="round"><path d="M8 1.8v1.4M1.8 8h1.4M3.6 3.6l1 1M12.4 3.6l-1 1"/></g>';
    const snow = '<g stroke="#fff" stroke-width="1.6" stroke-linecap="round"><path d="M8 20.5v2M12 20v2.5M16 20.5v2"/></g>';
    const rain = '<g stroke="#CFE6FF" stroke-width="1.8" stroke-linecap="round"><path d="M8.5 20l-1 2.3M12.5 20l-1 2.3M16.5 20l-1 2.3"/></g>';
    const bolt = '<path d="M12.5 18.5l-2.3 3.6h2.2l-1 2.4 3.3-4h-2.2l1-2z" fill="#FFD84D"/>';
    final night = DateTime.now().hour >= 18 || DateTime.now().hour < 6;
    String b;
    if (c == 0) {
      b = night ? moon : sun;
    } else if (c <= 2) {
      b = (night ? '' : smallSun) + cloud;
    } else if (c == 3 || c <= 48) {
      b = cloud;
    } else if ((c >= 71 && c <= 77) || c == 85 || c == 86) {
      b = '<g transform="translate(0 -2)">$cloud</g>$snow';
    } else if (c >= 95) {
      b = '<g transform="translate(0 -3)">$cloud</g>$bolt';
    } else {
      b = '<g transform="translate(0 -2)">$cloud</g>$rain';
    }
    return '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">$b</svg>';
  }

  @override
  Widget build(BuildContext context) {
    if (_t == null || _code == null) return const SizedBox(width: 4);
    final dark = Theme.of(context).brightness == Brightness.dark;
    // AG_WEATHER2: плашка с голубым фоном — белое облако видно и в светлой теме
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 6, 10, 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: dark ? const [Color(0xFF243447), Color(0xFF1B2735)] : const [Color(0xFF8EC5FF), Color(0xFF4F8DF5)],
        ),
        boxShadow: dark ? null : [BoxShadow(color: const Color(0xFF4F8DF5).withValues(alpha: .25), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        SvgPicture.string(_svg(_code!), width: 24, height: 24),
        const SizedBox(width: 5),
        Text('${_t! > 0 ? '+' : _t! < 0 ? '-' : ''}${_t!.abs()}°',
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
      ]),
    );
  }
}
