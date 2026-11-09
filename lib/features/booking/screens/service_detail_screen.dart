import 'package:mobile/core/nav.dart'; // AG_FIX1
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../auth/providers/auth_provider.dart';
import '../../../core/theme.dart';
import '../data/booking_repository.dart';
import '../providers/booking_flow_provider.dart';
import '../../../core/i18n.dart'; // AG_I18N1

class ServiceDetailScreen extends StatefulWidget {
  const ServiceDetailScreen({super.key, required this.serviceId});

  final String serviceId;

  @override
  State<ServiceDetailScreen> createState() => _ServiceDetailScreenState();
}

class _ServiceDetailScreenState extends State<ServiceDetailScreen> {
  late Future<ServiceDetail> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<BookingRepository>().serviceDetail(widget.serviceId);
  }

  String _iconForCategory(String category) {
    final value = category.toLowerCase();

    if (value.contains('двигател') || value.contains('мотор')) {
      return 'assets/icons/services/categories/engine.png';
    }

    if (value.contains('акпп') ||
        value.contains('кпп') ||
        value.contains('трансмис') ||
        value.contains('короб')) {
      return 'assets/icons/services/categories/transmission.png';
    }

    if (value.contains('тормоз')) {
      return 'assets/icons/services/categories/brake.png';
    }

    if (value.contains('рулев')) {
      return 'assets/icons/services/categories/steering.png';
    }

    if (value.contains('диагност')) {
      return 'assets/icons/services/categories/diagnostic.png';
    }

    if (value.contains('электр')) {
      return 'assets/icons/services/categories/electric.png';
    }

    if (value.contains('кондиц') ||
        value.contains('климат') ||
        value.contains('вакуум')) {
      return 'assets/icons/services/categories/ac.png';
    }

    if (value.contains('ходов') || value.contains('подвес')) {
      return 'assets/icons/services/categories/suspension.png';
    }

    return 'assets/icons/services/categories/maintenance.png';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      body: FutureBuilder<ServiceDetail>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: BrandColors.orange),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  snapshot.error.toString(),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final detail = snapshot.data!;
          final service = detail.service;
          final hasSpecialists = detail.specialists.isNotEmpty;

          final iconAsset = _iconForCategory(service.category);

          return Column(
            children: [
              Expanded(
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: SafeArea(
                        bottom: false,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                          child: Row(
                            children: [
                              _CircleAction(
                                icon: Icons.arrow_back_ios_new_rounded,
                                onTap: () => context.agBack('/services'), // AG_FIX1
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  tr('Об услуге'),
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      sliver: SliverToBoxAdapter(
                        child: _ServiceHeader(
                          title: service.title,
                          category: service.category,
                          price: service.priceLabel,
                          duration: service.durationLabel,
                          photoUrl: service.photoUrl,
                          iconAsset: iconAsset,
                        ),
                      ),
                    ),

                    if (service.description != null &&
                        service.description!.trim().isNotEmpty)
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                        sliver: SliverToBoxAdapter(
                          child: _DescriptionCard(
                            description: service.description!,
                          ),
                        ),
                      ),

                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                      sliver: SliverToBoxAdapter(
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tr('Специалисты'),
                                    style: TextStyle(
                                      fontSize: 19,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  SizedBox(height: 3),
                                  Text(
                                    tr('Мастера по этой услуге'),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (hasSpecialists)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: BrandColors.orange.withValues(
                                    alpha: .10,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${detail.specialists.length}',
                                  style: const TextStyle(
                                    color: BrandColors.orange,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                    if (!hasSpecialists)
                      const SliverPadding(
                        padding: EdgeInsets.fromLTRB(16, 0, 16, 0),
                        sliver: SliverToBoxAdapter(child: _EmptySpecialists()),
                      )
                    else
                      SliverToBoxAdapter(
                        child: SizedBox(
                          height: 156,
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            itemCount: detail.specialists.length,
                            separatorBuilder:
                                (_, __) => const SizedBox(width: 10),
                            itemBuilder: (context, index) {
                              final sp = detail.specialists[index];

                              return _SpecialistCard(
                                name: sp.fullName,
                                specialization: sp.specialization,
                                photoUrl: sp.photoUrl,
                              );
                            },
                          ),
                        ),
                      ),

                    if (detail.workExamples.isNotEmpty) ...[
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(16, 25, 16, 12),
                        sliver: SliverToBoxAdapter(
                          child: Text(
                            tr('Примеры работ'),
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),

                      SliverToBoxAdapter(
                        child: SizedBox(
                          height: 165,
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            scrollDirection: Axis.horizontal,
                            itemCount: detail.workExamples.length,
                            separatorBuilder:
                                (_, __) => const SizedBox(width: 10),
                            itemBuilder: (context, index) {
                              final example = detail.workExamples[index];

                              return _WorkExample(
                                photoUrl: example.photoUrl,
                                description: example.description,
                              );
                            },
                          ),
                        ),
                      ),
                    ],

                    const SliverToBoxAdapter(child: SizedBox(height: 28)),
                  ],
                ),
              ),

              _BottomButton(
                enabled: hasSpecialists,
                onPressed: () {
                  context.read<BookingFlowProvider>().selectService(service);

                  final auth = context.read<AuthProvider>();

                  if (!auth.isLoggedIn) {
                    context.push('/login');
                    return;
                  }

                  context.push('/booking/specialist');
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ServiceHeader extends StatelessWidget {
  const _ServiceHeader({
    required this.title,
    required this.category,
    required this.price,
    required this.duration,
    required this.photoUrl,
    required this.iconAsset,
  });

  final String title;
  final String category;
  final String price;
  final String duration;
  final String? photoUrl;
  final String iconAsset;

  bool get _hasPhoto => photoUrl != null && photoUrl!.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: dark ? colors.surfaceContainer : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: .45)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? .10 : .045),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _ServiceVisual(photoUrl: photoUrl, iconAsset: iconAsset),

              const SizedBox(width: 15),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: BrandColors.orange.withValues(alpha: .09),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Text(
                        category,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: BrandColors.orange,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 19,
                        height: 1.16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Container(
            height: 1,
            color: colors.outlineVariant.withValues(alpha: .35),
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: _InfoBox(
                  icon: Icons.payments_outlined,
                  title: tr('Стоимость'),
                  value: price,
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: _InfoBox(
                  icon: Icons.schedule_rounded,
                  title: tr('Время работы'),
                  value: duration,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ServiceVisual extends StatelessWidget {
  const _ServiceVisual({required this.photoUrl, required this.iconAsset});

  final String? photoUrl;
  final String iconAsset;

  bool get _hasPhoto => photoUrl != null && photoUrl!.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 92,
      height: 92,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            BrandColors.orange.withValues(alpha: .15),
            BrandColors.orange.withValues(alpha: .035),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child:
            _hasPhoto
                ? CachedNetworkImage(
                  imageUrl: photoUrl!,
                  width: 92,
                  height: 92,
                  fit: BoxFit.cover,

                  placeholder: (_, __) => _ServiceIcon(iconAsset: iconAsset),

                  errorWidget:
                      (_, __, ___) => _ServiceIcon(iconAsset: iconAsset),
                )
                : _ServiceIcon(iconAsset: iconAsset),
      ),
    );
  }
}

class _ServiceIcon extends StatelessWidget {
  const _ServiceIcon({required this.iconAsset});

  final String iconAsset;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Image.asset(
        iconAsset,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(
            Icons.car_repair_rounded,
            size: 52,
            color: BrandColors.orange,
          );
        },
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  const _InfoBox({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: .42),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Container(
            width: 33,
            height: 33,
            decoration: BoxDecoration(
              color: BrandColors.orange.withValues(alpha: .10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 17, color: BrandColors.orange),
          ),

          const SizedBox(width: 8),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 9.5,
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DescriptionCard extends StatefulWidget {
  const _DescriptionCard({required this.description});

  final String description;

  @override
  State<_DescriptionCard> createState() => _DescriptionCardState();
}

class _DescriptionCardState extends State<_DescriptionCard> {
  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;

    final longText = widget.description.length > 280;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: dark ? colors.surfaceContainer : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: .42)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: BrandColors.orange.withValues(alpha: .09),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.format_list_bulleted_rounded,
                  size: 19,
                  color: BrandColors.orange,
                ),
              ),

              const SizedBox(width: 10),

              Text(
                tr('Что входит в услугу'),
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
              ),
            ],
          ),

          const SizedBox(height: 14),

          AnimatedSize(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            child: Text(
              widget.description,
              maxLines: expanded || !longText ? null : 7,
              overflow: expanded || !longText ? null : TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: colors.onSurfaceVariant,
              ),
            ),
          ),

          if (longText) ...[
            const SizedBox(height: 8),

            InkWell(
              onTap: () {
                setState(() {
                  expanded = !expanded;
                });
              },
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      expanded ? tr('Свернуть') : tr('Показать полностью'),
                      style: const TextStyle(
                        color: BrandColors.orange,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 3),
                    Icon(
                      expanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      size: 18,
                      color: BrandColors.orange,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SpecialistCard extends StatelessWidget {
  const _SpecialistCard({
    required this.name,
    required this.specialization,
    required this.photoUrl,
  });

  final String name;
  final String? specialization;
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 138,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: dark ? colors.surfaceContainer : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: .45)),
      ),
      child: Column(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: BrandColors.orange.withValues(alpha: .08),
              border: Border.all(
                color: BrandColors.orange.withValues(alpha: .18),
                width: 2,
              ),
            ),
            child: ClipOval(
              child:
                  photoUrl != null && photoUrl!.trim().isNotEmpty
                      ? CachedNetworkImage(
                        imageUrl: photoUrl!,
                        fit: BoxFit.cover,
                        errorWidget:
                            (_, __, ___) => const Icon(
                              Icons.person_rounded,
                              color: BrandColors.orange,
                              size: 34,
                            ),
                      )
                      : const Icon(
                        Icons.person_rounded,
                        color: BrandColors.orange,
                        size: 34,
                      ),
            ),
          ),

          const SizedBox(height: 9),

          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
          ),

          if (specialization != null && specialization!.trim().isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(
              specialization!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 10, color: colors.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptySpecialists extends StatelessWidget {
  const _EmptySpecialists();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: .45),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(Icons.engineering_outlined, color: BrandColors.orange),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              tr('Сейчас нет доступных специалистов'),
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkExample extends StatelessWidget {
  const _WorkExample({required this.photoUrl, required this.description});

  final String photoUrl;
  final String description;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 185,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(19),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: photoUrl,
              fit: BoxFit.cover,
              errorWidget:
                  (_, __, ___) => Container(
                    color:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: const Icon(Icons.broken_image_outlined),
                  ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: .78),
                    ],
                  ),
                ),
                child: Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomButton extends StatelessWidget {
  const _BottomButton({required this.enabled, required this.onPressed});

  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        9,
        16,
        MediaQuery.paddingOf(context).bottom + 10,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
          top: BorderSide(color: colors.outlineVariant.withValues(alpha: .35)),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: enabled ? onPressed : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: BrandColors.orange,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(17),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.person_search_rounded, size: 20),
              const SizedBox(width: 8),
              Text(
                enabled ? tr('Выбрать специалиста') : tr('Нет специалистов'),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (enabled) ...[
                const SizedBox(width: 6),
                const Icon(Icons.arrow_forward_rounded, size: 19),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CircleAction extends StatelessWidget {
  const _CircleAction({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: colors.surfaceContainerHighest.withValues(alpha: .65),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(width: 42, height: 42, child: Icon(icon, size: 18)),
      ),
    );
  }
}
