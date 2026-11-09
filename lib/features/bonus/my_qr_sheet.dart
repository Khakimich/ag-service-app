// AG_BONUSQR1 — «Мой QR»: одноразовый код для списания бонусов на кассе.
// Код живёт 2 минуты, обновляется сам каждые 90 секунд. Списать по одному коду можно один раз.
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/api_client.dart';
import '../../core/i18n.dart';

Future<void> showMyBonusQr(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _MyQrSheet(),
  );
}

class _MyQrSheet extends StatefulWidget {
  const _MyQrSheet();
  @override
  State<_MyQrSheet> createState() => _MyQrSheetState();
}

class _MyQrSheetState extends State<_MyQrSheet> {
  String? _token;
  int? _balance;
  String? _error;
  int _left = 0;
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _load();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _left = _left > 0 ? _left - 1 : 0);
      if (_left == 30 || (_left == 0 && _token != null)) _load(); // обновляем заранее
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final r = await context.read<ApiClient>().get('/api/ag/bonus/my-qr');
      if (!mounted) return;
      if (r is Map && r['token'] is String) {
        setState(() {
          _token = r['token'] as String;
          _balance = (r['balance'] as num?)?.toInt();
          _left = (r['ttl'] as num?)?.toInt() ?? 120;
          _error = null;
        });
      } else {
        setState(() => _error = tr('Не удалось получить QR-код'));
      }
    } catch (_) {
      if (mounted) setState(() => _error = tr('Нет связи. Проверьте интернет'));
    }
  }

  String _fmt(int n) {
    final s = n.abs().toString();
    final b = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write(' ');
      b.write(s[i]);
    }
    return b.toString();
  }

  @override
  Widget build(BuildContext context) {
    const orange = Color(0xFFF26200);
    return Container(
      padding: EdgeInsets.fromLTRB(22, 12, 22, 22 + MediaQuery.of(context).padding.bottom),
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 42, height: 5, decoration: BoxDecoration(color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(9))),
        const SizedBox(height: 16),
        Text(tr('Оплата бонусами'), style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900, color: Color(0xFF15171C))),
        const SizedBox(height: 6),
        Text(tr('Покажите этот код администратору на кассе'),
            textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280), fontWeight: FontWeight.w600)),
        const SizedBox(height: 18),
        Container(
          width: 260,
          height: 260,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: orange.withValues(alpha: .35), width: 2),
            boxShadow: [BoxShadow(color: orange.withValues(alpha: .15), blurRadius: 24, offset: const Offset(0, 10))],
          ),
          alignment: Alignment.center,
          child: _token != null
              ? QrImageView(data: _token!, version: QrVersions.auto, size: 228, gapless: true,
                  eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Color(0xFF15171C)),
                  dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Color(0xFF15171C)))
              : _error != null
                  ? Column(mainAxisSize: MainAxisSize.min, children: [
                      Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.w700)),
                      const SizedBox(height: 10),
                      TextButton(onPressed: _load, child: Text(tr('Повторить'))),
                    ])
                  : const CircularProgressIndicator(color: orange),
        ),
        const SizedBox(height: 14),
        if (_token != null)
          Text(trf('Код обновится через {0} сек', [_left]),
              style: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF), fontWeight: FontWeight.w600)),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(color: const Color(0xFFFFF4EC), borderRadius: BorderRadius.circular(18)),
          child: Row(children: [
            Text(tr('Бонусный счёт'), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF6B4A33))),
            const Spacer(),
            Text(_balance == null ? '—' : '${_fmt(_balance!)} ₽',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: orange)),
          ]),
        ),
        const SizedBox(height: 10),
        Text(tr('Никому не пересылайте этот код. После списания придёт уведомление.'),
            textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
      ]),
    );
  }
}
