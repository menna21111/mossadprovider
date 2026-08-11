import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/constants/mosaed_colors.dart';
import '../../../core/constants/styles_manager.dart';
import '../../../core/network/failure.dart';
import '../../../core/realtime/chat_session_registry.dart';
import '../../../core/realtime/chat_socket_service.dart';
import '../data/chat_repository.dart';
import '../data/models/chat_message.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.requestId, this.requestTitle});

  final String requestId;
  final String? requestTitle;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  List<ChatMessage> _messages = [];
  ChatSocketService? _socket;
  bool _loading = true;
  bool _sending = false;
  bool _hasMore = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    ChatSessionRegistry.open(widget.requestId);
    _loadHistory();
    _connectSocket();
  }

  @override
  void dispose() {
    ChatSessionRegistry.close(widget.requestId);
    _socket?.dispose();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory({bool loadOlder = false}) async {
    if (loadOlder && !_hasMore) return;

    setState(() {
      _loading = !loadOlder;
      _error = null;
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
      });

      if (!loadOlder) {
        await context
            .read<ChatRepository>()
            .markMessagesAsRead(widget.requestId);
        _scrollToBottom();
      }
    } on ServerFailure catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.errMessage;
        _loading = false;
      });
    }
  }

  Future<void> _connectSocket() async {
    await _socket?.disconnect();
    _socket = ChatSocketService(
      requestId: widget.requestId,
      onMessage: _handleSocketMessage,
      onConnected: (url) {
        if (!mounted) return;
        debugPrint('[Chat] connected: $url');
      },
    );
    await _socket!.connect();
  }

  void _handleSocketMessage(Map<String, dynamic> payload) {
    final event = payload['event']?.toString();

    if (event == 'messages_read') {
      final ids = payload['message_ids'];
      if (ids is! List) return;
      final idSet = ids.map((e) => e.toString()).toSet();
      setState(() {
        _messages = _messages
            .map((m) => idSet.contains(m.id) ? m.copyWith(isRead: true) : m)
            .toList();
      });
      return;
    }

    if (!payload.containsKey('message')) return;

    final message = ChatMessage.fromJson(payload);
    if (message.id.isEmpty) return;
    if (_messages.any((m) => m.id == message.id)) return;

    setState(() {
      final pendingIndex = _messages.indexWhere(
        (m) =>
            m.id.startsWith('local_') &&
            m.isFromProvider &&
            m.message == message.message,
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

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() => _sending = true);
    _controller.clear();

    try {
      if (_socket?.isConnected != true) {
        await _socket?.connect();
      }

      if (_socket?.isConnected == true && _socket!.sendMessage(text)) {
        final optimistic = ChatMessage(
          id: 'local_${DateTime.now().millisecondsSinceEpoch}',
          senderType: 'provider',
          senderId: '',
          message: text,
          isRead: false,
          createdAt: DateTime.now().toIso8601String(),
        );
        if (mounted) {
          setState(() => _messages = [..._messages, optimistic]);
        }
        _scrollToBottom();
        return;
      }

      // Fallback only if socket is down.
      if (!mounted) return;
      final message = await context.read<ChatRepository>().sendMessage(
            requestId: widget.requestId,
            message: text,
          );
      if (mounted) setState(() => _messages = [..._messages, message]);
      _scrollToBottom();
    } on ServerFailure catch (_) {
      if (mounted) _controller.text = text;
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MosaedColors.background,
      appBar: AppBar(
        backgroundColor: MosaedColors.surfaceWhite,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_forward_rounded, color: MosaedColors.primary, size: 22.sp),
        ),
        title: Text(
          widget.requestTitle ?? 'mosaedChat'.tr(),
          style: getBoldStyle(fontSize: 16.sp, color: MosaedColors.textPrimary),
        ),
      ),
      body: Column(
        children: [
          if (_hasMore)
            TextButton(
              onPressed: () => _loadHistory(loadOlder: true),
              child: Text('mosaedLoadOlderMessages'.tr()),
            ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text(_error!))
                    : ListView.builder(
                        controller: _scrollController,
                        padding: EdgeInsets.all(16.w),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          return _MessageBubble(message: msg);
                        },
                      ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'mosaedTypeMessage'.tr(),
                      filled: true,
                      fillColor: MosaedColors.inputFill,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14.r),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                SizedBox(width: 8.w),
                IconButton(
                  onPressed: _sending ? null : _send,
                  icon: Icon(Icons.send_rounded, color: MosaedColors.primary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isMine = message.isFromProvider;
    return Align(
      alignment: isMine ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: EdgeInsets.only(bottom: 8.h),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
        constraints: BoxConstraints(maxWidth: 0.75.sw),
        decoration: BoxDecoration(
          color: isMine ? MosaedColors.primaryContainer : MosaedColors.surface,
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.message,
              style: getRegularStyle(
                fontSize: 14.sp,
                color: isMine ? Colors.white : MosaedColors.textPrimary,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              message.isRead ? '✓✓' : '✓',
              style: getRegularStyle(
                fontSize: 10.sp,
                color: isMine
                    ? Colors.white.withValues(alpha: 0.8)
                    : MosaedColors.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
