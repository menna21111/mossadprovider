import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../app/functions.dart';
import '../../../core/constants/mosaed_colors.dart';
import '../../../core/constants/mosaed_map_style.dart';
import '../../../core/constants/styles_manager.dart';
import '../../auth/presentation/widgets/mosaed_buttons.dart';
import 'widgets/address_chrome.dart';

/// Full-screen map picker with center pin (design).
class PickLocationMapScreen extends StatefulWidget {
  const PickLocationMapScreen({
    super.key,
    this.initialPosition,
    this.goToCurrentOnStart = true,
  });

  final LatLng? initialPosition;
  final bool goToCurrentOnStart;

  static Future<LatLng?> open(
    BuildContext context, {
    LatLng? initialPosition,
    bool goToCurrentOnStart = true,
  }) {
    return Navigator.of(context).push<LatLng>(
      MaterialPageRoute(
        builder: (_) => PickLocationMapScreen(
          initialPosition: initialPosition,
          goToCurrentOnStart: goToCurrentOnStart,
        ),
      ),
    );
  }

  @override
  State<PickLocationMapScreen> createState() => _PickLocationMapScreenState();
}

class _PickLocationMapScreenState extends State<PickLocationMapScreen> {
  static const _riyadh = LatLng(24.713552, 46.675297);

  GoogleMapController? _mapController;
  late LatLng _center;
  final _searchController = TextEditingController();
  bool _moving = false;

  @override
  void initState() {
    super.initState();
    _center = widget.initialPosition ?? _riyadh;
    _searchController.text = _formatCoords(_center);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.goToCurrentOnStart) _goToCurrentLocation();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  String _formatCoords(LatLng p) =>
      '${p.latitude.toStringAsFixed(5)}, ${p.longitude.toStringAsFixed(5)}';

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
      final latLng = LatLng(pos.latitude, pos.longitude);
      if (!mounted) return;
      setState(() {
        _center = latLng;
        _searchController.text = _formatCoords(latLng);
      });
      await _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: latLng, zoom: 16),
        ),
      );
    } catch (_) {}
  }

  void _confirm() => Navigator.pop(context, _center);

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: MosaedColors.surfaceWhite,
      appBar: AddressAppBar(
        title: 'mosaedSelectYourLocation'.tr(),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: GoogleMap(
              style: mosaedMapStyle,
              initialCameraPosition: CameraPosition(target: _center, zoom: 15),
              onMapCreated: (c) => _mapController = c,
              onCameraMove: (pos) {
                _center = pos.target;
                if (!_moving) setState(() => _moving = true);
              },
              onCameraIdle: () {
                setState(() {
                  _moving = false;
                  _searchController.text = _formatCoords(_center);
                });
              },
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              compassEnabled: false,
              padding: EdgeInsets.only(bottom: 110.h + bottomPad),
            ),
          ),
          IgnorePointer(
            child: Center(
              child: Padding(
                padding: EdgeInsets.only(bottom: 70.h + bottomPad),
                child: Icon(
                  Icons.location_on_rounded,
                  size: 48.sp,
                  color: MosaedColors.brand,
                ),
              ),
            ),
          ),
          Positioned(
            top: 12.h,
            left: 16.w,
            right: 16.w,
            child: Material(
              elevation: 2,
              shadowColor: Colors.black26,
              borderRadius: BorderRadius.circular(12.r),
              child: TextField(
                controller: _searchController,
                readOnly: true,
                style: getRegularStyle(
                  fontSize: 13.sp,
                  color: MosaedColors.brand,
                ),
                decoration: InputDecoration(
                  hintText: 'mosaedSearchAddressHint'.tr(),
                  hintStyle: getRegularStyle(
                    fontSize: 13.sp,
                    color: MosaedColors.textHint,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: MosaedColors.brand,
                    size: 22.sp,
                  ),
                  suffixIcon: IconButton(
                    onPressed: () => _searchController.clear(),
                    icon: Icon(
                      Icons.close_rounded,
                      color: MosaedColors.brand,
                      size: 20.sp,
                    ),
                  ),
                  filled: true,
                  fillColor: MosaedColors.surfaceWhite,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 14.w,
                    vertical: 14.h,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: const BorderSide(
                      color: MosaedColors.brand,
                      width: 1.2,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: const BorderSide(
                      color: MosaedColors.brand,
                      width: 1.4,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 16.w,
            bottom: 100.h + bottomPad,
            child: Material(
              color: MosaedColors.surfaceWhite,
              elevation: 2,
              borderRadius: BorderRadius.circular(12.r),
              child: InkWell(
                borderRadius: BorderRadius.circular(12.r),
                onTap: _goToCurrentLocation,
                child: SizedBox(
                  width: 48.w,
                  height: 48.w,
                  child: Icon(
                    Icons.my_location_rounded,
                    color: MosaedColors.brand,
                    size: 22.sp,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 16.h + bottomPad),
              decoration: BoxDecoration(
                color: MosaedColors.surfaceWhite,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: MosaedPrimaryButton(
                text: 'mosaedTapToConfirm'.tr(),
                onPressed: _moving ? null : _confirm,
                enabled: !_moving,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
