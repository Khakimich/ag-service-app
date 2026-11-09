// AG_REFLVL1 — уровни AG BONUS и их привилегии. Условия правьте здесь — экран уровней строится из этого списка.
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'i18n.dart';
import 'theme.dart';

class AgLevel {
  const AgLevel(this.name, this.from, this.icon, this.color, this.perks);

  final String name;
  final int from; // сколько приглашённых друзей нужно
  final String icon;
  final Color color;
  final List<String> perks;
}

/// Уровень растёт за приглашённых друзей.
List<AgLevel> agLevels() => [
      AgLevel('BRONZE', 0, 'assets/icons/bonus_levels/bronze.svg', const Color(0xFFC07A45), [
        tr('300 ₽ за каждого приглашённого друга'),
        tr('Оплата бонусами до 20% заказа'),
        tr('Уведомления о статусе ремонта'),
      ]),
      AgLevel('SILVER', 5, 'assets/icons/bonus_levels/silver.svg', const Color(0xFF9AA4B2), [
        tr('Кешбэк 3% бонусами с каждого ремонта'),
        tr('Приоритетная запись — свободное окно в течение 2 дней'),
      ]),
      AgLevel('GOLD', 10, 'assets/icons/bonus_levels/gold.svg', const Color(0xFFE2A93B), [
        tr('Кешбэк 5% бонусами'),
        tr('Бесплатная компьютерная диагностика раз в год'),
      ]),
      AgLevel('PLATINUM', 13, 'assets/icons/bonus_levels/platinum.svg', const Color(0xFF7FB7C9), [
        tr('Кешбэк 7% бонусами'),
        tr('Скидка 10% на запчасти'),
      ]),
      AgLevel('DIAMOND', 18, 'assets/icons/bonus_levels/diamond.svg', const Color(0xFF6E8BFF), [
        tr('Кешбэк 8% бонусами'),
        tr('Персональный мастер-приёмщик'),
      ]),
      AgLevel('AG ELITE', 25, 'assets/icons/bonus_levels/elite.svg', BrandColors.orange, [
        tr('Кешбэк 10% бонусами'),
        tr('Оплата бонусами до 30% заказа'),
        tr('Запись в день обращения без очереди'),
      ]),
    ];

int agLevelIndex(int invited) {
  final l = agLevels();
  for (var i = l.length - 1; i >= 0; i--) {
    if (invited >= l[i].from) return i;
  }
  return 0;
}

Future<void> showAgLevelsSheet(BuildContext context, {required int invited, int rewardPerFriend = 300}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: .55),
    builder: (_) => _LevelsSheet(invited: invited, reward: rewardPerFriend),
  );
}

class _LevelsSheet extends StatelessWidget {
  const _LevelsSheet({required this.invited, required this.reward});

  final int invited;
  final int reward;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final levels = agLevels();
    final cur = agLevelIndex(invited);
    final next = cur + 1 < levels.length ? levels[cur + 1] : null;
    final start = levels[cur].from;
    final progress = next == null ? 1.0 : ((invited - start) / (next.from - start)).clamp(0.0, 1.0);

    return FractionallySizedBox(
      heightFactor: .9,
      child: Container(
        decoration: BoxDecoration(
          color: dark ? const Color(0xFF14161A) : const Color(0xFFFFFBF7),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(children: [
          const SizedBox(height: 10),
          Container(width: 42, height: 5, decoration: BoxDecoration(color: colors.onSurfaceVariant.withValues(alpha: .25), borderRadius: BorderRadius.circular(9))),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 10, 4),
            child: Row(children: [
              Expanded(child: Text(tr('Уровни AG BONUS'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -.4))),
              IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close_rounded)),
            ]),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(16, 4, 16, 24 + MediaQuery.paddingOf(context).bottom),
              children: [
                // текущий уровень
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [levels[cur].color, Color.lerp(levels[cur].color, Colors.black, .35)!],
                    ),
                    boxShadow: [BoxShadow(color: levels[cur].color.withValues(alpha: .35), blurRadius: 24, offset: const Offset(0, 10))],
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Container(
                        width: 52,
                        height: 52,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: .22), borderRadius: BorderRadius.circular(16)),
                        child: SvgPicture.asset(levels[cur].icon),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(tr('Ваш уровень'), style: TextStyle(color: Colors.white.withValues(alpha: .85), fontSize: 12.5, fontWeight: FontWeight.w700)),
                          Text(levels[cur].name, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: .5)),
                        ]),
                      ),
                      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Text('$invited', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
                        Text(tr('друзей'), style: TextStyle(color: Colors.white.withValues(alpha: .85), fontSize: 12, fontWeight: FontWeight.w700)),
                      ]),
                    ]),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(9),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor: Colors.white.withValues(alpha: .25),
                        valueColor: const AlwaysStoppedAnimation(Colors.white),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      next == null
                          ? tr('Максимальный уровень — спасибо, что вы с нами!')
                          : trf('Пригласите ещё {0} — и откроется {1}', [next.from - invited, next.name]),
                      style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w800),
                    ),
                  ]),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: BrandColors.orange.withValues(alpha: .1), borderRadius: BorderRadius.circular(18)),
                  child: Row(children: [
                    const Icon(Icons.card_giftcard_rounded, color: BrandColors.orange),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(trf('За каждого друга, который пришёл на первый ремонт, — {0} ₽ на ваш бонусный счёт', [reward]),
                          style: const TextStyle(fontWeight: FontWeight.w700, height: 1.3)),
                    ),
                  ]),
                ),
                const SizedBox(height: 18),
                // все уровни
                for (var i = 0; i < levels.length; i++) _LevelRow(level: levels[i], state: i < cur ? 0 : i == cur ? 1 : 2, isLast: i == levels.length - 1),
                const SizedBox(height: 8),
                Text(tr('Привилегии уровня действуют, пока вы участник AG BONUS. Условия программы могут обновляться.'),
                    textAlign: TextAlign.center, style: TextStyle(color: colors.onSurfaceVariant, fontSize: 11.5)),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

/// state: 0 — пройден, 1 — текущий, 2 — закрыт
class _LevelRow extends StatelessWidget {
  const _LevelRow({required this.level, required this.state, required this.isLast});

  final AgLevel level;
  final int state;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final locked = state == 2;
    return IntrinsicHeight(
      child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        SizedBox(
          width: 44,
          child: Column(children: [
            Container(
              width: 44,
              height: 44,
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: locked ? colors.onSurfaceVariant.withValues(alpha: .1) : level.color.withValues(alpha: .18),
                border: Border.all(color: state == 1 ? level.color : Colors.transparent, width: 2),
              ),
              child: Opacity(opacity: locked ? .45 : 1, child: SvgPicture.asset(level.icon)),
            ),
            if (!isLast)
              Expanded(
                child: Container(width: 2, margin: const EdgeInsets.symmetric(vertical: 4), color: state == 0 ? level.color.withValues(alpha: .6) : colors.outlineVariant.withValues(alpha: .6)),
              ),
          ]),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            margin: EdgeInsets.only(bottom: isLast ? 0 : 12),
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(
              color: dark ? const Color(0xFF1B1E22) : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: state == 1 ? level.color : colors.outlineVariant.withValues(alpha: .5), width: state == 1 ? 1.6 : 1),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(level.name, style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w900, letterSpacing: .4, color: locked ? colors.onSurfaceVariant : null)),
                const Spacer(),
                if (state == 1)
                  _tag(tr('Ваш уровень'), level.color)
                else if (state == 0)
                  const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 20)
                else
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.lock_rounded, size: 14, color: colors.onSurfaceVariant),
                    const SizedBox(width: 3),
                    Text(level.from == 0 ? '' : trf('от {0} друзей', [level.from]),
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: colors.onSurfaceVariant)),
                  ]),
              ]),
              const SizedBox(height: 6),
              for (final p in level.perks)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Container(width: 6, height: 6, decoration: BoxDecoration(color: locked ? colors.onSurfaceVariant.withValues(alpha: .5) : level.color, shape: BoxShape.circle)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(p, style: TextStyle(fontSize: 13.5, height: 1.3, color: locked ? colors.onSurfaceVariant : null))),
                  ]),
                ),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _tag(String t, Color c) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(color: c.withValues(alpha: .16), borderRadius: BorderRadius.circular(99)),
        child: Text(t, style: TextStyle(color: c, fontSize: 11.5, fontWeight: FontWeight.w900)),
      );
}
