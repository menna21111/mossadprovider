import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';

import '../../../../core/constants/assets_manager.dart';
import '../../../../core/constants/mosaed_colors.dart';
import '../../../../core/constants/styles_manager.dart';
import '../../../notifications/presentation/cubit/notification_cubit.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    required this.name,
    required this.onNotificationsTap,
    this.avatarUrl,
  });

  final String name;
  final String? avatarUrl;
  final VoidCallback onNotificationsTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _HomeAvatar(avatarUrl: avatarUrl),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'mosaedHelloUser'.tr(args: [name]),
                style: getMediumStyle(
                  fontSize: 18.sp,
                  color: MosaedColors.textPrimary,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                'mosaedReadyToHelp'.tr(),
                style: getRegularStyle(
                  fontSize: 14.sp,
                  color: MosaedColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        BlocBuilder<NotificationCubit, NotificationState>(
          builder: (context, state) {
            return Stack(
              clipBehavior: Clip.none,
              children: [
                Material(

                  shape: const CircleBorder(),
                  child: InkWell(
                    
                 
                    onTap: onNotificationsTap,
                    child:Container(
                      padding: EdgeInsets.symmetric(horizontal: 5.w,vertical: 5.h),
                      height: 40.w,
                      width: 40.w,
                      decoration: BoxDecoration(
                        border: Border.all(color: MosaedColors.border),
                        shape: BoxShape.circle,
                      ),
                      child: SvgPicture.asset(
                        ImageAssets.notification,
                        height: 24.h,
                        width: 24.w,
                      ),
                    ),
                    
                   
                  
                ),),
                if (state.unreadCount > 0)
                  PositionedDirectional(
                    start: 2.w,
                    top: 2.h,
                    child: Container(
                      width: 10.w,
                      height: 10.w,
                      decoration: const BoxDecoration(
                        color: MosaedColors.danger,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _HomeAvatar extends StatelessWidget {
  const _HomeAvatar({this.avatarUrl});

  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    final url = avatarUrl?.trim();
    final hasPhoto = url != null && url.isNotEmpty;

    return Container(
      width: 48.w,
      height: 48.w,
      decoration: BoxDecoration(
        color: MosaedColors.surfaceContainerLow,
        shape: BoxShape.circle,
        border: Border.all(color: MosaedColors.fieldBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: hasPhoto
          ? Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _placeholder(),
            )
          : _placeholder(),
    );
  }

  Widget _placeholder() {
    return Icon(
      Icons.person_rounded,
      color: MosaedColors.textSecondary,
      size: 26.sp,
    );
  }
}
