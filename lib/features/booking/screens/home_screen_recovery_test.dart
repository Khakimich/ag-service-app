import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/notifications_provider.dart';
import 'service_search_dialog.dart';

import '../../auth/providers/auth_provider.dart';
import '../../my_cars/providers/my_cars_provider.dart';
import '../../../models/user_car.dart';
import '../providers/company_provider.dart';
import '../providers/referrals_provider.dart';

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
        context.read<ReferralsProvider>().loadSummary();
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

    await context.read<CompanyProvider>().loadAll();
  }

  Color get _orangeSoft {
    return Theme.of(context).brightness == Brightness.dark
        ? orange.withValues(alpha: .14)
        : const Color(0xFFFFF1E7);
  }

  Color get _border {
    return Theme.of(context).colorScheme.outlineVariant;
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
      body: SafeArea(
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
                  const SizedBox(height: 16),

                  _referralBankCard(),
                  const SizedBox(height: 12),

                  _bookingButton(),
                  const SizedBox(height: 18),

                  _sectionHeader(
                    'Мой гараж',
                    action: 'Все',
                    onTap: () => context.go('/profile/my-cars'),
                  ),
                  const SizedBox(height: 10),
                  _garage(),
                  const SizedBox(height: 18),

                  _sectionHeader('Быстрый доступ'),
                  const SizedBox(height: 10),
                  _quickActions(),
                  const SizedBox(height: 18),

                  _newsPreview(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 5) return 'Доброй ночи';
    if (h < 12) return 'Доброе утро';
    if (h < 18) return 'Добрый день';
    return 'Добрый вечер';
  }

  Widget _header() {
    final auth = context.watch<AuthProvider>();
    final notifications = context.watch<NotificationsProvider>();
    final unreadCount = notifications.unreadCount;

    final fullName = (auth.user?.name ?? '').trim();
    final firstName =
        fullName.isEmpty ? '' : fullName.split(RegExp(r'\s+')).first;

    final title =
        auth.isLoggedIn && firstName.isNotEmpty ? firstName : 'AG Service';

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final iconBackground =
        isDark ? const Color(0xFF22242A) : const Color(0xFFF3F4F6);

    final primaryText = isDark ? Colors.white : const Color(0xFF111318);

    final secondaryText =
        isDark ? const Color(0xFFAEB1B8) : const Color(0xFF737780);

    return Container(
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      color: Colors.transparent,
      child: Row(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: () {
                if (auth.isLoggedIn) {
                  context.go('/profile');
                } else {
                  context.push('/login');
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color:
                              isDark
                                  ? const Color(0xFF3A3C42)
                                  : const Color(0xFFE1E3E7),
                        ),
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/logo.png',
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 175),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _greeting(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: secondaryText,
                              fontSize: 13,
                              height: 1.1,
                              fontWeight: FontWeight.w500,
                            ),
                          ),

                          const SizedBox(height: 4),

                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: primaryText,
                                    fontSize: 21,
                                    height: 1,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -.4,
                                  ),
                                ),
                              ),

                              const SizedBox(width: 2),

                              Icon(
                                Icons.chevron_right_rounded,
                                size: 25,
                                color: secondaryText,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const Spacer(),

          Material(
            color: iconBackground,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: _openSearch,
              child: SizedBox(
                width: 46,
                height: 46,
                child: Icon(Icons.search_rounded, size: 27, color: primaryText),
              ),
            ),
          ),

          const SizedBox(width: 7),

          Material(
            color: iconBackground,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                context.push('/profile/notifications');
              },
              child: SizedBox(
                width: 46,
                height: 46,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Center(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        transitionBuilder: (child, animation) {
                          return ScaleTransition(
                            scale: animation,
                            child: FadeTransition(
                              opacity: animation,
                              child: child,
                            ),
                          );
                        },
                        child: SvgPicture.asset(
                          'assets/icons/profile/notifications.svg',
                          key: ValueKey(unreadCount > 0),
                          width: 27,
                          height: 27,
                          colorFilter: ColorFilter.mode(
                            primaryText,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                    ),
                    if (unreadCount > 0)
                      Positioned(
                        right: 4,
                        top: 3,
                        child: Container(
                          constraints: const BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE52B3D),
                            borderRadius: BorderRadius.circular(99),
                            border: Border.all(color: iconBackground, width: 2),
                          ),
                          child: Text(
                            unreadCount > 99 ? '99+' : '$unreadCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              height: 1,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _referralBankCard() {
    return _Pressable(pressedScale: 0.98, child: _referralBankCardBase());
  }

  Widget _referralBankCardBase() {
    final auth = context.watch<AuthProvider>();
    final referrals = context.watch<ReferralsProvider>();
    final summary = referrals.summary;

    final points = summary?.bonusPoints ?? auth.user?.bonusPoints ?? 0;
    final invited = summary?.referrals.length ?? 0;
    final code = summary?.referralCode ?? '—';

    if (!auth.isLoggedIn) {
      return Material(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => context.push('/login'),
          child: Container(
            height: 94,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
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
                  child: _svg('wallet', size: 29),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Реферальный счёт',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Войдите, чтобы увидеть баланс',
                        style: TextStyle(color: _muted, fontSize: 12),
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

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(26),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.go('/profile/referrals'),
        borderRadius: BorderRadius.circular(26),
        child: Container(
          height: 176,
          padding: const EdgeInsets.fromLTRB(18, 17, 18, 15),
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(26)),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF262626), Color(0xFF171717)],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -28,
                top: -48,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: orange.withValues(alpha: .12),
                  ),
                ),
              ),
              Positioned(
                right: 55,
                bottom: -75,
                child: Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: .025),
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: orange,
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: _svg('wallet', size: 22, color: Colors.white),
                      ),
                      const SizedBox(width: 11),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'AG BONUS',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                letterSpacing: .8,
                              ),
                            ),
                            SizedBox(height: 1),
                            Text(
                              'Реферальный баланс',
                              style: TextStyle(
                                color: Color(0xFFAFAFAF),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 31,
                        height: 31,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .07),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: _svg('arrow', size: 16, color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: points.toDouble()),
                    duration: const Duration(milliseconds: 850),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return Text(
                        '${value.round()} ₽',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          height: 1,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -.8,
                        ),
                      );
                    },
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: _bankStat('users', 'Приглашено', '$invited'),
                      ),
                      Container(
                        width: 1,
                        height: 27,
                        color: Colors.white.withValues(alpha: .10),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _bankStat(
                          'ticket',
                          'Реферал',
                          code.toUpperCase(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
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
                color: orange.withValues(alpha: .14 + (t * .08)),
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

            context.go('/services');
          },
          child: Container(
            height: 66,
            padding: const EdgeInsets.symmetric(horizontal: 15),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [Color(0xFFFF7200), Color(0xFFFF5700)],
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .16),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: _svg('calendar', size: 25, color: Colors.white),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Записаться в сервис',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Услуга  •  мастер  •  время',
                        style: TextStyle(
                          color: Color(0xFFFFE4D1),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .15),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: _svg('arrow', size: 17, color: Colors.white),
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

    return SizedBox(
      height: 118,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: cars.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          if (index == cars.length) {
            return _addCarCard();
          }

          return _carMiniCard(cars[index]);
        },
      ),
    );
  }

  Widget _garageGuest() {
    return _garageMessage(
      title: 'Ваш гараж',
      subtitle: 'Войдите, чтобы добавить автомобиль',
      onTap: () => context.push('/login'),
    );
  }

  Widget _garageEmpty() {
    return _garageMessage(
      title: 'Добавьте автомобиль',
      subtitle: 'VIN, марка, модель и госномер',
      onTap: () => context.go('/profile/my-cars'),
    );
  }

  Widget _garageMessage({
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(22),
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

    const replacements = <String, String>{
      'š': 's',
      'Š': 's',
      'ё': 'е',
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
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: () => context.go('/profile/my-cars'),
        borderRadius: BorderRadius.circular(22),
        child: Container(
          width: 262,
          height: 118,
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
                  color: _orangeSoft,
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
            onTap: () => context.go('/profile/my-cars'),
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
                  const Text(
                    'Добавить',
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
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _quickAction(
                icon: 'repair',
                title: 'Статус ремонта',
                subtitle: 'Следите за автомобилем',
                onTap: () => context.go('/bookings'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _quickAction(
                icon: 'calendar',
                title: 'Мои записи',
                subtitle: 'История и визиты',
                onTap: () => context.go('/bookings'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _quickAction(
                icon: 'services',
                title: 'Услуги и цены',
                subtitle: 'Каталог сервиса',
                onTap: () => context.go('/services'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _quickAction(
                icon: 'chat',
                title: 'Чат с сервисом',
                subtitle: 'Связаться с нами',
                onTap: () => context.go('/chats'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _quickAction({
    required String icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return _Pressable(
      child: _quickActionBase(
        icon: icon,
        title: title,
        subtitle: subtitle,
        onTap: onTap,
      ),
    );
  }

  Widget _quickActionBase({
    required String icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          height: 112,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: _border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _orangeSoft,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Image.asset(
                  'assets/home_v3/$icon.png',
                  width: 34,
                  height: 34,
                  fit: BoxFit.contain,
                ),
              ),
              const Spacer(),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14.5,
                  height: 1.1,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -.2,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: _muted, fontSize: 11.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _newsPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          'Новости и акции',
          action: 'Все',
          onTap: () => context.go('/news'),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 126,
          child: ListView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            children: [
              _promoBanner(
                'Акции',
                'Специальные предложения для клиентов',
                'ticket',
              ),
              const SizedBox(width: 10),
              _promoBanner(
                'AG Service',
                'Новости нашего автосервиса',
                'repair',
              ),
              const SizedBox(width: 10),
              _promoBanner(
                'Онлайн-запись',
                'Запишитесь на удобное время',
                'calendar',
              ),
              const SizedBox(width: 10),
              _promoBanner('AG Bonus', 'Бонусы и предложения', 'wallet'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _promoBanner(String title, String subtitle, String icon) {
    return _Pressable(child: _promoBannerBase(title, subtitle, icon));
  }

  Widget _promoBannerBase(String title, String subtitle, String icon) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: () => context.go('/news'),
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
                child: _svg(icon, size: 29, color: orange),
              ),
            ],
          ),
        ),
      ),
    );
  }
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
