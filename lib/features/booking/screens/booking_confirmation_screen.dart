import 'package:mobile/core/nav.dart'; // AG_FIX1
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme.dart';
import '../../../models/user_car.dart';
import '../../auth/providers/auth_provider.dart';
import '../../my_cars/providers/my_cars_provider.dart';
import '../data/booking_repository.dart';
import '../providers/booking_flow_provider.dart';
import '../../../core/i18n.dart'; // AG_I18N1

class BookingConfirmationScreen extends StatefulWidget {
  const BookingConfirmationScreen({super.key});

  @override
  State<BookingConfirmationScreen> createState() =>
      _BookingConfirmationScreenState();
}

class _BookingConfirmationScreenState extends State<BookingConfirmationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  bool _submitting = false;
  String? _submitError;
  String? _selectedCarId;

  bool _bookingAvailable = true;
  bool _checkingBookingAvailability = true;
  String _bookingUnavailableMessage = '';

  Future<void> _refreshBookingAvailability() async {
    try {
      final settings =
          await context.read<BookingRepository>().bookingSettings();

      if (!mounted) return;

      setState(() {
        _bookingAvailable = settings.bookingAvailable;
        _bookingUnavailableMessage = settings.message;
        _checkingBookingAvailability = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _checkingBookingAvailability = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();

    _selectedCarId = context.read<BookingFlowProvider>().carId;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      _refreshBookingAvailability();

      final auth = context.read<AuthProvider>();
      final carsProvider = context.read<MyCarsProvider>();

      if (auth.isLoggedIn) {
        _nameCtrl.text = auth.user!.name;
        _phoneCtrl.text = auth.user!.phone ?? '';

        if (carsProvider.cars.isEmpty) {
          carsProvider.load();
        }
      }
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  UserCar? _findSelectedCar(List<UserCar> cars) {
    for (final car in cars) {
      if (car.id == _selectedCarId) {
        return car;
      }
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final flow = context.read<BookingFlowProvider>();
    final repo = context.read<BookingRepository>();
    final auth = context.read<AuthProvider>();

    try {
      final settings = await repo.bookingSettings();

      if (!settings.bookingAvailable) {
        if (!mounted) return;

        setState(() {
          _bookingAvailable = false;
          _bookingUnavailableMessage = settings.message;
          _submitError =
              settings.message.isNotEmpty
                  ? settings.message
                  : tr('Онлайн-запись временно недоступна.');
        });

        return;
      }
    } catch (_) {
      // Сервер дополнительно проверит доступность при создании записи.
    }

    final customerName =
        auth.isLoggedIn ? auth.user!.name : _nameCtrl.text.trim();

    setState(() {
      _submitting = true;
      _submitError = null;
    });

    try {
      flow.setCustomer(name: customerName, phone: _phoneCtrl.text.trim());

      flow.selectCar(_selectedCarId);

      await repo.createBooking(
        serviceId: flow.service!.id,
        specialistId: flow.specialist!.id,
        scheduledAt: flow.slot!.start,
        customerName: customerName,
        customerPhone: _phoneCtrl.text.trim(),
        carId: _selectedCarId,
      );

      final prefs = await SharedPreferences.getInstance();

      await prefs.setString('customer_phone', _phoneCtrl.text.trim());

      if (!mounted) return;

      context.go('/booking/success');
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _submitError = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final flow = context.watch<BookingFlowProvider>();
    final service = flow.service!;
    final specialist = flow.specialist!;
    final slot = flow.slot!;

    final auth = context.watch<AuthProvider>();
    final isLoggedIn = auth.isLoggedIn;

    final cars =
        isLoggedIn ? context.watch<MyCarsProvider>().cars : <UserCar>[];

    final selectedCar = _findSelectedCar(cars);

    final dateLabel = DateFormat('d MMMM, EEEE', AgI18n.dateLocale).format(slot.start);

    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        bottom: false,
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _TopBar(onBack: () => context.agBack()), // AG_FIX1

              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                  children: [
                    if (!_checkingBookingAvailability &&
                        !_bookingAvailable) ...[
                      _UnavailableCard(message: _bookingUnavailableMessage),
                      const SizedBox(height: 14),
                    ],

                    _BookingHero(
                      serviceTitle: service.title,
                      price: service.priceLabel,
                      duration: service.durationLabel,
                    ),

                    const SizedBox(height: 12),

                    _BookingDetailsCard(
                      specialist: specialist.fullName,
                      specialization: specialist.specialization,
                      date: dateLabel,
                      time: slot.label,
                    ),

                    const SizedBox(height: 22),

                    _SectionTitle(
                      title: tr('Автомобиль'),
                      subtitle: tr('Автомобиль, который приедет в сервис'),
                    ),

                    const SizedBox(height: 10),

                    if (isLoggedIn && cars.isNotEmpty)
                      _CarSelector(
                        cars: cars,
                        selectedCarId: _selectedCarId,
                        onChanged: (id) {
                          setState(() {
                            _selectedCarId = id;
                          });
                        },
                      )
                    else
                      _NoCarCard(loggedIn: isLoggedIn),

                    const SizedBox(height: 22),

                    _SectionTitle(
                      title: tr('Ваши данные'),
                      subtitle: tr('Контактные данные для подтверждения записи'),
                    ),

                    const SizedBox(height: 10),

                    _CustomerCard(
                      loggedIn: isLoggedIn,
                      name: isLoggedIn ? auth.user!.name : null,
                      nameController: _nameCtrl,
                      phoneController: _phoneCtrl,
                    ),

                    if (_submitError != null) ...[
                      const SizedBox(height: 14),
                      _SubmitError(message: _submitError!),
                    ],

                    const SizedBox(height: 16),

                    const _CheckCard(),

                    if (selectedCar != null) ...[
                      const SizedBox(height: 12),
                      _SelectedCarMini(car: selectedCar),
                    ],
                  ],
                ),
              ),

              _BottomSubmit(
                loading: _submitting,
                checking: _checkingBookingAvailability,
                available: _bookingAvailable,
                onPressed: _submit,
              ),
            ],
          ),
        ),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr('Подтверждение записи'),
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -.35,
                  ),
                ),
                SizedBox(height: 1),
                Text(
                  tr('Проверьте данные перед записью'),
                  style: TextStyle(fontSize: 10.5, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BookingHero extends StatelessWidget {
  const _BookingHero({
    required this.serviceTitle,
    required this.price,
    required this.duration,
  });

  final String serviceTitle;
  final String price;
  final String duration;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors:
              dark
                  ? [colors.surfaceContainer, colors.surfaceContainer]
                  : [const Color(0xFFFFF2EB), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: BrandColors.orange.withValues(alpha: .14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: BrandColors.orange.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.car_repair_rounded,
                  color: BrandColors.orange,
                  size: 26,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr('Ваша запись'),
                      style: TextStyle(
                        fontSize: 11,
                        color: colors.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      serviceTitle,
                      style: const TextStyle(
                        fontSize: 18,
                        height: 1.15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 31,
                height: 31,
                decoration: const BoxDecoration(
                  color: BrandColors.orange,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _MiniInfo(
                  icon: Icons.payments_outlined,
                  label: tr('Стоимость'),
                  value: price,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: _MiniInfo(
                  icon: Icons.schedule_rounded,
                  label: tr('Длительность'),
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

class _MiniInfo extends StatelessWidget {
  const _MiniInfo({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: .72),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: BrandColors.orange),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 9, color: colors.onSurfaceVariant),
                ),
                const SizedBox(height: 1),
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

class _BookingDetailsCard extends StatelessWidget {
  const _BookingDetailsCard({
    required this.specialist,
    required this.specialization,
    required this.date,
    required this.time,
  });

  final String specialist;
  final String? specialization;
  final String date;
  final String time;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      child: Column(
        children: [
          _DetailLine(
            icon: Icons.engineering_rounded,
            title: tr('Специалист'),
            value:
                specialization != null && specialization!.trim().isNotEmpty
                    ? '$specialist`n${specialization!.trim()}'
                    : specialist,
          ),
          const _CardDivider(),
          _DetailLine(
            icon: Icons.calendar_month_rounded,
            title: tr('Дата'),
            value: date,
          ),
          const _CardDivider(),
          _DetailLine(
            icon: Icons.access_time_rounded,
            title: tr('Время'),
            value: time,
            orange: true,
          ),
        ],
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({
    required this.icon,
    required this.title,
    required this.value,
    this.orange = false,
  });

  final IconData icon;
  final String title;
  final String value;
  final bool orange;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 37,
            height: 37,
            decoration: BoxDecoration(
              color: BrandColors.orange.withValues(alpha: .08),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, size: 19, color: BrandColors.orange),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 10,
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: orange ? BrandColors.orange : colors.onSurface,
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});

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
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: TextStyle(fontSize: 11, color: colors.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _CarSelector extends StatelessWidget {
  const _CarSelector({
    required this.cars,
    required this.selectedCarId,
    required this.onChanged,
  });

  final List<UserCar> cars;
  final String? selectedCarId;
  final ValueChanged<String?> onChanged;

  UserCar? _selected() {
    for (final car in cars) {
      if (car.id == selectedCarId) {
        return car;
      }
    }

    return cars.isNotEmpty ? cars.first : null;
  }

  @override
  Widget build(BuildContext context) {
    final car = _selected();

    return PopupMenuButton<String>(
      initialValue: selectedCarId,
      onSelected: onChanged,
      position: PopupMenuPosition.under,
      itemBuilder: (context) {
        return cars
            .map(
              (item) => PopupMenuItem<String>(
                value: item.id,
                child: Row(
                  children: [
                    SizedBox(
                      width: 38,
                      height: 38,
                      child: _CarBrandLogo(title: item.title, size: 35),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item.displayName,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    if (item.id == selectedCarId)
                      const Icon(
                        Icons.check_circle_rounded,
                        color: BrandColors.orange,
                        size: 20,
                      ),
                  ],
                ),
              ),
            )
            .toList();
      },
      child: _SurfaceCard(
        child: Row(
          children: [
            Container(
              width: 62,
              height: 62,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withValues(alpha: .50),
                borderRadius: BorderRadius.circular(17),
              ),
              child:
                  car == null
                      ? const Icon(
                        Icons.directions_car_rounded,
                        color: BrandColors.orange,
                      )
                      : _CarBrandLogo(title: car.title, size: 48),
            ),
            const SizedBox(width: 13),
            Expanded(
              child:
                  car == null
                      ? Text(
                        tr('Выберите автомобиль'),
                        style: TextStyle(fontWeight: FontWeight.w800),
                      )
                      : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            car.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          if (car.year != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              trf('{0} год', [car.year]),
                              style: TextStyle(
                                fontSize: 11,
                                color:
                                    Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                          if (car.licensePlate?.trim().isNotEmpty == true) ...[
                            const SizedBox(height: 5),
                            Text(
                              car.licensePlate!.trim().toUpperCase(),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ],
                      ),
            ),
            const Icon(Icons.keyboard_arrow_down_rounded),
          ],
        ),
      ),
    );
  }
}

class _NoCarCard extends StatelessWidget {
  const _NoCarCard({required this.loggedIn});

  final bool loggedIn;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      child: Row(
        children: [
          const Icon(Icons.directions_car_outlined, color: BrandColors.orange),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              loggedIn
                  ? tr('Автомобиль не выбран')
                  : tr('Автомобиль можно добавить после входа'),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomerCard extends StatelessWidget {
  const _CustomerCard({
    required this.loggedIn,
    required this.name,
    required this.nameController,
    required this.phoneController,
  });

  final bool loggedIn;
  final String? name;
  final TextEditingController nameController;
  final TextEditingController phoneController;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return _SurfaceCard(
      child: Column(
        children: [
          if (loggedIn)
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: BrandColors.orange.withValues(alpha: .08),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(
                    Icons.person_outline_rounded,
                    color: BrandColors.orange,
                    size: 21,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr('Имя'),
                        style: TextStyle(
                          fontSize: 9.5,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        name ?? '',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          else
            TextFormField(
              controller: nameController,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: tr('Имя'),
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return tr('Введите имя');
                }
                return null;
              },
            ),

          if (loggedIn)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 11),
              child: _CardDivider(),
            )
          else
            const SizedBox(height: 12),

          TextFormField(
            controller: phoneController,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              labelText: tr('Телефон'),
              prefixIcon: Icon(Icons.phone_outlined),
            ),
            validator: (value) {
              if (value == null || value.trim().length < 5) {
                return tr('Введите номер телефона');
              }

              return null;
            },
          ),
        ],
      ),
    );
  }
}

class _CheckCard extends StatelessWidget {
  const _CheckCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: BrandColors.orange.withValues(alpha: .065),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.verified_outlined, color: BrandColors.orange, size: 21),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              tr('Проверьте дату, время, автомобиль и номер телефона перед подтверждением.'),
              style: TextStyle(
                fontSize: 11,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectedCarMini extends StatelessWidget {
  const _SelectedCarMini({required this.car});

  final UserCar car;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.check_circle_rounded,
          color: BrandColors.orange,
          size: 16,
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            trf('Выбран автомобиль: {0}', [car.displayName]),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10.5,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

class _UnavailableCard extends StatelessWidget {
  const _UnavailableCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: BrandColors.orange.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: BrandColors.orange.withValues(alpha: .25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, color: BrandColors.orange),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr('Онлайн-запись недоступна'),
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 3),
                Text(
                  message.isNotEmpty
                      ? message
                      : tr('Пожалуйста, свяжитесь с сервисом.'),
                  style: const TextStyle(fontSize: 12, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SubmitError extends StatelessWidget {
  const _SubmitError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: BrandColors.orange.withValues(alpha: .09),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: BrandColors.orange,
            size: 20,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: BrandColors.orange, fontSize: 11.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomSubmit extends StatelessWidget {
  const _BottomSubmit({
    required this.loading,
    required this.checking,
    required this.available,
    required this.onPressed,
  });

  final bool loading;
  final bool checking;
  final bool available;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final enabled = !loading && !checking && available;

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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .05),
            blurRadius: 18,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 53,
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
          child:
              loading
                  ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.3,
                      color: Colors.white,
                    ),
                  )
                  : checking
                  ? Text(
                    tr('Проверяем доступность...'),
                    style: TextStyle(fontWeight: FontWeight.w800),
                  )
                  : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline_rounded, size: 20),
                      SizedBox(width: 7),
                      Text(
                        tr('Подтвердить запись'),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(width: 6),
                      Icon(Icons.arrow_forward_rounded, size: 19),
                    ],
                  ),
        ),
      ),
    );
  }
}

class _SurfaceCard extends StatelessWidget {
  const _SurfaceCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: dark ? colors.surfaceContainer : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: .42)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? .08 : .03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _CardDivider extends StatelessWidget {
  const _CardDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      color: Theme.of(
        context,
      ).colorScheme.outlineVariant.withValues(alpha: .30),
    );
  }
}

class _CarBrandLogo extends StatelessWidget {
  const _CarBrandLogo({required this.title, this.size = 48});

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
