import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/constants/assets_manager.dart';
import '../../../../core/constants/mosaed_colors.dart';
import '../../../../core/constants/styles_manager.dart';
import '../../../home/presentation/widgets/home_relative_time.dart';
import '../../data/models/app_notification.dart';

class NotificationListItem extends StatelessWidget {
  const NotificationListItem({
    super.key,
    required this.notification,
    required this.onTap,
    this.showDivider = true,
  });

  final AppNotification notification;
  final VoidCallback onTap;
  final bool showDivider;

  static const _teal = Color(0xFF2A9D8F);
  static const _purple = Color(0xFF7C5CBF);
  static const _green = Color(0xFF1B7A4A);

  Color get _iconBackground {
    switch (notification.normalizedEvent) {
      case 'new_chat_message':
        return MosaedColors.brand;
      case 'new_custom_request':
        return _green;
      case 'new_offer':
        return MosaedColors.brand;
      case 'offer_accepted':
      case 'account_unblocked':
        return _teal;
      case 'offer_rejected':
      case 'offer_cancelled':
        return MosaedColors.danger;
      case 'due_payment_required':
        return _purple;
      case 'booking_assigned':
      case 'booking_status_changed':
      case 'new_booking':
        return MosaedColors.brand;
      default:
        if (notification.eventIcon == ImageAssets.card) return _purple;
        if (notification.eventIcon == ImageAssets.verifyWhite) return _teal;
        if (notification.eventIcon == ImageAssets.offers) return _green;
        if (notification.eventIcon == ImageAssets.taskIcon) {
          return MosaedColors.brand;
        }
        return MosaedColors.brand;
    }
  }

  @override
  Widget build(BuildContext context) {
    final asset = notification.eventIcon;
    final isSvg = notification.eventIconIsSvg;
    final bg = _iconBackground;

    final message = notification.body.trim().isNotEmpty
        ? notification.body
        : notification.title;
    final time = homeRelativeTime(notification.createdAt);

    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36.w,
                  height: 36.w,
                  decoration: BoxDecoration(
                    color: bg,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: isSvg
                      ? SvgPicture.asset(
                          asset,
                          width: 18.w,
                          height: 18.w,
                          colorFilter: const ColorFilter.mode(
                            Colors.white,
                            BlendMode.srcIn,
                          ),
                        )
                      : Image.asset(
                          asset,
                          width: 18.w,
                          height: 18.w,
                          fit: BoxFit.contain,
                          color: Colors.white,
                          colorBlendMode: BlendMode.srcIn,
                        ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message,
                        textAlign: TextAlign.start,
                        style: getMediumStyle(
                          fontSize: 13.sp,
                          color: notification.isRead
                              ? MosaedColors.textSecondary
                              : MosaedColors.textPrimary,
                          height: 1.4,
                        ),
                      ),
                      if (time.isNotEmpty) ...[
                        SizedBox(height: 6.h),
                        Text(
                          time,
                          textAlign: TextAlign.start,
                          style: getRegularStyle(
                            fontSize: 11.sp,
                            color: MosaedColors.textHint,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (showDivider)
            Divider(
              height: 1,
              thickness: .5,
             
              color: MosaedColors.border,
            ),
        ],
      ),
    );
  }
}

class NotificationGroupCard extends StatelessWidget {
  const NotificationGroupCard({
    super.key,
    required this.title,
    required this.items,
    required this.onTapItem,
  });

  final String title;
  final List<AppNotification> items;
  final ValueChanged<AppNotification> onTapItem;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsetsDirectional.only(start: 4.w, bottom: 10.h),
          child: Text(
            title,
            style: getMediumStyle(
              fontSize: 13.sp,
              color: MosaedColors.textPrimary,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: MosaedColors.surfaceWhite,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: MosaedColors.fieldBorder),
          ),
          child: Column(
            children: [
              for (var i = 0; i < items.length; i++)
                NotificationListItem(
                  notification: items[i],
                  showDivider: i != items.length - 1,
                  onTap: () => onTapItem(items[i]),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
