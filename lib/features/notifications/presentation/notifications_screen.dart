import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/constants/mosaed_colors.dart';
import '../../../core/constants/styles_manager.dart';
import '../data/models/app_notification.dart';
import 'cubit/notification_cubit.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<NotificationCubit>().loadNotifications(refresh: true);
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
          'mosaedNotifications'.tr(),
          style: getBoldStyle(fontSize: 18.sp, color: MosaedColors.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => context.read<NotificationCubit>().markAllAsRead(),
            child: Text(
              'mosaedMarkAllRead'.tr(),
              style: getMediumStyle(fontSize: 13.sp, color: MosaedColors.primary),
            ),
          ),
        ],
      ),
      body: BlocBuilder<NotificationCubit, NotificationState>(
        builder: (context, state) {
          if (state.loading && state.notifications.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: MosaedColors.primaryContainer),
            );
          }

          if (state.notifications.isEmpty) {
            return Center(
              child: Text(
                'mosaedNoNotificationsYet'.tr(),
                style: getRegularStyle(
                  fontSize: 14.sp,
                  color: MosaedColors.textSecondary,
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () =>
                context.read<NotificationCubit>().loadNotifications(refresh: true),
            color: MosaedColors.primary,
            child: ListView.separated(
              padding: EdgeInsets.all(16.w),
              itemCount: state.notifications.length + (state.hasMore ? 1 : 0),
              separatorBuilder: (_, __) => SizedBox(height: 10.h),
              itemBuilder: (context, index) {
                if (index >= state.notifications.length) {
                  if (state.loadingMore) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  context.read<NotificationCubit>().loadNotifications();
                  return const SizedBox.shrink();
                }

                final item = state.notifications[index];
                return _NotificationTile(notification: item);
              },
            ),
          );
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification});

  final AppNotification notification;

  @override
  Widget build(BuildContext context) {
    final isRead = notification.isRead;
    return InkWell(
      onTap: () {
        if (!isRead) {
          context.read<NotificationCubit>().markAsRead(notification.id);
        }
      },
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: isRead ? MosaedColors.surface : MosaedColors.primaryFixed,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: MosaedColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notification.title,
              style: getBoldStyle(
                fontSize: 14.sp,
                color: MosaedColors.textPrimary,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              notification.body,
              style: getRegularStyle(
                fontSize: 13.sp,
                color: MosaedColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
