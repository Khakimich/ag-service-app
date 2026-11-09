// AG_SPECUI1 — выбор мастера: рейтинг по 5-балльной шкале, светлая/тёмная тема, адаптивная сетка.
import 'package:mobile/core/nav.dart'; // AG_FIX3
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/ag_extras.dart';
import '../../../core/ag_icons.dart';
import '../../../core/api_client.dart';
import '../../../models/specialist.dart';
import '../data/booking_repository.dart';
import '../providers/booking_flow_provider.dart';
import '../../../core/i18n.dart'; // AG_I18N1

class SpecialistSelectionScreen extends StatefulWidget {
  const SpecialistSelectionScreen({super.key});

  @override
  State<SpecialistSelectionScreen> createState() => _SpecialistSelectionScreenState();
}

class _SpecialistSelectionScreenState extends State<SpecialistSelectionScreen> {
  late Future<ServiceDetail> _future;
  Map<String, AgRating> _ratings = const {};

  @override
  void initState() {
    super.initState();
    final service = context.read<BookingFlowProvider>().service;
    _future = context.read<BookingRepository>().serviceDetail(service!.id);
    AgRatings.load(context.read<ApiClient>()).then((r) {
      if (mounted) setState(() => _ratings = r);
    });
  }

  void _choose(Specialist sp) {
    context.read<BookingFlowProvider>().selectSpecialist(sp);
    context.push('/booking/datetime');
  }

  void _showReviews(Specialist sp) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ReviewsSheet(api: context.read<ApiClient>(), specialist: sp, rating: _ratings[sp.id], onChoose: () {
        Navigator.pop(context);
        _choose(sp);
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final bg = dark ? const Color(0xFF0E1014) : const Color(0xFFF4F5F8);
    final ink = dark ? const Color(0xFFF3F4F6) : const Color(0xFF15171C);
    final mut = dark ? const Color(0xFF9EA4AE) : const Color(0xFF6B7280);
    final service = context.watch<BookingFlowProvider>().service;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        surfaceTintColor: Colors.transparent,
        leading: const AgBackButton(fallback: '/'), // AG_FIX3
        title: Text(tr('Выберите мастера'), style: TextStyle(fontWeight: FontWeight.w800, color: ink)),
      ),
      body: FutureBuilder<ServiceDetail>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(snapshot.error.toString(), textAlign: TextAlign.center)));
          }
          final list = [...snapshot.data!.specialists];
          // сначала мастера с лучшим рейтингом
          list.sort((a, b) {
            final ra = _ratings[a.id], rb = _ratings[b.id];
            final sa = ra == null ? 0.0 : ra.avg + (ra.count >= 3 ? .01 : 0);
            final sb = rb == null ? 0.0 : rb.avg + (rb.count >= 3 ? .01 : 0);
            return sb.compareTo(sa);
          });
          if (list.isEmpty) {
            return Center(child: Text(tr('Нет свободных мастеров для этой услуги'), style: TextStyle(color: mut, fontSize: 15)));
          }
          return LayoutBuilder(builder: (context, box) {
            final w = box.maxWidth;
            final cols = w >= 1000 ? 3 : (w >= 640 ? 2 : 1);
            final side = w >= 640 ? 24.0 : 14.0;
            final double usable = (w > 1100 ? 1100.0 : w) - side * 2;
            final double cardW = (usable - 12 * (cols - 1)) / cols;
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(side, 4, side, 40),
              child: Center(
                child: SizedBox(
                  width: usable,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (service != null)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(2, 0, 2, 14),
                          child: Text(trf('Услуга: {0}', [service.title]),
                              maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14, color: mut, fontWeight: FontWeight.w600)),
                        ),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          for (var i = 0; i < list.length; i++)
                            SizedBox(
                              width: cardW,
                              child: _MasterCard(
                                sp: list[i],
                                rating: _ratings[list[i].id],
                                best: i == 0 && (_ratings[list[i].id]?.count ?? 0) >= 3,
                                onTap: () => _choose(list[i]),
                                onReviews: () => _showReviews(list[i]),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          });
        },
      ),
    );
  }
}

class _MasterCard extends StatelessWidget {
  const _MasterCard({required this.sp, required this.rating, required this.best, required this.onTap, required this.onReviews});
  final Specialist sp;
  final AgRating? rating;
  final bool best;
  final VoidCallback onTap;
  final VoidCallback onReviews;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final card = dark ? const Color(0xFF181B21) : Colors.white;
    final line = dark ? Colors.white.withValues(alpha: .07) : const Color(0xFFE9EBF0);
    final ink = dark ? const Color(0xFFF3F4F6) : const Color(0xFF15171C);
    final mut = dark ? const Color(0xFF9EA4AE) : const Color(0xFF6B7280);
    final soft = dark ? Colors.white.withValues(alpha: .06) : const Color(0xFFF3F4F7);
    final photo = sp.photoUrl ?? '';
    final spec = (sp.specialization ?? '').trim();
    final initials = sp.fullName.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty).take(2).map((s) => s[0]).join().toUpperCase();

    return Material(
      color: card,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: best ? const Color(0xFFFF6A00).withValues(alpha: .55) : line),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: dark ? .25 : .05), blurRadius: 20, offset: const Offset(0, 8))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: SizedBox(
                          width: 72,
                          height: 72,
                          child: photo.isEmpty
                              ? _initials(initials)
                              : CachedNetworkImage(
                                  imageUrl: photo,
                                  fit: BoxFit.cover,
                                  placeholder: (_, __) => _initials(initials),
                                  errorWidget: (_, __, ___) => _initials(initials),
                                ),
                        ),
                      ),
                      if (best)
                        Positioned(
                          left: -4,
                          top: -6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [Color(0xFFFFB400), Color(0xFFFF6A00)]),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(tr('ТОП'), style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900)),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(sp.fullName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 17, height: 1.2, fontWeight: FontWeight.w800, color: ink)),
                        const SizedBox(height: 3),
                        Text(spec.isEmpty ? tr('Мастер AG Service') : spec,
                            maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13.5, color: mut)),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: (rating?.count ?? 0) > 0 ? onReviews : null,
                          child: AgRatingRow(rating: rating, size: 15),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  if ((rating?.count ?? 0) > 0) ...[
                    Material(
                      color: soft,
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: onReviews,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          child: Text(tr('Отзывы'), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: ink)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Container(
                      height: 46,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFFFF8A2B), Color(0xFFFF5F00)]),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(tr('Выбрать время'), style: TextStyle(color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.w800)),
                          SizedBox(width: 6),
                          AgIcon(AgIcons.arrowRight, size: 18, color: Colors.white, strokeWidth: 2.3),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _initials(String t) => Container(
        alignment: Alignment.center,
        decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFFFFB067), Color(0xFFFF6A00)])),
        child: Text(t.isEmpty ? tr('М') : t, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
      );
}

class _ReviewsSheet extends StatelessWidget {
  const _ReviewsSheet({required this.api, required this.specialist, required this.rating, required this.onChoose});
  final ApiClient api;
  final Specialist specialist;
  final AgRating? rating;
  final VoidCallback onChoose;

  static Map<String, String> get _tagNames => {
    'quality': tr('Качество'),
    'speed': tr('Быстро'),
    'polite': tr('Вежливо'),
    'explained': tr('Всё объяснил'),
    'clean': tr('Чистота'),
    'price': tr('Честная цена'),
    // AG_RATE3: замечания
    'bad_quality': tr('Плохое качество'),
    'slow': tr('Долго'),
    'late': tr('Задержали по времени'),
    'rude': tr('Невежливо'),
    'not_explained': tr('Не объяснили'),
    'expensive': tr('Дорого'),
    'dirty': tr('Грязно в машине'),
    'redo': tr('Пришлось переделывать'),
  };

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final bg = dark ? const Color(0xFF181B21) : Colors.white;
    final ink = dark ? const Color(0xFFF3F4F6) : const Color(0xFF15171C);
    final mut = dark ? const Color(0xFF9EA4AE) : const Color(0xFF6B7280);
    final soft = dark ? Colors.white.withValues(alpha: .06) : const Color(0xFFF3F4F7);
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * .8),
      margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(26)),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: soft, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 14),
            Text(specialist.fullName, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: ink)),
            const SizedBox(height: 6),
            AgRatingRow(rating: rating, size: 18),
            const SizedBox(height: 12),
            Flexible(
              child: FutureBuilder<dynamic>(
                future: api.get('/api/ag/specialists/${specialist.id}/reviews'),
                builder: (context, snap) {
                  if (!snap.hasData) return const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()));
                  final list = (snap.data is Map && snap.data['reviews'] is List) ? snap.data['reviews'] as List : const [];
                  if (list.isEmpty) return Padding(padding: const EdgeInsets.all(16), child: Text(tr('Отзывов пока нет'), style: TextStyle(color: mut)));
                  return ListView.separated(
                    shrinkWrap: true,
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final r = list[i] as Map;
                      final stars = (r['rating'] as num?)?.toInt() ?? 0;
                      final tags = (r['tags'] is List) ? (r['tags'] as List).map((t) => _tagNames[t] ?? '').where((t) => t.isNotEmpty).toList() : const <String>[];
                      final text = (r['comment'] ?? '').toString().trim();
                      final isAdmin = r['source'] == 'admin'; // AG_RATE5
                      final date = DateTime.tryParse('${r['created_at']}')?.toLocal();
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: soft, borderRadius: BorderRadius.circular(16)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              for (var s = 0; s < 5; s++) AgStar(fill: s < stars ? 1 : 0, size: 14),
                              const Spacer(),
                              if (isAdmin) ...[
                                const SizedBox(width: 8),
                                Text(tr('Оценка AG Service'),
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFFFF6A00))),
                              ],
                              if (date != null)
                                Text('${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}',
                                    style: TextStyle(fontSize: 12, color: mut)),
                            ]),
                            if (tags.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(tags.join(' · '), style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFFFF6A00))),
                            ],
                            if (text.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(text, style: TextStyle(fontSize: 14, height: 1.35, color: ink)),
                            ],
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6A00),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: onChoose,
                child: Text(tr('Записаться к этому мастеру'), style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
