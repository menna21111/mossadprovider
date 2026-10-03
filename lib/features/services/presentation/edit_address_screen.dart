import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../app/functions.dart';
import '../../../core/constants/mosaed_colors.dart';
import '../../../core/constants/styles_manager.dart';
import '../../../core/network/failure.dart';
import '../../auth/presentation/widgets/mosaed_buttons.dart';
import '../data/models/address_models.dart';
import '../data/services_repository.dart';
import 'pick_location_map_screen.dart';
import 'widgets/address_chrome.dart';
import 'widgets/address_form_fields.dart';
import 'widgets/address_map_preview.dart';
import 'widgets/address_place_type.dart';

class EditAddressScreen extends StatefulWidget {
  const EditAddressScreen({super.key, required this.address});

  final CustomerAddress address;

  @override
  State<EditAddressScreen> createState() => _EditAddressScreenState();
}

class _EditAddressScreenState extends State<EditAddressScreen> {
  static const _riyadh = LatLng(24.713552, 46.675297);

  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();

  late AddressPlaceType _placeType;
  late bool _isDefault;
  late LatLng _position;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final a = widget.address;
    _placeType = addressPlaceTypeFromLabel(a.label);
    _isDefault = a.isDefault;
    _addressController.text =
        a.shortAddress.isNotEmpty ? a.shortAddress : a.fullAddress;
    _addressController.addListener(_onAddressChanged);
    _position = LatLng(
      double.tryParse(a.lat) ?? _riyadh.latitude,
      double.tryParse(a.lng) ?? _riyadh.longitude,
    );
  }

  void _onAddressChanged() => setState(() {});

  @override
  void dispose() {
    _addressController.removeListener(_onAddressChanged);
    _addressController.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      !_saving && _addressController.text.trim().isNotEmpty;

  Future<void> _openMapPicker() async {
    final picked = await PickLocationMapScreen.open(
      context,
      initialPosition: _position,
      goToCurrentOnStart: false,
    );
    if (picked != null && mounted) {
      setState(() => _position = picked);
    }
  }

  Future<void> _goToCurrentLocation() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      if (mounted) {
        AppFunctions.showsToast(
          'mosaedLocationPermissionDenied'.tr(),
          MosaedColors.danger,
          context,
        );
      }
      return;
    }
    try {
      final pos = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() => _position = LatLng(pos.latitude, pos.longitude));
      }
    } catch (_) {}
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_canSubmit) return;

    setState(() => _saving = true);
    try {
      final original = widget.address;
      await context.read<ServicesRepository>().updateAddress(
            original.id,
            CreateAddressPayload(
              city: original.city,
              region: original.region,
              district: _addressController.text.trim(),
              street: original.street,
              buildingNo: original.buildingNo,
              floorNo: original.floorNo,
              apartmentNo: original.apartmentNo,
              lat: _position.latitude,
              lng: _position.longitude,
              label: _placeType.label,
              isDefault: _isDefault,
            ),
          );
      if (!mounted) return;
      AppFunctions.showsToast(
        'mosaedAddressUpdated'.tr(),
        MosaedColors.success,
        context,
      );
      Navigator.pop(context, true);
    } on ServerFailure catch (e) {
      if (mounted) {
        AppFunctions.showsToast(e.errMessage, MosaedColors.danger, context);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MosaedColors.surfaceWhite,
      appBar: AddressAppBar(title: 'mosaedEditAddress'.tr()),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 16.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AddressTypeTiles(
                      value: _placeType,
                      onChanged: (v) => setState(() => _placeType = v),
                    ),
                    SizedBox(height: 20.h),
                    AddressFieldLabel('mosaedAddress'.tr()),
                    SizedBox(height: 8.h),
                    TextFormField(
                      controller: _addressController,
                      style: getRegularStyle(
                        fontSize: 13.sp,
                        color: MosaedColors.textPrimary,
                      ),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'mosaedAddress'.tr()
                          : null,
                      decoration: addressFieldDecoration(
                        hint: 'mosaedSelectDistrict'.tr(),
                      ),
                    ),
                    SizedBox(height: 16.h),
                    AddressMapPreview(
                      position: _position,
                      onTap: _openMapPicker,
                      onLocate: _goToCurrentLocation,
                    ),
                    SizedBox(height: 20.h),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'mosaedSetAsPrimary'.tr(),
                            style: getMediumStyle(
                              fontSize: 13.sp,
                              color: MosaedColors.textPrimary,
                            ),
                          ),
                        ),
                        Switch.adaptive(
                          value: _isDefault,
                          activeTrackColor: MosaedColors.brand,
                          activeThumbColor: Colors.white,
                          onChanged: (v) => setState(() => _isDefault = v),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 16.h),
              decoration: const BoxDecoration(
                color: MosaedColors.surfaceWhite,
                border: Border(
                  top: BorderSide(color: MosaedColors.fieldBorder),
                ),
              ),
              child: SafeArea(
                top: false,
                child: MosaedPrimaryButton(
                  text: 'mosaedSaveChanges'.tr(),
                  isLoading: _saving,
                  enabled: _canSubmit,
                  onPressed: _canSubmit ? _save : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
