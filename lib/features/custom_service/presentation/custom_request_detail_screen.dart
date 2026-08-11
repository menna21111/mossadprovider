import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:page_transition/page_transition.dart';

import '../../../app/functions.dart';
import '../../chat/presentation/chat_screen.dart';
import '../../../core/constants/mosaed_colors.dart';
import '../../../core/constants/styles_manager.dart';
import '../../../core/network/failure.dart';
import '../../auth/presentation/widgets/mosaed_buttons.dart';
import '../../orders/data/order_model.dart';
import '../../orders/data/provider_custom_request_model.dart';
import '../../orders/data/provider_offer_model.dart';
import '../../orders/data/provider_orders_repository.dart';

class CustomRequestDetailScreen extends StatefulWidget {
  const CustomRequestDetailScreen({
    super.key,
    required this.requestId,
  });

  final String requestId;

  @override
  State<CustomRequestDetailScreen> createState() =>
      _CustomRequestDetailScreenState();
}

class _CustomRequestDetailScreenState extends State<CustomRequestDetailScreen> {
  ProviderCustomRequest? _request;
  bool _loading = true;
  bool _submitting = false;
  String? _error;

  final _priceController = TextEditingController();
  final _noteController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _priceController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final request = await context
          .read<ProviderOrdersRepository>()
          .getProviderCustomRequestDetail(widget.requestId);
      if (!mounted) return;
      setState(() {
        _request = request;
        _loading = false;
        if (request.myOffer != null) {
          _priceController.text =
              request.myOffer!.displayPrice.toStringAsFixed(0);
          _noteController.text = request.myOffer!.note ?? '';
        }
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
        _error = 'mosaedCustomRequestLoadError'.tr();
        _loading = false;
      });
    }
  }

  Future<void> _submitOffer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    try {
      await context.read<ProviderOrdersRepository>().submitOffer(
            requestId: widget.requestId,
            payload: SubmitOfferPayload(
              providerPrice: double.parse(_priceController.text.trim()),
              note: _noteController.text.trim(),
            ),
          );
      if (!mounted) return;
      AppFunctions.showsToast(
        'mosaedOfferSubmitted'.tr(),
        MosaedColors.success,
        context,
      );
      await _load();
    } on ServerFailure catch (e) {
      if (mounted) {
        AppFunctions.showsToast(e.errMessage, MosaedColors.danger, context);
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _openChat(ProviderCustomRequest request) {
    AppFunctions.navigateTo(
      context,
      ChatScreen(
        requestId: request.id,
        requestTitle: request.title,
      ),
      PageTransitionType.rightToLeft,
    );
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
          'mosaedCustomRequestDetails'.tr(),
          style: getBoldStyle(fontSize: 18.sp, color: MosaedColors.textPrimary),
        ),
      ),
      body: _buildBody(),
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
        child: Padding(
          padding: EdgeInsets.all(24.w),
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
        ),
      );
    }

    final request = _request!;
    final statusColor = request.orderStatus.statusColor;

    return RefreshIndicator(
      onRefresh: _load,
      color: MosaedColors.primary,
      child: ListView(
        padding: EdgeInsets.all(20.w),
        children: [
          if (request.image != null && request.image!.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(18.r),
              child: Image.network(
                request.image!,
                height: 180.h,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _imagePlaceholder(),
              ),
            )
          else
            _imagePlaceholder(),
          SizedBox(height: 16.h),
          _headerCard(request, statusColor),
          SizedBox(height: 12.h),
          _infoCard(
            title: 'mosaedSpecialization'.tr(),
            value: request.specializationName ?? 'mosaedNotAvailableYet'.tr(),
            icon: Icons.handyman_outlined,
          ),
          SizedBox(height: 12.h),
          _infoCard(
            title: 'mosaedPreferredDay'.tr(),
            value: request.scheduledDate ?? 'mosaedNotAvailableYet'.tr(),
            icon: Icons.calendar_today_outlined,
          ),
          if (request.expiresAt != null) ...[
            SizedBox(height: 12.h),
            _infoCard(
              title: 'mosaedExpiresAt'.tr(),
              value: request.expiresAt!,
              icon: Icons.timer_outlined,
            ),
          ],
          SizedBox(height: 12.h),
          _infoCard(
            title: 'mosaedServiceLocation'.tr(),
            value: request.locationText.isNotEmpty
                ? request.locationText
                : 'mosaedNotAvailableYet'.tr(),
            icon: Icons.location_on_outlined,
          ),
          SizedBox(height: 12.h),
          _infoCard(
            title: 'mosaedProblemDescription'.tr(),
            value: request.description,
            icon: Icons.description_outlined,
          ),
          SizedBox(height: 20.h),
          if (request.hasMyOffer) ...[
            _myOfferCard(request.myOffer!),
            if (request.myOffer!.isAccepted ||
                request.status.toLowerCase().contains('accept')) ...[
              SizedBox(height: 12.h),
              MosaedPrimaryButton(
                text: 'mosaedChatWithClient'.tr(),
                icon: Icons.chat_bubble_outline_rounded,
                onPressed: () => _openChat(request),
              ),
            ],
          ] else
            _offerForm(),
        ],
      ),
    );
  }

  Widget _headerCard(ProviderCustomRequest request, Color statusColor) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: MosaedColors.surfaceWhite,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: MosaedColors.border),
        boxShadow: MosaedColors.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: MosaedColors.primaryFixed,
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  'mosaedCustomRequestBadge'.tr(),
                  style: getMediumStyle(
                    fontSize: 11.sp,
                    color: MosaedColors.primary,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  request.status,
                  style: getMediumStyle(
                    fontSize: 11.sp,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            request.title,
            style: getBoldStyle(
              fontSize: 20.sp,
              color: MosaedColors.textPrimary,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            '#${request.id.length > 8 ? request.id.substring(0, 8) : request.id}',
            style: getRegularStyle(
              fontSize: 12.sp,
              color: MosaedColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _myOfferCard(ProviderOffer offer) {
    final currency = 'mosaedCurrency'.tr();
    final accepted = offer.isAccepted;
    final accent = accepted ? MosaedColors.success : MosaedColors.primary;
    final bg = accepted ? MosaedColors.successBg : MosaedColors.primaryFixed;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                accepted
                    ? Icons.check_circle_rounded
                    : Icons.local_offer_rounded,
                color: accent,
                size: 22.sp,
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  accepted
                      ? 'mosaedOfferAcceptedBadge'.tr()
                      : 'mosaedMyOfferSubmitted'.tr(),
                  style: getBoldStyle(fontSize: 16.sp, color: accent),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            '${offer.displayPrice.toStringAsFixed(0)} $currency',
            style: getBoldStyle(fontSize: 22.sp, color: MosaedColors.textPrimary),
          ),
          if (offer.note != null && offer.note!.trim().isNotEmpty) ...[
            SizedBox(height: 8.h),
            Text(
              offer.note!,
              style: getRegularStyle(
                fontSize: 14.sp,
                color: MosaedColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _offerForm() {
    return Form(
      key: _formKey,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: MosaedColors.surfaceWhite,
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(color: MosaedColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'mosaedSubmitOffer'.tr(),
              style: getBoldStyle(fontSize: 16.sp, color: MosaedColors.textPrimary),
            ),
            SizedBox(height: 6.h),
            Text(
              'mosaedSubmitOfferHint'.tr(),
              style: getRegularStyle(
                fontSize: 13.sp,
                color: MosaedColors.textSecondary,
              ),
            ),
            SizedBox(height: 16.h),
            TextFormField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'mosaedOfferPrice'.tr(),
                suffixText: 'mosaedCurrency'.tr(),
                filled: true,
                fillColor: MosaedColors.inputFill,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14.r),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'fieldRequired'.tr();
                }
                final price = double.tryParse(value.trim());
                if (price == null || price <= 0) {
                  return 'mosaedInvalidPrice'.tr();
                }
                return null;
              },
            ),
            SizedBox(height: 12.h),
            TextFormField(
              controller: _noteController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'mosaedOfferNote'.tr(),
                hintText: 'mosaedOfferNoteHint'.tr(),
                filled: true,
                fillColor: MosaedColors.inputFill,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14.r),
                ),
              ),
              validator: (value) =>
                  value == null || value.trim().isEmpty ? 'fieldRequired'.tr() : null,
            ),
            SizedBox(height: 16.h),
            MosaedPrimaryButton(
              text: 'mosaedSubmitOffer'.tr(),
              icon: Icons.send_rounded,
              isLoading: _submitting,
              onPressed: _submitOffer,
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      height: 140.h,
      width: double.infinity,
      decoration: BoxDecoration(
        color: MosaedColors.primaryFixed,
        borderRadius: BorderRadius.circular(18.r),
      ),
      child: Icon(
        Icons.home_repair_service_rounded,
        size: 48.sp,
        color: MosaedColors.primary,
      ),
    );
  }

  Widget _infoCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: MosaedColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: MosaedColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              color: MosaedColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(icon, color: MosaedColors.primary, size: 20.sp),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: getMediumStyle(
                    fontSize: 12.sp,
                    color: MosaedColors.textSecondary,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  value,
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
      ),
    );
  }
}
