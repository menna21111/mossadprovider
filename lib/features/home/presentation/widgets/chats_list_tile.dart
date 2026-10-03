import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/mosaed_colors.dart';
import '../../../../core/constants/styles_manager.dart';
import '../../../chat/data/models/chat_conversation.dart';

class ChatsListTile extends StatelessWidget {
  const ChatsListTile({
    super.key,
    required this.conversation,
    required this.onTap,
  });

  final ChatConversation conversation;
  final VoidCallback onTap;

  String _timeLabel(BuildContext context) {
    final dt = conversation.lastMessageAt;
    if (dt == null) return '';
    final local = dt.toLocal();
    if (context.locale.languageCode == 'ar') {
      final hour = local.hour;
      final isPm = hour >= 12;
      final h = hour % 12 == 0 ? 12 : hour % 12;
      final m = local.minute.toString().padLeft(2, '0');
      return '$h:$m ${isPm ? 'م' : 'ص'}';
    }
    return DateFormat('h:mm a').format(local);
  }

  @override
  Widget build(BuildContext context) {
    final preview = conversation.lastMessage?.trim().isNotEmpty == true
        ? conversation.lastMessage!
        : conversation.requestTitle.isNotEmpty
            ? conversation.requestTitle
            : 'mosaedTapToOpenChat'.tr();
    final time = _timeLabel(context);
    final name = conversation.displayPeerName.isNotEmpty
        ? conversation.displayPeerName
        : 'mosaedClient'.tr();

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        child: Row(
          children: [
            ChatsAvatar(
              url: conversation.hasPeerImage ? conversation.peerImage : null,
              name: name,
              fallbackLetter: 'C',
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: getBoldStyle(
                      fontSize: 15.sp,
                      color: MosaedColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    preview,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: getRegularStyle(
                      fontSize: 13.sp,
                      color: MosaedColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 8.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (time.isNotEmpty)
                  Text(
                    time,
                    style: getRegularStyle(
                      fontSize: 12.sp,
                      color: MosaedColors.textHint,
                    ),
                  ),
                if (conversation.hasUnread) ...[
                  SizedBox(height: 8.h),
                  Container(
                    width: 8.w,
                    height: 8.w,
                    decoration: const BoxDecoration(
                      color: MosaedColors.brand,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ChatsAvatar extends StatelessWidget {
  const ChatsAvatar({
    super.key,
    required this.name,
    this.url,
    this.fallbackLetter = 'C',
  });

  final String name;
  final String? url;
  final String fallbackLetter;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: Container(
        width: 52.w,
        height: 52.w,
        color: MosaedColors.otpFill,
        child: url != null && url!.isNotEmpty
            ? Image.network(
                url!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _initials(),
              )
            : _initials(),
      ),
    );
  }

  Widget _initials() {
    final trimmed = name.trim();
    final isGenericCustomer = trimmed.isEmpty ||
        trimmed.toLowerCase() == 'customer' ||
        trimmed.toLowerCase() == 'client' ||
        trimmed == 'عميل';
    final initial =
        isGenericCustomer ? fallbackLetter : trimmed[0].toUpperCase();
    return Center(
      child: Text(
        initial,
        style: getBoldStyle(fontSize: 18.sp, color: MosaedColors.brand),
      ),
    );
  }
}
