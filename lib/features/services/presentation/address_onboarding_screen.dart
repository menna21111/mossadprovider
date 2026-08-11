import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../app/functions.dart';
import '../../../core/caching/cach_helper.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/mosaed_colors.dart';
import '../../../core/constants/styles_manager.dart';
import '../../../core/network/failure.dart';
import '../../auth/presentation/widgets/mosaed_buttons.dart';
import '../../home/presentation/main_shell.dart';
import '../data/models/address_models.dart';
import '../data/services_repository.dart';
import 'add_address_screen.dart';

class AddressOnboardingScreen extends StatefulWidget {
  const AddressOnboardingScreen({super.key});

  @override
  State<AddressOnboardingScreen> createState() =>
      _AddressOnboardingScreenState();
}

class _AddressOnboardingScreenState extends State<AddressOnboardingScreen> {
  List<CustomerAddress> _addresses = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await context.read<ServicesRepository>().getAddresses();
      if (mounted) {
        setState(() {
          _addresses = list;
          _loading = false;
        });
      }
    } on ServerFailure catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        AppFunctions.showsToast(e.errMessage, MosaedColors.danger, context);
      }
    }
  }

  bool get _hasValidAddress =>
      _addresses.any((address) => address.lat != '0' && address.lng != '0');

  Future<void> _finish() async {
    if (!_hasValidAddress) {
      AppFunctions.showsToast(
        'mosaedDefaultAddressRequired'.tr(),
        MosaedColors.danger,
        context,
      );
      return;
    }

    await CacheHelper().saveData(
      key: AppConstants.locationSetupDoneKey,
      value: true,
    );
    if (!mounted) return;
    AppFunctions.navigateToAndFinish(context, const MainShell());
  }

  Future<void> _addAddress() async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const AddAddressScreen(canSkip: true),
      ),
    );
    if (saved == true) await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MosaedColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'mosaedAddressOnboardingTitle'.tr(),
          style: getBoldStyle(fontSize: 18.sp, color: MosaedColors.textPrimary),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: EdgeInsets.all(20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'mosaedAddressOnboardingSubtitle'.tr(),
                    style: getRegularStyle(
                      fontSize: 14.sp,
                      color: MosaedColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: 20.h),
                  MosaedPrimaryButton(
                    text: 'mosaedAddAddress'.tr(),
                    icon: Icons.add_location_alt_rounded,
                    onPressed: _addAddress,
                  ),
                  SizedBox(height: 16.h),
                  Expanded(
                    child: _addresses.isEmpty
                        ? Center(
                            child: Text(
                              'mosaedNoAddressYet'.tr(),
                              style: getRegularStyle(
                                fontSize: 14.sp,
                                color: MosaedColors.textSecondary,
                              ),
                            ),
                          )
                        : ListView.separated(
                            itemCount: _addresses.length,
                            separatorBuilder: (context, index) =>
                                SizedBox(height: 10.h),
                            itemBuilder: (context, index) {
                              final address = _addresses[index];
                              return Container(
                                padding: EdgeInsets.all(14.w),
                                decoration: BoxDecoration(
                                  color: MosaedColors.surface,
                                  borderRadius: BorderRadius.circular(14.r),
                                  border: Border.all(color: MosaedColors.border),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.location_on_rounded,
                                      color: MosaedColors.primary,
                                    ),
                                    SizedBox(width: 10.w),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            address.label ?? address.cityName,
                                            style: getBoldStyle(
                                              fontSize: 14.sp,
                                              color: MosaedColors.textPrimary,
                                            ),
                                          ),
                                          Text(
                                            address.fullAddress,
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
                            },
                          ),
                  ),
                  SizedBox(height: 16.h),
                  MosaedPrimaryButton(
                    text: 'mosaedContinue'.tr(),
                    icon: Icons.arrow_forward_rounded,
                    onPressed: _hasValidAddress ? _finish : null,
                  ),
                ],
              ),
            ),
    );
  }
}
