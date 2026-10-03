import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/constants/mosaed_colors.dart';
import '../../../core/constants/styles_manager.dart';
import '../data/models/app_notification.dart';
import 'cubit/notification_cubit.dart';
import 'notification_navigation.dart';
import 'widgets/notification_empty_state.dart';
import 'widgets/notification_list_widgets.dart';

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

  bool _isToday(AppNotification n) {
    final raw = n.createdAt;
    if (raw == null) return true;
    final dt = DateTime.tryParse(raw)?.toLocal();
    if (dt == null) return true;
    final now = DateTime.now();
    return dt.year == now.year && dt.month == now.month && dt.day == now.day;
  }

  void _onTap(AppNotification notification) {
    if (!notification.isRead) {
      context.read<NotificationCubit>().markAsRead(notification.id);
    }
    NotificationNavigation.open(context, notification);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MosaedColors.surfaceWhite,
      appBar: AppBar(
        backgroundColor: MosaedColors.surfaceWhite,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: MosaedColors.textPrimary,
            size: 18.sp,
          ),
        ),
        title: Text(
          'mosaedNotifications'.tr(),
          style: getBoldStyle(
            fontSize: 16.sp,
            color: MosaedColors.textPrimary,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.h),
          child: Divider(height: 1, color: MosaedColors.fieldBorder),
        ),
      ),
      body: BlocBuilder<NotificationCubit, NotificationState>(
        builder: (context, state) {
          if (state.loading && state.notifications.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: MosaedColors.brand),
            );
          }

          if (state.notifications.isEmpty) {
            if (state.error != null) {
              return Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32.w),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        state.error!,
                        textAlign: TextAlign.center,
                        style: getRegularStyle(
                          fontSize: 14.sp,
                          color: MosaedColors.textSecondary,
                        ),
                      ),
                      SizedBox(height: 12.h),
                      TextButton.icon(
                        onPressed: () => context
                            .read<NotificationCubit>()
                            .loadNotifications(refresh: true),
                        icon: const Icon(Icons.refresh_rounded),
                        label: Text('mosaedRetry'.tr()),
                      ),
                    ],
                  ),
                ),
              );
            }
            return const NotificationEmptyState();
          }

          final today = state.notifications.where(_isToday).toList();
          final earlier =
              state.notifications.where((n) => !_isToday(n)).toList();

          return RefreshIndicator(
            color: MosaedColors.brand,
            onRefresh: () => context
                .read<NotificationCubit>()
                .loadNotifications(refresh: true),
            child: ListView(
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
              children: [
                if (today.isNotEmpty)
                  NotificationGroupCard(
                    title: 'mosaedToday'.tr(),
                    items: today,
                    onTapItem: _onTap,
                  ),
                if (today.isNotEmpty && earlier.isNotEmpty)
                  SizedBox(height: 20.h),
                if (earlier.isNotEmpty)
                  NotificationGroupCard(
                    title: 'mosaedEarlier'.tr(),
                    items: earlier,
                    onTapItem: _onTap,
                  ),
                if (state.hasMore) ...[
                  SizedBox(height: 16.h),
                  if (state.loadingMore)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(
                          color: MosaedColors.brand,
                        ),
                      ),
                    )
                  else
                    Builder(
                      builder: (context) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (context.mounted) {
                            context
                                .read<NotificationCubit>()
                                .loadNotifications();
                          }
                        });
                        return const SizedBox.shrink();
                      },
                    ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
