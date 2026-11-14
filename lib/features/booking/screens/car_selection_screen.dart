import 'package:mobile/core/nav.dart'; // AG_FIX1
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme.dart';
import '../../../models/user_car.dart';
import '../../my_cars/providers/my_cars_provider.dart';
import '../../my_cars/screens/car_form_screen.dart';
import '../providers/booking_flow_provider.dart';
import '../../../core/i18n.dart'; // AG_I18N1

class CarSelectionScreen extends StatefulWidget {
  const CarSelectionScreen({super.key});

  @override
  State<CarSelectionScreen> createState() => _CarSelectionScreenState();
}

class _CarSelectionScreenState extends State<CarSelectionScreen> {
  String? _selectedCarId;

  @override
  void initState() {
    super.initState();

    _selectedCarId = context.read<BookingFlowProvider>().carId;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<MyCarsProvider>().load();
    });
  }

  Future<void> _addCar() async {
    await Navigator.of(
      context,
      rootNavigator: true,
    ).push(MaterialPageRoute(builder: (_) => const CarFormScreen()));

    if (!mounted) return;
    await context.read<MyCarsProvider>().load();
  }

  void _continue() {
    if (_selectedCarId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('Выберите автомобиль для записи'))),
      );
      return;
    }

    context.read<BookingFlowProvider>().selectCar(_selectedCarId);
    context.push('/booking/confirm');
  }

  UserCar? _selectedCar(List<UserCar> cars) {
    for (final car in cars) {
      if (car.id == _selectedCarId) return car;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MyCarsProvider>();
    final colors = Theme.of(context).colorScheme;
    final selectedCar = _selectedCar(provider.cars);

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _TopBar(onBack: () => context.agBack()), // AG_FIX1
            Expanded(child: _buildBody(provider)),
            if (provider.cars.isNotEmpty)
              _BottomBar(
                car: selectedCar,
                onContinue: selectedCar == null ? null : _continue,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(MyCarsProvider provider) {
    if (provider.loading && provider.cars.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: BrandColors.orange),
      );
    }

    if (provider.error != null && provider.cars.isEmpty) {
      return _LoadError(message: provider.error!, onRetry: provider.load);
    }

    if (provider.cars.isEmpty) {
      return _EmptyGarage(onAdd: _addCar);
    }

    return RefreshIndicator(
      onRefresh: provider.load,
      color: BrandColors.orange,
      child: ListView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 30),
        children: [
          const _IntroCard(),

          const SizedBox(height: 18),

          ...provider.cars.map(
            (car) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _CarChoiceCard(
                car: car,
                selected: _selectedCarId == car.id,
                onTap: () {
                  setState(() {
                    _selectedCarId = car.id;
                  });
                },
              ),
            ),
          ),

          const SizedBox(height: 2),

          _AddCarButton(onTap: _addCar),

          const SizedBox(height: 26),

          Text(
            tr('Марки автомобилей'),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: -.3,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            tr('Логотип определяется автоматически по автомобилю'),
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),

          const SizedBox(height: 14),

          const _PopularBrands(),

          const SizedBox(height: 18),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          Material(
            color: colors.surfaceContainerHighest.withValues(alpha: .65),
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap: onBack,
              borderRadius: BorderRadius.circular(14),
              child: const SizedBox(
                width: 42,
                height: 42,
                child: Icon(Icons.arrow_back_ios_new_rounded, size: 17),
              ),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Text(
              tr('Выберите автомобиль'),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: -.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IntroCard extends StatelessWidget {
  const _IntroCard();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            BrandColors.orange.withValues(alpha: .10),
            BrandColors.orange.withValues(alpha: .025),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: BrandColors.orange.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(17),
            ),
            child: const Icon(
              Icons.directions_car_rounded,
              color: BrandColors.orange,
              size: 29,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr('Какой автомобиль приедет в сервис?'),
                  style: TextStyle(
                    fontSize: 17,
                    height: 1.15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -.25,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  tr('Выберите автомобиль из вашего гаража или добавьте новый.'),
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.35,
                    color: colors.onSurfaceVariant,
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

class _CarChoiceCard extends StatelessWidget {
  const _CarChoiceCard({
    required this.car,
    required this.selected,
    required this.onTap,
  });

  final UserCar car;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final plate = car.licensePlate?.trim();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 190),
          curve: Curves.easeOut,
          padding: const EdgeInsets.fromLTRB(14, 15, 13, 15),
          decoration: BoxDecoration(
            color:
                selected
                    ? BrandColors.orange.withValues(alpha: .035)
                    : colors.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color:
                  selected
                      ? BrandColors.orange
                      : colors.outlineVariant.withValues(alpha: .50),
              width: selected ? 1.8 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color:
                    selected
                        ? BrandColors.orange.withValues(alpha: .09)
                        : Colors.black.withValues(alpha: .035),
                blurRadius: selected ? 18 : 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 68,
                height: 68,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest.withValues(alpha: .48),
                  borderRadius: BorderRadius.circular(19),
                ),
                child: _CarBrandLogo(title: car.title, size: 52),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      car.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -.25,
                      ),
                    ),

                    if (car.year != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        trf('{0} год', [car.year]),
                        style: TextStyle(
                          fontSize: 13,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],

                    if (plate != null && plate.isNotEmpty) ...[
                      const SizedBox(height: 9),
                      Row(
                        children: [
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: colors.surfaceContainerHighest
                                    .withValues(alpha: .72),
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: Text(
                                plate.toUpperCase(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: .25,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: colors.surfaceContainerHighest.withValues(
                                alpha: .42,
                              ),
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: Text(
                              '🇷🇺 RUS',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(width: 10),

              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 31,
                    height: 31,
                    decoration: BoxDecoration(
                      color: selected ? BrandColors.orange : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color:
                            selected
                                ? BrandColors.orange
                                : colors.outlineVariant,
                        width: 2,
                      ),
                    ),
                    child:
                        selected
                            ? const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 20,
                            )
                            : null,
                  ),

                  const SizedBox(height: 12),

                  Icon(
                    Icons.directions_car_filled_rounded,
                    size: 36,
                    color:
                        selected
                            ? BrandColors.orange.withValues(alpha: .75)
                            : colors.onSurfaceVariant.withValues(alpha: .22),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddCarButton extends StatelessWidget {
  const _AddCarButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(19),
        child: Container(
          height: 62,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(19),
            border: Border.all(color: BrandColors.blue.withValues(alpha: .35)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: BrandColors.blue.withValues(alpha: .07),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: BrandColors.blue,
                  size: 25,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  tr('Добавить другой автомобиль'),
                  style: TextStyle(
                    color: BrandColors.blue,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 15,
                color: colors.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PopularBrands extends StatelessWidget {
  const _PopularBrands();

  static const brands = <_BrandItem>[
    _BrandItem('Hyundai', 'hyundai'),
    _BrandItem('Kia', 'kia'),
    _BrandItem('Toyota', 'toyota'),
    _BrandItem('Volkswagen', 'volkswagen'),
    _BrandItem('BMW', 'bmw'),
    _BrandItem('Mercedes', 'mercedes-benz'),
    _BrandItem('Audi', 'audi'),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 88,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: brands.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, index) {
          final brand = brands[index];

          return SizedBox(
            width: 66,
            child: Column(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest
                        .withValues(alpha: .42),
                    borderRadius: BorderRadius.circular(17),
                  ),
                  child: Image.asset(
                    'assets/car_logos/${brand.slug}.png',
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                    errorBuilder:
                        (_, __, ___) =>
                            const Icon(Icons.directions_car_rounded, size: 27),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  brand.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _BrandItem {
  const _BrandItem(this.name, this.slug);

  final String name;
  final String slug;
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.car, required this.onContinue});

  final UserCar? car;
  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final plate = car?.licensePlate?.trim();

    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        10,
        16,
        MediaQuery.paddingOf(context).bottom + 10,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
          top: BorderSide(color: colors.outlineVariant.withValues(alpha: .35)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          if (car != null) ...[
            Container(
              width: 49,
              height: 49,
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFFF3F4F6) : BrandColors.orange.withValues(alpha: .08), // AG_LOGODARK1
                borderRadius: BorderRadius.circular(14),
              ),
              child: _CarBrandLogo(title: car!.title, size: 38),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr('Выбран:'),
                    style: TextStyle(
                      fontSize: 10,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    car!.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (plate != null && plate.isNotEmpty)
                    Text(
                      plate.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10.5,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 10),
          ] else
            const Spacer(),

          SizedBox(
            height: 51,
            width: car == null ? 180 : 155,
            child: ElevatedButton(
              onPressed: onContinue,
              style: ElevatedButton.styleFrom(
                backgroundColor: BrandColors.orange,
                foregroundColor: Colors.white,
                disabledBackgroundColor: colors.surfaceContainerHighest,
                disabledForegroundColor: colors.onSurfaceVariant,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    tr('Продолжить'),
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
                  ),
                  SizedBox(width: 5),
                  Icon(Icons.arrow_forward_rounded, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CarBrandLogo extends StatelessWidget {
  const _CarBrandLogo({required this.title, this.size = 52});

  final String title;
  final double size;

  static const Set<String> _knownBrands = {
    'acura',
    'audi',
    'bentley',
    'bmw',
    'byd',
    'cadillac',
    'changan',
    'chery',
    'chevrolet',
    'chrysler',
    'citroen',
    'daewoo',
    'dodge',
    'exeed',
    'faw',
    'ferrari',
    'fiat',
    'ford',
    'gac-group',
    'gaz',
    'geely',
    'genesis',
    'great-wall',
    'haval',
    'honda',
    'hongqi',
    'hyundai',
    'infiniti',
    'isuzu',
    'jac',
    'jaguar',
    'jeep',
    'jetour',
    'kia',
    'lada',
    'land-rover',
    'lexus',
    'lifan',
    'mazda',
    'mercedes-benz',
    'mini',
    'mitsubishi',
    'nissan',
    'omoda',
    'opel',
    'peugeot',
    'porsche',
    'renault',
    'skoda',
    'subaru',
    'suzuki',
    'tesla',
    'toyota',
    'uaz',
    'volkswagen',
    'volvo',
    'zeekr',
  };

  String? _logoSlug() {
    var value = title.trim().toLowerCase();

    final replacements = <String, String>{
      'š': 's',
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

    for (var length = words.length; length >= 1; length--) {
      final candidate = words.take(length).join('-');
      final normalized = aliases[candidate] ?? candidate;

      if (_knownBrands.contains(normalized)) {
        return normalized;
      }
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final slug = _logoSlug();

    if (slug == null) {
      return Icon(
        Icons.directions_car_rounded,
        size: size * .65,
        color: BrandColors.orange,
      );
    }

    return Image.asset(
      'assets/car_logos/$slug.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      errorBuilder: (_, __, ___) {
        return Icon(
          Icons.directions_car_rounded,
          size: size * .65,
          color: BrandColors.orange,
        );
      },
    );
  }
}

class _EmptyGarage extends StatelessWidget {
  const _EmptyGarage({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 86,
              height: 86,
              decoration: BoxDecoration(
                color: BrandColors.orange.withValues(alpha: .09),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.garage_rounded,
                size: 43,
                color: BrandColors.orange,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              tr('Ваш гараж пока пуст'),
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 7),
            Text(
              tr('Добавьте автомобиль, чтобы продолжить запись.'),
              textAlign: TextAlign.center,
              style: TextStyle(
                height: 1.4,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded),
              label: Text(tr('Добавить автомобиль')),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.onRetry});

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
              size: 48,
              color: BrandColors.orange,
            ),
            const SizedBox(height: 12),
            Text(
              tr('Не удалось загрузить автомобили'),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 7),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onRetry, child: Text(tr('Повторить'))),
          ],
        ),
      ),
    );
  }
}
