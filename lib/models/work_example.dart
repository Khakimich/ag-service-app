class WorkExample {
  WorkExample({
    required this.id,
    required this.description,
    required this.photoUrl,
    required this.createdAt,
    this.serviceId,
  });

  final String id;
  final String description;
  final String photoUrl;
  final DateTime createdAt;
  final String? serviceId;

  factory WorkExample.fromJson(Map<String, dynamic> json) => WorkExample(
        id: json['id'] as String,
        description: json['description'] as String,
        photoUrl: json['photo_url'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
        serviceId: json['service_id'] as String?,
      );
}
