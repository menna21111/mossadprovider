import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:page_transition/page_transition.dart';

import '../../../app/functions.dart';
import '../../../core/constants/assets_manager.dart';
import '../../../core/constants/mosaed_colors.dart';
import '../../../core/constants/styles_manager.dart';
import '../../../core/network/failure.dart';
import '../../../core/utils/geo_distance.dart';
import '../../../core/widgets/orders_shimmer.dart';
import '../../auth/data/auth_repository.dart';
import '../../custom_service/presentation/widgets/request_format_helpers.dart';
import '../../orders/data/completion_form_model.dart';
import '../../orders/data/provider_orders_repository.dart';
import '../../orders/presentation/task_detail_screen.dart';
import 'widgets/my_works_job_card.dart';

class OrdersTab extends StatefulWidget {
  const OrdersTab({super.key});

  @override
  State<OrdersTab> createState() => _OrdersTabState();
}

class _OrdersTabState extends State<OrdersTab> {
  List<CompletionForm> _tasks = const [];
  double? _providerLat;
  double? _providerLng;
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

    final ordersRepo = context.read<ProviderOrdersRepository>();
    final authRepo = context.read<AuthRepository>();

    double? providerLat;
    double? providerLng;
    try {
      final profile = await authRepo.getProviderProfile();
      if (profile.addresses.isNotEmpty) {
        final address = profile.addresses.first;
        providerLat = parseCoord(address.lat);
        providerLng = parseCoord(address.lng);
      }
    } catch (_) {}

    List<CompletionForm> customForms = const [];
    List<CompletionForm> bookingForms = const [];
    ServerFailure? failure;

    try {
      customForms = await ordersRepo.getCustomCompletionForms();
    } catch (_) {
      customForms = const [];
    }

    try {
      bookingForms = await ordersRepo.getCompletionForms();
    } on ServerFailure catch (e) {
      failure = e;
    } catch (_) {
      failure = ServerFailure('mosaedOrdersLoadError'.tr());
    }

    if (!mounted) return;

    final tasks = [...customForms, ...bookingForms]
      ..sort((a, b) {
        final aDate = DateTime.tryParse(a.createdAt ?? '') ?? DateTime(1970);
        final bDate = DateTime.tryParse(b.createdAt ?? '') ?? DateTime(1970);
        return bDate.compareTo(aDate);
      });

    if (tasks.isEmpty && failure != null) {
      setState(() {
        _tasks = const [];
        _providerLat = providerLat;
        _providerLng = providerLng;
        _loading = false;
        _error = failure!.errMessage;
      });
      return;
    }

    setState(() {
      _tasks = tasks;
      _providerLat = providerLat;
      _providerLng = providerLng;
      _loading = false;
      _error = null;
    });
  }

  double? _distanceFor(CompletionForm form) {
    return distanceKmBetween(
      fromLat: _providerLat,
      fromLng: _providerLng,
      toLat: form.lat,
      toLng: form.lng,
    );
  }

  void _openTask(CompletionForm form) {
    final workId = form.workId;
    if (workId.isEmpty) {
      AppFunctions.showsToast(
        'mosaedCompletionFormLoadError'.tr(),
        MosaedColors.danger,
        context,
      );
      return;
    }

    AppFunctions.navigateTo(
      context,
      TaskDetailScreen(
        workId: workId,
        initialTitle: form.serviceTitle,
        kind: form.kind,
      ),
      PageTransitionType.rightToLeft,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MosaedColors.surfaceWhite,
      appBar: AppBar(
        backgroundColor: MosaedColors.surfaceWhite,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: Text(
          'mosaedNavTasks'.tr(),
          style: getBoldStyle(
            fontSize: 16.sp,
            color: MosaedColors.textPrimary,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.h),
          child: const Divider(height: 1, color: MosaedColors.fieldBorder),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: OrdersShimmer(),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.cloud_off_rounded,
                size: 48.sp,
                color: MosaedColors.textHint,
              ),
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

    if (_tasks.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        color: MosaedColors.brand,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: 120.h),
            Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 32.w),
                child: Column(
                  children: [
                    Image.asset(
                      ImageAssets.noPlaces,
                      width: 220.w,
                      fit: BoxFit.contain,
                    ),
                    SizedBox(height: 20.h),
                    Text(
                      'mosaedNoTasksEmpty'.tr(),
                      textAlign: TextAlign.center,
                      style: getBoldStyle(
                        fontSize: 15.sp,
                        color: MosaedColors.textPrimary,
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

    return RefreshIndicator(
      onRefresh: _load,
      color: MosaedColors.brand,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 24.h),
        itemCount: _tasks.length,
        separatorBuilder: (_, _) => SizedBox(height: 12.h),
        itemBuilder: (context, index) {
          final form = _tasks[index];
          final isCustom = form.isCustomRequest;
          final title = (form.serviceTitle ?? '').trim().isNotEmpty
              ? form.serviceTitle!.trim()
              : (isCustom
                  ? 'mosaedCustomRequest'.tr()
                  : 'mosaedActiveJob'.tr());
          final specialization = (form.specializationName ?? '').trim();
          final description = () {
            final desc = form.displayDescription.trim();
            if (desc.isNotEmpty &&
                desc != title &&
                desc != 'mosaedJobInProgressHint'.tr()) {
              return desc;
            }
            if (specialization.isNotEmpty && specialization != title) {
              return specialization;
            }
            return desc;
          }();

          return MyWorksJobCard(
            title: title,
            description: description,
            createdAt: form.createdAt,
            locationText:
                form.locationText.isNotEmpty ? form.locationText : null,
            scheduledDate: (form.scheduledDate ?? '').trim().isNotEmpty
                ? requestScheduleLabel(context, form.scheduledDate)
                : null,
            distanceKm: _distanceFor(form),
            imageUrl: form.cardImage,
            photoCount: form.cardPhotoCount > 0 ? form.cardPhotoCount : null,
            showSideImage: true,
            badgeLabel: isCustom
                ? 'mosaedCustomRequestBadge'.tr()
                : 'mosaedBookingTaskBadge'.tr(),
            badgeColor: isCustom
                ? const Color(0xFF1B7A4A)
                : MosaedColors.brand,
            badgeBackground: isCustom
                ? const Color(0xFFDEFFEB)
                : MosaedColors.otpFill,
            onTap: () => _openTask(form),
          );
        },
      ),
    );
  }
}
