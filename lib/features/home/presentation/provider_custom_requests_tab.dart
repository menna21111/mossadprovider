import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:page_transition/page_transition.dart';

import '../../../app/functions.dart';
import '../../../core/constants/mosaed_colors.dart';
import '../../../core/constants/styles_manager.dart';
import '../../../core/network/failure.dart';
import '../../orders/data/provider_custom_request_model.dart';
import '../../orders/data/provider_orders_repository.dart';
import '../../custom_service/presentation/custom_request_detail_screen.dart';

class ProviderCustomRequestsTab extends StatefulWidget {
  const ProviderCustomRequestsTab({super.key});

  @override
  ProviderCustomRequestsTabState createState() =>
      ProviderCustomRequestsTabState();
}

class ProviderCustomRequestsTabState extends State<ProviderCustomRequestsTab> {
  List<ProviderCustomRequest> _requests = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> reload() => _load();

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final requests = await context
          .read<ProviderOrdersRepository>()
          .getProviderCustomRequests();
      if (!mounted) return;
      setState(() {
        _requests = requests;
        _loading = false;
      });
    } on ServerFailure catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.errMessage;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'mosaedCustomRequestsLoadError'.tr();
        _loading = false;
      });
    }
  }

  void _openRequest(ProviderCustomRequest request) {
    AppFunctions.navigateTo(
      context,
      CustomRequestDetailScreen(requestId: request.id),
      PageTransitionType.rightToLeft,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'mosaedCustomRequest'.tr(),
                        style: getBoldStyle(
                          fontSize: 22.sp,
                          color: MosaedColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        'mosaedProviderCustomRequestsSubtitle'.tr(),
                        style: getRegularStyle(
                          fontSize: 13.sp,
                          color: MosaedColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!_loading)
                  IconButton(
                    onPressed: _load,
                    icon: Icon(
                      Icons.refresh_rounded,
                      color: MosaedColors.primary,
                    ),
                  ),
              ],
            ),
            SizedBox(height: 20.h),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: MosaedColors.primaryContainer),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_rounded, size: 48.sp, color: MosaedColors.textHint),
            SizedBox(height: 12.h),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: getRegularStyle(
                fontSize: 14.sp,
                color: MosaedColors.textSecondary,
              ),
            ),
            SizedBox(height: 16.h),
            TextButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded),
              label: Text('mosaedRetry'.tr()),
            ),
          ],
        ),
      );
    }

    if (_requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80.w,
              height: 80.w,
              decoration: BoxDecoration(
                color: MosaedColors.shieldBg,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.handyman_outlined,
                size: 40.sp,
                color: MosaedColors.primary,
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              'mosaedNoCustomRequestsYet'.tr(),
              style: getBoldStyle(
                fontSize: 16.sp,
                color: MosaedColors.textPrimary,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              'mosaedNoCustomRequestsHint'.tr(),
              textAlign: TextAlign.center,
              style: getRegularStyle(
                fontSize: 13.sp,
                color: MosaedColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: MosaedColors.primary,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _requests.length,
        separatorBuilder: (_, __) => SizedBox(height: 12.h),
        itemBuilder: (context, index) {
          final request = _requests[index];
          return _RequestCard(
            request: request,
            onTap: () => _openRequest(request),
          );
        },
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.request, required this.onTap});

  final ProviderCustomRequest request;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18.r),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: MosaedColors.surface,
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(color: MosaedColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    request.title,
                    style: getBoldStyle(
                      fontSize: 15.sp,
                      color: MosaedColors.textPrimary,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_left_rounded,
                  color: MosaedColors.textHint,
                  size: 20.sp,
                ),
              ],
            ),
            if (request.specializationName != null) ...[
              SizedBox(height: 6.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: MosaedColors.primaryFixed,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  request.specializationName!,
                  style: getMediumStyle(
                    fontSize: 10.sp,
                    color: MosaedColors.primary,
                  ),
                ),
              ),
            ],
            if (request.description.trim().isNotEmpty) ...[
              SizedBox(height: 8.h),
              Text(
                request.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: getRegularStyle(
                  fontSize: 13.sp,
                  color: MosaedColors.textSecondary,
                ),
              ),
            ],
            if (request.scheduledDate != null) ...[
              SizedBox(height: 10.h),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 14.sp,
                    color: MosaedColors.textHint,
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    request.scheduledDate!,
                    style: getRegularStyle(
                      fontSize: 12.sp,
                      color: MosaedColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
            if (request.hasMyOffer) ...[
              SizedBox(height: 8.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: (request.myOffer!.isAccepted
                          ? MosaedColors.successBg
                          : MosaedColors.primaryFixed),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  request.myOffer!.isAccepted
                      ? 'mosaedOfferAcceptedBadge'.tr()
                      : 'mosaedMyOfferSubmitted'.tr(),
                  style: getMediumStyle(
                    fontSize: 10.sp,
                    color: request.myOffer!.isAccepted
                        ? MosaedColors.success
                        : MosaedColors.primary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
