import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../app/auth_navigation.dart';
import '../../../app/functions.dart';
import '../../../core/constants/assets_manager.dart';
import '../../../core/constants/mosaed_colors.dart';
import '../../../core/network/failure.dart';
import '../../auth/presentation/widgets/mosaed_buttons.dart';
import '../data/models/address_models.dart';
import '../data/services_repository.dart';
import 'pick_location_map_screen.dart';
import 'widgets/address_chrome.dart';
import 'widgets/address_form_fields.dart';

class AddAddressScreen extends StatefulWidget {
  const AddAddressScreen({
    super.key,
    this.canSkip = false,
    this.initialPosition,
  });

  final bool canSkip;
  final LatLng? initialPosition;

  @override
  State<AddAddressScreen> createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends State<AddAddressScreen> {
  static const _riyadh = LatLng(24.713552, 46.675297);

  final _formKey = GlobalKey<FormState>();
  final _districtController = TextEditingController();
  final _streetController = TextEditingController();
  final _buildingController = TextEditingController();
  final _apartmentController = TextEditingController();

  LatLng _position = _riyadh;
  List<CityModel> _cities = [];
  List<RegionModel> _regions = [];
  String? _selectedCityId;
  String? _selectedRegionId;
  String? _selectedLabel;
  bool _loading = true;
  bool _saving = false;

  List<(String, String)> get _labelOptions => [
        ('mosaedLabelHome'.tr(), 'mosaedLabelHome'.tr()),
        ('mosaedLabelWork'.tr(), 'mosaedLabelWork'.tr()),
        ('mosaedLabelOther'.tr(), 'mosaedLabelOther'.tr()),
      ];

  @override
  void initState() {
    super.initState();
    if (widget.initialPosition != null) {
      _position = widget.initialPosition!;
    }
    _districtController.addListener(_onFormChanged);
    _streetController.addListener(_onFormChanged);
    _buildingController.addListener(_onFormChanged);
    _loadData();
  }

  void _onFormChanged() => setState(() {});

  bool get _canSubmit {
    return !_saving &&
        _selectedCityId != null &&
        _selectedRegionId != null &&
        _districtController.text.trim().isNotEmpty &&
        _streetController.text.trim().isNotEmpty &&
        _selectedLabel != null;
  }

  @override
  void dispose() {
    _districtController.removeListener(_onFormChanged);
    _streetController.removeListener(_onFormChanged);
    _buildingController.removeListener(_onFormChanged);
    _districtController.dispose();
    _streetController.dispose();
    _buildingController.dispose();
    _apartmentController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final cities = await context.read<ServicesRepository>().getCities();
      if (!mounted) return;
      setState(() {
        _cities = cities;
        _loading = false;
      });
      if (widget.initialPosition == null) {
        await _ensureDefaultPosition();
      }
    } on ServerFailure catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        AppFunctions.showsToast(e.errMessage, MosaedColors.danger, context);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _ensureDefaultPosition() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }
      final pos = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() => _position = LatLng(pos.latitude, pos.longitude));
      }
    } catch (_) {}
  }

  Future<void> _onCityChanged(String? cityId) async {
    if (cityId == null) return;
    setState(() {
      _selectedCityId = cityId;
      _selectedRegionId = null;
      _regions = [];
    });
    try {
      final regions =
          await context.read<ServicesRepository>().getRegions(cityId);
      if (!mounted) return;
      setState(() => _regions = regions);
    } catch (_) {}
  }

  Future<void> _openMapPicker() async {
    final picked = await PickLocationMapScreen.open(
      context,
      initialPosition: _position,
      goToCurrentOnStart: true,
    );
    if (picked != null && mounted) {
      setState(() => _position = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_canSubmit) return;

    setState(() => _saving = true);
    try {
      await context.read<ServicesRepository>().createAddress(
            CreateAddressPayload(
              city: _selectedCityId!,
              region: _selectedRegionId!,
              district: _districtController.text.trim(),
              street: _streetController.text.trim(),
              buildingNo: _buildingController.text.trim(),
              apartmentNo: _apartmentController.text.trim(),
              lat: _position.latitude,
              lng: _position.longitude,
              label: _selectedLabel,
            ),
          );
      if (!mounted) return;
      AppFunctions.showsToast(
        'mosaedAddressSaved'.tr(),
        MosaedColors.success,
        context,
      );
      if (widget.canSkip) {
        Navigator.pop(context, true);
      } else {
        await AuthNavigation.goAfterAddressSaved(context);
      }
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
      appBar: AddressAppBar(
        title: 'mosaedAddNewAddress'.tr(),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: MosaedColors.brand),
            )
          : Form(
              key: _formKey,
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(24.w, 8.h, 24.w, 16.h),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AddressFormIntro(
                            title: 'mosaedAddressFormTitle'.tr(),
                            subtitle: 'mosaedAddressFormSubtitle'.tr(),
                          ),
                          SizedBox(height: 24.h),
                          AddressDropdownField<String>(
                            label: 'mosaedCity'.tr(),
                            hint: 'mosaedSelectCity'.tr(),
                            iconAsset: ImageAssets.chooseCity,
                            value: _selectedCityId,
                            items: _cities
                                .map(
                                  (c) => DropdownMenuItem(
                                    value: c.id,
                                    child: Text(c.name),
                                  ),
                                )
                                .toList(),
                            onChanged: _onCityChanged,
                            validator: (v) => v == null
                                ? 'mosaedAddressCityRegionRequired'.tr()
                                : null,
                          ),
                          SizedBox(height: 14.h),
                          AddressDropdownField<String>(
                            label: 'mosaedRegion'.tr(),
                            hint: 'mosaedSelectRegion'.tr(),
                            iconAsset: ImageAssets.mapsGlobal02,
                            value: _selectedRegionId,
                            items: _regions
                                .map(
                                  (r) => DropdownMenuItem(
                                    value: r.id,
                                    child: Text(r.name),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _selectedRegionId = v),
                            validator: (v) => v == null
                                ? 'mosaedAddressCityRegionRequired'.tr()
                                : null,
                          ),
                          SizedBox(height: 14.h),
                          AddressTextField(
                            label: 'mosaedDistrict'.tr(),
                            controller: _districtController,
                            hint: 'mosaedSelectDistrict'.tr(),
                            iconAsset: ImageAssets.chooseArea,
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'mosaedDistrict'.tr()
                                : null,
                          ),
                          SizedBox(height: 14.h),
                          AddressTextField(
                            label: 'mosaedStreet'.tr(),
                            controller: _streetController,
                            hint: 'mosaedStreetDetailedHint'.tr(),
                            iconAsset: ImageAssets.chooseStreet,
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'mosaedStreet'.tr()
                                : null,
                          ),
                          SizedBox(height: 14.h),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: AddressTextField(
                                  label: 'mosaedBuildingNo'.tr(),
                                  controller: _buildingController,
                                  hint: '12',
                                  iconAsset: ImageAssets.buildNumber,
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: AddressTextField(
                                  label: 'mosaedApartmentOptional'.tr(),
                                  controller: _apartmentController,
                                  hint: '5',
                                  iconAsset: ImageAssets.houseIcon,
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 14.h),
                          AddressDropdownField<String>(
                            label: 'mosaedDescription'.tr(),
                            hint: 'mosaedSelectPlaceDescription'.tr(),
                            iconAsset: ImageAssets.descIcon,
                            value: _selectedLabel,
                            items: _labelOptions
                                .map(
                                  (e) => DropdownMenuItem(
                                    value: e.$1,
                                    child: Text(e.$2),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _selectedLabel = v),
                            validator: (v) => v == null
                                ? 'mosaedSelectPlaceDescription'.tr()
                                : null,
                          ),
                          SizedBox(height: 8.h),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(24.w, 8.h, 24.w, 16.h),
                    child: Column(
                      children: [
                        MosaedPrimaryButton(
                          text: 'mosaedSaveAndContinue'.tr(),
                          isLoading: _saving,
                          onPressed: _canSubmit ? _save : null,
                        ),
                        SizedBox(height: 14.h),
                        UseCurrentLocationLink(onTap: _openMapPicker),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
