import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../app/functions.dart';
import '../../../core/constants/assets_manager.dart';
import '../../../core/constants/mosaed_colors.dart';
import '../../../core/constants/styles_manager.dart';
import '../../../core/network/failure.dart';
import '../../auth/presentation/widgets/mosaed_buttons.dart';
import '../../orders/data/provider_custom_request_model.dart';
import '../../orders/data/provider_offer_model.dart';
import '../../orders/data/provider_orders_repository.dart';
import '../../payments/presentation/widgets/payment_amount_text.dart';
import 'widgets/request_summary_card.dart';

class SubmitOfferScreen extends StatefulWidget {
  const SubmitOfferScreen({super.key, required this.request});

  final ProviderCustomRequest request;

  static const double platformFeeRate = 0.15;

  @override
  State<SubmitOfferScreen> createState() => _SubmitOfferScreenState();
}

class _SubmitOfferScreenState extends State<SubmitOfferScreen> {
  final _priceController = TextEditingController();
  final _noteController = TextEditingController();
  final _noteFocus = FocusNode();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final offer = widget.request.myOffer;
    if (offer != null) {
      _priceController.text = offer.displayPrice.toStringAsFixed(0);
      _noteController.text = offer.note ?? '';
    }
    _priceController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _priceController.dispose();
    _noteController.dispose();
    _noteFocus.dispose();
    super.dispose();
  }

  double? get _offerPrice {
    final raw = _priceController.text.trim();
    if (raw.isEmpty) return null;
    final value = double.tryParse(raw);
    if (value == null || value <= 0) return null;
    return value;
  }

  bool get _canSubmit => _offerPrice != null && !_submitting;

  String _formatAmount(double value) {
    if (value % 1 == 0) return value.toStringAsFixed(0);
    return value.toStringAsFixed(2);
  }

  Future<void> _submit() async {
    final price = _offerPrice;
    if (price == null) return;

    setState(() => _submitting = true);
    try {
      await context.read<ProviderOrdersRepository>().submitOffer(
            requestId: widget.request.id,
            payload: SubmitOfferPayload(
              providerPrice: price,
              note: _noteController.text.trim(),
            ),
          );
      if (!mounted) return;
      AppFunctions.showsToast(
        'mosaedOfferSubmitted'.tr(),
        MosaedColors.success,
        context,
      );
      Navigator.pop(context, true);
    } on ServerFailure catch (e) {
      if (mounted) {
        AppFunctions.showsToast(e.errMessage, MosaedColors.danger, context);
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final offerPrice = _offerPrice;
    final platformFee =
        offerPrice == null ? 0.0 : offerPrice * SubmitOfferScreen.platformFeeRate;
    final total = offerPrice == null ? 0.0 : offerPrice + platformFee;
    final hasPrice = offerPrice != null;

    return Scaffold(
      backgroundColor: MosaedColors.surfaceWhite,
      appBar: AppBar(
        backgroundColor: MosaedColors.surfaceWhite,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.arrow_forward_ios_rounded,
            color: MosaedColors.textPrimary,
            size: 18.sp,
          ),
        ),
        title: Text(
          'mosaedSubmitOfferTitle'.tr(),
          style: getBoldStyle(fontSize: 16.sp, color: MosaedColors.textPrimary),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.h),
          child: const Divider(height: 1, color: MosaedColors.fieldBorder),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 20.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  RequestSummaryCard(request: widget.request),
                  SizedBox(height: 22.h),
                  Text(
                    'mosaedOfferPrice'.tr(),
                    style: getBoldStyle(
                      fontSize: 14.sp,
                      color: MosaedColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 10.h),
                  _PriceCard(
                    controller: _priceController,
                    enabled: !_submitting,
                    hasPrice: hasPrice,
                    offerAmount: hasPrice ? _formatAmount(offerPrice) : '0',
                    feeAmount: hasPrice ? _formatAmount(platformFee) : '0',
                    totalAmount: hasPrice ? _formatAmount(total) : '0',
                  ),
                  SizedBox(height: 22.h),
                  Text(
                    'mosaedNotesToClient'.tr(),
                    style: getBoldStyle(
                      fontSize: 14.sp,
                      color: MosaedColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 10.h),
                  _NotesField(
                    controller: _noteController,
                    focusNode: _noteFocus,
                    enabled: !_submitting,
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 12.h),
            color: MosaedColors.surfaceWhite,
            child: SafeArea(
              top: false,
              child: MosaedPrimaryButton(
                text: 'mosaedSendOffer'.tr(),
                isLoading: _submitting,
                enabled: _canSubmit,
                onPressed: _canSubmit ? _submit : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceCard extends StatelessWidget {
  const _PriceCard({
    required this.controller,
    required this.enabled,
    required this.hasPrice,
    required this.offerAmount,
    required this.feeAmount,
    required this.totalAmount,
  });

  final TextEditingController controller;
  final bool enabled;
  final bool hasPrice;
  final String offerAmount;
  final String feeAmount;
  final String totalAmount;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(14.w, 14.h, 14.w, 14.h),
      decoration: BoxDecoration(
        color: MosaedColors.surfaceWhite,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: MosaedColors.fieldBorder),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 2.h),
            decoration: BoxDecoration(
              color: MosaedColors.surfaceWhite,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Row(
              children: [
                SvgPicture.asset(
                  ImageAssets.riyalIcon,
                  width: 18.w,
                  height: 18.w,
                  colorFilter: const ColorFilter.mode(
                    MosaedColors.brand,
                    BlendMode.srcIn,
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: TextField(
                    controller: controller,
                    enabled: enabled,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    textAlign: TextAlign.start,
                    style: getBoldStyle(
                      fontSize: 16.sp,
                      color: MosaedColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: '0',
                      hintStyle: getRegularStyle(
                        fontSize: 16.sp,
                        color: MosaedColors.textHint,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 14.h),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 14.h),
          _BreakdownRow(
            label: 'mosaedYourOfferAmount'.tr(),
            amount: offerAmount,
            muted: !hasPrice,
          ),
          SizedBox(height: 10.h),
          _BreakdownRow(
            label: 'mosaedPlatformFeeLine'.tr(),
            amount: feeAmount,
            showInfo: true,
            muted: !hasPrice,
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 12.h),
            child: const Divider(height: 1, color: MosaedColors.fieldBorder),
          ),
          _BreakdownRow(
            label: 'mosaedTotalAmount'.tr(),
            amount: totalAmount,
            isTotal: true,
            muted: !hasPrice,
          ),
        ],
      ),
    );
  }
}

class _NotesField extends StatelessWidget {
  const _NotesField({
    required this.controller,
    required this.focusNode,
    required this.enabled,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: focusNode,
      builder: (context, _) {
        final isFocused = focusNode.hasFocus;
        return Container(
          constraints: BoxConstraints(minHeight: 140.h),
          decoration: BoxDecoration(
            color: MosaedColors.surfaceWhite,
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(
              color: isFocused ? MosaedColors.brand : MosaedColors.fieldBorder,
              width: isFocused ? 1.4 : 1,
            ),
          ),
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            enabled: enabled,
            maxLines: null,
            minLines: 6,
            textAlign: TextAlign.start,
            textAlignVertical: TextAlignVertical.top,
            style: getRegularStyle(
              fontSize: 14.sp,
              color: MosaedColors.textPrimary,
              height: 1.45,
            ),
            decoration: InputDecoration(
              hintText: 'mosaedWriteYourNotes'.tr(),
              hintStyle: getRegularStyle(
                fontSize: 14.sp,
                color: MosaedColors.textHint,
              ),
              filled: false,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              contentPadding: EdgeInsets.fromLTRB(14.w, 14.h, 14.w, 14.h),
            ),
          ),
        );
      },
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({
    required this.label,
    required this.amount,
    this.isTotal = false,
    this.showInfo = false,
    this.muted = false,
  });

  final String label;
  final String amount;
  final bool isTotal;
  final bool showInfo;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final labelColor = muted
        ? MosaedColors.textHint
        : (isTotal ? MosaedColors.textPrimary : MosaedColors.textSecondary);
    final amountColor = muted
        ? MosaedColors.textHint
        : (isTotal ? MosaedColors.brand : MosaedColors.textPrimary);

    final labelStyle = isTotal
        ? getBoldStyle(fontSize: 14.sp, color: labelColor)
        : getRegularStyle(fontSize: 13.sp, color: labelColor);

    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              Flexible(child: Text(label, style: labelStyle)),
              if (showInfo) ...[
                SizedBox(width: 4.w),
                Icon(
                  Icons.info_outline_rounded,
                  size: 14.sp,
                  color: MosaedColors.textHint,
                ),
              ],
            ],
          ),
        ),
        PaymentAmountText(
          amount: amount,
          color: amountColor,
          fontSize: isTotal ? 15 : 13,
          iconSize: isTotal ? 13 : 11,
        ),
      ],
    );
  }
}
