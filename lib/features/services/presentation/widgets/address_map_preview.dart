import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/constants/mosaed_colors.dart';
import '../../../../core/constants/mosaed_map_style.dart';

class AddressMapPreview extends StatelessWidget {
  const AddressMapPreview({
    super.key,
    required this.position,
    required this.onTap,
    this.onLocate,
  });

  final LatLng position;
  final VoidCallback onTap;
  final VoidCallback? onLocate;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16.r),
      child: SizedBox(
        height: 168.h,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            IgnorePointer(
              child: GoogleMap(
                key: ValueKey('${position.latitude}-${position.longitude}'),
                style: mosaedMapStyle,
                initialCameraPosition:
                    CameraPosition(target: position, zoom: 15),
                markers: {
                  Marker(
                    markerId: const MarkerId('preview'),
                    position: position,
                    icon: BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueOrange,
                    ),
                  ),
                },
                zoomControlsEnabled: false,
                myLocationButtonEnabled: false,
                mapToolbarEnabled: false,
                compassEnabled: false,
                scrollGesturesEnabled: false,
                zoomGesturesEnabled: false,
                rotateGesturesEnabled: false,
                tiltGesturesEnabled: false,
              ),
            ),
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: InkWell(onTap: onTap),
              ),
            ),
            if (onLocate != null)
              Positioned(
                left: 12.w,
                bottom: 12.h,
                child: Material(
                  color: MosaedColors.surfaceWhite,
                  elevation: 2,
                  shadowColor: Colors.black26,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: onLocate,
                    child: SizedBox(
                      width: 40.w,
                      height: 40.w,
                      child: Icon(
                        Icons.my_location_rounded,
                        color: MosaedColors.brand,
                        size: 18.sp,
                      ),
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
