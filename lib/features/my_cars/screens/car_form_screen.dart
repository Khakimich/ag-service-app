// AG_CARFORM2 — «Добавить авто»: оранжевая шапка с 3D-машиной, белые карточки,
// все иконки — SVG (без шрифтовых значков), живой предпросмотр госномера, кнопка закреплена снизу.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../../core/ag_icon3d.dart';
import '../../../core/theme.dart';
import '../../../models/user_car.dart';
import '../providers/my_cars_provider.dart';
import '../../../core/i18n.dart'; // AG_I18N1

const _orange = BrandColors.orange;

class _Ico {
  static String _l(String p, [String c = '#FF6A00', double w = 2]) =>
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="$c" stroke-width="$w" stroke-linecap="round" stroke-linejoin="round">$p</svg>';
  static final back = _l('<path d="M15 5l-7 7 7 7"/>', '#FFFFFF', 2.6);
  static final brand = _l('<circle cx="12" cy="12" r="8.5"/><path d="M12 3.5v4M12 16.5v4M3.5 12h4M16.5 12h4"/><circle cx="12" cy="12" r="2.2"/>');
  static final model = _l('<path d="M4 16v-3.5l1.8-4.6A2 2 0 0 1 7.7 6.6h8.6a2 2 0 0 1 1.9 1.3L20 12.5V16"/><path d="M3 12.5h18v4a1 1 0 0 1-1 1H4a1 1 0 0 1-1-1z"/><circle cx="7.5" cy="17.5" r="1.6"/><circle cx="16.5" cy="17.5" r="1.6"/>');
  static final vin = _l('<rect x="3" y="5" width="18" height="14" rx="3"/><path d="M7 9.5v5M10 9.5v5M13 9.5v5M16.5 9.5v5"/>');
  static final year = _l('<rect x="3.5" y="5" width="17" height="15.5" rx="3"/><path d="M3.5 10h17M8 3v4M16 3v4"/><path d="M8 14h3"/>');
  static final plate = _l('<rect x="2.5" y="7" width="19" height="10" rx="2.2"/><path d="M6 12h6"/><path d="M15.5 9.5v5"/>');
  static final shield = _l('<path d="M12 3l7 3v5c0 4.5-3 8.2-7 10-4-1.8-7-5.5-7-10V6z"/><path d="M9 12l2 2 4-4"/>', '#16A34A');
  static final down = _l('<path d="M6 9l6 6 6-6"/>', '#9CA3AF', 2.4);
  static final search = _l('<circle cx="11" cy="11" r="6.5"/><path d="M20 20l-4.2-4.2"/>', '#9CA3AF', 2.2);
  static final check = _l('<path d="M5 12.5l4.5 4.5L19 7.5"/>', '#FF6A00', 2.8);
  static final plusO = _l('<path d="M12 5v14M5 12h14"/>', '#FF6A00', 2.6);
  static final ok = _l('<path d="M5 12.5l4.5 4.5L19 7.5"/>', '#FFFFFF', 3);
  static final plus = _l('<path d="M12 5v14M5 12h14"/>', '#FFFFFF', 2.8);
}

Widget _svg(String s, double size) => SvgPicture.string(s, width: size, height: size);

class CarFormScreen extends StatefulWidget {
  const CarFormScreen({super.key, this.car});

  final UserCar? car;

  @override
  State<CarFormScreen> createState() => _CarFormScreenState();
}

class _CarFormScreenState extends State<CarFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _makeCtrl;
  late final TextEditingController _modelCtrl;
  late final TextEditingController _vinCtrl;
  late final TextEditingController _yearCtrl;
  late final TextEditingController _plateCtrl;

  late final bool _isEditing;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.car != null;
    _makeCtrl = TextEditingController(text: widget.car?.make ?? '');
    _modelCtrl = TextEditingController(text: widget.car?.model ?? '');
    _vinCtrl = TextEditingController(text: widget.car?.vinCode ?? '');
    _yearCtrl = TextEditingController(text: widget.car?.year?.toString() ?? '');
    _plateCtrl = TextEditingController(text: widget.car?.licensePlate ?? '');
    for (final c in [_makeCtrl, _modelCtrl, _vinCtrl, _yearCtrl, _plateCtrl]) {
      c.addListener(_refresh);
    }
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    for (final c in [_makeCtrl, _modelCtrl, _vinCtrl, _yearCtrl, _plateCtrl]) {
      c.removeListener(_refresh);
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);

    final provider = context.read<MyCarsProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final year = int.tryParse(_yearCtrl.text.trim());

    final ok = _isEditing
        ? await provider.updateCar(
            id: widget.car!.id,
            make: _makeCtrl.text.trim(),
            model: _modelCtrl.text.trim(),
            vinCode: _vinCtrl.text.trim(),
            year: year,
            licensePlate: _plateCtrl.text.trim(),
          )
        : await provider.addCar(
            make: _makeCtrl.text.trim(),
            model: _modelCtrl.text.trim(),
            vinCode: _vinCtrl.text.trim(),
            year: year,
            licensePlate: _plateCtrl.text.trim(),
          );

    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      Navigator.pop(context);
      return;
    }
    messenger.showSnackBar(SnackBar(
      behavior: SnackBarBehavior.floating,
      content: Text(_isEditing ? tr('Не удалось обновить автомобиль') : tr('Не удалось добавить автомобиль')),
    ));
  }

  String? _vinValidator(String? value) {
    final vin = value?.trim() ?? '';
    if (vin.isEmpty) return null;
    if (vin.length != 17) return tr('VIN должен содержать 17 символов');
    if (RegExp(r'[IOQ]', caseSensitive: false).hasMatch(vin)) return tr('VIN не должен содержать I, O или Q');
    return null;
  }

  String? _yearValidator(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    final year = int.tryParse(text);
    if (year == null || year < 1900 || year > DateTime.now().year + 1) return tr('Проверьте год выпуска');
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final top = MediaQuery.paddingOf(context).top;
    final title = [_makeCtrl.text.trim(), _modelCtrl.text.trim()].where((e) => e.isNotEmpty).join(' ');

    return Scaffold(
      backgroundColor: dark ? const Color(0xFF111113) : const Color(0xFFF6F6F8),
      body: Column(children: [
        Expanded(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: EdgeInsets.zero,
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              children: [
                // ── шапка
                Container(
                  padding: EdgeInsets.fromLTRB(18, top + 8, 18, 36),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
                        colors: [Color(0xFFFF8A2A), Color(0xFFFF6A00), Color(0xFFE85500)]),
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 40, height: 40, alignment: Alignment.center,
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: .2), borderRadius: BorderRadius.circular(14)),
                        child: _svg(_Ico.back, 20),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(children: [
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(_isEditing ? tr('Редактировать авто') : tr('Добавить авто'),
                              style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: -.6)),
                          const SizedBox(height: 6),
                          Text(
                            title.isEmpty ? tr('После этого записываться в сервис будет быстрее') : title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: Colors.white.withValues(alpha: .92), fontSize: 14.5, height: 1.3, fontWeight: FontWeight.w700),
                          ),
                        ]),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        width: 76, height: 76, alignment: Alignment.center,
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .12), blurRadius: 18, offset: const Offset(0, 8))]),
                        child: const AgIcon3D('car', size: 56),
                      ),
                    ]),
                  ]),
                ),
                Transform.translate(
                  offset: const Offset(0, -18),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      _Card(
                        title: tr('Основная информация'),
                        children: [
                          _BrandField(
                            controller: _makeCtrl,
                            validator: (v) => (v == null || v.trim().isEmpty) ? tr('Выберите марку автомобиля') : null,
                          ),
                          const SizedBox(height: 12),
                          _Field(
                            controller: _modelCtrl,
                            icon: _Ico.model,
                            label: tr('Модель'),
                            hint: tr('Например, Solaris или Rapid'),
                            caps: TextCapitalization.words,
                            validator: (v) => (v == null || v.trim().isEmpty) ? tr('Укажите модель автомобиля') : null,
                          ),
                        ],
                      ),
                      _Card(
                        title: tr('Данные автомобиля'),
                        subtitle: tr('Можно заполнить позже — помогут быстрее оформить запись'),
                        children: [
                          _Field(
                            controller: _vinCtrl,
                            icon: _Ico.vin,
                            label: tr('VIN-код'),
                            hint: 'JTHBW1GG7E2052333',
                            caps: TextCapitalization.characters,
                            trailing: _VinBadge(length: _vinCtrl.text.trim().length),
                            formatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                              LengthLimitingTextInputFormatter(17),
                              _UpperCaseTextFormatter(),
                            ],
                            validator: _vinValidator,
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 4, top: 6),
                            child: Text(tr('17 символов без букв I, O и Q'),
                                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant, fontWeight: FontWeight.w600)),
                          ),
                          const SizedBox(height: 12),
                          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Expanded(
                              flex: 4,
                              child: _Field(
                                controller: _yearCtrl,
                                icon: _Ico.year,
                                label: tr('Год'),
                                hint: '2019',
                                keyboard: TextInputType.number,
                                formatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)],
                                validator: _yearValidator,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 6,
                              child: _Field(
                                controller: _plateCtrl,
                                icon: _Ico.plate,
                                label: tr('Госномер'),
                                hint: 'C859HP196',
                                caps: TextCapitalization.characters,
                                formatters: [
                                  FilteringTextInputFormatter.allow(RegExp(r'[A-Za-zА-Яа-я0-9]')),
                                  _UpperCaseTextFormatter(),
                                ],
                              ),
                            ),
                          ]),
                          if (_plateCtrl.text.trim().isNotEmpty) ...[
                            const SizedBox(height: 14),
                            Center(child: _PlatePreview(text: _plateCtrl.text.trim())),
                          ],
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: const Color(0xFFE8F7EE), borderRadius: BorderRadius.circular(16)),
                        child: Row(children: [
                          _svg(_Ico.shield, 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(tr('Данные автомобиля используются только для вашего гаража и записи в сервис.'),
                                style: const TextStyle(fontSize: 12.5, height: 1.35, fontWeight: FontWeight.w600, color: Color(0xFF166534))),
                          ),
                        ]),
                      ),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ),
        // ── кнопка снизу
        Container(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + MediaQuery.paddingOf(context).bottom),
          decoration: BoxDecoration(
            color: dark ? const Color(0xFF1B1E22) : Colors.white,
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .06), blurRadius: 16, offset: const Offset(0, -4))],
          ),
          child: SizedBox(
            height: 56,
            width: double.infinity,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: const LinearGradient(colors: [Color(0xFFFF8A2A), Color(0xFFFF6A00)]),
                boxShadow: [BoxShadow(color: _orange.withValues(alpha: .35), blurRadius: 16, offset: const Offset(0, 6))],
              ),
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  disabledBackgroundColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                ),
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.6, color: Colors.white))
                    : Row(mainAxisSize: MainAxisSize.min, children: [
                        _svg(_isEditing ? _Ico.ok : _Ico.plus, 20),
                        const SizedBox(width: 8),
                        Text(_isEditing ? tr('Сохранить изменения') : tr('Добавить в гараж'),
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Colors.white)),
                      ]),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.title, required this.children, this.subtitle});
  final String title;
  final String? subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF1B1E22) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .05), blurRadius: 20, offset: const Offset(0, 6))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(title, style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w900, letterSpacing: -.3)),
        if (subtitle != null) ...[
          const SizedBox(height: 3),
          Text(subtitle!, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ],
        const SizedBox(height: 12),
        ...children,
      ]),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.icon,
    required this.label,
    required this.hint,
    this.caps = TextCapitalization.none,
    this.keyboard,
    this.formatters,
    this.validator,
    this.trailing,
  });

  final TextEditingController controller;
  final String icon, label, hint;
  final TextCapitalization caps;
  final TextInputType? keyboard;
  final List<TextInputFormatter>? formatters;
  final FormFieldValidator<String>? validator;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    OutlineInputBorder b(Color c, [double w = 1.2]) =>
        OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: c, width: w));
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 6),
        child: Text(label, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: cs.onSurfaceVariant)),
      ),
      TextFormField(
        controller: controller,
        keyboardType: keyboard,
        textCapitalization: caps,
        inputFormatters: formatters,
        validator: validator,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: .2),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: .6), fontWeight: FontWeight.w500),
          filled: true,
          fillColor: dark ? const Color(0xFF24282D) : const Color(0xFFF6F6F8),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          prefixIcon: Padding(padding: const EdgeInsets.only(left: 14, right: 10), child: _svg(icon, 21)),
          prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
          suffixIcon: trailing == null ? null : Padding(padding: const EdgeInsets.only(right: 10), child: trailing),
          suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
          enabledBorder: b(Colors.transparent),
          focusedBorder: b(_orange, 1.6),
          errorBorder: b(const Color(0xFFDC2626)),
          focusedErrorBorder: b(const Color(0xFFDC2626), 1.6),
          border: b(Colors.transparent),
        ),
      ),
    ]);
  }
}

/// Счётчик VIN: серый → оранжевый → зелёный, когда введены все 17 символов.
class _VinBadge extends StatelessWidget {
  const _VinBadge({required this.length});
  final int length;

  @override
  Widget build(BuildContext context) {
    final done = length == 17;
    final color = done ? const Color(0xFF16A34A) : (length == 0 ? const Color(0xFF9CA3AF) : _orange);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: .12), borderRadius: BorderRadius.circular(10)),
      child: Text('$length/17', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: color)),
    );
  }
}

/// Предпросмотр российского госномера.
class _PlatePreview extends StatelessWidget {
  const _PlatePreview({required this.text});
  final String text;

  static const _flag =
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 12 8"><rect width="12" height="8" fill="#fff" stroke="#ccc" stroke-width=".4"/><rect y="2.67" width="12" height="2.67" fill="#1C57D9"/><rect y="5.33" width="12" height="2.67" fill="#E4262E"/></svg>';

  @override
  Widget build(BuildContext context) {
    final t = text.toUpperCase();
    // серия+номер и регион (последние 2–3 цифры, если номер полный)
    final m = RegExp(r'^([A-ZА-Я]\d{3}[A-ZА-Я]{2})(\d{2,3})$').firstMatch(t);
    final main = m?.group(1) ?? t;
    final region = m?.group(2) ?? '';
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: const Color(0xFF111111), width: 2),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .08), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(main,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: 1.5, color: Color(0xFF111111))),
        ),
        if (region.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: const BoxDecoration(border: Border(left: BorderSide(color: Color(0xFF111111), width: 2))),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(region, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, height: 1, color: Color(0xFF111111))),
              const SizedBox(height: 2),
              Row(mainAxisSize: MainAxisSize.min, children: [
                const Text('RUS', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Color(0xFF111111))),
                const SizedBox(width: 2),
                SvgPicture.string(_flag, width: 11, height: 7),
              ]),
            ]),
          ),
      ]),
    );
  }
}

// ───────────── AG_CARFORM3: выбор марки из списка с логотипами ─────────────

class _Brand {
  const _Brand(this.name, this.slug);
  final String name, slug;
}

/// Популярные в России марки — показываются сеткой сверху.
const _popular = <_Brand>[
  _Brand('Lada', 'lada'), _Brand('Kia', 'kia'), _Brand('Hyundai', 'hyundai'), _Brand('Toyota', 'toyota'),
  _Brand('Volkswagen', 'volkswagen'), _Brand('Skoda', 'skoda'), _Brand('Renault', 'renault'), _Brand('Nissan', 'nissan'),
  _Brand('Chery', 'chery'), _Brand('Haval', 'haval'), _Brand('Geely', 'geely'), _Brand('Changan', 'changan'),
  _Brand('Exeed', 'exeed'), _Brand('Omoda', 'omoda'), _Brand('Jetour', 'jetour'), _Brand('Mitsubishi', 'mitsubishi'),
  _Brand('Mazda', 'mazda'), _Brand('Ford', 'ford'), _Brand('Chevrolet', 'chevrolet'), _Brand('BMW', 'bmw'),
  _Brand('Mercedes-Benz', 'mercedes-benz'), _Brand('Audi', 'audi'), _Brand('Lexus', 'lexus'), _Brand('Honda', 'honda'),
];

/// Русские названия марок для поиска («тойота» → Toyota).
const _ruAlias = <String, String>{
  'лада': 'lada', 'ваз': 'lada', 'киа': 'kia', 'хендай': 'hyundai', 'хёндэ': 'hyundai', 'хундай': 'hyundai',
  'тойота': 'toyota', 'фольксваген': 'volkswagen', 'шкода': 'skoda', 'рено': 'renault', 'ниссан': 'nissan',
  'чери': 'chery', 'хавал': 'haval', 'джили': 'geely', 'чанган': 'changan', 'эксид': 'exeed', 'омода': 'omoda',
  'джетур': 'jetour', 'митсубиси': 'mitsubishi', 'мицубиси': 'mitsubishi', 'мазда': 'mazda', 'форд': 'ford',
  'шевроле': 'chevrolet', 'бмв': 'bmw', 'мерседес': 'mercedes-benz', 'ауди': 'audi', 'лексус': 'lexus', 'хонда': 'honda',
  'опель': 'opel', 'пежо': 'peugeot', 'ситроен': 'citroen', 'сузуки': 'suzuki', 'субару': 'subaru', 'вольво': 'volvo',
  'уаз': 'uaz', 'газ': 'gaz', 'дэу': 'daewoo', 'деу': 'daewoo', 'инфинити': 'infiniti', 'порше': 'porsche',
  'датсун': 'datsun', 'джак': 'jac', 'донгфенг': 'dongfeng', 'фав': 'faw', 'зикр': 'zeekr', 'генезис': 'genesis',
};

List<_Brand>? _allBrandsCache;

Future<List<_Brand>> _loadBrands() async {
  if (_allBrandsCache != null) return _allBrandsCache!;
  try {
    final raw = await rootBundle.loadString('assets/car_logos/data.json');
    final list = (jsonDecode(raw) as List)
        .whereType<Map>()
        .map((e) => _Brand((e['name'] ?? '').toString(), (e['slug'] ?? '').toString()))
        .where((b) => b.name.isNotEmpty && b.slug.isNotEmpty)
        .toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return _allBrandsCache = list;
  } catch (_) {
    return _allBrandsCache = List.of(_popular);
  }
}

String _slugOf(String name) => name.trim().toLowerCase().replaceAll('&', 'and').replaceAll(RegExp(r'[^a-z0-9]+'), '-').replaceAll(RegExp(r'^-+|-+$'), '');

class _BrandLogo extends StatelessWidget {
  const _BrandLogo({required this.name, this.size = 36});
  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final slug = _ruAlias[name.trim().toLowerCase()] ?? _slugOf(name);
    final letter = Text(name.isEmpty ? '?' : name.characters.first.toUpperCase(),
        style: TextStyle(fontSize: size * .45, fontWeight: FontWeight.w900, color: _orange));
    if (slug.isEmpty) return SizedBox(width: size, height: size, child: Center(child: letter));
    return Image.asset('assets/car_logos/$slug.png',
        width: size, height: size, fit: BoxFit.contain, filterQuality: FilterQuality.high,
        errorBuilder: (_, __, ___) => SizedBox(width: size, height: size, child: Center(child: letter)));
  }
}

/// Поле «Марка»: по нажатию открывается список марок с логотипами и поиском.
class _BrandField extends StatelessWidget {
  const _BrandField({required this.controller, this.validator});
  final TextEditingController controller;
  final FormFieldValidator<String>? validator;

  Future<void> _open(BuildContext context) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BrandSheet(current: controller.text),
    );
    if (picked != null && picked.trim().isNotEmpty) controller.text = picked.trim();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    OutlineInputBorder b(Color c, [double w = 1.2]) =>
        OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: c, width: w));
    final name = controller.text.trim();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 6),
        child: Text(tr('Марка'), style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: cs.onSurfaceVariant)),
      ),
      TextFormField(
        controller: controller,
        readOnly: true,
        onTap: () => _open(context),
        validator: validator,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        decoration: InputDecoration(
          hintText: tr('Выберите марку'),
          hintStyle: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: .6), fontWeight: FontWeight.w500),
          filled: true,
          fillColor: dark ? const Color(0xFF24282D) : const Color(0xFFF6F6F8),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 10, right: 8),
            child: name.isEmpty ? Padding(padding: const EdgeInsets.all(4), child: _svg(_Ico.brand, 21)) : _BrandLogo(name: name, size: 30),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
          suffixIcon: Padding(padding: const EdgeInsets.only(right: 12), child: _svg(_Ico.down, 18)),
          suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
          enabledBorder: b(Colors.transparent),
          focusedBorder: b(_orange, 1.6),
          errorBorder: b(const Color(0xFFDC2626)),
          focusedErrorBorder: b(const Color(0xFFDC2626), 1.6),
          border: b(Colors.transparent),
        ),
      ),
    ]);
  }
}

class _BrandSheet extends StatefulWidget {
  const _BrandSheet({required this.current});
  final String current;
  @override
  State<_BrandSheet> createState() => _BrandSheetState();
}

class _BrandSheetState extends State<_BrandSheet> {
  final _q = TextEditingController();
  List<_Brand> _all = const [];

  @override
  void initState() {
    super.initState();
    _loadBrands().then((v) {
      if (mounted) setState(() => _all = v);
    });
    _q.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  List<_Brand> get _found {
    final q = _q.text.trim().toLowerCase();
    if (q.isEmpty) return _all;
    final alias = _ruAlias.entries.where((e) => e.key.startsWith(q)).map((e) => e.value).toSet();
    return _all.where((b) => b.name.toLowerCase().contains(q) || alias.contains(b.slug)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final bg = dark ? const Color(0xFF1B1E22) : Colors.white;
    final searching = _q.text.trim().isNotEmpty;
    final found = _found;
    final h = MediaQuery.sizeOf(context).height * .86;

    return Container(
      height: h,
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      decoration: BoxDecoration(color: bg, borderRadius: const BorderRadius.vertical(top: Radius.circular(28))),
      child: Column(children: [
        const SizedBox(height: 10),
        Container(width: 40, height: 5, decoration: BoxDecoration(color: cs.outlineVariant, borderRadius: BorderRadius.circular(3))),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
          child: Row(children: [
            Expanded(child: Text(tr('Марка автомобиля'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -.4))),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: _q,
            autofocus: false,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: tr('Поиск: Kia, Тойота, Lada…'),
              filled: true,
              fillColor: dark ? const Color(0xFF24282D) : const Color(0xFFF6F6F8),
              prefixIcon: Padding(padding: const EdgeInsets.only(left: 14, right: 10), child: _svg(_Ico.search, 20)),
              prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
            children: [
              if (!searching) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(6, 6, 6, 10),
                  child: Text(tr('Популярные'), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: cs.onSurfaceVariant)),
                ),
                GridView.count(
                  crossAxisCount: 4,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: .95,
                  children: [
                    for (final b in _popular)
                      _BrandTile(brand: b, selected: b.name.toLowerCase() == widget.current.trim().toLowerCase(),
                          onTap: () => Navigator.pop(context, b.name)),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(6, 18, 6, 6),
                  child: Text(tr('Все марки'), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: cs.onSurfaceVariant)),
                ),
              ],
              if (_all.isEmpty)
                const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator(color: _orange)))
              else
                for (final b in found)
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    leading: _BrandLogo(name: b.name, size: 34),
                    title: Text(b.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                    trailing: b.name.toLowerCase() == widget.current.trim().toLowerCase() ? _svg(_Ico.check, 20) : null,
                    onTap: () => Navigator.pop(context, b.name),
                  ),
              if (searching)
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  leading: Container(
                    width: 34, height: 34, alignment: Alignment.center,
                    decoration: BoxDecoration(color: _orange.withValues(alpha: .1), borderRadius: BorderRadius.circular(10)),
                    child: _svg(_Ico.plusO, 18),
                  ),
                  title: Text(trf('Указать «{0}»', [_q.text.trim()]), style: const TextStyle(fontWeight: FontWeight.w800, color: _orange)),
                  subtitle: Text(tr('Если вашей марки нет в списке')),
                  onTap: () => Navigator.pop(context, _q.text.trim()),
                ),
            ],
          ),
        ),
      ]),
    );
  }
}

class _BrandTile extends StatelessWidget {
  const _BrandTile({required this.brand, required this.selected, required this.onTap});
  final _Brand brand;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: selected ? _orange.withValues(alpha: .1) : (dark ? const Color(0xFF24282D) : const Color(0xFFF6F6F8)),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: selected ? _orange : Colors.transparent, width: 1.5),
          ),
          padding: const EdgeInsets.all(6),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            _BrandLogo(name: brand.name, size: 38),
            const SizedBox(height: 6),
            Text(brand.name, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800)),
          ]),
        ),
      ),
    );
  }
}

class _UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    return newValue.copyWith(text: newValue.text.toUpperCase(), selection: newValue.selection);
  }
}
