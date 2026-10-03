import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:page_transition/page_transition.dart';

import '../../../app/functions.dart';
import '../../../core/constants/mosaed_colors.dart';
import '../../../core/constants/styles_manager.dart';
import '../../../core/network/failure.dart';
import '../../auth/presentation/widgets/mosaed_buttons.dart';
import '../../chat/presentation/chat_screen.dart';
import '../../orders/data/provider_offer_model.dart';
import '../../orders/data/provider_orders_repository.dart';

class OfferDetailScreen extends StatefulWidget {
  const OfferDetailScreen({
    super.key,
    required this.offerId,
    this.initialOffer,
  });

  final String offerId;
  final ProviderOffer? initialOffer;

  @override
  State<OfferDetailScreen> createState() => _OfferDetailScreenState();
}

class _OfferDetailScreenState extends State<OfferDetailScreen> {
  ProviderOfferDetail? _offer;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final offer = await context
          .read<ProviderOrdersRepository>()
          .getProviderOfferDetail(widget.offerId);
      if (!mounted) return;
      setState(() {
        _offer = offer;
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
        _error = 'mosaedOffersLoadError'.tr();
        _loading = false;
      });
    }
  }

  bool get _canChat {
    if (_offer?.canChat == true) return true;
    final initial = widget.initialOffer;
    return initial?.canChat == true;
  }

  String? get _chatRequestId =>
      _offer?.customRequestId ?? widget.initialOffer?.customRequestId;

  String? get _chatTitle =>
      _offer?.customRequestTitle ?? widget.initialOffer?.customRequestTitle;

  void _openChat() {
    final requestId = _chatRequestId;
    if (requestId == null || requestId.isEmpty) return;
    final initial = widget.initialOffer;
    final price = _offer?.displayPrice ?? initial?.displayPrice;
    final peer = initial?.customerName;

    AppFunctions.navigateTo(
      context,
      ChatScreen(
        requestId: requestId,
        requestTitle: _chatTitle,
        peerName: peer,
        price: (price != null && price > 0) ? price : null,
      ),
      PageTransitionType.rightToLeft,
    );
  }

  String _statusLabel(String? status, {bool isAccepted = false}) {
    if (isAccepted || (status?.toLowerCase().contains('accept') ?? false)) {
      return 'mosaedOfferStatusAccepted'.tr();
    }
    final s = status?.toLowerCase() ?? '';
    if (s.contains('reject') || s.contains('decline')) {
      return 'mosaedOfferStatusRejected'.tr();
    }
    if (s.contains('expir')) {
      return 'mosaedOfferStatusExpired'.tr();
    }
    if (s.isEmpty || s == 'pending') {
      return 'mosaedOfferStatusPending'.tr();
    }
    return status!;
  }

  Color _statusColor(String? status, {bool isAccepted = false}) {
    if (isAccepted || (status?.toLowerCase().contains('accept') ?? false)) {
      return MosaedColors.success;
    }
    final s = status?.toLowerCase() ?? '';
    if (s.contains('reject') || s.contains('decline') || s.contains('expir')) {
      return MosaedColors.danger;
    }
    return MosaedColors.primary;
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
          icon: Icon(
            Icons.arrow_forward_rounded,
            color: MosaedColors.primary,
            size: 22.sp,
          ),
        ),
        title: Text(
          'mosaedOfferDetails'.tr(),
          style: getBoldStyle(fontSize: 18.sp, color: MosaedColors.textPrimary),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading && _offer == null && widget.initialOffer == null) {
      return const Center(
        child: CircularProgressIndicator(color: MosaedColors.primaryContainer),
      );
    }

    if (_error != null && _offer == null && widget.initialOffer == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _error!,
              style: getRegularStyle(
                fontSize: 14.sp,
                color: MosaedColors.textSecondary,
              ),
            ),
            TextButton(onPressed: _load, child: Text('mosaedRetry'.tr())),
          ],
        ),
      );
    }

    final offer = _offer;
    final initial = widget.initialOffer;
    final currency = 'mosaedCurrency'.tr();
    final title = offer?.customRequestTitle ??
        initial?.customRequestTitle ??
        'mosaedCustomRequest'.tr();
    final providerPrice = offer?.providerPrice ?? initial?.providerPrice ?? 0;
    final finalPrice = offer?.finalPrice ?? initial?.finalPrice;
    final displayPrice = offer?.displayPrice ?? initial?.displayPrice ?? 0;
    final note = offer?.note ?? initial?.note;
    final status = offer?.status ?? initial?.status;
    final isAccepted = offer?.isAccepted ?? initial?.isAccepted ?? false;
    final specialization =
        offer?.specializationName ?? initial?.specializationName;
    final location = (offer?.locationText.isNotEmpty == true)
        ? offer!.locationText
        : (initial?.locationText ?? '');
    final statusColor = _statusColor(status, isAccepted: isAccepted);

    return RefreshIndicator(
      onRefresh: _load,
      color: MosaedColors.primary,
      child: ListView(
        padding: EdgeInsets.all(20.w),
        children: [
          if (isAccepted) ...[
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(14.w),
              decoration: BoxDecoration(
                color: MosaedColors.successBg,
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(
                  color: MosaedColors.success.withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    color: MosaedColors.success,
                    size: 22.sp,
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      'mosaedOfferAcceptedBadge'.tr(),
                      style: getMediumStyle(
                        fontSize: 13.sp,
                        color: MosaedColors.success,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12.h),
          ],
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: MosaedColors.surfaceWhite,
              borderRadius: BorderRadius.circular(18.r),
              border: Border.all(color: MosaedColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: getBoldStyle(
                          fontSize: 18.sp,
                          color: MosaedColors.textPrimary,
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Text(
                        _statusLabel(status, isAccepted: isAccepted),
                        style: getMediumStyle(
                          fontSize: 11.sp,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                if (specialization != null && specialization.isNotEmpty) ...[
                  SizedBox(height: 8.h),
                  Text(
                    specialization,
                    style: getRegularStyle(
                      fontSize: 13.sp,
                      color: MosaedColors.textSecondary,
                    ),
                  ),
                ],
                if (location.isNotEmpty) ...[
                  SizedBox(height: 6.h),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 16.sp,
                        color: MosaedColors.textHint,
                      ),
                      SizedBox(width: 4.w),
                      Expanded(
                        child: Text(
                          location,
                          style: getRegularStyle(
                            fontSize: 12.sp,
                            color: MosaedColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                SizedBox(height: 12.h),
                Text(
                  '${displayPrice.toStringAsFixed(0)} $currency',
                  style: getBoldStyle(
                    fontSize: 28.sp,
                    color: MosaedColors.primary,
                  ),
                ),
                if (finalPrice != null &&
                    providerPrice > 0 &&
                    finalPrice != providerPrice) ...[
                  SizedBox(height: 4.h),
                  Text(
                    '${'mosaedFinalPrice'.tr()}: ${finalPrice.toStringAsFixed(0)} $currency',
                    style: getMediumStyle(
                      fontSize: 13.sp,
                      color: MosaedColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (note != null && note.trim().isNotEmpty) ...[
            SizedBox(height: 12.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: MosaedColors.surfaceWhite,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: MosaedColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'mosaedOfferNote'.tr(),
                    style: getMediumStyle(
                      fontSize: 12.sp,
                      color: MosaedColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    note,
                    style: getRegularStyle(
                      fontSize: 14.sp,
                      color: MosaedColors.textPrimary,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (_canChat) ...[
            SizedBox(height: 20.h),
            MosaedPrimaryButton(
              text: 'mosaedChatWithClient'.tr(),
              icon: Icons.chat_bubble_outline_rounded,
              onPressed: _openChat,
            ),
          ],
        ],
      ),
    );
  }
}
