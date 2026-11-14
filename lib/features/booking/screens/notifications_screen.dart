// AG_NOTIF2 — уведомления: группы по дням, иконка по типу, строгие карточки, светлая/тёмная тема.
import 'package:mobile/core/nav.dart'; // AG_FIX3
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../models/notification.dart';
import '../providers/notifications_provider.dart';
import '../../../core/i18n.dart'; // AG_I18N1

const _orange = Color(0xFFF26200);

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<NotificationsProvider>().load());
  }

  String _dayTitle(DateTime d) {
    final now = DateTime.now();
    final a = DateTime(d.year, d.month, d.day), b = DateTime(now.year, now.month, now.day);
    final diff = b.difference(a).inDays;
    if (diff == 0) return tr('Сегодня');
    if (diff == 1) return tr('Вчера');
    const m = ['января', 'февраля', 'марта', 'апреля', 'мая', 'июня', 'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря'];
    return '${d.day} ${tr(m[d.month - 1])}';
  }

  void _open(BuildContext context, NotificationsProvider p, AppNotification n) {
    if (n.isRead == false) p.markAsRead(n.id);
    if (n.type.startsWith('booking_')) context.go('/bookings');
    if (n.type.contains('bonus') || n.type.contains('referral')) context.push('/profile/referrals');
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(leading: const AgBackButton(), toolbarHeight: 48, backgroundColor: Colors.transparent, elevation: 0, scrolledUnderElevation: 0),
      body: Consumer<NotificationsProvider>(builder: (context, p, _) {
        final list = p.notifications;
        final rows = <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 12, 6),
            child: Row(children: [
              Expanded(child: Text(tr('Уведомления'), style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: -.6, color: cs.onSurface))),
              if (p.unreadCount > 0)
                TextButton(
                  onPressed: p.markAllAsRead,
                  child: Text(tr('Прочитать все'), style: const TextStyle(color: _orange, fontWeight: FontWeight.w700)),
                ),
            ]),
          ),
          if (p.unreadCount > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(trf('Новых: {0}', [p.unreadCount]), style: TextStyle(color: cs.onSurfaceVariant, fontWeight: FontWeight.w600)),
            ),
        ];
        String? lastDay;
        for (final n in list) {
          final day = _dayTitle(n.createdAt);
          if (day != lastDay) {
            lastDay = day;
            rows.add(Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(day.toUpperCase(), style: TextStyle(fontSize: 12, letterSpacing: .8, fontWeight: FontWeight.w800, color: cs.onSurfaceVariant)),
            ));
          }
          rows.add(_NotifCard(n: n, onTap: () => _open(context, p, n)));
        }
        if (list.isEmpty && p.loading == false) rows.add(const _Empty());
        if (list.isEmpty && p.loading) rows.add(const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator())));
        rows.add(const SizedBox(height: 120));
        return RefreshIndicator(onRefresh: p.load, child: ListView(physics: const AlwaysScrollableScrollPhysics(), children: rows));
      }),
    );
  }
}

class _NotifCard extends StatelessWidget {
  const _NotifCard({required this.n, required this.onTap});
  final AppNotification n;
  final VoidCallback onTap;

  static const _paths = {
    'bonus': '<rect x="4" y="9" width="16" height="11" rx="1.6"/><path d="M3.5 9h17v3.2h-17zM12 9v11"/><path d="M12 9c-1.4-3.4-5.4-3.7-5.4-1.5 0 1.3 2.2 1.5 5.4 1.5zm0 0c1.4-3.4 5.4-3.7 5.4-1.5 0 1.3-2.2 1.5-5.4 1.5z"/>',
    'booking': '<rect x="3.5" y="5" width="17" height="15.5" rx="2.5"/><path d="M3.5 10h17M8 3v4M16 3v4M8.5 14.5l2 2 4-4"/>',
    'cancel': '<rect x="3.5" y="5" width="17" height="15.5" rx="2.5"/><path d="M3.5 10h17M8 3v4M16 3v4M10 13.5l4 4M14 13.5l-4 4"/>',
    'photo': '<path d="M4 8h3l1.6-2.4h6.8L17 8h3a1 1 0 0 1 1 1v9a1 1 0 0 1-1 1H4a1 1 0 0 1-1-1V9a1 1 0 0 1 1-1z"/><circle cx="12" cy="13" r="3.4"/>',
    'tip': '<path d="M14.7 6.3a4 4 0 0 0-5.4 5.4L3.5 17.5l3 3 5.8-5.8a4 4 0 0 0 5.4-5.4l-2.5 2.5-2.5-.5-.5-2.5z"/>',
    'info': '<path d="M6.5 16.5V11a5.5 5.5 0 0 1 11 0v5.5l1.5 1.5H5z"/><path d="M10.2 20.2a2 2 0 0 0 3.6 0"/>',
  };

  (String, Color) _kind() {
    final t = n.type;
    if (t.contains('bonus') || t.contains('referral')) return ('bonus', const Color(0xFFF59E0B));
    if (t == 'booking_cancelled') return ('cancel', const Color(0xFFDC2626));
    if (t.startsWith('booking')) return ('booking', const Color(0xFF16A34A));
    if (t.contains('photo') || t.contains('intake')) return ('photo', const Color(0xFF2563EB));
    if (t.contains('recommend')) return ('tip', const Color(0xFF7C3AED));
    return ('info', _orange);
  }

  String _clean(String s) => s.replaceAll(RegExp(r'^[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}]\s*', unicode: true), '');

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final (k, color) = _kind();
    final hex = '#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
    final unread = n.isRead == false;
    final hh = n.createdAt.hour.toString().padLeft(2, '0'), mm = n.createdAt.minute.toString().padLeft(2, '0');
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Material(
        color: dark ? const Color(0xFF1A1E24) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: unread ? color.withValues(alpha: .35) : (dark ? const Color(0xFF262C34) : const Color(0xFFEDEFF2))),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(color: color.withValues(alpha: dark ? .18 : .10), borderRadius: BorderRadius.circular(12)),
                alignment: Alignment.center,
                child: SvgPicture.string(
                  '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="$hex" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round">${_paths[k]}</svg>',
                  width: 22, height: 22),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text(_clean(n.title), maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 15, height: 1.25, fontWeight: unread ? FontWeight.w800 : FontWeight.w600, color: cs.onSurface))),
                  const SizedBox(width: 8),
                  Text('$hh:$mm', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                ]),
                if (n.body.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(n.body, maxLines: 3, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13.5, height: 1.35, color: cs.onSurfaceVariant)),
                ],
              ])),
              if (unread) Padding(
                padding: const EdgeInsets.only(left: 8, top: 4),
                child: Container(width: 9, height: 9, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 80, 32, 0),
      child: Column(children: [
        SvgPicture.string('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#9CA3AF" stroke-width="1.4" stroke-linecap="round" stroke-linejoin="round"><path d="M6.5 16.5V11a5.5 5.5 0 0 1 11 0v5.5l1.5 1.5H5z"/><path d="M10.2 20.2a2 2 0 0 0 3.6 0"/></svg>', width: 56, height: 56),
        const SizedBox(height: 14),
        Text(tr('Уведомлений пока нет'), style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: cs.onSurface)),
        const SizedBox(height: 6),
        Text(tr('Здесь появятся записи, бонусы и новости сервиса'), textAlign: TextAlign.center, style: TextStyle(color: cs.onSurfaceVariant)),
      ]),
    );
  }
}
