import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:page_transition/page_transition.dart';

import '../../../app/functions.dart';
import '../../../core/constants/mosaed_colors.dart';
import '../../../core/constants/styles_manager.dart';
import '../../../core/network/failure.dart';
import '../../../core/widgets/mosaed_dropdown.dart';
import '../../../core/widgets/service_thumbnail.dart';
import '../data/models/existed_service.dart';
import '../data/services_repository.dart';
import 'service_booking_screen.dart';

class ServiceDetailScreen extends StatefulWidget {
  const ServiceDetailScreen({super.key, required this.serviceId});

  final String serviceId;

  @override
  State<ServiceDetailScreen> createState() => _ServiceDetailScreenState();
}

class _ServiceDetailScreenState extends State<ServiceDetailScreen> {
  ExistedServiceDetail? _detail;
  List<ServicePreviousWork> _previousWorks = [];
  String? _selectedAttributeId;
  bool _descriptionExpanded = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final repo = context.read<ServicesRepository>();
      final results = await Future.wait([
        repo.getServiceDetail(widget.serviceId),
        repo.getServicePreviousWorks(widget.serviceId),
      ]);
      if (!mounted) return;
      final detail = results[0] as ExistedServiceDetail;
      setState(() {
        _detail = detail;
        _previousWorks = results[1] as List<ServicePreviousWork>;
        if (detail.attributes.isNotEmpty) {
          _selectedAttributeId = detail.attributes.first.id;
        }
        _descriptionExpanded = false;
        _loading = false;
      });
    } on ServerFailure catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        AppFunctions.showsToast(e.errMessage, MosaedColors.danger, context);
        Navigator.pop(context);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
        Navigator.pop(context);
      }
    }
  }

  void _openBooking() {
    AppFunctions.navigateTo(
      context,
      ServiceBookingScreen(serviceId: widget.serviceId),
      PageTransitionType.rightToLeft,
    );
  }

  ServiceAttribute? get _selectedAttribute {
    final attrs = _detail?.attributes ?? [];
    if (_selectedAttributeId == null) return null;
    for (final attr in attrs) {
      if (attr.id == _selectedAttributeId) return attr;
    }
    return null;
  }

  void _onAttributeSelected(String? value) {
    if (value == null) return;
    setState(() {
      _selectedAttributeId = value;
      _descriptionExpanded = false;
    });
  }

  void _showPreviousWorks() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: MosaedColors.surfaceWhite,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.92,
        builder: (_, controller) => Padding(
          padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 24.h),
          child: Column(
            children: [
              Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: MosaedColors.border,
                  borderRadius: BorderRadius.circular(4.r),
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                'mosaedPreviousWorks'.tr(),
                style: getBoldStyle(
                  fontSize: 18.sp,
                  color: MosaedColors.textPrimary,
                ),
              ),
              SizedBox(height: 16.h),
              Expanded(
                child: _previousWorks.isEmpty
                    ? Center(
                        child: Text(
                          'mosaedNoPreviousWorks'.tr(),
                          style: getRegularStyle(
                            fontSize: 14.sp,
                            color: MosaedColors.textSecondary,
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: controller,
                        itemCount: _previousWorks.length,
                        itemBuilder: (_, i) =>
                            _previousWorkCard(_previousWorks[i]),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _detail == null) {
      return Scaffold(
        backgroundColor: MosaedColors.background,
        appBar: _topBar(),
        body: const Center(
          child: CircularProgressIndicator(color: MosaedColors.primaryContainer),
        ),
      );
    }

    final detail = _detail!;
    final currency = 'mosaedCurrency'.tr();

    return Scaffold(
      backgroundColor: MosaedColors.background,
      appBar: _topBar(),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 32.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _heroImage(detail),
            SizedBox(height: 20.h),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        detail.title,
                        style: getBoldStyle(
                          fontSize: 22.sp,
                          color: MosaedColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Row(
                        children: [
                          Icon(
                            Icons.star_rounded,
                            size: 16.sp,
                            color: MosaedColors.primaryContainer,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            '4.8 (120 ${'mosaedReviews'.tr()})',
                            style: getRegularStyle(
                              fontSize: 13.sp,
                              color: MosaedColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Material(
                  color: MosaedColors.primaryContainer,
                  borderRadius: BorderRadius.circular(14.r),
                  elevation: 2,
                  shadowColor: Colors.black.withValues(alpha: 0.08),
                  child: InkWell(
                    onTap: _openBooking,
                    borderRadius: BorderRadius.circular(14.r),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 10.h,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add_rounded, color: Colors.white, size: 18.sp),
                          SizedBox(width: 4.w),
                          Text(
                            'mosaedRequestService'.tr(),
                            style: getBoldStyle(fontSize: 13.sp, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (detail.details != null && detail.details!.trim().isNotEmpty) ...[
              SizedBox(height: 16.h),
              Text(
                detail.details!,
                style: getRegularStyle(
                  fontSize: 14.sp,
                  color: MosaedColors.textSecondary,
                  height: 1.6,
                ),
              ),
            ],
            if (detail.visitCostValue != null && detail.visitCostValue! > 0) ...[
              SizedBox(height: 16.h),
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: MosaedColors.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(
                    color: MosaedColors.primary.withValues(alpha: 0.1),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        color: MosaedColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Icon(
                        Icons.directions_car_rounded,
                        color: MosaedColors.primary,
                        size: 22.sp,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        'mosaedVisitCost'.tr(),
                        style: getMediumStyle(
                          fontSize: 15.sp,
                          color: MosaedColors.textSecondary,
                        ),
                      ),
                    ),
                    Text(
                      '${detail.visitCostValue!.toStringAsFixed(0)} ',
                      style: getBoldStyle(
                        fontSize: 20.sp,
                        color: MosaedColors.primary,
                      ),
                    ),
                    Text(
                      currency,
                      style: getMediumStyle(
                        fontSize: 12.sp,
                        color: MosaedColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (detail.attributes.isNotEmpty) ...[
              SizedBox(height: 24.h),
              Text(
                'mosaedOfferedServices'.tr(),
                style: getBoldStyle(
                  fontSize: 18.sp,
                  color: MosaedColors.textPrimary,
                ),
              ),
              SizedBox(height: 10.h),
              Container(
                decoration: BoxDecoration(
                  color: MosaedColors.surfaceWhite,
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(
                    color: MosaedColors.outlineVariant.withValues(alpha: 0.3),
                  ),
                  boxShadow: MosaedColors.softShadow,
                ),
                child: MosaedDropdown<String>(
                  title: '',
                  hint: 'mosaedSelectAttribute'.tr(),
                  icon: Icons.tune_rounded,
                  selectedValue: _selectedAttributeId,
                  items: detail.attributes
                      .map(
                        (attr) => MosaedDropdownItem(
                          value: attr.id,
                          label: attr.name,
                        ),
                      )
                      .toList(),
                  onSelected: _onAttributeSelected,
                ),
              ),
              if (_selectedAttribute != null) ...[
                SizedBox(height: 14.h),
                _costDetailsCard(_selectedAttribute!, currency),
              ],
            ],
            if (detail.warranty != null) ...[
              SizedBox(height: 20.h),
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: MosaedColors.successBg,
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(
                    color: MosaedColors.success.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 28.w,
                      height: 28.w,
                      decoration: const BoxDecoration(
                        color: MosaedColors.success,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.check_rounded, color: Colors.white, size: 16.sp),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Text(
                        'mosaedWarranty'.tr(),
                        style: getMediumStyle(
                          fontSize: 14.sp,
                          color: const Color(0xFF166534),
                        ),
                      ),
                    ),
                    Text(
                      '${detail.warranty!.durationValue} ${detail.warranty!.durationType}',
                      style: getBoldStyle(
                        fontSize: 16.sp,
                        color: const Color(0xFF15803D),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            SizedBox(height: 24.h),
            Text(
              'mosaedPreviousWorks'.tr(),
              style: getBoldStyle(
                fontSize: 18.sp,
                color: MosaedColors.textPrimary,
              ),
            ),
            SizedBox(height: 12.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _previousWorks.isEmpty ? null : _showPreviousWorks,
                style: ElevatedButton.styleFrom(
                  backgroundColor: MosaedColors.primary,
                  disabledBackgroundColor: MosaedColors.border,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  elevation: 2,
                ),
                icon: Icon(Icons.visibility_rounded, color: Colors.white, size: 20.sp),
                label: Text(
                  'mosaedViewPreviousWorks'.tr(),
                  style: getBoldStyle(fontSize: 14.sp, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _topBar() {
    return AppBar(
      backgroundColor: MosaedColors.surfaceWhite,
      elevation: 0,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: Icon(
          Icons.arrow_forward_rounded,
          color: MosaedColors.primary,
          size: 24.sp,
        ),
      ),
      title: Icon(
        Icons.home_repair_service_rounded,
        color: MosaedColors.primary,
        size: 28.sp,
      ),
      centerTitle: false,
    );
  }

  Widget _heroImage(ExistedServiceDetail detail) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14.r),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          fit: StackFit.expand,
          children: [
            detail.hasImage
                ? Image.network(
                    detail.image!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _headerFallback(detail),
                  )
                : _headerFallback(detail),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.4),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 12.h,
              right: 12.w,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: MosaedColors.primary,
                  borderRadius: BorderRadius.circular(8.r),
                  boxShadow: MosaedColors.softShadow,
                ),
                child: Text(
                  'mosaedCertifiedService'.tr(),
                  style: getMediumStyle(fontSize: 11.sp, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _costDetailsCard(ServiceAttribute attr, String currency) {
    final hasDetails = attr.details != null && attr.details!.trim().isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: MosaedColors.surfaceWhite,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: MosaedColors.outlineVariant.withValues(alpha: 0.2),
        ),
        boxShadow: MosaedColors.softShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16.w),
            color: MosaedColors.surfaceContainerLow,
            child: Text(
              'mosaedCostDetails'.tr(),
              style: getBoldStyle(
                fontSize: 16.sp,
                color: MosaedColors.textPrimary,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              children: [
                _detailRow('mosaedAttributeName'.tr(), attr.name),
                SizedBox(height: 12.h),
                if (attr.hasUnitName)
                  _detailRow('mosaedUnitType'.tr(), attr.unitName!),
                if (attr.hasUnitName) SizedBox(height: 12.h),
                _detailRow(
                  'mosaedRequiredField'.tr(),
                  attr.requiredFieldLabel('mosaedRequiredArea'.tr()),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  child: Divider(
                    color: MosaedColors.outlineVariant.withValues(alpha: 0.5),
                    height: 1,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'mosaedUnitPrice'.tr(),
                      style: getRegularStyle(
                        fontSize: 15.sp,
                        color: MosaedColors.textSecondary,
                      ),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          attr.unitCost,
                          style: getBoldStyle(
                            fontSize: 20.sp,
                            color: MosaedColors.primary,
                          ),
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          currency,
                          style: getMediumStyle(
                            fontSize: 12.sp,
                            color: MosaedColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (hasDetails) ...[
                  SizedBox(height: 12.h),
                  InkWell(
                    onTap: () => setState(
                      () => _descriptionExpanded = !_descriptionExpanded,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'mosaedServiceDetails'.tr(),
                            style: getMediumStyle(
                              fontSize: 13.sp,
                              color: MosaedColors.textPrimary,
                            ),
                          ),
                        ),
                        Icon(
                          _descriptionExpanded
                              ? Icons.expand_less_rounded
                              : Icons.expand_more_rounded,
                          color: MosaedColors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                  if (_descriptionExpanded)
                    Padding(
                      padding: EdgeInsets.only(top: 8.h),
                      child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Text(
                          attr.details!,
                          style: getRegularStyle(
                            fontSize: 13.sp,
                            color: MosaedColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: getRegularStyle(
            fontSize: 15.sp,
            color: MosaedColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: getMediumStyle(
            fontSize: 15.sp,
            color: MosaedColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _headerFallback(ExistedService detail) {
    return Container(
      color: detail.accentColor.withValues(alpha: 0.15),
      child: Center(
        child: ServiceThumbnail(
          service: detail,
          size: 80.w,
          borderRadius: BorderRadius.circular(20.r),
        ),
      ),
    );
  }

  Widget _previousWorkCard(ServicePreviousWork work) {
    return Container(
      margin: EdgeInsets.only(bottom: 14.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: MosaedColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: MosaedColors.border),
      ),
      child: Row(
        children: [
          Expanded(child: _workImage(url: work.beforeImage, label: 'mosaedBefore'.tr())),
          SizedBox(width: 10.w),
          Expanded(child: _workImage(url: work.afterImage, label: 'mosaedAfter'.tr())),
        ],
      ),
    );
  }

  Widget _workImage({required String url, required String label}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: getMediumStyle(fontSize: 12.sp, color: MosaedColors.textSecondary),
        ),
        SizedBox(height: 6.h),
        ClipRRect(
          borderRadius: BorderRadius.circular(10.r),
          child: AspectRatio(
            aspectRatio: 3 / 4,
            child: url.isNotEmpty
                ? Image.network(
                    url,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _imagePlaceholder(),
                  )
                : _imagePlaceholder(),
          ),
        ),
      ],
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      color: MosaedColors.inputFill,
      child: Icon(Icons.image_not_supported_outlined, color: MosaedColors.textHint),
    );
  }
}
