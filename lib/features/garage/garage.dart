// AG_RENT1 — «AG Гараж»: аренда автомобилей.
// Машины добавляют сотрудники в job.autogrom.ru → AG Service → «AG Гараж».
// Список берём с https://job.autogrom.ru/ag_rent_feed.php, заявка на аренду уходит
// в чат клиента с «Автосервисом AUTOGROM» (как эвакуатор и кузовной ремонт).
import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../../core/i18n.dart';
import '../auth/providers/auth_provider.dart';
import '../chat/data/chat_repository.dart';

const _feedUrl = 'https://job.autogrom.ru/ag_rent_feed.php';
const _o = Color(0xFFFF6A00);
const _o2 = Color(0xFFFF8A2A);
const _dept = 'autogrom_service';

// ───────────────────────── Модель ─────────────────────────
class RentCar {
  RentCar.fromJson(Map<String, dynamic> j)
      : id = (j['id'] as num?)?.toInt() ?? 0,
        brand = (j['brand'] ?? '').toString(),
        model = (j['model'] ?? '').toString(),
        year = (j['year'] as num?)?.toInt(),
        carClass = (j['class'] ?? '').toString(),
        classTitle = (j['class_title'] ?? '').toString(),
        gearbox = (j['gearbox'] ?? '').toString(),
        gearboxTitle = (j['gearbox_title'] ?? '').toString(),
        fuelTitle = (j['fuel_title'] ?? '').toString(),
        color = (j['color'] ?? '').toString(),
        seats = (j['seats'] as num?)?.toInt() ?? 5,
        priceDay = (j['price_day'] as num?)?.toInt() ?? 0,
        priceWeekDay = (j['price_week_day'] as num?)?.toInt() ?? 0,
        deposit = (j['deposit'] as num?)?.toInt() ?? 0,
        minDays = (j['min_days'] as num?)?.toInt() ?? 1,
        forTaxi = j['for_taxi'] == true,
        description = (j['description'] ?? '').toString(),
        features = [
          for (final f in (j['features'] as List? ?? const []))
            if (f is Map) (f['title'] ?? '').toString()
        ],
        photos = [for (final p in (j['photos'] as List? ?? const [])) p.toString()],
        status = (j['status'] ?? 'available').toString();

  final int id, seats, priceDay, priceWeekDay, deposit, minDays;
  final int? year;
  final String brand, model, carClass, classTitle, gearbox, gearboxTitle, fuelTitle, color, description, status;
  final bool forTaxi;
  final List<String> features, photos;

  String get title => '$brand $model'.trim();
  bool get available => status == 'available';
  /// Минимальная цена суток (с учётом скидки от 7 дней).
  int get priceFrom => priceWeekDay > 0 && priceWeekDay < priceDay ? priceWeekDay : priceDay;
  int dayPrice(int days) => days >= 7 && priceWeekDay > 0 ? priceWeekDay : priceDay;
}

String _money(int v) {
  final s = v.toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(' ');
    b.write(s[i]);
  }
  return '$b ₽';
}

String _daysWord(int n) {
  final m10 = n % 10, m100 = n % 100;
  if (m10 == 1 && m100 != 11) return tr('сутки');
  return tr('суток');
}

Future<List<RentCar>> _loadCars() async {
  final r = await http.get(Uri.parse(_feedUrl)).timeout(const Duration(seconds: 20));
  if (r.statusCode != 200) throw Exception('HTTP ${r.statusCode}');
  final data = jsonDecode(utf8.decode(r.bodyBytes));
  final list = (data is Map ? data['cars'] : null) as List? ?? const [];
  return [for (final e in list) if (e is Map<String, dynamic>) RentCar.fromJson(e)];
}

// ───────────────────────── SVG-иконки ─────────────────────────
class _I {
  static String _l(String p, [String c = '#FF6A00', double w = 2]) =>
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="$c" stroke-width="$w" stroke-linecap="round" stroke-linejoin="round">$p</svg>';
  static String back([String c = '#FFFFFF']) => _l('<path d="M15 5l-7 7 7 7"/>', c, 2.6);
  static String car([String c = '#FF6A00']) => _l('<path d="M5 16.5V12.5l1.8-4.6A2 2 0 0 1 8.7 6.6h6.6a2 2 0 0 1 1.9 1.3L19 12.5v4"/><path d="M3.5 12.5h17V17a1 1 0 0 1-1 1h-15a1 1 0 0 1-1-1z"/><path d="M6.5 18v1.5M17.5 18v1.5"/><circle cx="7.5" cy="15" r=".8"/><circle cx="16.5" cy="15" r=".8"/>', c);
  static String key([String c = '#FFFFFF']) => _l('<circle cx="8" cy="15" r="4"/><path d="M10.8 12.2L19 4M16 7l2.5 2.5M14 9l2 2"/>', c, 2.2);
  static String gear([String c = '#FF6A00']) => _l('<circle cx="6" cy="6" r="1.8"/><circle cx="12" cy="6" r="1.8"/><circle cx="18" cy="6" r="1.8"/><circle cx="6" cy="18" r="1.8"/><circle cx="12" cy="18" r="1.8"/><path d="M6 8v8M12 8v8M18 8v4H6"/>', c, 1.8);
  static String fuel([String c = '#FF6A00']) => _l('<path d="M4 20V5a2 2 0 0 1 2-2h6a2 2 0 0 1 2 2v15M3 20h12M4 10h10"/><path d="M14 8h2a2 2 0 0 1 2 2v6a1.5 1.5 0 0 0 3 0V9l-3-3"/>', c, 1.8);
  static String cal([String c = '#FF6A00']) => _l('<rect x="3.5" y="5" width="17" height="15.5" rx="3"/><path d="M3.5 10h17M8 3v4M16 3v4"/>', c, 1.8);
  static String seat([String c = '#FF6A00']) => _l('<circle cx="9" cy="7" r="3"/><path d="M3.5 20a5.5 5.5 0 0 1 11 0M16 4a3 3 0 0 1 0 6M17.5 14a5 5 0 0 1 3 6"/>', c, 1.8);
  static String palette([String c = '#FF6A00']) => _l('<path d="M12 3a9 9 0 1 0 0 18c1.2 0 2-.8 2-1.8 0-1-1-1.6-1-2.6 0-1 .8-1.8 1.8-1.8H17a4 4 0 0 0 4-4C21 6.6 17 3 12 3z"/><circle cx="7.5" cy="11" r="1"/><circle cx="10.5" cy="7" r="1"/><circle cx="15" cy="7.5" r="1"/>', c, 1.8);
  static String star([String c = '#FF6A00']) => _l('<path d="M12 3.5l2.5 5.2 5.7.8-4.1 4 1 5.6-5.1-2.7-5.1 2.7 1-5.6-4.1-4 5.7-.8z"/>', c, 1.8);
  static String check([String c = '#16A34A']) => _l('<path d="M5 12.5l4.5 4.5L19 7.5"/>', c, 2.6);
  static String taxi([String c = '#A16207']) => _l('<path d="M9.5 3.5h5l.8 2.5"/><path d="M5 16.5v-4l1.8-4.6A2 2 0 0 1 8.7 6.6h6.6a2 2 0 0 1 1.9 1.3L19 12.5v4"/><path d="M3.5 12.5h17v4.5a1 1 0 0 1-1 1h-15a1 1 0 0 1-1-1z"/>', c, 2);
  static String shield([String c = '#FF6A00']) => _l('<path d="M12 3l7 3v5c0 4.5-3 8.2-7 10-4-1.8-7-5.5-7-10V6z"/><path d="M9 12l2 2 4-4"/>', c, 1.8);
  static String phone([String c = '#FF6A00']) => _l('<path d="M5 4h3.5l1.8 4.5-2.3 1.4a11 11 0 0 0 6.1 6.1l1.4-2.3L20 15.5V19a2 2 0 0 1-2 2A16 16 0 0 1 3 6a2 2 0 0 1 2-2z"/>', c, 1.9);
  static String note([String c = '#FF6A00']) => _l('<path d="M5 4h14v16H5z"/><path d="M8.5 9h7M8.5 13h7M8.5 17h4"/>', c, 1.8);
  static String minus([String c = '#FF6A00']) => _l('<path d="M6 12h12"/>', c, 2.6);
  static String plus([String c = '#FF6A00']) => _l('<path d="M12 6v12M6 12h12"/>', c, 2.6);
  static String bell([String c = '#FF6A00']) => _l('<path d="M6 16v-5a6 6 0 0 1 12 0v5l1.5 2h-15z"/><path d="M10 20a2 2 0 0 0 4 0"/>', c, 1.9);
  static String refresh([String c = '#FF6A00']) => _l('<path d="M20 11a8 8 0 1 0-2.3 5.7"/><path d="M20 4v7h-7"/>', c, 2.2);
}

Widget _svg(String s, double size) => SvgPicture.string(s, width: size, height: size);

bool _dark(BuildContext c) => Theme.of(c).brightness == Brightness.dark;
Color _bg(BuildContext c) => _dark(c) ? const Color(0xFF111113) : const Color(0xFFF4F5F7);
Color _card(BuildContext c) => _dark(c) ? const Color(0xFF1B1E22) : Colors.white;
Color _soft(BuildContext c) => _dark(c) ? const Color(0xFF24282D) : const Color(0xFFF4F5F7);

// ───────────────────────── Список машин ─────────────────────────
class GarageScreen extends StatefulWidget {
  const GarageScreen({super.key});
  @override
  State<GarageScreen> createState() => _GarageScreenState();
}

class _GarageScreenState extends State<GarageScreen> {
  List<RentCar>? _cars;
  bool _error = false;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = false);
    try {
      final cars = await _loadCars();
      if (mounted) setState(() => _cars = cars);
    } catch (_) {
      if (mounted) setState(() => _error = true);
    }
  }

  List<(String, String)> get _filters {
    final cars = _cars ?? const <RentCar>[];
    final f = <(String, String)>[('all', tr('Все'))];
    if (cars.any((c) => c.forTaxi)) f.add(('taxi', tr('Для такси')));
    if (cars.any((c) => c.gearbox == 'auto' || c.gearbox == 'robot' || c.gearbox == 'cvt')) f.add(('auto', tr('Автомат')));
    final seen = <String>{};
    for (final c in cars) {
      if (c.carClass.isNotEmpty && c.classTitle.isNotEmpty && seen.add(c.carClass)) f.add(('class:${c.carClass}', c.classTitle));
    }
    return f;
  }

  List<RentCar> get _shown {
    final cars = _cars ?? const <RentCar>[];
    return switch (_filter) {
      'all' => cars,
      'taxi' => cars.where((c) => c.forTaxi).toList(),
      'auto' => cars.where((c) => c.gearbox != 'manual').toList(),
      _ when _filter.startsWith('class:') => cars.where((c) => 'class:${c.carClass}' == _filter).toList(),
      _ => cars,
    };
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final cars = _cars;
    final free = cars?.where((c) => c.available).length ?? 0;
    return Scaffold(
      backgroundColor: _bg(context),
      body: RefreshIndicator(
        color: _o,
        onRefresh: _load,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // шапка
            SliverToBoxAdapter(
              child: Container(
                padding: EdgeInsets.fromLTRB(18, top + 8, 18, 26),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
                      colors: [Color(0xFFFF8A2A), Color(0xFFFF6A00), Color(0xFFE85500)]),
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _RoundBtn(icon: _I.back(), onTap: () => context.canPop() ? context.pop() : context.go('/')),
                  const SizedBox(height: 16),
                  Row(children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('AG Гараж', style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900, letterSpacing: -.8)),
                        const SizedBox(height: 4),
                        Text(tr('Аренда авто для работы в такси и поездок'),
                            style: TextStyle(color: Colors.white.withValues(alpha: .92), fontSize: 14.5, fontWeight: FontWeight.w600, height: 1.3)),
                      ]),
                    ),
                    Container(
                      width: 64, height: 64, alignment: Alignment.center,
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: .18), borderRadius: BorderRadius.circular(20)),
                      child: _svg(_I.key(), 34),
                    ),
                  ]),
                  if (cars != null && cars.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Wrap(spacing: 8, runSpacing: 8, children: [
                      _HeadChip(text: trf('{0} свободно', [free])),
                      _HeadChip(text: trf('от {0} в сутки', [_money(cars.map((c) => c.priceFrom).reduce((a, b) => a < b ? a : b))])),
                    ]),
                  ],
                ]),
              ),
            ),
            if (cars != null && cars.isNotEmpty)
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 60,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
                    children: [
                      for (final f in _filters)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _FilterChip(text: f.$2, on: _filter == f.$1, onTap: () => setState(() => _filter = f.$1)),
                        ),
                    ],
                  ),
                ),
              ),
            if (_error && cars == null)
              SliverFillRemaining(hasScrollBody: false, child: _Message(
                title: tr('Не удалось загрузить машины'),
                text: tr('Проверьте интернет и попробуйте ещё раз.'),
                action: tr('Повторить'),
                onAction: _load,
              ))
            else if (cars == null)
              const SliverFillRemaining(hasScrollBody: false, child: Center(child: CircularProgressIndicator(color: _o)))
            else if (cars.isEmpty)
              SliverFillRemaining(hasScrollBody: false, child: _Message(
                title: tr('Скоро здесь появятся машины'),
                text: tr('Мы готовим автопарк для аренды. Загляните чуть позже.'),
              ))
            else
              SliverPadding(
                padding: EdgeInsets.fromLTRB(14, 8, 14, 28 + MediaQuery.paddingOf(context).bottom),
                sliver: SliverList.separated(
                  itemCount: _shown.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (_, i) => _CarCard(car: _shown[i]),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RoundBtn extends StatelessWidget {
  const _RoundBtn({required this.icon, required this.onTap, this.dark = false});
  final String icon;
  final VoidCallback onTap;
  final bool dark;
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40, height: 40, alignment: Alignment.center,
          decoration: BoxDecoration(
            color: dark ? Colors.black.withValues(alpha: .35) : Colors.white.withValues(alpha: .2),
            borderRadius: BorderRadius.circular(14),
          ),
          child: _svg(icon, 20),
        ),
      );
}

class _HeadChip extends StatelessWidget {
  const _HeadChip({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: .2), borderRadius: BorderRadius.circular(20)),
        child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800)),
      );
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.text, required this.on, required this.onTap});
  final String text;
  final bool on;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 15),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: on ? _o : _card(context),
            borderRadius: BorderRadius.circular(14),
            boxShadow: on ? [BoxShadow(color: _o.withValues(alpha: .3), blurRadius: 10, offset: const Offset(0, 4))] : null,
          ),
          child: Text(text, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: on ? Colors.white : Theme.of(context).colorScheme.onSurface)),
        ),
      );
}

class _Message extends StatelessWidget {
  const _Message({required this.title, required this.text, this.action, this.onAction});
  final String title, text;
  final String? action;
  final VoidCallback? onAction;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 88, height: 88, alignment: Alignment.center,
            decoration: BoxDecoration(color: _o.withValues(alpha: .1), shape: BoxShape.circle),
            child: _svg(_I.car(), 44),
          ),
          const SizedBox(height: 18),
          Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -.3)),
          const SizedBox(height: 6),
          Text(text, textAlign: TextAlign.center, style: TextStyle(fontSize: 14.5, color: Theme.of(context).colorScheme.onSurfaceVariant)),
          if (action != null) ...[
            const SizedBox(height: 18),
            TextButton.icon(
              onPressed: onAction,
              icon: _svg(_I.refresh(), 18),
              label: Text(action!, style: const TextStyle(color: _o, fontWeight: FontWeight.w900, fontSize: 15.5)),
            ),
          ],
        ]),
      );
}

/// Фото машины: листаются пальцем, точки внизу.
class _Gallery extends StatefulWidget {
  const _Gallery({required this.photos, required this.height, this.radius = 0, this.onTap});
  final List<String> photos;
  final double height, radius;
  final ValueChanged<int>? onTap;
  @override
  State<_Gallery> createState() => _GalleryState();
}

class _GalleryState extends State<_Gallery> {
  int _i = 0;
  @override
  Widget build(BuildContext context) {
    final p = widget.photos;
    final placeholder = Container(
      color: _soft(context),
      alignment: Alignment.center,
      child: _svg(_I.car(_dark(context) ? '#4B5563' : '#C4C8D0'), 72),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.radius),
      child: SizedBox(
        height: widget.height,
        child: p.isEmpty
            ? placeholder
            : Stack(children: [
                PageView.builder(
                  itemCount: p.length,
                  onPageChanged: (i) => setState(() => _i = i),
                  itemBuilder: (_, i) => GestureDetector(
                    onTap: widget.onTap == null ? null : () => widget.onTap!(i),
                    child: CachedNetworkImage(
                      imageUrl: p[i],
                      fit: BoxFit.cover,
                      width: double.infinity,
                      placeholder: (_, __) => placeholder,
                      errorWidget: (_, __, ___) => placeholder,
                    ),
                  ),
                ),
                if (p.length > 1)
                  Positioned(
                    left: 0, right: 0, bottom: 10,
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      for (var i = 0; i < p.length; i++)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 2.5),
                          width: i == _i ? 18 : 6, height: 6,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: i == _i ? 1 : .6),
                            borderRadius: BorderRadius.circular(3),
                            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                          ),
                        ),
                    ]),
                  ),
              ]),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.car});
  final RentCar car;
  @override
  Widget build(BuildContext context) {
    final free = car.available;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .1), blurRadius: 8)]),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 7, height: 7, decoration: BoxDecoration(shape: BoxShape.circle, color: free ? const Color(0xFF16A34A) : const Color(0xFFEA580C))),
        const SizedBox(width: 6),
        Text(free ? tr('Свободна') : tr('В аренде'),
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: free ? const Color(0xFF15803D) : const Color(0xFFC2410C))),
      ]),
    );
  }
}

class _Spec extends StatelessWidget {
  const _Spec({required this.icon, required this.text});
  final String icon, text;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(color: _soft(context), borderRadius: BorderRadius.circular(10)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          _svg(icon, 15),
          const SizedBox(width: 5),
          Text(text, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800)),
        ]),
      );
}

class _CarCard extends StatelessWidget {
  const _CarCard({required this.car});
  final RentCar car;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: _card(context),
      borderRadius: BorderRadius.circular(26),
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      child: InkWell(
        onTap: () => context.push('/garage/${car.id}', extra: car),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Stack(children: [
            _Gallery(photos: car.photos, height: 200, onTap: (_) => context.push('/garage/${car.id}', extra: car)),
            Positioned(left: 12, top: 12, child: _StatusPill(car: car)),
            if (car.forTaxi)
              Positioned(
                right: 12, top: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(color: const Color(0xFFFFD43B), borderRadius: BorderRadius.circular(20)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    _svg(_I.taxi('#1F2937'), 14),
                    const SizedBox(width: 4),
                    Text(tr('Для такси'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF1F2937))),
                  ]),
                ),
              ),
          ]),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Expanded(
                  child: Text.rich(
                    TextSpan(children: [
                      TextSpan(text: car.title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, letterSpacing: -.4)),
                      if (car.year != null)
                        TextSpan(text: '  ${car.year}', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: cs.onSurfaceVariant)),
                    ]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ]),
              const SizedBox(height: 10),
              Wrap(spacing: 6, runSpacing: 6, children: [
                if (car.classTitle.isNotEmpty) _Spec(icon: _I.star(), text: car.classTitle),
                if (car.gearboxTitle.isNotEmpty) _Spec(icon: _I.gear(), text: car.gearboxTitle),
                if (car.fuelTitle.isNotEmpty) _Spec(icon: _I.fuel(), text: car.fuelTitle),
              ]),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text.rich(TextSpan(children: [
                      if (car.priceFrom < car.priceDay) TextSpan(text: '${tr('от')} ', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: cs.onSurfaceVariant)),
                      TextSpan(text: _money(car.priceFrom), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: _o, letterSpacing: -.5)),
                      TextSpan(text: ' / ${tr('сутки')}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: cs.onSurfaceVariant)),
                    ])),
                    if (car.deposit > 0)
                      Text(trf('Залог {0}', [_money(car.deposit)]), style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: cs.onSurfaceVariant)),
                  ]),
                ),
                Container(
                  height: 42,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: car.available ? _o : _soft(context),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(car.available ? tr('Подробнее') : tr('Узнать'),
                      style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900, color: car.available ? Colors.white : cs.onSurface)),
                ),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ───────────────────────── Карточка машины ─────────────────────────
class GarageCarScreen extends StatefulWidget {
  const GarageCarScreen({super.key, required this.id, this.car});
  final int id;
  final RentCar? car;
  @override
  State<GarageCarScreen> createState() => _GarageCarScreenState();
}

class _GarageCarScreenState extends State<GarageCarScreen> {
  RentCar? _car;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _car = widget.car;
    if (_car == null) _load();
  }

  Future<void> _load() async {
    setState(() => _error = false);
    try {
      final cars = await _loadCars();
      final c = cars.where((e) => e.id == widget.id);
      if (mounted) setState(() { _car = c.isEmpty ? null : c.first; _error = c.isEmpty; });
    } catch (_) {
      if (mounted) setState(() => _error = true);
    }
  }

  void _openPhoto(int i) {
    final car = _car;
    if (car == null || car.photos.isEmpty) return;
    Navigator.of(context, rootNavigator: true).push(PageRouteBuilder(
      opaque: false,
      pageBuilder: (_, __, ___) => _PhotoViewer(photos: car.photos, start: i),
      transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final car = _car;
    if (car == null) {
      return Scaffold(
        backgroundColor: _bg(context),
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: _error
            ? _Message(title: tr('Машина не найдена'), text: tr('Возможно, её уже убрали из AG Гаража.'), action: tr('Повторить'), onAction: _load)
            : const Center(child: CircularProgressIndicator(color: _o)),
      );
    }
    final cs = Theme.of(context).colorScheme;
    final top = MediaQuery.paddingOf(context).top;
    return Scaffold(
      backgroundColor: _bg(context),
      body: Column(children: [
        Expanded(
          child: ListView(padding: EdgeInsets.zero, children: [
            Stack(children: [
              _Gallery(photos: car.photos, height: 300 + top, onTap: _openPhoto),
              Positioned(left: 14, top: top + 8, child: _RoundBtn(icon: _I.back(), dark: true, onTap: () => context.canPop() ? context.pop() : context.go('/garage'))),
              Positioned(right: 14, top: top + 12, child: _StatusPill(car: car)),
            ]),
            Transform.translate(
              offset: const Offset(0, -22),
              child: Container(
                padding: const EdgeInsets.fromLTRB(18, 20, 18, 8),
                decoration: BoxDecoration(color: _bg(context), borderRadius: const BorderRadius.vertical(top: Radius.circular(28))),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(car.title, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: -.7, height: 1.1)),
                        const SizedBox(height: 4),
                        Text([if (car.year != null) '${car.year}', if (car.color.isNotEmpty) car.color, if (car.classTitle.isNotEmpty) car.classTitle].join(' · '),
                            style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: cs.onSurfaceVariant)),
                      ]),
                    ),
                    if (car.forTaxi)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(color: const Color(0xFFFFD43B), borderRadius: BorderRadius.circular(12)),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          _svg(_I.taxi('#1F2937'), 15),
                          const SizedBox(width: 5),
                          Text(tr('Для такси'), style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: Color(0xFF1F2937))),
                        ]),
                      ),
                  ]),
                  const SizedBox(height: 16),
                  // цены
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [_o2, _o]),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [BoxShadow(color: _o.withValues(alpha: .3), blurRadius: 18, offset: const Offset(0, 8))],
                    ),
                    child: Row(children: [
                      Expanded(child: _PriceCell(label: tr('Сутки'), value: _money(car.priceDay))),
                      if (car.priceWeekDay > 0 && car.priceWeekDay < car.priceDay) ...[
                        _vline(),
                        Expanded(child: _PriceCell(label: tr('От 7 суток'), value: _money(car.priceWeekDay))),
                      ],
                      if (car.deposit > 0) ...[
                        _vline(),
                        Expanded(child: _PriceCell(label: tr('Залог'), value: _money(car.deposit))),
                      ],
                    ]),
                  ),
                  const SizedBox(height: 14),
                  _Section(title: tr('Характеристики'), child: GridView.count(
                    crossAxisCount: 3,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 1.15,
                    children: [
                      _SpecTile(icon: _I.cal(), label: tr('Год'), value: car.year?.toString() ?? '—'),
                      _SpecTile(icon: _I.gear(), label: tr('Коробка'), value: car.gearboxTitle.isEmpty ? '—' : car.gearboxTitle),
                      _SpecTile(icon: _I.fuel(), label: tr('Топливо'), value: car.fuelTitle.isEmpty ? '—' : car.fuelTitle),
                      _SpecTile(icon: _I.star(), label: tr('Класс'), value: car.classTitle.isEmpty ? '—' : car.classTitle),
                      _SpecTile(icon: _I.seat(), label: tr('Мест'), value: '${car.seats}'),
                      _SpecTile(icon: _I.palette(), label: tr('Цвет'), value: car.color.isEmpty ? '—' : car.color),
                    ],
                  )),
                  if (car.features.isNotEmpty)
                    _Section(title: tr('Что есть в машине'), child: Wrap(spacing: 8, runSpacing: 8, children: [
                      for (final f in car.features)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
                          decoration: BoxDecoration(color: const Color(0xFFE8F7EE), borderRadius: BorderRadius.circular(12)),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            _svg(_I.check(), 15),
                            const SizedBox(width: 6),
                            Text(f, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF166534))),
                          ]),
                        ),
                    ])),
                  _Section(title: tr('Условия'), child: Column(children: [
                    _CondRow(icon: _I.cal(), text: trf('Минимальный срок — {0} {1}', [car.minDays, _daysWord(car.minDays)])),
                    if (car.deposit > 0) _CondRow(icon: _I.shield(), text: trf('Залог {0} — возвращаем после сдачи машины', [_money(car.deposit)])),
                    _CondRow(icon: _I.note(), text: tr('Нужны паспорт и водительское удостоверение')),
                  ])),
                  if (car.description.trim().isNotEmpty)
                    _Section(title: tr('Описание'), child: Text(car.description.trim(),
                        style: TextStyle(fontSize: 15, height: 1.45, color: cs.onSurface.withValues(alpha: .85)))),
                ]),
              ),
            ),
          ]),
        ),
        Container(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + MediaQuery.paddingOf(context).bottom),
          decoration: BoxDecoration(
            color: _card(context),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .06), blurRadius: 16, offset: const Offset(0, -4))],
          ),
          child: Row(children: [
            Expanded(
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_money(car.priceDay), style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900, letterSpacing: -.4)),
                Text(tr('за сутки'), style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: cs.onSurfaceVariant)),
              ]),
            ),
            SizedBox(
              height: 54,
              child: _GradBtn(
                text: car.available ? tr('Забронировать') : tr('Сообщить, когда освободится'),
                onTap: () => _BookSheet.show(context, car),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _vline() => Container(width: 1, height: 34, margin: const EdgeInsets.symmetric(horizontal: 10), color: Colors.white.withValues(alpha: .35));
}

class _PriceCell extends StatelessWidget {
  const _PriceCell({required this.label, required this.value});
  final String label, value;
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha: .85), fontSize: 12.5, fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft,
            child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w900, letterSpacing: -.3))),
      ]);
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String title;
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: _card(context), borderRadius: BorderRadius.circular(22)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, letterSpacing: -.3)),
          const SizedBox(height: 12),
          child,
        ]),
      );
}

class _SpecTile extends StatelessWidget {
  const _SpecTile({required this.icon, required this.label, required this.value});
  final String icon, label, value;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: _soft(context), borderRadius: BorderRadius.circular(16)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          _svg(icon, 20),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurfaceVariant)),
            Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900)),
          ]),
        ]),
      );
}

class _CondRow extends StatelessWidget {
  const _CondRow({required this.icon, required this.text});
  final String icon, text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(children: [
          Container(
            width: 34, height: 34, alignment: Alignment.center,
            decoration: BoxDecoration(color: _o.withValues(alpha: .1), borderRadius: BorderRadius.circular(11)),
            child: _svg(icon, 18),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, height: 1.3))),
        ]),
      );
}

class _GradBtn extends StatelessWidget {
  const _GradBtn({required this.text, required this.onTap, this.busy = false});
  final String text;
  final VoidCallback? onTap;
  final bool busy;
  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(colors: [_o2, _o]),
          boxShadow: [BoxShadow(color: _o.withValues(alpha: .35), blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 22),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          ),
          onPressed: busy ? null : onTap,
          child: busy
              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.6, color: Colors.white))
              : Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
        ),
      );
}

/// Просмотр фото на весь экран.
class _PhotoViewer extends StatefulWidget {
  const _PhotoViewer({required this.photos, required this.start});
  final List<String> photos;
  final int start;
  @override
  State<_PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<_PhotoViewer> {
  late final PageController _c = PageController(initialPage: widget.start);
  late int _i = widget.start;
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.black,
        body: Stack(children: [
          PageView.builder(
            controller: _c,
            itemCount: widget.photos.length,
            onPageChanged: (i) => setState(() => _i = i),
            itemBuilder: (_, i) => InteractiveViewer(
              maxScale: 4,
              child: Center(child: CachedNetworkImage(imageUrl: widget.photos[i], fit: BoxFit.contain)),
            ),
          ),
          Positioned(
            left: 14, top: MediaQuery.paddingOf(context).top + 8,
            child: _RoundBtn(icon: _I.back(), dark: true, onTap: () => Navigator.of(context).pop()),
          ),
          Positioned(
            right: 18, top: MediaQuery.paddingOf(context).top + 18,
            child: Text('${_i + 1} / ${widget.photos.length}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
          ),
        ]),
      );
}

// ───────────────────────── Бронирование ─────────────────────────
class _BookSheet extends StatefulWidget {
  const _BookSheet({required this.car});
  final RentCar car;

  static Future<void> show(BuildContext context, RentCar car) async {
    if (!context.read<AuthProvider>().isLoggedIn) {
      context.push('/login');
      return;
    }
    final chatId = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BookSheet(car: car),
    );
    if (chatId != null && context.mounted) {
      await showModalBottomSheet<void>(
        context: context,
        useRootNavigator: true,
        backgroundColor: Colors.transparent,
        builder: (c) => _DoneSheet(
          available: car.available,
          onChat: () {
            Navigator.pop(c);
            context.push('/chats/$chatId');
          },
        ),
      );
    }
  }

  @override
  State<_BookSheet> createState() => _BookSheetState();
}

class _BookSheetState extends State<_BookSheet> {
  late DateTime _start = DateTime.now().add(const Duration(days: 1));
  late int _days = widget.car.minDays;
  bool _taxi = true;
  bool _sending = false;
  String? _error;
  final _phone = TextEditingController();
  final _comment = TextEditingController();

  @override
  void initState() {
    super.initState();
    _phone.text = context.read<AuthProvider>().user?.phone ?? '';
    _taxi = widget.car.forTaxi;
  }

  @override
  void dispose() {
    _phone.dispose();
    _comment.dispose();
    super.dispose();
  }

  String _date(DateTime d) => '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _start,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 120)),
      builder: (c, child) => Theme(
        data: Theme.of(c).copyWith(colorScheme: Theme.of(c).colorScheme.copyWith(primary: _o)),
        child: child!,
      ),
    );
    if (d != null) setState(() => _start = d);
  }

  Future<void> _send() async {
    final car = widget.car;
    if (_phone.text.replaceAll(RegExp(r'\D'), '').length < 10) return setState(() => _error = tr('Проверьте номер телефона'));
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      final price = car.dayPrice(_days);
      final text = car.available
          ? [
              '🔑 ${tr('Заявка: аренда авто')} — AG Гараж',
              '${tr('Машина')}: ${car.title}${car.year != null ? ', ${car.year}' : ''} (№${car.id})',
              '${tr('С')} ${_date(_start)} ${tr('на')} $_days ${_daysWord(_days)}',
              '${tr('Стоимость')}: ${_money(price)} × $_days = ${_money(price * _days)}${car.deposit > 0 ? ' + ${tr('залог')} ${_money(car.deposit)}' : ''}',
              if (_taxi) tr('Для работы в такси'),
              '${tr('Телефон')}: ${_phone.text.trim()}',
              if (_comment.text.trim().isNotEmpty) '${tr('Комментарий')}: ${_comment.text.trim()}',
            ].join('\n')
          : [
              '🔔 ${tr('Сообщите, когда освободится')} — AG Гараж',
              '${tr('Машина')}: ${car.title}${car.year != null ? ', ${car.year}' : ''} (№${car.id})',
              '${tr('Телефон')}: ${_phone.text.trim()}',
              if (_comment.text.trim().isNotEmpty) '${tr('Комментарий')}: ${_comment.text.trim()}',
            ].join('\n');
      final repo = context.read<ChatRepository>();
      final conv = await repo.getOrCreateDepartmentConversation(_dept);
      await repo.sendMessage(conv.id, body: text);
      if (mounted) Navigator.pop(context, conv.id);
    } catch (_) {
      if (mounted) setState(() => _error = tr('Не удалось отправить заявку. Проверьте интернет и попробуйте ещё раз'));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final car = widget.car;
    final cs = Theme.of(context).colorScheme;
    final price = car.dayPrice(_days);
    final total = price * _days;
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      decoration: BoxDecoration(color: _card(context), borderRadius: const BorderRadius.vertical(top: Radius.circular(28))),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Center(child: Container(width: 40, height: 5, decoration: BoxDecoration(color: cs.outlineVariant, borderRadius: BorderRadius.circular(3)))),
            const SizedBox(height: 14),
            Row(children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: 64, height: 48,
                  child: car.photos.isEmpty
                      ? Container(color: _soft(context), alignment: Alignment.center, child: _svg(_I.car(), 26))
                      : CachedNetworkImage(imageUrl: car.photos.first, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(car.available ? tr('Бронирование') : tr('Сообщить, когда освободится'),
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: cs.onSurfaceVariant)),
                  Text(car.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, letterSpacing: -.4)),
                ]),
              ),
            ]),
            const SizedBox(height: 18),
            if (car.available) ...[
              Row(children: [
                Expanded(
                  child: _Box(
                    onTap: _pickDate,
                    child: Row(children: [
                      _svg(_I.cal(), 20),
                      const SizedBox(width: 10),
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(tr('Начало'), style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: cs.onSurfaceVariant)),
                        Text(_date(_start), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                      ]),
                    ]),
                  ),
                ),
                const SizedBox(width: 10),
                _Box(
                  child: Row(children: [
                    _StepBtn(icon: _I.minus(), onTap: _days > car.minDays ? () => setState(() => _days--) : null),
                    SizedBox(
                      width: 62,
                      child: Column(children: [
                        Text('$_days', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                        Text(_daysWord(_days), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: cs.onSurfaceVariant)),
                      ]),
                    ),
                    _StepBtn(icon: _I.plus(), onTap: _days < 90 ? () => setState(() => _days++) : null),
                  ]),
                ),
              ]),
              const SizedBox(height: 10),
              _Box(
                onTap: () => setState(() => _taxi = !_taxi),
                child: Row(children: [
                  _svg(_I.taxi('#FF6A00'), 20),
                  const SizedBox(width: 10),
                  Expanded(child: Text(tr('Буду работать в такси'), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800))),
                  Switch.adaptive(value: _taxi, activeTrackColor: _o, onChanged: (v) => setState(() => _taxi = v)),
                ]),
              ),
              const SizedBox(height: 10),
            ],
            _Input(controller: _phone, icon: _I.phone(), hint: '+7 (___) ___-__-__', keyboard: TextInputType.phone),
            const SizedBox(height: 10),
            _Input(controller: _comment, icon: _I.note(), hint: tr('Комментарий (необязательно)')),
            if (car.available) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: _o.withValues(alpha: .08), borderRadius: BorderRadius.circular(18)),
                child: Column(children: [
                  _SumRow(left: '${_money(price)} × $_days ${_daysWord(_days)}', right: _money(total)),
                  if (car.deposit > 0) _SumRow(left: tr('Залог (вернём)'), right: _money(car.deposit)),
                  const Divider(height: 18),
                  _SumRow(left: tr('Итого к оплате'), right: _money(total + car.deposit), bold: true),
                ]),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!, style: const TextStyle(color: Color(0xFFB91C1C), fontWeight: FontWeight.w700)),
            ],
            const SizedBox(height: 16),
            SizedBox(
              height: 56,
              child: _GradBtn(text: car.available ? tr('Отправить заявку') : tr('Сообщить мне'), busy: _sending, onTap: _send),
            ),
            const SizedBox(height: 8),
            Text(tr('Оплата при получении машины. Менеджер свяжется с вами и подтвердит бронь.'),
                textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
          ]),
        ),
      ),
    );
  }
}

class _Box extends StatelessWidget {
  const _Box({required this.child, this.onTap});
  final Widget child;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Material(
        color: _soft(context),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), child: child),
        ),
      );
}

class _StepBtn extends StatelessWidget {
  const _StepBtn({required this.icon, this.onTap});
  final String icon;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Opacity(
        opacity: onTap == null ? .35 : 1,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: 36, height: 36, alignment: Alignment.center,
            decoration: BoxDecoration(color: _card(context), borderRadius: BorderRadius.circular(11)),
            child: _svg(icon, 18),
          ),
        ),
      );
}

class _Input extends StatelessWidget {
  const _Input({required this.controller, required this.icon, required this.hint, this.keyboard});
  final TextEditingController controller;
  final String icon, hint;
  final TextInputType? keyboard;
  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        keyboardType: keyboard,
        inputFormatters: keyboard == TextInputType.phone ? [FilteringTextInputFormatter.allow(RegExp(r'[\d+()\- ]'))] : null,
        style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700),
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: _soft(context),
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
          prefixIcon: Padding(padding: const EdgeInsets.only(left: 14, right: 10), child: _svg(icon, 20)),
          prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: _o, width: 1.6)),
        ),
      );
}

class _SumRow extends StatelessWidget {
  const _SumRow({required this.left, required this.right, this.bold = false});
  final String left, right;
  final bool bold;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(children: [
          Expanded(child: Text(left, style: TextStyle(fontSize: bold ? 16 : 14, fontWeight: bold ? FontWeight.w900 : FontWeight.w700))),
          Text(right, style: TextStyle(fontSize: bold ? 18 : 14.5, fontWeight: FontWeight.w900, color: bold ? _o : null)),
        ]),
      );
}

class _DoneSheet extends StatelessWidget {
  const _DoneSheet({required this.available, required this.onChat});
  final bool available;
  final VoidCallback onChat;
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.fromLTRB(20, 26, 20, 16),
        decoration: BoxDecoration(color: _card(context), borderRadius: BorderRadius.circular(28)),
        child: SafeArea(
          top: false,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 84, height: 84, alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(colors: [_o2, _o]),
                boxShadow: [BoxShadow(color: _o.withValues(alpha: .35), blurRadius: 24, offset: const Offset(0, 10))],
              ),
              child: _svg(_I.check('#FFFFFF'), 44),
            ),
            const SizedBox(height: 18),
            Text(available ? tr('Заявка отправлена!') : tr('Готово!'),
                style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w900, letterSpacing: -.4)),
            const SizedBox(height: 6),
            Text(
              available
                  ? tr('Менеджер свяжется с вами и подтвердит бронь. Переписка — в чате с автосервисом.')
                  : tr('Напишем вам в чат, как только машина освободится.'),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14.5, height: 1.4, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            SizedBox(width: double.infinity, height: 54, child: _GradBtn(text: tr('Открыть чат'), onTap: onChat)),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(tr('Закрыть'), style: const TextStyle(color: _o, fontWeight: FontWeight.w800)),
            ),
          ]),
        ),
      );
}
