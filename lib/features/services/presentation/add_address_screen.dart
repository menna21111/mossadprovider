import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../app/auth_navigation.dart';
import '../../../app/functions.dart';
import '../../../core/constants/mosaed_colors.dart';
import '../../../core/constants/styles_manager.dart';
import '../../../core/network/failure.dart';
import '../../auth/presentation/widgets/mosaed_buttons.dart';
import '../data/models/address_models.dart';
import '../data/services_repository.dart';

class AddAddressScreen extends StatefulWidget {
  const AddAddressScreen({super.key, this.canSkip = false});

  final bool canSkip;

  @override
  State<AddAddressScreen> createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends State<AddAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  final _districtController = TextEditingController();
  final _streetController = TextEditingController();
  final _buildingController = TextEditingController();
  final _floorController = TextEditingController();
  final _apartmentController = TextEditingController();
  final _labelController = TextEditingController(text: 'المنزل');

  GoogleMapController? _mapController;
  LatLng _position = const LatLng(24.713552, 46.675297);
  List<CityModel> _cities = [];
  List<RegionModel> _regions = [];
  String? _selectedCityId;
  String? _selectedRegionId;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _districtController.dispose();
    _streetController.dispose();
    _buildingController.dispose();
    _floorController.dispose();
    _apartmentController.dispose();
    _labelController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final repo = context.read<ServicesRepository>();
      final cities = await repo.getCities();
      if (!mounted) return;
      setState(() {
        _cities = cities;
        _loading = false;
        if (cities.isNotEmpty) {
          _selectedCityId = cities.first.id;
          _regions = cities.first.regions;
          if (_regions.isNotEmpty) _selectedRegionId = _regions.first.id;
        }
      });
      await _goToCurrentLocation();
    } on ServerFailure catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        AppFunctions.showsToast(e.errMessage, MosaedColors.danger, context);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _goToCurrentLocation() async {
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      await Geolocator.requestPermission();
    }
    try {
      final pos = await Geolocator.getCurrentPosition();
      final latLng = LatLng(pos.latitude, pos.longitude);
      if (!mounted) return;
      setState(() => _position = latLng);
      await _mapController?.animateCamera(CameraUpdate.newLatLng(latLng));
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
      final regions = await context.read<ServicesRepository>().getRegions(cityId);
      if (!mounted) return;
      setState(() {
        _regions = regions;
        if (regions.isNotEmpty) _selectedRegionId = regions.first.id;
      });
    } catch (_) {}
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCityId == null || _selectedRegionId == null) {
      AppFunctions.showsToast(
        'mosaedAddressCityRegionRequired'.tr(),
        MosaedColors.danger,
        context,
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await context.read<ServicesRepository>().createAddress(
            CreateAddressPayload(
              city: _selectedCityId!,
              region: _selectedRegionId!,
              district: _districtController.text.trim(),
              street: _streetController.text.trim(),
              buildingNo: _buildingController.text.trim(),
              floorNo: _floorController.text.trim(),
              apartmentNo: _apartmentController.text.trim(),
              lat: _position.latitude,
              lng: _position.longitude,
              label: _labelController.text.trim(),
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
      backgroundColor: MosaedColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'mosaedAddAddress'.tr(),
          style: getBoldStyle(fontSize: 18.sp, color: MosaedColors.textPrimary),
        ),
        actions: [
          IconButton(
            onPressed: _goToCurrentLocation,
            icon: const Icon(Icons.my_location_rounded),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                SizedBox(
                  height: 220.h,
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: _position,
                      zoom: 14,
                    ),
                    onMapCreated: (c) => _mapController = c,
                    onTap: (latLng) => setState(() => _position = latLng),
                    markers: {
                      Marker(
                        markerId: const MarkerId('selected'),
                        position: _position,
                        draggable: true,
                        onDragEnd: (p) => setState(() => _position = p),
                      ),
                    },
                    myLocationEnabled: true,
                    myLocationButtonEnabled: false,
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(20.w),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'mosaedMapPinHint'.tr(),
                            style: getRegularStyle(
                              fontSize: 12.sp,
                              color: MosaedColors.textSecondary,
                            ),
                          ),
                          SizedBox(height: 16.h),
                          _dropdown(
                            label: 'mosaedCity'.tr(),
                            value: _selectedCityId,
                            items: _cities
                                .map((c) => (c.id, c.name))
                                .toList(),
                            onChanged: _onCityChanged,
                          ),
                          SizedBox(height: 12.h),
                          _dropdown(
                            label: 'mosaedRegion'.tr(),
                            value: _selectedRegionId,
                            items: _regions
                                .map((r) => (r.id, r.name))
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _selectedRegionId = v),
                          ),
                          SizedBox(height: 12.h),
                          _field(
                            controller: _districtController,
                            label: 'mosaedDistrict'.tr(),
                            hint: 'mosaedDistrictHint'.tr(),
                            required: true,
                          ),
                          SizedBox(height: 12.h),
                          _field(
                            controller: _streetController,
                            label: 'mosaedStreet'.tr(),
                            hint: 'mosaedStreetHint'.tr(),
                            required: true,
                          ),
                          SizedBox(height: 12.h),
                          Row(
                            children: [
                              Expanded(
                                child: _field(
                                  controller: _buildingController,
                                  label: 'mosaedBuildingNo'.tr(),
                                  hint: '12',
                                ),
                              ),
                              SizedBox(width: 8.w),
                              Expanded(
                                child: _field(
                                  controller: _floorController,
                                  label: 'mosaedFloorNo'.tr(),
                                  hint: '3',
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12.h),
                          _field(
                            controller: _apartmentController,
                            label: 'mosaedApartmentNo'.tr(),
                            hint: '5',
                          ),
                          SizedBox(height: 12.h),
                          _field(
                            controller: _labelController,
                            label: 'mosaedAddressLabel'.tr(),
                            hint: 'mosaedAddressLabelHint'.tr(),
                          ),
                          SizedBox(height: 20.h),
                          MosaedPrimaryButton(
                            text: 'mosaedSaveAddress'.tr(),
                            icon: Icons.save_rounded,
                            isLoading: _saving,
                            onPressed: _save,
                          ),
                          if (widget.canSkip) ...[
                            SizedBox(height: 12.h),
                            MosaedOutlineButton(
                              text: 'cancel'.tr(),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _dropdown({
    required String label,
    required String? value,
    required List<(String, String)> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: getMediumStyle(
            fontSize: 13.sp,
            color: MosaedColors.textSecondary,
          ),
        ),
        SizedBox(height: 6.h),
        DropdownButtonFormField<String>(
          value: value,
          decoration: _decoration(),
          items: items
              .map(
                (e) => DropdownMenuItem(value: e.$1, child: Text(e.$2)),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool required = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: getMediumStyle(
            fontSize: 13.sp,
            color: MosaedColors.textSecondary,
          ),
        ),
        SizedBox(height: 6.h),
        TextFormField(
          controller: controller,
          decoration: _decoration(hint: hint),
          validator: required
              ? (v) => v == null || v.trim().isEmpty
                  ? 'fieldRequired'.tr()
                  : null
              : null,
        ),
      ],
    );
  }

  InputDecoration _decoration({String? hint}) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: MosaedColors.inputFill,
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14.r),
        borderSide: const BorderSide(color: MosaedColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14.r),
        borderSide: const BorderSide(color: MosaedColors.primary, width: 1.5),
      ),
    );
  }
}
