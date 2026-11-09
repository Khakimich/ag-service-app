class ChatMessage {
  ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderRole,
    required this.body,
    this.photoUrl,
    this.fileUrl,
    this.fileName,
    this.videoUrl,
    this.audioUrl,
    this.audioDuration,
    this.replyToId,
    this.editedAt,
    this.deletedAt,
    this.isPinned = false,
    this.pinnedAt,
    this.senderId,
    this.senderEmployeeId,
    required this.createdAt,
    this.isTemp = false,
    this.uploading = false,
    this.tempType,
  });

  final String id;
  final String conversationId;
  final String senderRole;
  final String body;

  final String? photoUrl;
  final String? fileUrl;
  final String? fileName;
  final String? videoUrl;

  final String? audioUrl;
  final int? audioDuration;

  final String? replyToId;

  final DateTime? editedAt;
  final DateTime? deletedAt;

  final bool isPinned;
  final DateTime? pinnedAt;

  final String? senderId;
  final int? senderEmployeeId;

  final DateTime createdAt;

  final bool isTemp;
  final bool uploading;
  final String? tempType;

  bool get isFromClient => senderRole == 'client';

  bool get hasPhoto => photoUrl != null && photoUrl!.isNotEmpty;

  bool get hasVideo => videoUrl != null && videoUrl!.isNotEmpty;

  bool get hasAudio => audioUrl != null && audioUrl!.isNotEmpty;

  bool get isDeleted => deletedAt != null;

  bool get isEdited => editedAt != null;

  bool get isDocument => fileUrl != null && fileUrl!.isNotEmpty && !hasVideo;

  bool get isPhotoMessage => hasPhoto && !isDocument && !hasVideo;

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    DateTime? parseNullableDate(dynamic value) {
      if (value == null) {
        return null;
      }

      final raw = value.toString();

      if (raw.isEmpty) {
        return null;
      }

      return DateTime.tryParse(raw)?.toLocal();
    }

    int? parseNullableInt(dynamic value) {
      if (value == null) {
        return null;
      }

      if (value is int) {
        return value;
      }

      return int.tryParse(value.toString());
    }

    final createdRaw = json['created_at']?.toString();

    return ChatMessage(
      id: json['id']?.toString() ?? '',
      conversationId: json['conversation_id']?.toString() ?? '',
      senderRole: json['sender_role']?.toString() ?? '',
      body: json['body']?.toString() ?? '',

      photoUrl: json['photo_url']?.toString(),

      fileUrl: json['file_url']?.toString(),

      fileName: json['file_name']?.toString(),

      videoUrl: json['video_url']?.toString(),

      audioUrl: json['audio_url']?.toString(),

      audioDuration: parseNullableInt(json['audio_duration']),

      replyToId: json['reply_to_id']?.toString(),

      editedAt: parseNullableDate(json['edited_at']),

      deletedAt: parseNullableDate(json['deleted_at']),

      isPinned: json['is_pinned'] == true,

      pinnedAt: parseNullableDate(json['pinned_at']),

      senderId: json['sender_id']?.toString(),

      senderEmployeeId: parseNullableInt(json['sender_employee_id']),

      createdAt:
          createdRaw != null
              ? DateTime.tryParse(createdRaw)?.toLocal() ?? DateTime.now()
              : DateTime.now(),

      isTemp: false,
      uploading: false,
    );
  }
}
