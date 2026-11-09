import 'package:mobile/core/nav.dart'; // AG_FIX1
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/theme.dart';
import '../../../models/slot.dart';
import '../data/booking_repository.dart';
import '../providers/booking_flow_provider.dart';
import '../../../core/i18n.dart'; // AG_I18N1

class DateTimeSelectionScreen extends StatefulWidget {
  const DateTimeSelectionScreen({super.key});

  @override
  State<DateTimeSelectionScreen> createState() =>
      _DateTimeSelectionScreenState();
}

DateTime _ekaterinburgNow() {
  return DateTime.now().toUtc().add(const Duration(hours: 5));
}

bool _sameCalendarDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

List<Slot> _removePastSlots(List<Slot> slots, DateTime selectedDate) {
  final now = _ekaterinburgNow();

  final today = DateTime(now.year, now.month, now.day);

  final date = DateTime(
    selectedDate.year,
    selectedDate.month,
    selectedDate.day,
  );

  if (date.isBefore(today)) {
    return const <Slot>[];
  }

  if (!_sameCalendarDay(date, today)) {
    return slots;
  }

  // ?????? ??????? ?? 30 ????? ?? ??????.
  final minimumTime = now.add(const Duration(minutes: 30));

  return slots
      .where((slot) {
        final start = slot.start;

        final slotTime = DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
          start.hour,
          start.minute,
          start.second,
        );

        return !slotTime.isBefore(minimumTime);
      })
      .toList(growable: false);
}

class _DateTimeSelectionScreenState extends State<DateTimeSelectionScreen> {
  late DateTime _selectedDate;
  late List<DateTime> _dates;
  Future<List<Slot>>? _slotsFuture;

  Slot? _selectedSlot;

  @override
  void initState() {
    super.initState();

    final today = DateTime.now();

    _selectedDate = DateTime(today.year, today.month, today.day);

    _dates = List.generate(14, (i) {
      final d = today.add(Duration(days: i));

      return DateTime(d.year, d.month, d.day);
    });

    _loadSlots();
  }

  void _loadSlots() {
    final flow = context.read<BookingFlowProvider>();
    final repo = context.read<BookingRepository>();

    _selectedSlot = null;

    _slotsFuture = repo.slots(
      specialistId: flow.specialist!.id,
      date: _selectedDate,
      durationMinutes: flow.service!.durationMinutes,
    );
  }

  void _selectDate(DateTime date) {
    if (date == _selectedDate) return;

    setState(() {
      _selectedDate = date;
      _loadSlots();
    });
  }

  void _selectSlot(Slot slot) {
    setState(() {
      _selectedSlot = slot;
    });
  }

  void _continue() {
    final slot = _selectedSlot;

    if (slot == null) return;

    context.read<BookingFlowProvider>().selectSlot(slot);

    context.push('/booking/car');
  }

  String _selectedDateTitle() {
    final formatted = DateFormat('EEEE, d MMMM', AgI18n.dateLocale).format(_selectedDate);

    if (formatted.isEmpty) {
      return '';
    }

    return formatted[0].toUpperCase() + formatted.substring(1);
  }

  int? _hourFromSlot(Slot slot) {
    final match = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(slot.label);

    if (match == null) return null;

    return int.tryParse(match.group(1)!);
  }

  List<Slot> _morningSlots(List<Slot> slots) {
    return slots.where((slot) {
      final hour = _hourFromSlot(slot);
      return hour != null && hour < 12;
    }).toList();
  }

  List<Slot> _daySlots(List<Slot> slots) {
    return slots.where((slot) {
      final hour = _hourFromSlot(slot);
      return hour != null && hour >= 12 && hour < 17;
    }).toList();
  }

  List<Slot> _eveningSlots(List<Slot> slots) {
    return slots.where((slot) {
      final hour = _hourFromSlot(slot);
      return hour != null && hour >= 17;
    }).toList();
  }

  List<Slot> _otherSlots(List<Slot> slots) {
    return slots.where((slot) {
      return _hourFromSlot(slot) == null;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _TopBar(onBack: () => context.agBack()), // AG_FIX1

            Expanded(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                    sliver: SliverToBoxAdapter(
                      child: _SelectedDateCard(title: _selectedDateTitle()),
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 94,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                        itemCount: _dates.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (_, i) {
                          final date = _dates[i];

                          return _DateChip(
                            date: date,
                            selected: date == _selectedDate,
                            onTap: () => _selectDate(date),
                          );
                        },
                      ),
                    ),
                  ),

                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                    sliver: SliverToBoxAdapter(
                      child: FutureBuilder<List<Slot>>(
                        future: _slotsFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const _LoadingSlots();
                          }

                          if (snapshot.hasError) {
                            return _SlotsError(
                              message: snapshot.error.toString(),
                              onRetry: () {
                                setState(() {
                                  _loadSlots();
                                });
                              },
                            );
                          }

                          final slots = snapshot.data ?? const <Slot>[];

                          if (slots.isEmpty) {
                            return const _NoSlots();
                          }

                          final morning = _morningSlots(slots);
                          final day = _daySlots(slots);
                          final evening = _eveningSlots(slots);
                          final other = _otherSlots(slots);

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      tr('Доступное время'),
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: -.3,
                                      ),
                                    ),
                                  ),

                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: BrandColors.orange.withValues(
                                        alpha: .09,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      trf('{0} свободно', [slots.length]),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: BrandColors.orange,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 5),

                              Text(
                                tr('Выберите удобное время для записи'),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colors.onSurfaceVariant,
                                ),
                              ),

                              const SizedBox(height: 18),

                              if (morning.isNotEmpty)
                                _SlotSection(
                                  icon: Icons.wb_sunny_outlined,
                                  title: tr('Утро'),
                                  slots: morning,
                                  selectedSlot: _selectedSlot,
                                  onSelected: _selectSlot,
                                ),

                              if (day.isNotEmpty)
                                _SlotSection(
                                  icon: Icons.light_mode_rounded,
                                  title: tr('День'),
                                  slots: day,
                                  selectedSlot: _selectedSlot,
                                  onSelected: _selectSlot,
                                ),

                              if (evening.isNotEmpty)
                                _SlotSection(
                                  icon: Icons.dark_mode_outlined,
                                  title: tr('Вечер'),
                                  slots: evening,
                                  selectedSlot: _selectedSlot,
                                  onSelected: _selectSlot,
                                ),

                              if (other.isNotEmpty)
                                _SlotSection(
                                  icon: Icons.schedule_rounded,
                                  title: tr('Другое время'),
                                  slots: other,
                                  selectedSlot: _selectedSlot,
                                  onSelected: _selectSlot,
                                ),

                              const SizedBox(height: 20),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),

            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child:
                  _selectedSlot == null
                      ? const SizedBox.shrink()
                      : _BottomContinue(
                        key: ValueKey(_selectedSlot!.label),
                        slotLabel: _selectedSlot!.label,
                        onPressed: _continue,
                      ),
            ),
          ],
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
      child: Row(
        children: [
          Material(
            color: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest.withValues(alpha: .65),
            borderRadius: BorderRadius.circular(13),
            child: InkWell(
              onTap: onBack,
              borderRadius: BorderRadius.circular(13),
              child: const SizedBox(
                width: 40,
                height: 40,
                child: Icon(Icons.arrow_back_ios_new_rounded, size: 17),
              ),
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr('Дата и время'),
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
                SizedBox(height: 1),
                Text(
                  tr('Выберите удобное время'),
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectedDateCard extends StatelessWidget {
  const _SelectedDateCard({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: dark ? colors.surfaceContainer : Colors.white,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: .45)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? .08 : .035),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 47,
            height: 47,
            decoration: BoxDecoration(
              color: BrandColors.orange.withValues(alpha: .10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.calendar_month_rounded,
              color: BrandColors.orange,
              size: 24,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr('Выбранная дата'),
                  style: TextStyle(
                    fontSize: 10.5,
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
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

class _DateChip extends StatelessWidget {
  const _DateChip({
    required this.date,
    required this.selected,
    required this.onTap,
  });

  final DateTime date;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final weekday = DateFormat('E', AgI18n.dateLocale).format(date).toUpperCase();

    final day = DateFormat('d').format(date);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(17),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 58,
        decoration: BoxDecoration(
          color:
              selected
                  ? BrandColors.orange
                  : colors.surfaceContainerHighest.withValues(alpha: .55),
          borderRadius: BorderRadius.circular(17),
          border: Border.all(
            color:
                selected
                    ? BrandColors.orange
                    : colors.outlineVariant.withValues(alpha: .30),
          ),
          boxShadow:
              selected
                  ? [
                    BoxShadow(
                      color: BrandColors.orange.withValues(alpha: .20),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                  : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              weekday,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color:
                    selected
                        ? Colors.white.withValues(alpha: .85)
                        : colors.onSurfaceVariant,
              ),
            ),

            const SizedBox(height: 3),

            Text(
              day,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: selected ? Colors.white : colors.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SlotSection extends StatelessWidget {
  const _SlotSection({
    required this.icon,
    required this.title,
    required this.slots,
    required this.selectedSlot,
    required this.onSelected,
  });

  final IconData icon;
  final String title;
  final List<Slot> slots;
  final Slot? selectedSlot;
  final ValueChanged<Slot> onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 19),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 17, color: BrandColors.orange),
              const SizedBox(width: 7),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 7),
              Text(
                '${slots.length}',
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          LayoutBuilder(
            builder: (context, constraints) {
              const spacing = 8.0;

              final width = (constraints.maxWidth - spacing * 3) / 4;

              return Wrap(
                spacing: spacing,
                runSpacing: 8,
                children: [
                  for (final slot in slots)
                    SizedBox(
                      width: width,
                      height: 44,
                      child: _SlotTile(
                        slot: slot,
                        selected:
                            identical(selectedSlot, slot) ||
                            selectedSlot?.label == slot.label,
                        onTap: () => onSelected(slot),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SlotTile extends StatelessWidget {
  const _SlotTile({
    required this.slot,
    required this.selected,
    required this.onTap,
  });

  final Slot slot;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 170),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? BrandColors.orange : colors.surface,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color:
                  selected
                      ? BrandColors.orange
                      : colors.outlineVariant.withValues(alpha: .75),
            ),
            boxShadow:
                selected
                    ? [
                      BoxShadow(
                        color: BrandColors.orange.withValues(alpha: .18),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ]
                    : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[
                const Icon(Icons.check_rounded, size: 15, color: Colors.white),
                const SizedBox(width: 3),
              ],

              Flexible(
                child: Text(
                  slot.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: selected ? Colors.white : colors.onSurface,
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

class _BottomContinue extends StatelessWidget {
  const _BottomContinue({
    super.key,
    required this.slotLabel,
    required this.onPressed,
  });

  final String slotLabel;
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
            decoration: BoxDecoration(
              color: BrandColors.orange.withValues(alpha: .09),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr('Выбрано'),
                  style: TextStyle(fontSize: 9, color: colors.onSurfaceVariant),
                ),
                Text(
                  slotLabel,
                  style: const TextStyle(
                    color: BrandColors.orange,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: onPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: BrandColors.orange,
                  foregroundColor: Colors.white,
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
          ),
        ],
      ),
    );
  }
}

class _LoadingSlots extends StatelessWidget {
  const _LoadingSlots();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 220,
      child: Center(
        child: CircularProgressIndicator(color: BrandColors.orange),
      ),
    );
  }
}

class _NoSlots extends StatelessWidget {
  const _NoSlots();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: .40),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: BrandColors.orange.withValues(alpha: .09),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.event_busy_rounded,
              color: BrandColors.orange,
              size: 27,
            ),
          ),

          const SizedBox(height: 12),

          Text(
            tr('Нет свободного времени'),
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),

          const SizedBox(height: 5),

          Text(
            tr('Выберите другой день'),
            style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _SlotsError extends StatelessWidget {
  const _SlotsError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: BrandColors.orange,
            size: 38,
          ),
          const SizedBox(height: 10),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          TextButton(onPressed: onRetry, child: Text(tr('Повторить'))),
        ],
      ),
    );
  }
}
