import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../app/functions.dart';
import '../../../core/constants/mosaed_colors.dart';
import '../../../core/constants/styles_manager.dart';
import '../../../core/network/failure.dart';
import '../../auth/presentation/widgets/mosaed_buttons.dart';
import '../data/booking_model.dart';
import '../data/completion_form_model.dart';
import '../data/order_model.dart';
import '../data/provider_custom_request_model.dart';
import '../data/provider_orders_repository.dart';
import 'completion_form_upload_screen.dart';

class CompletionFormDetailScreen extends StatefulWidget {
  const CompletionFormDetailScreen({
    super.key,
    required this.bookingId,
    this.initialTitle,
    this.kind = CompletionFormKind.booking,
  });

  final String bookingId;
  final String? initialTitle;
  final CompletionFormKind kind;

  @override
  State<CompletionFormDetailScreen> createState() =>
      _CompletionFormDetailScreenState();
}

class _CompletionFormDetailScreenState extends State<CompletionFormDetailScreen> {
  Booking? _booking;
  ProviderCustomRequest? _customRequest;
  CompletionForm? _completionForm;
  bool _loading = true;
  bool _confirmingCash = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  String get _bookingId => widget.bookingId;
  bool get _isCustom => widget.kind == CompletionFormKind.customRequest;

  bool get _isFinished => _completionForm?.isFinished == true;

  bool get _workNotStarted => _completionForm?.workNotStarted ?? true;

  bool get _needsAfterUpdate => _completionForm?.needsAfterUpload ?? false;

  bool get _readyToFinish => _completionForm?.readyToFinish ?? false;

  bool get _canOpenUpload => !_isFinished;

  OrderStatus get _workStatus => _completionForm?.status ?? OrderStatus.pending;

  String get _uploadButtonText {
    if (_workNotStarted) return 'mosaedStartService'.tr();
    if (_needsAfterUpdate) return 'mosaedContinueUploadPhotos'.tr();
    if (_readyToFinish) return 'mosaedFinishJob'.tr();
    return 'mosaedUploadWorkPhotos'.tr();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final repo = context.read<ProviderOrdersRepository>();
      var completionForm = await repo.getCompletionFormDetail(
        _bookingId,
        kind: widget.kind,
      );

      Booking? booking;
      ProviderCustomRequest? customRequest;
      if (_isCustom) {
        try {
          customRequest =
              await repo.getProviderCustomRequestDetail(_bookingId);
        } catch (_) {
          // Still show completion form without request metadata.
        }
      } else {
        try {
          booking = await repo.getProviderBookingDetail(_bookingId);
        } catch (_) {
          // Still show completion form without booking metadata.
        }
      }

      completionForm = _mergePaymentIntoForm(
        completionForm,
        bookingPaymentRequestId: booking?.paymentRequestId,
        bookingPaymentStatus: booking?.paymentStatus,
        bookingUnpaid: booking != null && !booking.paymentReceived,
      );

      // Existed bookings often put payment on a separate endpoint.
      if (completionForm.isFinished &&
          (completionForm.paymentStatus == null ||
              completionForm.paymentStatus!.trim().isEmpty ||
              !completionForm.hasPaymentRequest)) {
        final linked = await repo.getLinkedPayment(
          workId: _bookingId,
          kind: widget.kind,
        );
        if (linked != null) {
          completionForm = completionForm.copyWith(
            paymentRequestId:
                completionForm.paymentRequestId ?? linked['id'],
            paymentStatus: completionForm.paymentStatus ?? linked['status'],
          );
        }
      }

      if (!mounted) return;

      setState(() {
        _booking = booking;
        _customRequest = customRequest;
        _completionForm = completionForm;
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
        _error = 'mosaedCompletionFormLoadError'.tr();
        _loading = false;
      });
    }
  }

  CompletionForm _mergePaymentIntoForm(
    CompletionForm form, {
    String? bookingPaymentRequestId,
    String? bookingPaymentStatus,
    bool bookingUnpaid = false,
  }) {
    final needsId = !form.hasPaymentRequest;
    final needsStatus =
        form.paymentStatus == null || form.paymentStatus!.trim().isEmpty;

    var next = form;
    if (needsId || needsStatus) {
      next = form.copyWith(
        paymentRequestId: needsId
            ? (bookingPaymentRequestId?.trim().isNotEmpty == true
                ? bookingPaymentRequestId
                : form.paymentRequestId)
            : form.paymentRequestId,
        paymentStatus: needsStatus
            ? (bookingPaymentStatus?.trim().isNotEmpty == true
                ? bookingPaymentStatus
                : form.paymentStatus)
            : form.paymentStatus,
      );
    }

    // Finished existed booking with no payment fields yet → treat as awaiting method.
    if (next.isFinished &&
        bookingUnpaid &&
        !next.paymentConfirmed &&
        (next.paymentStatus == null || next.paymentStatus!.trim().isEmpty)) {
      next = next.copyWith(paymentStatus: 'awaiting_method');
    }

    return next;
  }

  String get _displayTitle =>
      _booking?.serviceTitle ??
      _customRequest?.title ??
      _completionForm?.serviceTitle ??
      widget.initialTitle ??
      'mosaedCompletionFormDetails'.tr();

  Future<void> _openUploadScreen() async {
    final title = _displayTitle;

    if (_readyToFinish) {
      await _openFinishScreen(title);
      return;
    }

    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CompletionFormUploadScreen(
          bookingId: _bookingId,
          serviceTitle: title,
          kind: widget.kind,
        ),
      ),
    );

    if (!mounted) return;
    await _load();
  }

  Future<void> _openFinishScreen(String title) async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CompletionFormUploadScreen(
          bookingId: _bookingId,
          serviceTitle: title,
          kind: widget.kind,
          startOnFinishStep: true,
        ),
      ),
    );

    if (!mounted) return;
    await _load();
  }

  Future<void> _confirmCash() async {
    final paymentRequestId = _completionForm?.paymentRequestId?.trim();
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
      final repo = context.read<ProviderOrdersRepository>();
      await repo.confirmCashPayment(paymentRequestId);
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
    final title = _displayTitle;

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
          'mosaedCompletionFormDetails'.tr(),
          style: getBoldStyle(fontSize: 18.sp, color: MosaedColors.textPrimary),
        ),
        actions: [
          IconButton(
            onPressed: _loading ? null : _load,
            icon: Icon(Icons.refresh_rounded, color: MosaedColors.primary),
          ),
        ],
      ),
      body: _buildBody(title),
    );
  }

  Widget _buildBody(String title) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: MosaedColors.primaryContainer),
      );
    }

    final hasEntity = _isCustom
        ? _completionForm != null
        : _booking != null;
    if (_error != null || !hasEntity) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_off_rounded, size: 48.sp, color: MosaedColors.textHint),
              SizedBox(height: 12.h),
              Text(
                _error ?? 'mosaedCompletionFormLoadError'.tr(),
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

    final booking = _booking;
    final custom = _customRequest;
    final finished = _isFinished;
    final workStatus = _workStatus;
    final location = _isCustom
        ? (custom?.locationText ?? '')
        : (booking?.addressText ?? '');
    final notes = _completionForm?.notes ?? booking?.notes ?? custom?.description;

    return RefreshIndicator(
      onRefresh: _load,
      color: MosaedColors.primary,
      child: ListView(
        padding: EdgeInsets.all(20.w),
        children: [
          _headerCard(
            title: title,
            workStatus: workStatus,
            customerName: booking?.customerName,
            totalCost: booking?.totalCost ??
                custom?.myOffer?.displayPrice ??
                0,
            badge: _isCustom ? 'mosaedCustomRequestBadge'.tr() : null,
          ),
          SizedBox(height: 12.h),
          // Payment status first when finished & unpaid — clearest signal.
          if (finished &&
              (_completionForm?.isPaymentPending == true ||
                  _completionForm?.paymentConfirmed == true ||
                  _completionForm?.hasPaymentRequest == true ||
                  (_completionForm?.paymentStatus?.trim().isNotEmpty ??
                      false))) ...[
            _paymentStatusCard(_completionForm!),
            SizedBox(height: 12.h),
          ],
          _statusHintCard(workStatus),
          SizedBox(height: 12.h),
          if (location.trim().isNotEmpty)
            _infoCard(
              title: 'mosaedServiceLocation'.tr(),
              value: location,
              icon: Icons.location_on_outlined,
            ),
          if (_isCustom &&
              custom != null &&
              custom.description.trim().isNotEmpty) ...[
            SizedBox(height: 12.h),
            _infoCard(
              title: 'mosaedProblemDescription'.tr(),
              value: custom.description,
              icon: Icons.description_outlined,
            ),
          ],
          if (!_isCustom && booking != null && booking.items.isNotEmpty) ...[
            SizedBox(height: 12.h),
            _itemsCard(booking),
          ],

          if (!finished && _completionForm?.hasBeforeImage == true) ...[
            SizedBox(height: 16.h),
            _workImagesPreview(showAfter: _completionForm?.hasRealAfterImage == true),
          ],

          if (_canOpenUpload) ...[
            SizedBox(height: 20.h),
            MosaedPrimaryButton(
              text: _uploadButtonText,
              onPressed: _openUploadScreen,
            ),
          ],

          if (finished) ...[
            SizedBox(height: 16.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(14.w),
              decoration: BoxDecoration(
                color: (_completionForm?.isPaymentPending == true)
                    ? const Color(0xFFF59E0B).withValues(alpha: 0.12)
                    : MosaedColors.success.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(
                  color: (_completionForm?.isPaymentPending == true)
                      ? const Color(0xFFF59E0B).withValues(alpha: 0.35)
                      : MosaedColors.success.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    (_completionForm?.isPaymentPending == true)
                        ? Icons.hourglass_top_rounded
                        : Icons.check_circle,
                    color: (_completionForm?.isPaymentPending == true)
                        ? const Color(0xFFF59E0B)
                        : MosaedColors.success,
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      (_completionForm?.isPaymentPending == true)
                          ? (_completionForm?.awaitingPaymentMethod == true
                              ? 'mosaedAwaitingPaymentMethodHint'.tr()
                              : 'mosaedJobFinishedAwaitingPayment'.tr())
                          : 'mosaedJobAlreadyFinished'.tr(),
                      style: getMediumStyle(
                        fontSize: 14.sp,
                        color: (_completionForm?.isPaymentPending == true)
                            ? const Color(0xFFB45309)
                            : MosaedColors.success,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (finished && _completionForm?.hasBeforeImage == true) ...[
              SizedBox(height: 16.h),
              _workImagesPreview(showAfter: true),
            ],
            if (notes?.trim().isNotEmpty == true) ...[
              SizedBox(height: 12.h),
              _infoCard(
                title: 'mosaedCompletionNotes'.tr(),
                value: notes!,
                icon: Icons.sticky_note_2_outlined,
              ),
            ],
          ],
          SizedBox(height: 24.h),
        ],
      ),
    );
  }

  Widget _workImagesPreview({required bool showAfter}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'mosaedWorkImages'.tr(),
          style: getBoldStyle(fontSize: 14.sp, color: MosaedColors.textPrimary),
        ),
        SizedBox(height: 10.h),
        Row(
          children: [
            Expanded(
              child: _previewThumb(
                label: 'mosaedBefore'.tr(),
                url: _completionForm?.beforeImage,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _previewThumb(
                label: 'mosaedAfter'.tr(),
                url: showAfter ? _completionForm?.afterImage : null,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _previewThumb({required String label, required String? url}) {
    return Container(
      height: 100.h,
      decoration: BoxDecoration(
        color: MosaedColors.surfaceWhite,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: MosaedColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: url != null && url.isNotEmpty
          ? Stack(
              fit: StackFit.expand,
              children: [
                Image.network(url, fit: BoxFit.cover),
                Positioned(
                  left: 6.w,
                  right: 6.w,
                  bottom: 6.h,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: getMediumStyle(fontSize: 10.sp, color: Colors.white),
                    ),
                  ),
                ),
              ],
            )
          : Center(
              child: Text(
                label,
                style: getRegularStyle(
                  fontSize: 12.sp,
                  color: MosaedColors.textHint,
                ),
              ),
            ),
    );
  }

  Widget _statusHintCard(OrderStatus status) {
    final paymentPending = _completionForm?.isPaymentPending == true;
    final text = switch (status) {
      OrderStatus.completed => paymentPending
          ? 'mosaedJobFinishedAwaitingPayment'.tr()
          : 'mosaedJobAlreadyFinished'.tr(),
      OrderStatus.workerArrived => _readyToFinish
          ? 'mosaedFinishJob'.tr()
          : _needsAfterUpdate
              ? 'mosaedUploadAfterStepHint'.tr()
              : 'mosaedWorkInProgressHint'.tr(),
      OrderStatus.pending => 'mosaedUploadBeforeStepHint'.tr(),
      OrderStatus.cancelled => 'mosaedOrderCancelled'.tr(),
    };
    final color = status == OrderStatus.completed && paymentPending
        ? const Color(0xFFF59E0B)
        : status.statusColor;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        text,
        style: getMediumStyle(fontSize: 13.sp, color: color),
      ),
    );
  }

  Widget _paymentStatusCard(CompletionForm form) {
    final confirmed = form.paymentConfirmed;
    final awaitingCash = form.awaitingCashConfirmation;
    final Color accent = confirmed
        ? MosaedColors.success
        : awaitingCash
            ? MosaedColors.primary
            : const Color(0xFFF59E0B);

    String hint;
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
              Icon(
                confirmed
                    ? Icons.verified_rounded
                    : Icons.payments_outlined,
                color: accent,
                size: 22.sp,
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
          if (awaitingCash) ...[
            SizedBox(height: 12.h),
            MosaedPrimaryButton(
              text: _confirmingCash
                  ? 'mosaedConfirmingCash'.tr()
                  : 'mosaedConfirmCashReceived'.tr(),
              isLoading: _confirmingCash,
              onPressed: _confirmingCash ? null : _confirmCash,
              icon: Icons.payments_rounded,
            ),
          ],
        ],
      ),
    );
  }

  Widget _headerCard({
    required String title,
    required OrderStatus workStatus,
    String? customerName,
    double totalCost = 0,
    String? badge,
  }) {
    final paymentPending = _completionForm?.isPaymentPending == true;
    final paymentConfirmed = _completionForm?.paymentConfirmed == true;
    final statusColor = paymentPending
        ? const Color(0xFFF59E0B)
        : paymentConfirmed && workStatus == OrderStatus.completed
            ? MosaedColors.success
            : workStatus.statusColor;
    final statusLabel = paymentPending
        ? (_completionForm?.paymentStatusLabelKey.tr() ??
            'mosaedPaymentPending'.tr())
        : workStatus.statusKey.tr();

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
          if (badge != null) ...[
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: MosaedColors.primaryFixed,
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Text(
                badge,
                style: getMediumStyle(
                  fontSize: 11.sp,
                  color: MosaedColors.primary,
                ),
              ),
            ),
            SizedBox(height: 10.h),
          ],
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
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  statusLabel,
                  style: getMediumStyle(fontSize: 11.sp, color: statusColor),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            '#${_bookingId.length > 8 ? _bookingId.substring(0, 8) : _bookingId}',
            style: getRegularStyle(
              fontSize: 12.sp,
              color: MosaedColors.textSecondary,
            ),
          ),
          if (customerName != null && customerName.trim().isNotEmpty) ...[
            SizedBox(height: 6.h),
            Text(
              '${'mosaedCustomer'.tr()}: $customerName',
              style: getRegularStyle(
                fontSize: 13.sp,
                color: MosaedColors.textSecondary,
              ),
            ),
          ],
          if (totalCost > 0) ...[
            SizedBox(height: 8.h),
            Text(
              '${totalCost.toStringAsFixed(0)} ${'mosaedCurrency'.tr()}',
              style: getBoldStyle(fontSize: 16.sp, color: MosaedColors.primary),
            ),
          ],
        ],
      ),
    );
  }

  Widget _itemsCard(Booking booking) {
    return Container(
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
            'mosaedServiceItems'.tr(),
            style: getBoldStyle(fontSize: 14.sp, color: MosaedColors.textPrimary),
          ),
          SizedBox(height: 10.h),
          ...booking.items.map(
            (item) => Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      item.attributeName,
                      style: getRegularStyle(
                        fontSize: 13.sp,
                        color: MosaedColors.textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    item.value.toString(),
                    style: getBoldStyle(
                      fontSize: 13.sp,
                      color: MosaedColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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
