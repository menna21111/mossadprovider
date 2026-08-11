import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../app/functions.dart';
import '../../../core/constants/mosaed_colors.dart';
import '../../../core/constants/styles_manager.dart';
import '../../auth/presentation/widgets/mosaed_buttons.dart';
import '../../orders/data/order_model.dart';

class OrderDetailsScreen extends StatefulWidget {
  const OrderDetailsScreen({super.key, required this.order});

  final ServiceOrder order;

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  late bool _paymentReceived;
  late String? _paymentTime;
  late double _customerRating;
  late bool _complaintSubmitted;
  final _complaintController = TextEditingController();
  bool _submittingComplaint = false;
  bool _submittingPayment = false;

  @override
  void initState() {
    super.initState();
    _paymentReceived = widget.order.paymentReceived;
    _paymentTime = widget.order.paymentTime;
    _customerRating = widget.order.customerRating;
    _complaintSubmitted = widget.order.complaintSubmitted;
  }

  @override
  void dispose() {
    _complaintController.dispose();
    super.dispose();
  }

  ServiceOrder get order => widget.order;

  String _val(String value) => value.startsWith('mosaed') ? value.tr() : value;

  Future<void> _confirmPayment() async {
    setState(() => _submittingPayment = true);
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() {
      _paymentReceived = true;
      _paymentTime = 'mosaedPaidJustNow';
      _submittingPayment = false;
    });
    AppFunctions.showsToast(
      'mosaedPaymentConfirmed'.tr(),
      MosaedColors.success,
      context,
    );
  }

  void _submitRating(int stars) {
    setState(() => _customerRating = stars.toDouble());
    AppFunctions.showsToast(
      'mosaedRatingSubmitted'.tr(),
      MosaedColors.success,
      context,
    );
  }

  Future<void> _submitComplaint() async {
    final text = _complaintController.text.trim();
    if (text.isEmpty) {
      AppFunctions.showsToast(
        'mosaedComplaintRequired'.tr(),
        MosaedColors.danger,
        context,
      );
      return;
    }
    setState(() => _submittingComplaint = true);
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() {
      _complaintSubmitted = true;
      _submittingComplaint = false;
    });
    AppFunctions.showsToast(
      'mosaedComplaintSubmitted'.tr(),
      MosaedColors.success,
      context,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MosaedColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'mosaedOrderDetails'.tr(args: [order.id]),
          style: getBoldStyle(fontSize: 18.sp, color: MosaedColors.textPrimary),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HeaderCard(order: order),
            if (order.hasWorkerArrived) ...[
              SizedBox(height: 12.h),
              _HighlightBanner(
                icon: Icons.engineering_rounded,
                title: 'mosaedWorkerArrivedTitle'.tr(),
                subtitle: _val(order.arrivedAt),
                color: MosaedColors.primary,
                background: MosaedColors.shieldBg,
              ),
            ],
            if (order.isCompleted) ...[
              SizedBox(height: 12.h),
              _HighlightBanner(
                icon: Icons.task_alt_rounded,
                title: 'mosaedServiceFinishedTitle'.tr(),
                subtitle: _val(order.finishedAt),
                color: MosaedColors.success,
                background: MosaedColors.successBg,
              ),
            ],
            SizedBox(height: 16.h),
            _Section(
              title: 'mosaedWorkerInfo'.tr(),
              child: _WorkerCard(order: order),
            ),
            if (order.isCompleted) ...[
              SizedBox(height: 16.h),
              _Section(
                title: 'mosaedPaymentInfo'.tr(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _InfoRow(
                      label: 'mosaedAgreedAmount'.tr(),
                      value:
                          '${order.agreedAmount.toStringAsFixed(0)} ${'mosaedCurrency'.tr()}',
                    ),
                    _InfoRow(
                      label: 'mosaedPaymentStatus'.tr(),
                      value: _paymentReceived
                          ? 'mosaedPaymentReceived'.tr()
                          : 'mosaedPaymentPending'.tr(),
                      valueColor: _paymentReceived
                          ? MosaedColors.success
                          : MosaedColors.danger,
                    ),
                    if (_paymentReceived && _paymentTime != null)
                      _InfoRow(
                        label: 'mosaedPaymentTime'.tr(),
                        value: _paymentTime!.startsWith('mosaed')
                            ? _paymentTime!.tr()
                            : _paymentTime!,
                        valueColor: MosaedColors.success,
                      ),
                    if (!_paymentReceived) ...[
                      SizedBox(height: 8.h),
                      MosaedPrimaryButton(
                        text: 'mosaedConfirmPayment'.tr(),
                        icon: Icons.payments_rounded,
                        isLoading: _submittingPayment,
                        onPressed: _confirmPayment,
                      ),
                    ],
                  ],
                ),
              ),
            ],
            SizedBox(height: 16.h),
            _Section(
              title: 'mosaedTimeline'.tr(),
              child: Column(
                children: [
                  _InfoRow(
                    label: 'mosaedScheduledTime'.tr(),
                    value: _val(order.scheduledSlot),
                  ),
                  if (!order.isPending)
                    _InfoRow(
                      label: 'mosaedArrivalTime'.tr(),
                      value: _val(order.arrivedAt),
                      valueColor: order.hasWorkerArrived || order.isCompleted
                          ? MosaedColors.primary
                          : null,
                    ),
                  if (order.isCompleted)
                    _InfoRow(
                      label: 'mosaedFinishTime'.tr(),
                      value: _val(order.finishedAt),
                      valueColor: MosaedColors.success,
                    ),
                ],
              ),
            ),
            if (!order.isPending) ...[
              SizedBox(height: 16.h),
              _Section(
                title: 'mosaedUsedItems'.tr(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'mosaedToolsUsed'.tr(),
                      style: getMediumStyle(
                        fontSize: 13.sp,
                        color: MosaedColors.textSecondary,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    if (order.toolsUsed.isEmpty)
                      Text('mosaedNotAvailableYet'.tr())
                    else
                      Wrap(
                        spacing: 8.w,
                        runSpacing: 8.h,
                        children: order.toolsUsed
                            .map((tool) => _Chip(text: _val(tool)))
                            .toList(),
                      ),
                    SizedBox(height: 14.h),
                    Text(
                      'mosaedMaterialsUsed'.tr(),
                      style: getMediumStyle(
                        fontSize: 13.sp,
                        color: MosaedColors.textSecondary,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    if (order.materialsUsed.isEmpty)
                      Text('mosaedNotAvailableYet'.tr())
                    else
                      Wrap(
                        spacing: 8.w,
                        runSpacing: 8.h,
                        children: order.materialsUsed
                            .map((item) => _Chip(text: _val(item)))
                            .toList(),
                      ),
                  ],
                ),
              ),
            ],
            if (order.isCompleted) ...[
              SizedBox(height: 16.h),
              _Section(
                title: 'mosaedRatingSection'.tr(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _InfoRow(
                      label: 'mosaedWorkerRating'.tr(),
                      value: order.workerRating > 0
                          ? '${order.workerRating} ⭐'
                          : 'mosaedNotAvailableYet'.tr(),
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      'mosaedYourRating'.tr(),
                      style: getMediumStyle(
                        fontSize: 13.sp,
                        color: MosaedColors.textSecondary,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    if (_customerRating > 0)
                      Row(
                        children: List.generate(
                          5,
                          (i) => Icon(
                            i < _customerRating.round()
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            color: const Color(0xFFF59E0B),
                            size: 32.sp,
                          ),
                        ),
                      )
                    else
                      Row(
                        children: List.generate(
                          5,
                          (i) => IconButton(
                            onPressed: () => _submitRating(i + 1),
                            icon: Icon(
                              Icons.star_outline_rounded,
                              color: const Color(0xFFF59E0B),
                              size: 36.sp,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(height: 16.h),
              _Section(
                title: 'mosaedComplaintSection'.tr(),
                child: _complaintSubmitted
                    ? Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(14.w),
                        decoration: BoxDecoration(
                          color: MosaedColors.successBg,
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                            color: MosaedColors.success.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle_outline_rounded,
                              color: MosaedColors.success,
                            ),
                            SizedBox(width: 10.w),
                            Expanded(
                              child: Text(
                                'mosaedComplaintReceived'.tr(),
                                style: getMediumStyle(
                                  fontSize: 13.sp,
                                  color: MosaedColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'mosaedComplaintHint'.tr(),
                            style: getRegularStyle(
                              fontSize: 13.sp,
                              color: MosaedColors.textSecondary,
                            ),
                          ),
                          SizedBox(height: 10.h),
                          TextField(
                            controller: _complaintController,
                            maxLines: 4,
                            decoration: InputDecoration(
                              hintText: 'mosaedComplaintPlaceholder'.tr(),
                              filled: true,
                              fillColor: MosaedColors.inputFill,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14.r),
                              ),
                            ),
                          ),
                          SizedBox(height: 12.h),
                          MosaedPrimaryButton(
                            text: 'mosaedSubmitComplaint'.tr(),
                            icon: Icons.send_rounded,
                            isLoading: _submittingComplaint,
                            onPressed: _submitComplaint,
                          ),
                        ],
                      ),
              ),
            ],
            SizedBox(height: 16.h),
            _Section(
              title: 'mosaedOrderNotes'.tr(),
              child: Text(
                _val(order.notes),
                style: getRegularStyle(
                  fontSize: 14.sp,
                  color: MosaedColors.textPrimary,
                ),
              ),
            ),
            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }
}

class _HighlightBanner extends StatelessWidget {
  const _HighlightBanner({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.background,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 44.w,
            height: 44.w,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(icon, color: color, size: 24.sp),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: getBoldStyle(fontSize: 14.sp, color: color),
                ),
                SizedBox(height: 4.h),
                Text(
                  subtitle,
                  style: getRegularStyle(
                    fontSize: 12.sp,
                    color: MosaedColors.textSecondary,
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

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.order});

  final ServiceOrder order;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: MosaedColors.surface,
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
                  order.serviceTitle,
                  style: getBoldStyle(
                    fontSize: 20.sp,
                    color: MosaedColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: order.statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  order.statusKey.tr(),
                  style: getMediumStyle(
                    fontSize: 11.sp,
                    color: order.statusColor,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 16.sp,
                color: MosaedColors.primary,
              ),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  order.locationText,
                  style: getRegularStyle(
                    fontSize: 13.sp,
                    color: MosaedColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WorkerCard extends StatelessWidget {
  const _WorkerCard({required this.order});

  final ServiceOrder order;

  @override
  Widget build(BuildContext context) {
    if (order.workerName == 'mosaedWorkerPending') {
      return Text(
        'mosaedWorkerAssigning'.tr(),
        style: getRegularStyle(
          fontSize: 14.sp,
          color: MosaedColors.textSecondary,
        ),
      );
    }

    return Row(
      children: [
        CircleAvatar(
          radius: 28.r,
          backgroundColor: MosaedColors.shieldBg,
          child: Icon(Icons.engineering_rounded, color: MosaedColors.primary),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                order.workerName,
                style: getBoldStyle(
                  fontSize: 16.sp,
                  color: MosaedColors.textPrimary,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                '${order.workerRating} ⭐ • ${order.workerJobsCount} ${'mosaedCompletedJobs'.tr()}',
                style: getRegularStyle(
                  fontSize: 12.sp,
                  color: MosaedColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: MosaedColors.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: MosaedColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: getBoldStyle(fontSize: 15.sp, color: MosaedColors.textPrimary),
          ),
          SizedBox(height: 12.h),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: getRegularStyle(
                fontSize: 13.sp,
                color: MosaedColors.textSecondary,
              ),
            ),
          ),
          Text(
            value,
            style: getMediumStyle(
              fontSize: 13.sp,
              color: valueColor ?? MosaedColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: MosaedColors.inputFill,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(
        text,
        style: getMediumStyle(fontSize: 12.sp, color: MosaedColors.textPrimary),
      ),
    );
  }
}
