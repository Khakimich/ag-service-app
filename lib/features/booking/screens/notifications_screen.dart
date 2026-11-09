import 'package:mobile/core/nav.dart'; // AG_FIX3
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/theme.dart';
import '../providers/notifications_provider.dart';
import '../../../core/i18n.dart'; // AG_I18N1

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationsProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: const AgBackButton(), toolbarHeight: 48, backgroundColor: Colors.transparent, elevation: 0, scrolledUnderElevation: 0), // AG_FIX3
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  tr('Уведомления'),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.onSurface,
                    letterSpacing: -0.4,
                  ),
                ),
                Consumer<NotificationsProvider>(
                  builder: (context, provider, _) {
                    if (provider.unreadCount == 0) {
                      return const SizedBox.shrink();
                    }
                    return TextButton(
                      onPressed: () => provider.markAllAsRead(),
                      child: Text(
                        tr('Прочитать все'),
                        style: TextStyle(
                          color: BrandColors.orange,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: Consumer<NotificationsProvider>(
              builder: (context, provider, _) {
                if (provider.loading && provider.notifications.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.error != null && provider.notifications.isEmpty) {
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
                          Text(provider.error!, textAlign: TextAlign.center),
                          const SizedBox(height: 16),
                          OutlinedButton(
                            onPressed: () => provider.load(),
                            child: Text(tr('Повторить')),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final list = provider.notifications;
                if (list.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.notifications_none_rounded,
                            size: 64,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          SizedBox(height: 16),
                          Text(
                            tr('Нет уведомлений'),
                            style: TextStyle(
                              fontSize: 16,
                              color:
                                  Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => provider.load(),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(0, 8, 0, 100),
                    itemCount: list.length,
                    separatorBuilder:
                        (_, __) => Divider(
                          height: 1,
                          indent: 16,
                          endIndent: 16,
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                    itemBuilder: (context, i) {
                      final item = list[i];
                      final dateLabel = DateFormat(
                        'd MMM, HH:mm',
                        AgI18n.dateLocale,
                      ).format(item.createdAt);

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.title,
                                style: TextStyle(
                                  fontWeight:
                                      item.isRead
                                          ? FontWeight.w500
                                          : FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            if (!item.isRead)
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: BrandColors.orange,
                                ),
                              ),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.body,
                                style: TextStyle(
                                  fontSize: 14,
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                dateLabel,
                                style: TextStyle(
                                  fontSize: 12,
                                  color:
                                      Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        onTap: () {
                          if (!item.isRead) {
                            provider.markAsRead(item.id);
                          }
                          // Navigation logic based on relatedId and type
                          if (item.relatedId != null &&
                              item.relatedId!.isNotEmpty) {
                            if (item.type == 'chat_message') {
                              context.push('/chats/${item.relatedId}');
                            } else if (item.type.startsWith('booking_')) {
                              context.go('/bookings');
                            }
                          }
                        },
                      );
                    },
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
