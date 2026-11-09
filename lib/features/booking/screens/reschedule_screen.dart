import 'package:mobile/core/nav.dart'; // AG_FIX3
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/theme.dart';
import '../../../models/booking_with_details.dart';
import '../../../models/slot.dart';
import '../data/booking_repository.dart';
import '../providers/my_bookings_provider.dart';
import '../../../core/i18n.dart'; // AG_I18N1

class RescheduleScreen extends StatefulWidget {
  const RescheduleScreen({super.key, required this.booking});
  final BookingWithDetails booking;

  @override
  State<RescheduleScreen> createState() => _RescheduleScreenState();
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

class _RescheduleScreenState extends State<RescheduleScreen> {
  late DateTime _selectedDate;
  late List<DateTime> _dates;
  Future<List<Slot>>? _slotsFuture;
  bool _submitting = false;
  String? _error;

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
    final repo = context.read<BookingRepository>();
    _slotsFuture = repo.slots(
      specialistId: widget.booking.specialist.id,
      date: _selectedDate,
      durationMinutes: widget.booking.durationMinutes,
    );
    setState(() {});
  }

  Future<void> _reschedule(Slot slot) async {
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final repo = context.read<BookingRepository>();
      await repo.rescheduleBooking(widget.booking.id, slot.start);
      if (!mounted) return;
      context.read<MyBookingsProvider>().load();
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.booking;
    final currentDate = DateFormat('d MMMM, HH:mm', AgI18n.dateLocale).format(b.scheduledAt);

    return Scaffold(
      appBar: AppBar(leading: const AgBackButton(fallback: '/bookings'), /* AG_FIX3 */ title: Text(tr('Перенос записи'))),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 18,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    trf('Текущая запись: {0} — {1}', [currentDate, b.service.title]),
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 88,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              itemCount: _dates.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final d = _dates[i];
                final selected = d == _selectedDate;
                return _DateChip(
                  date: d,
                  selected: selected,
                  onTap: () {
                    setState(() {
                      _selectedDate = d;
                      _loadSlots();
                    });
                  },
                );
              },
            ),
          ),
          const Divider(height: 1),
          if (_error != null)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: BrandColors.orange.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _error!,
                style: TextStyle(fontSize: 13, color: BrandColors.orange),
              ),
            ),
          Expanded(
            child: FutureBuilder<List<Slot>>(
              future: _slotsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text(snapshot.error.toString()));
                }
                final slots = snapshot.data ?? const <Slot>[];
                if (slots.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        tr('На эту дату нет свободного времени'),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 2.1,
                  ),
                  itemCount: slots.length,
                  itemBuilder:
                      (_, i) => _SlotTile(
                        slot: slots[i],
                        onTap: _submitting ? null : () => _reschedule(slots[i]),
                      ),
                );
              },
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
    final weekday = DateFormat.E(AgI18n.dateLocale).format(date).toUpperCase();
    final day = DateFormat('d').format(date);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 60,
        decoration: BoxDecoration(
          color:
              selected
                  ? BrandColors.orange
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              weekday,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color:
                    selected
                        ? Colors.white
                        : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              day,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color:
                    selected
                        ? Colors.white
                        : Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SlotTile extends StatelessWidget {
  const _SlotTile({required this.slot, required this.onTap});
  final Slot slot;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: BrandColors.blue.withValues(alpha: 0.4)),
        ),
        child: Text(
          slot.label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color:
                onTap != null
                    ? BrandColors.blue
                    : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
