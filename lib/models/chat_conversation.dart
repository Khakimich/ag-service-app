import '../core/i18n.dart'; // AG_I18N1
class ChatConversation {
  ChatConversation({
    required this.id,
    required this.userId,
    this.specialistId,
    this.specialistName,
    this.specialistPhotoUrl,
    this.department,
    this.lastMessageAt,
    this.lastMessageBody,
    this.lastMessageSender,
    required this.createdAt,
  });

  final String id;
  final String userId;

  final String? specialistId;
  final String? specialistName;
  final String? specialistPhotoUrl;

  final String? department;

  final DateTime? lastMessageAt;
  final String? lastMessageBody;
  final String? lastMessageSender;

  final DateTime createdAt;

  bool get hasMessages => lastMessageBody != null;

  String get departmentName {
    switch (department) {
      case 'autogrom_service':
        return tr('Автогром Сервис');

      case 'm_service':
        return tr('М-Сервис');

      case 'autogrom_shop':
        return tr('Автогром Магазин');

      case 'taxi_park':
        return tr('Таксопарк');

      default:
        return '';
    }
  }

  String get displayName {
    if (departmentName.isNotEmpty) {
      return departmentName;
    }

    return specialistName ?? 'AG Service';
  }

  factory ChatConversation.fromJson(
    Map<String, dynamic> json,
  ) {
    final specialistJson =
        json['specialist'] as Map<String, dynamic>?;

    return ChatConversation(
      id: json['id'] as String,

      userId:
          (json['user_id'] ?? '').toString(),

      specialistId:
          json['specialist_id'] as String?,

      specialistName:
          specialistJson?['full_name'] as String?,

      specialistPhotoUrl:
          specialistJson?['photo_url'] as String?,

      department:
          json['department'] as String?,

      lastMessageAt:
          json['last_message_at'] != null
              ? DateTime.parse(
                  json['last_message_at'] as String,
                ).toLocal()
              : null,

      lastMessageBody:
          json['last_message_body'] as String?,

      lastMessageSender:
          json['last_message_sender'] as String?,

      createdAt:
          DateTime.parse(
            json['created_at'] as String,
          ).toLocal(),
    );
  }
}