import '../../../core/api_client.dart';
import '../../../models/chat_conversation.dart';
import '../../../models/chat_message.dart';

class ChatDepartment {
  const ChatDepartment({
    required this.code,
    required this.title,
    required this.subtitle,
  });

  final String code;
  final String title;
  final String subtitle;

  factory ChatDepartment.fromJson(Map<String, dynamic> json) {
    return ChatDepartment(
      code: (json['code'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      subtitle: (json['subtitle'] ?? '').toString(),
    );
  }
}

class LinkPreview {
  const LinkPreview({
    required this.hasPreview,
    required this.url,
    this.domain,
    this.title,
    this.description,
    this.image,
    this.siteName,
  });

  final bool hasPreview;
  final String url;
  final String? domain;
  final String? title;
  final String? description;
  final String? image;
  final String? siteName;

  factory LinkPreview.fromJson(Map<String, dynamic> json) {
    return LinkPreview(
      hasPreview: json['has_preview'] == true,
      url: (json['url'] ?? '').toString(),
      domain: json['domain']?.toString(),
      title: json['title']?.toString(),
      description: json['description']?.toString(),
      image: json['image']?.toString(),
      siteName: json['site_name']?.toString(),
    );
  }
}

class ChatRepository {
  ChatRepository(this._api);

  final ApiClient _api;

  Future<List<ChatConversation>> listConversations() async {
    final data = await _api.get('/api/conversations') as Map<String, dynamic>;

    final raw = data['conversations'] as List<dynamic>? ?? const [];

    return raw
        .map((e) => ChatConversation.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<List<ChatDepartment>> listDepartments() async {
    final data =
        await _api.get('/api/conversations/departments')
            as Map<String, dynamic>;

    final raw = data['departments'] as List<dynamic>? ?? const [];

    return raw
        .map((e) => ChatDepartment.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<ChatConversation> getOrCreateDepartmentConversation(
    String department,
  ) async {
    final data =
        await _api.post('/api/conversations/department', {
              'department': department,
            })
            as Map<String, dynamic>;

    return ChatConversation.fromJson(
      data['conversation'] as Map<String, dynamic>,
    );
  }

  Future<List<ChatMessage>> fetchMessages(
    String conversationId, {
    String? after,
  }) async {
    final query = <String, dynamic>{};

    if (after != null) {
      query['after'] = after;
    }

    final data =
        await _api.get(
              '/api/conversations/$conversationId/messages',
              query: query.isEmpty ? null : query,
            )
            as Map<String, dynamic>;

    final raw = data['messages'] as List<dynamic>? ?? const [];

    return raw
        .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<ChatMessage> sendMessage(
    String conversationId, {
    String? body,
    String? photoBase64,
    String? fileBase64,
    String? fileName,
    String? audioBase64,
    int? audioDuration,
    String? replyToId,
  }) async {
    final payload = <String, dynamic>{};

    if (body != null && body.isNotEmpty) {
      payload['body'] = body;
    }

    if (photoBase64 != null) {
      payload['photo_base64'] = photoBase64;
    }

    if (fileBase64 != null) {
      payload['file_base64'] = fileBase64;
    }

    if (fileName != null) {
      payload['file_name'] = fileName;
    }

    if (audioBase64 != null) {
      payload['audio_base64'] = audioBase64;
    }

    if (audioDuration != null) {
      payload['audio_duration'] = audioDuration;
    }

    if (replyToId != null && replyToId.isNotEmpty) {
      payload['reply_to_id'] = replyToId;
    }

    final data =
        await _api.post('/api/conversations/$conversationId/messages', payload)
            as Map<String, dynamic>;

    return ChatMessage.fromJson(data['message'] as Map<String, dynamic>);
  }

  Future<ChatMessage> editMessage(
    String conversationId,
    String messageId,
    String body,
  ) async {
    final data =
        await _api.patch(
              '/api/conversations/$conversationId/messages/$messageId',
              {'body': body},
            )
            as Map<String, dynamic>;

    return ChatMessage.fromJson(data['message'] as Map<String, dynamic>);
  }

  Future<void> deleteMessageForMe(
    String conversationId,
    String messageId,
  ) async {
    await _api.delete(
      '/api/conversations/$conversationId/messages/$messageId/me',
    );
  }

  Future<ChatMessage> deleteMessageForEveryone(
    String conversationId,
    String messageId,
  ) async {
    final data =
        await _api.delete(
              '/api/conversations/$conversationId/messages/$messageId',
            )
            as Map<String, dynamic>;

    return ChatMessage.fromJson(data['message'] as Map<String, dynamic>);
  }

  Future<ChatMessage> togglePinMessage(
    String conversationId,
    String messageId,
  ) async {
    final data =
        await _api.post(
              '/api/conversations/$conversationId/messages/$messageId/pin',
              const {},
            )
            as Map<String, dynamic>;

    return ChatMessage.fromJson(data['message'] as Map<String, dynamic>);
  }

  Future<LinkPreview?> fetchLinkPreview(String url) async {
    try {
      final data =
          await _api.post('/api/link-preview', {'url': url})
              as Map<String, dynamic>;

      final preview = LinkPreview.fromJson(data);

      if (!preview.hasPreview) {
        return null;
      }

      return preview;
    } catch (_) {
      return null;
    }
  }
}
