import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/mosaed_colors.dart';
import '../../../../core/constants/styles_manager.dart';
import '../../data/models/chat_message.dart';
import 'voice_message_player.dart';

class ChatMessageBubble extends StatelessWidget {
  const ChatMessageBubble({
    super.key,
    required this.message,
    this.peerImage,
    this.peerName,
  });

  final ChatMessage message;
  final String? peerImage;
  final String? peerName;

  /// Mine sits on the row *end* (left in RTL, right in LTR).
  /// Peer sits on the row *start* (right in RTL, left in LTR).
  /// Sharp corner is always the outer bottom corner via [BorderRadiusDirectional].
  BorderRadiusGeometry _bubbleRadius(bool isMine) {
    final r = Radius.circular(16.r);
    return BorderRadiusDirectional.only(
      topStart: r,
      topEnd: r,
      // Outer corner (toward screen edge / avatar side) is sharp.
      bottomStart: isMine ? r : Radius.zero,
      bottomEnd: isMine ? Radius.zero : r,
    );
  }

  String _timeLabel(BuildContext context) {
    final raw = message.createdAt;
    if (raw == null || raw.isEmpty) return '';
    final dt = DateTime.tryParse(raw)?.toLocal();
    if (dt == null) return '';
    if (context.locale.languageCode == 'ar') {
      final hour = dt.hour;
      final isPm = hour >= 12;
      final h = hour % 12 == 0 ? 12 : hour % 12;
      final m = dt.minute.toString().padLeft(2, '0');
      return '$h:$m ${isPm ? 'م' : 'ص'}';
    }
    return DateFormat('h:mm a').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    // Provider app: my messages are from provider.
    final isMine = message.isFromProvider;
    final fg = isMine ? Colors.white : MosaedColors.textPrimary;
    final time = _timeLabel(context);

    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Column(
        crossAxisAlignment:
            isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
                isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isMine) ...[
                _SmallAvatar(url: peerImage, name: peerName ?? ''),
                SizedBox(width: 6.w),
              ],
              Flexible(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 280.w),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 14.w,
                      vertical: 12.h,
                    ),
                    decoration: BoxDecoration(
                      color: isMine
                          ? MosaedColors.brand
                          : const Color(0xFFF2F2F2),
                      borderRadius: _bubbleRadius(isMine),
                    ),
                    child: _body(context, fg, isMine),
                  ),
                ),
              ),
            ],
          ),
          if (time.isNotEmpty) ...[
            SizedBox(height: 4.h),
            Padding(
              padding: EdgeInsetsDirectional.only(
                start: isMine ? 0 : 34.w,
                end: isMine ? 4.w : 0,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isMine) ...[
                    Icon(
                      Icons.done_all_rounded,
                      size: 14.sp,
                      color: MosaedColors.brand,
                    ),
                    SizedBox(width: 4.w),
                  ],
                  Text(
                    time,
                    style: getRegularStyle(
                      fontSize: 11.sp,
                      color: MosaedColors.textHint,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _body(BuildContext context, Color fg, bool isMine) {
    switch (message.messageType) {
      case ChatMessageType.image:
        return _ImageBody(message: message, foreground: fg);
      case ChatMessageType.voice:
        return VoiceMessagePlayer(
          url: message.attachmentUrl ?? '',
          durationSeconds: message.attachmentDuration ?? 0,
          isMine: isMine,
        );
      case ChatMessageType.file:
        return _FileBody(message: message, foreground: fg, isMine: isMine);
      default:
        return Text(
          message.message,
          style: getRegularStyle(fontSize: 14.sp, color: fg, height: 1.4),
        );
    }
  }
}

class _ImageBody extends StatelessWidget {
  const _ImageBody({required this.message, required this.foreground});

  final ChatMessage message;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    final url = message.attachmentUrl;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (url != null && url.isNotEmpty)
          GestureDetector(
            onTap: () => _openPreview(context, url),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10.r),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 220.w, maxHeight: 220.h),
                child: message.isLocalAttachment
                    ? Image.file(File(url), fit: BoxFit.cover)
                    : Image.network(
                        url,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Icon(
                          Icons.broken_image_outlined,
                          color: foreground,
                        ),
                      ),
              ),
            ),
          ),
        if (message.hasCaption) ...[
          SizedBox(height: 6.h),
          Text(
            message.message,
            style: getRegularStyle(
              fontSize: 13.sp,
              color: foreground,
              height: 1.35,
            ),
          ),
        ],
      ],
    );
  }

  void _openPreview(BuildContext context, String url) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _ImagePreviewScreen(
          url: url,
          isLocal: message.isLocalAttachment,
        ),
      ),
    );
  }
}

class _FileBody extends StatelessWidget {
  const _FileBody({
    required this.message,
    required this.foreground,
    required this.isMine,
  });

  final ChatMessage message;
  final Color foreground;
  final bool isMine;

  String _sizeLabel() {
    final bytes = message.fileSize ?? 0;
    if (bytes <= 0) return '';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _open() async {
    final url = message.attachmentUrl;
    if (url == null || url.isEmpty || message.isLocalAttachment) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final name = message.fileName?.trim().isNotEmpty == true
        ? message.fileName!
        : 'mosaedChatFile'.tr();
    final size = _sizeLabel();

    return InkWell(
      onTap: _open,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.insert_drive_file_rounded, color: foreground, size: 22.sp),
          SizedBox(width: 8.w),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: getMediumStyle(fontSize: 13.sp, color: foreground),
                ),
                if (size.isNotEmpty)
                  Text(
                    size,
                    style: getRegularStyle(
                      fontSize: 11.sp,
                      color: isMine
                          ? Colors.white.withValues(alpha: 0.8)
                          : MosaedColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallAvatar extends StatelessWidget {
  const _SmallAvatar({required this.name, this.url});

  final String name;
  final String? url;

  @override
  Widget build(BuildContext context) {
    final trimmed = name.trim();
    final isGeneric = trimmed.isEmpty ||
        trimmed.toLowerCase() == 'customer' ||
        trimmed.toLowerCase() == 'client' ||
        trimmed == 'عميل';
    final letter = isGeneric ? 'C' : trimmed[0].toUpperCase();

    return ClipOval(
      child: Container(
        width: 28.w,
        height: 28.w,
        color: MosaedColors.otpFill,
        child: url != null && url!.isNotEmpty
            ? Image.network(
                url!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Center(
                  child: Text(
                    letter,
                    style: getBoldStyle(
                      fontSize: 11.sp,
                      color: MosaedColors.brand,
                    ),
                  ),
                ),
              )
            : Center(
                child: Text(
                  letter,
                  style: getBoldStyle(
                    fontSize: 11.sp,
                    color: MosaedColors.brand,
                  ),
                ),
              ),
      ),
    );
  }
}

class _ImagePreviewScreen extends StatelessWidget {
  const _ImagePreviewScreen({required this.url, required this.isLocal});

  final String url;
  final bool isLocal;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: InteractiveViewer(
          child: isLocal
              ? Image.file(File(url), fit: BoxFit.contain)
              : Image.network(url, fit: BoxFit.contain),
        ),
      ),
    );
  }
}
