import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:page_transition/page_transition.dart';

import '../../../app/functions.dart';
import '../../../core/constants/assets_manager.dart';
import '../../../core/constants/mosaed_colors.dart';
import '../../../core/constants/styles_manager.dart';
import '../../../core/network/failure.dart';
import '../../../core/widgets/mosaed_labeled_row.dart';
import '../../auth/presentation/widgets/mosaed_buttons.dart';
import '../../chat/presentation/chat_screen.dart';
import '../../orders/data/completion_form_model.dart';
import '../../orders/data/provider_custom_request_model.dart';
import '../../orders/data/provider_offer_model.dart';
import '../../orders/data/provider_orders_repository.dart';
import '../../orders/presentation/completion_form_upload_screen.dart';
import '../../payments/presentation/widgets/payment_amount_text.dart';
import 'widgets/request_details_card.dart';
import 'widgets/request_summary_card.dart';
import 'widgets/task_progress_stepper.dart';
import 'submit_offer_screen.dart';

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
  CompletionForm? _completion;
  bool _loading = true;
  String? _error;
  bool _readyToStart = false;

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
      final repo = context.read<ProviderOrdersRepository>();
      final request =
          await repo.getProviderCustomRequestDetail(widget.requestId);

      CompletionForm? completion;
      if (request.hasMyOffer &&
          (request.myOffer!.isAccepted ||
              request.status.toLowerCase().contains('accept'))) {
        try {
          completion = await repo.getCompletionFormDetail(
            widget.requestId,
            kind: CompletionFormKind.customRequest,
          );
        } catch (_) {
          completion = null;
        }
      }

      if (!mounted) return;
      setState(() {
        _request = request;
        _completion = completion;
        _loading = false;
        if (completion?.hasArrived == true) _readyToStart = true;
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

  Future<void> _openSubmitOfferScreen() async {
    final request = _request;
    if (request == null) return;
    final submitted = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => SubmitOfferScreen(request: request),
      ),
    );
    if (submitted == true && mounted) await _load();
  }

  void _openChat(ProviderCustomRequest request) {
    setState(() => _readyToStart = true);
    AppFunctions.navigateTo(
      context,
      ChatScreen(
        requestId: request.id,
        requestTitle: request.title,
        peerName: request.customerName,
      ),
      PageTransitionType.rightToLeft,
    );
  }

  Future<void> _openStartExecution(ProviderCustomRequest request) async {
    await AppFunctions.navigateTo(
      context,
      CompletionFormUploadScreen(
        bookingId: request.id,
        serviceTitle: request.title,
        kind: CompletionFormKind.customRequest,
        forcePhase: CompletionUploadPhase.before,
      ),
      PageTransitionType.rightToLeft,
    );
    if (mounted) await _load();
  }

  bool _isOfferAccepted(ProviderCustomRequest request) {
    final offer = request.myOffer;
    if (offer == null) return false;
    return offer.isAccepted ||
        request.status.toLowerCase().contains('accept');
  }

  @override
  Widget build(BuildContext context) {
    final request = _request;
    final accepted = request != null && _isOfferAccepted(request);
    final canSubmitOffer = request != null && !request.hasMyOffer;
    final progress = ProviderTaskProgress(completion: _completion);
    final workStarted = progress.workStarted;
    final hasBeforePhoto = progress.hasBeforePhoto;

    Widget? bottomBar;
    if (canSubmitOffer) {
      bottomBar = _SubmitOfferBar(onPressed: _openSubmitOfferScreen);
    } else if (accepted) {
      bottomBar = _AcceptedFooter(
        workStarted: workStarted,
        hasBeforePhoto: hasBeforePhoto,
        showStartMode: _readyToStart || workStarted,
        onChat: () => _openChat(request),
        onStart: () => _openStartExecution(request),
      );
    }

    return Scaffold(
      backgroundColor: MosaedColors.surfaceWhite,
      appBar: AppBar(
        backgroundColor: MosaedColors.surfaceWhite,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Transform.flip(
            flipX: context.locale.languageCode == 'ar',
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: MosaedColors.textPrimary,
              size: 18.sp,
            ),
          ),
        ),
        title: Text(
          accepted
              ? 'mosaedTaskDetails'.tr()
              : 'mosaedOrderDetailsTab'.tr(),
          style: getBoldStyle(fontSize: 16.sp, color: MosaedColors.textPrimary),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.h),
          child: const Divider(height: 1, color: MosaedColors.fieldBorder),
        ),
      ),
      body: _buildBody(accepted: accepted, progress: progress),
      bottomNavigationBar: bottomBar,
    );
  }

  Widget _buildBody({
    required bool accepted,
    required ProviderTaskProgress progress,
  }) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: MosaedColors.brand),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: getRegularStyle(
                  fontSize: 14.sp,
                  color: MosaedColors.textSecondary,
                ),
              ),
              SizedBox(height: 16.h),
              TextButton(onPressed: _load, child: Text('mosaedRetry'.tr())),
            ],
          ),
        ),
      );
    }

    final request = _request!;
    final hasOffer = request.hasMyOffer;
    final showAcceptedBanner =
        accepted && !progress.workStarted && !_readyToStart;

    return RefreshIndicator(
      onRefresh: _load,
      color: MosaedColors.brand,
      child: ListView(
        padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 24.h),
        children: [
          RequestSummaryCard(
            request: request,
            showOfferPrice: hasOffer,
          ),
          if (accepted) ...[
            SizedBox(height: 12.h),
            TaskProgressStepper(
              progress: progress,
              forceInactive: !(_readyToStart || progress.workStarted),
            ),
          ],
          if (hasOffer && !accepted) ...[
            SizedBox(height: 12.h),
            const _WaitingClientBanner(),
          ],
          if (showAcceptedBanner) ...[
            SizedBox(height: 12.h),
            const _YouAreAcceptedBanner(),
          ],
          SizedBox(height: 16.h),
          RequestDetailsCard(request: request),
          if (hasOffer) ...[
            SizedBox(height: 16.h),
            _YourOfferCard(offer: request.myOffer!),
          ],
        ],
      ),
    );
  }
}

class _WaitingClientBanner extends StatelessWidget {
  const _WaitingClientBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: MosaedColors.otpFill,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: MosaedColors.brand.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          SvgPicture.asset(
            ImageAssets.timeQuarterPass,
            width: 22.w,
            height: 22.w,
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              'mosaedWaitingClientApproval'.tr(),
              style: getMediumStyle(fontSize: 13.sp, color: MosaedColors.brand),
            ),
          ),
        ],
      ),
    );
  }
}

class _YouAreAcceptedBanner extends StatelessWidget {
  const _YouAreAcceptedBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF4FF),
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36.w,
            height: 36.w,
            decoration: const BoxDecoration(
              color: Color(0xFFDBEAFE),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: SvgPicture.asset(
              ImageAssets.checkmarkBadge01,
              width: 20.w,
              height: 20.w,
              colorFilter: const ColorFilter.mode(
                Color(0xFF2563EB),
                BlendMode.srcIn,
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'mosaedYouAreAccepted'.tr(),
                  style: getBoldStyle(
                    fontSize: 14.sp,
                    color: const Color(0xFF1D4ED8),
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'mosaedYouAreAcceptedHint'.tr(),
                  style: getRegularStyle(
                    fontSize: 12.sp,
                    color: const Color(0xFF3B82F6),
                    height: 1.4,
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

class _YourOfferCard extends StatelessWidget {
  const _YourOfferCard({required this.offer});

  final ProviderOffer offer;

  @override
  Widget build(BuildContext context) {
    final price = offer.displayPrice;
    final amount = price % 1 == 0
        ? price.toStringAsFixed(0)
        : price.toStringAsFixed(2);
    final note = (offer.note ?? '').trim();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(14.w, 16.h, 14.w, 10.h),
      decoration: BoxDecoration(
        color: MosaedColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: MosaedColors.fieldBorder),
        boxShadow: MosaedColors.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'mosaedYourOfferAmount'.tr(),
            style: getBoldStyle(fontSize: 15.sp, color: MosaedColors.brand),
          ),
          SizedBox(height: 16.h),
          MosaedLabeledRow(
            svgAsset: ImageAssets.moneyOrderDetails,
            label: 'mosaedCooperationValue'.tr(),
            circleSize: 40,
            verticalPadding: 0,
            child: PaymentAmountText(
              amount: amount,
              color: MosaedColors.textPrimary,
              fontSize: 13,
              iconSize: 12,
            ),
          ),
          if (note.isNotEmpty) ...[
            const MosaedFieldDivider(),
            MosaedLabeledRow(
              svgAsset: ImageAssets.message02,
              label: 'mosaedYourNotes'.tr(),
              circleSize: 40,
              verticalPadding: 0,
              child: Text(
                note,
                style: getRegularStyle(
                  fontSize: 13.sp,
                  color: MosaedColors.textPrimary,
                  height: 1.5,
                ),
              ),
            ),
          ],
          SizedBox(height: 6.h),
        ],
      ),
    );
  }
}

class _SubmitOfferBar extends StatelessWidget {
  const _SubmitOfferBar({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h),
      decoration: const BoxDecoration(
        color: MosaedColors.surfaceWhite,
        border: Border(top: BorderSide(color: MosaedColors.fieldBorder)),
      ),
      child: SafeArea(
        top: false,
        child: MosaedPrimaryButton(
          text: 'mosaedSubmitOfferAction'.tr(),
          onPressed: onPressed,
        ),
      ),
    );
  }
}

class _AcceptedFooter extends StatelessWidget {
  const _AcceptedFooter({
    required this.workStarted,
    required this.hasBeforePhoto,
    required this.showStartMode,
    required this.onChat,
    required this.onStart,
  });

  final bool workStarted;
  final bool hasBeforePhoto;
  final bool showStartMode;
  final VoidCallback onChat;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final Widget button;
    if (hasBeforePhoto) {
      button = MosaedPrimaryButton(
        text: 'mosaedDeliverWork'.tr(),
        onPressed: onStart,
      );
    } else if (workStarted) {
      button = MosaedPrimaryButton(
        text: 'mosaedUploadThePhoto'.tr(),
        onPressed: onStart,
      );
    } else if (showStartMode) {
      button = MosaedPrimaryButton(
        text: 'mosaedStartExecution'.tr(),
        onPressed: onStart,
      );
    } else {
      button = SizedBox(
        width: double.infinity,
        height: 52.h,
        child: OutlinedButton(
          onPressed: onChat,
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: MosaedColors.brand, width: 1.5),
            foregroundColor: MosaedColors.brand,
            backgroundColor: MosaedColors.surfaceWhite,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14.r),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                ImageAssets.message02,
                width: 20.w,
                height: 20.w,
                colorFilter: const ColorFilter.mode(
                  MosaedColors.brand,
                  BlendMode.srcIn,
                ),
              ),
              SizedBox(width: 8.w),
              Text(
                'mosaedChatNow'.tr(),
                style: getBoldStyle(
                  fontSize: 15.sp,
                  color: MosaedColors.brand,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h),
      decoration: const BoxDecoration(
        color: MosaedColors.surfaceWhite,
        border: Border(top: BorderSide(color: MosaedColors.fieldBorder)),
      ),
      child: SafeArea(top: false, child: button),
    );
  }
}
