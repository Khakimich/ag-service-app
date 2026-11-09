import 'package:mobile/core/nav.dart'; // AG_FIX3
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/company_provider.dart';
import '../widgets/photo_viewer.dart';
import '../../../core/i18n.dart'; // AG_I18N1

class AboutServiceScreen extends StatefulWidget {
  const AboutServiceScreen({super.key});

  @override
  State<AboutServiceScreen> createState() => _AboutServiceScreenState();
}

class _AboutServiceScreenState extends State<AboutServiceScreen> {
  static const orange = Color(0xFFFF6A00);

  final PageController _pageController = PageController();
  int _currentPhoto = 0;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<CompanyProvider>().loadAll();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _call(String phone) async {
    final cleaned = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (cleaned.isEmpty) return;

    await launchUrl(Uri(scheme: 'tel', path: cleaned));
  }

  Future<void> _openYandexMap() async {
    final uri = Uri.parse(
      'https://yandex.ru/maps/54/yekaterinburg/?ll=60.546761%2C56.754853&mode=poi&poi%5Bpoint%5D=60.546459%2C56.754691&poi%5Buri%5D=ymapsbm1%3A%2F%2Forg%3Foid%3D151067457406&z=19.06',
    );

    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final company = context.watch<CompanyProvider>();
    final profile = company.profile;
    final colors = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(leading: const AgBackButton(fallback: '/'), /* AG_FIX3 */ 
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: colors.surface,
        titleSpacing: 4,
        title: Text(
          tr('О приложении'),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            letterSpacing: -.25,
          ),
        ),
      ),
      body: RefreshIndicator(
        color: const Color(0xFFFF6A00),
        onRefresh: () => context.read<CompanyProvider>().loadAll(),
        child:
            profile == null
                ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    SizedBox(height: 240),
                    Center(child: CircularProgressIndicator(color: orange)),
                  ],
                )
                : ListView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                  children: [
                    // =====================================================
                    // HERO
                    // =====================================================
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors:
                              dark
                                  ? [
                                    colors.surfaceContainer,
                                    colors.surfaceContainerHighest,
                                  ]
                                  : [const Color(0xFFFFF4ED), Colors.white],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(26),
                        border: Border.all(
                          color: orange.withValues(alpha: .12),
                        ),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 82,
                            height: 82,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(23),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: .06),
                                  blurRadius: 18,
                                  offset: const Offset(0, 7),
                                ),
                              ],
                            ),
                            child:
                                profile.logoUrl != null &&
                                        profile.logoUrl!.trim().isNotEmpty
                                    ? CachedNetworkImage(
                                      imageUrl: profile.logoUrl!,
                                      fit: BoxFit.contain,
                                      errorWidget:
                                          (_, __, ___) => Image.asset(
                                            'assets/logo.png',
                                            fit: BoxFit.contain,
                                          ),
                                    )
                                    : Image.asset(
                                      'assets/logo.png',
                                      fit: BoxFit.contain,
                                    ),
                          ),

                          const SizedBox(height: 14),

                          Text(
                            profile.name,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 23,
                              height: 1.1,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -.55,
                            ),
                          ),

                          const SizedBox(height: 5),

                          Text(
                            tr('Автосервис • Екатеринбург'),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFFFF6A00),
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),

                          if (profile.description.trim().isNotEmpty) ...[
                            const SizedBox(height: 13),
                            Text(
                              profile.description,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: colors.onSurfaceVariant,
                                fontSize: 12.5,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // =====================================================
                    // PHOTOS
                    // =====================================================
                    if (profile.carouselUrls.isNotEmpty) ...[
                      const SizedBox(height: 14),

                      ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: SizedBox(
                          height: 205,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              PageView.builder(
                                controller: _pageController,
                                itemCount: profile.carouselUrls.length,
                                onPageChanged: (index) {
                                  setState(() {
                                    _currentPhoto = index;
                                  });
                                },
                                itemBuilder: (context, index) {
                                  return GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap:
                                        () => PhotoViewer.show(
                                          context,
                                          photos: profile.carouselUrls,
                                          initialIndex: index,
                                        ),
                                    child: CachedNetworkImage(
                                      imageUrl: profile.carouselUrls[index],
                                      fit: BoxFit.cover,
                                      placeholder:
                                          (_, __) => Container(
                                            color:
                                                colors.surfaceContainerHighest,
                                            alignment: Alignment.center,
                                            child:
                                                const CircularProgressIndicator(
                                                  color: Color(0xFFFF6A00),
                                                ),
                                          ),
                                      errorWidget:
                                          (_, __, ___) => Container(
                                            color:
                                                colors.surfaceContainerHighest,
                                            alignment: Alignment.center,
                                            child: Icon(
                                              Icons
                                                  .image_not_supported_outlined,
                                              color: colors.onSurfaceVariant,
                                              size: 38,
                                            ),
                                          ),
                                    ),
                                  );
                                },
                              ),

                              Positioned(
                                left: 0,
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  height: 65,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.transparent,
                                        Colors.black.withValues(alpha: .50),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              if (profile.carouselUrls.length > 1)
                                Positioned(
                                  left: 0,
                                  right: 0,
                                  bottom: 12,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: List.generate(
                                      profile.carouselUrls.length,
                                      (index) => AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 200,
                                        ),
                                        margin: const EdgeInsets.symmetric(
                                          horizontal: 3,
                                        ),
                                        width: _currentPhoto == index ? 18 : 6,
                                        height: 6,
                                        decoration: BoxDecoration(
                                          color:
                                              _currentPhoto == index
                                                  ? orange
                                                  : Colors.white.withValues(
                                                    alpha: .72,
                                                  ),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    _SectionHeader(
                      title: tr('Контакты'),
                      subtitle: tr('Свяжитесь с нами удобным способом'),
                    ),

                    const SizedBox(height: 10),

                    // =====================================================
                    // CONTACT CARD
                    // =====================================================
                    Container(
                      decoration: BoxDecoration(
                        color: dark ? colors.surfaceContainer : Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: colors.outlineVariant.withValues(alpha: .45),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: dark ? .06 : .025,
                            ),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _ContactRow(
                            icon: Icons.phone_rounded,
                            title: tr('Телефон'),
                            value: profile.phone,
                            onTap:
                                profile.phone.trim().isEmpty
                                    ? null
                                    : () => _call(profile.phone),
                          ),

                          const _ContactDivider(),

                          _ContactRow(
                            icon: Icons.location_on_rounded,
                            title: tr('Адрес'),
                            value: profile.address,
                            onTap:
                                profile.address.trim().isEmpty
                                    ? null
                                    : _openYandexMap,
                          ),

                          const _ContactDivider(),

                          _ContactRow(
                            icon: Icons.schedule_rounded,
                            title: tr('Режим работы'),
                            value: profile.workingHours,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // =====================================================
                    // ACTIONS
                    // =====================================================
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 52,
                            child: ElevatedButton.icon(
                              onPressed:
                                  profile.phone.trim().isEmpty
                                      ? null
                                      : () => _call(profile.phone),
                              icon: const Icon(Icons.phone_rounded, size: 19),
                              label: Text(tr('Позвонить')),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: orange,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                textStyle: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 10),

                        Expanded(
                          child: SizedBox(
                            height: 52,
                            child: OutlinedButton.icon(
                              onPressed: _openYandexMap,
                              icon: const Icon(Icons.near_me_rounded, size: 19),
                              label: Text(tr('Маршрут')),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: orange,
                                side: BorderSide(
                                  color: orange.withValues(alpha: .65),
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),

                    // =====================================================
                    // VERSION
                    // =====================================================
                    FutureBuilder<PackageInfo>(
                      future: PackageInfo.fromPlatform(),
                      builder: (context, snapshot) {
                        final version = snapshot.data?.version;

                        return Column(
                          children: [
                            Opacity(
                              opacity: .75,
                              child: Image.asset(
                                'assets/logo.png',
                                width: 52,
                                height: 28,
                                fit: BoxFit.contain,
                              ),
                            ),

                            const SizedBox(height: 7),

                            Text(
                              'AG Service',
                              style: TextStyle(
                                color: colors.onSurfaceVariant,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),

                            if (version != null &&
                                version.trim().isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                trf('Версия {0}', [version]),
                                style: TextStyle(
                                  color: colors.onSurfaceVariant.withValues(
                                    alpha: .70,
                                  ),
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ],
                        );
                      },
                    ),
                  ],
                ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w900,
            letterSpacing: -.25,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: TextStyle(fontSize: 10.5, color: colors.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.icon,
    required this.title,
    required this.value,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 13, 12, 13),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF2E9),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: const Color(0xFFFF6A00), size: 20),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 9.5,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value.trim().isEmpty ? tr('Не указано') : value,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.25,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),

            if (onTap != null)
              Icon(
                Icons.chevron_right_rounded,
                color: colors.onSurfaceVariant.withValues(alpha: .65),
                size: 21,
              ),
          ],
        ),
      ),
    );
  }
}

class _ContactDivider extends StatelessWidget {
  const _ContactDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: const EdgeInsets.only(left: 68),
      color: Theme.of(
        context,
      ).colorScheme.outlineVariant.withValues(alpha: .30),
    );
  }
}
