// AG_EXTRAS1 + AG_RATE2 + AG_RATE3 — непрочитанные сообщения, рейтинг мастеров, оценка мастера после ремонта.
import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_client.dart';
import '../core/i18n.dart'; // AG_I18N1

const _agOrange = Color(0xFFFF6A00);

/// Счётчик непрочитанных сообщений от сервиса (для вкладки «Чаты»).
class AgUnread extends ChangeNotifier {
  AgUnread._();
  static final AgUnread instance = AgUnread._();

  int total = 0;
  Map<String, int> byConversation = const {};
  Timer? _timer;
  ApiClient? _api;
  bool _busy = false;

  void start(ApiClient api) {
    _api = api;
    _timer ??= Timer.periodic(const Duration(seconds: 30), (_) => refresh());
    refresh();
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _set(0, const {});
  }

  void _set(int t, Map<String, int> by) {
    if (t == total && by.length == byConversation.length) {
      byConversation = by;
      return;
    }
    total = t;
    byConversation = by;
    notifyListeners();
  }

  Future<void> refresh() async {
    final api = _api;
    if (api == null || _busy) return;
    _busy = true;
    try {
      final data = await api.get('/api/ag/unread');
      if (data is Map) {
        final by = <String, int>{};
        final raw = data['by'];
        if (raw is Map) {
          raw.forEach((k, v) => by[k.toString()] = (v is num) ? v.toInt() : int.tryParse('$v') ?? 0);
        }
        _set((data['total'] is num) ? (data['total'] as num).toInt() : 0, by);
      }
    } catch (_) {
      // не вошёл или нет сети — счётчик просто не меняется
    } finally {
      _busy = false;
    }
  }

  /// Клиент открыл чат — всё прочитано.
  Future<void> markRead(ApiClient api, String conversationId) async {
    _api ??= api;
    if (byConversation.containsKey(conversationId)) {
      final by = Map<String, int>.from(byConversation);
      final n = by.remove(conversationId) ?? 0;
      _set((total - n).clamp(0, 1 << 30), by);
    }
    try {
      await api.post('/api/ag/conversations/$conversationId/read', {});
    } catch (_) {}
  }
}

/// Рейтинг мастеров: средняя оценка и количество.
class AgRatings {
  static Map<String, AgRating> _cache = {};
  static DateTime _at = DateTime.fromMillisecondsSinceEpoch(0);

  static Future<Map<String, AgRating>> load(ApiClient api) async {
    if (DateTime.now().difference(_at).inSeconds < 60 && _cache.isNotEmpty) return _cache;
    try {
      final data = await api.get('/api/ag/specialists/ratings');
      final out = <String, AgRating>{};
      final raw = data is Map ? data['ratings'] : null;
      if (raw is Map) {
        raw.forEach((k, v) {
          if (v is Map) {
            out[k.toString()] = AgRating((v['avg'] as num?)?.toDouble() ?? 0, (v['count'] as num?)?.toInt() ?? 0);
          }
        });
      }
      _cache = out;
      _at = DateTime.now();
    } catch (_) {}
    return _cache;
  }
}

class AgRating {
  const AgRating(this.avg, this.count);
  final double avg;
  final int count;
}

const _starPath =
    '<path d="M12 3.2l2.6 5.5 6 .8-4.4 4.2 1.1 6-5.3-2.9-5.3 2.9 1.1-6L3.4 9.5l6-.8z"/>';

/// Звезда (заполненная, наполовину или пустая).
class AgStar extends StatelessWidget {
  const AgStar({super.key, this.fill = 1, this.size = 16});
  final double fill;
  final double size;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final empty = dark ? const Color(0xFF3A3D45) : const Color(0xFFE3E5EA);
    Widget star(Color c) => SvgPicture.string(
          '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="#000" stroke="#000" stroke-width="1.2" stroke-linejoin="round">$_starPath</svg>',
          width: size,
          height: size,
          colorFilter: ColorFilter.mode(c, BlendMode.srcIn),
        );
    if (fill >= 1) return star(const Color(0xFFFFB400));
    if (fill <= 0) return star(empty);
    return Stack(
      children: [
        star(empty),
        ClipRect(
          child: Align(alignment: Alignment.centerLeft, widthFactor: fill, child: star(const Color(0xFFFFB400))),
        ),
      ],
    );
  }
}

/// Ряд из 5 звёзд с оценкой «4,8 · 23 оценки».
class AgRatingRow extends StatelessWidget {
  const AgRatingRow({super.key, required this.rating, this.size = 15, this.showCount = true});
  final AgRating? rating;
  final double size;
  final bool showCount;

  static String plural(int n) {
    final m10 = n % 10, m100 = n % 100;
    if (m10 == 1 && m100 != 11) return tr('оценка');
    if (m10 >= 2 && m10 <= 4 && (m100 < 12 || m100 > 14)) return tr('оценки');
    return tr('оценок');
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final mut = dark ? const Color(0xFF9EA4AE) : const Color(0xFF6B7280);
    final r = rating;
    if (r == null || r.count == 0) {
      return Row(mainAxisSize: MainAxisSize.min, children: [
        for (var i = 0; i < 5; i++) Padding(padding: const EdgeInsets.only(right: 1), child: AgStar(fill: 0, size: size)),
        const SizedBox(width: 6),
        Text(tr('Новый мастер'), style: TextStyle(fontSize: size * .82, fontWeight: FontWeight.w600, color: mut)),
      ]);
    }
    return Row(mainAxisSize: MainAxisSize.min, children: [
      for (var i = 0; i < 5; i++)
        Padding(padding: const EdgeInsets.only(right: 1), child: AgStar(fill: (r.avg - i).clamp(0.0, 1.0), size: size)),
      const SizedBox(width: 6),
      Text(r.avg.toStringAsFixed(1).replaceAll('.', ','),
          style: TextStyle(fontSize: size * .92, fontWeight: FontWeight.w800, color: dark ? Colors.white : const Color(0xFF15171C))),
      if (showCount) ...[
        const SizedBox(width: 4),
        Text('· ${r.count} ${plural(r.count)}', style: TextStyle(fontSize: size * .82, fontWeight: FontWeight.w600, color: mut)),
      ],
    ]);
  }
}

/// AG_RATE2: мои оценки — какие записи клиент уже оценил.
class AgMyReviews {
  static Future<Map<String, int>> load(ApiClient api) async {
    try {
      final data = await api.get('/api/ag/reviews/mine');
      final out = <String, int>{};
      final raw = data is Map ? data['ratings'] : null;
      if (raw is Map) raw.forEach((k, v) => out[k.toString()] = (v as num).toInt());
      return out;
    } catch (_) {
      return const {};
    }
  }
}

/// Окно «Оцените работу мастера» после завершённого ремонта.
class AgReviewPrompt {
  /// Открыть окно оценки для конкретной записи (кнопка «Оценить мастера» в архиве).
  static Future<bool> showFor(BuildContext context, Map<String, dynamic> booking) async {
    final api = context.read<ApiClient>();
    final r = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AgReviewSheet(api: api, booking: booking),
    );
    return r == true;
  }

  static bool _shownThisSession = false;
  static const _key = 'ag_review_dismissed';

  /// Проверяет, есть ли завершённые записи без оценки, и показывает окно (не чаще раза за запуск).
  static Future<void> maybeShow(BuildContext context, {bool force = false}) async {
    if (_shownThisSession && !force) return;
    final api = context.read<ApiClient>();
    List pending = const [];
    try {
      final data = await api.get('/api/ag/reviews/pending');
      pending = (data is Map && data['pending'] is List) ? data['pending'] as List : const [];
    } catch (_) {
      return;
    }
    if (pending.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final dismissed = prefs.getStringList(_key) ?? const <String>[];
    final next = pending.cast<Map>().firstWhere(
          (b) => force || !dismissed.contains(b['id'].toString()),
          orElse: () => const {},
        );
    if (next.isEmpty || !context.mounted) return;
    _shownThisSession = true;
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AgReviewSheet(api: api, booking: Map<String, dynamic>.from(next)),
    );
    if (result != true) {
      await prefs.setStringList(_key, [...dismissed, next['id'].toString()].take(50).toList());
    }
  }
}

class _AgReviewSheet extends StatefulWidget {
  const _AgReviewSheet({required this.api, required this.booking});
  final ApiClient api;
  final Map<String, dynamic> booking;

  @override
  State<_AgReviewSheet> createState() => _AgReviewSheetState();
}

class _AgReviewSheetState extends State<_AgReviewSheet> {
  int _rating = 0;
  final Set<String> _tags = {};
  final _comment = TextEditingController();
  bool _sending = false;
  bool _done = false;

  // AG_RATE3: варианты зависят от оценки
  static Map<String, String> get _good => {
    'quality': tr('Качество'),
    'speed': tr('Быстро'),
    'polite': tr('Вежливо'),
    'explained': tr('Всё объяснил'),
    'clean': tr('Чистота'),
    'price': tr('Честная цена'),
  };
  static Map<String, String> get _bad => {
    'bad_quality': tr('Плохое качество'),
    'slow': tr('Долго'),
    'late': tr('Задержали по времени'),
    'rude': tr('Невежливо'),
    'not_explained': tr('Не объяснили'),
    'expensive': tr('Дорого'),
    'dirty': tr('Грязно в машине'),
    'redo': tr('Пришлось переделывать'),
  };
  static Map<String, String> get _mid => {
    'quality': tr('Качество'),
    'polite': tr('Вежливо'),
    'slow': tr('Долго'),
    'late': tr('Задержали по времени'),
    'not_explained': tr('Не объяснили'),
    'expensive': tr('Дорого'),
  };
  static List<String> get _labels => ['', tr('Плохо'), tr('Так себе'), tr('Нормально'), tr('Хорошо'), tr('Отлично!')];
  static List<String> get _questions => [tr('Выберите оценку'), tr('Что пошло не так?'), tr('Что пошло не так?'), tr('Что можно улучшить?'), tr('Что понравилось?'), tr('Что понравилось?')];

  Color get _chipColor => _rating > 0 && _rating <= 2 ? const Color(0xFFE5484D) : _agOrange;

  Map<String, String> get _tagNames => _rating == 0 ? const {} : (_rating <= 2 ? _bad : (_rating == 3 ? _mid : _good));

  void _setRating(int r) {
    setState(() {
      final group = (int x) => x == 0 ? 0 : (x <= 2 ? 1 : (x == 3 ? 2 : 3));
      if (group(r) != group(_rating)) _tags.clear();
      _rating = r;
    });
  }

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_rating == 0 || _sending) return;
    setState(() => _sending = true);
    try {
      await widget.api.post('/api/ag/reviews', {
        'booking_id': widget.booking['id'],
        'rating': _rating,
        'tags': _tags.toList(),
        'comment': _comment.text.trim(),
      });
      if (!mounted) return;
      setState(() => _done = true);
      await Future.delayed(const Duration(milliseconds: 1400));
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final bg = dark ? const Color(0xFF181B21) : Colors.white;
    final ink = dark ? const Color(0xFFF3F4F6) : const Color(0xFF15171C);
    final mut = dark ? const Color(0xFF9EA4AE) : const Color(0xFF6B7280);
    final soft = dark ? Colors.white.withValues(alpha: .06) : const Color(0xFFF3F4F7);
    final spec = (widget.booking['specialist'] as Map?) ?? const {};
    final svc = (widget.booking['service'] as Map?) ?? const {};
    final photo = (spec['photo_url'] ?? '').toString();
    final name = (spec['full_name'] ?? tr('Мастер')).toString();

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(26)),
        child: SafeArea(
          top: false,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: _done
                ? Padding(
                    key: const ValueKey('done'),
                    padding: const EdgeInsets.symmetric(vertical: 34),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Text('🙏', style: TextStyle(fontSize: 46)),
                      const SizedBox(height: 10),
                      Text(tr('Спасибо за оценку!'), style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: ink)),
                      const SizedBox(height: 4),
                      Text(tr('Это помогает нам становиться лучше'), style: TextStyle(fontSize: 14, color: mut)),
                    ]),
                  )
                : Column(
                    key: const ValueKey('form'),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 40, height: 4, decoration: BoxDecoration(color: soft, borderRadius: BorderRadius.circular(2))),
                      const SizedBox(height: 16),
                      ClipOval(
                        child: photo.isEmpty
                            ? Container(
                                width: 72,
                                height: 72,
                                color: _agOrange,
                                alignment: Alignment.center,
                                child: Text(name.isNotEmpty ? name[0] : tr('М'),
                                    style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800)),
                              )
                            : CachedNetworkImage(imageUrl: photo, width: 72, height: 72, fit: BoxFit.cover),
                      ),
                      const SizedBox(height: 12),
                      Text(tr('Как вам работа мастера?'),
                          textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: ink)),
                      const SizedBox(height: 4),
                      Text('$name · ${svc['title'] ?? 'ремонт'}',
                          textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: mut)),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (var i = 1; i <= 5; i++)
                            GestureDetector(
                              onTap: () => _setRating(i),
                              child: AnimatedScale(
                                scale: _rating == i ? 1.18 : 1,
                                duration: const Duration(milliseconds: 160),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 5),
                                  child: AgStar(fill: i <= _rating ? 1 : 0, size: 42),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        height: 20,
                        child: Text(_labels[_rating],
                            style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: _agOrange)),
                      ),
                      const SizedBox(height: 10),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: _rating == 0
                            ? const SizedBox.shrink()
                            : Padding(
                                key: ValueKey(_questions[_rating]),
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Text(_questions[_rating],
                                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: ink)),
                              ),
                      ),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: [
                          for (final e in _tagNames.entries)
                            GestureDetector(
                              onTap: () => setState(() => _tags.contains(e.key) ? _tags.remove(e.key) : _tags.add(e.key)),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
                                decoration: BoxDecoration(
                                  color: _tags.contains(e.key) ? _chipColor.withValues(alpha: dark ? .22 : .12) : soft,
                                  borderRadius: BorderRadius.circular(99),
                                  border: Border.all(color: _tags.contains(e.key) ? _chipColor : Colors.transparent),
                                ),
                                child: Text(e.value,
                                    style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w700,
                                        color: _tags.contains(e.key) ? _chipColor : ink)),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _comment,
                        minLines: 2,
                        maxLines: 4,
                        maxLength: 1000,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          hintText: _rating > 0 && _rating <= 2
                              ? tr('Расскажите, что случилось — мы разберёмся')
                              : tr('Комментарий (необязательно)'),
                          counterText: '',
                          filled: true,
                          fillColor: soft,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: _agOrange,
                            disabledBackgroundColor: _agOrange.withValues(alpha: .35),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: _rating == 0 || _sending ? null : _send,
                          child: _sending
                              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                              : Text(tr('Отправить оценку'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text(tr('Позже'), style: TextStyle(color: mut, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
