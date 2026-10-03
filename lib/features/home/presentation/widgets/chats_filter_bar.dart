import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/mosaed_colors.dart';
import '../../../../core/constants/styles_manager.dart';
import 'chats_filter.dart';

class ChatsFilterBar extends StatelessWidget {
  const ChatsFilterBar({
    super.key,
    required this.filter,
    required this.onChanged,
  });

  final ChatFilter filter;
  final ValueChanged<ChatFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        children: [
          _FilterChip(
            label: 'mosaedChatsAll'.tr(),
            selected: filter == ChatFilter.all,
            onTap: () => onChanged(ChatFilter.all),
          ),
          SizedBox(width: 8.w),
          _FilterChip(
            label: 'mosaedChatsActive'.tr(),
            selected: filter == ChatFilter.active,
            onTap: () => onChanged(ChatFilter.active),
          ),
          SizedBox(width: 8.w),
          _FilterChip(
            label: 'mosaedChatsUnread'.tr(),
            selected: filter == ChatFilter.unread,
            onTap: () => onChanged(ChatFilter.unread),
          ),
          SizedBox(width: 8.w),
          _FilterChip(
            label: 'mosaedChatsCompleted'.tr(),
            selected: filter == ChatFilter.completed,
            onTap: () => onChanged(ChatFilter.completed),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10.r),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 4.w),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: MosaedColors.surfaceWhite,
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(
                color: selected ? MosaedColors.brand : MosaedColors.fieldBorder,
                width: selected ? 1.4 : 1,
              ),
            ),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: (selected ? getSemiBoldStyle : getMediumStyle)(
                fontSize:selected ?14.sp: 12.sp,
                color:
                    selected ? MosaedColors.brand : MosaedColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
