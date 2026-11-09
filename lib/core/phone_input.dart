// AG_PHONE7 — номер телефона всегда начинается с +7.
// Пишут 8 921… или 921… — получится +7921…; лишние символы и пробелы убираются.
// smart: true — для поля «Телефон или email»: если вводят буквы или @, это email, его не трогаем.
import 'package:flutter/services.dart';

class AgPhoneFormatter extends TextInputFormatter {
  AgPhoneFormatter({this.smart = false});

  final bool smart;

  static final RegExp _emailLike = RegExp(r'[A-Za-zА-Яа-яЁё@_]');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;

    if (text.isEmpty) return newValue;

    if (smart && _emailLike.hasMatch(text)) return newValue;

    var digits = text.replaceAll(RegExp(r'\D'), '');

    // Стёрли всё, кроме «+» — даём очистить поле.
    if (digits.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    if (!text.trimLeft().startsWith('+') && digits.startsWith('8')) {
      digits = '7${digits.substring(1)}';
    }

    var rest = digits.startsWith('7') ? digits.substring(1) : digits;

    if (rest.length > 10) rest = rest.substring(0, 10);

    final out = '+7$rest';

    return TextEditingValue(
      text: out,
      selection: TextSelection.collapsed(offset: out.length),
    );
  }
}
