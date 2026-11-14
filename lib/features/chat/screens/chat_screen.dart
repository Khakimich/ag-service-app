import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:just_audio/just_audio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

import '../../../core/theme.dart';
import '../../../core/api_client.dart';
import '../../../core/ag_extras.dart'; // AG_EXTRAS1
import '../../../models/chat_message.dart';
import '../../../models/chat_conversation.dart';
import '../data/chat_repository.dart';
import '../../../core/i18n.dart'; // AG_I18N1

// AG_M5CHAT1 + AG_M5CHAT2 + AG_M5CHAT3: оформление как в чате сотрудников (AG Messenger 5): белый фон, оранжевые акценты.
class _M5 {
  static const acc = Color(0xFFF26200);
  static const acc2 = Color(0xFFC24400);
  static const ink = Color(0xFF3B1A05);
  static const mut = Color(0xFF8A5A3C);
  static const soft = Color(0xFFB98E72);
  static const line = Color(0xFFF0DFD0);
  static const line2 = Color(0xFFFFD0A8);
  static const tint = Color(0xFFFFF3E8);

  static bool dark(BuildContext c) => Theme.of(c).brightness == Brightness.dark;
  static Color bg(BuildContext c) => dark(c) ? Theme.of(c).colorScheme.surface : Colors.white;
  static Color tintOf(BuildContext c) => dark(c) ? const Color(0xFF2A211B) : tint;
  static Color inkOf(BuildContext c) => dark(c) ? Theme.of(c).colorScheme.onSurface : ink;
  static Color mutOf(BuildContext c) => dark(c) ? Theme.of(c).colorScheme.onSurfaceVariant : mut;
  static Color lineOf(BuildContext c) => dark(c) ? Theme.of(c).colorScheme.outlineVariant : line;
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    required this.conversationId,
    this.conversation,
    this.bottomInset = 0,
  });
  final String conversationId;
  final ChatConversation? conversation;

  /// Отступ снизу под плавающее нижнее меню, когда чат открыт во вкладке.
  final double bottomInset;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  static const _pollInterval = Duration(seconds: 6);

  final _messages = <ChatMessage>[];
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _focusNode = FocusNode();
  final _picker = ImagePicker();

  // Voice recording
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _voicePreviewPlayer = AudioPlayer();

  StreamSubscription<Uint8List>? _voiceStreamSubscription;
  Timer? _voiceTimer;

  final List<int> _voicePcmBytes = <int>[];

  bool _isRecordingVoice = false;
  bool _isVoicePreviewPlaying = false;

  Duration _voiceRecordDuration = Duration.zero;
  Uint8List? _recordedVoiceBytes;

  Timer? _timer;
  bool _initialLoading = true;
  bool _sending = false;
  String? _error;
  XFile? _pickedImage;
  PlatformFile? _pickedFile;

  ChatMessage? _replyingTo;
  ChatMessage? _editingMessage;

  // Реакции на сообщения. Пока хранятся только на этом устройстве:
  // сервер их не принимает, поэтому собеседник реакцию не видит.
  static const _reactionEmojis = <String>['👍', '❤️', '😂', '😮', '😢', '🙏', '🔥', '👏', '✅', '👎'];

  final Map<String, String> _reactions = <String, String>{};

  String get _reactionsKey => 'chat_reactions_${widget.conversationId}';

  // ISO timestamp of the last message we received — used for incremental polling
  String? _lastTimestamp;

  // AG_M5CHAT1
  final Map<String, GlobalKey> _msgKeys = <String, GlobalKey>{};
  bool _showDownFab = false;
  int _newBelow = 0;
  String? _flashId;

  bool get _nearBottom {
    if (!_scrollCtrl.hasClients) return true;
    final p = _scrollCtrl.position;
    return p.maxScrollExtent - p.pixels < 160;
  }

  void _onScroll() {
    if (!_scrollCtrl.hasClients) return;
    final p = _scrollCtrl.position;
    final show = p.maxScrollExtent - p.pixels > 400;
    if (show != _showDownFab || (!show && _newBelow > 0)) {
      setState(() {
        _showDownFab = show;
        if (!show) _newBelow = 0;
      });
    }
  }

  GlobalKey _keyFor(String id) => _msgKeys.putIfAbsent(id, () => GlobalKey());

  ChatMessage? _findMessage(String? id) {
    if (id == null || id.isEmpty) return null;
    for (final m in _messages) {
      if (m.id == id) return m;
    }
    return null;
  }

  void _jumpToMessage(String id) {
    final ctx = _msgKeys[id]?.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      alignment: 0.4,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
    setState(() => _flashId = id);
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted && _flashId == id) setState(() => _flashId = null);
    });
  }

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    _focusNode.addListener(() {
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.addObserver(this);
    _loadInitial();
    _loadReactions();
  }

  Future<void> _loadReactions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_reactionsKey);

      if (raw == null || raw.isEmpty) return;

      final decoded = jsonDecode(raw);

      if (decoded is! Map || !mounted) return;

      setState(() {
        _reactions.clear();

        for (final entry in decoded.entries) {
          _reactions[entry.key.toString()] = entry.value.toString();
        }
      });
    } catch (_) {
      // Реакции необязательны: при ошибке чтения просто не показываем их.
    }
  }

  Future<void> _setReaction(ChatMessage message, String? emoji) async {
    setState(() {
      if (emoji == null || _reactions[message.id] == emoji) {
        _reactions.remove(message.id);
      } else {
        _reactions[message.id] = emoji;
      }
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_reactionsKey, jsonEncode(_reactions));
    } catch (_) {
      // Не удалось сохранить — реакция останется до закрытия чата.
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _voiceTimer?.cancel();
    _voiceStreamSubscription?.cancel();
    _audioRecorder.dispose();
    _voicePreviewPlayer.dispose();
    WidgetsBinding.instance.removeObserver(this);
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // Stop polling when app goes to background; resume on foreground.
  // Prevents unnecessary network traffic and avoids waking Render's sleeping instance.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden || // AG_CHATUI1: вкладка браузера скрыта — не отмечать прочитанным
        state == AppLifecycleState.detached) {
      _timer?.cancel();
      _timer = null;
    } else if (state == AppLifecycleState.resumed && _timer == null) {
      _poll(); // immediate catch-up
      _startPolling();
    }
  }

  Future<void> _loadInitial() async {
    try {
      final msgs = await context.read<ChatRepository>().fetchMessages(
        widget.conversationId,
      );
      if (!mounted) return;
      setState(() {
        _messages.addAll(msgs);
        if (msgs.isNotEmpty) {
          _lastTimestamp = msgs.last.createdAt.toUtc().toIso8601String();
        }
        _initialLoading = false;
      });
      _scrollToBottom(animated: false);
      _startPolling();
      _agMarkRead(); // AG_EXTRAS1
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _initialLoading = false;
      });
    }
  }

  // AG_EXTRAS1: чат открыт — сообщения прочитаны (счётчик на вкладке «Чаты»)
  void _agMarkRead() {
    if (!mounted) return;
    try {
      AgUnread.instance.markRead(context.read<ApiClient>(), widget.conversationId);
    } catch (_) {}
  }

  void _startPolling() {
    _timer?.cancel();
    _timer = Timer.periodic(_pollInterval, (_) => _poll());
  }

  Future<void> _poll() async {
    if (!mounted) return;
    try {
      final newMsgs = await context.read<ChatRepository>().fetchMessages(
        widget.conversationId,
        after: _lastTimestamp,
      );
      if (!mounted || newMsgs.isEmpty) return;
      final wasNearBottom = _nearBottom;
      var added = 0;
      setState(() {
        final existingIds = _messages.map((m) => m.id).toSet();
        for (final msg in newMsgs) {
          if (!existingIds.contains(msg.id)) {
            _messages.add(msg);
            added++;
          }
        }
        _lastTimestamp = newMsgs.last.createdAt.toUtc().toIso8601String();
        if (!wasNearBottom) _newBelow += added;
      });
      if (added > 0) _agMarkRead(); // AG_EXTRAS1
      if (wasNearBottom) _scrollToBottom();
    } catch (_) {
      // Polling errors are silent — next tick will retry.
    }
  }

  Future<void> _showMessageActions(ChatMessage message) async {
    if (message.isTemp || !mounted) return;

    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (sheetContext) {
        return Container(
          margin: const EdgeInsets.fromLTRB(8, 8, 8, 8),
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 6),
          decoration: BoxDecoration(
            color: _M5.bg(sheetContext),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _M5.lineOf(sheetContext)),
            boxShadow: const [
              BoxShadow(color: Color(0x29783400), blurRadius: 40, offset: Offset(0, 12)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!message.isDeleted)
                Container(
                  margin: const EdgeInsets.fromLTRB(6, 0, 6, 4),
                  padding: const EdgeInsets.only(bottom: 6),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: _M5.lineOf(sheetContext))),
                  ),
                  child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final emoji in _reactionEmojis)
                        InkWell(
                          borderRadius: BorderRadius.circular(23),
                          onTap:
                              () => Navigator.pop(sheetContext, 'react:$emoji'),
                          child: Container(
                            width: 44,
                            height: 44,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color:
                                  _reactions[message.id] == emoji
                                      ? BrandColors.orange.withValues(
                                        alpha: 0.18,
                                      )
                                      : Colors.transparent,
                            ),
                            child: Text(
                              emoji,
                              style: const TextStyle(fontSize: 24),
                            ),
                          ),
                        ),
                    ],
                  ),
                  ),
                ),
              _MessageActionTile(
                icon: 'assets/icons/chat/reply.svg',
                title: tr('Ответить'),
                onTap: () => Navigator.pop(sheetContext, 'reply'),
              ),
              if (!message.isDeleted && message.body.trim().isNotEmpty)
                _MessageActionTile(
                  icon: 'assets/icons/chat/copy.svg',
                  title: tr('Копировать'),
                  onTap: () => Navigator.pop(sheetContext, 'copy'),
                ),
              if (message.isFromClient && !message.isDeleted)
                _MessageActionTile(
                  icon: 'assets/icons/chat/edit.svg',
                  title: tr('Редактировать'),
                  onTap: () => Navigator.pop(sheetContext, 'edit'),
                ),
              if (!message.isDeleted)
                _MessageActionTile(
                  icon: 'assets/icons/chat/pin.svg',
                  title: message.isPinned ? tr('Открепить') : tr('Закрепить'),
                  onTap: () => Navigator.pop(sheetContext, 'pin'),
                ),
              _MessageActionTile(
                icon: 'assets/icons/chat/delete.svg',
                title: tr('Удалить'),
                destructive: true,
                onTap: () => Navigator.pop(sheetContext, 'delete'),
              ),
            ],
          ),
        );
      },
    );

    if (!mounted || action == null) return;

    if (action.startsWith('react:')) {
      await _setReaction(message, action.substring('react:'.length));
      return;
    }

    switch (action) {
      case 'copy':
        await Clipboard.setData(ClipboardData(text: message.body));
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr('Сообщение скопировано')),
            duration: Duration(seconds: 1),
          ),
        );
        break;

      case 'pin':
        await _toggleMessagePin(message);
        break;

      case 'delete':
        await _showDeleteMessageDialog(message);
        break;

      case 'reply':
        _startReply(message);
        break;

      case 'edit':
        _startEdit(message);
        break;
    }
  }

  Future<void> _toggleMessagePin(ChatMessage message) async {
    try {
      await context.read<ChatRepository>().togglePinMessage(
        widget.conversationId,
        message.id,
      );

      if (!mounted) return;

      await _refreshMessages();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(trf('Не удалось изменить закрепление: {0}', [e]))),
      );
    }
  }

  Future<void> _showDeleteMessageDialog(ChatMessage message) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (sheetContext) {
        return Container(
          margin: const EdgeInsets.fromLTRB(8, 8, 8, 8),
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 6),
          decoration: BoxDecoration(
            color: _M5.bg(sheetContext),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _M5.lineOf(sheetContext)),
            boxShadow: const [
              BoxShadow(color: Color(0x29783400), blurRadius: 40, offset: Offset(0, 12)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _MessageActionTile(
                icon: 'assets/icons/chat/delete.svg',
                title: tr('Удалить у себя'),
                destructive: true,
                onTap: () => Navigator.pop(sheetContext, 'me'),
              ),
              if (message.isFromClient)
                _MessageActionTile(
                  icon: 'assets/icons/chat/delete.svg',
                  title: tr('Удалить у всех'),
                  destructive: true,
                  onTap: () => Navigator.pop(sheetContext, 'everyone'),
                ),
            ],
          ),
        );
      },
    );

    if (!mounted || action == null) return;

    try {
      if (action == 'me') {
        await context.read<ChatRepository>().deleteMessageForMe(
          widget.conversationId,
          message.id,
        );

        if (!mounted) return;

        setState(() {
          _messages.removeWhere((item) => item.id == message.id);
        });
      }

      if (action == 'everyone') {
        await context.read<ChatRepository>().deleteMessageForEveryone(
          widget.conversationId,
          message.id,
        );

        if (!mounted) return;

        await _refreshMessages();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(trf('Не удалось удалить сообщение: {0}', [e]))),
      );
    }
  }

  Future<void> _refreshMessages() async {
    final messages = await context.read<ChatRepository>().fetchMessages(
      widget.conversationId,
    );

    if (!mounted) return;

    setState(() {
      _messages
        ..clear()
        ..addAll(messages);

      _lastTimestamp =
          messages.isEmpty
              ? null
              : messages.last.createdAt.toUtc().toIso8601String();
    });
  }

  void _startReply(ChatMessage message) {
    if (message.isDeleted) return;

    setState(() {
      _editingMessage = null;
      _replyingTo = message;
    });

    _focusNode.requestFocus();
  }

  void _startEdit(ChatMessage message) {
    if (message.isDeleted) return;

    setState(() {
      _replyingTo = null;
      _editingMessage = message;
      _inputCtrl.text = message.body;
      _inputCtrl.selection = TextSelection.collapsed(
        offset: _inputCtrl.text.length,
      );
    });

    _focusNode.requestFocus();
  }

  void _cancelReplyOrEdit() {
    setState(() {
      final wasEditing = _editingMessage != null;

      _replyingTo = null;
      _editingMessage = null;

      if (wasEditing) {
        _inputCtrl.clear();
      }
    });

    _focusNode.requestFocus();
  }

  Future<void> _pickImage({ImageSource source = ImageSource.gallery}) async {
    final image = await _picker.pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 70,
    );
    if (image != null && mounted) {
      setState(() => _pickedImage = image);
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(withData: true);
    if (result != null && result.files.isNotEmpty && mounted) {
      setState(() => _pickedFile = result.files.first);
    }
  }

  void _clearPickedFile() {
    setState(() => _pickedFile = null);
  }

  void _clearPickedImage() {
    setState(() {
      _pickedImage = null;
    });
  }

  Future<void> _send() async {
    final text = _inputCtrl.text.trim();

    final editing = _editingMessage;

    if (editing != null) {
      if (text.isEmpty || _sending) return;

      setState(() => _sending = true);

      try {
        final updated = await context.read<ChatRepository>().editMessage(
          widget.conversationId,
          editing.id,
          text,
        );

        if (!mounted) return;

        setState(() {
          final index = _messages.indexWhere((m) => m.id == updated.id);

          if (index != -1) {
            _messages[index] = updated;
          }

          _editingMessage = null;
          _replyingTo = null;
          _inputCtrl.clear();
        });
      } catch (e) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(trf('Не удалось изменить сообщение: {0}', [e]))),
        );
      } finally {
        if (mounted) {
          setState(() => _sending = false);
        }
      }

      return;
    }

    final hasImage = _pickedImage != null;
    final hasFile = _pickedFile != null;
    if (text.isEmpty && !hasImage && !hasFile) return;
    if (_sending) return;

    String? photoBase64;
    if (hasImage) {
      final bytes = await _pickedImage!.readAsBytes();
      photoBase64 = base64Encode(bytes);
    }

    String? fileBase64;
    String? fileName;
    if (hasFile && _pickedFile!.bytes != null) {
      fileBase64 = base64Encode(_pickedFile!.bytes!);
      fileName = _pickedFile!.name;
    }

    final replyToSend = _replyingTo;

    final tempId = 'temp-${DateTime.now().millisecondsSinceEpoch}';
    final tempType =
        hasImage
            ? 'image'
            : (hasFile &&
                    (fileName?.endsWith('.mp4') == true ||
                        _pickedFile!.name.endsWith('.mp4') == true)
                ? 'video'
                : 'file');

    final tempMsg = ChatMessage(
      id: tempId,
      conversationId: widget.conversationId,
      senderRole: 'client',
      body:
          text.isNotEmpty
              ? text
              : (tempType == 'image'
                  ? tr('Фото')
                  : tempType == 'video'
                  ? tr('Видео')
                  : fileName ?? tr('Файл')),
      createdAt: DateTime.now(),
      fileName: fileName,
      replyToId: replyToSend?.id,
      isTemp: true,
      uploading: true,
      tempType: tempType,
    );

    _inputCtrl.clear();
    final imageToSend = _pickedImage;
    final fileToSend = _pickedFile;
    setState(() {
      _sending = true;
      _pickedImage = null;
      _pickedFile = null;
      _replyingTo = null;
      _messages.add(tempMsg);
    });
    _scrollToBottom();

    try {
      if (!mounted) return;
      final msg = await context.read<ChatRepository>().sendMessage(
        widget.conversationId,
        body: text.isNotEmpty ? text : null,
        photoBase64: hasImage ? 'data:image/jpeg;base64,$photoBase64' : null,
        fileBase64:
            fileBase64 != null
                ? '${_mimeFromName(fileName ?? '')}base64,$fileBase64'
                : null,
        fileName: fileName,
        replyToId: replyToSend?.id,
      );
      if (!mounted) return;
      setState(() {
        final index = _messages.indexWhere((m) => m.id == tempId);
        if (index != -1) {
          _messages[index] = msg;
        } else {
          _messages.add(msg);
        }
        _lastTimestamp = msg.createdAt.toUtc().toIso8601String();
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.removeWhere((m) => m.id == tempId);
        _replyingTo = replyToSend;
      });
      if (text.isNotEmpty) _inputCtrl.text = text;
      if (imageToSend != null) _pickedImage = imageToSend;
      if (fileToSend != null) _pickedFile = fileToSend;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  // AG_SCROLL_FIX: keep scrolling down while messages (photos, link previews) finish layout
  void _scrollToBottom({bool animated = true}) {
    var tries = 0;
    void go() {
      if (!mounted || !_scrollCtrl.hasClients) return;
      final target = _scrollCtrl.position.maxScrollExtent;
      if (animated && tries == 0) {
        _scrollCtrl.animateTo(
          target,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
        );
      } else {
        _scrollCtrl.jumpTo(target);
      }
      tries++;
      if (tries < 6) {
        Future.delayed(Duration(milliseconds: tries == 1 ? 380 : 260), () {
          if (!mounted || !_scrollCtrl.hasClients) return;
          final p = _scrollCtrl.position;
          if (p.maxScrollExtent - p.pixels > 2) go();
        });
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => go());
  }

  @override
  Widget build(BuildContext context) {
    final conv = widget.conversation;

    final chatTitle = tr('AG | Мастер приемщик');

    final departmentName = conv?.departmentName ?? '';
    final chatSubtitle =
        departmentName.isNotEmpty ? departmentName : 'AG Service';

    final photoUrl = conv?.specialistPhotoUrl ?? '';

    // Во вкладке «Чат» возвращаться некуда, стрелка нужна только
    // когда чат открыт отдельным экраном.
    final showBack = widget.bottomInset == 0 && Navigator.of(context).canPop();

    return Scaffold(
      backgroundColor: _M5.bg(context),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(68),
        child: Material(
          color: _M5.bg(context),
          child: SafeArea(
            bottom: false,
            child: Container(
              height: 68,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: _M5.lineOf(context)),
                ),
              ),
              child: Row(
                children: [
                  if (showBack) ...[
                    IconButton(
                      tooltip: tr('Назад'),
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    const SizedBox(width: 4),
                  ],
                  const _AgChatAvatar(size: 46), // AG_CHATUI1: логотип AG + «онлайн» + значок поддержки
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          chatTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.2,
                            fontWeight: FontWeight.w600,
                            color: _M5.inkOf(context),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          chatSubtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.2,
                            fontWeight: FontWeight.w400,
                            color: _M5.mutOf(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                // AG_M5CHAT2: фон-обои как в чате сотрудников
                Positioned.fill(child: _M5Wallpaper()),
                Positioned.fill(child: _buildMessageList()),
                if (_showDownFab || _newBelow > 0)
                  Positioned(
                    right: 14,
                    bottom: 12,
                    child: _M5DownFab(
                      count: _newBelow,
                      onTap: () {
                        setState(() => _newBelow = 0);
                        _scrollToBottom();
                      },
                    ),
                  ),
              ],
            ),
          ),
          _buildInput(),
          if (widget.bottomInset > 0) SizedBox(height: widget.bottomInset),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    if (_initialLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
                color: BrandColors.orange,
              ),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () {
                  setState(() {
                    _error = null;
                    _initialLoading = true;
                  });
                  _loadInitial();
                },
                child: Text(tr('Повторить')),
              ),
            ],
          ),
        ),
      );
    }
    if (_messages.isEmpty) {
      return Center(
        child: Text(
          tr('Напишите сообщение, чтобы начать диалог'),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 14,
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.fromLTRB(10, 10, 12, 6),
      itemCount: _messages.length,
      itemBuilder: (_, i) {
        final msg = _messages[i];
        final prev = i > 0 ? _messages[i - 1] : null;
        final next = i + 1 < _messages.length ? _messages[i + 1] : null;
        final showDate = prev == null || !_sameDay(prev.createdAt, msg.createdAt);
        bool sameGroup(ChatMessage? a, ChatMessage b) =>
            a != null &&
            a.isFromClient == b.isFromClient &&
            _sameDay(a.createdAt, b.createdAt) &&
            b.createdAt.difference(a.createdAt).inMinutes.abs() < 5;
        final isFirst = showDate || !sameGroup(prev, msg);
        final isLast = next == null ||
            !_sameDay(msg.createdAt, next.createdAt) ||
            !sameGroup(msg, next);
        final quoted = _findMessage(msg.replyToId);
        return Column(
          key: _keyFor(msg.id),
          children: [
            if (showDate) _DateDivider(date: msg.createdAt),
            _M5SwipeReply(
              enabled: !msg.isTemp && !msg.isDeleted,
              onReply: () => _startReply(msg),
              child: _MessageBubble(
                message: msg,
                isFirst: isFirst,
                isLast: isLast,
                flash: _flashId == msg.id,
                avatarUrl: widget.conversation?.specialistPhotoUrl,
                quote: quoted,
                hasQuote: (msg.replyToId ?? '').isNotEmpty,
                onQuoteTap: quoted == null ? null : () => _jumpToMessage(quoted.id),
                reaction: _reactions[msg.id],
                onReactionTap: () => _setReaction(msg, null),
                onLongPress: () => _showMessageActions(msg),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildReplyEditPreview() {
    final message = _editingMessage ?? _replyingTo;

    if (message == null) {
      return const SizedBox.shrink();
    }

    final isEditing = _editingMessage != null;

    var preview = message.body.trim();

    if (preview.isEmpty) {
      if (message.hasAudio) {
        preview = tr('Голосовое сообщение');
      } else if (message.photoUrl != null && message.photoUrl!.isNotEmpty) {
        preview = tr('Фото');
      } else if (message.videoUrl != null && message.videoUrl!.isNotEmpty) {
        preview = tr('Видео');
      } else if (message.fileName != null && message.fileName!.isNotEmpty) {
        preview = message.fileName!;
      } else {
        preview = tr('Сообщение');
      }
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(4, 0, 4, 6),
      padding: const EdgeInsets.fromLTRB(10, 6, 6, 6),
      decoration: BoxDecoration(
        color: _M5.dark(context) ? _M5.tintOf(context) : const Color(0xFFFFF8F2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 38,
            decoration: BoxDecoration(
              color: BrandColors.orange,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEditing ? tr('Редактирование') : tr('Ответ на сообщение'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _M5.acc2,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  preview,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 13,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _cancelReplyOrEdit,
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: SvgPicture.asset(
                  'assets/icons/chat/close.svg',
                  width: 20,
                  height: 20,
                  colorFilter: ColorFilter.mode(
                    Theme.of(context).colorScheme.onSurfaceVariant,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInput() {
    if (_isRecordingVoice || _recordedVoiceBytes != null) {
      return _buildVoiceInput();
    }

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 6, 10, 10),
        color: _M5.bg(context),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_replyingTo != null || _editingMessage != null)
              _buildReplyEditPreview(),
            if (_pickedImage != null) _buildImagePreview(),
            if (_pickedFile != null) _buildFilePreview(),

            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                /*
                 * EMOJI
                 */
                SizedBox(
                  width: 44,
                  height: 44,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(22),
                      onTap: _showAttachmentMenu,
                      child: Center(
                        child: SvgPicture.asset(
                          'assets/icons/chat/attach.svg',
                          width: 27,
                          height: 27,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 5),

                /*
                 * MESSAGE FIELD
                 *
                 * minLines 1 / maxLines 5:
                 * поле само увеличивается по мере ввода текста.
                 */
                Expanded(
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 44),
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: _focusNode.hasFocus ? _M5.bg(context) : _M5.tintOf(context),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: _focusNode.hasFocus ? (_M5.dark(context) ? _M5.lineOf(context) : _M5.line2) : Colors.transparent,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _inputCtrl,
                            focusNode: _focusNode,
                            minLines: 1,
                            maxLines: 5,
                            keyboardType: TextInputType.multiline,
                            textInputAction: TextInputAction.newline,
                            textCapitalization: TextCapitalization.sentences,
                            style: const TextStyle(
                              fontSize: 16,
                              height: 1.25,
                              letterSpacing: 0,
                            ),
                            decoration: InputDecoration(
                              hintText: tr('Сообщение'),
                              hintStyle: TextStyle(
                                letterSpacing: 0,
                                color: _M5.dark(context)
                                    ? Theme.of(context).colorScheme.onSurfaceVariant
                                    : _M5.soft,
                                fontSize: 16,
                              ),
                              filled: false,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.fromLTRB(
                                15,
                                12,
                                6,
                                12,
                              ),
                            ),
                            onChanged: (_) {
                              setState(() {});
                            },
                          ),
                        ),

                        /*
                         * ATTACHMENT
                         */
                        SizedBox(
                          width: 43,
                          height: 44,
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(22),
                              onTap: _showEmojiPicker,
                              child: Center(
                                child: SvgPicture.asset(
                                  'assets/icons/chat/smile.svg',
                                  width: 26,
                                  height: 26,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 7),

                /*
                 * MIC <-> SEND
                 */
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 160),
                  transitionBuilder: (child, animation) {
                    return ScaleTransition(
                      scale: animation,
                      child: FadeTransition(opacity: animation, child: child),
                    );
                  },
                  child:
                      _sending
                          ? Container(
                            key: const ValueKey('sending'),
                            width: 46,
                            height: 46,
                            decoration: const BoxDecoration(
                              color: BrandColors.orange,
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: SizedBox(
                                width: 19,
                                height: 19,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          )
                          : _composerHasContent
                          ? _ChatSvgCircleButton(
                            key: const ValueKey('send'),
                            asset: 'assets/icons/chat/send.svg',
                            tooltip: tr('Отправить'),
                            onTap: _send,
                          )
                          : _ChatSvgCircleButton(
                            key: const ValueKey('mic'),
                            asset: 'assets/icons/chat/mic.svg',
                            tooltip: tr('Записать голосовое сообщение'),
                            onTap: _startVoiceRecording,
                          ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVoiceInput() {
    final isDraft = _recordedVoiceBytes != null && !_isRecordingVoice;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 9),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(
            top: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
        ),
        child: Row(
          children: [
            if (_isRecordingVoice) ...[
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                _formatVoiceDuration(_voiceRecordDuration),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  tr('Запись голосового сообщения...'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 14,
                  ),
                ),
              ),
              _VoiceComposerSvgButton(
                asset: 'assets/icons/chat/delete.svg',
                tooltip: tr('Отменить запись'),
                onTap: _cancelVoiceRecording,
                foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 7),
              _VoiceComposerSvgButton(
                asset: 'assets/icons/chat/stop.svg',
                tooltip: tr('Остановить запись'),
                onTap: _stopVoiceRecording,
                filled: true,
              ),
            ] else if (isDraft) ...[
              _VoiceComposerSvgButton(
                asset:
                    _isVoicePreviewPlaying
                        ? 'assets/icons/chat/pause.svg'
                        : 'assets/icons/chat/play.svg',
                tooltip: _isVoicePreviewPlaying ? tr('Пауза') : tr('Прослушать'),
                onTap: _toggleVoicePreview,
                filled: true,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  height: 46,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(23),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: List.generate(22, (index) {
                            final heights = <double>[
                              8,
                              14,
                              20,
                              12,
                              25,
                              17,
                              10,
                              22,
                              15,
                              27,
                              11,
                              19,
                              24,
                              13,
                              21,
                              9,
                              17,
                              26,
                              12,
                              20,
                              15,
                              8,
                            ];

                            return Expanded(
                              child: Center(
                                child: Container(
                                  width: 2,
                                  height: heights[index],
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: BrandColors.orange.withValues(
                                      alpha: 0.65,
                                    ),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _formatVoiceDuration(_voiceRecordDuration),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 7),
              _VoiceComposerSvgButton(
                asset: 'assets/icons/chat/delete.svg',
                tooltip: tr('Удалить запись'),
                onTap: _cancelVoiceRecording,
                foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 7),
              _sending
                  ? Container(
                    width: 46,
                    height: 46,
                    decoration: const BoxDecoration(
                      color: BrandColors.orange,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: SizedBox(
                        width: 19,
                        height: 19,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  )
                  : _VoiceComposerSvgButton(
                    asset: 'assets/icons/chat/send.svg',
                    tooltip: tr('Отправить голосовое'),
                    onTap: _sendRecordedVoice,
                    filled: true,
                  ),
            ],
          ],
        ),
      ),
    );
  }

  bool get _composerHasContent {
    return _inputCtrl.text.trim().isNotEmpty ||
        _pickedImage != null ||
        _pickedFile != null;
  }

  void _showEmojiPicker() {
    const emojis = <String>[
      '😀',
      '😁',
      '😂',
      '😊',
      '😍',
      '😘',
      '😎',
      '🥰',
      '😉',
      '🙂',
      '🤔',
      '👍',
      '👏',
      '🙏',
      '❤️',
      '🔥',
      '🎉',
      '✅',
      '👌',
      '💯',
      '🚗',
      '🔧',
      '🛠️',
      '📍',
      '😅',
      '😢',
      '😮',
      '😡',
      '🤝',
      '👋',
      '💪',
      '⏰',
      '📞',
      '💬',
      '⛽',
      '🛞',
    ];

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.all(10),
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 18),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(22),
            ),
            child: GridView.builder(
              shrinkWrap: true,
              itemCount: emojis.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
              ),
              itemBuilder: (_, index) {
                final emoji = emojis[index];

                return InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    final selection = _inputCtrl.selection;

                    final oldText = _inputCtrl.text;

                    final offset =
                        selection.isValid ? selection.start : oldText.length;

                    final safeOffset = offset.clamp(0, oldText.length);

                    final newText =
                        oldText.substring(0, safeOffset) +
                        emoji +
                        oldText.substring(safeOffset);

                    _inputCtrl.value = TextEditingValue(
                      text: newText,
                      selection: TextSelection.collapsed(
                        offset: safeOffset + emoji.length,
                      ),
                    );

                    Navigator.pop(sheetContext);

                    setState(() {});

                    _focusNode.requestFocus();
                  },
                  child: Center(
                    child: Text(emoji, style: const TextStyle(fontSize: 27)),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  // AG_M5CHAT3: меню вложений как в чате сотрудников — Камера, Галерея, Файл, Местоположение, Сканер штрихкода
  void _showAttachmentMenu() {
    final items = <(String, Color, String, VoidCallback)>[
      if (!kIsWeb) (_M5Ic.cam, const Color(0xFFF26200), tr('Камера'), () => _pickImage(source: ImageSource.camera)),
      (_M5Ic.gal, const Color(0xFF3B82F6), tr('Галерея'), () => _pickImage()),
      (_M5Ic.file, const Color(0xFF8B5CF6), tr('Файл'), () => _pickFile()),
      (_M5Ic.geo, const Color(0xFF16A34A), tr('Местоположение'), _sendLocation),
      (_M5Ic.scan, const Color(0xFF0F766E), tr('Сканер штрихкода'), _openScanner),
    ];
    final bottom = MediaQuery.of(context).padding.bottom + widget.bottomInset + 64;
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: tr('Закрыть'),
      barrierColor: Colors.black.withValues(alpha: 0.08),
      transitionDuration: const Duration(milliseconds: 140),
      pageBuilder: (dc, _, __) => SafeArea(
        child: Align(
          alignment: Alignment.bottomLeft,
          child: Padding(
            padding: EdgeInsets.fromLTRB(10, 0, 10, bottom),
            child: Material(
              color: _M5.bg(dc),
              elevation: 0,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: 260,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _M5.lineOf(dc)),
                  boxShadow: const [BoxShadow(color: Color(0x29783400), blurRadius: 40, offset: Offset(0, 12))],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final it in items)
                      InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () {
                          Navigator.pop(dc);
                          it.$4();
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(color: it.$2, shape: BoxShape.circle),
                                child: SvgPicture.string(it.$1),
                              ),
                              const SizedBox(width: 12),
                              Text(it.$3, style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w500, color: _M5.inkOf(dc))),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      transitionBuilder: (_, anim, __, child) => FadeTransition(
        opacity: anim,
        child: ScaleTransition(
          alignment: Alignment.bottomLeft,
          scale: Tween<double>(begin: 0.92, end: 1).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
          child: child,
        ),
      ),
    );
  }

  void _toast(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  /// Отправляет готовый текст как обычное сообщение, сохраняя то, что клиент уже набрал.
  Future<void> _sendPreparedText(String text) async {
    if (_pickedImage != null || _pickedFile != null) {
      _toast(tr('Сначала отправьте или уберите прикреплённый файл'));
      return;
    }
    if (_editingMessage != null) {
      _toast(tr('Сначала закончите редактирование сообщения'));
      return;
    }
    final draft = _inputCtrl.text;
    _inputCtrl.text = text;
    await _send();
    if (mounted && draft.isNotEmpty && _inputCtrl.text.isEmpty) _inputCtrl.text = draft;
  }

  void _insertText(String text) {
    final cur = _inputCtrl.text;
    final next = cur.isEmpty ? text : (cur.endsWith(' ') ? '$cur$text' : '$cur $text');
    _inputCtrl.text = next;
    _inputCtrl.selection = TextSelection.collapsed(offset: next.length);
    _focusNode.requestFocus();
    setState(() {});
  }

  // ---------- 📍 Местоположение (как у сотрудников: ссылка на Яндекс Карты) ----------
  Future<void> _sendLocation() async {
    Position? pos;
    String? err;
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        err = tr('Включите геолокацию (GPS) на телефоне и попробуйте ещё раз.');
      } else {
        var perm = await Geolocator.checkPermission();
        if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
        if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
          err = tr('Нет доступа к местоположению. Разрешите его в настройках.');
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(tr('Определяю, где вы…')), duration: Duration(seconds: 2)),
            );
          }
          pos = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              timeLimit: Duration(seconds: 20),
            ),
          );
        }
      }
    } catch (_) {
      err = tr('Не удалось определить местоположение. Попробуйте ещё раз.');
    }
    if (!mounted) return;
    if (pos == null) {
      _toast(err ?? tr('Не удалось определить местоположение.'));
      return;
    }
    final p = pos;
    final ok = await showDialog<bool>(
      context: context,
      builder: (dc) => AlertDialog(
        backgroundColor: _M5.bg(dc),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(tr('📍 Местоположение')),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: _M5MapPreview(lat: p.latitude, lon: p.longitude, height: 180),
              ),
              const SizedBox(height: 8),
              Text(
                trf('Точность ±{0} м', [p.accuracy.round()]),
                style: TextStyle(fontSize: 13, color: _M5.mutOf(dc)),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dc, false), child: Text(tr('Отмена'))),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _M5.acc),
            onPressed: () => Navigator.pop(dc, true),
            child: Text(tr('Отправить')),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _sendPreparedText(trf('📍 Местоположение\n{0}', [_M5Geo.url(p.latitude, p.longitude)]));
    }
  }

  // ---------- Сканер штрихкода (VIN или код запчасти) ----------
  Future<void> _openScanner() async {
    final raw = await Navigator.of(context).push<String>(
      MaterialPageRoute(fullscreenDialog: true, builder: (_) => const _M5ScannerPage()),
    );
    if (!mounted || raw == null || raw.trim().isEmpty) return;
    var code = raw.trim().toUpperCase().replaceAll(RegExp(r'\s+'), '');
    if (code.length == 18 && code.startsWith('I')) code = code.substring(1); // Code 39 на стойке двери
    final isVin = RegExp(r'^[A-HJ-NPR-Z0-9]{17}$').hasMatch(code);
    final text = isVin ? code : raw.trim();
    final act = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sc) => SafeArea(
        child: Container(
          margin: const EdgeInsets.all(10),
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
          decoration: BoxDecoration(color: _M5.bg(sc), borderRadius: BorderRadius.circular(20)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(isVin ? 'VIN' : tr('Код'), style: TextStyle(fontSize: 13, color: _M5.mutOf(sc))),
              const SizedBox(height: 4),
              SelectableText(text,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: 1, color: _M5.inkOf(sc), fontFamily: 'monospace')),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: _M5.acc, minimumSize: const Size.fromHeight(44)),
                      onPressed: () => Navigator.pop(sc, 'ins'),
                      child: Text(tr('Вставить в сообщение')),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(44), foregroundColor: _M5.acc2),
                      onPressed: () => Navigator.pop(sc, 'again'),
                      child: Text(tr('Сканировать ещё')),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (!mounted) return;
    if (act == 'ins') _insertText(isVin ? 'VIN $text' : text);
    if (act == 'again') _openScanner();
  }

  Future<void> _startVoiceRecording() async {
    if (_sending || _isRecordingVoice) return;

    try {
      final allowed = await _audioRecorder.hasPermission();

      if (!allowed) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('Разрешите доступ к микрофону.'))),
        );
        return;
      }

      // Удаляем предыдущую запись, если пользователь решил записать новую.
      await _voicePreviewPlayer.stop();

      _voiceTimer?.cancel();
      await _voiceStreamSubscription?.cancel();

      _voicePcmBytes.clear();

      setState(() {
        _recordedVoiceBytes = null;
        _voiceRecordDuration = Duration.zero;
        _isVoicePreviewPlaying = false;
        _isRecordingVoice = true;
      });

      const config = RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: 16000,
        numChannels: 1,
        echoCancel: true,
        noiseSuppress: true,
        autoGain: true,
      );

      final stream = await _audioRecorder.startStream(config);

      _voiceStreamSubscription = stream.listen(
        (chunk) {
          _voicePcmBytes.addAll(chunk);
        },
        onError: (Object error) {
          if (!mounted) return;

          _voiceTimer?.cancel();

          setState(() {
            _isRecordingVoice = false;
          });

          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(trf('Ошибка записи: {0}', [error]))));
        },
      );

      _voiceTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted || !_isRecordingVoice) return;

        setState(() {
          _voiceRecordDuration += const Duration(seconds: 1);
        });
      });
    } catch (e) {
      _voiceTimer?.cancel();

      if (!mounted) return;

      setState(() {
        _isRecordingVoice = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(trf('Не удалось включить микрофон: {0}', [e]))),
      );
    }
  }

  Future<void> _stopVoiceRecording() async {
    if (!_isRecordingVoice) return;

    try {
      _voiceTimer?.cancel();
      _voiceTimer = null;

      // Останавливаем recorder.
      // На Flutter Web StreamSubscription.asFuture() может зависнуть,
      // поэтому не ждём его бесконечно.
      await _audioRecorder.stop();

      // Даём браузеру короткое время передать последний audio chunk.
      await Future<void>.delayed(const Duration(milliseconds: 150));

      await _voiceStreamSubscription?.cancel();
      _voiceStreamSubscription = null;

      if (_voicePcmBytes.isEmpty) {
        if (!mounted) return;

        setState(() {
          _isRecordingVoice = false;
          _recordedVoiceBytes = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr('Не удалось записать голосовое сообщение.')),
          ),
        );
        return;
      }

      final wav = _pcm16ToWav(
        Uint8List.fromList(_voicePcmBytes),
        sampleRate: 16000,
        channels: 1,
      );

      if (!mounted) return;

      setState(() {
        _isRecordingVoice = false;
        _recordedVoiceBytes = wav;

        if (_voiceRecordDuration.inSeconds < 1) {
          _voiceRecordDuration = const Duration(seconds: 1);
        }
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isRecordingVoice = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(trf('Не удалось завершить запись: {0}', [e]))),
      );
    }
  }

  Future<void> _cancelVoiceRecording() async {
    _voiceTimer?.cancel();
    _voiceTimer = null;

    try {
      if (_isRecordingVoice) {
        await _audioRecorder.cancel();
      }
    } catch (_) {}

    await _voiceStreamSubscription?.cancel();
    _voiceStreamSubscription = null;

    try {
      await _voicePreviewPlayer.stop();
    } catch (_) {}

    _voicePcmBytes.clear();

    if (!mounted) return;

    setState(() {
      _isRecordingVoice = false;
      _isVoicePreviewPlaying = false;
      _recordedVoiceBytes = null;
      _voiceRecordDuration = Duration.zero;
    });
  }

  Future<void> _toggleVoicePreview() async {
    final bytes = _recordedVoiceBytes;

    if (bytes == null || bytes.isEmpty) return;

    try {
      if (_isVoicePreviewPlaying) {
        await _voicePreviewPlayer.pause();

        if (mounted) {
          setState(() => _isVoicePreviewPlaying = false);
        }

        return;
      }

      if (_voicePreviewPlayer.processingState == ProcessingState.completed) {
        await _voicePreviewPlayer.seek(Duration.zero);
      }

      if (_voicePreviewPlayer.audioSource == null) {
        final uri = Uri.dataFromBytes(bytes, mimeType: 'audio/wav');

        await _voicePreviewPlayer.setUrl(uri.toString());
      }

      if (mounted) {
        setState(() => _isVoicePreviewPlaying = true);
      }

      unawaited(
        _voicePreviewPlayer.play().whenComplete(() {
          if (!mounted) return;

          setState(() {
            _isVoicePreviewPlaying = false;
          });
        }),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() => _isVoicePreviewPlaying = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(trf('Не удалось воспроизвести запись: {0}', [e]))),
      );
    }
  }

  Future<void> _sendRecordedVoice() async {
    final bytes = _recordedVoiceBytes;

    if (bytes == null || bytes.isEmpty || _sending) return;

    final durationSeconds =
        _voiceRecordDuration.inSeconds < 1 ? 1 : _voiceRecordDuration.inSeconds;

    final replyToSend = _replyingTo;
    final repository = context.read<ChatRepository>();

    setState(() {
      _sending = true;
    });

    try {
      await _voicePreviewPlayer.stop();

      final msg = await repository.sendMessage(
        widget.conversationId,
        audioBase64: 'data:audio/wav;base64,${base64Encode(bytes)}',
        audioDuration: durationSeconds,
        replyToId: replyToSend?.id,
      );

      if (!mounted) return;

      setState(() {
        _messages.add(msg);
        _lastTimestamp = msg.createdAt.toUtc().toIso8601String();

        _recordedVoiceBytes = null;
        _voiceRecordDuration = Duration.zero;
        _isVoicePreviewPlaying = false;
        _replyingTo = null;
      });

      _voicePcmBytes.clear();
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(trf('Не удалось отправить голосовое сообщение: {0}', [e]))),
      );
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  Uint8List _pcm16ToWav(
    Uint8List pcm, {
    required int sampleRate,
    required int channels,
  }) {
    const bitsPerSample = 16;

    final byteRate = sampleRate * channels * bitsPerSample ~/ 8;
    final blockAlign = channels * bitsPerSample ~/ 8;

    final result = Uint8List(44 + pcm.length);
    final data = ByteData.sublistView(result);

    void writeAscii(int offset, String value) {
      for (var i = 0; i < value.length; i++) {
        result[offset + i] = value.codeUnitAt(i);
      }
    }

    writeAscii(0, 'RIFF');
    data.setUint32(4, 36 + pcm.length, Endian.little);
    writeAscii(8, 'WAVE');

    writeAscii(12, 'fmt ');
    data.setUint32(16, 16, Endian.little);
    data.setUint16(20, 1, Endian.little);
    data.setUint16(22, channels, Endian.little);
    data.setUint32(24, sampleRate, Endian.little);
    data.setUint32(28, byteRate, Endian.little);
    data.setUint16(32, blockAlign, Endian.little);
    data.setUint16(34, bitsPerSample, Endian.little);

    writeAscii(36, 'data');
    data.setUint32(40, pcm.length, Endian.little);

    result.setRange(44, result.length, pcm);

    return result;
  }

  String _formatVoiceDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);

    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  Widget _buildImagePreview() {
    return Container(
      height: 80,
      margin: const EdgeInsets.only(bottom: 8, left: 8),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: kIsWeb /* AG_WEB_PREVIEW */ ? Image.network(_pickedImage!.path, width: 80, height: 80, fit: BoxFit.cover) : Image.file(File(_pickedImage!.path),
              width: 80,
              height: 80,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _pickedImage!.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13),
            ),
          ),
          IconButton(
            onPressed: _clearPickedImage,
            icon: const Icon(Icons.close, size: 18),
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }

  Widget _buildFilePreview() {
    final name = _pickedFile!.name;
    final ext = name.contains('.') ? name.split('.').last.toUpperCase() : '?';
    return Container(
      height: 60,
      margin: const EdgeInsets.only(bottom: 8, left: 8),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: BrandColors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                ext,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: BrandColors.orange,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13),
            ),
          ),
          IconButton(
            onPressed: _clearPickedFile,
            icon: const Icon(Icons.close, size: 18),
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _VoiceComposerSvgButton extends StatelessWidget {
  const _VoiceComposerSvgButton({
    required this.asset,
    required this.tooltip,
    required this.onTap,
    this.filled = false,
    this.foregroundColor,
  });

  final String asset;
  final String tooltip;
  final VoidCallback onTap;
  final bool filled;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final iconColor =
        foregroundColor ??
        (filled
            ? Colors.white
            : Theme.of(context).colorScheme.onSurfaceVariant);

    return Tooltip(
      message: tooltip,
      child: Material(
        color: filled ? BrandColors.orange : Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 46,
            height: 46,
            child: Center(
              child: SvgPicture.asset(
                asset,
                width: 23,
                height: 23,
                colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChatSvgCircleButton extends StatelessWidget {
  const _ChatSvgCircleButton({
    super.key,
    required this.asset,
    required this.tooltip,
    required this.onTap,
  });

  final String asset;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: _M5.acc,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Center(
              child: SvgPicture.asset(asset, width: 23, height: 23),
            ),
          ),
        ),
      ),
    );
  }
}

class _DateDivider extends StatelessWidget {
  const _DateDivider({required this.date});
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    String label;
    if (now.year == date.year &&
        now.month == date.month &&
        now.day == date.day) {
      label = tr('Сегодня');
    } else if (now.difference(date).inDays == 1) {
      label = tr('Вчера');
    } else {
      label = DateFormat('d MMMM', AgI18n.dateLocale).format(date);
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 8),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2A211B) : _M5.tint,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: isDark ? Theme.of(context).colorScheme.onSurfaceVariant : _M5.mut,
            ),
          ),
        ),
      ),
    );
  }
}

class FullScreenImage extends StatefulWidget {
  final String photoUrl;
  final String? caption;

  const FullScreenImage({super.key, required this.photoUrl, this.caption});

  @override
  State<FullScreenImage> createState() => _FullScreenImageState();
}

class _FullScreenImageState extends State<FullScreenImage> {
  final _transformationController = TransformationController();

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title:
            widget.caption != null && widget.caption != 'Фото'
                ? Text(
                  widget.caption!,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                )
                : null,
      ),
      body: InteractiveViewer(
        transformationController: _transformationController,
        minScale: 1,
        maxScale: 5,
        child: Center(
          child: CachedNetworkImage(
            imageUrl: widget.photoUrl,
            placeholder:
                (_, __) => const Center(
                  child: SizedBox(
                    width: 30,
                    height: 30,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                ),
            errorWidget:
                (_, __, ___) => const Icon(
                  Icons.broken_image,
                  color: Colors.white,
                  size: 64,
                ),
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}

String _mimeFromName(String name) {
  if (!name.contains('.')) return 'data:application/octet-stream;';
  final ext = name.split('.').last.toLowerCase();
  switch (ext) {
    case 'pdf':
      return 'data:application/pdf;';
    case 'doc':
      return 'data:application/msword;';
    case 'docx':
      return 'data:application/vnd.openxmlformats-officedocument.wordprocessingml.document;';
    case 'xls':
      return 'data:application/vnd.ms-excel;';
    case 'xlsx':
      return 'data:application/vnd.openxmlformats-officedocument.spreadsheetml.sheet;';
    case 'png':
      return 'data:image/png;';
    case 'jpg':
    case 'jpeg':
      return 'data:image/jpeg;';
    case 'gif':
      return 'data:image/gif;';
    case 'webp':
      return 'data:image/webp;';
    case 'txt':
      return 'data:text/plain;';
    case 'csv':
      return 'data:text/csv;';
    case 'zip':
      return 'data:application/zip;';
    case 'rar':
      return 'data:application/vnd.rar;';
    case 'mp4':
      return 'data:video/mp4;';
    default:
      return 'data:application/octet-stream;';
  }
}

void _openFullScreenImage(
  BuildContext context,
  String photoUrl, {
  String? caption,
}) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => FullScreenImage(photoUrl: photoUrl, caption: caption),
    ),
  );
}

Future<void> _openDocument(BuildContext context, String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null) return;
  try {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(tr('Не удалось открыть файл'))));
    }
  }
}

class _MessageActionTile extends StatelessWidget {
  const _MessageActionTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.destructive = false,
  });

  final String icon;
  final String title;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final foreground =
        destructive ? Colors.red : Theme.of(context).colorScheme.onSurface;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(
          children: [
            SvgPicture.asset(
              icon,
              width: 23,
              height: 23,
              colorFilter: ColorFilter.mode(foreground, BlendMode.srcIn),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: foreground,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageLinkContent extends StatefulWidget {
  const _MessageLinkContent({required this.text, required this.isClient});

  final String text;
  final bool isClient;

  @override
  State<_MessageLinkContent> createState() => _MessageLinkContentState();
}

class _MessageLinkContentState extends State<_MessageLinkContent> {
  static final RegExp _urlRegex = RegExp(
    r'https?://[^\s<>()]+',
    caseSensitive: false,
  );

  String? _url;
  Future<LinkPreview?>? _previewFuture;

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  @override
  void didUpdateWidget(covariant _MessageLinkContent oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.text != widget.text) {
      _prepare();
    }
  }

  void _prepare() {
    final match = _urlRegex.firstMatch(widget.text);

    if (match == null) {
      _url = null;
      _previewFuture = null;
      return;
    }

    var url = match.group(0);

    if (url == null || url.isEmpty) {
      _url = null;
      _previewFuture = null;
      return;
    }

    while (url!.endsWith('.') ||
        url.endsWith(',') ||
        url.endsWith(';') ||
        url.endsWith(':') ||
        url.endsWith('!') ||
        url.endsWith('?')) {
      url = url.substring(0, url.length - 1);
    }

    _url = url;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _url == null) return;

      setState(() {
        _previewFuture = context.read<ChatRepository>().fetchLinkPreview(_url!);
      });
    });
  }

  Future<void> _openUrl(String value) async {
    final uri = Uri.tryParse(value);

    if (uri == null) return;

    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('Не удалось открыть ссылку'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final url = _url;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildText(),

        if (url != null && _previewFuture != null) ...[
          const SizedBox(height: 8),
          FutureBuilder<LinkPreview?>(
            future: _previewFuture,
            builder: (context, snapshot) {
              final preview = snapshot.data;

              if (preview == null) {
                return const SizedBox.shrink();
              }

              return _OpenGraphCard(
                preview: preview,
                isClient: widget.isClient,
                onTap: () => _openUrl(preview.url),
              );
            },
          ),
        ],
      ],
    );
  }

  Widget _buildText() {
    final url = _url;

    if (url == null) {
      return SelectableText(
        widget.text,
        style: TextStyle(
          fontSize: 15.5,
          height: 1.32,
          color:
              widget.isClient
                  ? Colors.white
                  : Theme.of(context).colorScheme.onSurface,
        ),
      );
    }

    final index = widget.text.indexOf(url);

    if (index < 0) {
      return SelectableText(
        widget.text,
        style: TextStyle(
          fontSize: 15.5,
          height: 1.32,
          color:
              widget.isClient
                  ? Colors.white
                  : Theme.of(context).colorScheme.onSurface,
        ),
      );
    }

    final before = widget.text.substring(0, index);
    final after = widget.text.substring(index + url.length);

    final normalColor =
        widget.isClient
            ? Colors.white
            : Theme.of(context).colorScheme.onSurface;

    final linkColor = widget.isClient ? Colors.white : BrandColors.orange;

    return Text.rich(
      TextSpan(
        style: TextStyle(fontSize: 15.5, height: 1.32, color: normalColor),
        children: [
          if (before.isNotEmpty) TextSpan(text: before),

          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _openUrl(url),
              child: Text(
                url,
                style: TextStyle(
                  fontSize: 15.5,
                  height: 1.32,
                  color: linkColor,
                  decoration: TextDecoration.underline,
                  decorationColor: linkColor,
                ),
              ),
            ),
          ),

          if (after.isNotEmpty) TextSpan(text: after),
        ],
      ),
    );
  }
}

class _OpenGraphCard extends StatelessWidget {
  const _OpenGraphCard({
    required this.preview,
    required this.isClient,
    required this.onTap,
  });

  final LinkPreview preview;
  final bool isClient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final image = preview.image?.trim() ?? '';
    final title = preview.title?.trim() ?? '';
    final description = preview.description?.trim() ?? '';

    final site =
        (preview.siteName?.trim().isNotEmpty ?? false)
            ? preview.siteName!.trim()
            : (preview.domain?.trim() ?? '');

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color:
              isClient
                  ? Colors.white.withValues(alpha: 0.13)
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                isClient
                    ? Colors.white.withValues(alpha: 0.16)
                    : Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (image.isNotEmpty)
              CachedNetworkImage(
                imageUrl: image,
                height: 150,
                fit: BoxFit.cover,
                placeholder:
                    (_, __) => Container(
                      height: 150,
                      color:
                          isClient
                              ? Colors.white.withValues(alpha: 0.08)
                              : Theme.of(context).colorScheme.outlineVariant,
                    ),
                errorWidget: (_, __, ___) => const SizedBox.shrink(),
              ),

            if (site.isNotEmpty || title.isNotEmpty || description.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(11),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (site.isNotEmpty)
                      Text(
                        site,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color:
                              isClient
                                  ? Colors.white.withValues(alpha: 0.72)
                                  : BrandColors.orange,
                        ),
                      ),

                    if (site.isNotEmpty && title.isNotEmpty)
                      const SizedBox(height: 4),

                    if (title.isNotEmpty)
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.25,
                          fontWeight: FontWeight.w700,
                          color:
                              isClient
                                  ? Colors.white
                                  : Theme.of(context).colorScheme.onSurface,
                        ),
                      ),

                    if (title.isNotEmpty && description.isNotEmpty)
                      const SizedBox(height: 4),

                    if (description.isNotEmpty)
                      Text(
                        description,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.3,
                          color:
                              isClient
                                  ? Colors.white.withValues(alpha: 0.82)
                                  : Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.onLongPress,
    this.reaction,
    this.onReactionTap,
    this.isFirst = true,
    this.isLast = true,
    this.flash = false,
    this.avatarUrl,
    this.quote,
    this.hasQuote = false,
    this.onQuoteTap,
  });

  final ChatMessage message;
  final VoidCallback onLongPress;
  final String? reaction;
  final VoidCallback? onReactionTap;
  final bool isFirst;
  final bool isLast;
  final bool flash;
  final String? avatarUrl;
  final ChatMessage? quote;
  final bool hasQuote;
  final VoidCallback? onQuoteTap;

  String _quoteText(ChatMessage m) {
    if (m.isDeleted) return tr('Сообщение удалено');
    final b = m.body.trim();
    if (b.isNotEmpty && b != 'Фото' && b != 'Видео') return b;
    if (m.hasAudio) return tr('Голосовое сообщение');
    if (m.hasPhoto) return tr('Фото');
    if (m.hasVideo) return tr('Видео');
    if ((m.fileName ?? '').isNotEmpty) return m.fileName!;
    return tr('Сообщение');
  }

  Widget _buildQuote(BuildContext context, bool isClient) {
    final q = quote;
    final title = q == null ? tr('Ответ') : (q.isFromClient ? tr('Вы') : 'AG Service');
    final text = q == null ? tr('Сообщение') : _quoteText(q);
    final thumb = (q != null && q.isPhotoMessage && !q.isDeleted) ? q.photoUrl : null;
    final fg = isClient ? Colors.white : _M5.inkOf(context);
    return GestureDetector(
      onTap: onQuoteTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(6, 6, 6, 0),
        padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
        decoration: BoxDecoration(
          color: isClient
              ? Colors.white.withValues(alpha: 0.20)
              : _M5.acc.withValues(alpha: 0.09),
          borderRadius: BorderRadius.circular(8),
          border: Border(
            left: BorderSide(color: isClient ? Colors.white : _M5.acc, width: 3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (thumb != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: CachedNetworkImage(imageUrl: thumb, width: 34, height: 34, fit: BoxFit.cover),
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13, height: 1.3, fontWeight: FontWeight.w600, color: isClient ? Colors.white : _M5.acc2)),
                  Text(text,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13, height: 1.3, color: fg.withValues(alpha: 0.85))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isClient = message.isFromClient;

    final time = DateFormat('HH:mm').format(message.createdAt);

    final screenWidth = MediaQuery.sizeOf(context).width;

    final maxBubbleWidth = screenWidth >= 700 ? 520.0 : screenWidth * 0.82;

    final isDocument =
        message.isDocument || (message.isTemp && message.tempType == 'file');

    final hasPhoto =
        message.isPhotoMessage ||
        (message.isTemp && message.tempType == 'image');

    final hasVideo =
        message.hasVideo || (message.isTemp && message.tempType == 'video');

    final hasAudio = message.hasAudio;

    final isDeleted = message.isDeleted;

    final rawBody = message.body.trim();

    final hasText =
        !isDeleted &&
        rawBody.isNotEmpty &&
        rawBody != 'Фото' &&
        rawBody != 'Видео' &&
        rawBody != 'Голосовое сообщение' &&
        !(message.isTemp &&
            (message.tempType == 'image' || message.tempType == 'video'));

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final reactionEmoji = reaction;

    // Короткие текстовые сообщения сжимаем по ширине текста.
    final compact =
        !hasPhoto && !hasVideo && !rawBody.toLowerCase().contains('http');
    final geoMsg = _M5Geo.parse(rawBody) != null;

    // AG_M5CHAT1: хвостик только у последнего сообщения в группе
    const r = Radius.circular(18);
    final tail = Radius.circular(isLast ? 4 : 6);
    final Widget bubble = AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            margin: EdgeInsets.only(bottom: reactionEmoji == null ? 0 : 3),
            decoration: BoxDecoration(
              color:
                  isClient
                      ? null
                      : (flash
                          ? _M5.line2
                          : (isDark ? const Color(0xFF2A211B) : _M5.tint)),
              gradient:
                  isClient
                      ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: flash
                            ? const [Color(0xFFFFA25A), Color(0xFFFF7E22)]
                            : const [Color(0xFFFF7E22), _M5.acc],
                      )
                      : null,
              borderRadius: BorderRadius.only(
                topLeft: r,
                topRight: r,
                bottomLeft: isClient ? r : tail,
                bottomRight: isClient ? tail : r,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (hasQuote && !isDeleted) _buildQuote(context, isClient),
                /*
               * DELETED
               */
                if (isDeleted)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 11, 14, 3),
                    child: Text(
                      tr('Сообщение удалено'),
                      style: TextStyle(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        color:
                            isClient
                                ? Colors.white.withValues(alpha: 0.75)
                                : Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),

                /*
               * VIDEO
               */
                if (!isDeleted && hasVideo)
                  Padding(
                    padding: const EdgeInsets.all(4),
                    child:
                        message.isTemp
                            ? Container(
                              width: double.infinity,
                              height: 180,
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            )
                            : ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: _InlineVideoPlayer(
                                url: message.videoUrl!,
                                isClient: isClient,
                              ),
                            ),
                  ),

                /*
               * PHOTO
               */
                if (!isDeleted && hasPhoto)
                  Padding(
                    padding: const EdgeInsets.all(4),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child:
                          message.isTemp
                              ? Container(
                                width: double.infinity,
                                height: 180,
                                color: Colors.black.withValues(alpha: 0.05),
                                child: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              )
                              : GestureDetector(
                                onTap:
                                    () => _openFullScreenImage(
                                      context,
                                      message.photoUrl!,
                                    ),
                                child: CachedNetworkImage(
                                  imageUrl: message.photoUrl!,
                                  width: double.infinity,
                                  height: 210,
                                  fit: BoxFit.cover,
                                  placeholder:
                                      (_, __) => Container(
                                        height: 210,
                                        color:
                                            Theme.of(
                                              context,
                                            ).colorScheme.outlineVariant,
                                        child: const Center(
                                          child: SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          ),
                                        ),
                                      ),
                                  errorWidget:
                                      (_, __, ___) => Container(
                                        height: 120,
                                        padding: const EdgeInsets.all(16),
                                        color:
                                            Theme.of(
                                              context,
                                            ).colorScheme.outlineVariant,
                                        child: Center(
                                          child: Text(
                                            tr('Не удалось загрузить фото'),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),
                                ),
                              ),
                    ),
                  ),

                /*
               * VOICE
               */
                if (!isDeleted && hasAudio)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 2),
                    child: _ChatVoiceMessage(
                      url: message.audioUrl!,
                      duration: message.audioDuration,
                      isClient: isClient,
                    ),
                  ),

                /*
               * DOCUMENT
               */
                if (!isDeleted && isDocument)
                  Container(
                    margin: const EdgeInsets.fromLTRB(6, 6, 6, 2),
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      color:
                          isClient
                              ? Colors.white.withValues(alpha: 0.12)
                              : Colors.black.withValues(alpha: 0.025),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color:
                                isClient
                                    ? Colors.white.withValues(alpha: 0.18)
                                    : BrandColors.orange.withValues(
                                      alpha: 0.10,
                                    ),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.insert_drive_file_outlined,
                            color: isClient ? Colors.white : BrandColors.orange,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            message.fileName ?? tr('Файл'),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color:
                                  isClient
                                      ? Colors.white
                                      : Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                        if (!message.uploading)
                          IconButton(
                            tooltip: tr('Открыть'),
                            onPressed:
                                () => _openDocument(context, message.fileUrl!),
                            icon: Icon(
                              Icons.open_in_new_rounded,
                              size: 20,
                              color:
                                  isClient ? Colors.white : BrandColors.orange,
                            ),
                          )
                        else
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                      ],
                    ),
                  ),

                /*
               * TEXT
               */
                if (hasText)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(11, 7, 11, 0),
                    child: _M5Geo.parse(message.body) != null
                        ? _M5GeoCard(point: _M5Geo.parse(message.body)!, isClient: isClient)
                        : _MessageLinkContent(
                            text: message.body,
                            isClient: isClient,
                          ),
                  ),

                /*
               * META: edited / pin / time
               */
                Padding(
                  padding: const EdgeInsets.fromLTRB(11, 2, 9, 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (message.isPinned) ...[
                        Icon(
                          Icons.push_pin_outlined,
                          size: 12,
                          color:
                              isClient
                                  ? Colors.white.withValues(alpha: 0.72)
                                  : Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                      ],

                      if (message.isEdited) ...[
                        Text(
                          tr('изменено'),
                          style: TextStyle(
                            fontSize: 10,
                            color:
                                isClient
                                    ? Colors.white.withValues(alpha: 0.68)
                                    : Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 5),
                      ],

                      Text(
                        time,
                        style: TextStyle(
                          fontSize: 11.5,
                          color:
                              isClient
                                  ? Colors.white.withValues(alpha: 0.82)
                                  : (isDark ? Theme.of(context).colorScheme.onSurfaceVariant : _M5.soft),
                        ),
                      ),
                      if (isClient) ...[
                        const SizedBox(width: 3),
                        message.isTemp
                            ? SizedBox(
                                width: 11,
                                height: 11,
                                child: CircularProgressIndicator(
                                  strokeWidth: 1.6,
                                  color: Colors.white.withValues(alpha: 0.85),
                                ),
                              )
                            : Icon(Icons.done_all_rounded, size: 16, color: Colors.white.withValues(alpha: 0.9)), // AG_CHATUI1: доставлено
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );

    final Widget content = ConstrainedBox(
          constraints: BoxConstraints(maxWidth: geoMsg ? (maxBubbleWidth < 320 ? maxBubbleWidth : 320) : maxBubbleWidth),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment:
                isClient ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              compact ? IntrinsicWidth(child: bubble) : bubble,
              if (reactionEmoji != null)
                GestureDetector(
                  onTap: onReactionTap,
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(6, 2, 6, 0),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: isClient ? const Color(0xFFFFE2C8) : _M5.bg(context),
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(
                        color: isClient ? _M5.line2 : _M5.lineOf(context),
                      ),
                    ),
                    child: Text(
                      reactionEmoji,
                      style: const TextStyle(fontSize: 15),
                    ),
                  ),
                ),
            ],
          ),
        );

    // AG_M5CHAT1: аватар AG слева у последнего сообщения группы, отступы между группами
    final av = (avatarUrl ?? '').isNotEmpty ? avatarUrl! : null;
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onLongPress: message.isTemp ? null : onLongPress,
      child: Padding(
        padding: EdgeInsets.only(top: isFirst ? 8 : 2),
        child: Row(
          mainAxisAlignment: isClient ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isClient) ...[
              SizedBox(
                width: 32,
                height: 32,
                child: isLast
                    ? const _AgChatAvatar(size: 32, badge: false)
                    : null,
              ),
              const SizedBox(width: 8),
            ],
            Flexible(child: content),
          ],
        ),
      ),
    );
  }
}

/// AG_M5CHAT1: свайп вправо по сообщению — «Ответить», как в чате сотрудников.
class _M5SwipeReply extends StatefulWidget {
  const _M5SwipeReply({required this.child, required this.onReply, this.enabled = true});
  final Widget child;
  final VoidCallback onReply;
  final bool enabled;

  @override
  State<_M5SwipeReply> createState() => _M5SwipeReplyState();
}

class _M5SwipeReplyState extends State<_M5SwipeReply> {
  double _dx = 0;
  bool _fired = false;
  static const _trigger = 64.0;

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;
    final p = (_dx / _trigger).clamp(0.0, 1.0);
    return GestureDetector(
      onHorizontalDragUpdate: (d) {
        final nx = (_dx + d.delta.dx).clamp(0.0, 90.0);
        if (nx >= _trigger && !_fired) {
          _fired = true;
          HapticFeedback.selectionClick();
        }
        setState(() => _dx = nx);
      },
      onHorizontalDragEnd: (_) {
        if (_fired) widget.onReply();
        setState(() {
          _dx = 0;
          _fired = false;
        });
      },
      onHorizontalDragCancel: () => setState(() {
        _dx = 0;
        _fired = false;
      }),
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          if (_dx > 4)
            Positioned(
              left: 4,
              child: Opacity(
                opacity: p,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _fired ? _M5.acc : _M5.tintOf(context),
                  ),
                  child: Icon(Icons.reply_rounded, size: 18, color: _fired ? Colors.white : _M5.acc),
                ),
              ),
            ),
          Transform.translate(offset: Offset(_dx, 0), child: widget.child),
        ],
      ),
    );
  }
}

/// AG_M5CHAT3: значки меню вложений — те же, что в чате сотрудников.
class _M5Ic {
  static const _h = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#ffffff" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">';
  static const cam = '$_h<path d="M4 8h3l1.6-2.4A1 1 0 0 1 9.4 5h5.2a1 1 0 0 1 .8.6L17 8h3a1 1 0 0 1 1 1v9a1 1 0 0 1-1 1H4a1 1 0 0 1-1-1V9a1 1 0 0 1 1-1z"/><circle cx="12" cy="13" r="3.5"/></svg>';
  static const gal = '$_h<rect x="3" y="4" width="18" height="16" rx="2.5"/><circle cx="8.5" cy="9.5" r="1.8"/><path d="m21 16-5.2-5.2a1 1 0 0 0-1.4 0L5 20"/></svg>';
  static const file = '$_h<path d="M14 3H7a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h10a2 2 0 0 0 2-2V8z"/><path d="M14 3v5h5"/><path d="M9 13h6M9 17h4"/></svg>';
  static const geo = '$_h<path d="M12 21s-7-6.2-7-11.5a7 7 0 0 1 14 0C19 14.8 12 21 12 21z"/><circle cx="12" cy="9.5" r="2.5"/></svg>';
  static const scan = '$_h<path d="M3 7V5a2 2 0 0 1 2-2h2M17 3h2a2 2 0 0 1 2 2v2M21 17v2a2 2 0 0 1-2 2h-2M7 21H5a2 2 0 0 1-2-2v-2"/><path d="M7 8v8M10 8v8M13 8v8M16 8v8"/></svg>';
}

/// AG_M5CHAT3: формат местоположения общий с чатом сотрудников:
/// «📍 Местоположение\nhttps://yandex.ru/maps/?pt=<lon>,<lat>&z=17&l=map».
class _M5Geo {
  static String url(double lat, double lon) =>
      'https://yandex.ru/maps/?pt=${lon.toStringAsFixed(6)},${lat.toStringAsFixed(6)}&z=17&l=map';

  static (double, double)? parse(String body) {
    final t = body.trim();
    if (!t.startsWith('📍 Местоположение')) return null;
    final m = RegExp(r'yandex\.ru/maps/\?pt=(-?[\d.]+),(-?[\d.]+)').firstMatch(t);
    if (m == null) return null;
    final lon = double.tryParse(m.group(1)!);
    final lat = double.tryParse(m.group(2)!);
    if (lat == null || lon == null) return null;
    return (lat, lon);
  }
}

class _M5MapPreview extends StatelessWidget {
  const _M5MapPreview({required this.lat, required this.lon, this.height = 160});
  final double lat;
  final double lon;
  final double height;

  @override
  Widget build(BuildContext context) {
    final ll = '${lon.toStringAsFixed(6)},${lat.toStringAsFixed(6)}';
    final fallback = Container(
      height: height,
      color: _M5.tintOf(context),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.location_on_rounded, color: _M5.acc, size: 40),
          const SizedBox(height: 4),
          Text('${lat.toStringAsFixed(5)}, ${lon.toStringAsFixed(5)}',
              style: TextStyle(fontSize: 12.5, color: _M5.mutOf(context))),
        ],
      ),
    );
    return SizedBox(
      height: height,
      width: double.infinity,
      child: Image.network(
        'https://static-maps.yandex.ru/1.x/?ll=$ll&z=16&size=450,260&l=map&pt=$ll,pm2rdm',
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback,
        loadingBuilder: (c, child, p) => p == null ? child : fallback,
      ),
    );
  }
}

class _M5GeoCard extends StatelessWidget {
  const _M5GeoCard({required this.point, required this.isClient});
  final (double, double) point;
  final bool isClient;

  @override
  Widget build(BuildContext context) {
    final lat = point.$1, lon = point.$2;
    final fg = isClient ? Colors.white : _M5.acc2;
    Widget btn(String text, String url) => Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
            child: Container(
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isClient ? Colors.white.withValues(alpha: 0.2) : Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(text, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: fg)),
            ),
          ),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(tr('📍 Местоположение'),
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isClient ? Colors.white : _M5.inkOf(context))),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () => launchUrl(Uri.parse(_M5Geo.url(lat, lon)), mode: LaunchMode.externalApplication),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: _M5MapPreview(lat: lat, lon: lon, height: 150),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            btn(tr('Открыть карту'), _M5Geo.url(lat, lon)),
            const SizedBox(width: 6),
            btn(tr('🚗 Маршрут'),
                'https://yandex.ru/maps/?rtext=~${lat.toStringAsFixed(6)},${lon.toStringAsFixed(6)}&rtt=auto'),
          ],
        ),
      ],
    );
  }
}

/// AG_M5CHAT3: экран сканера штрихкода (VIN на стойке двери / под лобовым стеклом, код запчасти).
class _M5ScannerPage extends StatefulWidget {
  const _M5ScannerPage();

  @override
  State<_M5ScannerPage> createState() => _M5ScannerPageState();
}

class _M5ScannerPageState extends State<_M5ScannerPage> {
  final MobileScannerController _ctrl = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: const [
      BarcodeFormat.code39,
      BarcodeFormat.code128,
      BarcodeFormat.code93,
      BarcodeFormat.qrCode,
      BarcodeFormat.dataMatrix,
      BarcodeFormat.pdf417,
      BarcodeFormat.ean13,
      BarcodeFormat.ean8,
      BarcodeFormat.itf,
      BarcodeFormat.upcA,
    ],
  );
  bool _done = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(tr('Сканер штрихкода')),
        actions: [
          IconButton(
            tooltip: tr('Фонарик'),
            icon: const Icon(Icons.flashlight_on_rounded),
            onPressed: () => _ctrl.toggleTorch(),
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _ctrl,
            onDetect: (capture) {
              if (_done) return;
              for (final b in capture.barcodes) {
                final v = b.rawValue;
                if (v != null && v.trim().isNotEmpty) {
                  _done = true;
                  HapticFeedback.mediumImpact();
                  Navigator.of(context).pop(v);
                  return;
                }
              }
            },
          ),
          Center(
            child: Container(
              width: 290,
              height: 150,
              decoration: BoxDecoration(
                border: Border.all(color: _M5.acc, width: 3),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 40,
            child: Text(
              tr('Наведите камеру на штрихкод VIN (стойка двери, под лобовым стеклом) или на штрихкод запчасти.'),
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 15, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

/// AG_M5CHAT2: обои чата (тот же рисунок, что у сотрудников).
class _M5Wallpaper extends StatelessWidget { // AG_CHATUI1: спокойный фон без рисунков
  @override
  Widget build(BuildContext context) {
    final dark = _M5.dark(context);
    return CustomPaint(
      painter: _AgDotsPainter(dark ? const Color(0xFF15171B) : const Color(0xFFF4F5F7), dark ? const Color(0x14FFFFFF) : const Color(0x0F1F2937)),
      child: const SizedBox.expand(),
    );
  }
}

class _AgDotsPainter extends CustomPainter {
  _AgDotsPainter(this.bg, this.dot);
  final Color bg, dot;
  @override
  void paint(Canvas c, Size s) {
    c.drawRect(Offset.zero & s, Paint()..color = bg);
    final p = Paint()..color = dot;
    for (double y = 10; y < s.height; y += 22) {
      for (double x = (y ~/ 22).isEven ? 10 : 21; x < s.width; x += 22) {
        c.drawCircle(Offset(x, y), 1.1, p);
      }
    }
  }
  @override
  bool shouldRepaint(covariant _AgDotsPainter o) => o.bg != bg || o.dot != dot;
}

class _AgChatAvatar extends StatelessWidget {
  const _AgChatAvatar({required this.size, this.badge = true});
  final double size;
  final bool badge;
  @override
  Widget build(BuildContext context) {
    final ring = _M5.dark(context) ? const Color(0xFF15171B) : Colors.white;
    return SizedBox(
      width: size, height: size,
      child: Stack(clipBehavior: Clip.none, children: [
        Container(
          width: size, height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: ring, width: 2),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .12), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: ClipOval(child: Image.asset('assets/logo.png', fit: BoxFit.cover, filterQuality: FilterQuality.high)),
        ),
        if (badge) ...[
          // «онлайн»
          Positioned(
            right: 0, bottom: 0,
            child: Container(
              width: size * .28, height: size * .28,
              decoration: BoxDecoration(color: const Color(0xFF22C55E), shape: BoxShape.circle, border: Border.all(color: ring, width: 2)),
            ),
          ),
        ],
      ]),
    );
  }
}

/// AG_M5CHAT1: круглая кнопка «вниз» со счётчиком новых сообщений.
class _M5DownFab extends StatelessWidget {
  const _M5DownFab({required this.count, required this.onTap});
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: _M5.bg(context),
          shape: const CircleBorder(),
          elevation: 6,
          shadowColor: const Color(0x55783400),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: const SizedBox(
              width: 44,
              height: 44,
              child: Icon(Icons.keyboard_arrow_down_rounded, color: _M5.acc2, size: 28),
            ),
          ),
        ),
        if (count > 0)
          Positioned(
            top: -6,
            right: -4,
            child: Container(
              constraints: const BoxConstraints(minWidth: 20),
              height: 20,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              alignment: Alignment.center,
              decoration: BoxDecoration(color: _M5.acc, borderRadius: BorderRadius.circular(10)),
              child: Text(
                count > 99 ? '99+' : '$count',
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ),
      ],
    );
  }
}

class _ChatVoiceMessage extends StatefulWidget {
  const _ChatVoiceMessage({
    required this.url,
    required this.duration,
    required this.isClient,
  });

  final String url;
  final int? duration;
  final bool isClient;

  @override
  State<_ChatVoiceMessage> createState() => _ChatVoiceMessageState();
}

class _ChatVoiceMessageState extends State<_ChatVoiceMessage> {
  late final AudioPlayer _player;

  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  bool _loading = false;
  bool _playing = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();

    _player = AudioPlayer();

    _duration = Duration(seconds: widget.duration ?? 0);

    _player.positionStream.listen((position) {
      if (!mounted) {
        return;
      }

      setState(() {
        _position = position;
      });
    });

    _player.durationStream.listen((duration) {
      if (!mounted || duration == null) {
        return;
      }

      setState(() {
        _duration = duration;
      });
    });

    _player.playerStateStream.listen((state) {
      if (!mounted) {
        return;
      }

      setState(() {
        _playing = state.playing;

        if (state.processingState == ProcessingState.completed) {
          _position = Duration.zero;
        }
      });
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  String _formatDuration(Duration value) {
    final seconds = value.inSeconds < 0 ? 0 : value.inSeconds;

    final minutes = seconds ~/ 60;
    final rest = seconds % 60;

    return '$minutes:${rest.toString().padLeft(2, '0')}';
  }

  Future<void> _togglePlay() async {
    if (_loading) {
      return;
    }

    try {
      if (_playing) {
        await _player.pause();
        return;
      }

      if (_player.processingState == ProcessingState.completed) {
        await _player.seek(Duration.zero);
      }

      if (_player.audioSource == null) {
        setState(() {
          _loading = true;
          _hasError = false;
        });

        await _player.setUrl(widget.url);
      }

      await _player.play();
    } catch (error) {
      debugPrint('Voice playback error: $error');

      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isClient = widget.isClient;

    final foreground = isClient ? Colors.white : BrandColors.orange;

    final secondary =
        isClient
            ? Colors.white.withValues(alpha: 0.72)
            : Theme.of(context).colorScheme.onSurfaceVariant;

    final totalMs = _duration.inMilliseconds > 0 ? _duration.inMilliseconds : 1;

    final positionMs = _position.inMilliseconds.clamp(0, totalMs);

    final progress = positionMs / totalMs;

    return SizedBox(
      width: 260,
      child: Row(
        children: [
          Material(
            color:
                isClient
                    ? Colors.white.withValues(alpha: 0.18)
                    : BrandColors.orange.withValues(alpha: 0.10),
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: _togglePlay,
              child: SizedBox(
                width: 44,
                height: 44,
                child: Center(
                  child:
                      _loading
                          ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: foreground,
                            ),
                          )
                          : SvgPicture.asset(
                            _playing
                                ? 'assets/icons/chat/pause.svg'
                                : 'assets/icons/chat/play.svg',
                            width: 25,
                            height: 25,
                            colorFilter:
                                isClient
                                    ? const ColorFilter.mode(
                                      Colors.white,
                                      BlendMode.srcIn,
                                    )
                                    : null,
                          ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 24,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: List.generate(24, (index) {
                      const heights = <double>[
                        5,
                        9,
                        14,
                        8,
                        18,
                        11,
                        7,
                        15,
                        20,
                        9,
                        13,
                        6,
                        17,
                        10,
                        19,
                        8,
                        14,
                        7,
                        16,
                        11,
                        6,
                        13,
                        9,
                        5,
                      ];

                      final fraction = (index + 1) / 24;

                      final active = fraction <= progress;

                      return Expanded(
                        child: Center(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 0.7),
                            height: heights[index],
                            decoration: BoxDecoration(
                              color:
                                  active
                                      ? foreground
                                      : foreground.withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),

                const SizedBox(height: 3),

                Row(
                  children: [
                    Text(
                      _formatDuration(
                        _playing || _position > Duration.zero
                            ? _position
                            : _duration,
                      ),
                      style: TextStyle(fontSize: 10.5, color: secondary),
                    ),

                    if (_hasError) ...[
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          tr('Не удалось воспроизвести'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 10, color: secondary),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineVideoPlayer extends StatefulWidget {
  const _InlineVideoPlayer({required this.url, required this.isClient});
  final String url;
  final bool isClient;

  @override
  State<_InlineVideoPlayer> createState() => _InlineVideoPlayerState();
}

class _InlineVideoPlayerState extends State<_InlineVideoPlayer> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  String _errorMsg = '';

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize()
          .then((_) {
            if (mounted) {
              setState(() {
                _isInitialized = true;
              });
            }
          })
          .catchError((error) {
            debugPrint("Video init error: $error");
            if (mounted) {
              setState(() {
                _hasError = true;
                _errorMsg = error.toString();
              });
            }
          });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Container(
        width: 240,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.red.withValues(alpha: 0.7),
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                tr('Не удалось загрузить видео'),
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                _errorMsg,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.red.withValues(alpha: 0.8),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () => _openDocument(context, widget.url),
                icon: const Icon(Icons.open_in_new, size: 14),
                label: Text(
                  tr('Открыть в браузере'),
                  style: TextStyle(fontSize: 10),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: BrandColors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  minimumSize: const Size(100, 28),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isInitialized) {
      return Container(
        width: 240,
        height: 160,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FullScreenVideoPlayer(url: widget.url),
          ),
        );
      },
      child: Container(
        width: 240,
        constraints: const BoxConstraints(maxHeight: 320),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            alignment: Alignment.center,
            children: [
              AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Colors.black45,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow,
                  size: 32,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FullScreenVideoPlayer extends StatefulWidget {
  const FullScreenVideoPlayer({super.key, required this.url});
  final String url;

  @override
  State<FullScreenVideoPlayer> createState() => _FullScreenVideoPlayerState();
}

class _FullScreenVideoPlayerState extends State<FullScreenVideoPlayer> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  String _errorMsg = '';
  bool _showControls = true;
  Timer? _controlsTimer;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize()
          .then((_) {
            if (mounted) {
              setState(() {
                _isInitialized = true;
              });
              _controller.play();
              _startControlsTimer();
            }
          })
          .catchError((error) {
            debugPrint("Full screen video init error: $error");
            if (mounted) {
              setState(() {
                _hasError = true;
                _errorMsg = error.toString();
              });
            }
          });

    _controller.addListener(_videoListener);
  }

  void _videoListener() {
    if (mounted) {
      setState(() {});
    }
  }

  void _startControlsTimer() {
    _controlsTimer?.cancel();
    _controlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _controller.value.isPlaying) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
    if (_showControls) {
      _startControlsTimer();
    }
  }

  @override
  void dispose() {
    _controlsTimer?.cancel();
    _controller.removeListener(_videoListener);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleControls,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Video Player
            if (_isInitialized)
              Center(
                child: AspectRatio(
                  aspectRatio: _controller.value.aspectRatio,
                  child: VideoPlayer(_controller),
                ),
              )
            else if (_hasError)
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.white,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        tr('Не удалось загрузить видео'),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _errorMsg,
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => _openDocument(context, widget.url),
                        icon: const Icon(Icons.open_in_new),
                        label: Text(tr('Открыть в браузере')),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: BrandColors.orange,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          tr('Назад'),
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),

            // Controls Overlay
            if (_isInitialized && _showControls)
              Positioned.fill(
                child: Container(
                  color: Colors.black38,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Top Bar
                      SafeArea(
                        child: Align(
                          alignment: Alignment.topLeft,
                          child: IconButton(
                            icon: const Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                              size: 28,
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                      ),

                      // Play/Pause Center Button
                      Center(
                        child: IconButton(
                          icon: Icon(
                            _controller.value.isPlaying
                                ? Icons.pause_circle_filled
                                : Icons.play_circle_filled,
                            color: Colors.white,
                            size: 72,
                          ),
                          onPressed: () {
                            setState(() {
                              if (_controller.value.isPlaying) {
                                _controller.pause();
                              } else {
                                _controller.play();
                              }
                            });
                            _startControlsTimer();
                          },
                        ),
                      ),

                      // Bottom Progress bar & Duration
                      SafeArea(
                        top: false,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              VideoProgressIndicator(
                                _controller,
                                allowScrubbing: true,
                                colors: const VideoProgressColors(
                                  playedColor: BrandColors.orange,
                                  bufferedColor: Colors.white30,
                                  backgroundColor: Colors.white12,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _formatDuration(_controller.value.position),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    _formatDuration(_controller.value.duration),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}

