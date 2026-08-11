import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:page_transition/page_transition.dart';

import '../../../app/functions.dart';
import '../../../core/constants/mosaed_colors.dart';
import '../../../core/constants/styles_manager.dart';
import '../../../core/network/failure.dart';
import '../../orders/data/provider_offer_model.dart';
import '../../orders/data/provider_orders_repository.dart';
import 'offer_detail_screen.dart';

enum _OffersStatusFilter {
  all,
  accepted,
  pending,
}

class OffersTab extends StatefulWidget {
  const OffersTab({super.key});

  @override
  OffersTabState createState() => OffersTabState();
}

class OffersTabState extends State<OffersTab> {
  List<ProviderOffer> _offers = [];
  bool _loading = true;
  String? _error;
  _OffersStatusFilter _statusFilter = _OffersStatusFilter.all;

  String? get _statusQuery {
    switch (_statusFilter) {
      case _OffersStatusFilter.all:
        return null;
      case _OffersStatusFilter.accepted:
        return 'accepted';
      case _OffersStatusFilter.pending:
        return 'pending';
    }
  }

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
      final offers = await context
          .read<ProviderOrdersRepository>()
          .getProviderOffers(status: _statusQuery);
      if (!mounted) return;
      setState(() {
        _offers = offers;
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

  Future<void> _applyStatus(_OffersStatusFilter filter) async {
    if (_statusFilter == filter) return;
    setState(() => _statusFilter = filter);
    await _load();
  }

  void _openOffer(ProviderOffer offer) {
    AppFunctions.navigateTo(
      context,
      OfferDetailScreen(offerId: offer.id, initialOffer: offer),
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
                        'mosaedMyOffers'.tr(),
                        style: getBoldStyle(
                          fontSize: 22.sp,
                          color: MosaedColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        'mosaedMyOffersSubtitle'.tr(),
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
            SizedBox(height: 16.h),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _OfferFilterChip(
                    label: 'mosaedFilterAll'.tr(),
                    selected: _statusFilter == _OffersStatusFilter.all,
                    onTap: () => _applyStatus(_OffersStatusFilter.all),
                  ),
                  SizedBox(width: 8.w),
                  _OfferFilterChip(
                    label: 'mosaedOfferStatusAccepted'.tr(),
                    selected: _statusFilter == _OffersStatusFilter.accepted,
                    onTap: () => _applyStatus(_OffersStatusFilter.accepted),
                  ),
                  SizedBox(width: 8.w),
                  _OfferFilterChip(
                    label: 'mosaedFilterNotAcceptedYet'.tr(),
                    selected: _statusFilter == _OffersStatusFilter.pending,
                    onTap: () => _applyStatus(_OffersStatusFilter.pending),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),
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

    if (_offers.isEmpty) {
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
                Icons.local_offer_outlined,
                size: 40.sp,
                color: MosaedColors.primary,
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              'mosaedNoOffersYet'.tr(),
              style: getBoldStyle(
                fontSize: 16.sp,
                color: MosaedColors.textPrimary,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              _statusFilter == _OffersStatusFilter.all
                  ? 'mosaedNoOffersHint'.tr()
                  : 'mosaedFilterEmptyHint'.tr(),
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
        itemCount: _offers.length,
        separatorBuilder: (_, __) => SizedBox(height: 12.h),
        itemBuilder: (context, index) {
          final offer = _offers[index];
          return _OfferCard(offer: offer, onTap: () => _openOffer(offer));
        },
      ),
    );
  }
}

class _OfferFilterChip extends StatelessWidget {
  const _OfferFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? MosaedColors.primary.withValues(alpha: 0.12)
          : MosaedColors.surface,
      borderRadius: BorderRadius.circular(20.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: selected ? MosaedColors.primary : MosaedColors.border,
            ),
          ),
          child: Text(
            label,
            style: getMediumStyle(
              fontSize: 12.sp,
              color:
                  selected ? MosaedColors.primary : MosaedColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _OfferCard extends StatelessWidget {
  const _OfferCard({required this.offer, required this.onTap});

  final ProviderOffer offer;
  final VoidCallback onTap;

  String get _statusLabel {
    if (offer.isAccepted) return 'mosaedOfferStatusAccepted'.tr();
    final s = offer.status?.toLowerCase() ?? '';
    if (s.contains('reject') || s.contains('decline')) {
      return 'mosaedOfferStatusRejected'.tr();
    }
    if ((offer.requestStatus?.toLowerCase().contains('expir') ?? false) ||
        s.contains('expir')) {
      return 'mosaedOfferStatusExpired'.tr();
    }
    if (s.isEmpty || s == 'pending') return 'mosaedOfferStatusPending'.tr();
    return offer.status!;
  }

  Color get _statusColor {
    if (offer.isAccepted) return MosaedColors.success;
    final s = offer.status?.toLowerCase() ?? '';
    if (s.contains('reject') ||
        s.contains('decline') ||
        s.contains('expir') ||
        (offer.requestStatus?.toLowerCase().contains('expir') ?? false)) {
      return MosaedColors.danger;
    }
    return MosaedColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    final currency = 'mosaedCurrency'.tr();
    final statusColor = _statusColor;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18.r),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: MosaedColors.surface,
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(
            color: offer.isAccepted
                ? MosaedColors.success.withValues(alpha: 0.35)
                : MosaedColors.border,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48.w,
              height: 48.w,
              decoration: BoxDecoration(
                color: offer.isAccepted
                    ? MosaedColors.successBg
                    : MosaedColors.primaryFixed,
                borderRadius: BorderRadius.circular(14.r),
              ),
              child: Icon(
                offer.isAccepted
                    ? Icons.check_circle_rounded
                    : Icons.local_offer_rounded,
                color: offer.isAccepted
                    ? MosaedColors.success
                    : MosaedColors.primary,
                size: 24.sp,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    offer.customRequestTitle ?? 'mosaedCustomRequest'.tr(),
                    style: getBoldStyle(
                      fontSize: 15.sp,
                      color: MosaedColors.textPrimary,
                    ),
                  ),
                  if (offer.specializationName != null &&
                      offer.specializationName!.isNotEmpty) ...[
                    SizedBox(height: 4.h),
                    Text(
                      offer.specializationName!,
                      style: getRegularStyle(
                        fontSize: 12.sp,
                        color: MosaedColors.textSecondary,
                      ),
                    ),
                  ],
                  if (offer.locationText.isNotEmpty) ...[
                    SizedBox(height: 2.h),
                    Text(
                      offer.locationText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: getRegularStyle(
                        fontSize: 11.sp,
                        color: MosaedColors.textHint,
                      ),
                    ),
                  ],
                  SizedBox(height: 6.h),
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 2.h,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: Text(
                          _statusLabel,
                          style: getMediumStyle(
                            fontSize: 11.sp,
                            color: statusColor,
                          ),
                        ),
                      ),
                      if (offer.canChat) ...[
                        SizedBox(width: 8.w),
                        Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 14.sp,
                          color: MosaedColors.primary,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${offer.displayPrice.toStringAsFixed(0)} $currency',
                  style: getBoldStyle(
                    fontSize: 16.sp,
                    color: MosaedColors.primary,
                  ),
                ),
                Icon(
                  Icons.chevron_left_rounded,
                  color: MosaedColors.textHint,
                  size: 20.sp,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
