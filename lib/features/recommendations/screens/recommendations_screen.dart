import 'package:mobile/core/nav.dart'; // AG_FIX3
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/api_client.dart';
import '../../../models/recommendation.dart';
import '../data/recommendations_repository.dart';
import '../../../core/i18n.dart'; // AG_I18N1

class RecommendationsScreen extends StatefulWidget {
  const RecommendationsScreen({super.key});

  @override
  State<RecommendationsScreen> createState() => _RecommendationsScreenState();
}

class _RecommendationsScreenState extends State<RecommendationsScreen> {
  late final RecommendationsRepository _repository;

  List<Recommendation> _items = const [];
  bool _loading = true;
  String? _error;
  String? _changingId;

  static const _orange = Color(0xFFFF6A00);
  static const _orangeSoft = Color(0xFFFFF1E7);

  @override
  void initState() {
    super.initState();
    _repository = RecommendationsRepository(context.read<ApiClient>());
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final items = await _repository.list();

      if (!mounted) return;

      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  Future<void> _changeStatus(Recommendation item, String status) async {
    if (_changingId != null) return;

    setState(() => _changingId = item.id);

    try {
      final updated = await _repository.setStatus(id: item.id, status: status);

      if (!mounted) return;

      setState(() {
        _items = _items
            .map((current) => current.id == item.id ? updated : current)
            .toList(growable: false);
        _changingId = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status == 'accepted'
                ? tr('Рекомендация принята')
                : tr('Вы отказались от рекомендации'),
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      setState(() => _changingId = null);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            trf('Не удалось сохранить ответ: {0}', [error]),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(leading: const AgBackButton(fallback: '/'), /* AG_FIX3 */ 
        title: Text(
          tr('Рекомендации'),
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        centerTitle: false,
      ),
      body: RefreshIndicator(onRefresh: _load, child: _body()),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: _orange));
    }

    if (_error != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 80),
          const Icon(Icons.cloud_off_rounded, size: 54, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            tr('Не удалось загрузить рекомендации'),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            tr('Потяните экран вниз, чтобы повторить.'),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    if (_items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 70),
          Center(
            child: Container(
              width: 96,
              height: 96,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _orangeSoft,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Image.asset(
                'assets/home_v3/recommendations.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            tr('Пока нет рекомендаций'),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            tr('Когда мастер добавит рекомендацию по вашему автомобилю, она появится здесь.'),
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, height: 1.4),
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
      itemCount: _items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, index) => _card(_items[index]),
    );
  }

  Widget _card(Recommendation item) {
    final car = item.car;
    final pending = item.status == 'active';
    final changing = _changingId == item.id;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: .22),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .035),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: _orangeSoft,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Image.asset(
                  'assets/home_v3/recommendations.png',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      car != null && car.title.isNotEmpty
                          ? car.title
                          : tr('Ваш автомобиль'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (car?.licensePlate?.trim().isNotEmpty == true) ...[
                      const SizedBox(height: 2),
                      Text(
                        car!.licensePlate!,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              _statusChip(item.status),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            item.text,
            style: const TextStyle(
              fontSize: 15,
              height: 1.42,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (item.mileage != null) ...[
            const SizedBox(height: 12),
            _infoRow(
              Icons.speed_rounded,
              trf('Пробег: {0} км', [_number(item.mileage!)]),
            ),
          ],
          if (item.authorName.trim().isNotEmpty) ...[
            const SizedBox(height: 7),
            _infoRow(
              Icons.engineering_rounded,
              trf('Мастер: {0}', [item.authorName]),
            ),
          ],
          const SizedBox(height: 7),
          _infoRow(Icons.schedule_rounded, _date(item.createdAt)),
          if (pending) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed:
                        changing ? null : () => _changeStatus(item, 'declined'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      tr('Отказаться'),
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed:
                        changing ? null : () => _changeStatus(item, 'accepted'),
                    style: FilledButton.styleFrom(
                      backgroundColor: _orange,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child:
                        changing
                            ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.3,
                                color: Colors.white,
                              ),
                            )
                            : Text(
                              tr('Согласен'),
                              style: TextStyle(fontWeight: FontWeight.w900),
                            ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _statusChip(String status) {
    final accepted = status == 'accepted';
    final declined = status == 'declined';

    final text =
        accepted
            ? tr('Согласовано')
            : declined
            ? tr('Отказ')
            : tr('Новая');

    final color =
        accepted
            ? const Color(0xFF178A45)
            : declined
            ? const Color(0xFFC43C35)
            : _orange;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 17, color: Colors.grey.shade600),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  String _date(DateTime value) {
    final local = value.toLocal();

    String two(int number) => number.toString().padLeft(2, '0');

    return '${two(local.day)}.${two(local.month)}.${local.year} '
        '${two(local.hour)}:${two(local.minute)}';
  }

  String _number(int value) {
    final source = value.toString();
    final result = StringBuffer();

    for (var i = 0; i < source.length; i++) {
      if (i > 0 && (source.length - i) % 3 == 0) {
        result.write(' ');
      }
      result.write(source[i]);
    }

    return result.toString();
  }
}
