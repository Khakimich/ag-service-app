import 'package:mobile/core/nav.dart'; // AG_FIX3
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/theme.dart';
import '../providers/referrals_provider.dart';
import '../../../core/i18n.dart'; // AG_I18N1
import '../widgets/invite_card.dart'; // AG_INVITE1
import '../../../core/ag_levels.dart'; // AG_REFLVL1

class ReferralScreen extends StatefulWidget {
  const ReferralScreen({super.key});

  @override
  State<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends State<ReferralScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReferralsProvider>().loadSummary();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: const AgBackButton(fallback: '/profile'), title: Text(tr('Пригласить друзей'))), // AG_FIX3
      body: Consumer<ReferralsProvider>(
        builder: (context, provider, _) {
          if (provider.loading && provider.summary == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null && provider.summary == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      size: 48,
                      color: BrandColors.orange,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      trf('Ошибка загрузки: {0}', [provider.error]),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: provider.loadSummary,
                      child: Text(tr('Повторить')),
                    ),
                  ],
                ),
              ),
            );
          }

          final summary = provider.summary;
          if (summary == null) {
            return Center(child: Text(tr('Нет данных')));
          }

          final referralUrl = 'https://autogrom.ru/ref/${summary.referralCode}';

          return RefreshIndicator(
            onRefresh: provider.loadSummary,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              children: [
                Text(
                  tr('Реферальная программа'),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.onSurface,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 20),
                // Points Balance Card
                Card(
                  elevation: 0,
                  color: BrandColors.orange.withValues(alpha: 0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: BrandColors.orange.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.wallet_giftcard_rounded,
                          size: 48,
                          color: BrandColors.orange,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          tr('Ваш баланс бонусов'),
                          style: TextStyle(
                            fontSize: 16,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          trf('{0} ₽', [summary.bonusPoints]),
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: BrandColors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Share Link Section
                Text(
                  tr('Приглашайте друзей'),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  trf('Делитесь ссылкой ниже. Друг получит {0} ₽ сразу после регистрации, а вы — {1} ₽ после его первого визита в сервис.', [summary.friendReward, summary.referrerFirstVisitReward]),
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),

                // Referral Link Copy Row
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          referralUrl,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: referralUrl));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                tr('Реферальная ссылка скопирована в буфер обмена'),
                              ),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.copy_rounded,
                          color: BrandColors.orange,
                        ),
                        tooltip: tr('Копировать'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // AG_INVITE1: карточка-приглашение + WhatsApp / Telegram
                InviteFriendsButton( // AG_INVITE2
                  code: summary.referralCode,
                  url: referralUrl,
                  giftText: trf('{0} бонусов на первый ремонт', [summary.friendReward]),
                ),

                const SizedBox(height: 32),

                // Referral Program Rules
                Text(
                  tr('Правила начисления'),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                Container( // AG_REFRED2: новые правила с 14 ноября
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE53935), Color(0xFFB71C1C)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: const Color(0xFFD32F2F).withValues(alpha: .35), blurRadius: 18, offset: const Offset(0, 8))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30)),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.campaign_rounded, size: 18, color: Color(0xFFD32F2F)),
                          const SizedBox(width: 6),
                          Text(tr('НОВЫЕ ПРАВИЛА С 14 НОЯБРЯ'), style: const TextStyle(color: Color(0xFFD32F2F), fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: .4)),
                        ]),
                      ),
                      const SizedBox(height: 14),
                      _AgRefRedRow(icon: Icons.person_add_alt_1_rounded, amount: summary.friendReward, text: tr('Другу — сразу после регистрации по вашей ссылке')),
                      const SizedBox(height: 12),
                      _AgRefRedRow(icon: Icons.car_repair_rounded, amount: summary.referrerFirstVisitReward, text: tr('Вам — когда друг приедет в сервис и пройдёт любую услугу')),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _RuleTile(
                  icon: Icons.person_add_alt_1_rounded,
                  title: tr('Друг регистрируется по ссылке'),
                  description: trf('Другу сразу начисляется {0} ₽ на бонусный счёт.', [summary.friendReward]),
                ),
                if (summary.referrerSignupReward > 0)
                  _RuleTile(
                    icon: Icons.celebration_rounded,
                    title: tr('Приглашение принято'),
                    description: trf('Вам — {0} ₽, когда друг зарегистрируется.', [summary.referrerSignupReward]),
                  ),
                _RuleTile(
                  icon: Icons.check_circle_outline_rounded,
                  title: tr('Первый ремонт друга'),
                  description: trf('Вам — {0} ₽ на бонусный счёт, когда друг впервые обслужится в сервисе.', [summary.referrerFirstVisitReward]),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon( // AG_REFLVL1
                  onPressed: () => showAgLevelsSheet(context, invited: summary.referrals.length, rewardPerFriend: summary.referrerTotal),
                  icon: const Icon(Icons.workspace_premium_rounded, color: BrandColors.orange),
                  label: Text(tr('Уровни и привилегии'), style: const TextStyle(color: BrandColors.orange, fontWeight: FontWeight.w800)),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    side: BorderSide(color: BrandColors.orange.withValues(alpha: .45)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
                const SizedBox(height: 32),

                // Referred Friends list
                Text(
                  trf('Приглашенные друзья ({0})', [summary.referrals.length]),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),

                if (summary.referrals.isEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        tr('Вы еще не пригласили друзей.\nСамое время поделиться ссылкой!'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: summary.referrals.length,
                    separatorBuilder:
                        (context, index) => Divider(
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                    itemBuilder: (context, index) {
                      final item = summary.referrals[index];
                      final isFirstVisit = item.status == 'first_visit';

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor:
                              isFirstVisit
                                  ? BrandColors.orange.withValues(alpha: 0.15)
                                  : Theme.of(
                                    context,
                                  ).colorScheme.surfaceContainerHighest,
                          child: Icon(
                            isFirstVisit
                                ? Icons.done_all_rounded
                                : Icons.person_outline_rounded,
                            color:
                                isFirstVisit
                                    ? BrandColors.orange
                                    : Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        title: Text(
                          item.refereeName,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          trf('Регистрация: {0}', [DateFormat('dd.MM.yyyy').format(item.refereeRegisteredAt)]),
                          style: TextStyle(
                            fontSize: 13,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color:
                                isFirstVisit
                                    ? BrandColors.orange.withValues(alpha: 0.1)
                                    : Theme.of(
                                      context,
                                    ).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color:
                                  isFirstVisit
                                      ? BrandColors.orange.withValues(
                                        alpha: 0.2,
                                      )
                                      : Colors.transparent,
                            ),
                          ),
                          child: Text(
                            isFirstVisit ? tr('Первый визит') : tr('Зарегистрирован'),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color:
                                  isFirstVisit
                                      ? BrandColors.orange
                                      : Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _RuleTile extends StatelessWidget {
  const _RuleTile({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: BrandColors.orange, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1.3,
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


class _AgRefRedRow extends StatelessWidget { // AG_REFRED2
  const _AgRefRedRow({required this.icon, required this.amount, required this.text});
  final IconData icon;
  final num amount;
  final String text;
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        width: 46, height: 46,
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: .18), borderRadius: BorderRadius.circular(14)),
        child: Icon(icon, color: Colors.white, size: 26),
      ),
      const SizedBox(width: 12),
      Text('+${amount.toStringAsFixed(0)} ₽', style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900)),
      const SizedBox(width: 12),
      Expanded(child: Text(text, style: TextStyle(color: Colors.white.withValues(alpha: .95), fontSize: 15, fontWeight: FontWeight.w700, height: 1.25))),
    ]);
  }
}
