import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/theme.dart';
import '../providers/booking_flow_provider.dart';
import '../../../core/i18n.dart'; // AG_I18N1

class BookingSuccessScreen extends StatelessWidget {
  const BookingSuccessScreen({super.key});

  void _goHome(BuildContext context) {
    context.read<BookingFlowProvider>().reset();
    context.go('/');
  }

  void _goBookings(BuildContext context) {
    context.read<BookingFlowProvider>().reset();
    context.go('/bookings');
  }

  Future<void> _addToCalendar(BuildContext context) async {
    if (kIsWeb) { /* AG_WEB_CAL */ ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('Добавить в календарь можно в приложении на телефоне')))); return; }
    final flow = context.read<BookingFlowProvider>();

    final service = flow.service;
    final specialist = flow.specialist;
    final slot = flow.slot;

    if (service == null || slot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('Не удалось получить данные записи'))),
      );
      return;
    }

    final specialization = specialist?.specialization?.trim();

    final masterText =
        specialist == null
            ? null
            : specialization != null && specialization.isNotEmpty
            ? '${specialist.fullName} — $specialization'
            : specialist.fullName;

    final endDate = slot.start.add(Duration(minutes: service.durationMinutes));

    final description = <String>[
      tr('Запись в автосервис Автогром'),
      '',
      trf('Услуга: {0}', [service.title]),
      trf('Стоимость: {0}', [service.priceLabel]),
      if (masterText != null) trf('Специалист: {0}', [masterText]),
    ].join('\n');

    final event = Event(
      title: trf('Автогром — {0}', [service.title]),
      description: description,
      startDate: slot.start,
      endDate: endDate,
    );

    await Add2Calendar.addEvent2Cal(event);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final flow = context.watch<BookingFlowProvider>();

    final service = flow.service;
    final specialist = flow.specialist;
    final slot = flow.slot;

    final specialization = specialist?.specialization?.trim();

    String? dateLabel;
    String? timeLabel;

    if (slot != null) {
      dateLabel = DateFormat('d MMMM, EEEE', AgI18n.dateLocale).format(slot.start);

      timeLabel = slot.label;
    }

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 32, 18, 24),
                child: Column(
                  children: [
                    const _SuccessIcon(),

                    const SizedBox(height: 20),

                    Text(
                      tr('Запись создана!'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -.6,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      tr('Ваша заявка успешно отправлена\nв автосервис.'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.45,
                        color: colors.onSurfaceVariant,
                      ),
                    ),

                    if (service != null ||
                        specialist != null ||
                        slot != null) ...[
                      const SizedBox(height: 26),

                      _DetailsCard(
                        serviceTitle: service?.title,
                        price: service?.priceLabel,
                        duration: service?.durationLabel,
                        specialistName: specialist?.fullName,
                        specialistSpecialization: specialization,
                        date: dateLabel,
                        time: timeLabel,
                      ),
                    ],

                    const SizedBox(height: 16),

                    _NotificationCard(colors: colors),
                  ],
                ),
              ),
            ),

            _BottomActions(
              calendarEnabled: service != null && slot != null,
              onCalendar: () => _addToCalendar(context),
              onBookings: () => _goBookings(context),
              onHome: () => _goHome(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuccessIcon extends StatelessWidget {
  const _SuccessIcon();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 108,
          height: 108,
          decoration: BoxDecoration(
            color: BrandColors.orange.withValues(alpha: .045),
            shape: BoxShape.circle,
          ),
        ),
        Container(
          width: 82,
          height: 82,
          decoration: BoxDecoration(
            color: BrandColors.orange.withValues(alpha: .10),
            shape: BoxShape.circle,
          ),
        ),
        Container(
          width: 58,
          height: 58,
          decoration: const BoxDecoration(
            color: BrandColors.orange,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_rounded, size: 36, color: Colors.white),
        ),
      ],
    );
  }
}

class _DetailsCard extends StatelessWidget {
  const _DetailsCard({
    required this.serviceTitle,
    required this.price,
    required this.duration,
    required this.specialistName,
    required this.specialistSpecialization,
    required this.date,
    required this.time,
  });

  final String? serviceTitle;
  final String? price;
  final String? duration;
  final String? specialistName;
  final String? specialistSpecialization;
  final String? date;
  final String? time;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: dark ? colors.surfaceContainer : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: .42)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? .08 : .035),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          if (serviceTitle != null)
            _DetailRow(
              icon: Icons.car_repair_rounded,
              label: tr('Услуга'),
              value: serviceTitle!,
              secondValue: duration,
            ),

          if (serviceTitle != null && price != null) const _CardDivider(),

          if (price != null)
            _DetailRow(
              icon: Icons.payments_outlined,
              label: tr('Стоимость'),
              value: price!,
              highlight: true,
            ),

          if (specialistName != null) ...[
            const _CardDivider(),
            _DetailRow(
              icon: Icons.engineering_rounded,
              label: tr('Специалист'),
              value: specialistName!,
              secondValue:
                  specialistSpecialization != null &&
                          specialistSpecialization!.isNotEmpty
                      ? specialistSpecialization
                      : null,
            ),
          ],

          if (date != null) ...[
            const _CardDivider(),
            _DetailRow(
              icon: Icons.calendar_month_rounded,
              label: tr('Дата'),
              value: date!,
            ),
          ],

          if (time != null) ...[
            const _CardDivider(),
            _DetailRow(
              icon: Icons.access_time_rounded,
              label: tr('Время'),
              value: time!,
              highlight: true,
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.secondValue,
    this.highlight = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? secondValue;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: BrandColors.orange.withValues(alpha: .08),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, size: 21, color: BrandColors.orange),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 9.5,
                    color: colors.onSurfaceVariant,
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
                    color: highlight ? BrandColors.orange : colors.onSurface,
                  ),
                ),

                if (secondValue != null && secondValue!.trim().isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    secondValue!,
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.25,
                      fontWeight: FontWeight.w600,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.colors});

  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: .42),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: BrandColors.orange.withValues(alpha: .08),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.notifications_active_outlined,
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
                  tr('Следите за записью'),
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  tr('Информация о записи будет доступна в разделе «Мои записи».'),
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.4,
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

class _CardDivider extends StatelessWidget {
  const _CardDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: const EdgeInsets.only(left: 54),
      color: Theme.of(
        context,
      ).colorScheme.outlineVariant.withValues(alpha: .28),
    );
  }
}

class _BottomActions extends StatelessWidget {
  const _BottomActions({
    required this.calendarEnabled,
    required this.onCalendar,
    required this.onBookings,
    required this.onHome,
  });

  final bool calendarEnabled;
  final VoidCallback onCalendar;
  final VoidCallback onBookings;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

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
          top: BorderSide(color: colors.outlineVariant.withValues(alpha: .30)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .045),
            blurRadius: 18,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton(
              onPressed: calendarEnabled ? onCalendar : null,
              style: OutlinedButton.styleFrom(
                foregroundColor: BrandColors.orange,
                side: BorderSide(
                  color: BrandColors.orange.withValues(alpha: .48),
                  width: 1.3,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(17),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_month_rounded, size: 20),
                  SizedBox(width: 8),
                  Text(
                    tr('Добавить в календарь'),
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
                  ),
                  SizedBox(width: 6),
                  Icon(Icons.add_rounded, size: 19),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: onBookings,
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
                  Icon(Icons.event_note_rounded, size: 20),
                  SizedBox(width: 8),
                  Text(
                    tr('Посмотреть мои записи'),
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
                  ),
                  SizedBox(width: 6),
                  Icon(Icons.arrow_forward_rounded, size: 19),
                ],
              ),
            ),
          ),

          const SizedBox(height: 2),

          TextButton(
            onPressed: onHome,
            child: Text(
              tr('На главную'),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: colors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
