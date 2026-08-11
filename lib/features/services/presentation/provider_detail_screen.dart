import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/constants/mosaed_colors.dart';
import '../../../core/constants/styles_manager.dart';
import '../data/models/existed_service.dart';

class ProviderDetailScreen extends StatelessWidget {
  const ProviderDetailScreen({super.key, required this.provider});

  final ServiceProvider provider;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MosaedColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'mosaedProviderDetails'.tr(),
          style: getBoldStyle(fontSize: 18.sp, color: MosaedColors.textPrimary),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24.w),
        child: Column(
          children: [
            CircleAvatar(
              radius: 52.r,
              backgroundColor: MosaedColors.primary.withValues(alpha: 0.12),
              backgroundImage: provider.imageUrl != null
                  ? NetworkImage(provider.imageUrl!)
                  : null,
              child: provider.imageUrl == null
                  ? Icon(Icons.person, size: 52.sp, color: MosaedColors.primary)
                  : null,
            ),
            SizedBox(height: 16.h),
            Text(
              provider.providerName,
              style: getBoldStyle(
                fontSize: 22.sp,
                color: MosaedColors.textPrimary,
              ),
            ),
            if (provider.specializationName != null) ...[
              SizedBox(height: 6.h),
              Text(
                provider.specializationName!,
                style: getRegularStyle(
                  fontSize: 14.sp,
                  color: MosaedColors.textSecondary,
                ),
              ),
            ],
            SizedBox(height: 24.h),
            _InfoCard(
              icon: Icons.star_rounded,
              title: 'mosaedProviderRating'.tr(),
              value: provider.averageRating,
              subtitle: '${provider.totalReviews} ${'mosaedReviews'.tr()}',
            ),
            SizedBox(height: 12.h),
            _InfoCard(
              icon: Icons.phone_rounded,
              title: 'phoneNumber'.tr(),
              value: provider.providerPhone,
            ),
            SizedBox(height: 12.h),
            _InfoCard(
              icon: Icons.verified_rounded,
              title: 'mosaedProviderStatus'.tr(),
              value: provider.isAvailable
                  ? 'mosaedProviderAvailable'.tr()
                  : 'mosaedProviderUnavailable'.tr(),
              valueColor: provider.isAvailable
                  ? MosaedColors.success
                  : MosaedColors.danger,
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.value,
    this.subtitle,
    this.valueColor,
  });

  final IconData icon;
  final String title;
  final String value;
  final String? subtitle;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: MosaedColors.surface,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: MosaedColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: MosaedColors.primary),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: getRegularStyle(
                    fontSize: 12.sp,
                    color: MosaedColors.textSecondary,
                  ),
                ),
                Text(
                  value,
                  style: getBoldStyle(
                    fontSize: 15.sp,
                    color: valueColor ?? MosaedColors.textPrimary,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: getRegularStyle(
                      fontSize: 12.sp,
                      color: MosaedColors.textHint,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
