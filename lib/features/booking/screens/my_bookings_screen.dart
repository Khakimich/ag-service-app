// AG_BOOKUI1 + AG_RATE2 — «Мои записи»: новый вид, светлая и тёмная тема, адаптивная сетка, SVG-иконки.
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/ag_icon3d.dart';
import '../../../core/ag_extras.dart'; // AG_RATE2
import '../../../core/ag_icons.dart';
import '../../../core/ag_intake.dart'; // AG_INTAKE1
import '../../../core/api_client.dart';
import '../../../core/theme.dart';
import '../../../models/booking_with_details.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/booking_flow_provider.dart';
import '../providers/my_bookings_provider.dart';
import '../../chat/data/chat_repository.dart';
import '../../../core/i18n.dart'; // AG_I18N1

/// Иконки экрана записей — тот же стиль, что [AgIcons] (линия 24×24).
class _BkIc {
  static const back = '<path d="M15 5l-7 7 7 7"/>';
  static const clock = '<circle cx="12" cy="12" r="8.5"/><path d="M12 7.5V12l3 2"/>';
  static const check = '<circle cx="12" cy="12" r="8.5"/><path d="M8.5 12.3l2.4 2.4 4.8-5"/>';
  static const wrench =
      '<path d="M15 4.5a4.5 4.5 0 0 0-4.3 5.9l-6.1 6.1a2 2 0 1 0 2.9 2.9l6.1-6.1A4.5 4.5 0 0 0 19.5 9l-2.7 2.7-2.5-.6-.6-2.5L16.4 6"/>';
  static const flag = '<path d="M5 21V4.5"/><path d="M5 5h11.5l-2 4 2 4H5"/>';
  static const cross = '<circle cx="12" cy="12" r="8.5"/><path d="M9.2 9.2l5.6 5.6M14.8 9.2l-5.6 5.6"/>';
  static const user = '<circle cx="12" cy="8.5" r="3.5"/><path d="M5 20a7 7 0 0 1 14 0"/>';
  static const car =
      '<path d="M4 16.5V13l1.8-4.3A2 2 0 0 1 7.6 7.5h8.8a2 2 0 0 1 1.8 1.2L20 13v3.5a1 1 0 0 1-1 1h-1"/><path d="M6 17.5H5a1 1 0 0 1-1-1"/><path d="M4.5 13h15"/><circle cx="8" cy="17.5" r="1.8"/><circle cx="16" cy="17.5" r="1.8"/><path d="M9.8 17.5h4.4"/>';
  static const ruble = '<path d="M8 20V4.5h5.2a4 4 0 0 1 0 8H6M6 16h8"/>';
  static const resched = '<rect x="4" y="5.5" width="16" height="14.5" rx="2.5"/><path d="M4 10h16M8.5 3.5v4M15.5 3.5v4"/><path d="M14.5 13.2l1.8 1.8-1.8 1.8M8 15h8.2"/>';
  static const chat = '<path d="M5 5h14a1 1 0 0 1 1 1v9a1 1 0 0 1-1 1h-7l-5 4v-4H5a1 1 0 0 1-1-1V6a1 1 0 0 1 1-1z"/><path d="M8.5 9.5h7M8.5 12.5h4.5"/>';
  static const repeat = '<path d="M17 4.5l2.5 2.5L17 9.5"/><path d="M4.5 12V11a4 4 0 0 1 4-4h11"/><path d="M7 19.5L4.5 17 7 14.5"/><path d="M19.5 12v1a4 4 0 0 1-4 4h-11"/>';
  static const trash = '<path d="M4.5 7h15M10 4h4M6.5 7l1 12a1.5 1.5 0 0 0 1.5 1.4h6a1.5 1.5 0 0 0 1.5-1.4l1-12"/><path d="M10 11v5.5M14 11v5.5"/>';
  static const plus = '<path d="M12 5v14M5 12h14"/>';
}

/// Цвета экрана в светлой и тёмной теме.
class _BkPal {
  _BkPal(BuildContext c) : dark = Theme.of(c).brightness == Brightness.dark;
  final bool dark;
  Color get bg => dark ? const Color(0xFF0E1014) : const Color(0xFFF4F5F8);
  Color get head => dark ? const Color(0xFF14171C) : Colors.white;
  Color get card => dark ? const Color(0xFF181B21) : Colors.white;
  Color get line => dark ? Colors.white.withValues(alpha: .07) : const Color(0xFFE9EBF0);
  Color get soft => dark ? Colors.white.withValues(alpha: .06) : const Color(0xFFF3F4F7);
  Color get ink => dark ? const Color(0xFFF3F4F6) : const Color(0xFF15171C);
  Color get mut => dark ? const Color(0xFF9EA4AE) : const Color(0xFF6B7280);
  Color get shadow => Colors.black.withValues(alpha: dark ? .28 : .06);
}

class _BkStatus {
  const _BkStatus(this.color, this.icon);
  final Color color;
  final String icon;

  static _BkStatus of(String status) {
    switch (status) {
      case 'pending':
        return const _BkStatus(Color(0xFFFF6A00), _BkIc.clock);
      case 'confirmed':
        return const _BkStatus(Color(0xFF16A34A), _BkIc.check);
      case 'in_progress':
        return const _BkStatus(Color(0xFF2F6BFF), _BkIc.wrench);
      case 'completed':
        return const _BkStatus(Color(0xFF64748B), _BkIc.flag);
      case 'cancelled':
        return const _BkStatus(Color(0xFFE5484D), _BkIc.cross);
      default:
        return const _BkStatus(Color(0xFF64748B), _BkIc.clock);
    }
  }
}

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  bool? _wasLoggedIn;
  Map<String, int> _myRatings = const {}; // AG_RATE2: мои оценки по записям

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final isLoggedIn = context.read<AuthProvider>().isLoggedIn;
      _wasLoggedIn = isLoggedIn;
      if (isLoggedIn) {
        context.read<MyBookingsProvider>().load();
        _loadMyRatings();
      }
    });
  }

  Future<void> _loadMyRatings() async {
    final r = await AgMyReviews.load(context.read<ApiClient>());
    if (mounted) setState(() => _myRatings = r);
  }

  Future<void> _rate(BuildContext context, BookingWithDetails b) async {
    final ok = await AgReviewPrompt.showFor(context, {
      'id': b.id,
      'service': {'title': b.service.title},
      'specialist': {'full_name': b.specialist.fullName, 'photo_url': b.specialist.photoUrl},
    });
    if (ok) _loadMyRatings();
  }

  Future<void> _confirmCancel(
    BuildContext context,
    MyBookingsProvider provider,
    String id,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (dialogCtx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
            title: Text(tr('Отменить запись?')),
            content: Text(tr('Это действие нельзя отменить.')),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx, false),
                child: Text(tr('Нет')),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx, true),
                style: TextButton.styleFrom(foregroundColor: const Color(0xFFE5484D)),
                child: Text(tr('Да, отменить')),
              ),
            ],
          ),
    );
    if (confirmed != true || !context.mounted) return;
    final ok = await provider.cancel(id);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('Не удалось отменить запись'))),
      );
    }
  }

  void _repeatBooking(BuildContext context, BookingWithDetails booking) {
    context.read<BookingFlowProvider>().reset();
    context.read<BookingFlowProvider>().selectService(booking.service);
    context.push('/booking/specialist');
  }

  Future<void> _openChat(BuildContext context, BookingWithDetails booking) async {
    try {
      final conv = await context
          .read<ChatRepository>()
          .getOrCreateDepartmentConversation('autogrom_service');
      if (!context.mounted) return;
      context.push('/chats/${conv.id}', extra: conv);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  void _newBooking(BuildContext context) {
    if (!context.read<AuthProvider>().isLoggedIn) {
      context.push('/login');
      return;
    }
    context.push('/services');
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final p = _BkPal(context);

    if (_wasLoggedIn != null && _wasLoggedIn != auth.isLoggedIn) {
      _wasLoggedIn = auth.isLoggedIn;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (auth.isLoggedIn) {
          context.read<MyBookingsProvider>().load();
        } else {
          context.read<MyBookingsProvider>().clear();
        }
      });
    }

    if (auth.loading) {
      return Scaffold(backgroundColor: p.bg, body: const Center(child: CircularProgressIndicator()));
    }

    if (!auth.isLoggedIn) {
      return Scaffold(
        backgroundColor: p.bg,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const AgIcon3D('calendar', size: 96),
                    const SizedBox(height: 18),
                    Text(tr('Ваши записи в сервис'),
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: p.ink)),
                    const SizedBox(height: 8),
                    Text(tr('Войдите, чтобы видеть, переносить и отменять свои записи'),
                        textAlign: TextAlign.center, style: TextStyle(fontSize: 14.5, height: 1.4, color: p.mut)),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: BrandColors.orange,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: () => context.push('/login'),
                        child: Text(tr('Войти'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: p.ink,
                          side: BorderSide(color: p.line),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: () => context.push('/register'),
                        child: Text(tr('Зарегистрироваться'), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: p.bg,
        body: Consumer<MyBookingsProvider>(
          builder: (context, provider, _) {
            final active = provider.activeBookings;
            final archive = provider.archiveBookings;
            Widget body;
            if (provider.loading && active.isEmpty && archive.isEmpty) {
              body = const Center(child: CircularProgressIndicator());
            } else if (provider.error != null && active.isEmpty && archive.isEmpty) {
              body = _ErrorView(message: provider.error!, onRetry: provider.load);
            } else {
              body = TabBarView(
                children: [
                  _BookingListView(
                    bookings: active,
                    archive: false,
                    onRefresh: () async {
                      await provider.load();
                      await _loadMyRatings();
                    },
                    onCancel: (id) => _confirmCancel(context, provider, id),
                    onRepeat: (b) => _repeatBooking(context, b),
                    onContact: (b) => _openChat(context, b),
                    onReschedule: (b) => context.push('/booking/reschedule', extra: b),
                    onNew: () => _newBooking(context),
                  ),
                  _BookingListView(
                    bookings: archive,
                    archive: true,
                    onRefresh: () async {
                      await provider.load();
                      await _loadMyRatings();
                    },
                    onCancel: null,
                    onRepeat: (b) => _repeatBooking(context, b),
                    onContact: (b) => _openChat(context, b),
                    onReschedule: null,
                    onNew: () => _newBooking(context),
                    myRatings: _myRatings,
                    onRate: (b) => _rate(context, b),
                  ),
                ],
              );
            }
            return Column(
              children: [
                _Header(activeCount: active.length, archiveCount: archive.length),
                Expanded(child: body),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.activeCount, required this.archiveCount});
  final int activeCount;
  final int archiveCount;

  String _plural(int n, String one, String few, String many) {
    final m10 = n % 10, m100 = n % 100;
    if (m10 == 1 && m100 != 11) return one;
    if (m10 >= 2 && m10 <= 4 && (m100 < 12 || m100 > 14)) return few;
    return many;
  }

  @override
  Widget build(BuildContext context) {
    final p = _BkPal(context);
    final sub = activeCount == 0
        ? tr('Нет предстоящих визитов')
        : '$activeCount ${_plural(activeCount, 'предстоящий визит', 'предстоящих визита', 'предстоящих визитов')}';
    Widget tab(String text, int count) => Tab(
          height: 42,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(text),
              if (count > 0) ...[
                const SizedBox(width: 7),
                Builder(builder: (c) {
                  final selected = DefaultTextStyle.of(c).style.color == Colors.white;
                  return Container(
                    constraints: const BoxConstraints(minWidth: 22),
                    height: 22,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected ? Colors.white.withValues(alpha: .25) : BrandColors.orange.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Text('$count',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w800, color: selected ? Colors.white : BrandColors.orange)),
                  );
                }),
              ],
            ],
          ),
        );

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: p.head,
        border: Border(bottom: BorderSide(color: p.line)),
      ),
      child: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1180),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Material(
                        color: p.soft,
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () {
                            if (context.canPop()) {
                              context.pop();
                            } else {
                              context.go('/');
                            }
                          },
                          child: SizedBox(
                            width: 44,
                            height: 44,
                            child: Center(child: AgIcon(_BkIc.back, size: 22, color: p.ink, strokeWidth: 2.2)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(tr('Мои записи'),
                                style: TextStyle(fontSize: 24, height: 1.1, fontWeight: FontWeight.w900, letterSpacing: -.4, color: p.ink)),
                            const SizedBox(height: 3),
                            Text(sub, style: TextStyle(fontSize: 13.5, color: p.mut)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: p.soft, borderRadius: BorderRadius.circular(16)),
                    child: TabBar(
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      labelColor: Colors.white,
                      unselectedLabelColor: p.mut,
                      labelStyle: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800),
                      unselectedLabelStyle: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
                      splashBorderRadius: BorderRadius.circular(13),
                      indicator: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFFFF8A2B), Color(0xFFFF5F00)]),
                        borderRadius: BorderRadius.circular(13),
                        boxShadow: [BoxShadow(color: BrandColors.orange.withValues(alpha: .30), blurRadius: 12, offset: const Offset(0, 4))],
                      ),
                      tabs: [tab(tr('Активные'), activeCount), tab(tr('Архив'), archiveCount)],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BookingListView extends StatelessWidget {
  const _BookingListView({
    required this.bookings,
    required this.archive,
    required this.onRefresh,
    required this.onCancel,
    required this.onRepeat,
    required this.onContact,
    required this.onReschedule,
    required this.onNew,
    this.myRatings = const {},
    this.onRate,
  });

  final Map<String, int> myRatings;
  final void Function(BookingWithDetails)? onRate;
  final List<BookingWithDetails> bookings;
  final bool archive;
  final Future<void> Function() onRefresh;
  final void Function(String id)? onCancel;
  final void Function(BookingWithDetails) onRepeat;
  final void Function(BookingWithDetails) onContact;
  final void Function(BookingWithDetails)? onReschedule;
  final VoidCallback onNew;

  @override
  Widget build(BuildContext context) {
    final p = _BkPal(context);
    if (bookings.isEmpty) {
      return RefreshIndicator(
        color: BrandColors.orange,
        onRefresh: onRefresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 24, 28, 120),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 380),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Opacity(opacity: archive ? .55 : 1, child: const AgIcon3D('calendar', size: 92)),
                        const SizedBox(height: 18),
                        Text(archive ? tr('Архив пуст') : tr('Нет предстоящих записей'),
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: p.ink)),
                        const SizedBox(height: 8),
                        Text(
                          archive
                              ? tr('Здесь появятся завершённые и отменённые визиты')
                              : tr('Запишитесь на удобное время — мастер будет ждать вас'),
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14, height: 1.4, color: p.mut),
                        ),
                        if (!archive) ...[
                          const SizedBox(height: 22),
                          SizedBox(
                            height: 50,
                            child: FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: BrandColors.orange,
                                padding: const EdgeInsets.symmetric(horizontal: 26),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              onPressed: onNew,
                              icon: const AgIcon(_BkIc.plus, size: 20, color: Colors.white, strokeWidth: 2.4),
                              label: Text(tr('Записаться'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, box) {
        final w = box.maxWidth;
        final cols = w >= 1100 ? 3 : (w >= 720 ? 2 : 1);
        const gap = 14.0;
        final side = w >= 720 ? 24.0 : 14.0;
        final double usable = (w > 1180 ? 1180.0 : w) - side * 2;
        final cardW = (usable - gap * (cols - 1)) / cols;
        return RefreshIndicator(
          color: BrandColors.orange,
          onRefresh: onRefresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(side, 16, side, 130),
            child: Center(
              child: SizedBox(
                width: usable,
                child: Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: [
                    for (final b in bookings)
                      SizedBox(
                        width: cardW,
                        child: _BookingCard(
                          booking: b,
                          archive: archive,
                          onCancel: onCancel != null && (b.status == 'pending' || b.status == 'confirmed')
                              ? () => onCancel!(b.id)
                              : null,
                          onReschedule: onReschedule != null && (b.status == 'pending' || b.status == 'confirmed')
                              ? () => onReschedule!(b)
                              : null,
                          onRepeat: () => onRepeat(b),
                          onContact: () => onContact(b),
                          myRating: myRatings[b.id],
                          onRate: onRate != null && b.status == 'completed' ? () => onRate!(b) : null,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({
    required this.booking,
    required this.archive,
    required this.onCancel,
    required this.onRepeat,
    required this.onContact,
    required this.onReschedule,
    this.myRating,
    this.onRate,
  });

  final int? myRating;
  final VoidCallback? onRate;
  final BookingWithDetails booking;
  final bool archive;
  final VoidCallback? onCancel;
  final VoidCallback onRepeat;
  final VoidCallback onContact;
  final VoidCallback? onReschedule;

  String _duration(int minutes) {
    if (minutes < 60) return trf('{0} мин', [minutes]);
    final h = minutes ~/ 60, m = minutes % 60;
    return m == 0 ? trf('{0} ч', [h]) : trf('{0} ч {1} мин', [h, m]);
  }

  String? _when(DateTime at) {
    final now = DateTime.now();
    final d0 = DateTime(now.year, now.month, now.day);
    final d1 = DateTime(at.year, at.month, at.day);
    final days = d1.difference(d0).inDays;
    if (days < 0) return null;
    if (days == 0) {
      final mins = at.difference(now).inMinutes;
      if (mins <= 0) return tr('Сегодня');
      if (mins < 60) return trf('Через {0} мин', [mins]);
      return trf('Сегодня, через {0} ч', [mins ~/ 60]);
    }
    if (days == 1) return tr('Завтра');
    if (days < 7) return trf('Через {0} дн.', [days]);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final p = _BkPal(context);
    final st = _BkStatus.of(booking.status);
    final at = booking.scheduledAt;
    final end = at.add(Duration(minutes: booking.durationMinutes));
    final upcoming = !archive && booking.isActive;
    final when = upcoming ? _when(at) : null;
    final spec = booking.specialist;
    final photo = spec.photoUrl ?? '';
    final specText = (spec.specialization ?? '').trim();
    final car = booking.car;
    final carText = car == null
        ? null
        : [
            car.displayName,
            if ((car.licensePlate ?? '').trim().isNotEmpty) car.licensePlate!.toUpperCase(),
          ].join(' · ');

    return Container(
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: p.line),
        boxShadow: [BoxShadow(color: p.shadow, blurRadius: 24, offset: const Offset(0, 10))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Верх: дата-плашка, услуга, статус
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DateTile(at: at, active: upcoming),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _StatusChip(label: booking.statusLabel, status: st),
                          if (when != null) ...[
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(when,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: BrandColors.orange)),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 7),
                      Text(booking.service.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 17, height: 1.22, fontWeight: FontWeight.w800, letterSpacing: -.2, color: p.ink,
                              decoration: booking.status == 'cancelled' ? TextDecoration.lineThrough : null,
                              decorationColor: p.mut)),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          AgIcon(_BkIc.clock, size: 15, color: p.mut, strokeWidth: 2),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              '${DateFormat('HH:mm').format(at)} – ${DateFormat('HH:mm').format(end)} · ${_duration(booking.durationMinutes)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: p.mut),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Детали
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            decoration: BoxDecoration(color: p.soft, borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                Row(
                  children: [
                    _Avatar(url: photo, name: spec.fullName),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(spec.fullName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: p.ink)),
                          Text(specText.isNotEmpty ? specText : tr('Мастер'),
                              maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.5, color: p.mut)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(10)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AgIcon(_BkIc.ruble, size: 14, color: BrandColors.orange, strokeWidth: 2.2),
                          const SizedBox(width: 4),
                          Text(booking.service.priceLabel.replaceAll('₽', '').trim(),
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: p.ink)),
                        ],
                      ),
                    ),
                  ],
                ),
                if (carText != null) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    child: Divider(height: 1, color: p.line),
                  ),
                  Row(
                    children: [
                      SizedBox(
                        width: 36,
                        child: Center(child: AgIcon(_BkIc.car, size: 21, color: p.mut, strokeWidth: 1.9)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(carText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: p.ink)),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          // AG_RATE2: оценка мастера по завершённой записи
          if (onRate != null && myRating != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: onRate,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Text(tr('Ваша оценка'), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: p.mut)),
                      const SizedBox(width: 8),
                      for (var i = 0; i < 5; i++)
                        Padding(padding: const EdgeInsets.only(right: 2), child: AgStar(fill: i < myRating! ? 1 : 0, size: 17)),
                      const Spacer(),
                      Text(tr('Изменить'), style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: BrandColors.orange)),
                    ],
                  ),
                ),
              ),
            ),
          AgIntakeStrip(bookingId: booking.id), // AG_INTAKE1
          // Действия
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            child: Row(
              children: [
                if (onRate != null && myRating == null) ...[
                  Expanded(
                    child: Material(
                      borderRadius: BorderRadius.circular(14),
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFFFFB400), Color(0xFFFF6A00)]),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: onRate,
                          child: SizedBox(
                            height: 46,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                AgStar(fill: 1, size: 19),
                                SizedBox(width: 7),
                                Flexible(
                                  child: Text(tr('Оценить мастера'),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _IconAction(icon: _BkIc.repeat, tooltip: tr('Записаться снова'), onTap: onRepeat),
                  const SizedBox(width: 8),
                ] else if (onReschedule != null) ...[
                  Expanded(
                    child: _ActionButton(
                      icon: _BkIc.resched,
                      label: tr('Перенести'),
                      filled: true,
                      onTap: onReschedule!,
                    ),
                  ),
                  const SizedBox(width: 8),
                ] else ...[
                  Expanded(
                    child: _ActionButton(
                      icon: _BkIc.repeat,
                      label: tr('Записаться снова'),
                      filled: true,
                      onTap: onRepeat,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                if (onCancel != null) ...[
                  Expanded(
                    child: _ActionButton(
                      icon: _BkIc.cross,
                      label: tr('Отменить'),
                      color: const Color(0xFFE5484D),
                      onTap: onCancel!,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                _IconAction(icon: _BkIc.chat, tooltip: tr('Связаться с сервисом'), onTap: onContact),
                if (onReschedule != null) ...[
                  const SizedBox(width: 8),
                  _IconAction(icon: _BkIc.repeat, tooltip: tr('Повторить запись'), onTap: onRepeat),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DateTile extends StatelessWidget {
  const _DateTile({required this.at, required this.active});
  final DateTime at;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final p = _BkPal(context);
    final month = DateFormat('MMM', AgI18n.dateLocale).format(at).replaceAll('.', '');
    final wd = DateFormat('EE', AgI18n.dateLocale).format(at);
    final fg = active ? Colors.white : p.ink;
    return Container(
      width: 58,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        gradient: active
            ? const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFFF9A45), Color(0xFFFF5F00)])
            : null,
        color: active ? null : p.soft,
        borderRadius: BorderRadius.circular(16),
        boxShadow: active
            ? [BoxShadow(color: BrandColors.orange.withValues(alpha: .28), blurRadius: 14, offset: const Offset(0, 6))]
            : null,
      ),
      child: Column(
        children: [
          Text(month.toUpperCase(),
              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: .6, color: fg.withValues(alpha: .85))),
          Text('${at.day}', style: TextStyle(fontSize: 24, height: 1.1, fontWeight: FontWeight.w900, color: fg)),
          Text(wd, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: fg.withValues(alpha: .8))),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.status});
  final String label;
  final _BkStatus status;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 3, 9, 3),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: dark ? .18 : .11),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AgIcon(status.icon, size: 14, color: status.color, strokeWidth: 2.3),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: status.color)),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.url, required this.name});
  final String url;
  final String name;

  @override
  Widget build(BuildContext context) {
    final letters = name.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty).take(2).map((s) => s[0]).join().toUpperCase();
    final fallback = Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(colors: [Color(0xFFFFB067), Color(0xFFFF6A00)]),
      ),
      child: letters.isEmpty
          ? const AgIcon(_BkIc.user, size: 18, color: Colors.white, strokeWidth: 2)
          : Text(letters, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800)),
    );
    if (url.isEmpty) return fallback;
    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: url,
        width: 36,
        height: 36,
        fit: BoxFit.cover,
        placeholder: (_, __) => fallback,
        errorWidget: (_, __, ___) => fallback,
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.filled = false,
    this.color,
  });
  final String icon;
  final String label;
  final VoidCallback onTap;
  final bool filled;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final p = _BkPal(context);
    final c = color ?? BrandColors.orange;
    final fg = filled ? Colors.white : c;
    return Material(
      color: filled ? c : c.withValues(alpha: p.dark ? .16 : .09),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: SizedBox(
          height: 46,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AgIcon(icon, size: 18, color: fg, strokeWidth: 2.1),
              const SizedBox(width: 7),
              Flexible(
                child: Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: fg)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconAction extends StatelessWidget {
  const _IconAction({required this.icon, required this.tooltip, required this.onTap});
  final String icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = _BkPal(context);
    return Tooltip(
      message: tooltip,
      child: Material(
        color: p.soft,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: SizedBox(
            width: 46,
            height: 46,
            child: Center(child: AgIcon(icon, size: 21, color: p.ink, strokeWidth: 1.9)),
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
    final p = _BkPal(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 24, 28, 120),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AgIcon(_BkIc.cross, size: 52, color: Color(0xFFE5484D), strokeWidth: 1.6),
            const SizedBox(height: 14),
            Text(tr('Не удалось загрузить записи'),
                textAlign: TextAlign.center, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: p.ink)),
            const SizedBox(height: 6),
            Text(message, textAlign: TextAlign.center, style: TextStyle(fontSize: 13.5, color: p.mut)),
            const SizedBox(height: 18),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: BrandColors.orange,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: onRetry,
              child: Text(tr('Повторить')),
            ),
          ],
        ),
      ),
    );
  }
}
