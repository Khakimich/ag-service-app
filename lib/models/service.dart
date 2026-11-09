import '../core/i18n.dart'; // AG_I18N1
class Service {
  Service({
    required this.id,
    required this.title,
    required this.description,
    required this.priceFrom,
    required this.priceFixed,
    required this.durationMinutes,
    required this.photoUrl,
    required this.category,
    this.discountTag,
    this.discountPrice,
  });

  final String id;
  final String title;
  final String? description;
  final double priceFrom;
  final bool priceFixed;
  final int durationMinutes;
  final String? photoUrl;
  final String category;
  final String? discountTag;
  final double? discountPrice;

  factory Service.fromJson(Map<String, dynamic> json) {
    final rawDescription = json['description']?.toString();
    final apiCategory = json['category']?.toString().trim();

    final extractedCategory = _extractCategory(rawDescription);

    final category =
        apiCategory != null && apiCategory.isNotEmpty
            ? apiCategory
            : extractedCategory ?? 'Без категории';

    return Service(
      id: json['id'].toString(),
      title: json['title'].toString(),
      description: _cleanDescription(rawDescription),
      priceFrom: (json['price_from'] as num).toDouble(),
      priceFixed: json['price_fixed'] == true,
      durationMinutes: (json['duration_minutes'] as num).toInt(),
      photoUrl: json['photo_url']?.toString(),
      category: category,
      discountTag: json['discount_tag']?.toString(),
      discountPrice:
          json['discount_price'] != null
              ? (json['discount_price'] as num).toDouble()
              : null,
    );
  }

  static String? _extractCategory(String? description) {
    if (description == null || description.trim().isEmpty) {
      return null;
    }

    final match = RegExp(
      r'^\s*\[Категория\s*:\s*([^\]]+)\]',
      caseSensitive: false,
      multiLine: true,
    ).firstMatch(description);

    final value = match?.group(1)?.trim();

    if (value == null || value.isEmpty) {
      return null;
    }

    return value;
  }

  static String? _cleanDescription(String? description) {
    if (description == null) return null;

    final cleaned =
        description
            .replaceFirst(
              RegExp(
                r'^\s*\[Категория\s*:\s*[^\]]+\]\s*',
                caseSensitive: false,
                multiLine: true,
              ),
              '',
            )
            .trim();

    return cleaned.isEmpty ? null : cleaned;
  }

  String get priceLabel {
    final originalPrice = priceFrom.toStringAsFixed(0);

    if (discountPrice != null) {
      final p = discountPrice!.toStringAsFixed(0);
      return priceFixed ? '$p ₽' : trf('от {0} ₽', [p]);
    }

    return priceFixed ? '$originalPrice ₽' : trf('от {0} ₽', [originalPrice]);
  }

  String get durationLabel {
    if (durationMinutes < 60) {
      return trf('{0} мин', [durationMinutes]);
    }

    final h = durationMinutes ~/ 60;
    final m = durationMinutes % 60;

    return m == 0 ? trf('{0} ч', [h]) : trf('{0} ч {1} мин', [h, m]);
  }
}
