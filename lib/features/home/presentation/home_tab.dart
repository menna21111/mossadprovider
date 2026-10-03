import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:page_transition/page_transition.dart';

import '../../../app/functions.dart';
import '../../../core/constants/assets_manager.dart';
import '../../../core/constants/mosaed_colors.dart';
import '../../../core/utils/geo_distance.dart';
import '../../auth/data/auth_repository.dart';
import '../../custom_service/presentation/custom_request_detail_screen.dart';
import '../../custom_service/presentation/widgets/request_format_helpers.dart';
import '../../notifications/presentation/notifications_screen.dart';
import '../../orders/data/completion_form_model.dart';
import '../../orders/data/provider_custom_request_model.dart';
import '../../orders/data/provider_offer_model.dart';
import '../../orders/data/provider_orders_repository.dart';
import '../../orders/presentation/task_detail_screen.dart';
import 'widgets/home_dues_warning_banner.dart';
import 'widgets/home_error_body.dart';
import 'widgets/home_header.dart';
import 'widgets/home_relative_time.dart';
import 'widgets/home_section_header.dart';
import 'widgets/home_summary_section.dart';
import 'widgets/home_work_card.dart';
import 'widgets/home_work_list.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({
    super.key,
    this.onOpenRequests,
    this.onOpenTasks,
    this.onOpenOffers,
  });

  final VoidCallback? onOpenRequests;
  final VoidCallback? onOpenTasks;
  final VoidCallback? onOpenOffers;

  @override
  State<HomeTab> createState() => HomeTabState();
}

class HomeTabState extends State<HomeTab> {
  List<ProviderCustomRequest> _nearby = const [];
  List<ProviderOffer> _pendingOffers = const [];
  List<CompletionForm> _activeJobs = const [];
  String? _avatarUrl;
  double? _providerLat;
  double? _providerLng;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => reload());
  }

  Future<void> reload() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    final ordersRepo = context.read<ProviderOrdersRepository>();
    final authRepo = context.read<AuthRepository>();
    try {
      String? avatarUrl;
      double? providerLat;
      double? providerLng;
      try {
        final profile = await authRepo.getProviderProfile();
        avatarUrl = profile.avatar;
        if (profile.addresses.isNotEmpty) {
          final address = profile.addresses.first;
          providerLat = parseCoord(address.lat);
          providerLng = parseCoord(address.lng);
        }
      } catch (_) {}

      final nearby = await ordersRepo.getProviderCustomRequests(
        lat: providerLat,
        lng: providerLng,
      );
      final pending = await ordersRepo.getProviderOffers(status: 'pending');
      List<CompletionForm> bookingForms = const [];
      List<CompletionForm> customForms = const [];
      try {
        bookingForms = await ordersRepo.getCompletionForms();
      } catch (_) {}
      try {
        customForms = await ordersRepo.getCustomCompletionForms();
      } catch (_) {}

      // فرص قريبة = طلبات مخصصة لم يُقدَّم عليها عرض بعد
      var nearbyWithoutOffer =
          nearby.where((request) => !request.hasMyOffer).toList();
      nearbyWithoutOffer = await _enrichNearbyCoords(
        ordersRepo,
        nearbyWithoutOffer,
        providerLat: providerLat,
        providerLng: providerLng,
      );

      final activeJobs = [...bookingForms, ...customForms]
          .where((form) => form.isCurrentWork)
          .toList()
        ..sort((a, b) {
          final aDate = DateTime.tryParse(a.createdAt ?? '') ?? DateTime(1970);
          final bDate = DateTime.tryParse(b.createdAt ?? '') ?? DateTime(1970);
          return bDate.compareTo(aDate);
        });

      if (!mounted) return;
      setState(() {
        _nearby = nearbyWithoutOffer;
        _pendingOffers = pending;
        _activeJobs = activeJobs;
        _avatarUrl = avatarUrl;
        _providerLat = providerLat;
        _providerLng = providerLng;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'mosaedHomeLoadError'.tr();
      });
    }
  }

  Future<List<ProviderCustomRequest>> _enrichNearbyCoords(
    ProviderOrdersRepository repo,
    List<ProviderCustomRequest> requests, {
    double? providerLat,
    double? providerLng,
  }) async {
    if (requests.isEmpty) return requests;

    final limit = requests.length.clamp(0, 8);
    final head = requests.take(limit).toList();
    final tail = requests.skip(limit).toList();

    final enrichedHead = await Future.wait(
      head.map((request) async {
        var updated = request;
        if (!request.hasCoords ||
            request.description.trim().isEmpty ||
            (request.customerName ?? '').trim().isEmpty) {
          try {
            final detail = await repo.getProviderCustomRequestDetail(request.id);
            updated = request.copyWith(
              description: request.description.trim().isNotEmpty
                  ? request.description
                  : detail.description,
              customerName: (request.customerName ?? '').trim().isNotEmpty
                  ? request.customerName
                  : detail.customerName,
              customerAvatar: (request.customerAvatar ?? '').trim().isNotEmpty
                  ? request.customerAvatar
                  : detail.customerAvatar,
              city: request.city ?? detail.city,
              region: request.region ?? detail.region,
              district: request.district ?? detail.district,
              lat: request.lat ?? detail.lat,
              lng: request.lng ?? detail.lng,
              photoCount: request.photoCount ?? detail.photoCount,
              image: request.image ?? detail.image,
              images: request.images.isNotEmpty ? request.images : detail.images,
            );
          } catch (_) {}
        }

        final computed = distanceKmBetween(
          fromLat: providerLat,
          fromLng: providerLng,
          toLat: updated.lat,
          toLng: updated.lng,
        );
        if (computed != null) {
          updated = updated.copyWith(distanceKm: computed);
        }
        return updated;
      }),
    );

    return [...enrichedHead, ...tail];
  }

  double? _distanceTo({double? lat, double? lng, double? fallback}) {
    return distanceKmBetween(
          fromLat: _providerLat,
          fromLng: _providerLng,
          toLat: lat,
          toLng: lng,
        ) ??
        fallback;
  }

  void _openNotifications() {
    AppFunctions.navigateTo(
      context,
      const NotificationsScreen(),
      PageTransitionType.rightToLeft,
    );
  }

  void _openRequest(ProviderCustomRequest request) {
    AppFunctions.navigateTo(
      context,
      CustomRequestDetailScreen(requestId: request.id),
      PageTransitionType.rightToLeft,
    );
  }

  void _openJob(CompletionForm form) {
    AppFunctions.navigateTo(
      context,
      TaskDetailScreen(
        workId: form.workId,
        initialTitle: form.serviceTitle,
        kind: form.kind,
      ),
      PageTransitionType.rightToLeft,
    );
  }

  @override
  Widget build(BuildContext context) {
    final rawName = context.read<AuthRepository>().userName.trim();
    final name = rawName.isEmpty ? 'mosaedGuest'.tr() : rawName;

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        color: MosaedColors.brand,
        onRefresh: reload,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 0),
                child: HomeHeader(
                  name: name,
                  avatarUrl: _avatarUrl,
                  onNotificationsTap: _openNotifications,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: HomeDuesWarningBanner()),
            if (_loading)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: CircularProgressIndicator(color: MosaedColors.brand),
                ),
              )
            else if (_error != null)
              SliverFillRemaining(
                hasScrollBody: false,
                child: HomeErrorBody(message: _error!, onRetry: reload),
              )
            else ...[
              SliverToBoxAdapter(
                child: HomeSummarySection(
                  nearbyCount: _nearby.length,
                  pendingOffersCount: _pendingOffers.length,
                  activeJobsCount: _activeJobs.length,
                  onOpenRequests: widget.onOpenRequests,
                  onOpenOffers: widget.onOpenOffers,
                  onOpenTasks: widget.onOpenTasks,
                ),
              ),
              SliverToBoxAdapter(
                child: HomeSectionHeader(
                  title: 'mosaedNearbyOpportunitiesNearYou'.tr(),
                  onViewAll: widget.onOpenRequests,
                ),
              ),
              SliverToBoxAdapter(
                child: HomeWorkList(
                  isEmpty: _nearby.isEmpty,
                  emptyMessage: 'mosaedNoNearbyOpportunities'.tr(),
                  emptyImage: ImageAssets.noPlaces,
                  height: 215.h,
                  emptyHeight: 215.h,
                  itemCount: _nearby.length.clamp(0, 8),
                  itemBuilder: (context, index) {
                    final item = _nearby[index];
                    final customerName =
                        (item.customerName ?? '').trim().isNotEmpty
                            ? item.customerName!.trim()
                            : 'mosaedClient'.tr();
                    return HomeWorkCard(
                      width: 362.w,
                      height: 215.h,
                      badge: 'mosaedCustomRequestBadge'.tr(),
                      imageUrl: item.image,
                      title: item.title.trim().isNotEmpty
                          ? item.title
                          : (item.specializationName ?? 'mosaedCustomRequest'.tr()),
                      personName: customerName,
                      personAvatar: item.customerAvatar,
                      timeLabel: homeRelativeTime(item.createdAt),
                      description: item.displayDescription,
                      photoCount: item.photoCount,
                      distanceKm: item.distanceKm ??
                          _distanceTo(lat: item.lat, lng: item.lng),
                      locationText: item.locationText.isNotEmpty
                          ? item.locationText
                          : null,
                      scheduledDate:
                          (item.scheduledDate ?? '').trim().isNotEmpty
                              ? requestScheduleLabel(
                                  context,
                                  item.scheduledDate,
                                )
                              : null,
                      onTap: () => _openRequest(item),
                    );
                  },
                ),
              ),
              SliverToBoxAdapter(
                child: HomeSectionHeader(
                  title: 'mosaedCurrentWorks'.tr(),
                  onViewAll: widget.onOpenTasks,
                ),
              ),
              SliverToBoxAdapter(
                child: HomeWorkList(
                  isEmpty: _activeJobs.isEmpty,
                  emptyMessage: 'mosaedNoActiveJobs'.tr(),
                  emptyImage: ImageAssets.serviceToMe,
                  height: 215.h,
                  emptyHeight: 215.h,
                  itemCount: _activeJobs.length.clamp(0, 8),
                  itemBuilder: (context, index) {
                    final job = _activeJobs[index];
                    return HomeWorkCard(
                      width: 362.w,
                      height: 215.h,
                      badge: job.isCustomRequest
                          ? 'mosaedCustomRequestBadge'.tr()
                          : 'mosaedBookingTaskBadge'.tr(),
                      badgeColor: job.isCustomRequest
                          ? const Color(0xFF1B7A4A)
                          : MosaedColors.brand,
                      badgeBackground: job.isCustomRequest
                          ? const Color(0xFFDEFFEB)
                          : MosaedColors.otpFill,
                      imageUrl: job.cardImage,
                      title: job.displayTitle,
                      personName: job.displayCustomerName,
                      personAvatar: job.customerAvatar,
                      timeLabel: homeRelativeTime(job.createdAt),
                      description: job.displayDescription,
                      photoCount: job.cardPhotoCount > 0
                          ? job.cardPhotoCount
                          : null,
                      distanceKm: _distanceTo(lat: job.lat, lng: job.lng),
                      locationText: job.locationText.isNotEmpty
                          ? job.locationText
                          : null,
                      scheduledDate:
                          (job.scheduledDate ?? '').trim().isNotEmpty
                              ? job.scheduledDate
                              : null,
                      statusLabel: job.isPaymentPending
                          ? job.paymentStatusLabelKey.tr()
                          : 'mosaedInProgress'.tr(),
                      onTap: () => _openJob(job),
                    );
                  },
                ),
              ),
              SliverToBoxAdapter(child: SizedBox(height: 24.h)),
            ],
          ],
        ),
      ),
    );
  }
}
