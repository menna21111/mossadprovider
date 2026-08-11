import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../app/functions.dart';
import '../../../core/constants/mosaed_colors.dart';
import '../../../core/constants/styles_manager.dart';
import '../../../core/network/failure.dart';
import '../../auth/presentation/widgets/mosaed_buttons.dart';
import '../data/models/address_models.dart';
import '../data/services_repository.dart';
import 'add_address_screen.dart';

class AddressesListScreen extends StatefulWidget {
  const AddressesListScreen({super.key});

  @override
  State<AddressesListScreen> createState() => _AddressesListScreenState();
}

class _AddressesListScreenState extends State<AddressesListScreen> {
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
      if (mounted) setState(() {
        _addresses = list;
        _loading = false;
      });
    } on ServerFailure catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        AppFunctions.showsToast(e.errMessage, MosaedColors.danger, context);
      }
    }
  }

  Future<void> _delete(String id) async {
    try {
      await context.read<ServicesRepository>().deleteAddress(id);
      await _load();
      if (mounted) {
        AppFunctions.showsToast(
          'mosaedAddressDeleted'.tr(),
          MosaedColors.success,
          context,
        );
      }
    } on ServerFailure catch (e) {
      if (mounted) {
        AppFunctions.showsToast(e.errMessage, MosaedColors.danger, context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MosaedColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'mosaedMyAddresses'.tr(),
          style: getBoldStyle(fontSize: 18.sp, color: MosaedColors.textPrimary),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: EdgeInsets.all(20.w),
                children: [
                  MosaedPrimaryButton(
                    text: 'mosaedAddAddress'.tr(),
                    icon: Icons.add_location_alt_rounded,
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AddAddressScreen(canSkip: true),
                        ),
                      );
                      await _load();
                    },
                  ),
                  SizedBox(height: 16.h),
                  if (_addresses.isEmpty)
                    Center(
                      child: Text(
                        'mosaedNoAddressYet'.tr(),
                        style: getRegularStyle(
                          fontSize: 14.sp,
                          color: MosaedColors.textSecondary,
                        ),
                      ),
                    )
                  else
                    ..._addresses.map(
                      (a) => Card(
                        margin: EdgeInsets.only(bottom: 10.h),
                        child: ListTile(
                          leading: Icon(
                            Icons.location_on_rounded,
                            color: MosaedColors.primary,
                          ),
                          title: Text(a.label ?? a.cityName),
                          subtitle: Text(a.fullAddress),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: MosaedColors.danger,
                            ),
                            onPressed: () => _delete(a.id),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
