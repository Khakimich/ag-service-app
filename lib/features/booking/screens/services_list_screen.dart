import 'package:mobile/core/nav.dart'; // AG_FIX1
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme.dart';
import '../../../models/service.dart';
import '../data/booking_repository.dart';
import '../../../core/i18n.dart'; // AG_I18N1

class ServicesListScreen extends StatefulWidget {
  const ServicesListScreen({super.key, this.initialSearch});

  final String? initialSearch;

  @override
  State<ServicesListScreen> createState() => _ServicesListScreenState();
}

class _ServicesListScreenState extends State<ServicesListScreen> {
  late Future<List<Service>> _future;
  late final TextEditingController _searchCtrl;

  String _query = '';
  String _selectedCategory = 'Все';

  @override
  void initState() {
    super.initState();

    _query = (widget.initialSearch ?? '').trim().toLowerCase();
    _searchCtrl = TextEditingController(text: widget.initialSearch ?? '');
    _searchCtrl.addListener(_onSearch);
    _searchOpen = (widget.initialSearch ?? '').trim().isNotEmpty;

    _future = context.read<BookingRepository>().listServices();
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_onSearch);
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _onSearch() {
    if (!mounted) return;

    setState(() {
      _query = _searchCtrl.text.trim().toLowerCase();
    });
  }

  void _retry() {
    setState(() {
      _future = context.read<BookingRepository>().listServices();
    });
  }

  List<String> _categories(List<Service> services) {
    final values = <String>[];

    for (final service in services) {
      final category = service.category.trim();

      if (category.isEmpty || category == 'Без категории') {
        continue;
      }

      if (!values.contains(category)) {
        values.add(category);
      }
    }

    values.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    return ['Все', ...values];
  }

  List<Service> _filtered(List<Service> services) {
    return services
        .where((service) {
          final categoryMatches =
              _selectedCategory == 'Все' ||
              service.category == _selectedCategory;

          if (!categoryMatches) return false;

          if (_query.isEmpty) return true;

          final searchable =
              [
                service.title,
                service.description ?? '',
                service.category,
              ].join(' ').toLowerCase();

          return searchable.contains(_query);
        })
        .toList(growable: false);
  }

  String _iconForCategory(String category) {
    final value = category.toLowerCase();

    if (category == 'Все') {
      return 'assets/icons/services/categories/all.png';
    }

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

  void _openCategoriesCatalog(List<Service> services, List<String> categories) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: .55),
      builder: (sheetContext) {
        final colors = Theme.of(sheetContext).colorScheme;
        final isDark = Theme.of(sheetContext).brightness == Brightness.dark;

        int countFor(String category) {
          if (category == 'Все') {
            return services.length;
          }

          return services.where((s) => s.category == category).length;
        }

        return FractionallySizedBox(
          heightFactor: .82,
          child: Container(
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(30),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .22),
                  blurRadius: 30,
                  offset: const Offset(0, -8),
                ),
              ],
            ),
            child: Column(
              children: [
                const SizedBox(height: 10),

                Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: colors.onSurfaceVariant.withValues(alpha: .28),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 14, 14),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: BrandColors.orange.withValues(alpha: .12),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.grid_view_rounded,
                          color: BrandColors.orange,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tr('Каталог услуг'),
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -.4,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              trf('{0} услуг в {1} категориях', [services.length, categories.length - 1]),
                              style: TextStyle(
                                color: colors.onSurfaceVariant,
                                fontSize: 12.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: tr('Закрыть'),
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),

                Divider(
                  height: 1,
                  color: colors.outlineVariant.withValues(alpha: .45),
                ),

                Expanded(
                  child: GridView.builder(
                    padding: EdgeInsets.fromLTRB(16, 18, 16, 110 + MediaQuery.paddingOf(sheetContext).bottom),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.45,
                        ),
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      final selected = category == _selectedCategory;
                      final count = countFor(category);

                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(22),
                          onTap: () {
                            setState(() {
                              _selectedCategory = category;
                            });

                            Navigator.of(sheetContext).pop();
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color:
                                  selected
                                      ? BrandColors.orange
                                      : isDark
                                      ? const Color(0xFF1B1E22)
                                      : colors.surfaceContainerHighest
                                          .withValues(alpha: .55),
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color:
                                    selected
                                        ? BrandColors.orange
                                        : colors.outlineVariant.withValues(
                                          alpha: .55,
                                        ),
                              ),
                              boxShadow: [
                                if (selected)
                                  BoxShadow(
                                    color: BrandColors.orange.withValues(
                                      alpha: .22,
                                    ),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 58,
                                      height: 58,
                                      padding: const EdgeInsets.all(5),
                                      decoration: BoxDecoration(
                                        color:
                                            selected
                                                ? Colors.white.withValues(
                                                  alpha: .18,
                                                )
                                                : BrandColors.orange.withValues(
                                                  alpha: .10,
                                                ),
                                        borderRadius: BorderRadius.circular(13),
                                      ),
                                      child: Image.asset(
                                        _iconForCategory(category),
                                        fit: BoxFit.contain,
                                        errorBuilder: (
                                          context,
                                          error,
                                          stackTrace,
                                        ) {
                                          return Icon(
                                            Icons.car_repair_rounded,
                                            color:
                                                selected
                                                    ? Colors.white
                                                    : BrandColors.orange,
                                            size: 38,
                                          );
                                        },
                                      ),
                                    ),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            selected
                                                ? Colors.white.withValues(
                                                  alpha: .18,
                                                )
                                                : isDark
                                                ? Colors.white.withValues(
                                                  alpha: .12,
                                                )
                                                : const Color(
                                                  0xFF16A34A,
                                                ).withValues(alpha: .12),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        '$count',
                                        style: TextStyle(
                                          color:
                                              selected
                                                  ? Colors.white
                                                  : isDark
                                                  ? Colors.white
                                                  : const Color(0xFF16A34A),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                Text(
                                  category == 'Все' ? tr('Все услуги') : category,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color:
                                        selected
                                            ? Colors.white
                                            : colors.onSurface,
                                    fontSize: 13,
                                    height: 1.15,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // AG_SVC2 — новый экран услуг: поиск по кнопке-лупе, лента категорий, сетка карточек
  bool _searchOpen = false;
  final FocusNode _searchFocus = FocusNode();

  void _toggleSearch() {
    setState(() => _searchOpen = !_searchOpen);
    if (_searchOpen) {
      Future.delayed(const Duration(milliseconds: 120), () { if (mounted) _searchFocus.requestFocus(); });
    } else {
      _searchCtrl.clear();
      _searchFocus.unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        bottom: false,
        child: FutureBuilder<List<Service>>(
          future: _future,
          builder: (context, snapshot) {
            final loading = snapshot.connectionState == ConnectionState.waiting;
            final services = snapshot.data ?? const <Service>[];
            final categories = _categories(services);
            if (!categories.contains(_selectedCategory)) _selectedCategory = 'Все';
            final filtered = _filtered(services);

            return Column(
              children: [
                _AgSvcTopBar(
                  total: services.length,
                  searchOpen: _searchOpen,
                  controller: _searchCtrl,
                  focusNode: _searchFocus,
                  onBack: () => context.agBack(), // AG_FIX1
                  onToggleSearch: _toggleSearch,
                ),
                if (!loading && !snapshot.hasError && services.isNotEmpty)
                  _AgCategoryStrip(
                    categories: categories,
                    selected: _selectedCategory,
                    countFor: (c) => c == 'Все' ? services.length : services.where((s) => s.category == c).length,
                    iconFor: _iconForCategory,
                    onSelect: (c) => setState(() => _selectedCategory = c),
                    onOpenCatalog: () => _openCategoriesCatalog(services, categories),
                  ),
                Expanded(
                  child: loading
                      ? const _LoadingState()
                      : snapshot.hasError
                          ? _ErrorState(message: snapshot.error.toString(), onRetry: _retry)
                          : AnimatedSwitcher(
                              duration: const Duration(milliseconds: 220),
                              child: _buildList(services, filtered, key: ValueKey('$_selectedCategory|$_query')),
                            ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildList(
    List<Service> services,
    List<Service> filtered, {
    required Key key,
  }) {
    if (services.isEmpty) {
      return _EmptyState(
        key: key,
        title: tr('Услуги пока не добавлены'),
        subtitle: tr('Когда услуги появятся, они будут доступны здесь.'),
      );
    }

    if (filtered.isEmpty) {
      return _EmptyState(
        key: key,
        title: tr('Ничего не найдено'),
        subtitle: tr('Попробуйте другую категорию или измените запрос.'),
        actionText: tr('Сбросить фильтры'),
        onAction: () {
          _searchCtrl.clear();
          setState(() => _selectedCategory = 'Все');
        },
      );
    }

    return RefreshIndicator(
      key: key,
      color: BrandColors.orange,
      onRefresh: () async {
        final future = context.read<BookingRepository>().listServices();
        setState(() => _future = future);
        await future;
      },
      child: LayoutBuilder(
        builder: (context, c) {
          final cols = c.maxWidth >= 900 ? 4 : c.maxWidth >= 600 ? 3 : 2;
          return CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 6, 18, 10),
                sliver: SliverToBoxAdapter(
                  child: Row(children: [
                    Expanded(
                      child: Text(
                        _query.isNotEmpty
                            ? trf('Найдено: {0}', [filtered.length])
                            : (_selectedCategory == 'Все' ? tr('Все услуги') : _selectedCategory),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, letterSpacing: -.3),
                      ),
                    ),
                    Text('${filtered.length}',
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontWeight: FontWeight.w700)),
                  ]),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 120 + MediaQuery.paddingOf(context).bottom),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: cols,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    mainAxisExtent: 238,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => _AgServiceTile(service: filtered[i], iconAsset: _iconForCategory(filtered[i].category)),
                    childCount: filtered.length,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/* ===================== AG_SVC2: верхняя панель с кнопкой поиска ===================== */
class _AgSvcTopBar extends StatelessWidget {
  const _AgSvcTopBar({
    required this.total,
    required this.searchOpen,
    required this.controller,
    required this.focusNode,
    required this.onBack,
    required this.onToggleSearch,
  });

  final int total;
  final bool searchOpen;
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onBack;
  final VoidCallback onToggleSearch;

  Widget _round(BuildContext context, IconData icon, VoidCallback onTap, {bool accent = false}) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: accent ? BrandColors.orange : colors.surfaceContainerHighest.withValues(alpha: .7),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: SizedBox(width: 46, height: 46, child: Icon(icon, size: 23, color: accent ? Colors.white : colors.onSurface)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        transitionBuilder: (child, a) => FadeTransition(
          opacity: a,
          child: SizeTransition(sizeFactor: a, axis: Axis.horizontal, axisAlignment: 1, child: child),
        ),
        child: searchOpen
            ? Row(key: const ValueKey('s'), children: [
                Expanded(
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerHighest.withValues(alpha: .7),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: BrandColors.orange.withValues(alpha: .55), width: 1.5),
                    ),
                    child: Row(children: [
                      const SizedBox(width: 12),
                      const Icon(Icons.search_rounded, color: BrandColors.orange),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: controller,
                          focusNode: focusNode,
                          textInputAction: TextInputAction.search,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          decoration: InputDecoration(
                            isCollapsed: true,
                            border: InputBorder.none,
                            hintText: tr('Найти услугу'),
                          ),
                        ),
                      ),
                      ValueListenableBuilder<TextEditingValue>(
                        valueListenable: controller,
                        builder: (_, v, __) => v.text.isEmpty
                            ? const SizedBox(width: 10)
                            : IconButton(
                                visualDensity: VisualDensity.compact,
                                onPressed: controller.clear,
                                icon: Icon(Icons.cancel_rounded, size: 20, color: colors.onSurfaceVariant),
                              ),
                      ),
                    ]),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: onToggleSearch,
                  child: Text(tr('Отмена'), style: const TextStyle(color: BrandColors.orange, fontWeight: FontWeight.w800)),
                ),
              ])
            : Row(key: const ValueKey('t'), children: [
                _round(context, Icons.arrow_back_ios_new_rounded, onBack),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(tr('Услуги'), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: -.6, height: 1.05)),
                    if (total > 0)
                      Text(trf('{0} услуг автосервиса', [total]),
                          style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12.5, fontWeight: FontWeight.w600)),
                  ]),
                ),
                _round(context, Icons.search_rounded, onToggleSearch, accent: true),
              ]),
      ),
    );
  }
}

/* ===================== AG_SVC2: лента категорий ===================== */
class _AgCategoryStrip extends StatelessWidget {
  const _AgCategoryStrip({
    required this.categories,
    required this.selected,
    required this.countFor,
    required this.iconFor,
    required this.onSelect,
    required this.onOpenCatalog,
  });

  final List<String> categories;
  final String selected;
  final int Function(String) countFor;
  final String Function(String) iconFor;
  final ValueChanged<String> onSelect;
  final VoidCallback onOpenCatalog;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      height: 104,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
        itemCount: categories.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          if (i == categories.length) {
            return _chip(context, colors, isDark,
                label: tr('Все категории'), on: false, onTap: onOpenCatalog,
                icon: const Icon(Icons.grid_view_rounded, color: BrandColors.orange, size: 26));
          }
          final c = categories[i];
          final on = c == selected;
          return _chip(context, colors, isDark,
              label: c == 'Все' ? tr('Все') : c,
              badge: countFor(c),
              on: on,
              onTap: () => onSelect(c),
              icon: Image.asset(iconFor(c), width: 34, height: 34, fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Icon(Icons.car_repair_rounded, color: on ? Colors.white : BrandColors.orange)));
        },
      ),
    );
  }

  Widget _chip(BuildContext context, ColorScheme colors, bool isDark,
      {required String label, required bool on, required VoidCallback onTap, required Widget icon, int? badge}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 84,
        padding: const EdgeInsets.fromLTRB(6, 9, 6, 7),
        decoration: BoxDecoration(
          color: on ? BrandColors.orange : (isDark ? const Color(0xFF1B1E22) : const Color(0xFFFFF4EC)),
          borderRadius: BorderRadius.circular(20),
          boxShadow: on ? [BoxShadow(color: BrandColors.orange.withValues(alpha: .3), blurRadius: 14, offset: const Offset(0, 6))] : null,
        ),
        child: Column(children: [
          Container(
            width: 42,
            height: 42,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: on ? Colors.white : Colors.white.withValues(alpha: isDark ? .08 : 1), borderRadius: BorderRadius.circular(13)),
            child: Center(child: icon),
          ),
          const Spacer(),
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11.5, height: 1.1, fontWeight: FontWeight.w800, color: on ? Colors.white : colors.onSurface)),
          if (badge != null)
            Text('$badge', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: on ? Colors.white70 : colors.onSurfaceVariant)),
        ]),
      ),
    );
  }
}

/* ===================== AG_SVC2: карточка услуги в сетке ===================== */
class _AgServiceTile extends StatelessWidget {
  const _AgServiceTile({required this.service, required this.iconAsset});

  final Service service;
  final String iconAsset;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasDiscount = service.discountTag != null && service.discountTag!.trim().isNotEmpty;
    return Material(
      color: isDark ? const Color(0xFF16191D) : Colors.white,
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      child: InkWell(
        onTap: () => context.push('/services/${service.id}'),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: colors.outlineVariant.withValues(alpha: .45)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(
              height: 112,
              width: double.infinity,
              child: Stack(fit: StackFit.expand, children: [
                _ServiceImage(photoUrl: service.photoUrl, iconAsset: iconAsset),
                if (hasDiscount)
                  Positioned(
                    left: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: const Color(0xFFDC2626), borderRadius: BorderRadius.circular(9)),
                      child: Text(service.discountTag!, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900)),
                    ),
                  ),
                Positioned(
                  right: 8,
                  bottom: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                    decoration: BoxDecoration(color: Colors.black.withValues(alpha: .55), borderRadius: BorderRadius.circular(9)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.schedule_rounded, size: 12, color: Colors.white),
                      const SizedBox(width: 3),
                      Text(service.durationLabel, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                    ]),
                  ),
                ),
              ]),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(service.category,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: BrandColors.orange, fontSize: 11, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 3),
                  Text(service.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14.5, height: 1.2, fontWeight: FontWeight.w800, letterSpacing: -.2)),
                  const Spacer(),
                  Row(children: [
                    Expanded(
                      child: Text(service.priceLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w900, letterSpacing: -.3)),
                    ),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(color: BrandColors.orange, borderRadius: BorderRadius.circular(11)),
                      child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                    ),
                  ]),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _ServicesHeader extends StatelessWidget {
  const _ServicesHeader({required this.totalCount, required this.onBack});

  final int totalCount;
  final VoidCallback onBack;

  String _servicesText(int count) {
    final mod10 = count % 10;
    final mod100 = count % 100;

    if (mod10 == 1 && mod100 != 11) {
      return trf('{0} услуга', [count]);
    }

    if (mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14)) {
      return trf('{0} услуги', [count]);
    }

    return trf('{0} услуг', [count]);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
          bottom: BorderSide(
            color: colors.outlineVariant.withValues(alpha: .35),
          ),
        ),
      ),
      child: Row(
        children: [
          Material(
            color: colors.surfaceContainerHighest.withValues(alpha: .6),
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: onBack,
              borderRadius: BorderRadius.circular(16),
              child: const SizedBox(
                width: 48,
                height: 48,
                child: Icon(Icons.arrow_back_ios_new_rounded, size: 19),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr('Услуги'),
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -.5,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  trf('Автосервис  •  {0}', [_servicesText(totalCount)]),
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 45,
            height: 45,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: BrandColors.orange.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: SvgPicture.asset('assets/icons/services/car.svg'),
          ),
        ],
      ),
    );
  }
}

class _SearchBox extends StatelessWidget {
  const _SearchBox({required this.controller, required this.onClear});

  final TextEditingController controller;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
      child: Container(
        height: 58,
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest.withValues(alpha: .62),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: colors.outlineVariant.withValues(alpha: .45),
          ),
        ),
        child: TextField(
          controller: controller,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: tr('Поиск услуги...'),
            hintStyle: TextStyle(color: colors.onSurfaceVariant, fontSize: 14),
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: BrandColors.orange,
              size: 22,
            ),
            suffixIcon: ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (_, value, __) {
                if (value.text.isEmpty) {
                  return const SizedBox.shrink();
                }

                return IconButton(
                  tooltip: tr('Очистить'),
                  onPressed: onClear,
                  icon: const Icon(Icons.close_rounded, size: 19),
                );
              },
            ),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 15),
          ),
        ),
      ),
    );
  }
}

class _CatalogButton extends StatelessWidget {
  const _CatalogButton({
    required this.selectedCategory,
    required this.categoryCount,
    required this.onTap,
  });

  final String selectedCategory;
  final int categoryCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 7, 18, 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            height: 58,
            padding: const EdgeInsets.symmetric(horizontal: 15),
            decoration: BoxDecoration(
              color:
                  isDark
                      ? const Color(0xFF1B1E22)
                      : colors.surfaceContainerHighest.withValues(alpha: .48),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: colors.outlineVariant.withValues(alpha: .5),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: BrandColors.orange.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.menu_rounded,
                    color: BrandColors.orange,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr('Каталог услуг'),
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        selectedCategory == 'Все'
                            ? trf('{0} категорий', [categoryCount])
                            : selectedCategory,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color:
                              selectedCategory == 'Все'
                                  ? colors.onSurfaceVariant
                                  : BrandColors.orange,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: BrandColors.orange,
                  size: 25,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryChip extends StatefulWidget {
  const _CategoryChip({
    required this.category,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String category;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_CategoryChip> createState() => _CategoryChipState();
}

class _CategoryChipState extends State<_CategoryChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selected = widget.selected;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) {
        if (!_hovered) {
          setState(() => _hovered = true);
        }
      },
      onExit: (_) {
        if (_hovered) {
          setState(() => _hovered = false);
        }
      },
      child: AnimatedScale(
        scale: _hovered ? 1.035 : 1.0,
        duration: const Duration(milliseconds: 190),
        curve: Curves.easeOutCubic,
        child: AnimatedSlide(
          offset: _hovered ? const Offset(0, -0.06) : Offset.zero,
          duration: const Duration(milliseconds: 190),
          curve: Curves.easeOutCubic,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(16),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 190),
                curve: Curves.easeOutCubic,
                constraints: const BoxConstraints(minHeight: 46),
                padding: const EdgeInsets.fromLTRB(14, 9, 9, 9),
                decoration: BoxDecoration(
                  color:
                      selected
                          ? BrandColors.orange
                          : _hovered
                          ? Color.alphaBlend(
                            BrandColors.orange.withValues(alpha: .08),
                            isDark ? const Color(0xFF1B2127) : Colors.white,
                          )
                          : isDark
                          ? const Color(0xFF1B2127)
                          : colors.surfaceContainerHighest.withValues(
                            alpha: .55,
                          ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    width: _hovered || selected ? 1.2 : 1,
                    color:
                        selected
                            ? BrandColors.orange
                            : _hovered
                            ? BrandColors.orange.withValues(alpha: .65)
                            : colors.outlineVariant.withValues(alpha: .48),
                  ),
                  boxShadow: [
                    if (_hovered)
                      BoxShadow(
                        color: BrandColors.orange.withValues(
                          alpha: isDark ? .18 : .13,
                        ),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    if (selected)
                      BoxShadow(
                        color: BrandColors.orange.withValues(alpha: .20),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 190),
                      curve: Curves.easeOutCubic,
                      style: TextStyle(
                        color:
                            selected
                                ? Colors.white
                                : _hovered
                                ? BrandColors.orange
                                : colors.onSurface,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -.15,
                      ),
                      child: Text(widget.category),
                    ),
                    const SizedBox(width: 8),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 190),
                      curve: Curves.easeOutCubic,
                      constraints: const BoxConstraints(
                        minWidth: 28,
                        minHeight: 26,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color:
                            selected
                                ? Colors.white.withValues(alpha: .18)
                                : _hovered
                                ? BrandColors.orange.withValues(alpha: .12)
                                : colors.surface.withValues(
                                  alpha: isDark ? .45 : .85,
                                ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${widget.count}',
                        style: TextStyle(
                          color:
                              selected
                                  ? Colors.white
                                  : _hovered
                                  ? BrandColors.orange
                                  : colors.onSurfaceVariant,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({required this.service, required this.iconAsset});

  final Service service;
  final String iconAsset;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push('/services/${service.id}'),
        borderRadius: BorderRadius.circular(24),
        child: Container(
          height: 146,
          decoration: BoxDecoration(
            color: colors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: colors.outlineVariant.withValues(alpha: .5),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? .15 : .055),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 128,
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(23),
                    bottomLeft: Radius.circular(23),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _ServiceImage(
                        photoUrl: service.photoUrl,
                        iconAsset: iconAsset,
                      ),
                      if (service.discountTag != null &&
                          service.discountTag!.trim().isNotEmpty)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: BrandColors.orange,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              service.discountTag!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              service.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 16,
                                height: 1.22,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -.15,
                              ),
                            ),
                          ),
                          const SizedBox(width: 5),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 14,
                            color: colors.onSurfaceVariant,
                          ),
                        ],
                      ),
                      const SizedBox(height: 7),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: BrandColors.orange.withValues(alpha: .08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          service.category,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: BrandColors.orange,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Icon(
                            Icons.schedule_rounded,
                            size: 15,
                            color: colors.onSurfaceVariant,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            service.durationLabel,
                            style: TextStyle(
                              color: colors.onSurfaceVariant,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Text(
                            service.priceLabel,
                            style: const TextStyle(
                              color: BrandColors.orange,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          if (service.discountPrice != null) ...[
                            const SizedBox(width: 7),
                            Flexible(
                              child: Text(
                                '${service.priceFrom.round()} ₽',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: colors.onSurfaceVariant,
                                  fontSize: 11,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServiceImage extends StatelessWidget {
  const _ServiceImage({required this.photoUrl, required this.iconAsset});

  final String? photoUrl;
  final String iconAsset;

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoUrl != null && photoUrl!.trim().isNotEmpty;

    if (hasPhoto) {
      return CachedNetworkImage(
        imageUrl: photoUrl!,
        fit: BoxFit.cover,
        placeholder: (_, __) => _CategoryImagePlaceholder(iconAsset: iconAsset),
        errorWidget:
            (_, __, ___) => _CategoryImagePlaceholder(iconAsset: iconAsset),
      );
    }

    return _CategoryImagePlaceholder(iconAsset: iconAsset);
  }
}

class _CategoryImagePlaceholder extends StatelessWidget {
  const _CategoryImagePlaceholder({required this.iconAsset});

  final String iconAsset;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            BrandColors.orange.withValues(alpha: .13),
            BrandColors.orange.withValues(alpha: .035),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final shortestSide = constraints.biggest.shortestSide;

          // Иконка автоматически подстраивается под размер области.
          final iconSize = (shortestSide * .64).clamp(62.0, 94.0);

          return Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              width: iconSize,
              height: iconSize,
              child: Image.asset(
                iconAsset,
                width: iconSize,
                height: iconSize,
                fit: BoxFit.contain,
                alignment: Alignment.center,
                filterQuality: FilterQuality.high,
                gaplessPlayback: true,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.car_repair_rounded,
                    color: BrandColors.orange,
                    size: iconSize * .62,
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 75),
        const CircularProgressIndicator(color: BrandColors.orange),
        const SizedBox(height: 16),
        Text(
          tr('Загружаем услуги...'),
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    super.key,
    required this.title,
    required this.subtitle,
    this.actionText,
    this.onAction,
  });

  final String title;
  final String subtitle;
  final String? actionText;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 82,
              height: 82,
              padding: const EdgeInsets.all(21),
              decoration: BoxDecoration(
                color: BrandColors.orange.withValues(alpha: .09),
                shape: BoxShape.circle,
              ),
              child: SvgPicture.asset('assets/icons/services/car.svg'),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.onSurfaceVariant,
                height: 1.4,
                fontSize: 13,
              ),
            ),
            if (actionText != null && onAction != null) ...[
              const SizedBox(height: 18),
              OutlinedButton(
                onPressed: onAction,
                style: OutlinedButton.styleFrom(
                  foregroundColor: BrandColors.orange,
                ),
                child: Text(actionText!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 50,
              color: BrandColors.orange,
            ),
            const SizedBox(height: 14),
            Text(
              tr('Не удалось загрузить услуги'),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 7),
            Text(
              message,
              textAlign: TextAlign.center,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: BrandColors.orange,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.refresh_rounded),
              label: Text(tr('Повторить')),
            ),
          ],
        ),
      ),
    );
  }
}
