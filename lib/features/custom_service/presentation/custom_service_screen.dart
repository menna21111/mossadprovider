import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/functions.dart';
import '../../../core/constants/mosaed_colors.dart';
import '../../../core/constants/styles_manager.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/network/failure.dart';
// import '../../../core/services/cloudinary_upload_service.dart';
import '../../../core/widgets/mosaed_dropdown.dart';
import '../../auth/presentation/widgets/mosaed_buttons.dart';
import '../../services/data/models/address_models.dart';
import '../../services/data/services_repository.dart';
import '../../services/presentation/add_address_screen.dart';
import '../data/custom_service_repository.dart';
import '../data/models/custom_service_models.dart';

class CustomServiceScreen extends StatefulWidget {
  const CustomServiceScreen({super.key});

  @override
  State<CustomServiceScreen> createState() => _CustomServiceScreenState();
}

class _CustomServiceScreenState extends State<CustomServiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _imagePicker = ImagePicker();

  List<Specialization> _specializations = [];
  List<CustomerAddress> _addresses = [];
  String? _selectedSpecializationId;
  String? _selectedAddressId;
  DateTime? _scheduledDate;
  File? _pickedImage;
  String? _uploadedImageUrl;
  bool _loading = true;
  bool _submitting = false;
  // bool _uploadingImage = false; // TODO: مع تفعيل Cloudinary

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final servicesRepo = context.read<ServicesRepository>();
      final customRepo = context.read<CustomServiceRepository>();

      final results = await Future.wait([
        customRepo.getSpecializations(),
        servicesRepo.getAddresses(),
      ]);

      final specializations = results[0] as List<Specialization>;
      final addresses = results[1] as List<CustomerAddress>;
      final defaultId = servicesRepo.cachedDefaultAddressId;

      String? selectedAddressId;
      if (addresses.isNotEmpty) {
        selectedAddressId = addresses
            .firstWhere(
              (a) => a.id == defaultId || a.isDefault,
              orElse: () => addresses.first,
            )
            .id;
      }

      if (!mounted) return;
      setState(() {
        _specializations = specializations;
        _addresses = addresses;
        _selectedAddressId = selectedAddressId;
        if (specializations.isNotEmpty) {
          _selectedSpecializationId = specializations.first.id;
        }
        _loading = false;
      });
    } on ServerFailure catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        AppFunctions.showsToast(e.errMessage, MosaedColors.danger, context);
      }
    }
  }

  Future<void> _addAddress() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AddAddressScreen(canSkip: true),
      ),
    );
    await _loadData();
  }

  Future<void> _pickScheduledDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _scheduledDate = picked);
  }

  Future<void> _showImageSourceSheet() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: MosaedColors.surfaceWhite,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 12.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: Text('mosaedPickFromGallery'.tr()),
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_camera_outlined),
                  title: Text('mosaedTakePhoto'.tr()),
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (source == null) return;

    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 85,
      );
      if (picked == null) return;
      setState(() {
        _pickedImage = File(picked.path);
        // مؤقتًا: أي صورة مختارة تستخدم placeholder URL لحد تفعيل Cloudinary
        _uploadedImageUrl = AppConstants.customRequestPlaceholderImage;
      });
      // await _uploadPickedImage();
    } catch (_) {
      if (!mounted) return;
      AppFunctions.showsToast(
        'mosaedImagePickError'.tr(),
        MosaedColors.danger,
        context,
      );
    }
  }

  void _removeImage() => setState(() {
        _pickedImage = null;
        _uploadedImageUrl = null;
      });

  // TODO: فعّل لما يتظبط cloudinary upload preset
  // Future<void> _uploadPickedImage() async {
  //   if (_pickedImage == null) return;
  //
  //   setState(() => _uploadingImage = true);
  //   try {
  //     final url = await context
  //         .read<CloudinaryUploadService>()
  //         .uploadImage(_pickedImage!);
  //     if (!mounted) return;
  //     setState(() {
  //       _uploadedImageUrl = url;
  //       _uploadingImage = false;
  //     });
  //   } on ServerFailure catch (e) {
  //     if (!mounted) return;
  //     setState(() {
  //       _uploadingImage = false;
  //       _pickedImage = null;
  //       _uploadedImageUrl = null;
  //     });
  //     AppFunctions.showsToast(e.errMessage, MosaedColors.danger, context);
  //   }
  // }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedSpecializationId == null || _selectedSpecializationId!.isEmpty) {
      AppFunctions.showsToast(
        'mosaedSelectSpecialization'.tr(),
        MosaedColors.danger,
        context,
      );
      return;
    }

    if (_pickedImage != null && _uploadedImageUrl == null) {
      setState(() {
        _uploadedImageUrl = AppConstants.customRequestPlaceholderImage;
      });
    }

    // if (_pickedImage != null && _uploadedImageUrl == null) {
    //   if (_uploadingImage) {
    //     AppFunctions.showsToast(
    //       'mosaedUploadingImage'.tr(),
    //       MosaedColors.danger,
    //       context,
    //     );
    //     return;
    //   }
    //   await _uploadPickedImage();
    //   if (_uploadedImageUrl == null) return;
    // }

    if (_scheduledDate == null) {
      AppFunctions.showsToast(
        'mosaedSelectPreferredDay'.tr(),
        MosaedColors.danger,
        context,
      );
      return;
    }

    if (_selectedAddressId == null) {
      AppFunctions.showsToast(
        'mosaedAddressRequired'.tr(),
        MosaedColors.danger,
        context,
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      await context.read<CustomServiceRepository>().createCustomRequest(
            CustomRequestPayload(
              specializationId: _selectedSpecializationId!,
              title: _titleController.text.trim(),
              description: _descriptionController.text.trim(),
              scheduledDate: DateFormat('yyyy-MM-dd').format(_scheduledDate!),
              addressId: _selectedAddressId!,
              image: _uploadedImageUrl ?? AppConstants.customRequestPlaceholderImage,
            ),
          );
      if (!mounted) return;
      AppFunctions.showsToast(
        'mosaedCustomServiceSuccess'.tr(),
        MosaedColors.success,
        context,
      );
      Navigator.pop(context);
    } on ServerFailure catch (e) {
      if (mounted) {
        AppFunctions.showsToast(e.errMessage, MosaedColors.danger, context);
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          width: 36.w,
          height: 36.w,
          decoration: BoxDecoration(
            color: MosaedColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Icon(icon, color: MosaedColors.primary, size: 20.sp),
        ),
        SizedBox(width: 10.w),
        Text(
          title,
          style: getBoldStyle(fontSize: 16.sp, color: MosaedColors.textPrimary),
        ),
      ],
    );
  }

  Widget _surfaceField({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: MosaedColors.surfaceWhite,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: MosaedColors.outlineVariant),
        boxShadow: MosaedColors.softShadow,
      ),
      child: child,
    );
  }

  Widget _buildImagePicker() {
    return InkWell(
      onTap: _submitting ? null : _showImageSourceSheet,
      borderRadius: BorderRadius.circular(14.r),
      child: _surfaceField(
        child: _pickedImage == null
            ? Padding(
                padding: EdgeInsets.symmetric(vertical: 28.h),
                child: Column(
                  children: [
                    Icon(
                      Icons.add_photo_alternate_outlined,
                      size: 42.sp,
                      color: MosaedColors.primaryContainer,
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'mosaedTapToAddPhoto'.tr(),
                      style: getMediumStyle(
                        fontSize: 13.sp,
                        color: MosaedColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              )
            : Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10.r),
                    child: Image.file(
                      _pickedImage!,
                      width: double.infinity,
                      height: 180.h,
                      fit: BoxFit.cover,
                    ),
                  ),
                  // if (_uploadingImage)
                  //   Positioned.fill(
                  //     child: Container(
                  //       decoration: BoxDecoration(
                  //         color: Colors.black45,
                  //         borderRadius: BorderRadius.circular(10.r),
                  //       ),
                  //       child: Center(
                  //         child: Column(
                  //           mainAxisSize: MainAxisSize.min,
                  //           children: [
                  //             const CircularProgressIndicator(color: Colors.white),
                  //             SizedBox(height: 8.h),
                  //             Text(
                  //               'mosaedUploadingImage'.tr(),
                  //               style: getMediumStyle(
                  //                 fontSize: 12.sp,
                  //                 color: Colors.white,
                  //               ),
                  //             ),
                  //           ],
                  //         ),
                  //       ),
                  //     ),
                  //   ),
                  if (_uploadedImageUrl != null)
                    Positioned(
                      top: 8.h,
                      right: 8.w,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: MosaedColors.success,
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_rounded, color: Colors.white, size: 16),
                            SizedBox(width: 4.w),
                            Text(
                              'OK',
                              style: getMediumStyle(
                                fontSize: 11.sp,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  Positioned(
                    top: 8.h,
                    left: 8.w,
                    child: IconButton.filled(
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black54,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _submitting ? null : _removeImage,
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ),
                  Positioned(
                    bottom: 8.h,
                    right: 8.w,
                    child: TextButton.icon(
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.black54,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _submitting ? null : _showImageSourceSheet,
                      icon: const Icon(Icons.edit_rounded, size: 18),
                      label: Text('mosaedChangePhoto'.tr()),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isBusy = _submitting;

    return Scaffold(
      backgroundColor: MosaedColors.background,
      appBar: AppBar(
        backgroundColor: MosaedColors.surfaceWhite,
        elevation: 0,
        leading: IconButton(
          onPressed: isBusy ? null : () => Navigator.pop(context),
          icon: Icon(
            Icons.arrow_forward_rounded,
            color: MosaedColors.primary,
            size: 22.sp,
          ),
        ),
        title: Text(
          'mosaedCustomServiceTitle'.tr(),
          style: getBoldStyle(fontSize: 18.sp, color: MosaedColors.textPrimary),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: MosaedColors.primaryContainer),
            )
          : Form(
              key: _formKey,
              child: ListView(
                padding: EdgeInsets.all(20.w),
                children: [
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: MosaedColors.primaryFixed,
                      borderRadius: BorderRadius.circular(14.r),
                      border: Border.all(
                        color: MosaedColors.primary.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Text(
                      'mosaedCustomServiceIntro'.tr(),
                      style: getRegularStyle(
                        fontSize: 13.sp,
                        color: MosaedColors.onPrimaryContainer,
                        height: 1.5,
                      ),
                    ),
                  ),
                  SizedBox(height: 24.h),
                  _sectionTitle('mosaedRequestTitle'.tr(), Icons.title_rounded),
                  SizedBox(height: 10.h),
                  _surfaceField(
                    child: TextFormField(
                      controller: _titleController,
                      textAlign: TextAlign.right,
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'fieldRequired'.tr()
                          : null,
                      decoration: InputDecoration(
                        hintText: 'mosaedRequestTitleHint'.tr(),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(12.w),
                      ),
                    ),
                  ),
                  SizedBox(height: 24.h),
                  _sectionTitle(
                    'mosaedSpecialization'.tr(),
                    Icons.category_outlined,
                  ),
                  SizedBox(height: 10.h),
                  _surfaceField(
                    child: Padding(
                      padding: EdgeInsets.all(8.w),
                      child: MosaedDropdown<String>(
                        title: '',
                        hint: 'mosaedSelectSpecialization'.tr(),
                        icon: Icons.handyman_outlined,
                        selectedValue: _selectedSpecializationId,
                        items: _specializations
                            .map(
                              (s) => MosaedDropdownItem(
                                value: s.id,
                                label: s.name,
                              ),
                            )
                            .toList(),
                        onSelected: (v) =>
                            setState(() => _selectedSpecializationId = v),
                      ),
                    ),
                  ),
                  SizedBox(height: 24.h),
                  _sectionTitle(
                    'mosaedProblemDescription'.tr(),
                    Icons.description_outlined,
                  ),
                  SizedBox(height: 10.h),
                  _surfaceField(
                    child: TextFormField(
                      controller: _descriptionController,
                      maxLines: 5,
                      textAlign: TextAlign.right,
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'fieldRequired'.tr()
                          : null,
                      decoration: InputDecoration(
                        hintText: 'mosaedCustomProblemHint'.tr(),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(12.w),
                      ),
                    ),
                  ),
                  SizedBox(height: 24.h),
                  _sectionTitle('mosaedPhoto'.tr(), Icons.image_outlined),
                  SizedBox(height: 10.h),
                  _buildImagePicker(),
                  SizedBox(height: 24.h),
                  _sectionTitle(
                    'mosaedPreferredDay'.tr(),
                    Icons.calendar_today_rounded,
                  ),
                  SizedBox(height: 10.h),
                  InkWell(
                    onTap: _pickScheduledDate,
                    borderRadius: BorderRadius.circular(14.r),
                    child: _surfaceField(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 14.w,
                          vertical: 14.h,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _scheduledDate == null
                                  ? 'mosaedSelectPreferredDay'.tr()
                                  : DateFormat(
                                      'EEEE، d MMMM yyyy',
                                      context.locale.languageCode,
                                    ).format(_scheduledDate!),
                              style: getRegularStyle(
                                fontSize: 14.sp,
                                color: _scheduledDate == null
                                    ? MosaedColors.textHint
                                    : MosaedColors.textPrimary,
                              ),
                            ),
                            Icon(
                              Icons.calendar_month_rounded,
                              color: MosaedColors.primaryContainer,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 24.h),
                  _sectionTitle(
                    'mosaedServiceLocation'.tr(),
                    Icons.location_on_outlined,
                  ),
                  SizedBox(height: 10.h),
                  _surfaceField(
                    child: Padding(
                      padding: EdgeInsets.all(8.w),
                      child: MosaedDropdown<String>(
                        title: '',
                        hint: 'mosaedSelectAddress'.tr(),
                        icon: Icons.home_work_outlined,
                        selectedValue: _selectedAddressId,
                        items: _addresses
                            .map(
                              (a) => MosaedDropdownItem(
                                value: a.id,
                                label: a.fullAddress,
                              ),
                            )
                            .toList(),
                        onSelected: (v) => setState(() => _selectedAddressId = v),
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _addAddress,
                    icon: Icon(Icons.add_circle_outline, color: MosaedColors.primary),
                    label: Text(
                      'mosaedAddAddress'.tr(),
                      style: getBoldStyle(
                        fontSize: 13.sp,
                        color: MosaedColors.primary,
                      ),
                    ),
                  ),
                  SizedBox(height: 24.h),
                  MosaedPrimaryButton(
                    text: 'mosaedSubmitCustomRequest'.tr(),
                    icon: Icons.send_rounded,
                    isLoading: isBusy,
                    onPressed: _submit,
                  ),
                  SizedBox(height: 16.h),
                ],
              ),
            ),
    );
  }
}
