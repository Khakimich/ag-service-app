class AppNotification {
  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.relatedId,
    required this.isRead,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String body;
  final String type;
  final String? relatedId;
  final bool isRead;
  final DateTime createdAt;

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
        id: json['id'] as String,
        title: json['title'] as String,
        body: json['body'] as String,
        type: json['type'] as String,
        relatedId: json['related_id'] as String?,
        isRead: json['is_read'] as bool,
        createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'type': type,
        'related_id': relatedId,
        'is_read': isRead,
        'created_at': createdAt.toUtc().toIso8601String(),
      };
}
