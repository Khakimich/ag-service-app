import 'package:mobile/core/nav.dart'; // AG_FIX1
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme.dart';
import '../../../models/user_car.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/my_cars_provider.dart';
import 'car_form_screen.dart';
import '../../../core/i18n.dart'; // AG_I18N1

class MyCarsScreen extends StatefulWidget {
  const MyCarsScreen({super.key});

  @override
  State<MyCarsScreen> createState() => _MyCarsScreenState();
}

class _MyCarsScreenState extends State<MyCarsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (context.read<AuthProvider>().isLoggedIn) {
        context.read<MyCarsProvider>().load();
      }
    });
  }

  Future<void> _openCarForm({UserCar? car}) async {
    final auth = context.read<AuthProvider>();

    if (!auth.isLoggedIn) {
      context.push('/login');
      return;
    }

    await Navigator.of(
      context,
      rootNavigator: true,
    ).push(MaterialPageRoute(builder: (_) => CarFormScreen(car: car)));

    if (!mounted) return;
    await context.read<MyCarsProvider>().load();
  }

  Future<void> _confirmDelete(
    BuildContext context,
    MyCarsProvider provider,
    UserCar car,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (dialogCtx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: Text(tr('Удалить автомобиль?')),
            content: Text(trf('{0} будет удалён из вашего гаража.', [car.title])),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx, false),
                child: Text(tr('Отмена')),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: Text(tr('Удалить')),
              ),
            ],
          ),
    );

    if (confirmed != true || !context.mounted) return;

    final ok = await provider.deleteCar(car.id);

    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('Не удалось удалить автомобиль'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (!auth.isLoggedIn) {
      return const _GuestGarageView();
    }
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: Consumer<MyCarsProvider>(
          builder: (context, provider, _) {
            return Column(
              children: [
                _GarageHeader(
                  count: provider.cars.length,
                  onBack: () => context.agBack(), // AG_FIX1
                  onAdd: () => _openCarForm(),
                ),
                Expanded(child: _buildContent(context, provider)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, MyCarsProvider provider) {
    if (provider.loading && provider.cars.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: BrandColors.orange),
      );
    }

    if (provider.error != null && provider.cars.isEmpty) {
      return _ErrorView(message: provider.error!, onRetry: provider.load);
    }

    if (provider.cars.isEmpty) {
      return RefreshIndicator(
        color: BrandColors.orange,
        onRefresh: provider.load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 70, 20, 120),
          children: [_EmptyGarage(onAdd: () => _openCarForm())],
        ),
      );
    }

    return RefreshIndicator(
      color: BrandColors.orange,
      onRefresh: provider.load,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth =
              constraints.maxWidth > 760 ? 760.0 : constraints.maxWidth;

          return ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              constraints.maxWidth > 760
                  ? (constraints.maxWidth - maxWidth) / 2 + 20
                  : 20,
              12,
              constraints.maxWidth > 760
                  ? (constraints.maxWidth - maxWidth) / 2 + 20
                  : 20,
              120,
            ),
            itemCount: provider.cars.length + 1,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (itemCtx, index) {
              if (index == provider.cars.length) {
                return _AddCarCard(onTap: () => _openCarForm());
              }

              final car = provider.cars[index];

              return _CarCard(
                car: car,
                onEdit: () => _openCarForm(car: car),
                onDelete: () => _confirmDelete(itemCtx, provider, car),
              );
            },
          );
        },
      ),
    );
  }
}

class _GarageHeader extends StatelessWidget {
  const _GarageHeader({
    required this.count,
    required this.onBack,
    required this.onAdd,
  });

  final int count;
  final VoidCallback onBack;
  final VoidCallback onAdd;

  String get _countText {
    final mod10 = count % 10;
    final mod100 = count % 100;

    if (mod10 == 1 && mod100 != 11) {
      return trf('{0} автомобиль', [count]);
    }

    if (mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14)) {
      return trf('{0} автомобиля', [count]);
    }

    return trf('{0} автомобилей', [count]);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
          bottom: BorderSide(
            color: colors.outlineVariant.withValues(alpha: .45),
          ),
        ),
      ),
      child: Row(
        children: [
          Material(
            color: colors.surfaceContainerHighest.withValues(alpha: .55),
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: onBack,
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
                  tr('Мой гараж'),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _countText,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Material(
            color: BrandColors.orange,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: onAdd,
              borderRadius: BorderRadius.circular(16),
              child: const SizedBox(
                width: 48,
                height: 48,
                child: Icon(Icons.add_rounded, color: Colors.white, size: 27),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CarCard extends StatelessWidget {
  const _CarCard({
    required this.car,
    required this.onEdit,
    required this.onDelete,
  });

  final UserCar car;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  String? _logoSlug(String make) {
    var value = make.trim().toLowerCase();

    const aliases = <String, String>{
      'škoda': 'skoda',
      'skoda': 'skoda',
      'шкода': 'skoda',
      'hyundai': 'hyundai',
      'хендай': 'hyundai',
      'хундай': 'hyundai',
      'хёндэ': 'hyundai',
      'kia': 'kia',
      'киа': 'kia',
      'toyota': 'toyota',
      'тойота': 'toyota',
      'lexus': 'lexus',
      'лексус': 'lexus',
      'bmw': 'bmw',
      'бмв': 'bmw',
      'audi': 'audi',
      'ауди': 'audi',
      'volkswagen': 'volkswagen',
      'фольксваген': 'volkswagen',
      'mercedes': 'mercedes-benz',
      'mercedes-benz': 'mercedes-benz',
      'мерседес': 'mercedes-benz',
      'nissan': 'nissan',
      'ниссан': 'nissan',
      'honda': 'honda',
      'хонда': 'honda',
      'mazda': 'mazda',
      'мазда': 'mazda',
      'ford': 'ford',
      'форд': 'ford',
      'chevrolet': 'chevrolet',
      'шевроле': 'chevrolet',
      'renault': 'renault',
      'рено': 'renault',
      'mitsubishi': 'mitsubishi',
      'митсубиси': 'mitsubishi',
      'subaru': 'subaru',
      'субару': 'subaru',
      'porsche': 'porsche',
      'порше': 'porsche',
      'volvo': 'volvo',
      'вольво': 'volvo',
      'geely': 'geely',
      'джили': 'geely',
      'chery': 'chery',
      'чери': 'chery',
      'haval': 'haval',
      'хавал': 'haval',
      'lada': 'lada',
      'ваз': 'lada',
    };

    if (aliases.containsKey(value)) {
      return aliases[value];
    }

    value = value
        .replaceAll('&', 'and')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');

    if (value.isEmpty) return null;

    return value;
  }

  Widget _brandLogo(BuildContext context) {
    final slug = _logoSlug(car.make);

    if (slug == null) {
      return const Icon(
        Icons.directions_car_rounded,
        color: BrandColors.orange,
        size: 38,
      );
    }

    return Image.asset(
      'assets/car_logos/$slug.png',
      width: 68,
      height: 68,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      errorBuilder:
          (_, __, ___) => const Icon(
            Icons.directions_car_rounded,
            color: BrandColors.orange,
            size: 38,
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final hasVin = car.vinCode != null && car.vinCode!.trim().isNotEmpty;

    final hasPlate =
        car.licensePlate != null && car.licensePlate!.trim().isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color:
              isDark
                  ? Colors.white.withValues(alpha: .09)
                  : colors.outlineVariant.withValues(alpha: .65),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? .16 : .055),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 88,
              height: 88,
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFFF3F4F6) : BrandColors.orange.withValues(alpha: .09), // AG_LOGODARK1
                borderRadius: BorderRadius.circular(22),
              ),
              child: Center(child: _brandLogo(context)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      car.make.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: BrandColors.orange,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      car.model,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 20,
                        height: 1.08,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -.35,
                      ),
                    ),
                    const SizedBox(height: 11),
                    Wrap(
                      spacing: 7,
                      runSpacing: 7,
                      children: [
                        if (car.year != null)
                          _InfoChip(
                            icon: Icons.calendar_month_rounded,
                            text: car.year.toString(),
                          ),
                        if (hasPlate)
                          _InfoChip(
                            icon: Icons.pin_outlined,
                            text: car.licensePlate!,
                          ),
                      ],
                    ),
                    if (hasVin) ...[
                      const SizedBox(height: 11),
                      Row(
                        children: [
                          Icon(
                            Icons.fingerprint_rounded,
                            size: 15,
                            color: colors.onSurfaceVariant,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'VIN  ${car.vinCode}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                letterSpacing: .2,
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
            ),
            const SizedBox(width: 4),
            PopupMenuButton<String>(
              tooltip: tr('Действия'),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              onSelected: (value) {
                if (value == 'edit') onEdit();
                if (value == 'delete') onDelete();
              },
              itemBuilder:
                  (_) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 19),
                          SizedBox(width: 10),
                          Text(tr('Редактировать')),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_outline_rounded,
                            size: 19,
                            color: Colors.red,
                          ),
                          SizedBox(width: 10),
                          Text(tr('Удалить'), style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
              icon: Icon(
                Icons.more_horiz_rounded,
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: .65),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: colors.onSurfaceVariant),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: colors.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _AddCarCard extends StatelessWidget {
  const _AddCarCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: BrandColors.orange.withValues(alpha: .08),
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: BrandColors.orange.withValues(alpha: .28),
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 46,
                height: 46,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: BrandColors.orange,
                    borderRadius: BorderRadius.all(Radius.circular(15)),
                  ),
                  child: Icon(Icons.add_rounded, color: Colors.white, size: 27),
                ),
              ),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr('Добавить автомобиль'),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      tr('Добавьте ещё одну машину в гараж'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: BrandColors.orange,
                size: 17,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyGarage extends StatelessWidget {
  const _EmptyGarage({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      children: [
        Container(
          width: 104,
          height: 104,
          decoration: BoxDecoration(
            color: BrandColors.orange.withValues(alpha: .1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.directions_car_filled_rounded,
            color: BrandColors.orange,
            size: 48,
          ),
        ),
        const SizedBox(height: 22),
        Text(
          tr('Ваш гараж пока пуст'),
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(
          tr('Добавьте автомобиль, чтобы быстрее записываться в сервис.'),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            height: 1.45,
            color: colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 26),
        SizedBox(
          width: 260,
          height: 54,
          child: ElevatedButton.icon(
            onPressed: onAdd,
            style: ElevatedButton.styleFrom(
              backgroundColor: BrandColors.orange,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(17),
              ),
            ),
            icon: const Icon(Icons.add_rounded),
            label: Text(
              tr('Добавить автомобиль'),
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ],
    );
  }
}

class _GuestGarageView extends StatelessWidget {
  const _GuestGarageView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 28, 22, 120),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text(
                        tr('Мой гараж'),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),

                  const Spacer(),

                  Container(
                    width: 104,
                    height: 104,
                    decoration: BoxDecoration(
                      color: BrandColors.orange.withValues(
                        alpha: isDark ? .14 : .10,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.directions_car_rounded,
                      size: 52,
                      color: BrandColors.orange,
                    ),
                  ),

                  const SizedBox(height: 26),

                  Text(
                    tr('Ваш гараж ждёт вас'),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    tr('Войдите в аккаунт, чтобы добавлять автомобили, записываться в сервис и хранить историю обслуживания.'),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      height: 1.45,
                      color: colors.onSurfaceVariant,
                    ),
                  ),

                  const SizedBox(height: 30),

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton(
                      onPressed: () => context.push('/login'),
                      style: FilledButton.styleFrom(
                        backgroundColor: BrandColors.orange,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: Text(
                        tr('Войти в аккаунт'),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    tr('После входа здесь появятся ваши автомобили'),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),

                  const Spacer(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: BrandColors.orange,
            ),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onRetry, child: Text(tr('Повторить'))),
          ],
        ),
      ),
    );
  }
}
