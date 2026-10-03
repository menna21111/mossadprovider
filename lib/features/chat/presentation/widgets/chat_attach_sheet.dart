import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/mosaed_colors.dart';
import '../../../../core/constants/styles_manager.dart';

Future<void> showChatAttachSheet({
  required BuildContext context,
  required VoidCallback onCamera,
  required VoidCallback onGallery,
  required VoidCallback onFile,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: MosaedColors.surfaceWhite,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
    ),
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 20.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: MosaedColors.fieldBorder,
                  borderRadius: BorderRadius.circular(4.r),
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                'mosaedChatAttach'.tr(),
                style: getBoldStyle(
                  fontSize: 16.sp,
                  color: MosaedColors.textPrimary,
                ),
              ),
              SizedBox(height: 12.h),
              _AttachOption(
                icon: Icons.photo_camera_outlined,
                label: 'mosaedChatCamera'.tr(),
                onTap: () {
                  Navigator.pop(context);
                  onCamera();
                },
              ),
              _AttachOption(
                icon: Icons.photo_outlined,
                label: 'mosaedChatGallery'.tr(),
                onTap: () {
                  Navigator.pop(context);
                  onGallery();
                },
              ),
              _AttachOption(
                icon: Icons.insert_drive_file_outlined,
                label: 'mosaedChatDocument'.tr(),
                onTap: () {
                  Navigator.pop(context);
                  onFile();
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _AttachOption extends StatelessWidget {
  const _AttachOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: MosaedColors.otpFill,
        child: Icon(icon, color: MosaedColors.brand, size: 20.sp),
      ),
      title: Text(
        label,
        style: getMediumStyle(fontSize: 14.sp, color: MosaedColors.textPrimary),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 4.w),
    );
  }
}
