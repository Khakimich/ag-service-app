// AG_CARFORM2 — «Добавить авто»: оранжевая шапка с 3D-машиной, белые карточки,
// все иконки — SVG (без шрифтовых значков), живой предпросмотр госномера, кнопка закреплена снизу.
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
                          _Field(
                            controller: _makeCtrl,
                            icon: _Ico.brand,
                            label: tr('Марка'),
                            hint: tr('Например, Hyundai или Skoda'),
                            caps: TextCapitalization.words,
                            validator: (v) => (v == null || v.trim().isEmpty) ? tr('Укажите марку автомобиля') : null,
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

class _UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    return newValue.copyWith(text: newValue.text.toUpperCase(), selection: newValue.selection);
  }
}
