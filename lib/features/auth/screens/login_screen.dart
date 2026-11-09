// AG_AUTH4..6 (после AG_LOGIN2/3) — новый экран входа: живой фон, карта AG BONUS, стеклянная форма, адаптивный (телефон / планшет / компьютер), светлая и тёмная тема,
// кнопка регистрации всегда видна. Логика входа прежняя.
import 'package:mobile/core/phone_input.dart'; // AG_PHONE7
import 'package:mobile/core/promo_splash.dart'; // AG_PROMO2
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme.dart';
import '../../../core/ag_auth_shell.dart'; // AG_AUTH4
import '../providers/auth_provider.dart';
import '../../../core/i18n.dart'; // AG_I18N1

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _passFocus = FocusNode();
  bool _loading = false;
  String? _error;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) AgPromoSplash.show(context);
    }); // AG_PROMO2
  }

  @override
  void dispose() {
    _identifierCtrl.dispose();
    _passCtrl.dispose();
    _passFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await context.read<AuthProvider>().login(
            _identifierCtrl.text.trim(),
            _passCtrl.text,
          );
      if (!mounted) return;
      context.go('/');
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return AgAuthShell(
      register: false,
      title: tr('С возвращением 👋'),
      subtitle: tr('Войдите, чтобы записываться в сервис, следить за ремонтом и копить бонусы'),
      child: AutofillGroup(child: _form(_LgPal(dark), elevated: false)),
    );
  }

  InputDecoration _dec(_LgPal p, {required String hint, required String icon, Widget? suffix}) {
    OutlineInputBorder b(Color c, [double w = 1]) =>
        OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: c, width: w));
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: p.mut, fontSize: 15.5, fontWeight: FontWeight.w500),
      filled: true,
      fillColor: p.field,
      prefixIcon: Padding(
        padding: const EdgeInsets.fromLTRB(16, 15, 10, 15),
        child: SvgPicture.asset(icon, width: 22, height: 22, colorFilter: ColorFilter.mode(p.mut, BlendMode.srcIn)),
      ),
      prefixIconConstraints: const BoxConstraints(minWidth: 48),
      suffixIcon: suffix,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      border: b(p.line),
      enabledBorder: b(p.line),
      focusedBorder: b(BrandColors.orange, 1.6),
      errorBorder: b(const Color(0xFFE5484D)),
      focusedErrorBorder: b(const Color(0xFFE5484D), 1.6),
      errorStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
    );
  }

  Widget _form(_LgPal p, {required bool elevated}) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            inputFormatters: [AgPhoneFormatter(smart: true)], // AG_PHONE7
            controller: _identifierCtrl,
            style: TextStyle(color: p.ink, fontWeight: FontWeight.w600, fontSize: 16),
            decoration: _dec(p, hint: tr('Телефон или e-mail'), icon: 'assets/icons/profile/personal.svg'),
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.username, AutofillHints.telephoneNumber, AutofillHints.email],
            onFieldSubmitted: (_) => _passFocus.requestFocus(),
            validator: (v) => (v == null || v.trim().isEmpty) ? tr('Введите телефон или e-mail') : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _passCtrl,
            focusNode: _passFocus,
            style: TextStyle(color: p.ink, fontWeight: FontWeight.w600, fontSize: 16),
            decoration: _dec(
              p,
              hint: tr('Пароль'),
              icon: 'assets/icons/profile/lock.svg',
              suffix: IconButton(
                tooltip: _obscure ? tr('Показать пароль') : tr('Скрыть пароль'),
                onPressed: () => setState(() => _obscure = !_obscure),
                icon: SvgPicture.asset(
                  _obscure ? 'assets/icons/auth/eye_off.svg' : 'assets/icons/auth/eye.svg',
                  width: 22,
                  height: 22,
                  colorFilter: ColorFilter.mode(p.mut, BlendMode.srcIn),
                ),
              ),
            ),
            obscureText: _obscure,
            autofillHints: const [AutofillHints.password],
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _submit(),
            validator: (v) => (v == null || v.isEmpty) ? tr('Введите пароль') : null,
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => context.push('/forgot-password'),
              style: TextButton.styleFrom(foregroundColor: BrandColors.orange, padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10)),
              child: Text(tr('Забыли пароль?'), style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            child: _error == null
                ? const SizedBox(width: double.infinity)
                : Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5484D).withValues(alpha: p.dark ? .16 : .08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE5484D).withValues(alpha: .3)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.error_outline_rounded, size: 20, color: Color(0xFFE5484D)),
                        const SizedBox(width: 8),
                        Expanded(child: Text(_error!, style: const TextStyle(color: Color(0xFFE5484D), fontWeight: FontWeight.w600, height: 1.3))),
                      ],
                    ),
                  ),
          ),
          // Войти
          SizedBox(
            height: 56,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFFFF8A2B), Color(0xFFFF5A00)]),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [BoxShadow(color: BrandColors.orange.withValues(alpha: .35), blurRadius: 18, offset: const Offset(0, 8))],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: _loading ? null : _submit,
                  child: Center(
                    child: _loading
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(tr('Войти'), style: TextStyle(color: Colors.white, fontSize: 16.5, fontWeight: FontWeight.w900)),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward_rounded, size: 21, color: Colors.white),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LgPal {
  const _LgPal(this.dark);
  final bool dark;
  Color get bg => dark ? const Color(0xFF07090D) : const Color(0xFFF4F5F8);
  Color get card => dark ? const Color(0xFF12161C) : Colors.white;
  Color get field => dark ? const Color(0xFF1C2129) : const Color(0xFFF6F3F0);
  Color get line => dark ? const Color(0xFF2B323C) : const Color(0xFFEDE4DC);
  Color get ink => dark ? const Color(0xFFF6F7F8) : const Color(0xFF15171C);
  Color get mut => dark ? const Color(0xFFA3AAB4) : const Color(0xFF69717D);
}
