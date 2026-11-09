class AgNewsItem {
  const AgNewsItem({
    required this.id,
    required this.type,
    required this.title,
    required this.shortDescription,
    required this.body,
    required this.imageUrl,
    required this.publishedAt,
  });

  final String id;
  final String type;
  final String title;
  final String shortDescription;
  final String body;
  final String? imageUrl;
  final DateTime? publishedAt;

  bool get isPromotion => type == 'promotion';

  factory AgNewsItem.fromJson(Map<String, dynamic> json) {
    return AgNewsItem(
      id: (json['id'] ?? '').toString(),
      type: (json['type'] ?? 'news').toString(),
      title: (json['title'] ?? '').toString(),
      shortDescription:
          (json['short_description'] ?? '').toString(),
      body: (json['body'] ?? '').toString(),
      imageUrl: (json['image_url'] as String?)?.trim().isEmpty == true
          ? null
          : json['image_url'] as String?,
      publishedAt: json['published_at'] == null
          ? null
          : DateTime.tryParse(json['published_at'].toString()),
    );
  }
}