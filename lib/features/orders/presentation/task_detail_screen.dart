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
import '../../../core/widgets/mosaed_horizontal_photos.dart';
import '../../../core/widgets/mosaed_labeled_row.dart';
import '../../../core/widgets/mosaed_ribbon_card.dart';
import '../../auth/presentation/widgets/mosaed_buttons.dart';
import '../../chat/presentation/chat_screen.dart';
import '../../custom_service/presentation/widgets/request_format_helpers.dart';
import '../../custom_service/presentation/widgets/task_progress_stepper.dart';
import '../../payments/presentation/widgets/payment_amount_text.dart';
import '../data/booking_model.dart';
import '../data/completion_form_model.dart';
import '../data/provider_custom_request_model.dart';
import '../data/provider_orders_repository.dart';
import 'completion_form_upload_screen.dart';

/// Task overview after assignment / offer accept (completion-form entry).
/// Matches Figma «تفاصيل المهمة» — then opens upload/work screen on start.
class TaskDetailScreen extends StatefulWidget {
  const TaskDetailScreen({
    super.key,
    required this.workId,
    required this.kind,
    this.initialTitle,
  });

  final String workId;
  final CompletionFormKind kind;
  final String? initialTitle;

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  CompletionForm? _completion;
  ProviderCustomRequest? _request;
  Booking? _booking;
  bool _loading = true;
  String? _error;
  bool _readyToStart = false;
  bool _detailsExpanded = false;
  bool _confirmingCash = false;

  bool get _isCustom => widget.kind == CompletionFormKind.customRequest;

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
      final completion = await repo.getCompletionFormDetail(
        widget.workId,
        kind: widget.kind,
      );

      ProviderCustomRequest? request;
      Booking? booking;
      if (_isCustom) {
        try {
          request = await repo.getProviderCustomRequestDetail(widget.workId);
        } catch (_) {}
      } else {
        try {
          booking = await repo.getProviderBookingDetail(widget.workId);
        } catch (_) {}
      }

      if (!mounted) return;
      setState(() {
        _completion = completion;
        _request = request;
        _booking = booking;
        _loading = false;
        if (completion.hasArrived) _readyToStart = true;
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
        _error = 'mosaedCompletionFormLoadError'.tr();
        _loading = false;
      });
    }
  }

  void _openChat() {
    final request = _request;
    if (request == null) return;
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

  String? get _displayTitle =>
      widget.initialTitle ??
      _request?.title ??
      _booking?.serviceTitle ??
      _completion?.serviceTitle;

  Future<void> _openUpload({required CompletionUploadPhase phase}) async {
    await AppFunctions.navigateTo(
      context,
      CompletionFormUploadScreen(
        bookingId: widget.workId,
        serviceTitle: _displayTitle,
        kind: widget.kind,
        forcePhase: phase,
        startOnFinishStep: phase == CompletionUploadPhase.finish,
      ),
      PageTransitionType.rightToLeft,
    );
    if (mounted) await _load();
  }

  Future<void> _openStart() =>
      _openUpload(phase: CompletionUploadPhase.before);

  Future<void> _openDeliver() {
    final form = _completion;
    if (form?.readyToFinish == true) {
      return _openUpload(phase: CompletionUploadPhase.finish);
    }
    if (form?.hasBeforeImage == true) {
      return _openUpload(phase: CompletionUploadPhase.after);
    }
    return _openUpload(phase: CompletionUploadPhase.before);
  }

  Future<void> _confirmCash() async {
    final paymentRequestId = _completion?.paymentRequestId?.trim();
    if (paymentRequestId == null || paymentRequestId.isEmpty) {
      AppFunctions.showsToast(
        'mosaedPaymentRequestMissing'.tr(),
        MosaedColors.danger,
        context,
      );
      return;
    }

    setState(() => _confirmingCash = true);
    try {
      await context
          .read<ProviderOrdersRepository>()
          .confirmCashPayment(paymentRequestId);
      if (!mounted) return;
      AppFunctions.showsToast(
        'mosaedCashConfirmed'.tr(),
        MosaedColors.success,
        context,
      );
      await _load();
    } on ServerFailure catch (e) {
      if (!mounted) return;
      AppFunctions.showsToast(e.errMessage, MosaedColors.danger, context);
    } catch (_) {
      if (!mounted) return;
      AppFunctions.showsToast(
        'mosaedCashConfirmError'.tr(),
        MosaedColors.danger,
        context,
      );
    } finally {
      if (mounted) setState(() => _confirmingCash = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = ProviderTaskProgress(completion: _completion);
    final workStarted = progress.workStarted;
    final hasBeforePhoto = progress.hasBeforePhoto;
    final workFinished = progress.workFinished;
    final showStartMode = _readyToStart || workStarted;
    final canChat = _isCustom && _request != null;
    final awaitingCash = _completion?.awaitingCashConfirmation == true;
    final showPaymentFooter = workFinished && awaitingCash;

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
          'mosaedTaskDetails'.tr(),
          style: getBoldStyle(fontSize: 16.sp, color: MosaedColors.textPrimary),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.h),
          child: const Divider(height: 1, color: MosaedColors.fieldBorder),
        ),
      ),
      body: _buildBody(progress: progress, showStartMode: showStartMode),
      bottomNavigationBar: _loading || _error != null
          ? null
          : showPaymentFooter
              ? _CashConfirmFooter(
                  confirming: _confirmingCash,
                  onConfirm: _confirmCash,
                )
              : workFinished
                  ? null
                  : _TaskFooter(
                      workStarted: workStarted,
                      hasBeforePhoto: hasBeforePhoto,
                      showStartMode: showStartMode,
                      canChat: canChat && !showStartMode,
                      onChat: _openChat,
                      onStart: _openStart,
                      onUploadBefore: _openStart,
                      onDeliver: _openDeliver,
                    ),
    );
  }

  Widget _buildBody({
    required ProviderTaskProgress progress,
    required bool showStartMode,
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

    final showAcceptedBanner = !progress.workStarted && !showStartMode;
    final workStarted = progress.workStarted;
    final problemPreview = () {
      final fromCompletion = (_completion?.serviceTitle ?? '').trim();
      if (fromCompletion.isNotEmpty) return fromCompletion;
      final fromRequest = (_request?.title ?? '').trim();
      if (fromRequest.isNotEmpty) return fromRequest;
      final fromBooking = (_booking?.serviceTitle ?? '').trim();
      if (fromBooking.isNotEmpty) return fromBooking;
      return 'mosaedActiveJob'.tr();
    }();

    // Prefer completion-form payload (custom_request_images, customer, price).
    final detailsCard = _BookingDetailsCard(
      booking: _booking,
      completion: _completion,
      request: _request,
    );
    final summaryCard = _BookingSummaryCard(
      booking: _booking,
      completion: _completion,
      request: _request,
      fallbackTitle: widget.initialTitle,
    );

    return RefreshIndicator(
      onRefresh: _load,
      color: MosaedColors.brand,
      child: ListView(
        padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 24.h),
        children: [
          summaryCard,
          SizedBox(height: 12.h),
          TaskProgressStepper(
            progress: progress,
            forceInactive: !showStartMode,
          ),
          if (showAcceptedBanner) ...[
            SizedBox(height: 12.h),
            const _YouAreAcceptedBanner(),
          ],
          if (_completion != null &&
              (_completion!.isFinished ||
                  _completion!.isPaymentPending ||
                  _completion!.paymentConfirmed)) ...[
            SizedBox(height: 12.h),
            _PaymentStatusCard(form: _completion!),
          ],
          if (workStarted && _completion?.hasBeforeImage == true) ...[
            SizedBox(height: 16.h),
            _WorkPhotosSection(
              beforeUrl: _completion!.beforeImage,
              afterUrl: _completion!.hasRealAfterImage
                  ? _completion!.afterImage
                  : null,
            ),
          ],
          SizedBox(height: 16.h),
          if (workStarted && _completion?.hasBeforeImage == true)
            _CollapsibleDetails(
              expanded: _detailsExpanded,
              onToggle: () =>
                  setState(() => _detailsExpanded = !_detailsExpanded),
              problemTitle: problemPreview,
              child: detailsCard,
            )
          else
            detailsCard,
          if (_request?.myOffer != null) ...[
            SizedBox(height: 16.h),
            _YourOfferCard(
              amount: _request!.myOffer!.displayPrice,
              note: _request!.myOffer!.note,
            ),
          ] else if ((_completion?.finalPrice ?? 0) > 0) ...[
            SizedBox(height: 16.h),
            _YourOfferCard(
              amount: _completion!.finalPrice!,
              note: null,
            ),
          ] else if (_booking != null && _booking!.totalCost > 0) ...[
            SizedBox(height: 16.h),
            _YourOfferCard(amount: _booking!.totalCost, note: _booking!.notes),
          ],
        ],
      ),
    );
  }
}

class _BookingSummaryCard extends StatelessWidget {
  const _BookingSummaryCard({
    required this.booking,
    required this.completion,
    this.request,
    this.fallbackTitle,
  });

  final Booking? booking;
  final CompletionForm? completion;
  final ProviderCustomRequest? request;
  final String? fallbackTitle;

  @override
  Widget build(BuildContext context) {
    final title = (completion?.serviceTitle ??
            request?.title ??
            booking?.serviceTitle ??
            fallbackTitle ??
            '')
        .trim();
    final schedule = requestScheduleLabel(
      context,
      booking?.scheduledDate ??
          completion?.scheduledDate ??
          request?.scheduledDate,
    );
    final dayLabel = requestRelativeDayLabel(
      context,
      completion?.createdAt ?? request?.createdAt,
    );
    final price = (completion?.finalPrice ?? 0) > 0
        ? completion!.finalPrice
        : (request?.myOffer?.displayPrice != null &&
                request!.myOffer!.displayPrice > 0)
            ? request!.myOffer!.displayPrice
            : ((booking?.totalCost ?? 0) > 0 ? booking!.totalCost : null);
    final isCustom =
        completion?.isCustomRequest == true || request != null;
    final specialization = (completion?.specializationName ??
            request?.specializationName ??
            '')
        .trim();
    final customerName = (completion?.customerName ??
            request?.customerName ??
            '')
        .trim();
    final customerAvatar = (completion?.customerAvatar ??
            request?.customerAvatar ??
            '')
        .trim();

    return MosaedRibbonCard(
      statusLabel: isCustom
          ? 'mosaedCustomRequestBadge'.tr()
          : 'mosaedBookingTaskBadge'.tr(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.isNotEmpty ? title : 'mosaedActiveJob'.tr(),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: getBoldStyle(
              fontSize: 14.sp,
              color: MosaedColors.textPrimary,
            ),
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              CircleAvatar(
                radius: 12.r,
                backgroundColor: MosaedColors.surfaceContainerLow,
                backgroundImage: customerAvatar.isNotEmpty
                    ? NetworkImage(customerAvatar)
                    : null,
                child: customerAvatar.isEmpty
                    ? Icon(
                        Icons.person,
                        size: 14.sp,
                        color: MosaedColors.textSecondary,
                      )
                    : null,
              ),
              SizedBox(width: 6.w),
              Flexible(
                child: Text(
                  customerName.isNotEmpty
                      ? customerName
                      : 'mosaedClient'.tr(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: getBoldStyle(
                    fontSize: 12.sp,
                    color: MosaedColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                ImageAssets.time04,
                width: 14.w,
                height: 14.w,
                colorFilter: const ColorFilter.mode(
                  MosaedColors.textHint,
                  BlendMode.srcIn,
                ),
              ),
              SizedBox(width: 4.w),
              Text(
                dayLabel,
                style: getRegularStyle(
                  fontSize: 12.sp,
                  color: MosaedColors.textSecondary,
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: [
              if (specialization.isNotEmpty)
                _Chip(label: specialization),
              _Chip(
                svgAsset: ImageAssets.time04,
                label: schedule,
              ),
            ],
          ),
          if (price != null && price > 0) ...[
            SizedBox(height: 12.h),
            Row(
              children: [
                Text(
                  '${'mosaedYourOfferAmount'.tr()} ',
                  style: getBoldStyle(
                    fontSize: 13.sp,
                    color: MosaedColors.brand,
                  ),
                ),
                PaymentAmountText(
                  amount: price % 1 == 0
                      ? price.toStringAsFixed(0)
                      : price.toStringAsFixed(2),
                  color: MosaedColors.brand,
                  fontSize: 13,
                  iconSize: 12,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, this.svgAsset});

  final String label;
  final String? svgAsset;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (svgAsset != null)
            SvgPicture.asset(
              svgAsset!,
              width: 13.w,
              height: 13.w,
              colorFilter: const ColorFilter.mode(
                MosaedColors.textSecondary,
                BlendMode.srcIn,
              ),
            ),
          SizedBox(width: 5.w),
          Text(
            label,
            style: getMediumStyle(
              fontSize: 11.sp,
              color: MosaedColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _BookingDetailsCard extends StatelessWidget {
  const _BookingDetailsCard({
    required this.booking,
    required this.completion,
    this.request,
  });

  final Booking? booking;
  final CompletionForm? completion;
  final ProviderCustomRequest? request;

  @override
  Widget build(BuildContext context) {
    final title = (completion?.serviceTitle ??
            request?.title ??
            booking?.serviceTitle ??
            '')
        .trim();
    final notes = (completion?.description ??
            request?.description ??
            booking?.notes ??
            '')
        .trim();
    final location = (completion?.locationText ??
            request?.locationText ??
            booking?.addressText ??
            '')
        .trim();
    final schedule = requestScheduleLabel(
      context,
      booking?.scheduledDate ??
          completion?.scheduledDate ??
          request?.scheduledDate,
    );
    final orderNo = requestOrderNumber(
      request?.id ??
          booking?.id ??
          completion?.workId ??
          completion?.id ??
          '',
    );
    final specialization = (completion?.specializationName ??
            request?.specializationName ??
            '')
        .trim();
    final customerName = (completion?.customerName ??
            request?.customerName ??
            '')
        .trim();
    final customerPhone = (completion?.customerPhone ?? '').trim();
    final customerAvatar = (completion?.customerAvatar ??
            request?.customerAvatar ??
            '')
        .trim();
    final photos = (completion?.requestImages.isNotEmpty == true)
        ? completion!.requestImages
        : (request?.images ?? const <String>[]);

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
            'mosaedDetailsSection'.tr(),
            style: getBoldStyle(fontSize: 15.sp, color: MosaedColors.brand),
          ),
          SizedBox(height: 16.h),
          MosaedLabeledRow(
            svgAsset: ImageAssets.note01,
            label: 'mosaedProblemLabel'.tr(),
            circleSize: 40,
            verticalPadding: 0,
            child: Text(
              title.isNotEmpty ? title : '—',
              style: getMediumStyle(
                fontSize: 13.sp,
                color: MosaedColors.textPrimary,
              ),
            ),
          ),
          if (notes.isNotEmpty) ...[
            const MosaedFieldDivider(),
            MosaedLabeledRow(
              svgAsset: ImageAssets.message02,
              label: 'mosaedProblemDescription'.tr(),
              circleSize: 40,
              verticalPadding: 0,
              child: Text(
                notes,
                style: getRegularStyle(
                  fontSize: 13.sp,
                  color: MosaedColors.textPrimary,
                  height: 1.5,
                ),
              ),
            ),
          ],
          if (specialization.isNotEmpty) ...[
            const MosaedFieldDivider(),
            MosaedLabeledRow(
              svgAsset: ImageAssets.orders,
              label: 'mosaedServiceType'.tr(),
              circleSize: 40,
              verticalPadding: 0,
              child: Text(
                specialization,
                style: getMediumStyle(
                  fontSize: 13.sp,
                  color: MosaedColors.textPrimary,
                ),
              ),
            ),
          ],
          const MosaedFieldDivider(),
          MosaedLabeledRow(
            svgAsset: ImageAssets.image02,
            label: 'mosaedProblemPhotos'.tr(),
            circleSize: 40,
            verticalPadding: 0,
            child: photos.isEmpty
                ? Text(
                    '—',
                    style: getRegularStyle(
                      fontSize: 13.sp,
                      color: MosaedColors.textSecondary,
                    ),
                  )
                : MosaedHorizontalPhotos(urls: photos),
          ),
          const MosaedFieldDivider(),
          MosaedLabeledRow(
            icon: Icons.person_outline_rounded,
            label: 'mosaedClient'.tr(),
            circleSize: 40,
            verticalPadding: 0,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14.r,
                  backgroundColor: MosaedColors.surfaceContainerLow,
                  backgroundImage: customerAvatar.isNotEmpty
                      ? NetworkImage(customerAvatar)
                      : null,
                  child: customerAvatar.isEmpty
                      ? Icon(
                          Icons.person,
                          size: 16.sp,
                          color: MosaedColors.textSecondary,
                        )
                      : null,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customerName.isNotEmpty
                            ? customerName
                            : 'mosaedClient'.tr(),
                        style: getMediumStyle(
                          fontSize: 13.sp,
                          color: MosaedColors.textPrimary,
                        ),
                      ),
                      if (customerPhone.isNotEmpty) ...[
                        SizedBox(height: 2.h),
                        Text(
                          customerPhone,
                          style: getRegularStyle(
                            fontSize: 12.sp,
                            color: MosaedColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const MosaedFieldDivider(),
          MosaedLabeledRow(
            svgAsset: ImageAssets.chooseCity,
            label: 'mosaedServiceLocationShort'.tr(),
            circleSize: 40,
            verticalPadding: 0,
            child: Text(
              location.isNotEmpty ? location : '—',
              style: getMediumStyle(
                fontSize: 13.sp,
                color: MosaedColors.textPrimary,
              ),
            ),
          ),
          const MosaedFieldDivider(),
          MosaedLabeledRow(
            svgAsset: ImageAssets.time04,
            label: 'mosaedAppointment'.tr(),
            circleSize: 40,
            verticalPadding: 0,
            child: Text(
              schedule,
              style: getMediumStyle(
                fontSize: 13.sp,
                color: MosaedColors.textPrimary,
              ),
            ),
          ),
          const MosaedFieldDivider(),
          MosaedLabeledRow(
            svgAsset: ImageAssets.orderHash,
            label: 'mosaedOrderNumber'.tr(),
            circleSize: 40,
            verticalPadding: 0,
            child: Text(
              orderNo,
              style: getBoldStyle(
                fontSize: 13.sp,
                color: MosaedColors.textPrimary,
              ),
            ),
          ),
          SizedBox(height: 6.h),
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
  const _YourOfferCard({required this.amount, this.note});

  final double amount;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final display = amount % 1 == 0
        ? amount.toStringAsFixed(0)
        : amount.toStringAsFixed(2);
    final noteText = (note ?? '').trim();

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
              amount: display,
              color: MosaedColors.textPrimary,
              fontSize: 13,
              iconSize: 12,
            ),
          ),
          if (noteText.isNotEmpty) ...[
            const MosaedFieldDivider(),
            MosaedLabeledRow(
              svgAsset: ImageAssets.message02,
              label: 'mosaedYourNotes'.tr(),
              circleSize: 40,
              verticalPadding: 0,
              child: Text(
                noteText,
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

class _WorkPhotosSection extends StatelessWidget {
  const _WorkPhotosSection({
    required this.beforeUrl,
    this.afterUrl,
  });

  final String? beforeUrl;
  final String? afterUrl;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'mosaedWorkImages'.tr(),
          style: getBoldStyle(fontSize: 15.sp, color: MosaedColors.textPrimary),
        ),
        SizedBox(height: 10.h),
        SizedBox(
          height: 96.h,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              if (beforeUrl != null && beforeUrl!.trim().isNotEmpty)
                _WorkPhotoThumb(url: beforeUrl!, label: 'mosaedBefore'.tr()),
              if (afterUrl != null && afterUrl!.trim().isNotEmpty) ...[
                SizedBox(width: 10.w),
                _WorkPhotoThumb(url: afterUrl!, label: 'mosaedAfter'.tr()),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _WorkPhotoThumb extends StatelessWidget {
  const _WorkPhotoThumb({required this.url, required this.label});

  final String url;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96.w,
      height: 96.w,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: MosaedColors.fieldBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            url,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => ColoredBox(
              color: MosaedColors.primaryFixed,
              child: Center(
                child: SvgPicture.asset(
                  ImageAssets.image02,
                  width: 28.w,
                  height: 28.w,
                  colorFilter: const ColorFilter.mode(
                    MosaedColors.textHint,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 6.h,
            right: 6.w,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                label,
                style: getMediumStyle(fontSize: 10.sp, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CollapsibleDetails extends StatelessWidget {
  const _CollapsibleDetails({
    required this.expanded,
    required this.onToggle,
    required this.problemTitle,
    required this.child,
  });

  final bool expanded;
  final VoidCallback onToggle;
  final String problemTitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (expanded) {
      return Column(
        children: [
          child,
          SizedBox(height: 8.h),
          TextButton(
            onPressed: onToggle,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'mosaedShowLess'.tr(),
                  style: getMediumStyle(
                    fontSize: 13.sp,
                    color: MosaedColors.brand,
                  ),
                ),
                SizedBox(width: 4.w),
                Icon(
                  Icons.keyboard_arrow_up_rounded,
                  color: MosaedColors.brand,
                  size: 18.sp,
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(14.w, 16.h, 14.w, 8.h),
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
            'mosaedDetailsSection'.tr(),
            style: getBoldStyle(fontSize: 15.sp, color: MosaedColors.brand),
          ),
          SizedBox(height: 16.h),
          MosaedLabeledRow(
            svgAsset: ImageAssets.note01,
            label: 'mosaedProblemLabel'.tr(),
            circleSize: 40,
            verticalPadding: 0,
            child: Text(
              problemTitle,
              style: getMediumStyle(
                fontSize: 13.sp,
                color: MosaedColors.textPrimary,
              ),
            ),
          ),
          TextButton(
            onPressed: onToggle,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'mosaedShowMore'.tr(),
                  style: getMediumStyle(
                    fontSize: 13.sp,
                    color: MosaedColors.brand,
                  ),
                ),
                SizedBox(width: 4.w),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: MosaedColors.brand,
                  size: 18.sp,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentStatusCard extends StatelessWidget {
  const _PaymentStatusCard({required this.form});

  final CompletionForm form;

  @override
  Widget build(BuildContext context) {
    final confirmed = form.paymentConfirmed;
    final awaitingCash = form.awaitingCashConfirmation;
    final Color accent = confirmed
        ? MosaedColors.success
        : awaitingCash
            ? MosaedColors.brand
            : const Color(0xFFF59E0B);

    final String hint;
    if (confirmed) {
      hint = 'mosaedPaymentConfirmed'.tr();
    } else if (awaitingCash) {
      hint = 'mosaedAwaitingCashConfirmationHint'.tr();
    } else if (form.awaitingGatewayPayment) {
      hint = 'mosaedAwaitingGatewayPaymentHint'.tr();
    } else if (form.awaitingPaymentMethod) {
      hint = 'mosaedAwaitingPaymentMethodHint'.tr();
    } else {
      hint = 'mosaedPaymentPendingHint'.tr();
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SvgPicture.asset(
                confirmed
                    ? ImageAssets.checkmarkCircle03
                    : ImageAssets.moneyOrderDetails,
                width: 22.w,
                height: 22.w,
                colorFilter: ColorFilter.mode(accent, BlendMode.srcIn),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  'mosaedPaymentStatus'.tr(),
                  style: getBoldStyle(
                    fontSize: 14.sp,
                    color: MosaedColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  form.paymentStatusLabelKey.tr(),
                  style: getMediumStyle(fontSize: 11.sp, color: accent),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            hint,
            style: getRegularStyle(
              fontSize: 12.sp,
              color: MosaedColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _CashConfirmFooter extends StatelessWidget {
  const _CashConfirmFooter({
    required this.confirming,
    required this.onConfirm,
  });

  final bool confirming;
  final VoidCallback onConfirm;

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
          text: confirming
              ? 'mosaedConfirmingCash'.tr()
              : 'mosaedConfirmCashReceived'.tr(),
          isLoading: confirming,
          onPressed: confirming ? null : onConfirm,
          icon: Icons.payments_rounded,
        ),
      ),
    );
  }
}

class _TaskFooter extends StatelessWidget {
  const _TaskFooter({
    required this.workStarted,
    required this.hasBeforePhoto,
    required this.showStartMode,
    required this.canChat,
    required this.onChat,
    required this.onStart,
    required this.onUploadBefore,
    required this.onDeliver,
  });

  final bool workStarted;
  final bool hasBeforePhoto;
  final bool showStartMode;
  final bool canChat;
  final VoidCallback onChat;
  final VoidCallback onStart;
  final VoidCallback onUploadBefore;
  final VoidCallback onDeliver;

  @override
  Widget build(BuildContext context) {
    final Widget button;
    if (hasBeforePhoto) {
      button = MosaedPrimaryButton(
        text: 'mosaedDeliverWork'.tr(),
        onPressed: onDeliver,
      );
    } else if (workStarted) {
      button = MosaedPrimaryButton(
        text: 'mosaedUploadThePhoto'.tr(),
        onPressed: onUploadBefore,
      );
    } else if (showStartMode || !canChat) {
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
