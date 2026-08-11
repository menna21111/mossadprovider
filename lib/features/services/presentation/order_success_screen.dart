import 'package:audioplayers/audioplayers.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../app/functions.dart';
import '../../../core/constants/mosaed_colors.dart';
import '../../../core/constants/styles_manager.dart';
import '../../auth/presentation/widgets/mosaed_buttons.dart';
import '../../home/presentation/main_shell.dart';

class OrderSuccessScreen extends StatefulWidget {
  const OrderSuccessScreen({super.key, this.bookingId});

  final String? bookingId;

  @override
  State<OrderSuccessScreen> createState() => _OrderSuccessScreenState();
}

class _OrderSuccessScreenState extends State<OrderSuccessScreen> {
  final AudioPlayer _player = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _playSuccessSound();
  }

  Future<void> _playSuccessSound() async {
    try {
      await _player.play(AssetSource('sound/scuess_order.mp3'));
    } catch (_) {}
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  void _trackOrder() {
    AppFunctions.navigateToAndFinish(
      context,
      const MainShell(initialIndex: 1),
    );
  }

  void _goHome() {
    AppFunctions.navigateToAndFinish(context, const MainShell());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MosaedColors.background,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 96.w,
                height: 96.w,
                decoration: BoxDecoration(
                  color: MosaedColors.successBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle_rounded,
                  color: MosaedColors.success,
                  size: 56.sp,
                ),
              ),
              SizedBox(height: 24.h),
              Text(
                'mosaedOrderSuccessTitle'.tr(),
                textAlign: TextAlign.center,
                style: getBoldStyle(
                  fontSize: 24.sp,
                  color: MosaedColors.textPrimary,
                ),
              ),
              SizedBox(height: 10.h),
              Text(
                'mosaedOrderSuccessSubtitle'.tr(),
                textAlign: TextAlign.center,
                style: getRegularStyle(
                  fontSize: 14.sp,
                  color: MosaedColors.textSecondary,
                ),
              ),
              if (widget.bookingId != null && widget.bookingId!.isNotEmpty) ...[
                SizedBox(height: 16.h),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: MosaedColors.surface,
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(color: MosaedColors.border),
                  ),
                  child: Text(
                    '${'mosaedOrderNumber'.tr()}: ${widget.bookingId}',
                    style: getMediumStyle(
                      fontSize: 13.sp,
                      color: MosaedColors.textPrimary,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              MosaedPrimaryButton(
                text: 'mosaedTrackOrder'.tr(),
                icon: Icons.receipt_long_rounded,
                onPressed: _trackOrder,
              ),
              SizedBox(height: 12.h),
              MosaedOutlineButton(
                text: 'mosaedGoHome'.tr(),
                onPressed: _goHome,
              ),
              SizedBox(height: 16.h),
            ],
          ),
        ),
      ),
    );
  }
}
