import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/constants/assets_manager.dart';
import '../../../core/constants/mosaed_colors.dart';
import '../../../core/constants/styles_manager.dart';
import '../../notifications/presentation/cubit/notification_cubit.dart';
import '../../payments/presentation/provider_wallet_offers_drawer.dart';
import 'chats_tab.dart';
import 'home_tab.dart';
import 'my_works_tab.dart';
import 'orders_tab.dart';
import 'profile_tab.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int _index = widget.initialIndex;
  final _homeKey = GlobalKey<HomeTabState>();
  final _myWorksKey = GlobalKey<MyWorksTabState>();
  final _chatsKey = GlobalKey<ChatsTabState>();

  late final List<Widget> _pages = [
    HomeTab(
      key: _homeKey,
      onOpenRequests: () => _openMyWorks(MyWorksSection.nearby),
      onOpenTasks: () => _openMyWorks(MyWorksSection.assigned),
      onOpenOffers: () => _openMyWorks(MyWorksSection.offers),
    ),
    MyWorksTab(key: _myWorksKey),
    const OrdersTab(),
    ChatsTab(key: _chatsKey),
    const ProfileTab(),
  ];

  void _openMyWorks(MyWorksSection section) {
    setState(() => _index = 1);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _myWorksKey.currentState?.openSection(section);
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cubit = context.read<NotificationCubit>();
      cubit.onNewCustomRequest = () {
        _myWorksKey.currentState?.reload();
        _homeKey.currentState?.reload();
      };
      cubit.onOfferAccepted = () {
        _myWorksKey.currentState?.reload();
        _chatsKey.currentState?.reload();
        _homeKey.currentState?.reload();
      };
      cubit.onNewChatMessage = () {
        _chatsKey.currentState?.reload();
      };
      cubit.startRealtime();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MosaedColors.background,
      endDrawer: const ProviderWalletOffersDrawer(),
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: MosaedColors.surfaceWhite,
          border: Border(
            top: BorderSide(color: MosaedColors.fieldBorder, width: 0.5),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 2),
            child: Row(
              children: [
                _NavItem(
                  asset: ImageAssets.home,
                  fallbackIcon: Icons.home_rounded,
                  label: 'home'.tr(),
                  selected: _index == 0,
                  onTap: () => setState(() => _index = 0),
                ),
                _NavItem(
                  asset: ImageAssets.orders,
                  fallbackIcon: Icons.assignment_outlined,
                  label: 'mosaedNavRequests'.tr(),
                  selected: _index == 1,
                  onTap: () => setState(() => _index = 1),
                ),
                _NavItem(
                  asset: ImageAssets.taskIcon,
                  fallbackIcon: Icons.task_alt_rounded,
                  label: 'mosaedNavTasks'.tr(),
                  selected: _index == 2,
                  onTap: () => setState(() => _index = 2),
                ),
                _NavItem(
                  asset: ImageAssets.messages,
                  fallbackIcon: Icons.chat_bubble_outline_rounded,
                  label: 'mosaedMyChats'.tr(),
                  selected: _index == 3,
                  onTap: () => setState(() => _index = 3),
                ),
                _NavItem(
                  asset: ImageAssets.moreIcon,
                  fallbackIcon: Icons.more_horiz_rounded,
                  label: 'mosaedMore'.tr(),
                  selected: _index == 4,
                  onTap: () => setState(() => _index = 4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.asset,
    required this.fallbackIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String asset;
  final IconData fallbackIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? MosaedColors.brand : MosaedColors.textSecondary;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              asset,
              width: 20,
              height: 20,
              colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
              errorBuilder: (_, _, _) => Icon(
                fallbackIcon,
                size: 20,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: getMediumStyle(fontSize: 10.sp, color: color),
            ),
          ],
        ),
      ),
    );
  }
}
