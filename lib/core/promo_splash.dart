// AG_PROMO1 — экран приветствия (акция/услуга) при открытии приложения.
// Включается и меняется в AG Service → «Экран приветствия» (job.autogrom.ru).
import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import '../core/i18n.dart'; // AG_I18N1

class AgPromoSplash {
  AgPromoSplash._();

  static const String feedUrl = 'https://job.autogrom.ru/ag_promo_feed.php';
  static bool _done = false;

  /// Показать заставку, если она включена. Один раз за запуск.
  static Future<void> show(BuildContext context) async {
    if (_done) return;
    _done = true;
    try {
      final res = await http
          .get(Uri.parse(feedUrl), headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 4));
      if (res.statusCode != 200) return;
      final d = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      if (d['enabled'] != true) return;
      final url = '${d['url'] ?? ''}';
      if (url.isEmpty) return;

      final id = '${d['id'] ?? ''}';
      final freq = '${d['frequency'] ?? 'daily'}';
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now().millisecondsSinceEpoch;
      if (freq == 'once' && prefs.getBool('ag_promo_seen_$id') == true) return;
      if (freq == 'daily') {
        final last = prefs.getInt('ag_promo_day_$id') ?? 0;
        if (now - last < 20 * 3600 * 1000) return;
      }
      if (!context.mounted) return;

      // Сначала загружаем фото/видео полностью (до 20 сек.), потом показываем — без чёрного экрана.
      VideoPlayerController? video;
      if (d['type'] == 'video') {
        video = VideoPlayerController.networkUrl(Uri.parse(url));
        try {
          await video.initialize().timeout(const Duration(seconds: 20));
        } catch (e) {
          await video.dispose();
          debugPrint('[Promo] video not loaded: $e');
          return;
        }
      } else {
        var ok = true;
        await precacheImage(
          NetworkImage(url),
          context,
          onError: (e, _) {
            ok = false;
          },
        ).timeout(const Duration(seconds: 20), onTimeout: () {
          ok = false;
        });
        if (!ok) {
          debugPrint('[Promo] image not loaded');
          return;
        }
      }
      if (!context.mounted) {
        await video?.dispose();
        return;
      }

      await Navigator.of(context, rootNavigator: true).push(
        PageRouteBuilder<void>(
          opaque: true,
          transitionDuration: const Duration(milliseconds: 380),
          reverseTransitionDuration: const Duration(milliseconds: 320),
          pageBuilder: (_, a, __) => FadeTransition(opacity: a, child: _PromoPage(data: d, video: video)),
        ),
      );
      await prefs.setBool('ag_promo_seen_$id', true);
      await prefs.setInt('ag_promo_day_$id', now);
    } catch (e) {
      debugPrint('[Promo] skipped: $e');
    }
  }
}

class _PromoPage extends StatefulWidget {
  const _PromoPage({required this.data, this.video});

  final Map<String, dynamic> data;
  final VideoPlayerController? video;

  @override
  State<_PromoPage> createState() => _PromoPageState();
}

class _PromoPageState extends State<_PromoPage> with SingleTickerProviderStateMixin {
  VideoPlayerController? _video;
  Timer? _timer;
  Timer? _fail;
  late int _left;
  bool _ready = false;
  bool _closed = false;
  late final AnimationController _zoom = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 12),
  );

  String get _url => '${widget.data['url']}';
  bool get _isVideo => widget.data['type'] == 'video';
  String get _title => '${widget.data['title'] ?? ''}'.trim();
  String get _btnText => '${widget.data['button_text'] ?? ''}'.trim();
  String get _btnUrl => '${widget.data['button_url'] ?? ''}'.trim();

  @override
  void initState() {
    super.initState();
    _left = int.tryParse('${widget.data['duration']}') ?? 5;
    // Если фото/видео не загрузилось за 6 секунд — просто закрываем.
    _fail = Timer(const Duration(seconds: 10), () {
      if (!_ready) _close();
    });
    final c = widget.video;
    if (_isVideo && c != null) {
      _video = c;
      c.setVolume(0);
      c.setLooping(true);
      c.play();
      WidgetsBinding.instance.addPostFrameCallback((_) => _onReady());
    }
  }

  void _onReady() {
    if (_ready || !mounted) return;
    setState(() => _ready = true);
    _fail?.cancel();
    _zoom.forward();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      if (_left <= 1) {
        t.cancel();
        _close();
      } else {
        setState(() => _left--);
      }
    });
  }

  void _close() {
    if (_closed || !mounted) return;
    _closed = true;
    _timer?.cancel();
    Navigator.of(context).maybePop();
  }

  Future<void> _tapButton() async {
    final u = _btnUrl;
    _close();
    if (u.isEmpty) return;
    final uri = u.startsWith('/') ? Uri.parse('https://job.autogrom.ru$u') : Uri.parse(u);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _fail?.cancel();
    _video?.dispose();
    _zoom.dispose();
    super.dispose();
  }

  Widget _media() {
    if (_isVideo) {
      final c = _video;
      if (c == null || !c.value.isInitialized) return const SizedBox.expand();
      return SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(width: c.value.size.width, height: c.value.size.height, child: VideoPlayer(c)),
        ),
      );
    }
    return ScaleTransition(
      scale: Tween<double>(begin: 1.0, end: 1.08).animate(CurvedAnimation(parent: _zoom, curve: Curves.easeOut)),
      child: Image.network(
        _url,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        frameBuilder: (_, child, frame, __) {
          if (frame != null) WidgetsBinding.instance.addPostFrameCallback((_) => _onReady());
          return AnimatedOpacity(opacity: frame == null ? 0 : 1, duration: const Duration(milliseconds: 350), child: child);
        },
        errorBuilder: (_, __, ___) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _close());
          return const SizedBox.expand();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasBottom = _title.isNotEmpty || _btnText.isNotEmpty;
    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            _media(),
            if (!_ready)
              const Center(
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white70),
                ),
              ),
            if (hasBottom)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(22, 80, 22, 26),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Color(0xCC000000)],
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    child: AnimatedSlide(
                      offset: _ready ? Offset.zero : const Offset(0, 0.3),
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOutCubic,
                      child: AnimatedOpacity(
                        opacity: _ready ? 1 : 0,
                        duration: const Duration(milliseconds: 500),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (_title.isNotEmpty)
                              Text(
                                _title,
                                style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800, height: 1.15),
                              ),
                            if (_title.isNotEmpty && _btnText.isNotEmpty) const SizedBox(height: 16),
                            if (_btnText.isNotEmpty)
                              SizedBox(
                                height: 56,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFFF6B00),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                                  ),
                                  onPressed: _tapButton,
                                  child: Text(_btnText),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            Positioned(
              top: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Material(
                    color: Colors.black.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(30),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(30),
                      onTap: _close,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        child: Text(
                          _ready ? trf('Пропустить · {0}', [_left]) : tr('Пропустить'),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
