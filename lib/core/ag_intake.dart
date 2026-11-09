// AG_INTAKE1 + AG_INTAKE3 (видео) + AG_INTAKE4 (плеер внутри приложения) — фото-приёмка авто: клиент видит, в каком состоянии сдал машину (фото мастера, пробег, топливо).
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart'; // AG_INTAKE4

import 'api_client.dart';
import 'theme.dart';
import '../core/i18n.dart'; // AG_I18N1

class AgIntakePhoto {
  AgIntakePhoto(Map j)
      : id = (j['id'] as num?)?.toInt() ?? 0,
        label = (j['label'] ?? tr('Фото')).toString(),
        note = j['note']?.toString(),
        url = (j['url'] ?? '').toString(),
        thumb = (j['thumb'] ?? j['url'] ?? '').toString(),
        isVideo = (j['type'] ?? '') == 'video';
  final int id;
  final bool isVideo;
  final String label;
  final String? note;
  final String url;
  final String thumb;
}

class AgIntakeSet {
  AgIntakeSet(Map j)
      : photos = [for (final p in (j['photos'] as List? ?? const [])) if (p is Map) AgIntakePhoto(p)],
        mileage = (j['mileage'] as num?)?.toInt(),
        fuel = j['fuel']?.toString(),
        comment = j['comment']?.toString(),
        master = j['master']?.toString(),
        takenAt = DateTime.tryParse((j['taken_at'] ?? '').toString())?.toLocal();
  final List<AgIntakePhoto> photos;
  final int? mileage;
  final String? fuel;
  final String? comment;
  final String? master;
  final DateTime? takenAt;
}

class AgIntake {
  static Future<Map<String, AgIntakeSet>>? _f;
  static DateTime _at = DateTime(2000);

  static Future<Map<String, AgIntakeSet>> load(ApiClient api, {bool force = false}) {
    if (force || _f == null || DateTime.now().difference(_at).inMinutes >= 2) {
      _at = DateTime.now();
      _f = api.get('/api/ag/intake/mine').then((r) {
        final b = r is Map ? r['bookings'] : null;
        final out = <String, AgIntakeSet>{};
        if (b is Map) {
          b.forEach((k, v) {
            if (v is Map) out[k.toString()] = AgIntakeSet(v);
          });
        }
        return out;
      }).catchError((Object _) => <String, AgIntakeSet>{});
    }
    return _f!;
  }
}

/// Полоска «Фото приёмки» в карточке записи. Если фото нет — ничего не показывает.
class AgIntakeStrip extends StatelessWidget {
  const AgIntakeStrip({super.key, required this.bookingId});
  final String bookingId;

  @override
  Widget build(BuildContext context) {
    final api = context.read<ApiClient>();
    return FutureBuilder<Map<String, AgIntakeSet>>(
      future: AgIntake.load(api),
      builder: (context, snap) {
        final set = snap.data?[bookingId];
        if (set == null || set.photos.isEmpty) return const SizedBox.shrink();
        final dark = Theme.of(context).brightness == Brightness.dark;
        final mut = dark ? const Color(0xFFA3AAB4) : const Color(0xFF69717D);
        final ink = dark ? const Color(0xFFF6F7F8) : const Color(0xFF15171C);
        return Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
          child: Material(
            color: BrandColors.orange.withValues(alpha: dark ? .10 : .06),
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => AgIntakeGallery.open(context, set, 0),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.photo_camera_outlined, size: 18, color: BrandColors.orange),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(AgIntakeGallery.title(set),
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: ink)),
                      ),
                      Text(tr('Смотреть'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: BrandColors.orange)),
                      const Icon(Icons.chevron_right_rounded, size: 18, color: BrandColors.orange),
                    ]),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 58,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: set.photos.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 6),
                        itemBuilder: (c, i) => GestureDetector(
                          onTap: () => AgIntakeGallery.open(context, set, i),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Stack(children: [
                              Image.network(set.photos[i].thumb, width: 76, height: 58, fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(width: 76, height: 58, color: set.photos[i].isVideo ? const Color(0xFF1F242C) : mut.withValues(alpha: .2),
                                      child: Icon(set.photos[i].isVideo ? Icons.videocam_rounded : Icons.image_not_supported_outlined, size: 20, color: set.photos[i].isVideo ? Colors.white70 : mut))),
                              if (set.photos[i].isVideo)
                                const Positioned.fill(
                                  child: Center(
                                    child: CircleAvatar(radius: 13, backgroundColor: BrandColors.orange,
                                        child: AgPlayIcon(size: 11)),
                                  ),
                                ),
                            ]),
                          ),
                        ),
                      ),
                    ),
                    if (set.mileage != null || (set.fuel ?? '').isNotEmpty) ...[
                      const SizedBox(height: 7),
                      Text(
                        [
                          if (set.mileage != null) trf('Пробег {0} км', [NumberFormat.decimalPattern(AgI18n.dateLocale).format(set.mileage)]),
                          if ((set.fuel ?? '').isNotEmpty) trf('Топливо {0}', [AgIntakeGallery.fuel(set.fuel!)]),
                        ].join(' · '),
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: mut),
                      ),
                    ],
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

class AgIntakeGallery extends StatefulWidget {
  const AgIntakeGallery({super.key, required this.set, required this.start});
  final AgIntakeSet set;
  final int start;

  static String title(AgIntakeSet s) {
    final v = s.photos.where((p) => p.isVideo).length, f = s.photos.length - v;
    return [if (f > 0) trf('Фото приёмки · {0}', [f]), if (v > 0) trf('видео · {0}', [v])].join(' · ');
  }

  static Future<void> play(String url) async {
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  static String fuel(String v) => {'0': tr('пусто'), '25': '¼', '50': '½', '75': '¾', '100': tr('полный')}[v] ?? v;

  static void open(BuildContext context, AgIntakeSet set, int i) {
    Navigator.of(context, rootNavigator: true).push(PageRouteBuilder(
      opaque: true,
      pageBuilder: (_, __, ___) => AgIntakeGallery(set: set, start: i),
      transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
    ));
  }

  @override
  State<AgIntakeGallery> createState() => _AgIntakeGalleryState();
}

class _AgIntakeGalleryState extends State<AgIntakeGallery> {
  late final PageController _pc = PageController(initialPage: widget.start);
  late int _i = widget.start;

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.set;
    final p = s.photos[_i];
    final info = [
      if (s.takenAt != null) DateFormat('d MMMM yyyy, HH:mm', AgI18n.dateLocale).format(s.takenAt!),
      if ((s.master ?? '').isNotEmpty) trf('принял {0}', [s.master]),
    ].join(' · ');
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              controller: _pc,
              itemCount: s.photos.length,
              onPageChanged: (v) => setState(() => _i = v),
              itemBuilder: (_, i) => s.photos[i].isVideo
                  ? AgIntakeVideo(key: ValueKey('v${s.photos[i].id}'), url: s.photos[i].url, poster: s.photos[i].thumb)
                  : InteractiveViewer(
                minScale: 1,
                maxScale: 5,
                child: Center(
                  child: Image.network(s.photos[i].url, fit: BoxFit.contain,
                      loadingBuilder: (c, w, ev) => ev == null ? w : const Center(child: CircularProgressIndicator(color: BrandColors.orange)),
                      errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_outlined, color: Colors.white54, size: 48)),
                ),
              ),
            ),
            Positioned(
              left: 8, right: 8, top: 4,
              child: Row(children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                  style: IconButton.styleFrom(backgroundColor: Colors.white.withValues(alpha: .12)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(p.isVideo ? tr('Видео приёмки') : tr('Фото приёмки'), style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
                    if (info.isNotEmpty)
                      Text(info, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70, fontSize: 12.5)),
                  ]),
                ),
                Text('${_i + 1} / ${s.photos.length}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                const SizedBox(width: 8),
              ]),
            ),
            Positioned(
              left: 12, right: 12, bottom: 12,
              child: Container(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                decoration: BoxDecoration(color: Colors.black.withValues(alpha: .6), borderRadius: BorderRadius.circular(16)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                  Text(p.isVideo && (p.note ?? '').isNotEmpty ? '${p.label} · ${p.note}' : p.label, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                  if ((p.note ?? '').isNotEmpty && !p.isVideo)
                    Padding(padding: const EdgeInsets.only(top: 3), child: Text(p.note!, style: const TextStyle(color: Colors.white, fontSize: 14))),
                  if (s.mileage != null || (s.fuel ?? '').isNotEmpty || (s.comment ?? '').isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        [
                          if (s.mileage != null) trf('Пробег {0} км', [NumberFormat.decimalPattern(AgI18n.dateLocale).format(s.mileage)]),
                          if ((s.fuel ?? '').isNotEmpty) trf('топливо {0}', [AgIntakeGallery.fuel(s.fuel!)]),
                          if ((s.comment ?? '').isNotEmpty) s.comment!,
                        ].join(' · '),
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Треугольник «играть» — рисуется, не зависит от шрифта иконок.
class AgPlayIcon extends StatelessWidget {
  const AgPlayIcon({super.key, this.size = 24, this.color = Colors.white, this.pause = false});
  final double size;
  final Color color;
  final bool pause;
  @override
  Widget build(BuildContext context) => CustomPaint(size: Size.square(size), painter: _PlayPainter(color, pause));
}

class _PlayPainter extends CustomPainter {
  _PlayPainter(this.color, this.pause);
  final Color color;
  final bool pause;
  @override
  void paint(Canvas c, Size s) {
    final p = Paint()..color = color;
    if (pause) {
      final w = s.width * .28;
      c.drawRRect(RRect.fromLTRBR(s.width * .12, 0, s.width * .12 + w, s.height, const Radius.circular(2)), p);
      c.drawRRect(RRect.fromLTRBR(s.width * .88 - w, 0, s.width * .88, s.height, const Radius.circular(2)), p);
    } else {
      final path = Path()
        ..moveTo(s.width * .18, 0)
        ..lineTo(s.width, s.height / 2)
        ..lineTo(s.width * .18, s.height)
        ..close();
      c.drawPath(path, p);
    }
  }

  @override
  bool shouldRepaint(_PlayPainter o) => o.color != color || o.pause != pause;
}

/// AG_INTAKE4: видео приёмки прямо в приложении — плей/пауза, перемотка, время.
class AgIntakeVideo extends StatefulWidget {
  const AgIntakeVideo({super.key, required this.url, required this.poster});
  final String url;
  final String poster;
  @override
  State<AgIntakeVideo> createState() => _AgIntakeVideoState();
}

class _AgIntakeVideoState extends State<AgIntakeVideo> {
  VideoPlayerController? _c;
  bool _loading = false, _failed = false;

  Future<void> _start() async {
    if (_c != null) {
      final v = _c!.value;
      if (v.isPlaying) {
        await _c!.pause();
      } else {
        if (v.position >= v.duration && v.duration > Duration.zero) await _c!.seekTo(Duration.zero);
        await _c!.play();
      }
      if (mounted) setState(() {});
      return;
    }
    setState(() => _loading = true);
    final c = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    try {
      await c.initialize();
      c.addListener(() {
        if (mounted) setState(() {});
      });
      if (!mounted) {
        await c.dispose();
        return;
      }
      setState(() {
        _c = c;
        _loading = false;
      });
      await c.play();
    } catch (_) {
      await c.dispose();
      if (mounted) {
        setState(() {
          _loading = false;
          _failed = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _c?.dispose();
    super.dispose();
  }

  String _t(Duration d) => '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final c = _c;
    final ready = c != null && c.value.isInitialized;
    final playing = ready && c.value.isPlaying;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _failed ? null : _start,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: ready
                ? Center(child: AspectRatio(aspectRatio: c.value.aspectRatio, child: VideoPlayer(c)))
                : Image.network(widget.poster, fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const ColoredBox(color: Color(0xFF14171C))),
          ),
          if (_loading)
            const SizedBox(width: 56, height: 56, child: CircularProgressIndicator(color: BrandColors.orange, strokeWidth: 4))
          else if (_failed)
            Column(mainAxisSize: MainAxisSize.min, children: [
              Text(tr('Видео не открылось в приложении'), style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: BrandColors.orange),
                onPressed: () => AgIntakeGallery.play(widget.url),
                child: Text(tr('Открыть в браузере')),
              ),
            ])
          else if (!playing)
            Container(
              width: 84,
              height: 84,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: BrandColors.orange, shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .4), blurRadius: 24)]),
              child: const Padding(padding: EdgeInsets.only(left: 6), child: AgPlayIcon(size: 34)),
            ),
          if (ready)
            Positioned(
              left: 16,
              right: 16,
              bottom: 110,
              child: Row(children: [
                GestureDetector(
                  onTap: _start,
                  child: Padding(padding: const EdgeInsets.all(6), child: AgPlayIcon(size: 18, pause: playing)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: VideoProgressIndicator(c, allowScrubbing: true, padding: const EdgeInsets.symmetric(vertical: 10),
                      colors: VideoProgressColors(playedColor: BrandColors.orange, bufferedColor: Colors.white38, backgroundColor: Colors.white12)),
                ),
                const SizedBox(width: 10),
                Text('${_t(c.value.position)} / ${_t(c.value.duration)}',
                    style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w700)),
              ]),
            )
          else if (!_failed)
            Positioned(
              bottom: 120,
              child: Text(tr('Нажмите, чтобы смотреть видео'), style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            ),
        ],
      ),
    );
  }
}
