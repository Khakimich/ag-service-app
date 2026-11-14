// AG_QUICKBOOK1 — запись «сначала время»: дата и время → свободные мастера → услуга.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/i18n.dart';
import '../../../models/service.dart';
import '../../../models/slot.dart';
import '../../../models/specialist.dart';
import '../data/booking_repository.dart';
import '../data/company_repository.dart';
import '../providers/booking_flow_provider.dart';

const _orange = Color(0xFFFF6A00);

class QuickBookingScreen extends StatefulWidget {
  const QuickBookingScreen({super.key});
  @override
  State<QuickBookingScreen> createState() => _QuickBookingScreenState();
}

class _QuickBookingScreenState extends State<QuickBookingScreen> {
  int _step = 0; // 0 — дата и время, 1 — мастер, 2 — услуга
  late final List<DateTime> _dates;
  late DateTime _date;
  List<Specialist> _specialists = const [];
  // время "HH:mm" → свободные мастера и их слот
  Map<String, List<(Specialist, Slot)>> _free = {};
  bool _loading = true;
  String? _error;
  String? _time;
  Specialist? _master;
  Slot? _slot;
  List<Service>? _services;
  String _query = '';
  String? _checkingId;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _dates = List.generate(14, (i) => DateTime(now.year, now.month, now.day).add(Duration(days: i)));
    _date = _dates.first;
    _init();
  }

  Future<void> _init() async {
    try {
      _specialists = await context.read<CompanyRepository>().listSpecialists();
    } catch (e) {
      _error = tr('Не удалось загрузить мастеров');
    }
    await _loadDay();
  }

  Future<void> _loadDay() async {
    setState(() { _loading = true; _error = null; _time = null; _free = {}; });
    final repo = context.read<BookingRepository>();
    final now = DateTime.now().toUtc().add(const Duration(minutes: 30));
    final result = <String, List<(Specialist, Slot)>>{};
    await Future.wait(_specialists.map((s) async {
      try {
        final slots = await repo.slots(specialistId: s.id, date: _date, durationMinutes: 30);
        for (final sl in slots) {
          if (sl.start.toUtc().isBefore(now)) continue;
          // AG_QUICKBOOK2: время по Екатеринбургу (как в подписи слота), а не UTC
          final m = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(sl.label);
          final key = m != null ? '${m.group(1)!.padLeft(2, '0')}:${m.group(2)}' : sl.label;
          (result[key] ??= []).add((s, sl));
        }
      } catch (_) {}
    }));
    if (mounted) setState(() { _free = Map.fromEntries(result.entries.toList()..sort((a, b) => a.key.compareTo(b.key))); _loading = false; });
  }

  Future<void> _openServices() async {
    setState(() => _step = 2);
    if (_services == null) {
      try {
        final list = await context.read<BookingRepository>().listServices();
        if (mounted) setState(() => _services = list);
      } catch (_) {
        if (mounted) setState(() => _services = const []);
      }
    }
  }

  Future<void> _pickService(Service s) async {
    setState(() => _checkingId = s.id);
    final repo = context.read<BookingRepository>();
    Slot? fit;
    try {
      final slots = await repo.slots(specialistId: _master!.id, date: _date, durationMinutes: s.durationMinutes);
      for (final sl in slots) {
        if (sl.start.toUtc() == _slot!.start.toUtc()) { fit = sl; break; }
      }
    } catch (_) {}
    if (mounted == false) return;
    setState(() => _checkingId = null);
    if (fit == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(trf('Мастер не успеет «{0}» с {1} — работа длится дольше свободного окна. Выберите другое время или мастера.', [s.title, _time ?? ''])),
      ));
      return;
    }
    final flow = context.read<BookingFlowProvider>();
    flow.selectService(s);
    flow.selectSpecialist(_master!);
    flow.selectSlot(fit);
    context.push('/booking/car');
  }

  String _dow(DateTime d) => [tr('Пн'), tr('Вт'), tr('Ср'), tr('Чт'), tr('Пт'), tr('Сб'), tr('Вс')][d.weekday - 1];
  String _mon(DateTime d) => [tr('янв'), tr('фев'), tr('мар'), tr('апр'), tr('мая'), tr('июн'), tr('июл'), tr('авг'), tr('сен'), tr('окт'), tr('ноя'), tr('дек')][d.month - 1];

  @override
  Widget build(BuildContext context) {
    final titles = [tr('Дата и время'), tr('Свободные мастера'), tr('Выберите услугу')];
    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (did, _) { if (did == false) setState(() => _step -= 1); },
      child: Scaffold(
        appBar: AppBar(
          title: Text(titles[_step], style: const TextStyle(fontWeight: FontWeight.w800)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => _step == 0 ? context.pop() : setState(() => _step -= 1),
          ),
        ),
        body: Column(children: [
          _Steps(step: _step),
          if (_step > 0) _Summary(text: '${_date.day} ${_mon(_date)}, ${_dow(_date)} · ${_time ?? ''}${_master != null && _step == 2 ? ' · ${_master!.fullName}' : ''}'),
          Expanded(child: [_stepTime, _stepMaster, _stepService][_step]()),
        ]),
      ),
    );
  }

  Widget _stepTime() {
    final cs = Theme.of(context).colorScheme;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(
        height: 84,
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          scrollDirection: Axis.horizontal,
          itemCount: _dates.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final d = _dates[i];
            final on = d == _date;
            return GestureDetector(
              onTap: () { if (on == false) { setState(() => _date = d); _loadDay(); } },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: 58,
                decoration: BoxDecoration(
                  color: on ? _orange : cs.surfaceContainerHighest.withValues(alpha: .5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(i == 0 ? tr('Сегодня') : _dow(d), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: on ? Colors.white : cs.onSurfaceVariant)),
                  Text('${d.day}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: on ? Colors.white : cs.onSurface)),
                  Text(_mon(d), style: TextStyle(fontSize: 11, color: on ? Colors.white : cs.onSurfaceVariant)),
                ]),
              ),
            );
          },
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Text(tr('Свободное время'), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
      ),
      Expanded(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text(_error!))
                : _free.isEmpty
                    ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(tr('На этот день свободного времени нет. Выберите другую дату.'), textAlign: TextAlign.center)))
                    : GridView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 110, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 1.45),
                        itemCount: _free.length,
                        itemBuilder: (_, i) {
                          final e = _free.entries.elementAt(i);
                          return Material(
                            color: cs.surfaceContainerHighest.withValues(alpha: .5),
                            borderRadius: BorderRadius.circular(14),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () => setState(() { _time = e.key; _master = null; _step = 1; }),
                              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                                Text(e.key, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                                Text(trf('{0} мастер.', [e.value.length]), style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
                              ]),
                            ),
                          );
                        },
                      ),
      ),
    ]);
  }

  Widget _stepMaster() {
    final list = _free[_time] ?? const [];
    final cs = Theme.of(context).colorScheme;
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final (m, sl) = list[i];
        return Material(
          color: cs.surfaceContainerHighest.withValues(alpha: .45),
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () { setState(() { _master = m; _slot = sl; }); _openServices(); },
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: _orange.withValues(alpha: .15),
                  backgroundImage: (m.photoUrl ?? '').isNotEmpty ? NetworkImage(m.photoUrl!) : null,
                  child: (m.photoUrl ?? '').isEmpty ? Text(m.fullName.isNotEmpty ? m.fullName[0] : '?', style: const TextStyle(fontWeight: FontWeight.w900, color: _orange, fontSize: 20)) : null,
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(m.fullName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  if ((m.specialization ?? '').isNotEmpty)
                    Text(m.specialization!, style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
                  const SizedBox(height: 4),
                  Text(trf('Свободен в {0}', [_time ?? '']), style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF2E7D32))),
                ])),
                const Icon(Icons.chevron_right_rounded, color: _orange),
              ]),
            ),
          ),
        );
      },
    );
  }

  Widget _stepService() {
    final cs = Theme.of(context).colorScheme;
    if (_services == null) return const Center(child: CircularProgressIndicator());
    final q = _query.trim().toLowerCase();
    final list = q.isEmpty ? _services! : _services!.where((s) => s.title.toLowerCase().contains(q) || s.category.toLowerCase().contains(q)).toList();
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: TextField(
          onChanged: (v) => setState(() => _query = v),
          style: const TextStyle(fontSize: 16),
          decoration: InputDecoration(
            hintText: tr('Поиск услуги: масло, колодки, развал…'),
            prefixIcon: const Icon(Icons.search_rounded),
            filled: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          ),
        ),
      ),
      Expanded(
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            final s = list[i];
            final busy = _checkingId == s.id;
            return Material(
              color: cs.surfaceContainerHighest.withValues(alpha: .45),
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: _checkingId == null ? () => _pickService(s) : null,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        width: 56, height: 56,
                        child: (s.photoUrl ?? '').isNotEmpty
                            ? Image.network(s.photoUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.build_rounded, color: _orange))
                            : const Icon(Icons.build_rounded, color: _orange),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(s.category, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: _orange)),
                      Text(s.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700)),
                      Text(trf('от {0} ₽ · {1} мин', [s.priceFrom.toStringAsFixed(0), s.durationMinutes]), style: TextStyle(fontSize: 12.5, color: cs.onSurfaceVariant)),
                    ])),
                    busy ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5)) : const Icon(Icons.chevron_right_rounded, color: _orange),
                  ]),
                ),
              ),
            );
          },
        ),
      ),
    ]);
  }
}

class _Steps extends StatelessWidget {
  const _Steps({required this.step});
  final int step;
  @override
  Widget build(BuildContext context) {
    final labels = [tr('Время'), tr('Мастер'), tr('Услуга')];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Row(children: List.generate(3, (i) {
        final on = i <= step;
        return Expanded(child: Column(children: [
          AnimatedContainer(duration: const Duration(milliseconds: 200), height: 5, margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(color: on ? _orange : Colors.black12, borderRadius: BorderRadius.circular(3))),
          const SizedBox(height: 4),
          Text('${i + 1}. ${labels[i]}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: on ? _orange : Colors.black38)),
        ]));
      })),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(color: _orange.withValues(alpha: .10), borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          const Icon(Icons.event_available_rounded, color: _orange, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontWeight: FontWeight.w800))),
        ]),
      );
}
