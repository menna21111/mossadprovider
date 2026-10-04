import 'dart:async';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:page_transition/page_transition.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../../app/functions.dart';
import '../../../core/constants/mosaed_colors.dart';
import '../../../core/constants/styles_manager.dart';
import '../../../core/network/failure.dart';
import '../../../core/realtime/chat_session_registry.dart';
import '../../../core/realtime/chat_socket_service.dart';
import '../../custom_service/presentation/custom_request_detail_screen.dart';
import '../../payments/presentation/widgets/payment_amount_text.dart';
import '../data/chat_repository.dart';
import '../data/models/chat_message.dart';
import 'widgets/chat_attach_sheet.dart';
import 'widgets/chat_input_bar.dart';
import 'widgets/chat_message_bubble.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    required this.requestId,
    this.requestTitle,
    this.peerName,
    this.peerImage,
    this.price,
  });

  final String requestId;
  final String? requestTitle;
  final String? peerName;
  final String? peerImage;
  final double? price;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  static const _imageMaxBytes = 10 * 1024 * 1024;
  static const _voiceMaxBytes = 15 * 1024 * 1024;
  static const _fileMaxBytes = 25 * 1024 * 1024;

  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _recorder = AudioRecorder();
  final _picker = ImagePicker();

  List<ChatMessage> _messages = [];
  ChatSocketService? _socket;
  bool _loading = true;
  bool _sending = false;
  bool _loadingOlder = false;
  bool _hasMore = false;
  bool _recording = false;
  Duration _recordDuration = Duration.zero;
  Timer? _recordTimer;
  String? _recordPath;
  String? _error;

  @override
  void initState() {
    super.initState();
    ChatSessionRegistry.open(widget.requestId);
    _bootstrap();
  }

  @override
  void dispose() {
    ChatSessionRegistry.close(widget.requestId);
    _socket?.dispose();
    _recordTimer?.cancel();
    _recorder.dispose();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    await Future.wait([_loadHistory(), _connectSocket()]);
  }

  Future<void> _loadHistory({bool loadOlder = false}) async {
    if (loadOlder && (!_hasMore || _loadingOlder)) return;

    setState(() {
      if (loadOlder) {
        _loadingOlder = true;
      } else {
        _loading = true;
        _error = null;
      }
    });

    try {
      final page = await context.read<ChatRepository>().getMessages(
        requestId: widget.requestId,
        offset: loadOlder ? _messages.length : 0,
      );
      if (!mounted) return;

      setState(() {
        if (loadOlder) {
          _messages = [...page.results, ..._messages];
        } else {
          _messages = page.results;
        }
        _hasMore = page.hasMore;
        _loading = false;
        _loadingOlder = false;
        _error = null;
      });

      if (!loadOlder) {
        await context.read<ChatRepository>().markMessagesAsRead(
          widget.requestId,
        );
        _scrollToBottom();
      }
    } on ServerFailure catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.errMessage;
        _loading = false;
        _loadingOlder = false;
      });
    }
  }

  Future<void> _connectSocket() async {
    await _socket?.disconnect();

    _socket = ChatSocketService(
      requestId: widget.requestId,
      onMessage: _handleSocketMessage,
      onConnected: (_) {},
      onClose: (_, _) {},
    );
    await _socket!.connect();
  }

  Map<String, dynamic>? _extractMessageMap(Map<String, dynamic> payload) {
    bool looksLikeMessage(Map<String, dynamic> map) {
      return map['id'] != null ||
          map['sender_type'] != null ||
          map['message_type'] != null ||
          map['attachment_url'] != null ||
          map['message'] is String;
    }

    final data = payload['data'];
    if (data is Map<String, dynamic>) {
      if (looksLikeMessage(data)) return data;
      final nested = data['message'];
      if (nested is Map<String, dynamic> && looksLikeMessage(nested)) {
        return nested;
      }
    }
    final message = payload['message'];
    if (message is Map<String, dynamic> && looksLikeMessage(message)) {
      return message;
    }
    if (looksLikeMessage(payload)) return payload;
    return null;
  }

  void _handleSocketMessage(Map<String, dynamic> payload) {
    final data = payload['data'];
    final map = data is Map<String, dynamic> ? data : payload;
    final event =
        (payload['event'] ?? map['event'] ?? payload['type'] ?? map['type'])
            ?.toString()
            .toLowerCase();

    if (event == 'connection_established' ||
        event == 'connected' ||
        event == 'connection_ack') {
      return;
    }

    if (event == 'messages_read') {
      final ids = payload['message_ids'] ?? map['message_ids'];
      if (ids is! List) return;
      final idSet = ids.map((e) => e.toString()).toSet();
      if (!mounted) return;
      setState(() {
        _messages = _messages
            .map((m) => idSet.contains(m.id) ? m.copyWith(isRead: true) : m)
            .toList();
      });
      return;
    }

    final messagePayload = _extractMessageMap(payload);
    if (messagePayload == null) return;

    final message = ChatMessage.fromJson(messagePayload);
    if (message.id.isEmpty &&
        !message.hasCaption &&
        (message.attachmentUrl == null || message.attachmentUrl!.isEmpty)) {
      return;
    }
    if (message.id.isNotEmpty && _messages.any((m) => m.id == message.id)) {
      return;
    }

    if (!mounted) return;
    setState(() {
      final pendingIndex = _messages.indexWhere(
        (m) =>
            m.isLocalPending &&
            m.isFromProvider &&
            m.messageType == message.messageType &&
            ((message.hasCaption && m.message == message.message) ||
                (!message.hasCaption && m.messageType != ChatMessageType.text)),
      );
      if (pendingIndex >= 0 && message.isFromProvider) {
        final updated = [..._messages];
        updated[pendingIndex] = message;
        _messages = updated;
      } else {
        _messages = [..._messages, message];
      }
    });
    _scrollToBottom();

    if (!message.isFromProvider) {
      context.read<ChatRepository>().markMessagesAsRead(widget.requestId);
    }
  }

  ChatMessage _localMessage({
    required String type,
    String text = '',
    String? attachmentUrl,
    int? duration,
    String? fileName,
    int? fileSize,
  }) {
    return ChatMessage(
      id: 'local_${DateTime.now().millisecondsSinceEpoch}',
      senderType: 'provider',
      senderId: '',
      message: text,
      isRead: false,
      createdAt: DateTime.now().toIso8601String(),
      messageType: type,
      attachmentUrl: attachmentUrl,
      attachmentDuration: duration,
      fileName: fileName,
      fileSize: fileSize,
    );
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending || _recording) return;

    setState(() => _sending = true);
    _controller.clear();

    try {
      if (_socket?.isConnected != true) {
        await _socket?.connect();
      }

      if (_socket?.isConnected == true && _socket!.sendMessage(text)) {
        if (mounted) {
          setState(() {
            _messages = [
              ..._messages,
              _localMessage(type: ChatMessageType.text, text: text),
            ];
            _error = null;
          });
        }
        _scrollToBottom();
        return;
      }

      if (!mounted) return;
      final message = await context.read<ChatRepository>().sendMessage(
        requestId: widget.requestId,
        message: text,
      );
      if (mounted) {
        setState(() {
          _messages = [..._messages, message];
          _error = null;
        });
      }
      _scrollToBottom();
    } on ServerFailure catch (e) {
      if (!mounted) return;
      _controller.text = text;
      AppFunctions.showsToast(e.errMessage, MosaedColors.danger, context);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _sendAttachment({
    required String type,
    required String path,
    String? name,
    String? caption,
    int? duration,
  }) async {
    if (_sending) return;
    final repo = context.read<ChatRepository>();
    final file = File(path);
    if (!file.existsSync()) return;

    final size = await file.length();
    final max = type == ChatMessageType.image
        ? _imageMaxBytes
        : type == ChatMessageType.voice
        ? _voiceMaxBytes
        : _fileMaxBytes;
    if (size > max) {
      if (!mounted) return;
      final mb = (max / (1024 * 1024)).round();
      AppFunctions.showsToast(
        'mosaedFileTooLarge'.tr(args: ['$mb']),
        MosaedColors.danger,
        context,
      );
      return;
    }

    final optimistic = _localMessage(
      type: type,
      text: caption ?? '',
      attachmentUrl: path,
      duration: duration,
      fileName: name,
      fileSize: size,
    );
    setState(() {
      _sending = true;
      _messages = [..._messages, optimistic];
    });
    _scrollToBottom();

    try {
      final sent = await repo.send(
        requestId: widget.requestId,
        messageType: type,
        message: caption,
        attachmentPath: path,
        attachmentName: name,
      );
      if (!mounted) return;
      setState(() {
        _messages = _messages
            .map((m) => m.id == optimistic.id ? sent : m)
            .toList();
        _error = null;
      });
    } on ServerFailure catch (e) {
      if (!mounted) return;
      setState(() {
        _messages = _messages.where((m) => m.id != optimistic.id).toList();
      });
      AppFunctions.showsToast(e.errMessage, MosaedColors.danger, context);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _onAttach() async {
    if (!enabled || _recording) return;
    await showChatAttachSheet(
      context: context,
      onCamera: () => _pickImage(ImageSource.camera),
      onGallery: () => _pickImage(ImageSource.gallery),
      onFile: _pickFile,
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final file = await _picker.pickImage(source: source, imageQuality: 85);
      if (file == null) return;
      await _sendAttachment(
        type: ChatMessageType.image,
        path: file.path,
        name: file.name,
      );
    } catch (_) {}
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.any);
      final file = result?.files.single;
      final path = file?.path;
      if (path == null || path.isEmpty) return;
      await _sendAttachment(
        type: ChatMessageType.file,
        path: path,
        name: file?.name,
      );
    } catch (_) {}
  }

  Future<void> _toggleRecording() async {
    if (_recording) {
      await _stopAndSendRecording();
      return;
    }

    bool allowed = false;
    try {
      allowed = await _recorder.hasPermission();
    } catch (_) {
      allowed = false;
    }
    if (!allowed) {
      if (!mounted) return;
      AppFunctions.showsToast(
        'mosaedMicPermission'.tr(),
        MosaedColors.danger,
        context,
      );
      return;
    }

    final dir = await getTemporaryDirectory();
    final path =
        '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
    try {
      await _recorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc, numChannels: 1),
        path: path,
      );
    } catch (_) {
      if (!mounted) return;
      AppFunctions.showsToast(
        'mosaedMicPermission'.tr(),
        MosaedColors.danger,
        context,
      );
      return;
    }
    if (!mounted) return;
    setState(() {
      _recording = true;
      _recordPath = path;
      _recordDuration = Duration.zero;
    });
    _recordTimer?.cancel();
    _recordTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _recordDuration += const Duration(seconds: 1));
    });
  }

  Future<void> _cancelRecording() async {
    _recordTimer?.cancel();
    _recordTimer = null;
    try {
      await _recorder.stop();
    } catch (_) {}
    final path = _recordPath;
    if (path != null) {
      try {
        final f = File(path);
        if (f.existsSync()) f.deleteSync();
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() {
      _recording = false;
      _recordPath = null;
      _recordDuration = Duration.zero;
    });
  }

  Future<void> _stopAndSendRecording() async {
    _recordTimer?.cancel();
    _recordTimer = null;
    String? path;
    try {
      path = await _recorder.stop();
    } catch (_) {
      path = _recordPath;
    }
    final duration = _recordDuration;
    if (!mounted) return;
    setState(() {
      _recording = false;
      _recordPath = null;
      _recordDuration = Duration.zero;
    });
    if (path == null || path.isEmpty || duration.inSeconds < 1) return;
    await _sendAttachment(
      type: ChatMessageType.voice,
      path: path,
      name: 'voice_note.m4a',
      duration: duration.inSeconds,
    );
  }

  bool get enabled => !_loading;

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  void _openRequestDetails() {
    AppFunctions.navigateTo(
      context,
      CustomRequestDetailScreen(requestId: widget.requestId),
      PageTransitionType.rightToLeft,
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.peerName?.trim().isNotEmpty == true
        ? widget.peerName!
        : 'mosaedClient'.tr();

    return Scaffold(
      backgroundColor: MosaedColors.background,
      appBar: AppBar(
        backgroundColor: MosaedColors.surfaceWhite,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.arrow_back_ios,
            color: MosaedColors.textPrimary,
            size: 18.sp,
          ),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _HeaderAvatar(url: widget.peerImage, name: title),
            SizedBox(width: 10.w),
            Flexible(
              child: Text(
                title,
                style: getBoldStyle(
                  fontSize: 15.sp,
                  color: MosaedColors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          if (widget.requestTitle != null &&
              widget.requestTitle!.trim().isNotEmpty)
            _OrderSummaryBar(
              title: widget.requestTitle!,
              price: widget.price,
              onViewDetails: _openRequestDetails,
            ),
          if (_hasMore)
            TextButton(
              onPressed: _loadingOlder
                  ? null
                  : () => _loadHistory(loadOlder: true),
              child: Text(
                _loadingOlder ? '...' : 'mosaedLoadOlderMessages'.tr(),
              ),
            ),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: MosaedColors.brand),
                  )
                : _error != null && _messages.isEmpty
                ? _ErrorState(error: _error!, onRetry: _bootstrap)
                : _messages.isEmpty
                ? Center(
                    child: Text(
                      'mosaedWriteMessage'.tr(),
                      style: getRegularStyle(
                        fontSize: 14.sp,
                        color: MosaedColors.textHint,
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 12.h,
                    ),
                    itemCount: _messages.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return Padding(
                          padding: EdgeInsets.only(bottom: 14.h),
                          child: Center(
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 14.w,
                                vertical: 5.h,
                              ),
                              decoration: BoxDecoration(
                                color: MosaedColors.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(20.r),
                              ),
                              child: Text(
                                'mosaedToday'.tr(),
                                style: getMediumStyle(
                                  fontSize: 11.sp,
                                  color: MosaedColors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        );
                      }
                      final message = _messages[index - 1];
                      return ChatMessageBubble(
                        message: message,
                        peerImage: widget.peerImage,
                        peerName: title,
                      );
                    },
                  ),
          ),
          ChatInputBar(
            controller: _controller,
            enabled: enabled,
            sending: _sending,
            recording: _recording,
            recordDuration: _recordDuration,
            onSend: _send,
            onAttach: _onAttach,
            onMicTap: _toggleRecording,
            onCancelRecord: _cancelRecording,
            onSendRecord: _stopAndSendRecording,
          ),
        ],
      ),
    );
  }
}

class _OrderSummaryBar extends StatelessWidget {
  const _OrderSummaryBar({
    required this.title,
    required this.onViewDetails,
    this.price,
  });

  final String title;
  final double? price;
  final VoidCallback onViewDetails;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 4.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: MosaedColors.surfaceWhite,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: MosaedColors.brand.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: getBoldStyle(
                    fontSize: 13.sp,
                    color: MosaedColors.textPrimary,
                  ),
                ),
                if (price != null && price! > 0) ...[
                  SizedBox(height: 4.h),
                  PaymentAmountText(
                    amount: price!.toStringAsFixed(
                      price!.truncateToDouble() == price ? 0 : 2,
                    ),
                    color: MosaedColors.brand,
                    fontSize: 12,
                    iconSize: 12,
                  ),
                ],
              ],
            ),
          ),
          TextButton(
            onPressed: onViewDetails,
            child: Text(
              'mosaedViewDetails'.tr(),
              style: getBoldStyle(fontSize: 12.sp, color: MosaedColors.brand),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderAvatar extends StatelessWidget {
  const _HeaderAvatar({required this.name, this.url});

  final String name;
  final String? url;

  @override
  Widget build(BuildContext context) {
    final trimmed = name.trim();
    final isGeneric =
        trimmed.isEmpty ||
        trimmed.toLowerCase() == 'customer' ||
        trimmed.toLowerCase() == 'client' ||
        trimmed == 'عميل';
    final letter = isGeneric ? 'C' : trimmed[0].toUpperCase();

    return ClipOval(
      child: Container(
        width: 36.w,
        height: 36.w,
        color: MosaedColors.otpFill,
        child: url != null && url!.isNotEmpty
            ? Image.network(
                url!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Center(
                  child: Text(
                    letter,
                    style: getBoldStyle(
                      fontSize: 14.sp,
                      color: MosaedColors.brand,
                    ),
                  ),
                ),
              )
            : Center(
                child: Text(
                  letter,
                  style: getBoldStyle(
                    fontSize: 14.sp,
                    color: MosaedColors.brand,
                  ),
                ),
              ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error, required this.onRetry});

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              error,
              textAlign: TextAlign.center,
              style: getRegularStyle(
                fontSize: 14.sp,
                color: MosaedColors.textSecondary,
              ),
            ),
            SizedBox(height: 12.h),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text('mosaedRetry'.tr()),
            ),
          ],
        ),
      ),
    );
  }
}
