import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../../core/theme.dart';
import '../../../models/user_car.dart';
import '../providers/my_cars_provider.dart';
import '../../../core/i18n.dart'; // AG_I18N1

class CarFormScreen extends StatefulWidget {
  const CarFormScreen({super.key, this.car});

  final UserCar? car;

  @override
  State<CarFormScreen> createState() => _CarFormScreenState();
}

class _CarFormScreenState extends State<CarFormScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _makeCtrl;
  late final TextEditingController _modelCtrl;
  late final TextEditingController _vinCtrl;
  late final TextEditingController _yearCtrl;
  late final TextEditingController _plateCtrl;

  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

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

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, .035),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _animationController.forward();

    _vinCtrl.addListener(_refresh);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _vinCtrl.removeListener(_refresh);
    _animationController.dispose();
    _makeCtrl.dispose();
    _modelCtrl.dispose();
    _vinCtrl.dispose();
    _yearCtrl.dispose();
    _plateCtrl.dispose();
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

    bool ok;

    if (_isEditing) {
      ok = await provider.updateCar(
        id: widget.car!.id,
        make: _makeCtrl.text.trim(),
        model: _modelCtrl.text.trim(),
        vinCode: _vinCtrl.text.trim(),
        year: year,
        licensePlate: _plateCtrl.text.trim(),
      );
    } else {
      ok = await provider.addCar(
        make: _makeCtrl.text.trim(),
        model: _modelCtrl.text.trim(),
        vinCode: _vinCtrl.text.trim(),
        year: year,
        licensePlate: _plateCtrl.text.trim(),
      );
    }

    if (!mounted) return;

    setState(() => _saving = false);

    if (ok) {
      Navigator.pop(context);
      return;
    }

    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(
          _isEditing
              ? tr('Не удалось обновить автомобиль')
              : tr('Не удалось добавить автомобиль'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(
              title: _isEditing ? tr('Редактировать авто') : tr('Добавить авто'),
              onBack: () => Navigator.pop(context),
            ),
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 720),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _IntroCard(isEditing: _isEditing),
                              const SizedBox(height: 22),

                              _SectionLabel(
                                title: tr('Основная информация'),
                                subtitle: tr('Укажите марку и модель автомобиля'),
                              ),
                              const SizedBox(height: 12),

                              _PremiumField(
                                controller: _makeCtrl,
                                iconAsset: 'assets/icons/car_form/brand.svg',
                                label: tr('Марка'),
                                hint: tr('Например, Hyundai или Skoda'),
                                helper: tr('Название производителя автомобиля'),
                                textCapitalization: TextCapitalization.words,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return tr('Укажите марку автомобиля');
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 14),

                              _PremiumField(
                                controller: _modelCtrl,
                                iconAsset: 'assets/icons/car_form/model.svg',
                                label: tr('Модель'),
                                hint: tr('Например, Solaris или Rapid'),
                                helper:
                                    tr('Укажите модель так, как она называется'),
                                textCapitalization: TextCapitalization.words,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return tr('Укажите модель автомобиля');
                                  }
                                  return null;
                                },
                              ),

                              const SizedBox(height: 26),

                              _SectionLabel(
                                title: tr('Данные автомобиля'),
                                subtitle:
                                    tr('Эти данные помогут быстрее оформить запись'),
                              ),
                              const SizedBox(height: 12),

                              _PremiumField(
                                controller: _vinCtrl,
                                iconAsset: 'assets/icons/car_form/vin.svg',
                                label: tr('VIN-код'),
                                hint: tr('Например, JTHBW1GG7E2052333'),
                                helper: tr('17 символов без букв I, O и Q'),
                                textCapitalization:
                                    TextCapitalization.characters,
                                maxLength: 17,
                                suffix: _VinStatus(
                                  length: _vinCtrl.text.trim().length,
                                ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'[A-Za-z0-9]'),
                                  ),
                                  LengthLimitingTextInputFormatter(17),
                                  _UpperCaseTextFormatter(),
                                ],
                                validator: (value) {
                                  final vin = value?.trim() ?? '';

                                  if (vin.isEmpty) return null;

                                  if (vin.length != 17) {
                                    return tr('VIN должен содержать 17 символов');
                                  }

                                  if (RegExp(
                                    r'[IOQ]',
                                    caseSensitive: false,
                                  ).hasMatch(vin)) {
                                    return tr('VIN не должен содержать I, O или Q');
                                  }

                                  return null;
                                },
                              ),
                              const SizedBox(height: 14),

                              _PremiumField(
                                controller: _yearCtrl,
                                iconAsset: 'assets/icons/car_form/year.svg',
                                label: tr('Год выпуска'),
                                hint: tr('Например, 2019'),
                                helper: tr('Год выпуска автомобиля по документам'),
                                keyboardType: TextInputType.number,
                                maxLength: 4,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(4),
                                ],
                                validator: (value) {
                                  final text = value?.trim() ?? '';
                                  if (text.isEmpty) return null;

                                  final year = int.tryParse(text);
                                  final maxYear = DateTime.now().year + 1;

                                  if (year == null ||
                                      year < 1900 ||
                                      year > maxYear) {
                                    return tr('Проверьте год выпуска');
                                  }

                                  return null;
                                },
                              ),
                              const SizedBox(height: 14),

                              _PremiumField(
                                controller: _plateCtrl,
                                iconAsset: 'assets/icons/car_form/plate.svg',
                                label: tr('Госномер'),
                                hint: tr('Например, C859HP196'),
                                helper: tr('Введите номер без пробелов'),
                                textCapitalization:
                                    TextCapitalization.characters,
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'[A-Za-zА-Яа-я0-9]'),
                                  ),
                                  _UpperCaseTextFormatter(),
                                ],
                              ),

                              const SizedBox(height: 28),

                              _PrivacyHint(isDark: isDark),

                              const SizedBox(height: 18),

                              _SaveButton(
                                loading: _saving,
                                isEditing: _isEditing,
                                onPressed: _save,
                              ),

                              const SizedBox(height: 12),

                              Text(
                                tr('Поля VIN, год и госномер можно заполнить позже.'),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: colors.onSurfaceVariant,
                                  fontSize: 12,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
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

class _TopBar extends StatelessWidget {
  const _TopBar({required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 20, 12),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
          bottom: BorderSide(
            color: colors.outlineVariant.withValues(alpha: .35),
          ),
        ),
      ),
      child: Row(
        children: [
          Material(
            color: colors.surfaceContainerHighest.withValues(alpha: .55),
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: onBack,
              borderRadius: BorderRadius.circular(16),
              child: const SizedBox(
                width: 48,
                height: 48,
                child: Icon(Icons.arrow_back_ios_new_rounded, size: 19),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.w800,
                letterSpacing: -.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IntroCard extends StatelessWidget {
  const _IntroCard({required this.isEditing});

  final bool isEditing;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            BrandColors.orange.withValues(alpha: .14),
            BrandColors.orange.withValues(alpha: .035),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: BrandColors.orange.withValues(alpha: .18)),
      ),
      child: Row(
        children: [
          Container(
            width: 68,
            height: 68,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: BrandColors.orange.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: SvgPicture.asset('assets/icons/car_form/header_car.svg'),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEditing ? tr('Обновите данные авто') : tr('Добавьте авто в гараж'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -.25,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  isEditing
                      ? tr('Проверьте информацию и сохраните изменения.')
                      : tr('После этого записываться в сервис будет быстрее.'),
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 13,
                    height: 1.4,
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

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: TextStyle(fontSize: 12.5, color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _PremiumField extends StatefulWidget {
  const _PremiumField({
    required this.controller,
    required this.iconAsset,
    required this.label,
    required this.hint,
    required this.helper,
    this.validator,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.maxLength,
    this.inputFormatters,
    this.suffix,
  });

  final TextEditingController controller;
  final String iconAsset;
  final String label;
  final String hint;
  final String helper;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final Widget? suffix;

  @override
  State<_PremiumField> createState() => _PremiumFieldState();
}

class _PremiumFieldState extends State<_PremiumField> {
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode()..addListener(_onFocusChanged);
  }

  void _onFocusChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final focused = _focusNode.hasFocus;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      decoration: BoxDecoration(
        color:
            focused
                ? BrandColors.orange.withValues(alpha: .055)
                : colors.surfaceContainerHighest.withValues(alpha: .58),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color:
              focused
                  ? BrandColors.orange
                  : colors.outlineVariant.withValues(alpha: .55),
          width: focused ? 1.5 : 1,
        ),
        boxShadow:
            focused
                ? [
                  BoxShadow(
                    color: BrandColors.orange.withValues(alpha: .10),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ]
                : const [],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 46,
            height: 46,
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color:
                  focused
                      ? BrandColors.orange.withValues(alpha: .13)
                      : colors.surface.withValues(alpha: .72),
              borderRadius: BorderRadius.circular(14),
            ),
            child: SvgPicture.asset(widget.iconAsset),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextFormField(
              controller: widget.controller,
              focusNode: _focusNode,
              validator: widget.validator,
              keyboardType: widget.keyboardType,
              textCapitalization: widget.textCapitalization,
              maxLength: widget.maxLength,
              inputFormatters: widget.inputFormatters,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                contentPadding: const EdgeInsets.only(top: 1),
                labelText: widget.label,
                labelStyle: TextStyle(
                  color: focused ? BrandColors.orange : colors.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
                hintText: widget.hint,
                hintStyle: TextStyle(
                  color: colors.onSurfaceVariant.withValues(alpha: .65),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                helperText: widget.helper,
                helperMaxLines: 2,
                helperStyle: TextStyle(
                  color: colors.onSurfaceVariant,
                  fontSize: 11.5,
                  height: 1.3,
                ),
                counterText: '',
                suffixIcon: widget.suffix,
                suffixIconConstraints: const BoxConstraints(
                  minWidth: 42,
                  minHeight: 36,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VinStatus extends StatelessWidget {
  const _VinStatus({required this.length});

  final int length;

  @override
  Widget build(BuildContext context) {
    final complete = length == 17;
    final colors = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color:
            complete
                ? Colors.green.withValues(alpha: .12)
                : colors.surface.withValues(alpha: .75),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$length/17',
        style: TextStyle(
          color: complete ? Colors.green : colors.onSurfaceVariant,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _PrivacyHint extends StatelessWidget {
  const _PrivacyHint({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: .42),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.verified_user_outlined,
            color: BrandColors.orange,
            size: 21,
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              tr('Данные автомобиля используются для вашего гаража и записи в сервис.'),
              style: TextStyle(
                color: colors.onSurfaceVariant,
                fontSize: 11.5,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SaveButton extends StatefulWidget {
  const _SaveButton({
    required this.loading,
    required this.isEditing,
    required this.onPressed,
  });

  final bool loading;
  final bool isEditing;
  final VoidCallback onPressed;

  @override
  State<_SaveButton> createState() => _SaveButtonState();
}

class _SaveButtonState extends State<_SaveButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.loading ? null : (_) => setState(() => _pressed = true),
      onTapCancel:
          widget.loading ? null : () => setState(() => _pressed = false),
      onTapUp: widget.loading ? null : (_) => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? .985 : 1,
        duration: const Duration(milliseconds: 100),
        child: SizedBox(
          height: 58,
          child: ElevatedButton(
            onPressed: widget.loading ? null : widget.onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: BrandColors.orange,
              foregroundColor: Colors.white,
              disabledBackgroundColor: BrandColors.orange.withValues(
                alpha: .65,
              ),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child:
                  widget.loading
                      ? const SizedBox(
                        key: ValueKey('loading'),
                        width: 23,
                        height: 23,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Colors.white,
                        ),
                      )
                      : Row(
                        key: const ValueKey('label'),
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            widget.isEditing
                                ? Icons.check_rounded
                                : Icons.add_rounded,
                            size: 23,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            widget.isEditing
                                ? tr('Сохранить изменения')
                                : tr('Добавить автомобиль'),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
            ),
          ),
        ),
      ),
    );
  }
}

class _UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
      composing: TextRange.empty,
    );
  }
}
