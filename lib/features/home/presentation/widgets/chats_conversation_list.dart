import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/mosaed_colors.dart';
import '../../../chat/data/models/chat_conversation.dart';
import 'chats_list_tile.dart';

class ChatsConversationList extends StatelessWidget {
  const ChatsConversationList({
    super.key,
    required this.conversations,
    required this.onRefresh,
    required this.onOpenChat,
    this.loadingMore = false,
  });

  final List<ChatConversation> conversations;
  final Future<void> Function() onRefresh;
  final ValueChanged<ChatConversation> onOpenChat;
  final bool loadingMore;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: MosaedColors.brand,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h),
        itemCount: conversations.length + (loadingMore ? 1 : 0),
        separatorBuilder: (_, _) => Divider(
          height: 1,
          thickness: 1,
          color: MosaedColors.fieldBorder,
        ),
        itemBuilder: (_, i) {
          if (i >= conversations.length) {
            return Padding(
              padding: EdgeInsets.symmetric(vertical: 12.h),
              child: const Center(
                child: CircularProgressIndicator(color: MosaedColors.brand),
              ),
            );
          }
          final conversation = conversations[i];
          return ChatsListTile(
            conversation: conversation,
            onTap: () => onOpenChat(conversation),
          );
        },
      ),
    );
  }
}
