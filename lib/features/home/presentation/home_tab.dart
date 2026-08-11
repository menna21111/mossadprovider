import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:page_transition/page_transition.dart';

import '../../../app/functions.dart';
import '../../../core/constants/mosaed_colors.dart';
import '../../../core/constants/styles_manager.dart';
import '../../../core/network/failure.dart';
import '../../../core/widgets/home_shimmer.dart';
import '../../../core/widgets/service_thumbnail.dart';
import '../../auth/data/auth_repository.dart';
import '../../custom_service/presentation/custom_service_screen.dart';
import '../../custom_service/presentation/widgets/custom_service_home_card.dart';
import '../../services/data/models/existed_service.dart';
import '../../services/data/services_repository.dart';
import '../../services/presentation/service_detail_screen.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  List<ExistedService> _services = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  Future<void> _loadServices() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final services =
          await context.read<ServicesRepository>().getExistedServices();
      if (mounted) {
        setState(() {
          _services = services;
          _loading = false;
        });
      }
    } on ServerFailure catch (e) {
      if (mounted) {
        setState(() {
          _error = e.errMessage;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openServiceDetail(BuildContext context, String serviceId) {
    AppFunctions.navigateTo(
      context,
      ServiceDetailScreen(serviceId: serviceId),
      PageTransitionType.rightToLeft,
    );
  }

  void _openCustomService(BuildContext context) {
    AppFunctions.navigateTo(
      context,
      const CustomServiceScreen(),
      PageTransitionType.rightToLeft,
    );
  }

  @override
  Widget build(BuildContext context) {
    final userName = context.read<AuthRepository>().userName;

    return ColoredBox(
      color: MosaedColors.background,
      child: SafeArea(
        child: RefreshIndicator(
          color: MosaedColors.primaryContainer,
          onRefresh: _loadServices,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Container(
                  padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 16.h),
                  decoration: BoxDecoration(
                    color: MosaedColors.surface.withValues(alpha: 0.92),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 22.r,
                        backgroundColor: MosaedColors.surfaceContainerLow,
                        child: Icon(
                          Icons.person_rounded,
                          color: MosaedColors.primary,
                          size: 26.sp,
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'mosaedWelcomeUser'.tr(),
                              style: getRegularStyle(
                                fontSize: 11.sp,
                                color: MosaedColors.onSurfaceVariant,
                              ),
                            ),
                            Text(
                              userName.isNotEmpty ? userName : 'mosaedGuest'.tr(),
                              style: getBoldStyle(
                                fontSize: 14.sp,
                                color: MosaedColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.notifications,
                        color: MosaedColors.primary,
                        size: 32.sp,
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(child: SizedBox(height: 20.h)),
              SliverToBoxAdapter(
                child: CustomServiceHomeCard(
                  onTap: () => _openCustomService(context),
                ),
              ),
              SliverToBoxAdapter(child: SizedBox(height: 24.h)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'mosaedFeaturedServices'.tr(),
                        style: getBoldStyle(
                          fontSize: 20.sp,
                          color: MosaedColors.textPrimary,
                        ),
                      ),
                      if (_error != null)
                        TextButton(
                          onPressed: _loadServices,
                          child: Text(
                            'mosaedRetry'.tr(),
                            style: getBoldStyle(
                              fontSize: 12.sp,
                              color: MosaedColors.primary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              if (_loading)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                    child: const HomeShimmer(),
                  ),
                )
              else if (_services.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(20.w),
                    child: Text(
                      _error ?? 'noCategories'.tr(),
                      textAlign: TextAlign.center,
                      style: getRegularStyle(
                        fontSize: 14.sp,
                        color: MosaedColors.textSecondary,
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 24.h),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16.h,
                      crossAxisSpacing: 16.w,
                      childAspectRatio: 0.82,
                    ),
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final service = _services[index];
                      return _ServiceGridCard(
                        service: service,
                        onTap: () => _openServiceDetail(context, service.id),
                      );
                    }, childCount: _services.length),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServiceGridCard extends StatelessWidget {
  const _ServiceGridCard({required this.service, required this.onTap});

  final ExistedService service;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: MosaedColors.surfaceWhite,
      borderRadius: BorderRadius.circular(24.r),
      elevation: 0,
      shadowColor: Colors.black.withValues(alpha: 0.05),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24.r),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(
              color: MosaedColors.outlineVariant.withValues(alpha: 0.25),
            ),
            boxShadow: MosaedColors.softShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (service.hasImage)
                        Image.network(
                          service.image!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _imageFallback(),
                        )
                      else
                        _imageFallback(),
                      Positioned(
                        top: 8.h,
                        left: 8.w,
                        child: Container(
                          padding: EdgeInsets.all(6.w),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.92),
                            shape: BoxShape.circle,
                            boxShadow: MosaedColors.softShadow,
                          ),
                          child: ServiceThumbnail(
                            service: service,
                            size: 18.w,
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 8.w),
                child: Text(
                  service.title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: getMediumStyle(
                    fontSize: 13.sp,
                    color: MosaedColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _imageFallback() {
    return Container(
      color: service.accentColor.withValues(alpha: 0.12),
      child: Center(
        child: ServiceThumbnail(
          service: service,
          size: 48.w,
          borderRadius: BorderRadius.circular(14.r),
        ),
      ),
    );
  }
}
