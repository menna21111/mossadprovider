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
import '../../auth/data/auth_repository.dart';
import '../../custom_service/presentation/custom_request_detail_screen.dart';
import '../../custom_service/presentation/widgets/request_format_helpers.dart';
import '../../orders/data/completion_form_model.dart';
import '../../orders/data/provider_custom_request_model.dart';
import '../../orders/data/provider_offer_model.dart';
import '../../orders/data/provider_orders_repository.dart';
import '../../orders/presentation/task_detail_screen.dart';
import 'offer_detail_screen.dart';
import 'widgets/home_relative_time.dart';
import 'widgets/home_work_card.dart';
import 'widgets/my_works_assigned_card.dart';
import 'widgets/my_works_empty_state.dart';
import 'widgets/my_works_offer_card.dart';
import 'widgets/my_works_pill_tabs.dart';

enum MyWorksSection { nearby, offers, assigned }

class MyWorksTab extends StatefulWidget {
  const MyWorksTab({super.key, this.initialSection = MyWorksSection.nearby});

  final MyWorksSection initialSection;

  @override
  State<MyWorksTab> createState() => MyWorksTabState();
}

class MyWorksTabState extends State<MyWorksTab> {
  late MyWorksSection _section = widget.initialSection;

  List<ProviderCustomRequest> _nearby = const [];
  List<ProviderOffer> _offers = const [];
  /// Assigned jobs: existed bookings + custom-request completion forms.
  List<CompletionForm> _assigned = const [];
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

    final repo = context.read<ProviderOrdersRepository>();
    final authRepo = context.read<AuthRepository>();
    try {
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

      final requests = await repo.getProviderCustomRequests(
        lat: providerLat,
        lng: providerLng,
      );
      final offers = await repo.getProviderOffers();

      List<CompletionForm> bookingForms = const [];
      List<CompletionForm> customForms = const [];
      try {
        bookingForms = await repo.getCompletionForms();
      } catch (_) {}
      try {
        customForms = await repo.getCustomCompletionForms();
      } catch (_) {}
      final assigned = [...bookingForms, ...customForms]
          .where((form) => form.isCurrentWork)
          .toList()
        ..sort((a, b) {
          final aDate = DateTime.tryParse(a.createdAt ?? '') ?? DateTime(1970);
          final bDate = DateTime.tryParse(b.createdAt ?? '') ?? DateTime(1970);
          return bDate.compareTo(aDate);
        });

      var nearby = requests.where((r) => !r.hasMyOffer).toList();
      nearby = await _enrichNearbyCoords(
        repo,
        nearby,
        providerLat: providerLat,
        providerLng: providerLng,
      );

      if (!mounted) return;
      setState(() {
        _nearby = nearby;
        _offers = offers;
        _assigned = assigned;
        _providerLat = providerLat;
        _providerLng = providerLng;
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
        _error = 'mosaedMyWorksLoadError'.tr();
        _loading = false;
      });
    }
  }

  void openSection(MyWorksSection section) {
    setState(() => _section = section);
    if (section == MyWorksSection.assigned) {
      reload();
    }
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
        if (!request.hasCoords) {
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

  void _openRequest(ProviderCustomRequest request) {
    AppFunctions.navigateTo(
      context,
      CustomRequestDetailScreen(requestId: request.id),
      PageTransitionType.rightToLeft,
    );
  }

  void _openOffer(ProviderOffer offer) {
    AppFunctions.navigateTo(
      context,
      OfferDetailScreen(offerId: offer.id, initialOffer: offer),
      PageTransitionType.rightToLeft,
    );
  }

  void _openAssigned(CompletionForm form) {
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
    final labels = [
      'mosaedNearbyOpportunitiesNearYou'.tr(),
      'mosaedMyOffers'.tr(),
      'mosaedAssignedToYou'.tr(),
    ];

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 0),
            child: Center(
              child: Text(
                'mosaedMyWorks'.tr(),
                style: getBoldStyle(
                  fontSize: 20.sp,
                  color: MosaedColors.textPrimary,
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
            child: MyWorksPillTabs(
              labels: labels,
              selectedIndex: _section.index,
              onChanged: (i) => setState(
                () => _section = MyWorksSection.values[i],
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              color: MosaedColors.brand,
              onRefresh: reload,
              child: _buildBody(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: 140.h),
          const Center(
            child: CircularProgressIndicator(color: MosaedColors.brand),
          ),
        ],
      );
    }

    if (_error != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(24.w),
        children: [
          SizedBox(height: 80.h),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: getRegularStyle(
              fontSize: 14.sp,
              color: MosaedColors.textSecondary,
            ),
          ),
          SizedBox(height: 12.h),
          TextButton(onPressed: reload, child: Text('retry'.tr())),
        ],
      );
    }

    switch (_section) {
      case MyWorksSection.nearby:
        return _nearbyList();
      case MyWorksSection.offers:
        return _offersList();
      case MyWorksSection.assigned:
        return _assignedList();
    }
  }

  Widget _nearbyList() {
    if (_nearby.isEmpty) {
      return MyWorksEmptyState(
        image: ImageAssets.noPlaces,
        message: 'mosaedNoNearbyOpportunities'.tr(),
      );
    }
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h),
      itemCount: _nearby.length,
      separatorBuilder: (_, _) => SizedBox(height: 12.h),
      itemBuilder: (context, index) {
        final item = _nearby[index];
        final customerName = (item.customerName ?? '').trim().isNotEmpty
            ? item.customerName!.trim()
            : 'mosaedClient'.tr();
        return HomeWorkCard(
          width: double.infinity,
          height: 215.h,
          badge: 'mosaedCustomRequestBadge'.tr(),
          badgeColor: const Color(0xFF1B7A4A),
          badgeBackground: const Color(0xFFDEFFEB),
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
              _distanceTo(
                lat: item.lat,
                lng: item.lng,
              ),
          locationText:
              item.locationText.isNotEmpty ? item.locationText : null,
          scheduledDate: (item.scheduledDate ?? '').trim().isNotEmpty
              ? requestScheduleLabel(context, item.scheduledDate)
              : null,
          onTap: () => _openRequest(item),
        );
      },
    );
  }

  Widget _offersList() {
    if (_offers.isEmpty) {
      return MyWorksEmptyState(
        image: ImageAssets.noOffer,
        message: 'mosaedNoOffersYet'.tr(),
      );
    }
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h),
      itemCount: _offers.length,
      separatorBuilder: (_, _) => SizedBox(height: 12.h),
      itemBuilder: (context, index) {
        final offer = _offers[index];
        return MyWorksOfferCard(
          offer: offer,
          onTap: () => _openOffer(offer),
        );
      },
    );
  }

  Widget _assignedList() {
    if (_assigned.isEmpty) {
      return MyWorksEmptyState(
        image: ImageAssets.serviceToMe,
        message: 'mosaedNoAssignedWorks'.tr(),
      );
    }
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h),
      itemCount: _assigned.length,
      separatorBuilder: (_, _) => SizedBox(height: 12.h),
      itemBuilder: (context, index) {
        final form = _assigned[index];
        return MyWorksAssignedCard(
          form: form,
          distanceKm: _distanceTo(lat: form.lat, lng: form.lng),
          onTap: () => _openAssigned(form),
        );
      },
    );
  }
}
