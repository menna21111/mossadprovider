import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:page_transition/page_transition.dart';

import '../../../app/functions.dart';
import '../../../core/constants/mosaed_colors.dart';
import '../../../core/constants/styles_manager.dart';
import '../../../core/network/failure.dart';
import '../../../core/widgets/orders_shimmer.dart';
import '../../orders/data/completion_form_model.dart';
import '../../orders/data/order_model.dart';
import '../../orders/data/provider_orders_repository.dart';
import '../../orders/presentation/completion_form_detail_screen.dart';

enum _CompletionStatusFilter {
  all,
  published,
  completed,
}

enum _CompletionDateFilter {
  all,
  today,
  custom,
}

class OrdersTab extends StatefulWidget {
  const OrdersTab({super.key});

  @override
  State<OrdersTab> createState() => _OrdersTabState();
}

class _OrdersTabState extends State<OrdersTab> {
  List<ServiceOrder> _customOrders = [];
  List<ServiceOrder> _bookingOrders = [];
  bool _loading = true;
  String? _error;

  _CompletionStatusFilter _statusFilter = _CompletionStatusFilter.all;
  _CompletionDateFilter _dateFilter = _CompletionDateFilter.all;
  DateTimeRange? _customRange;

  bool get _isEmpty => _customOrders.isEmpty && _bookingOrders.isEmpty;

  String? get _statusQuery {
    switch (_statusFilter) {
      case _CompletionStatusFilter.all:
        return null;
      case _CompletionStatusFilter.published:
        return 'published';
      case _CompletionStatusFilter.completed:
        return 'completed';
    }
  }

  String? get _dateFromQuery {
    switch (_dateFilter) {
      case _CompletionDateFilter.all:
        return null;
      case _CompletionDateFilter.today:
        return _formatApiDate(DateTime.now());
      case _CompletionDateFilter.custom:
        return _customRange == null
            ? null
            : _formatApiDate(_customRange!.start);
    }
  }

  String? get _dateToQuery {
    switch (_dateFilter) {
      case _CompletionDateFilter.all:
        return null;
      case _CompletionDateFilter.today:
        return _formatApiDate(DateTime.now());
      case _CompletionDateFilter.custom:
        return _customRange == null ? null : _formatApiDate(_customRange!.end);
    }
  }

  String _formatApiDate(DateTime date) =>
      DateFormat('yyyy-MM-dd').format(date);

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

    final repo = context.read<ProviderOrdersRepository>();
    ServerFailure? bookingFailure;

    List<CompletionForm> customForms = const [];
    List<CompletionForm> bookingForms = const [];

    final status = _statusQuery;
    final dateFrom = _dateFromQuery;
    final dateTo = _dateToQuery;

    try {
      customForms = await repo.getCustomCompletionForms(
        status: status,
        dateFrom: dateFrom,
        dateTo: dateTo,
      );
    } catch (_) {
      // Custom section optional — don't block booking forms.
      customForms = const [];
    }

    try {
      bookingForms = await repo.getCompletionForms(
        status: status,
        dateFrom: dateFrom,
        dateTo: dateTo,
      );
    } on ServerFailure catch (e) {
      bookingFailure = e;
    } catch (_) {
      bookingFailure = ServerFailure('mosaedOrdersLoadError'.tr());
    }

    if (!mounted) return;

    final customOrders =
        customForms.map((form) => form.toServiceOrder()).toList()
          ..sort((a, b) => b.scheduledSlot.compareTo(a.scheduledSlot));
    final bookingOrders =
        bookingForms.map((form) => form.toServiceOrder()).toList()
          ..sort((a, b) => b.scheduledSlot.compareTo(a.scheduledSlot));

    final failure = bookingFailure;
    if (customOrders.isEmpty && bookingOrders.isEmpty && failure != null) {
      setState(() {
        _customOrders = [];
        _bookingOrders = [];
        _loading = false;
        _error = failure.errMessage;
      });
      return;
    }

    setState(() {
      _customOrders = customOrders;
      _bookingOrders = bookingOrders;
      _loading = false;
      _error = null;
    });
  }

  Future<void> _applyStatus(_CompletionStatusFilter filter) async {
    if (_statusFilter == filter) return;
    setState(() => _statusFilter = filter);
    await _load();
  }

  Future<void> _applyDate(_CompletionDateFilter filter) async {
    if (filter == _CompletionDateFilter.custom) {
      await _pickCustomRange();
      return;
    }
    if (_dateFilter == filter && filter != _CompletionDateFilter.custom) {
      return;
    }
    setState(() {
      _dateFilter = filter;
      if (filter != _CompletionDateFilter.custom) {
        _customRange = null;
      }
    });
    await _load();
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final initial = _customRange ??
        DateTimeRange(
          start: now.subtract(const Duration(days: 30)),
          end: now,
        );

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 1, 12, 31),
      initialDateRange: initial,
      helpText: 'mosaedFilterDateRange'.tr(),
      cancelText: 'cancel'.tr(),
      confirmText: 'mosaedApplyFilter'.tr(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: MosaedColors.primary,
                ),
          ),
          child: child!,
        );
      },
    );

    if (picked == null || !mounted) return;

    setState(() {
      _dateFilter = _CompletionDateFilter.custom;
      _customRange = picked;
    });
    await _load();
  }

  void _openOrder(ServiceOrder order) {
    final workId = order.bookingId;
    if (workId == null || workId.isEmpty) {
      AppFunctions.showsToast(
        'mosaedCompletionFormLoadError'.tr(),
        MosaedColors.danger,
        context,
      );
      return;
    }

    AppFunctions.navigateTo(
      context,
      CompletionFormDetailScreen(
        bookingId: workId,
        initialTitle: order.serviceTitle,
        kind: order.isCustomRequest
            ? CompletionFormKind.customRequest
            : CompletionFormKind.booking,
      ),
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
                        'mosaedCompletionForms'.tr(),
                        style: getBoldStyle(
                          fontSize: 22.sp,
                          color: MosaedColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        'mosaedCompletionFormsSubtitle'.tr(),
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
            _buildFilters(),
            SizedBox(height: 16.h),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    final customLabel = _customRange == null
        ? 'mosaedFilterDateRange'.tr()
        : '${_formatApiDate(_customRange!.start)} → ${_formatApiDate(_customRange!.end)}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'mosaedFilterByStatus'.tr(),
          style: getMediumStyle(
            fontSize: 12.sp,
            color: MosaedColors.textSecondary,
          ),
        ),
        SizedBox(height: 8.h),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _FilterChip(
                label: 'mosaedFilterAll'.tr(),
                selected: _statusFilter == _CompletionStatusFilter.all,
                onTap: () => _applyStatus(_CompletionStatusFilter.all),
              ),
              SizedBox(width: 8.w),
              _FilterChip(
                label: 'mosaedFilterPublished'.tr(),
                selected: _statusFilter == _CompletionStatusFilter.published,
                onTap: () => _applyStatus(_CompletionStatusFilter.published),
              ),
              SizedBox(width: 8.w),
              _FilterChip(
                label: 'mosaedFilterCompleted'.tr(),
                selected: _statusFilter == _CompletionStatusFilter.completed,
                onTap: () => _applyStatus(_CompletionStatusFilter.completed),
              ),
            ],
          ),
        ),
        SizedBox(height: 12.h),
        Text(
          'mosaedFilterByDate'.tr(),
          style: getMediumStyle(
            fontSize: 12.sp,
            color: MosaedColors.textSecondary,
          ),
        ),
        SizedBox(height: 8.h),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _FilterChip(
                label: 'mosaedFilterAll'.tr(),
                selected: _dateFilter == _CompletionDateFilter.all,
                onTap: () => _applyDate(_CompletionDateFilter.all),
              ),
              SizedBox(width: 8.w),
              _FilterChip(
                label: 'mosaedFilterToday'.tr(),
                selected: _dateFilter == _CompletionDateFilter.today,
                onTap: () => _applyDate(_CompletionDateFilter.today),
              ),
              SizedBox(width: 8.w),
              _FilterChip(
                label: customLabel,
                selected: _dateFilter == _CompletionDateFilter.custom,
                icon: Icons.date_range_rounded,
                onTap: () => _applyDate(_CompletionDateFilter.custom),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (_loading) return const OrdersShimmer();

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

    if (_isEmpty) {
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
                Icons.assignment_outlined,
                size: 40.sp,
                color: MosaedColors.primary,
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              'mosaedNoCompletionFormsYet'.tr(),
              style: getBoldStyle(
                fontSize: 16.sp,
                color: MosaedColors.textPrimary,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'mosaedFilterEmptyHint'.tr(),
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
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          if (_customOrders.isNotEmpty) ...[
            _sectionHeader('mosaedCustomCompletionForms'.tr()),
            SizedBox(height: 12.h),
            ..._cardsFor(_customOrders),
            if (_bookingOrders.isNotEmpty) SizedBox(height: 24.h),
          ],
          if (_bookingOrders.isNotEmpty) ...[
            _sectionHeader('mosaedBookingCompletionForms'.tr()),
            SizedBox(height: 12.h),
            ..._cardsFor(_bookingOrders),
          ],
          SizedBox(height: 12.h),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Text(
      title,
      style: getBoldStyle(
        fontSize: 15.sp,
        color: MosaedColors.textPrimary,
      ),
    );
  }

  List<Widget> _cardsFor(List<ServiceOrder> orders) {
    final widgets = <Widget>[];
    for (var i = 0; i < orders.length; i++) {
      if (i > 0) widgets.add(SizedBox(height: 12.h));
      final order = orders[i];
      widgets.add(
        _OrderCard(
          order: order,
          onTap: () => _openOrder(order),
        ),
      );
    }
    return widgets;
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

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
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 14.sp,
                  color: selected
                      ? MosaedColors.primary
                      : MosaedColors.textSecondary,
                ),
                SizedBox(width: 6.w),
              ],
              Text(
                label,
                style: getMediumStyle(
                  fontSize: 12.sp,
                  color: selected
                      ? MosaedColors.primary
                      : MosaedColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order, required this.onTap});

  final ServiceOrder order;
  final VoidCallback onTap;

  String _localized(String value) =>
      value.startsWith('mosaed') ? value.tr() : value;

  @override
  Widget build(BuildContext context) {
    final currency = 'mosaedCurrency'.tr();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18.r),
      child: Container(
        decoration: BoxDecoration(
          color: MosaedColors.surface,
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(
            color: order.isCustomRequest
                ? MosaedColors.primary.withValues(alpha: 0.25)
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
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14.r),
                child: Container(
                  width: 56.w,
                  height: 56.w,
                  color: order.statusColor.withValues(alpha: 0.1),
                  child: order.serviceImage != null &&
                          order.serviceImage!.isNotEmpty
                      ? Image.network(
                          order.serviceImage!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(
                            order.isCustomRequest
                                ? Icons.handyman_outlined
                                : Icons.assignment_outlined,
                            color: order.statusColor,
                          ),
                        )
                      : Icon(
                          order.isCustomRequest
                              ? Icons.handyman_outlined
                              : Icons.assignment_outlined,
                          color: order.statusColor,
                          size: 28.sp,
                        ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (order.isCustomRequest) ...[
                      Text(
                        'mosaedCustomRequestBadge'.tr(),
                        style: getMediumStyle(
                          fontSize: 10.sp,
                          color: MosaedColors.primary,
                        ),
                      ),
                      SizedBox(height: 2.h),
                    ],
                    Text(
                      order.serviceTitle,
                      style: getBoldStyle(
                        fontSize: 15.sp,
                        color: MosaedColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      order.id,
                      style: getRegularStyle(
                        fontSize: 12.sp,
                        color: MosaedColors.textSecondary,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      _localized(order.scheduledSlot),
                      style: getRegularStyle(
                        fontSize: 11.sp,
                        color: MosaedColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: order.needsPayment
                          ? const Color(0xFFF59E0B).withValues(alpha: 0.15)
                          : order.statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Text(
                      order.needsPayment
                          ? 'mosaedPaymentDueBanner'.tr()
                          : order.statusKey.tr(),
                      style: getMediumStyle(
                        fontSize: 11.sp,
                        color: order.needsPayment
                            ? const Color(0xFFB45309)
                            : order.statusColor,
                      ),
                    ),
                  ),
                  if (order.agreedAmount > 0) ...[
                    SizedBox(height: 6.h),
                    Text(
                      '${order.agreedAmount.toStringAsFixed(0)} $currency',
                      style: getBoldStyle(
                        fontSize: 14.sp,
                        color: MosaedColors.primary,
                      ),
                    ),
                  ],
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
      ),
    );
  }
}
