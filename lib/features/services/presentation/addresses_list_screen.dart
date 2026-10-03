import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

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
import 'edit_address_screen.dart';
import 'pick_location_map_screen.dart';
import 'widgets/address_chrome.dart';
import 'widgets/address_list_card.dart';
import 'widgets/location_prompt_sheet.dart';

class AddressesListScreen extends StatefulWidget {
  const AddressesListScreen({
    super.key,
    this.showLocationPromptOnOpen = false,
    this.onboarding = false,
  });

  /// Opens the location method sheet after the first frame.
  final bool showLocationPromptOnOpen;

  /// After save / later → mark setup done and go home.
  final bool onboarding;

  @override
  State<AddressesListScreen> createState() => _AddressesListScreenState();
}

class _AddressesListScreenState extends State<AddressesListScreen> {
  List<CustomerAddress> _addresses = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load().then((_) {
      if (!mounted) return;
      if (_addresses.isNotEmpty) return;
      if (widget.showLocationPromptOnOpen || widget.onboarding) {
        _openAddFlow();
      }
    });
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await context.read<ServicesRepository>().getAddresses();
      if (mounted) {
        setState(() {
          // Provider keeps a single address only.
          _addresses = list.isEmpty ? const [] : [list.first];
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

  Future<void> _finishOnboarding() async {
    await CacheHelper().saveData(
      key: AppConstants.locationSetupDoneKey,
      value: true,
    );
    if (!mounted) return;
    AppFunctions.navigateToAndFinish(context, const MainShell());
  }

  Future<void> _openAddFlow() async {
    if (_addresses.isNotEmpty) return;
    final action = await LocationPromptSheet.show(context);
    if (!mounted || action == null) return;

    switch (action) {
      case LocationPromptAction.later:
        if (widget.onboarding) await _finishOnboarding();
        return;
      case LocationPromptAction.currentLocation:
        await _addViaCurrentLocation();
      case LocationPromptAction.manual:
        await _addManually();
    }
  }

  Future<void> _addViaCurrentLocation() async {
    final picked = await PickLocationMapScreen.open(
      context,
      goToCurrentOnStart: true,
    );
    if (!mounted || picked == null) return;
    await _openAddAddressForm(initialPosition: picked);
  }

  Future<void> _addManually() async {
    await _openAddAddressForm();
  }

  Future<void> _openAddAddressForm({LatLng? initialPosition}) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddAddressScreen(
          canSkip: true,
          initialPosition: initialPosition,
        ),
      ),
    );
    if (!mounted) return;
    if (saved == true) {
      if (widget.onboarding) {
        await _finishOnboarding();
      } else {
        await _load();
      }
    }
  }

  Future<void> _edit(CustomerAddress address) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EditAddressScreen(address: address),
      ),
    );
    if (updated == true && mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MosaedColors.surfaceWhite,
      appBar: AddressAppBar(
        title: 'mosaedMyAddresses'.tr(),
        showBack: !widget.onboarding,
        actions: [
          if (widget.onboarding)
            TextButton(
              onPressed: _finishOnboarding,
              child: Text(
                'mosaedLater'.tr(),
                style: getBoldStyle(
                  fontSize: 13.sp,
                  color: MosaedColors.brand,
                ),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: MosaedColors.brand),
            )
          : RefreshIndicator(
              color: MosaedColors.brand,
              onRefresh: _load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h),
                children: [
                  if (_addresses.isEmpty)
                    Padding(
                      padding: EdgeInsets.only(top: 80.h),
                      child: Text(
                        'mosaedNoAddressYet'.tr(),
                        textAlign: TextAlign.center,
                        style: getRegularStyle(
                          fontSize: 13.sp,
                          color: MosaedColors.textSecondary,
                        ),
                      ),
                    )
                  else
                    AddressListCard(
                      address: _addresses.first,
                      onEdit: () => _edit(_addresses.first),
                    ),
                ],
              ),
            ),
      bottomNavigationBar: _loading || _addresses.isNotEmpty
          ? null
          : Container(
              padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h),
              decoration: const BoxDecoration(
                color: MosaedColors.surfaceWhite,
                border: Border(
                  top: BorderSide(color: MosaedColors.fieldBorder),
                ),
              ),
              child: SafeArea(
                top: false,
                child: MosaedPrimaryButton(
                  text: '+ ${'mosaedAddNewAddress'.tr()}',
                  onPressed: _openAddFlow,
                ),
              ),
            ),
    );
  }
}
