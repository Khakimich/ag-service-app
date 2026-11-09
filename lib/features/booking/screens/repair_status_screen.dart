import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/ag_icons.dart';
import '../../../core/theme.dart';
import '../../../models/booking_with_details.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/my_bookings_provider.dart';
import '../../../core/i18n.dart'; // AG_I18N1

/// «Статус ремонта»: на какой стадии машина клиента.
///
/// Данные берутся с job.autogrom.ru — там мастер в «Моих записях» нажимает
/// «Начать работу» / «Завершить» по каждой услуге. Проценты считаются по минутам
/// от нормы услуги; пока мастер не нажал «Завершить», больше 99 % не бывает.
/// Секунд, штрафов и имени мастера клиент не видит.
const String kRepairStatusUrl = String.fromEnvironment(
  'REPAIR_STATUS_URL',
  defaultValue: 'https://job.autogrom.ru/repair.php',
);

class RepairService {
  RepairService({
    required this.title,
    required this.state,
    required this.percent,
    required this.normMinutes,
    this.startedAt,
    this.paused,
    this.pausedTotal = 0,
    this.pausedAt,
  });

  final String title;

  /// waiting — ожидает, work — в работе, done — завершена.
  final String state;
  int percent;
  final int normMinutes;

  /// Секунды Unix по часам сервера.
  final int? startedAt;

  /// null — идёт; 'pause' — пауза; 'parts' — мастер ждёт запчасть.
  final String? paused;

  /// Сколько секунд уже было на паузе (прошлые паузы).
  final int pausedTotal;

  /// Когда началась текущая пауза (секунды Unix), если сейчас пауза.
  final int? pausedAt;

  factory RepairService.fromJson(Map<String, dynamic> json) => RepairService(
    title: (json['title'] ?? tr('Услуга')).toString(),
    state: (json['state'] ?? 'waiting').toString(),
    percent: (json['percent'] as num?)?.toInt() ?? 0,
    normMinutes: ((json['norm_minutes'] as num?)?.toInt() ?? 30).clamp(1, 100000).toInt(),
    startedAt: (json['started_at'] as num?)?.toInt(),
    paused: json['paused']?.toString(),
    pausedTotal: (json['paused_total'] as num?)?.toInt() ?? 0,
    pausedAt: (json['paused_at'] as num?)?.toInt(),
  );
}

class RepairStatus {
  RepairStatus({
    required this.found,
    required this.stage,
    required this.stageText,
    required this.percent,
    required this.services,
    required this.serverShift,
    this.car = '',
    this.plate = '',
    this.master = '',
    this.paused,
    this.doneAt,
  });

  final bool found;

  /// waiting — работы не начаты, work — идут, done — машина готова.
  String stage;
  String stageText;
  int percent;
  final List<RepairService> services;
  final String car;
  final String plate;

  /// Ф.И.О. мастера.
  final String master;

  /// Сейчас пауза у текущей услуги: 'pause' или 'parts' (ждём запчасть).
  final String? paused;

  /// Когда завершены все работы (секунды Unix по часам сервера).
  final int? doneAt;

  /// Разница между часами сервера и телефона, в секундах.
  final int serverShift;

  factory RepairStatus.fromJson(Map<String, dynamic> json) {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final server = (json['server_time'] as num?)?.toInt() ?? now;
    return RepairStatus(
      found: json['found'] != false,
      stage: (json['stage'] ?? 'waiting').toString(),
      stageText: (json['stage_text'] ?? tr('Ожидает начала работ')).toString(),
      percent: (json['percent'] as num?)?.toInt() ?? 0,
      services:
          (json['services'] as List<dynamic>? ?? [])
              .whereType<Map>()
              .map((e) => RepairService.fromJson(Map<String, dynamic>.from(e)))
              .toList(),
      car: (json['car'] ?? '').toString(),
      plate: (json['plate'] ?? '').toString(),
      master: (json['master'] ?? '').toString(),
      paused: json['paused']?.toString(),
      doneAt: (json['done_at'] as num?)?.toInt(),
      serverShift: server - now,
    );
  }

  /// Между обращениями к серверу досчитывает проценты услуги «в работе» по минутам.
  void tick() {
    if (stage == 'done' || services.isEmpty) return;
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000 + serverShift;
    var total = 0.0;
    var got = 0.0;
    for (final s in services) {
      total += s.normMinutes;
      if (s.state == 'done') {
        got += s.normMinutes;
      } else if (s.state == 'work' && s.startedAt != null) {
        final pauseNow = s.pausedAt != null ? (now - s.pausedAt!).clamp(0, 1 << 30).toInt() : 0;
        final minutes =
            ((now - s.startedAt! - s.pausedTotal - pauseNow) ~/ 60).clamp(0, 100000).toInt();
        s.percent = ((minutes / s.normMinutes) * 100).floor().clamp(0, 99).toInt();
        got += minutes < s.normMinutes * 0.99 ? minutes : s.normMinutes * 0.99;
      }
    }
    if (total > 0) percent = ((got / total) * 100).floor().clamp(0, 99).toInt();
  }
}

class RepairStatusScreen extends StatefulWidget {
  const RepairStatusScreen({super.key});

  @override
  State<RepairStatusScreen> createState() => _RepairStatusScreenState();
}

class _RepairStatusScreenState extends State<RepairStatusScreen>
    with WidgetsBindingObserver {
  final Map<String, RepairStatus> _status = {};
  Timer? _pull;
  Timer? _tick;
  bool _loadingStatus = false;
  bool? _wasLoggedIn;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
    _pull = Timer.periodic(const Duration(seconds: 30), (_) => _refreshStatus());
    _tick = Timer.periodic(const Duration(seconds: 15), (_) {
      if (!mounted) return;
      setState(() {
        for (final s in _status.values) {
          s.tick();
        }
      });
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pull?.cancel();
    _tick?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshStatus();
  }

  Future<void> _reload() async {
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    _wasLoggedIn = auth.isLoggedIn;
    if (!auth.isLoggedIn) return;
    await context.read<MyBookingsProvider>().load();
    await _refreshStatus();
  }

  /// Записи, по которым может идти ремонт: сегодняшние и вчерашние, кроме отменённых.
  List<BookingWithDetails> _current(MyBookingsProvider provider) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final from = today.subtract(const Duration(days: 3));
    final to = today.add(const Duration(days: 1));
    final all = [...provider.activeBookings, ...provider.archiveBookings];
    final list =
        all
            .where(
              (b) =>
                  b.status != 'cancelled' &&
                  !b.scheduledAt.isBefore(from) &&
                  b.scheduledAt.isBefore(to),
            )
            .toList()
          ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    return list;
  }

  /// Показываем ремонт, пока он идёт, и ещё 24 часа после того, как машина готова.
  /// Запись, по которой работу не начинали, видна 24 часа от времени записи.
  bool _visible(BookingWithDetails b) {
    final now = DateTime.now();
    final s = _status[b.id];
    if (s != null && s.found) {
      if (s.stage != 'done') return true;
      final doneAt = s.doneAt;
      if (doneAt == null) return true;
      final doneLocal = DateTime.fromMillisecondsSinceEpoch((doneAt - s.serverShift) * 1000);
      return now.difference(doneLocal) < const Duration(hours: 24);
    }
    return now.difference(b.scheduledAt) < const Duration(hours: 24);
  }

  BookingWithDetails? _next(MyBookingsProvider provider) {
    final now = DateTime.now();
    final list =
        provider.activeBookings.where((b) => b.scheduledAt.isAfter(now)).toList()
          ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    return list.isEmpty ? null : list.first;
  }

  Future<void> _refreshStatus() async {
    if (!mounted || _loadingStatus) return;
    final bookings = _current(context.read<MyBookingsProvider>());
    if (bookings.isEmpty) return;
    _loadingStatus = true;
    try {
      final results = await Future.wait(bookings.map(_fetch));
      if (!mounted) return;
      setState(() {
        for (var i = 0; i < bookings.length; i++) {
          final r = results[i];
          if (r != null) _status[bookings[i].id] = r..tick();
        }
      });
    } finally {
      _loadingStatus = false;
    }
  }

  Future<RepairStatus?> _fetch(BookingWithDetails booking) async {
    try {
      final uri = Uri.parse(
        kRepairStatusUrl,
      ).replace(queryParameters: {'json': '1', 'booking': booking.id});
      final res = await http.get(uri).timeout(const Duration(seconds: 12));
      if (res.statusCode != 200) return null;
      final data = jsonDecode(utf8.decode(res.bodyBytes));
      if (data is! Map || data['ok'] != true) return null;
      return RepairStatus.fromJson(Map<String, dynamic>.from(data));
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final auth = context.watch<AuthProvider>();

    if (_wasLoggedIn != null && _wasLoggedIn != auth.isLoggedIn) {
      _wasLoggedIn = auth.isLoggedIn;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _status.clear();
        _reload();
      });
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F1115) : const Color(0xFFF5F6F8),
      body: Column(
        children: [
          _Header(isDark: isDark),
          Expanded(
            child:
                auth.loading
                    ? const Center(child: CircularProgressIndicator())
                    : !auth.isLoggedIn
                    ? const _LoginView()
                    : Consumer<MyBookingsProvider>(
                      builder: (context, provider, _) {
                        final current = _current(provider).where(_visible).toList();
                        if (provider.loading && current.isEmpty) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        return RefreshIndicator(
                          color: BrandColors.orange,
                          onRefresh: _reload,
                          child: ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                            children: [
                              if (current.isEmpty)
                                _EmptyView(next: _next(provider))
                              else
                                for (final b in current) ...[
                                  _RepairCard(
                                    booking: b,
                                    status: _status[b.id],
                                  ),
                                  const SizedBox(height: 14),
                                ],
                              if (current.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    tr('Обновляется автоматически'),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                            ],
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

class _Header extends StatelessWidget {
  const _Header({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.of(context).padding.top + 14,
        20,
        16,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF15181D) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: .30),
          ),
        ),
      ),
      child: Row(
        children: [
          Material(
            color:
                isDark
                    ? Colors.white.withValues(alpha: .08)
                    : const Color(0xFFF2F3F5),
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                if (context.canPop()) {
                  context.pop();
                  return;
                }
                context.go('/');
              },
              child: const SizedBox(
                width: 46,
                height: 46,
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
                  tr('Статус ремонта'),
                  style: TextStyle(
                    fontSize: 26,
                    height: 1.05,
                    fontWeight: FontWeight.w900,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tr('На какой стадии ваш автомобиль'),
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.colorScheme.onSurfaceVariant,
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

class _RepairCard extends StatelessWidget {
  const _RepairCard({required this.booking, required this.status});

  final BookingWithDetails booking;
  final RepairStatus? status;

  static const _green = Color(0xFF22B573);
  static const _amber = Color(0xFFE0A800);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final s = status;
    final car = booking.car;
    final carTitle =
        (s != null && s.car.isNotEmpty)
            ? s.car
            : car == null
            ? tr('Ваш автомобиль')
            : [
              car.make,
              car.model,
              if (car.year != null) '${car.year}',
            ].where((e) => e.trim().isNotEmpty).join(' ');
    final plate =
        (s != null && s.plate.isNotEmpty) ? s.plate : (car?.licensePlate ?? '');
    final stage = s?.stage ?? 'waiting';
    final percent = s?.percent ?? 0;
    final done = stage == 'done';
    final services =
        (s != null && s.services.isNotEmpty)
            ? s.services
            : [
              RepairService(
                title: booking.service.title,
                state: 'waiting',
                percent: 0,
                normMinutes: booking.durationMinutes,
              ),
            ];
    final when = DateFormat('d MMMM, HH:mm', AgI18n.dateLocale).format(booking.scheduledAt);
    final stageText =
        s?.stageText ??
        (booking.scheduledAt.isAfter(DateTime.now())
            ? trf('Запись на {0}', [when])
            : tr('Ожидает начала работ'));
    final paused = !done && s?.paused != null;
    final accent = done ? _green : (paused ? _amber : BrandColors.orange);
    final master = s?.master ?? '';

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF181A1F) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color:
              stage == 'work'
                  ? accent.withValues(alpha: .45)
                  : theme.colorScheme.outlineVariant.withValues(alpha: .35),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? .25 : .05),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              SizedBox(
                width: 92,
                height: 92,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox.expand(
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(end: percent / 100),
                        duration: const Duration(milliseconds: 700),
                        curve: Curves.easeOutCubic,
                        builder:
                            (_, v, __) => CircularProgressIndicator(
                              value: v,
                              strokeWidth: 9,
                              strokeCap: StrokeCap.round,
                              backgroundColor:
                                  isDark
                                      ? Colors.white.withValues(alpha: .08)
                                      : const Color(0xFFF0F1F4),
                              valueColor: AlwaysStoppedAnimation(accent),
                            ),
                      ),
                    ),
                    Semantics(
                      label: trf('Готово {0} процентов', [percent]),
                      excludeSemantics: true,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '$percent',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: theme.colorScheme.onSurface,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                          Text(
                            '%',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      carTitle,
                      style: TextStyle(
                        fontSize: 19,
                        height: 1.15,
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    if (plate.isNotEmpty) ...[
                      const SizedBox(height: 7),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(7),
                          border: Border.all(color: const Color(0xFFD5D7DC)),
                        ),
                        child: Text(
                          plate,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            letterSpacing: .8,
                            color: Color(0xFF15171C),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 7),
                    Text(
                      when,
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (master.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text.rich(
                        TextSpan(
                          text: tr('Мастер: '),
                          children: [
                            TextSpan(
                              text: master,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color:
                  stage == 'waiting'
                      ? (isDark
                          ? Colors.white.withValues(alpha: .06)
                          : const Color(0xFFF2F3F5))
                      : accent.withValues(alpha: isDark ? .16 : .10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                _StageDot(stage: paused ? 'paused' : stage, color: accent),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    stageText,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color:
                          stage == 'waiting'
                              ? theme.colorScheme.onSurfaceVariant
                              : (done
                                  ? _green
                                  : paused
                                  ? (isDark
                                      ? const Color(0xFFFFD45C)
                                      : const Color(0xFF8A6500))
                                  : (isDark
                                      ? const Color(0xFFFFC29A)
                                      : const Color(0xFFC23D00))),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < services.length; i++) ...[
            _ServiceRow(index: i, service: services[i]),
            if (i < services.length - 1) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _StageDot extends StatefulWidget {
  const _StageDot({required this.stage, required this.color});
  final String stage;
  final Color color;

  @override
  State<_StageDot> createState() => _StageDotState();
}

class _StageDotState extends State<_StageDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(covariant _StageDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    final calm = WidgetsBinding
        .instance
        .platformDispatcher
        .accessibilityFeatures
        .disableAnimations;
    if (widget.stage == 'work' && !calm) {
      if (!_c.isAnimating) _c.repeat();
    } else {
      _c.stop();
      _c.value = 0;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color =
        widget.stage == 'waiting'
            ? Theme.of(context).colorScheme.onSurfaceVariant
            : widget.color;
    return AnimatedBuilder(
      animation: _c,
      builder:
          (_, __) => Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                if (widget.stage == 'work')
                  BoxShadow(
                    color: color.withValues(alpha: .45 * (1 - _c.value)),
                    blurRadius: 0,
                    spreadRadius: 8 * _c.value,
                  ),
              ],
            ),
          ),
    );
  }
}

class _ServiceRow extends StatelessWidget {
  const _ServiceRow({required this.index, required this.service});

  final int index;
  final RepairService service;

  static const _green = Color(0xFF22B573);
  static const _amber = Color(0xFFE0A800);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final work = service.state == 'work';
    final done = service.state == 'done';
    final paused = work && service.paused != null;
    final tone = paused ? _amber : BrandColors.orange;
    final label =
        done
            ? tr('Завершена')
            : (paused
                ? (service.paused == 'parts' ? tr('Мастер ждёт запчасть') : tr('Пауза'))
                : (work ? tr('В работе') : tr('Ожидает')));
    final labelColor =
        done
            ? _green
            : paused
            ? (isDark ? const Color(0xFFFFD45C) : const Color(0xFF8A6500))
            : (work
                ? (isDark ? const Color(0xFFFFB98A) : const Color(0xFFC23D00))
                : theme.colorScheme.onSurfaceVariant);

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
      decoration: BoxDecoration(
        color:
            work
                ? tone.withValues(alpha: isDark ? .10 : .06)
                : (isDark
                    ? Colors.white.withValues(alpha: .04)
                    : const Color(0xFFF7F8FA)),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              work
                  ? tone.withValues(alpha: .35)
                  : Colors.transparent,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      done
                          ? _green.withValues(alpha: .15)
                          : (work
                              ? tone
                              : (isDark
                                  ? Colors.white.withValues(alpha: .08)
                                  : const Color(0xFFE9EBEF))),
                ),
                child:
                    done
                        ? const Icon(Icons.check_rounded, size: 19, color: _green)
                        : Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color:
                                work
                                    ? Colors.white
                                    : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      label,
                      style: TextStyle(fontSize: 13, color: labelColor),
                    ),
                  ],
                ),
              ),
              if (!(service.state == 'waiting'))
                Text(
                  '${service.percent}%',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: done ? _green : tone,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
            ],
          ),
          if (work) ...[
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(left: 44),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(end: service.percent / 100),
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.easeOutCubic,
                  builder:
                      (_, v, __) => LinearProgressIndicator(
                        value: v,
                        minHeight: 6,
                        backgroundColor:
                            isDark
                                ? Colors.white.withValues(alpha: .08)
                                : const Color(0xFFE9EBEF),
                        valueColor: AlwaysStoppedAnimation(tone),
                      ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.next});
  final BookingWithDetails? next;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 48, 16, 0),
      child: Column(
        children: [
          AgIcon(
            AgIcons.wrench,
            size: 56,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            tr('Сейчас ваш автомобиль не в ремонте'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            next == null
                ? tr('Когда мастер начнёт работу по вашей записи, здесь будет видно, на какой она стадии.')
                : trf('Ближайшая запись: {0} — {1}.', [DateFormat('d MMMM, HH:mm', AgI18n.dateLocale).format(next!.scheduledAt), next!.service.title]),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.go('/bookings'),
            child: Text(tr('Мои записи')),
          ),
        ],
      ),
    );
  }
}

class _LoginView extends StatelessWidget {
  const _LoginView();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AgIcon(AgIcons.wrench, size: 56, color: color),
            const SizedBox(height: 16),
            Text(
              tr('Войдите, чтобы видеть статус ремонта'),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: color),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.push('/login'),
              child: Text(tr('Войти')),
            ),
          ],
        ),
      ),
    );
  }
}
