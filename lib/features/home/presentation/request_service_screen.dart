import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:page_transition/page_transition.dart';

import '../../../app/functions.dart';
import '../../../core/constants/mosaed_colors.dart';
import '../../../core/constants/styles_manager.dart';
import '../../../core/services/location_service.dart';
import '../../auth/presentation/widgets/mosaed_buttons.dart';
import 'location_setup_screen.dart';

class RequestServiceScreen extends StatefulWidget {
  const RequestServiceScreen({super.key, this.initialServiceKey});

  final String? initialServiceKey;

  static const slots = [
    'mosaedSlotToday2',
    'mosaedSlotToday4',
    'mosaedSlotToday6',
    'mosaedSlotTomorrow10',
    'mosaedSlotTomorrow2',
    'mosaedSlotTomorrow6',
  ];

  static const services = [
    'mosaedPlumbing',
    'mosaedInsulation',
    'mosaedElectric',
    'mosaedAc',
    'mosaedCleaning',
    'mosaedPainting',
  ];

  @override
  State<RequestServiceScreen> createState() => _RequestServiceScreenState();
}

class _RequestServiceScreenState extends State<RequestServiceScreen> {
  late String? _selectedService;
  String? _selectedSlot;
  final _notesController = TextEditingController();
  late UserLocation _location;

  @override
  void initState() {
    super.initState();
    _selectedService = widget.initialServiceKey ?? RequestServiceScreen.services.first;
    _location = LocationService.savedLocation;
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_selectedService == null) {
      AppFunctions.showsToast(
        'mosaedSelectService'.tr(),
        MosaedColors.danger,
        context,
      );
      return;
    }
    if (_selectedSlot == null) {
      AppFunctions.showsToast(
        'mosaedSelectSlot'.tr(),
        MosaedColors.danger,
        context,
      );
      return;
    }
    if (!LocationService.hasValidLocation) {
      AppFunctions.showsToast(
        'mosaedLocationRequired'.tr(),
        MosaedColors.danger,
        context,
      );
      return;
    }

    AppFunctions.showsToast(
      'mosaedRequestSubmitted'.tr(),
      MosaedColors.success,
      context,
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MosaedColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'mosaedRequestService'.tr(),
          style: getBoldStyle(fontSize: 18.sp, color: MosaedColors.textPrimary),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'mosaedSelectServiceType'.tr(),
                style: getBoldStyle(fontSize: 16.sp, color: MosaedColors.textPrimary),
              ),
              SizedBox(height: 12.h),
              Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                children: RequestServiceScreen.services.map((service) {
                  final selected = _selectedService == service;
                  return ChoiceChip(
                    label: Text(service.tr()),
                    selected: selected,
                    selectedColor: MosaedColors.primary.withValues(alpha: 0.15),
                    labelStyle: getMediumStyle(
                      fontSize: 12.sp,
                      color: selected
                          ? MosaedColors.primary
                          : MosaedColors.textPrimary,
                    ),
                    onSelected: (_) => setState(() => _selectedService = service),
                  );
                }).toList(),
              ),
              SizedBox(height: 24.h),
              Text(
                'mosaedServiceLocation'.tr(),
                style: getBoldStyle(fontSize: 16.sp, color: MosaedColors.textPrimary),
              ),
              SizedBox(height: 10.h),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: MosaedColors.surface,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: MosaedColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.location_on_rounded, color: MosaedColors.primary),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            _location.fullAddress.isEmpty
                                ? 'mosaedNoLocationYet'.tr()
                                : _location.fullAddress,
                            style: getMediumStyle(
                              fontSize: 13.sp,
                              color: MosaedColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10.h),
                    TextButton.icon(
                      onPressed: () async {
                        await AppFunctions.navigateTo(
                          context,
                          const LocationSetupScreen(canSkip: true),
                          PageTransitionType.rightToLeft,
                        );
                        if (mounted) {
                          setState(() => _location = LocationService.savedLocation);
                        }
                      },
                      icon: const Icon(Icons.edit_location_alt_outlined),
                      label: Text('mosaedChangeLocation'.tr()),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24.h),
              Text(
                'mosaedSelectAppointment'.tr(),
                style: getBoldStyle(fontSize: 16.sp, color: MosaedColors.textPrimary),
              ),
              SizedBox(height: 8.h),
              Text(
                'mosaedFixedSlotsHint'.tr(),
                style: getRegularStyle(
                  fontSize: 12.sp,
                  color: MosaedColors.textSecondary,
                ),
              ),
              SizedBox(height: 12.h),
              ...RequestServiceScreen.slots.map((slot) {
                final selected = _selectedSlot == slot;
                return Padding(
                  padding: EdgeInsets.only(bottom: 8.h),
                  child: InkWell(
                    onTap: () => setState(() => _selectedSlot = slot),
                    borderRadius: BorderRadius.circular(14.r),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                      decoration: BoxDecoration(
                        color: selected
                            ? MosaedColors.primary.withValues(alpha: 0.1)
                            : MosaedColors.surface,
                        borderRadius: BorderRadius.circular(14.r),
                        border: Border.all(
                          color: selected
                              ? MosaedColors.primary
                              : MosaedColors.border,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.schedule_rounded,
                            color: selected
                                ? MosaedColors.primary
                                : MosaedColors.textSecondary,
                          ),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: Text(
                              slot.tr(),
                              style: getMediumStyle(
                                fontSize: 14.sp,
                                color: MosaedColors.textPrimary,
                              ),
                            ),
                          ),
                          if (selected)
                            Icon(Icons.check_circle, color: MosaedColors.primary),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              SizedBox(height: 16.h),
              Text(
                'notesOptional'.tr(),
                style: getMediumStyle(
                  fontSize: 13.sp,
                  color: MosaedColors.textSecondary,
                ),
              ),
              SizedBox(height: 8.h),
              TextField(
                controller: _notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'notesHint'.tr(),
                  filled: true,
                  fillColor: MosaedColors.inputFill,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14.r),
                    borderSide: const BorderSide(color: MosaedColors.border),
                  ),
                ),
              ),
              SizedBox(height: 24.h),
              MosaedPrimaryButton(
                text: 'mosaedConfirmRequest'.tr(),
                icon: Icons.check_rounded,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}


