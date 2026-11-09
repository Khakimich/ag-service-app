import 'package:mobile/core/nav.dart'; // AG_FIX3
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../auth/providers/auth_provider.dart';
import '../../../core/i18n.dart'; // AG_I18N1

class PersonalDataScreen extends StatefulWidget {
  const PersonalDataScreen({super.key});

  @override
  State<PersonalDataScreen> createState() => _PersonalDataScreenState();
}

class _PersonalDataScreenState extends State<PersonalDataScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;

  DateTime? _birthDate;
  bool _saving = false;
  bool _uploadingAvatar = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_initialized) return;

    final user = context.read<AuthProvider>().user;

    if (user != null) {
      _nameController.text = user.name;

      final rawBirthDate = user.birthDate;
      if (rawBirthDate != null && rawBirthDate.isNotEmpty) {
        _birthDate = DateTime.tryParse(rawBirthDate);
      }
    }

    _initialized = true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day.$month.${date.year}';
  }

  String _apiDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '${date.year}-$month-$day';
  }

  Future<void> _pickAvatar() async {
    if (_uploadingAvatar) return;

    try {
      final picker = ImagePicker();

      final image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1600,
        maxHeight: 1600,
      );

      if (image == null) return;

      final bytes = await image.readAsBytes();

      const maxBytes = 5 * 1024 * 1024;

      if (bytes.length > maxBytes) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr('Размер фотографии не должен превышать 5 МБ')),
          ),
        );
        return;
      }

      final lowerName = image.name.toLowerCase();

      String mimeType;

      if (lowerName.endsWith('.png')) {
        mimeType = 'image/png';
      } else if (lowerName.endsWith('.webp')) {
        mimeType = 'image/webp';
      } else if (lowerName.endsWith('.jpg') || lowerName.endsWith('.jpeg')) {
        mimeType = 'image/jpeg';
      } else {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr('Выберите фотографию JPG, PNG или WebP')),
          ),
        );
        return;
      }

      final dataUri = 'data:$mimeType;base64,${base64Encode(bytes)}';

      if (!mounted) return;

      final authProvider = context.read<AuthProvider>();

      setState(() {
        _uploadingAvatar = true;
      });

      await authProvider.uploadAvatar(
        imageBase64: dataUri,
        fileName: image.name,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(tr('Фото профиля обновлено'))));
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(trf('Не удалось загрузить фотографию: {0}', [e]))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _uploadingAvatar = false;
        });
      }
    }
  }

  Future<void> _selectBirthDate() async {
    final now = DateTime.now();

    final selected = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 25, now.month, now.day),
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: tr('Дата рождения'),
      cancelText: tr('Отмена'),
      confirmText: tr('Выбрать'),
    );

    if (selected == null) return;

    setState(() {
      _birthDate = selected;
    });
  }

  Future<void> _save() async {
    if (_saving) return;

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      await context.read<AuthProvider>().updateProfile(
        name: _nameController.text.trim(),
        birthDate: _birthDate == null ? null : _apiDate(_birthDate!),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(tr('Личные данные сохранены'))));
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(trf('Не удалось сохранить данные: {0}', [e]))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    if (user == null) {
      return Scaffold(body: Center(child: Text(tr('Требуется авторизация'))));
    }

    final theme = Theme.of(context);
    final initials =
        user.name.trim().isEmpty
            ? 'AG'
            : user.name
                .trim()
                .split(RegExp(r'\s+'))
                .where((part) => part.isNotEmpty)
                .take(2)
                .map((part) => part[0].toUpperCase())
                .join();

    return Scaffold(
      appBar: AppBar(leading: const AgBackButton(fallback: '/profile'), /* AG_FIX3 */ title: Text(tr('Личные данные'))),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: _uploadingAvatar ? null : _pickAvatar,
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  width: 96,
                                  height: 96,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: theme.colorScheme.primary.withValues(
                                      alpha: 0.10,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child:
                                      user.avatarUrl != null &&
                                              user.avatarUrl!.trim().isNotEmpty
                                          ? ClipOval(
                                            child: Image.network(
                                              user.avatarUrl!,
                                              width: 96,
                                              height: 96,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (_, __, ___) =>
                                                      _AvatarInitials(
                                                        initials: initials,
                                                      ),
                                            ),
                                          )
                                          : _AvatarInitials(initials: initials),
                                ),
                                Positioned(
                                  right: -2,
                                  bottom: -2,
                                  child: Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primary,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: theme.scaffoldBackgroundColor,
                                        width: 3,
                                      ),
                                    ),
                                    alignment: Alignment.center,
                                    child:
                                        _uploadingAvatar
                                            ? const SizedBox(
                                              width: 15,
                                              height: 15,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            )
                                            : SvgPicture.asset(
                                              'assets/icons/profile/camera.svg',
                                              width: 17,
                                              height: 17,
                                              colorFilter:
                                                  const ColorFilter.mode(
                                                    Colors.white,
                                                    BlendMode.srcIn,
                                                  ),
                                            ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _uploadingAvatar
                                ? tr('Загрузка...')
                                : tr('Нажмите, чтобы изменить фото'),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    _SectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _FieldTitle(tr('Имя')),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _nameController,
                            textInputAction: TextInputAction.done,
                            decoration: InputDecoration(
                              hintText: tr('Введите имя'),
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              final name = value?.trim() ?? '';

                              if (name.length < 2) {
                                return tr('Введите имя');
                              }

                              if (name.length > 100) {
                                return tr('Имя слишком длинное');
                              }

                              return null;
                            },
                          ),

                          const SizedBox(height: 20),

                          const _FieldTitle('Email'),
                          const SizedBox(height: 8),
                          _ReadOnlyField(
                            value: user.email,
                            helper:
                                tr('Email привязан к аккаунту и не изменяется здесь'),
                          ),

                          const SizedBox(height: 20),

                          _FieldTitle(tr('Телефон')),
                          const SizedBox(height: 8),
                          _ReadOnlyField(
                            value:
                                user.phone?.trim().isNotEmpty == true
                                    ? user.phone!
                                    : tr('Не указан'),
                          ),

                          const SizedBox(height: 20),

                          _FieldTitle(tr('Дата рождения')),
                          const SizedBox(height: 8),

                          InkWell(
                            onTap: _selectBirthDate,
                            borderRadius: BorderRadius.circular(12),
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                suffixIcon: Icon(Icons.calendar_month_outlined),
                              ),
                              child: Text(
                                _birthDate == null
                                    ? tr('Не указана')
                                    : _formatDate(_birthDate!),
                                style: TextStyle(
                                  color:
                                      _birthDate == null
                                          ? theme.hintColor
                                          : theme.colorScheme.onSurface,
                                ),
                              ),
                            ),
                          ),

                          if (_birthDate != null) ...[
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton(
                                onPressed: () {
                                  setState(() {
                                    _birthDate = null;
                                  });
                                },
                                child: Text(tr('Удалить дату рождения')),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    SizedBox(
                      height: 52,
                      child: FilledButton(
                        onPressed: _saving ? null : _save,
                        child:
                            _saving
                                ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                                : Text(tr('Сохранить')),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AvatarInitials extends StatelessWidget {
  const _AvatarInitials({required this.initials});

  final String initials;

  @override
  Widget build(BuildContext context) {
    return Text(
      initials,
      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.w800,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.45),
        ),
      ),
      child: child,
    );
  }
}

class _FieldTitle extends StatelessWidget {
  const _FieldTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(
        context,
      ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
    );
  }
}

class _ReadOnlyField extends StatelessWidget {
  const _ReadOnlyField({required this.value, this.helper});

  final String value;
  final String? helper;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        border: const OutlineInputBorder(),
        helperText: helper,
      ),
      child: Text(value),
    );
  }
}
