import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:page_transition/page_transition.dart';

import '../../../app/functions.dart';
import '../../../core/constants/mosaed_colors.dart';
import '../../../core/constants/styles_manager.dart';
import '../../notifications/presentation/cubit/notification_cubit.dart';
import '../../notifications/presentation/notifications_screen.dart';
import 'offers_tab.dart';
import 'orders_tab.dart';
import 'profile_tab.dart';
import 'provider_custom_requests_tab.dart';
import '../../payments/presentation/provider_wallet_offers_drawer.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int _index = widget.initialIndex;
  final _customRequestsKey = GlobalKey<ProviderCustomRequestsTabState>();
  final _offersKey = GlobalKey<OffersTabState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cubit = context.read<NotificationCubit>();
      cubit.onNewCustomRequest = () => _customRequestsKey.currentState?.reload();
      cubit.onOfferAccepted = () => _offersKey.currentState?.reload();
      cubit.startRealtime();
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      const OrdersTab(),
      OffersTab(key: _offersKey),
      ProviderCustomRequestsTab(key: _customRequestsKey),
      const ProfileTab(),
    ];

    return Scaffold(
      backgroundColor: MosaedColors.background,
      endDrawer: const ProviderWalletOffersDrawer(),
      body: Column(
        children: [
          Builder(
            builder: (context) => _TopBar(
              onNotificationsTap: _openNotifications,
              onMenuTap: () => Scaffold.of(context).openEndDrawer(),
            ),
          ),
          Expanded(
            child: IndexedStack(index: _index, children: pages),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: MosaedColors.surfaceWhite,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
          border: Border(
            top: BorderSide(color: MosaedColors.surfaceContainerLow),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 8.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.assignment_outlined,
                  label: 'mosaedCompletionForms'.tr(),
                  selected: _index == 0,
                  onTap: () => setState(() => _index = 0),
                ),
                _NavItem(
                  icon: Icons.local_offer_outlined,
                  label: 'mosaedMyOffers'.tr(),
                  selected: _index == 1,
                  onTap: () => setState(() => _index = 1),
                ),
                _NavItem(
                  icon: Icons.handyman_outlined,
                  label: 'mosaedCustomRequest'.tr(),
                  selected: _index == 2,
                  onTap: () => setState(() => _index = 2),
                ),
                _NavItem(
                  icon: Icons.person_rounded,
                  label: 'profile'.tr(),
                  selected: _index == 3,
                  onTap: () => setState(() => _index = 3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openNotifications() {
    AppFunctions.navigateTo(
      context,
      const NotificationsScreen(),
      PageTransitionType.rightToLeft,
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.onNotificationsTap,
    required this.onMenuTap,
  });

  final VoidCallback onNotificationsTap;
  final VoidCallback onMenuTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(20.w, 8.h, 12.w, 8.h),
        child: Row(
          children: [
            IconButton(
              onPressed: onMenuTap,
              icon: Icon(
                Icons.menu_rounded,
                color: MosaedColors.primary,
                size: 26.sp,
              ),
            ),
            Expanded(
              child: Text(
                'mosaedProviderApp'.tr(),
                style: getBoldStyle(
                  fontSize: 18.sp,
                  color: MosaedColors.textPrimary,
                ),
              ),
            ),
            BlocBuilder<NotificationCubit, NotificationState>(
              builder: (context, state) {
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      onPressed: onNotificationsTap,
                      icon: Icon(
                        Icons.notifications_outlined,
                        color: MosaedColors.primary,
                        size: 26.sp,
                      ),
                    ),
                    if (state.unreadCount > 0)
                      Positioned(
                        right: 6.w,
                        top: 6.h,
                        child: Container(
                          padding: EdgeInsets.all(4.w),
                          decoration: const BoxDecoration(
                            color: MosaedColors.danger,
                            shape: BoxShape.circle,
                          ),
                          constraints: BoxConstraints(minWidth: 18.w, minHeight: 18.w),
                          child: Text(
                            state.unreadCount > 99 ? '99+' : '${state.unreadCount}',
                            textAlign: TextAlign.center,
                            style: getBoldStyle(fontSize: 9.sp, color: Colors.white),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14.r),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: selected ? MosaedColors.primaryContainer : Colors.transparent,
            borderRadius: BorderRadius.circular(14.r),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20.sp,
                color: selected
                    ? MosaedColors.onPrimaryContainer
                    : MosaedColors.textSecondary,
              ),
              SizedBox(height: 2.h),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: getMediumStyle(
                  fontSize: 9.sp,
                  color: selected
                      ? MosaedColors.onPrimaryContainer
                      : MosaedColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
